fx_version 'cerulean'
game 'gta5'

description 'JorgeDev Elevator System - Premium Elevator Creator'
author 'JorgeDev'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
    'client/admin.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/admin.lua',
    'server/version.lua',
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/script.js',
}

dependencies {
    'ox_lib',
    'oxmysql',
}
