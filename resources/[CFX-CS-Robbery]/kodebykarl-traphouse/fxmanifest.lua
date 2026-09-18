fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'kodebykarl-traphouse'
author 'KodeByKarl'
description 'Ultra-Secured Unli TrapHouse RedZone & Kills System for GrimCity'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    '@es_extended/imports.lua',
    'server/webhook.lua',
    'server/main.lua'
}

dependencies {
    'es_extended',
    'ox_lib',
    'ox_inventory'
}
