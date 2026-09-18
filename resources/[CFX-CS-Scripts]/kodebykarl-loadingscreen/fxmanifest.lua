fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'kodebykarl-loadingscreen'
author 'KodeByKarl'
description 'Grim City loading screen'
version '1.0.0'

provide 'cfx-keydi-loadingscreen'

loadscreen 'html/index.html'
loadscreen_manual_shutdown 'yes'
loadscreen_cursor 'yes'

shared_script 'config.lua'

client_script 'client/main.lua'
server_script 'server/discord.lua'

files {
    'html/index.html',
    'html/assets/**/*',
}
