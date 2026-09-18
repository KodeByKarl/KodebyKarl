local Vars = {}

Vars.ox = exports.ox_inventory
Vars.oxItems = Vars.ox:Items()
Vars.oxCb = lib.callback
Vars.carrying = {}
Vars.carried = {}
Vars.buhating = {}
Vars.nakabuhat = {}
Vars.piggybacking = {}
Vars.beingPiggybacked = {}
Vars.takingHostage = {}
Vars.takenHostage = {}

if not IsDuplicityVersion() then
    Vars.oxPoints = lib.points
    Vars.oxImagePath = GetConvar('inventory:imagepath', '')
    Vars.playerState = LocalPlayer.state
    Vars.oxTarget = exports.ox_target
    Vars.isCarrying = false
end

return Vars