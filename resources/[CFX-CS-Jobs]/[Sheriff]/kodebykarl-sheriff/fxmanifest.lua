fx_version 'cerulean'
game 'gta5'

name 'kodebykarl-sheriff'
author 'KodeByKarl'
description 'Blaine County Sheriff (BCSO) — uses kodebykarl-police LEO menu/cuffs; this resource owns the job + Paleto station'
version '1.0.0'
lua54 'yes'

provide 'cfx-cs-sheriff'

dependency 'kodebykarl-police'
dependency 'es_extended'
dependency 'ox_lib'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}
