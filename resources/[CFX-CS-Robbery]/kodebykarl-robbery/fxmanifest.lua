fx_version 'cerulean'
use_experimental_fxv2_oal 'yes'
lua54 'yes'
game 'gta5'

name 'kodebykarl-robbery'
author 'KodeByKarl'
description 'Heists, house robbery, and interior shells'
version '1.0.0'

provide 'cfx-cs-robbery'
provide 'cfx-cs-interior'

this_is_a_map 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'init.lua',
    'shared/*.lua',
    'shared/heist/_init.lua',
    'shared/heist/big/*.lua',
    'shared/heist/stores/police/*.lua',
    'shared/heist/stores/sheriff/*.lua',
}

client_scripts {
    'modules/interior/main.lua',
    'modules/interior/optional.lua',
    'modules/**/client.lua'
}

server_scripts {
    'modules/**/server.lua'
}

-- House-rob shell: furnitured_midapart (from qb-interior / K4MB starter shells)
files {
    'stream/starter_shells_k4mb1.ytyp',
}

data_file 'DLC_ITYP_REQUEST' 'stream/starter_shells_k4mb1.ytyp'

dependencies {
    'es_extended',
    'ox_lib',
    'ox_inventory',
    'kodebykarl-ui',
}
