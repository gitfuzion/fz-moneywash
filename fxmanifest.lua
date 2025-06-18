fx_version 'cerulean'
game 'gta5'

author 'Fuzion'
description 'A moneywash system for FiveM'
version 'v1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

lua54 'yes'