return {
	{
		coords = vec3(79.4085, -389.1056, 41.6248),
		prefix = 'pd',
		label = 'Police Evidence',
		target = { -- qtarget support
			name = 'mrpd_evidence', -- name of zone must be unique
			loc = vec3(79.4085, -389.1056, 41.6248),
			length = 1.4,
			width = 2.0,
			heading = 67.8423,
			minZ = 40.6,
			maxZ = 43.1
		}
	},
	{
		coords = vec3(1888.1609, 3663.3677, 34.1130),
		prefix = 'sd',
		label = 'Sheriff Evidence',
		target = {
			name = 'sheriff_evidence',
			loc = vec3(1888.1609, 3663.3677, 34.1130),
			length = 1.4,
			width = 2.0,
			heading = 28.5636,
			minZ = 33.1,
			maxZ = 35.5
		}
	}
}
