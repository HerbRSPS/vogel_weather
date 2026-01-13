fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Vogel'
description 'Advanced Weather & Time Control System - ESX Framework'
version '1.2.1'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config.lua',
    'locales/locale.lua',
    'locales/nl.lua',
    'locales/en.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'es_extended',
    'ox_lib',
    'lation_ui',
    'oxmysql'
}
