-- ████████████████████████████████████████████████████████████████
-- ██                      VOGEL WEATHER SYSTEM                  ██
-- ██                         SERVER SIDE                        ██
-- ████████████████████████████████████████████████████████████████

ESX = exports[Config.ESXExport]:getSharedObject()

-- ████████████████████████████████████████████████████████████████
-- ██                       DEBUG FUNCTIONS                      ██
-- ████████████████████████████████████████████████████████████████

--- Debug print function
---@param message string Debug message
---@param data any Optional data to print
local function DebugPrint(message, data)
    if not Config.Debug then return end
    
    local prefix = '^3[VOGEL WEATHER DEBUG]^0'
    if data then
        print(prefix .. ' ' .. message .. ': ' .. json.encode(data, {indent = true}))
    else
        print(prefix .. ' ' .. message)
    end
end

-- ████████████████████████████████████████████████████████████████
-- ██                        GLOBAL STATE                        ██
-- ████████████████████████████████████████████████████████████████

local currentWeather = Config.Weather.defaultWeather
local currentHour = Config.Time.defaultHour
local currentMinute = Config.Time.defaultMinute
local isTimeFrozen = Config.Time.freezeTime
local isBlackoutActive = false
local isDynamicWeatherEnabled = Config.Weather.enableDynamic
local isDynamicTimeEnabled = Config.Time.enableDynamic
local timeScale = Config.Time.timeScale

-- ████████████████████████████████████████████████████████████████
-- ██                    DATABASE FUNCTIONS                      ██
-- ████████████████████████████████████████████████████████████████

--- Initialize database table
local function InitializeDatabase()
    if not Config.Database.enabled then 
        DebugPrint('Database disabled in config')
        return 
    end
    
    DebugPrint('Initializing database table: ' .. Config.Database.tableName)
    
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `]] .. Config.Database.tableName .. [[` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `weather` varchar(50) DEFAULT 'CLEAR',
            `hour` int(11) DEFAULT 12,
            `minute` int(11) DEFAULT 0,
            `time_frozen` tinyint(1) DEFAULT 0,
            `blackout` tinyint(1) DEFAULT 0,
            `dynamic_weather` tinyint(1) DEFAULT 1,
            `dynamic_time` tinyint(1) DEFAULT 1,
            `time_scale` int(11) DEFAULT 30,
            `last_updated` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    print('[^2VOGEL WEATHER^0] Database table initialized')
    DebugPrint('Database initialization complete')
end

--- Load saved weather/time state from database
local function LoadWeatherState()
    if not Config.Database.enabled then 
        DebugPrint('Database disabled, using default values')
        return 
    end
    
    DebugPrint('Loading weather state from database')
    
    local result = MySQL.query.await('SELECT * FROM ' .. Config.Database.tableName .. ' ORDER BY id DESC LIMIT 1')
    
    if result and result[1] then
        currentWeather = result[1].weather or Config.Weather.defaultWeather
        currentHour = result[1].hour or Config.Time.defaultHour
        currentMinute = result[1].minute or Config.Time.defaultMinute
        isTimeFrozen = result[1].time_frozen == 1
        isBlackoutActive = result[1].blackout == 1
        isDynamicWeatherEnabled = result[1].dynamic_weather == 1
        isDynamicTimeEnabled = result[1].dynamic_time == 1
        timeScale = result[1].time_scale or Config.Time.timeScale
        
        DebugPrint('Loaded saved state: ' .. currentWeather .. ' | ' .. currentHour .. ':' .. currentMinute)
        DebugPrint('Loaded state from database', {
            weather = currentWeather,
            time = currentHour .. ':' .. currentMinute,
            timeFrozen = isTimeFrozen,
            blackout = isBlackoutActive,
            dynamicWeather = isDynamicWeatherEnabled,
            dynamicTime = isDynamicTimeEnabled,
            timeScale = timeScale
        })
    else
        SaveWeatherState()
        DebugPrint('No saved state found, using defaults')
    end
end

