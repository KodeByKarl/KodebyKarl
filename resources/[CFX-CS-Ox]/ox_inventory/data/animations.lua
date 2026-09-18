return {
	anim = {
		-- flag 49 = upper body only so food stays usable while holding a gun
		['eating'] = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger', flag = 49 },
	},
	prop = {
		['burger'] = { model = `prop_cs_burger_01`, pos = vec3(0.02, 0.02, -0.02), rot = vec3(0.0, 0.0, 0.0) },
	}
}