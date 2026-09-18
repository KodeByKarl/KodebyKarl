fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'kodebykarl-projectcars'
author 'KodeByKarl'
description 'Build a driveable car from a wrecked shell with 3D part installs'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@es_extended/imports.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

dependencies {
    'es_extended',
    'ox_lib',
    'ox_inventory',
    'oxmysql',
}

-- Copy files from install/ onto a fresh server (see install/README.md)
escrow_ignore {
    'config.lua',
    'README.md',
    'sql/**',
    'install/**',
}
