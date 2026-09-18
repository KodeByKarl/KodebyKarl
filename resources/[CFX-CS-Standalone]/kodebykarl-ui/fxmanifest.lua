fx_version 'cerulean'
use_experimental_fxv2_oal 'yes'
game { 'gta5' }

author 'Antigravity'
description 'Grim kodebykarl UI modules'
version '1.0.0'

lua54 'yes'

-- Drop-in for robbery / scripts that still export cfx-cs-scoreboard
provide 'cfx-cs-scoreboard'
-- Drop-in for scripts that still export cfx-keydi-ui
provide 'cfx-keydi-ui'
-- Drop-in for scripts that still export cfx-cs-chat
provide 'cfx-cs-chat'
-- Drop-in for scripts that depend on / export xsound audio engine
provide 'xsound'
-- Drop-in for identity / cfx-keydi-identity
provide 'esx_identity'

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/assets/**/*',
    'Module/welcomebanner/sounds/**/*',
    'Module/welcomebanner/images/**/*',
    'Module/welcomebanner/data/*.json',
    'Module/cfx-keydi-invoice/sql/*.sql',
    'Module/cfx-keydi-playtimeshop/sql/*.sql',
    'Module/cfx-keydi-vip/sql/*.sql',
    'Module/cfx-keydi-ipad/sql/*.sql',
    'Module/cfx-keydi-ipad/server/dept.lua',
    'Module/cfx-keydi-university/sql/*.sql',
    'Module/cfx-keydi-market/phone/**/*',
}

shared_scripts {
    '@ox_lib/init.lua',
    '@es_extended/imports.lua',
    'Module/cfx-keydi-identity/shared/config.lua',
    'Module/cfx-keydi-identity/shared/constants.lua',
    'Module/cfx-keydi-identity/shared/utils.lua',
    'Module/cfx-keydi-badge/shared/config.lua',
    'Module/cfx-keydi-radiolist/shared/config.lua',
    'Module/cfx-keydi-scoreboard/shared/config.lua',
    'Module/cfx-keydi-indicator/shared/config.lua',
    'Module/cfx-keydi-deathscreen/shared/config.lua',
    'Module/cfx-keydi-deathscreen/shared/bones.lua',
    'Module/cfx-keydi-chat/shared/config.lua',
    'Module/cfx-keydi-modules/shared/config.lua',
    'Module/cfx-keydi-serverlocations/shared/config.lua',
    'Module/cfx-keydi-fps/shared/config.lua',
    'Module/cfx-keydi-report/shared/config.lua',
    'Module/cfx-keydi-banking/shared/config.lua',
    'Module/cfx-keydi-autofarm/shared/config.lua',
    'Module/cfx-keydi-market/shared/config.lua',
    'Module/cfx-keydi-weedfarm/shared/config.lua',
    'Module/cfx-keydi-chopshop/shared/config.lua',
    'Module/cfx-keydi-welcome/sh_welcome.lua',
    'Module/welcomebanner/shared/config.lua',
    'Module/cfx-keydi-comserv/shared/config.lua',
    'Module/cfx-keydi-lockscript/shared/config.lua',
    'Module/cfx-keydi-carlock/shared/config.lua',
    'Module/cfx-keydi-invoice/shared/config.lua',
    'Module/cfx-keydi-ipad/shared/config.lua',
    'Module/cfx-keydi-playtimeshop/shared/config.lua',
    'Module/cfx-keydi-vip/shared/config.lua',
    'Module/cfx-keydi-university/shared/config.lua',
}

