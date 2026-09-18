fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'cfx-keydi-society'
author 'KodeByKarl'
description 'Society / job funds — stores balances in MySQL for jobs and gangs'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    '@es_extended/imports.lua',
    'server/main.lua',
    'server/esx_compat.lua',
}

files {
    'sql/install.sql',
}

dependencies {
    'oxmysql',
    'ox_lib',
    'es_extended',
}
