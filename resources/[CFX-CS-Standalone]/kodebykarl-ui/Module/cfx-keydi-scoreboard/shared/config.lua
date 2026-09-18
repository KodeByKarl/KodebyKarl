ConfigScoreboard = {}

ConfigScoreboard.Debug = false

ConfigScoreboard.ServerName = "Grim City" -- Display name of your server in the scoreboard
ConfigScoreboard.EnablePriorityStatus = true -- Set to true to show Priority Status in the scoreboard, false to hide it

-- After a robbery ends (or PD sets Cooldown): wait this long, then auto Safe
ConfigScoreboard.PriorityCooldownSeconds = 15 * 60

ConfigScoreboard.ToggleKey = 'F10' -- Default keybind to toggle the scoreboard

-- Jobs we want to count online in the scoreboard
ConfigScoreboard.Jobs = {
    { name = "Los EMS", job = "ambulance" },
    { name = "Paleto EMS", job = "pambulance" },
    { name = "Sandy EMS", job = "sambulance" },
    { name = "Los Police", job = "police" },
    { name = "Paleto Sheriff", job = "sheriff" },
}

-- World events (location = place; status timer is driven live via SetWorldEvent endsAt/timer)
ConfigScoreboard.WorldEvents = {
    { name = "Airdrop", location = "—", status = "INACTIVE" },
    { name = "Traphouse", location = "—", status = "INACTIVE" },
    { name = "Turf Wars", location = "—", status = "INACTIVE" }
}

-- Default refresh interval for scoreboard metrics on client (in ms)
ConfigScoreboard.RefreshInterval = 5000

-- Discord avatars (leave empty to use convar kodebykarl_discord_bot_token)
ConfigScoreboard.DiscordBotToken = ""
