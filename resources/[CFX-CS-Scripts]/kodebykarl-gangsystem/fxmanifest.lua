fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'kodebykarl-gangsystem'
author 'KodeByKarl'
description 'Gang HQ zones, stashes, and boss gang menu'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'shared/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/stashes.lua',
    'server/boss.lua',
    'server/org.lua',
    'server/guncraft.lua',
    'server/claimcar.lua',
}

client_scripts {
    'client/main.lua',
    'client/zones.lua',
    'client/bossmenu.lua',
    'client/guncraft.lua',
    'client/claimcar.lua',
}

dependencies {
    'es_extended',
    'ox_lib',
    'ox_inventory',
    'ox_target',
    'cfx-keydi-society',
}
