shared_script '@cfx-cs-auth/shared_fg-obfuscated.lua'
shared_script '@cfx-cs-auth/shared_fg-obfuscated.lua'
fx_version 'cerulean'
games {'gta5'}
name 'kodebykarl-business'
author 'KodeByKarl'
description 'Business shops and crafting'
version '2.0'
lua54 'yes'
provide 'cfx-hu-business'
files {
    'locales/en.json'
}
shared_scripts{
    '@es_extended/imports.lua',
    '@ox_lib/init.lua'
}
client_scripts{
    'config.lua',
    'modules/utils.lua',
    'client/*.lua'
}
server_scripts{
    '@oxmysql/lib/MySQL.lua',
    'config.lua',
    'server/*.lua'
}server_scripts { '@mysql-async/lib/MySQL.lua' }