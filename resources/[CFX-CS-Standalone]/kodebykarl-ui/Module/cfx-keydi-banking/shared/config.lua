ConfigBanking = {}

ConfigBanking.Debug = false
ConfigBanking.OpenCommand = "" -- Leave blank to disable /banking; open only via ATM / bank teller
ConfigBanking.OpenKey = "" -- Default keybind (leave blank; command disabled when OpenCommand is blank)
ConfigBanking.MaxTransactionsStored = 20

ConfigBanking.ATMs = {
    `prop_atm_01`,
    `prop_atm_02`,
    `prop_atm_03`,
    `prop_fleeca_atm`,
}

ConfigBanking.BankPedLocations = {
    { coords = vector3(149.4113, -1042.0449, 29.3680), heading = 342.9182 }, -- Legion Square
    { coords = vector3(-1211.8585, -331.9854, 37.7809), heading = 28.5983 }, -- Rockford Hills
    { coords = vector3(-2961.0720, 483.1107, 15.6970), heading = 88.1986 }, -- Great Ocean Highway
    { coords = vector3(-112.2223, 6471.1128, 31.6267), heading = 132.7517 }, -- Paleto Bay
    { coords = vector3(313.8176, -280.5338, 54.1647), heading = 339.1609 }, -- Pillbox Hill
    { coords = vector3(-351.3247, -51.3466, 49.0365), heading = 339.3305 }, -- Burton
    { coords = vector3(1174.9718, 2708.2034, 38.0879), heading = 178.2974 }, -- Sandy Shores
    { coords = vector3(247.0348, 225.1851, 106.2875), heading = 158.7528 }, -- Vinewood
}

--[[
    Discord logs via kodebykarl-logs → ECONOMY channels:
    #withdraw #deposit #transfer #SOCIETY #RICHEST-PERSON
]]
ConfigBanking.Logs = {
    Enabled = true,
    LogTypes = {
        withdraw = true,
        deposit = true,
        society = true,
        transfer = true,
        richest = true,
    },
}

--[[
    Periodic richest-player report moved to kodebykarl-utils (modules/richest).
    Keep Enabled = false here to avoid duplicate Discord posts / /topmoney conflict.
]]
ConfigBanking.Richest = {
    Enabled = false,
    IntervalMinutes = 30,
    Top = 10,
    OnlyTop = true,
    IncludeDirtyMoney = true,
    AdminCommand = "topmoney",
    LogMessageType = "standard",
}
