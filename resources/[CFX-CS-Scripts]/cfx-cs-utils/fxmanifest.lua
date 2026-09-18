fx_version 'cerulean'

games {'gta5'}
author 'clxsx'
description 'cfx-cs-utils'
version '2.0.0'
lua54 'yes'

-- ui_page 'build/index.html'

shared_scripts{
    '@ox_lib/init.lua',
    'init.lua' 
}

client_scripts{
    'modules/**/client.lua',
}

server_scripts{
    '@oxmysql/lib/MySQL.lua',
    'modules/**/server.lua'
}

files {
    'helpers/*.lua',
    'configs/*.lua',
    'build/assets/*',
    'build/index.html'
}

escrow_ignore{
    'helpers/*.lua',
    'configs/*.lua',
    'init.lua',
    'modules/**/server.lua'
}