--- Save current weather/time state to database
function SaveWeatherState()
    if not Config.Database.enabled then 
        DebugPrint('Database disabled, skipping save')
        return 
    end
    
    DebugPrint('Saving weather state to database', {
        weather = currentWeather,
        hour = currentHour,
        minute = currentMinute,
        timeFrozen = isTimeFrozen,
        blackout = isBlackoutActive,
        dynamicWeather = isDynamicWeatherEnabled,
        dynamicTime = isDynamicTimeEnabled,
        timeScale = timeScale
    })
    
    MySQL.query([[
        INSERT INTO ]] .. Config.Database.tableName .. [[ 
        (weather, hour, minute, time_frozen, blackout, dynamic_weather, dynamic_time, time_scale) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        currentWeather,
        currentHour,
        currentMinute,
        isTimeFrozen and 1 or 0,
        isBlackoutActive and 1 or 0,
        isDynamicWeatherEnabled and 1 or 0,
        isDynamicTimeEnabled and 1 or 0,
        timeScale
    })
end

-- ████████████████████████████████████████████████████████████████
-- ██                   PERMISSION FUNCTIONS                     ██
-- ████████████████████████████████████████████████████████████████

--- Check if player has admin permission
---@param source number Player server ID
---@return boolean hasPermission
local function HasPermission(source)
    DebugPrint('Checking permission for player: ' .. source, {
        permissionSystem = Config.PermissionSystem
    })
    
    if Config.PermissionSystem == 'license' then
        -- License-based permission check
        local identifiers = GetPlayerIdentifiers(source)
        DebugPrint('Checking license-based permissions', {
            identifiers = identifiers,
            whitelisted = Config.WhitelistedLicenses
        })
        
        for _, identifier in ipairs(identifiers) do
            if string.find(identifier, 'license:') then
                local license = string.gsub(identifier, 'license:', '')
                
                for _, whitelistedLicense in ipairs(Config.WhitelistedLicenses) do
                    local cleanWhitelist = string.gsub(whitelistedLicense, 'license:', '')
                    if license == cleanWhitelist then
                        DebugPrint('Player ' .. source .. ' has whitelisted license')
                        return true
                    end
                end
            end
        end
        
        DebugPrint('Player ' .. source .. ' does not have whitelisted license')
        return false
    elseif Config.PermissionSystem == 'group' then
        -- ESX group-based permission check
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then 
            DebugPrint('Player ' .. source .. ' not found in ESX')
            return false 
        end
        
        local playerGroup = xPlayer.getGroup()
        DebugPrint('Checking group-based permissions', {
            playerGroup = playerGroup,
            allowedGroups = Config.AdminGroups
        })
        
        for _, group in ipairs(Config.AdminGroups) do
            if playerGroup == group then
                DebugPrint('Player ' .. source .. ' has admin group: ' .. playerGroup)
                return true
            end
        end
        
        DebugPrint('Player ' .. source .. ' does not have admin group (current: ' .. playerGroup .. ')')
        return false
    end
    
    DebugPrint('Invalid permission system configured: ' .. Config.PermissionSystem)
    return false
end

-- ████████████████████████████████████████████████████████████████
-- ██                      TIME MANAGEMENT                       ██
-- ████████████████████████████████████████████████████████████████

--- Update game time for all players
local function UpdateTime()
    DebugPrint('Broadcasting time update', {
        hour = currentHour,
        minute = currentMinute,
        frozen = isTimeFrozen,
        scale = timeScale
    })
    TriggerClientEvent('vogel_weather:syncTime', -1, currentHour, currentMinute, isTimeFrozen, timeScale)
end

--- Progress time forward
local function ProgressTime()
    if isTimeFrozen or not isDynamicTimeEnabled then return end
    
    currentMinute += 1
    
    if currentMinute >= 60 then
        currentMinute = 0
        currentHour += 1
        
        if currentHour >= 24 then
            currentHour = 0
            DebugPrint('Time wrapped to new day')
        end
    end
    
    UpdateTime()
end

--- Set specific time
---@param hour number Hour (0-23)
---@param minute number Minute (0-59)
local function SetTime(hour, minute)
    DebugPrint('Setting time', {hour = hour, minute = minute})
    currentHour = hour
    currentMinute = minute
    UpdateTime()
    SaveWeatherState()
end

--- Toggle time freeze
local function ToggleTimeFrozen()
    isTimeFrozen = not isTimeFrozen
    DebugPrint('Time freeze toggled', {frozen = isTimeFrozen})
    UpdateTime()
    SaveWeatherState()
    return isTimeFrozen
end

--- Set time scale
---@param scale number Time progression multiplier
local function SetTimeScale(scale)
    DebugPrint('Setting time scale', {scale = scale})
    timeScale = scale
    UpdateTime()
    SaveWeatherState()
end

-- ████████████████████████████████████████████████████████████████
-- ██                     WEATHER MANAGEMENT                     ██
-- ████████████████████████████████████████████████████████████████

--- Update weather for all players
local function UpdateWeather()
    DebugPrint('Broadcasting weather update', {
        weather = currentWeather,
        blackout = isBlackoutActive,
        transitionTime = Config.Weather.transitionTime
    })
    TriggerClientEvent('vogel_weather:syncWeather', -1, currentWeather, isBlackoutActive, Config.Weather.transitionTime)
end

--- Set specific weather
---@param weatherType string Weather type name
local function SetWeather(weatherType)
    DebugPrint('Setting weather', {weatherType = weatherType})
    currentWeather = weatherType
    UpdateWeather()
    SaveWeatherState()
end

--- Toggle blackout mode
local function ToggleBlackout()
    if not Config.Weather.allowBlackout then 
        DebugPrint('Blackout not allowed in config')
        return false 
    end
    
    isBlackoutActive = not isBlackoutActive
    DebugPrint('Blackout toggled', {active = isBlackoutActive})
    UpdateWeather()
    SaveWeatherState()
    return isBlackoutActive
end

--- Set random weather (for dynamic system)
local function SetRandomWeather()
    if not isDynamicWeatherEnabled then return end
    
    local availableWeathers = Config.Weather.types
    local randomIndex = math.random(1, #availableWeathers)
    local newWeather = availableWeathers[randomIndex].name
    DebugPrint('Dynamic weather change', {newWeather = newWeather})
    SetWeather(newWeather)
end

-- ████████████████████████████████████████████████████████████████
-- ██                      SERVER EVENTS                         ██
-- ████████████████████████████████████████████████████████████████

--- Handle weather change request
RegisterNetEvent('vogel_weather:changeWeather', function(weatherType, adminName)
    local src = source
    
    if not HasPermission(src) then
        TriggerClientEvent('vogel_weather:notify', src, _('no_permission'), 'error')
        return
    end
    
    SetWeather(weatherType)
    
    if Config.UI.showNotifications then
        if Config.UI.showAdminName and adminName then
            TriggerClientEvent('vogel_weather:notify', -1, _('weather_changed_by', weatherType, adminName), 'success')
        else
            TriggerClientEvent('vogel_weather:notify', -1, _('weather_changed', weatherType), 'success')
        end
    end
end)

--- Handle time change request
RegisterNetEvent('vogel_weather:changeTime', function(hour, minute, adminName)
    local src = source
    
    if not HasPermission(src) then
        TriggerClientEvent('vogel_weather:notify', src, _('no_permission'), 'error')
        return
    end
    
    SetTime(hour, minute)
    
    if Config.UI.showNotifications then
        local timeStr = string.format('%02d:%02d', hour, minute)
        if Config.UI.showAdminName and adminName then
            TriggerClientEvent('vogel_weather:notify', -1, _('time_changed_by', timeStr, adminName), 'success')
        else
            TriggerClientEvent('vogel_weather:notify', -1, _('time_changed', timeStr), 'success')
        end
    end
end)

--- Handle time freeze toggle
RegisterNetEvent('vogel_weather:toggleTimeFrozen', function(adminName)
    local src = source
    
    if not HasPermission(src) then
        TriggerClientEvent('vogel_weather:notify', src, _('no_permission'), 'error')
        return
    end
    
    local frozen = ToggleTimeFrozen()
    
    if Config.UI.showNotifications then
        if frozen then
            if Config.UI.showAdminName and adminName then
                TriggerClientEvent('vogel_weather:notify', -1, _('time_frozen_by', adminName), 'success')
            else
                TriggerClientEvent('vogel_weather:notify', -1, _('time_frozen'), 'success')
            end
        else
            if Config.UI.showAdminName and adminName then
                TriggerClientEvent('vogel_weather:notify', -1, _('time_resumed_by', adminName), 'success')
            else
                TriggerClientEvent('vogel_weather:notify', -1, _('time_resumed'), 'success')
            end
        end
    end
end)

--- Handle blackout toggle
RegisterNetEvent('vogel_weather:toggleBlackout', function(adminName)
    local src = source
    
    if not HasPermission(src) then
        TriggerClientEvent('vogel_weather:notify', src, _('no_permission'), 'error')
        return
    end
    
    local active = ToggleBlackout()
    
    if Config.UI.showNotifications then
        if active then
            if Config.UI.showAdminName and adminName then
                TriggerClientEvent('vogel_weather:notify', -1, _('blackout_enabled_by', adminName), 'success')
            else
                TriggerClientEvent('vogel_weather:notify', -1, _('blackout_enabled'), 'success')
            end
        else
            if Config.UI.showAdminName and adminName then
                TriggerClientEvent('vogel_weather:notify', -1, _('blackout_disabled_by', adminName), 'success')
            else
                TriggerClientEvent('vogel_weather:notify', -1, _('blackout_disabled'), 'success')
            end
        end
    end
end)

--- Handle time scale change
RegisterNetEvent('vogel_weather:changeTimeScale', function(scale, adminName)
    local src = source
    
    if not HasPermission(src) then
        TriggerClientEvent('vogel_weather:notify', src, _('no_permission'), 'error')
        return
    end
    
    SetTimeScale(scale)
    
    if Config.UI.showNotifications then
        if Config.UI.showAdminName and adminName then
            TriggerClientEvent('vogel_weather:notify', -1, _('time_scale_changed_by', scale, adminName), 'success')
        else
            TriggerClientEvent('vogel_weather:notify', -1, _('time_scale_changed', scale), 'success')
        end
    end
end)

--- Handle dynamic weather toggle
RegisterNetEvent('vogel_weather:toggleDynamicWeather', function(adminName)
    local src = source
    
    if not HasPermission(src) then
        TriggerClientEvent('vogel_weather:notify', src, _('no_permission'), 'error')
        return
    end
    
    isDynamicWeatherEnabled = not isDynamicWeatherEnabled
    SaveWeatherState()
    
    if Config.UI.showNotifications then
        if isDynamicWeatherEnabled then
            if Config.UI.showAdminName and adminName then
                TriggerClientEvent('vogel_weather:notify', -1, _('dynamic_weather_enabled_by', adminName), 'success')
            else
                TriggerClientEvent('vogel_weather:notify', -1, _('dynamic_weather_enabled'), 'success')
            end
        else
            if Config.UI.showAdminName and adminName then
                TriggerClientEvent('vogel_weather:notify', -1, _('dynamic_weather_disabled_by', adminName), 'success')
            else
                TriggerClientEvent('vogel_weather:notify', -1, _('dynamic_weather_disabled'), 'success')
            end
        end
    end
end)

--- Handle dynamic time toggle
RegisterNetEvent('vogel_weather:toggleDynamicTime', function(adminName)
    local src = source
    
    if not HasPermission(src) then
        TriggerClientEvent('vogel_weather:notify', src, _('no_permission'), 'error')
        return
    end
    
    isDynamicTimeEnabled = not isDynamicTimeEnabled
    SaveWeatherState()
    
    if Config.UI.showNotifications then
        if isDynamicTimeEnabled then
            if Config.UI.showAdminName and adminName then
                TriggerClientEvent('vogel_weather:notify', -1, _('dynamic_time_enabled_by', adminName), 'success')
            else
                TriggerClientEvent('vogel_weather:notify', -1, _('dynamic_time_enabled'), 'success')
            end
        else
            if Config.UI.showAdminName and adminName then
                TriggerClientEvent('vogel_weather:notify', -1, _('dynamic_time_disabled_by', adminName), 'success')
            else
                TriggerClientEvent('vogel_weather:notify', -1, _('dynamic_time_disabled'), 'success')
            end
        end
    end
end)

--- Send current state to client
RegisterNetEvent('vogel_weather:requestSync', function()
    local src = source
    TriggerClientEvent('vogel_weather:syncWeather', src, currentWeather, isBlackoutActive, 0)
    TriggerClientEvent('vogel_weather:syncTime', src, currentHour, currentMinute, isTimeFrozen, timeScale)
end)

--- Get current state (for menu)
lib.callback.register('vogel_weather:getState', function(source)
    if not HasPermission(source) then
        return nil
    end
    
    return {
        weather = currentWeather,
        hour = currentHour,
        minute = currentMinute,
        timeFrozen = isTimeFrozen,
        blackout = isBlackoutActive,
        dynamicWeather = isDynamicWeatherEnabled,
        dynamicTime = isDynamicTimeEnabled,
        timeScale = timeScale
    }
end)

-- ████████████████████████████████████████████████████████████████
-- ██                      SERVER THREADS                        ██
-- ████████████████████████████████████████████████████████████████

--- Time progression thread
CreateThread(function()
    while true do
        Wait(60000 / timeScale) -- 1 in-game minute
        ProgressTime()
    end
end)

--- Dynamic weather change thread
CreateThread(function()
    while true do
        Wait(Config.Weather.dynamicInterval * 60000) -- Convert to milliseconds
        SetRandomWeather()
    end
end)

--- Periodic time sync thread
CreateThread(function()
    while true do
        Wait(Config.Time.syncInterval)
        UpdateTime()
    end
end)

-- ████████████████████████████████████████████████████████████████
-- ██                    RESOURCE LIFECYCLE                      ██
-- ████████████████████████████████████████████████████████████████

--- Initialize on resource start
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    print('[^2VOGEL WEATHER^0] Initializing...')
    InitializeDatabase()
    Wait(500)
    LoadWeatherState()
    UpdateWeather()
    UpdateTime()
    DebugPrint('System started successfully')
end)

--- Save state on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    SaveWeatherState()
    DebugPrint('State saved, shutting down')
end)
