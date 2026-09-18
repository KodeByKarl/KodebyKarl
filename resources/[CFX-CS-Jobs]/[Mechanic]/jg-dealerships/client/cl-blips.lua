--[[
  Description:
    Client-side blip creation helpers for dealership, direct-sale, and trucking map markers.

  Global Namespace:
    Blips.Client

  Globals:
    Blips.Client.Create
    Blips.Client.CreateRoute
    Blips.Client.Remove
    Blips.Client.SetCoords

  Exports:
    None
]]--

Blips = Blips or {}
Blips.Client = Blips.Client or {}

---@class BlipOptions
---@field sprite? integer
---@field colour? integer
---@field color? integer
---@field scale? number
---@field shortRange? boolean
---@field name? string
---@field route? boolean
---@field routeColour? integer
---@field routeColor? integer
---@field waypoint? boolean

---@param coords vector3|vector4
---@param options BlipOptions
---@return integer blip
function Blips.Client.Create(coords, options)
  options = options or {}

  local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
  SetBlipSprite(blip, options.sprite or 1)
  SetBlipColour(blip, options.colour or options.color or 0)
  SetBlipScale(blip, options.scale or 1.0)
  SetBlipAsShortRange(blip, options.shortRange ~= false)

  if options.name then
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(options.name)
    EndTextCommandSetBlipName(blip)
  end

  if options.route then
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, options.routeColour or options.routeColor or options.colour or options.color or 0)
  end

  if options.waypoint then
    SetNewWaypoint(coords.x, coords.y)
  end

  return blip
end

---@param coords vector3|vector4
---@param options BlipOptions?
---@return integer blip
function Blips.Client.CreateRoute(coords, options)
  options = options or {}
  options.route = true
  options.shortRange = false
  options.waypoint = options.waypoint ~= false

  return Blips.Client.Create(coords, options)
end

---@param blip integer?
function Blips.Client.Remove(blip)
  if not blip or not DoesBlipExist(blip) then return end
  RemoveBlip(blip)
end

---@param blip integer?
---@param coords vector3|vector4
function Blips.Client.SetCoords(blip, coords)
  if not blip or not DoesBlipExist(blip) then return end
  SetBlipCoords(blip, coords.x, coords.y, coords.z)
end