client_scripts {
    'Module/cfx-keydi-identity/client/main.lua',
    'Module/cfx-keydi-identity/client/nui.lua',
    'Module/cfx-keydi-identity/client/events.lua',
    'Module/cfx-keydi-identity/client/commands.lua',
    'Module/cfx-keydi-badge/client/main.lua',
    'Module/cfx-keydi-radiolist/client/main.lua',
    'Module/cfx-keydi-scoreboard/client/main.lua',
    'Module/cfx-keydi-indicator/client/main.lua',
    'Module/cfx-keydi-chat/client/main.lua',
    'Module/cfx-keydi-chat/client/auto_templates.lua',

    'Module/cfx-keydi-modules/client/main.lua',
    'Module/cfx-keydi-serverlocations/client/main.lua',
    'Module/cfx-keydi-fps/client/main.lua',
    'Module/cfx-keydi-report/client/main.lua',
    'Module/cfx-keydi-banking/client/main.lua',
    'Module/cfx-keydi-autofarm/client/main.lua',
    'Module/cfx-keydi-market/client/main.lua',
    'Module/cfx-keydi-market/client/phone.lua',
    'Module/cfx-keydi-weedfarm/client/main.lua',
    'Module/cfx-keydi-chopshop/client/main.lua',
    'Module/cfx-keydi-welcome/client/main.lua',
    'Module/welcomebanner/client/main.lua',
    'Module/cfx-keydi-comserv/client/main.lua',
    'Module/cfx-keydi-lockscript/client/main.lua',
    'Module/cfx-keydi-lockscript/client/adapter_illenium.lua',
    'Module/cfx-keydi-carlock/client/main.lua',
    'Module/cfx-keydi-invoice/client/main.lua',
    'Module/cfx-keydi-ipad/client/main.lua',
    'Module/cfx-keydi-ipad/client/party.lua',
    'Module/cfx-keydi-playtimeshop/client/main.lua',
    'Module/cfx-keydi-vip/client/main.lua',
    'Module/cfx-keydi-university/client/main.lua',
    'Module/cfx-keydi-deathscreen/client/main.lua',
    'Module/cfx-keydi-raven/raven.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'Module/cfx-keydi-modules/server/electron.lua',
    'Module/cfx-keydi-identity/server/database.lua',
    'Module/cfx-keydi-identity/server/main.lua',
    'Module/cfx-keydi-identity/server/callbacks.lua',
    'Module/cfx-keydi-identity/server/events.lua',
    'Module/cfx-keydi-badge/server/main.lua',
    'Module/cfx-keydi-radiolist/server/main.lua',
    'Module/cfx-keydi-scoreboard/server/main.lua',
    'Module/cfx-keydi-indicator/server/main.lua',
    'Module/cfx-keydi-chat/server/main.lua',
    'Module/cfx-keydi-chat/server/commands.lua',
    'Module/cfx-keydi-chat/server/exports.lua',
    'Module/cfx-keydi-modules/server/main.lua',
    'Module/cfx-keydi-serverlocations/server/main.lua',
    'Module/cfx-keydi-modules/server/multijob.lua',
    'Module/cfx-keydi-report/server/main.lua',
    'Module/cfx-keydi-banking/server/logs.lua',
    'Module/cfx-keydi-banking/server/main.lua',
    'Module/cfx-keydi-playtimeshop/server/main.lua',
    'Module/cfx-keydi-autofarm/server/main.lua',
    'Module/cfx-keydi-market/server/main.lua',
    'Module/cfx-keydi-weedfarm/server/main.lua',
    'Module/cfx-keydi-chopshop/server/main.lua',
    'Module/cfx-keydi-welcome/server/main.lua',
    'Module/welcomebanner/server/main.lua',
    'Module/cfx-keydi-comserv/server/logs.lua',
    'Module/cfx-keydi-comserv/server/main.lua',
    'Module/cfx-keydi-lockscript/server/locks.lua',
    'Module/cfx-keydi-lockscript/server/logs.lua',
    'Module/cfx-keydi-lockscript/server/main.lua',
    'Module/cfx-keydi-carlock/server/main.lua',
    'Module/cfx-keydi-invoice/server/main.lua',
    'Module/cfx-keydi-ipad/server/economy.lua',
    'Module/cfx-keydi-ipad/server/dept.lua',
    'Module/cfx-keydi-ipad/server/business.lua',
    'Module/cfx-keydi-ipad/server/party.lua',
    'Module/cfx-keydi-ipad/server/leaderboard.lua',
    'Module/cfx-keydi-vip/server/main.lua',
    'Module/cfx-keydi-university/server/main.lua',
    'Module/cfx-keydi-deathscreen/server/main.lua',
    'Module/cfx-keydi-raven/raven.lua',
}

dependencies {
    'es_extended',
    'oxmysql',
    'ox_lib',
    'ox_inventory',
    'ox_target',
    -- 'pma-voice',
    -- 'cfx-keydi-radio',
    -- '/assetpacks',
}

-- Keep configs / locales editable after Keymaster escrow (Lua + stream are encrypted)
escrow_ignore {
    'Module/**/shared/config.lua',
    'Module/welcomebanner/sounds/**/*',
    'Module/welcomebanner/images/**/*',
    'Module/welcomebanner/data/*.json',
    'Module/cfx-keydi-welcome/sh_welcome.lua',
    'Module/cfx-keydi-raven/raven.lua',
}
