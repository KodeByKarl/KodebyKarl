server_script '@Pandorangani/src/include/server.lua'
client_script '@Pandorangani/src/include/client.lua'
-- shared_script '@cfx-keydi-sentry/modules/secure/shared.lua'
-- Developed by clxsx999 - C-Scripts --
fx_version "cerulean"

game "gta5"
lua54 "yes"
name "kodebykarl-ambulance"
author "KodeByKarl"
version "0.0.1"
provide 'cfx-keydi-ambulance'
provide 'kodebykarl-pambulance'

dependencies {
    'es_extended',
    'ox_lib',
    'oxmysql',
    'ox_inventory',
    'cfx-keydi-society'
}

ui_page 'build/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/injury.lua',
    'helpers/notify.lua'
}

files{
    'build/assets/*',
    'build/logo.png',
    'build/sound/*',
    'build/index.html',
    'shared/*.lua',
    'helpers/*.lua',
    'actions/**/client.lua'
}

client_scripts {
    'modules/**/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'modules/logs/server.lua',
    'modules/core/server.lua',
    'modules/injury/server.lua',
    'modules/coin_farm/server.lua',
    'actions/**/server.lua'
}
