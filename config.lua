Config = {}

-- ████████████████████████████████████████████████████████████████
-- ██                     FRAMEWORK SETTINGS                     ██
-- ████████████████████████████████████████████████████████████████

-- Only ESX framework is supported
Config.Framework = 'ESX'
Config.ESXExport = 'es_extended'    -- ESX export name

-- ████████████████████████████████████████████████████████████████
-- ██                       DEBUG SETTINGS                        ██
-- ████████████████████████████████████████████████████████████████

-- Enable debug mode for detailed console logging
Config.Debug = false

-- ████████████████████████████████████████████████████████████████
-- ██                     LOCALE SETTINGS                        ██
-- ████████████████████████████████████████████████████████████████

-- Available locales: 'nl', 'en'
Config.Locale = 'en'

-- ████████████████████████████████████████████████████████████████
-- ██                  NOTIFICATION SETTINGS                     ██
-- ████████████████████████████████████████████████████████████████

-- Notification system to use
-- Options: 'lation_ui' (modern notifications), 'esx' (ESX.ShowNotification)
Config.NotificationSystem = 'lation_ui'

-- ████████████████████████████████████████████████████████████████
-- ██                      MENU SETTINGS                         ██
-- ████████████████████████████████████████████████████████████████

-- Menu system to use
-- Options: 'lation_ui' (modern UI), 'esx' (ESX.UI.Menu)
Config.MenuSystem = 'lation_ui'

-- ████████████████████████████████████████████████████████████████
-- ██                    PERMISSION SETTINGS                     ██
-- ████████████████████████████████████████████████████████████████

-- Permission system to use
-- Options: 'group' (ESX admin groups), 'license' (Rockstar license identifiers)
Config.PermissionSystem = 'group'

-- Admin groups that can use weather/time controls (only used if PermissionSystem = 'group')
Config.AdminGroups = {
    'admin',
    'superadmin',
    'owner'
}

-- Whitelisted license identifiers (only used if PermissionSystem = 'license')
-- Format: 'license:abc123' or just 'abc123'
Config.WhitelistedLicenses = {
    -- 'license:1b12505fa07d33d6f3f7',
    -- 'license:9i8h7g6f5e4d3c2b1a0j',
}

-- ████████████████████████████████████████████████████████████████
-- ██                      WEATHER SETTINGS                      ██
-- ████████████████████████████████████████████████████████████████

Config.Weather = {
    enableDynamic = true,          -- Enable automatic weather changes
    dynamicInterval = 30,           -- Minutes between automatic weather changes
    transitionTime = 45,            -- Seconds for smooth weather transitions
    defaultWeather = 'CLEAR',       -- Default weather on server start
    types = {                       -- Available weather types with labels and icons
        {name = 'CLEAR', icon = 'fa-sun'},
        {name = 'EXTRASUNNY', icon = 'fa-sun'},
        {name = 'CLOUDS', icon = 'fa-cloud'},
        {name = 'OVERCAST', icon = 'fa-cloud-sun'},
        {name = 'RAIN', icon = 'fa-cloud-rain'},
        {name = 'CLEARING', icon = 'fa-cloud-sun'},
        {name = 'THUNDER', icon = 'fa-cloud-bolt'},
        {name = 'SMOG', icon = 'fa-smog'},
        {name = 'FOGGY', icon = 'fa-smog'},
        {name = 'XMAS', icon = 'fa-snowflake'},
        {name = 'SNOWLIGHT', icon = 'fa-snowflake'},
        {name = 'BLIZZARD', icon = 'fa-wind'},
    },
    allowBlackout = true,           -- Allow admins to toggle blackout mode
}

-- ████████████████████████████████████████████████████████████████
-- ██                        TIME SETTINGS                       ██
-- ████████████████████████████████████████████████████████████████

Config.Time = {
    enableDynamic = true,           -- Enable time progression
    timeScale = 30,                 -- How many seconds IRL = 1 minute in-game (lower = faster)
    syncInterval = 5000,            -- Milliseconds between client time sync
    defaultHour = 12,               -- Default hour on server start (0-23)
    defaultMinute = 0,              -- Default minute on server start (0-59)
    freezeTime = false,             -- Start with time frozen
    presets = {                     -- Quick time presets shown in menu
        {hour = 6, minute = 0, key = 'time_sunrise'},
        {hour = 12, minute = 0, key = 'time_noon'},
        {hour = 18, minute = 0, key = 'time_sunset'},
        {hour = 0, minute = 0, key = 'time_midnight'},
    }
}

-- ████████████████████████████████████████████████████████████████
-- ██                     COMMAND SETTINGS                       ██
-- ████████████████████████████████████████████████████████████████

Config.Commands = {
    openMenu = 'weather',              -- Command to open weather/time menu
}

-- ████████████████████████████████████████████████████████████████
-- ██                    DATABASE SETTINGS                       ██
-- ████████████████████████████████████████████████████████████████

Config.Database = {
    enabled = true,                 -- Save weather/time state to database
    tableName = 'vogel_weather',    -- Database table name (auto-creates)
}

-- ████████████████████████████████████████████████████████████████
-- ██                      UI/UX SETTINGS                        ██
-- ████████████████████████████████████████████████████████████████

Config.UI = {
    showNotifications = true,       -- Show notifications for weather/time changes
    showAdminName = true,           -- Include admin name in notifications
    notificationDuration = 5000,    -- Notification duration in milliseconds
}

-- ████████████████████████████████████████████████████████████████
-- ██                    PERFORMANCE SETTINGS                    ██
-- ████████████████████████████████████████████████████████████████

Config.Performance = {
    weatherUpdateInterval = 100,    -- Milliseconds between weather updates (lower = smoother)
    timeUpdateInterval = 100,       -- Milliseconds between time updates (lower = smoother)
}
