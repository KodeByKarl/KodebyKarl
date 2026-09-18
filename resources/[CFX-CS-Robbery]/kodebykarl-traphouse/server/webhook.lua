local Webhook = {}

function Webhook.SendLog(title, color, message)
    if not Config.WebhookURL or Config.WebhookURL == '' then return end

    local embedData = {
        {
            ["title"] = title,
            ["color"] = color or 16711680,
            ["author"] = {
                ["name"] = 'KodeByKarl Unli TrapHouse System',
                ["icon_url"] = "https://r2.fivemanage.com/IBsYpR5f4ceyk3GWUfSzg/c-scripts_dc.png"
            },
            ["description"] = message,
            ["footer"] = {
                ["text"] = 'GrimCity Roleplay • ' .. os.date('%Y-%m-%d %H:%M:%S'),
            },
        }
    }

    PerformHttpRequest(Config.WebhookURL, function() end, "POST", json.encode({
        username = "KodeByKarl TrapHouse Logs",
        embeds = embedData
    }), { ["Content-Type"] = "application/json" })
end

return Webhook
