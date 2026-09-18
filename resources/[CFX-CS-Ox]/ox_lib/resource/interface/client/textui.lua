--[[
    https://github.com/overextended/ox_lib

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 Linden <https://github.com/thelindat>

    CFX-CS patch: stacked / keyed TextUI so scripts cannot wipe each other's prompts.
    - showTextUI(text, { id = 'my_resource', ... })
    - hideTextUI('my_resource') only removes that id and redisplays the next
    - hideTextUI() with no args only removes the 'default' id (legacy callers)
    - hideTextUI(true) or hideTextUI('all') force-clears every entry
]]

---@class TextUIOptions
---@field id? string
---@field position? 'right-center' | 'left-center' | 'top-center' | 'bottom-center'
---@field icon? string | {[1]: IconProp, [2]: string};
---@field iconColor? string;
---@field style? string | table;
---@field alignIcon? 'top' | 'center';

local isOpen = false
local currentText
local currentId

--- @type table<string, { text: string, options: TextUIOptions }>
local entries = {}
--- most-recent last (top of stack)
local stack = {}

local function removeFromStack(id)
    for i = #stack, 1, -1 do
        if stack[i] == id then
            table.remove(stack, i)
        end
    end
end

local function pushStack(id)
    removeFromStack(id)
    stack[#stack + 1] = id
end

local function sendHide()
    SendNUIMessage({
        action = 'textUiHide'
    })
    isOpen = false
    currentText = nil
    currentId = nil
end

local function sendShow(entry)
    local options = entry.options
    options.text = entry.text

    SendNUIMessage({
        action = 'textUi',
        data = options
    })

    isOpen = true
    currentText = entry.text
    currentId = options.id
end

local function refreshDisplay()
    local topId = stack[#stack]
    if not topId then
        sendHide()
        return
    end

    local entry = entries[topId]
    if not entry then
        removeFromStack(topId)
        refreshDisplay()
        return
    end

    -- Already showing this exact text from this id — skip NUI spam
    if isOpen and currentId == topId and currentText == entry.text then
        return
    end

    sendShow(entry)
end

---@param text string
---@param options? TextUIOptions
function lib.showTextUI(text, options)
    local opts = {}
    if options then
        for k, v in pairs(options) do
            opts[k] = v
        end
    end

    local id = opts.id or 'default'
    opts.id = id

    local prev = entries[id]
    if prev and prev.text == text and stack[#stack] == id and isOpen then
        entries[id] = { text = text, options = opts }
        return
    end

    entries[id] = { text = text, options = opts }
    pushStack(id)
    refreshDisplay()
end

---@param id? string | boolean
--- Omit id → hide only the legacy 'default' entry (safe for other keyed prompts).
--- Pass a string → hide that id only.
--- Pass true or 'all' → clear every TextUI entry.
function lib.hideTextUI(id)
    if id == true or id == 'all' then
        entries = {}
        stack = {}
        sendHide()
        return
    end

    id = id or 'default'

    if not entries[id] then
        -- Nothing to remove for this id — do NOT nuke unrelated prompts
        return
    end

    entries[id] = nil
    removeFromStack(id)
    refreshDisplay()
end

---@return boolean, string | nil, string | nil
function lib.isTextUIOpen()
    return isOpen, currentText, currentId
end
