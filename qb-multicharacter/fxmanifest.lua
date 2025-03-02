fx_version 'cerulean'
game 'gta5'

description 'QB-Multicharacter'
version '1.0.0'

ui_page 'html/index.html'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'locales/es.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/animations.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua', -- Añadir esta línea
    'server/main.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

lua54 'yes'

dependencies {
    'oxmysql', -- Añadir esta línea
    'qb-core'
}