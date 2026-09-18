fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'kodebykarl-turfwar'
author 'KodeByKarl'
description 'Modern Sequence Turf War System for GrimCity'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/zone.lua',
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
    'ox_inventory',
    'kodebykarl-ui',
}
