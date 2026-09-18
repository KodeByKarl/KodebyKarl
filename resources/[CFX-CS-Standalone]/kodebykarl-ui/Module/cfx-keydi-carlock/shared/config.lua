--[[
    cfx-keydi-carlock
    Vehicle lock / key system (ESX + ox_lib + ox_target).
    Keys are granted from jg-advancedgarages, dealerships, rentals, and sharing.
]]

ConfigCarlock = {}

ConfigCarlock.Enabled = true
ConfigCarlock.Debug = false

ConfigCarlock.Target = true
ConfigCarlock.TargetIcon = "fa-solid fa-lock"
ConfigCarlock.TargetDistance = 2.5

ConfigCarlock.Command = "carlock"
ConfigCarlock.DefaultKey = "L"
ConfigCarlock.CheckRadius = 8.0

ConfigCarlock.ProgressLength = 850
ConfigCarlock.Sounds = true
ConfigCarlock.Horn = true
ConfigCarlock.Lights = true
ConfigCarlock.LockMeCommand = false -- /me while locking (uses cfx-keydi-chat)

ConfigCarlock.DisableWhileLocking = {
    car = true,
    move = false,
    combat = true,
}

ConfigCarlock.Anim = {
    dict = "anim@mp_player_intmenu@key_fob@",
    clip = "fob_click_fp",
}

ConfigCarlock.Notifications = {
    Locked = true,
    Unlocked = true,
    NotYourVehicle = true,
    NoNearbyVehicles = true,
}

ConfigCarlock.Locale = {
    NotifyTitle = "Vehicle Lock",
    TargetLock = "Lock / Unlock Vehicle",
    TargetManage = "Manage Keys",
    ProgressLocking = "Locking...",
    ProgressUnlocking = "Unlocking...",
    NotifyLocked = "You locked the vehicle.",
    NotifyUnlocked = "You unlocked the vehicle.",
    NoVehicleNearby = "There are no nearby vehicles.",
    NotOwned = "You don't have keys for this vehicle.",
    ShareTitle = "Key Management",
    ShareKeys = "Share Keys",
    RemoveKeys = "Remove Shared Keys",
    ShareBlocked = "You cannot manage keys with a shared or temporary key.",
    AlreadyShared = "That player already has keys for this vehicle.",
    SharedTo = "You shared keys for %s with %s.",
    SharedFrom = "You received keys for %s.",
    RemovedFrom = "Your keys for %s were removed.",
    RemovedTo = "You removed keys for %s from that player.",
    NoShared = "You haven't shared keys with anyone yet.",
    ConfirmRemove = "Remove keys for %s from %s?",
    SelectPlayer = "Player to share keys with",
    Busy = "You are already using your keys.",
}
