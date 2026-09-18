return {
	enable = true,
	allowedWeapons = {
        [`WEAPON_PISTOL`] = true,
        [`WEAPON_COMBATPISTOL`] = true
    },
    commands = {
        'takehostage',
        'th'
    },
    InProgress = false,
	type = "",
	targetSrc = -1,
	agressor = {
		animDict = "anim@gangops@hostage@",
		anim = "perp_idle",
		flag = 49,
	},
	hostage = {
		animDict = "anim@gangops@hostage@",
		anim = "victim_idle",
		attachX = -0.24,
		attachY = 0.11,
		attachZ = 0.0,
		flag = 49,
	}
}