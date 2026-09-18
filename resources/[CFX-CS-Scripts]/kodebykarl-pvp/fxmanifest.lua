fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'kodebykarl-pvp'
author 'KodeByKarl'
description 'Deathmatch arena — iPad join, cfx-bwd-pvp gameplay (no stream)'
version '1.0.0'

dependencies {
    'es_extended',
    'ox_lib',
    'oxmysql',
    'ox_inventory',
    'ox_target',
}

provide 'cfx-bwd-pvp'

shared_scripts {
    '@ox_lib/init.lua',
    '@es_extended/imports.lua',
    'shared/config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/leaderboard.lua',
}
