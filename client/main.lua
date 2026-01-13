-- ████████████████████████████████████████████████████████████████
-- ██                      VOGEL WEATHER SYSTEM                  ██
-- ██                         CLIENT SIDE                        ██
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
-- ██                        CLIENT STATE                        ██
-- ████████████████████████████████████████████████████████████████

local currentWeather = Config.Weather.defaultWeather
local targetWeather = Config.Weather.defaultWeather
local currentHour = Config.Time.defaultHour
local currentMinute = Config.Time.defaultMinute
local isTimeFrozen = false
local isBlackoutActive = false
local timeScale = Config.Time.timeScale
local weatherTransitionProgress = 1.0
local isTransitioning = false

-- ████████████████████████████████████████████████████████████████
-- ██                      WEATHER FUNCTIONS                     ██
-- ████████████████████████████████████████████████████████████████

--- Set weather with smooth transition
---@param newWeather string Target weather type
---@param transitionTime number Transition duration in seconds
local function SetWeatherTransition(newWeather, transitionTime)
    if newWeather == currentWeather then 
        DebugPrint('Weather already set to: ' .. newWeather)
        return 
    end
    
    DebugPrint('Starting weather transition', {
        from = currentWeather,
        to = newWeather,
        transitionTime = transitionTime
    })
    
    targetWeather = newWeather
    currentWeather = newWeather
    
    if transitionTime > 0 then
        isTransitioning = true
        weatherTransitionProgress = 0.0
        
        CreateThread(function()
            SetWeatherTypeOvertimePersist(newWeather, transitionTime)
            
            local startTime = GetGameTimer()
            local duration = transitionTime * 1000
            
            while weatherTransitionProgress < 1.0 do
                Wait(100)
                local elapsed = GetGameTimer() - startTime
                weatherTransitionProgress = math.min(elapsed / duration, 1.0)
            end
            
            isTransitioning = false
            SetWeatherTypePersist(newWeather)
            SetWeatherTypeNow(newWeather)
            DebugPrint('Weather transition complete: ' .. newWeather)
        end)
    else
        SetWeatherTypePersist(newWeather)
        SetWeatherTypeNow(newWeather)
        DebugPrint('Weather set instantly: ' .. newWeather)
    end
end

--- Apply blackout effect
local function ApplyBlackout(active)
    DebugPrint('Applying blackout', {active = active})
    isBlackoutActive = active
    SetArtificialLightsState(active)
    SetArtificialLightsStateAffectsVehicles(false)
end

-- ████████████████████████████████████████████████████████████████
-- ██                       TIME FUNCTIONS                       ██
-- ████████████████████████████████████████████████████████████████

--- Update game time
local function UpdateGameTime()
    NetworkOverrideClockTime(currentHour, currentMinute, 0)
end

--- Format time as HH:MM string
---@param hour number Hour (0-23)
---@param minute number Minute (0-59)
---@return string formattedTime
local function FormatTime(hour, minute)
    return string.format('%02d:%02d', hour, minute)
end

-- ████████████████████████████████████████████████████████████████
-- ██                      UI MENU SYSTEM                        ██
-- ████████████████████████████████████████████████████████████████

--- Show notification using configured system
---@param message string Notification message
---@param type string Notification type (success, error, info)
local function ShowNotification(message, type)
    if Config.NotificationSystem == 'lation_ui' then
        exports['lation_ui']:notify({
            title = _('menu_title'),
            description = message,
            type = type or 'info',
            duration = Config.UI.notificationDuration
        })
    elseif Config.NotificationSystem == 'esx' then
        if type == 'error' then
            ESX.ShowNotification('~r~' .. message)
        elseif type == 'success' then
            ESX.ShowNotification('~g~' .. message)
        else
            ESX.ShowNotification(message)
        end
    end
end

local function OpenWeatherMenu()
    local weatherOptions = {}
    
    for i, weather in ipairs(Config.Weather.types) do
        local label = _('weather_' .. string.lower(weather.name))
        local isActive = (currentWeather == weather.name)
        
        weatherOptions[#weatherOptions + 1] = {
            title = label,
            description = _('change_weather_to', label),
            icon = weather.icon,
            iconColor = isActive and '#4CAF50' or '#FFFFFF',
            value = weather.name,
            onSelect = function()
                local playerName = GetPlayerName(PlayerId())
                TriggerServerEvent('vogel_weather:changeWeather', weather.name, playerName)
            end
        }
    end
    
    if Config.Weather.allowBlackout then
        weatherOptions[#weatherOptions + 1] = {
            title = _('blackout'),
            description = isBlackoutActive and _('blackout_disable') or _('blackout_enable'),
            icon = 'fa-lightbulb',
            iconColor = isBlackoutActive and '#FF9800' or '#FFFFFF',
            onSelect = function()
                local playerName = GetPlayerName(PlayerId())
                TriggerServerEvent('vogel_weather:toggleBlackout', playerName)
            end
        }
    end
    
    if Config.MenuSystem == 'lation_ui' then
        exports['lation_ui']:registerMenu({
            id = 'vogel_weather_weather_menu',
            title = _('weather_menu_title'),
            menu = 'vogel_weather_main',
            position = 'top-right',
            options = weatherOptions
        })
        exports['lation_ui']:showMenu('vogel_weather_weather_menu')
    elseif Config.MenuSystem == 'esx' then
        local elements = {}
        for _, option in ipairs(weatherOptions) do
            elements[#elements + 1] = {
                label = option.title,
                value = option.value or option.title,
                name = option.title
            }
        end
        
        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'weather_menu', {
            title = _('weather_menu_title'),
            align = 'top-right',
            elements = elements
        }, function(data, menu)
            for _, option in ipairs(weatherOptions) do
                if (option.value and option.value == data.current.value) or option.title == data.current.label then
                    if option.onSelect then
                        option.onSelect()
                    end
                    break
                end
            end
        end, function(data, menu)
            menu.close()
        end)
    end
end

local function OpenTimeMenu()
    local timeOptions = {}
    
    for i, preset in ipairs(Config.Time.presets) do
        local label = preset.key and _(preset.key) or _('time_custom')
        
        timeOptions[#timeOptions + 1] = {
            title = label,
            description = _('time_changed', FormatTime(preset.hour, preset.minute)),
            icon = 'fa-clock',
            value = 'preset_' .. i,
            preset = preset,
            onSelect = function()
                local playerName = GetPlayerName(PlayerId())
                TriggerServerEvent('vogel_weather:changeTime', preset.hour, preset.minute, playerName)
            end
        }
    end
    
    timeOptions[#timeOptions + 1] = {
        title = _('time_custom'),
        description = _('time_custom_desc'),
        icon = 'fa-clock',
        value = 'custom',
        onSelect = function()
            if Config.MenuSystem == 'lation_ui' then
                local input = exports['lation_ui']:input({
                    title = _('input_time_title'),
                    options = {
                        {type = 'number', label = _('input_hour'), placeholder = '12', min = 0, max = 23, required = true},
                        {type = 'number', label = _('input_minute'), placeholder = '0', min = 0, max = 59, required = true}
                    }
                })
                
                if input and input[1] and input[2] then
                    local hour = tonumber(input[1])
                    local minute = tonumber(input[2])
                    if hour and minute then
                        local playerName = GetPlayerName(PlayerId())
                        TriggerServerEvent('vogel_weather:changeTime', hour, minute, playerName)
                    end
                end
            elseif Config.MenuSystem == 'esx' then
                ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'time_hour_input', {
                    title = _('input_hour')
                }, function(data, menu)
                    local hour = tonumber(data.value)
                    if hour and hour >= 0 and hour <= 23 then
                        menu.close()
                        ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'time_minute_input', {
                            title = _('input_minute')
                        }, function(data2, menu2)
                            local minute = tonumber(data2.value)
                            if minute and minute >= 0 and minute <= 59 then
                                menu2.close()
                                local playerName = GetPlayerName(PlayerId())
                                TriggerServerEvent('vogel_weather:changeTime', hour, minute, playerName)
                            else
                                ShowNotification('Invalid minute (0-59)', 'error')
                            end
                        end, function(data2, menu2)
                            menu2.close()
                        end)
                    else
                        ShowNotification('Invalid hour (0-23)', 'error')
                    end
                end, function(data, menu)
                    menu.close()
                end)
            end
        end
    }
    
    timeOptions[#timeOptions + 1] = {
        title = _('time_freeze'),
        description = isTimeFrozen and _('time_resume_desc') or _('time_freeze_desc'),
        icon = 'fa-pause',
        iconColor = isTimeFrozen and '#FF9800' or '#FFFFFF',
        value = 'freeze',
        onSelect = function()
            local playerName = GetPlayerName(PlayerId())
            TriggerServerEvent('vogel_weather:toggleTimeFrozen', playerName)
        end
    }
    
    if Config.MenuSystem == 'lation_ui' then
        exports['lation_ui']:registerMenu({
            id = 'vogel_weather_time_menu',
            title = _('time_menu_title'),
            menu = 'vogel_weather_main',
            position = 'top-right',
            options = timeOptions
        })
        exports['lation_ui']:showMenu('vogel_weather_time_menu')
    elseif Config.MenuSystem == 'esx' then
        local elements = {}
        for _, option in ipairs(timeOptions) do
            elements[#elements + 1] = {
                label = option.title,
                value = option.value,
                name = option.title
            }
        end
        
        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'time_menu', {
            title = _('time_menu_title'),
            align = 'top-right',
            elements = elements
        }, function(data, menu)
            for _, option in ipairs(timeOptions) do
                if option.value == data.current.value then
                    if option.onSelect then
                        option.onSelect()
                    end
                    break
                end
            end
        end, function(data, menu)
            menu.close()
        end)
    end
end

local function OpenTimeScaleMenu()
    local scaleOptions = {1, 2, 5, 10, 20, 30, 50, 100, 200}
    local menuOptions = {}
    
    for i, scale in ipairs(scaleOptions) do
        local isCurrentScale = (timeScale == scale)
        
        menuOptions[#menuOptions + 1] = {
            title = _('time_scale_speed', scale),
            description = _('time_scale_desc', scale),
            icon = 'fa-forward',
            iconColor = isCurrentScale and '#4CAF50' or '#FFFFFF',
            value = scale,
            onSelect = function()
                local playerName = GetPlayerName(PlayerId())
                TriggerServerEvent('vogel_weather:changeTimeScale', scale, playerName)
            end
        }
    end
    
    if Config.MenuSystem == 'lation_ui' then
        exports['lation_ui']:registerMenu({
            id = 'vogel_weather_timescale_menu',
            title = _('time_scale_menu_title'),
            menu = 'vogel_weather_main',
            position = 'top-right',
            options = menuOptions
        })
        exports['lation_ui']:showMenu('vogel_weather_timescale_menu')
    elseif Config.MenuSystem == 'esx' then
        local elements = {}
        for _, option in ipairs(menuOptions) do
            elements[#elements + 1] = {
                label = option.title,
                value = option.value,
                name = option.title
            }
        end
        
        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'timescale_menu', {
            title = _('time_scale_menu_title'),
            align = 'top-right',
            elements = elements
        }, function(data, menu)
            for _, option in ipairs(menuOptions) do
                if option.value == data.current.value then
                    if option.onSelect then
                        option.onSelect()
                    end
                    break
                end
            end
        end, function(data, menu)
            menu.close()
        end)
    end
end

local function OpenMainMenu()
    DebugPrint('Opening main menu')
    
    local state = lib.callback.await('vogel_weather:getState', false)
    
    if not state then
        DebugPrint('Permission denied for menu access')
        ShowNotification(_('no_permission'), 'error')
        return
    end
    
    DebugPrint('Received state from server', state)
    
    currentWeather = state.weather
    currentHour = state.hour
    currentMinute = state.minute
    isTimeFrozen = state.timeFrozen
    isBlackoutActive = state.blackout
    timeScale = state.timeScale
    
    local mainOptions = {
        {
            title = _('weather_control'),
            description = _('weather_control_desc', currentWeather),
            icon = 'fa-cloud-sun',
            iconColor = '#2196F3',
            value = 'weather',
            onSelect = function()
                OpenWeatherMenu()
            end
        },
        {
            title = _('time_control'),
            description = _('time_control_desc', FormatTime(currentHour, currentMinute)),
            icon = 'fa-clock',
            iconColor = '#4CAF50',
            value = 'time',
            onSelect = function()
                OpenTimeMenu()
            end
        },
        {
            title = _('time_scale_control'),
            description = _('time_scale_control_desc', timeScale),
            icon = 'fa-gauge-high',
            iconColor = '#FF9800',
            value = 'scale',
            onSelect = function()
                OpenTimeScaleMenu()
            end
        },
        {
            title = _('dynamic_weather'),
            description = state.dynamicWeather and _('dynamic_weather_enabled_desc') or _('dynamic_weather_disabled_desc'),
            icon = 'fa-arrows-rotate',
            iconColor = state.dynamicWeather and '#4CAF50' or '#757575',
            value = 'dynamic_weather',
            onSelect = function()
                local playerName = GetPlayerName(PlayerId())
                TriggerServerEvent('vogel_weather:toggleDynamicWeather', playerName)
            end
        },
        {
            title = _('dynamic_time'),
            description = state.dynamicTime and _('dynamic_time_enabled_desc') or _('dynamic_time_disabled_desc'),
            icon = 'fa-arrows-rotate',
            iconColor = state.dynamicTime and '#4CAF50' or '#757575',
            value = 'dynamic_time',
            onSelect = function()
                local playerName = GetPlayerName(PlayerId())
                TriggerServerEvent('vogel_weather:toggleDynamicTime', playerName)
            end
        }
    }
    
    if Config.MenuSystem == 'lation_ui' then
        exports['lation_ui']:registerMenu({
            id = 'vogel_weather_main',
            title = _('menu_title'),
            subtitle = _('menu_subtitle'),
            position = 'top-right',
            options = mainOptions
        })
        exports['lation_ui']:showMenu('vogel_weather_main')
    elseif Config.MenuSystem == 'esx' then
        local elements = {}
        for _, option in ipairs(mainOptions) do
            elements[#elements + 1] = {
                label = option.title,
                value = option.value,
                name = option.title
            }
        end
        
        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'main_menu', {
            title = _('menu_title'),
            align = 'top-right',
            elements = elements
        }, function(data, menu)
            for _, option in ipairs(mainOptions) do
                if option.value == data.current.value then
                    if option.onSelect then
                        option.onSelect()
                    end
                    break
                end
            end
        end, function(data, menu)
            menu.close()
        end)
    end
end

-- ████████████████████████████████████████████████████████████████
-- ██                      CLIENT EVENTS                         ██
-- ████████████████████████████████████████████████████████████████

--- Sync weather from server
RegisterNetEvent('vogel_weather:syncWeather', function(weather, blackout, transitionTime)
    DebugPrint('Received weather sync from server', {
        weather = weather,
        blackout = blackout,
        transitionTime = transitionTime
    })
    SetWeatherTransition(weather, transitionTime)
    ApplyBlackout(blackout)
end)

--- Sync time from server
RegisterNetEvent('vogel_weather:syncTime', function(hour, minute, frozen, scale)
    DebugPrint('Received time sync from server', {
        hour = hour,
        minute = minute,
        frozen = frozen,
        scale = scale
    })
    currentHour = hour
    currentMinute = minute
    isTimeFrozen = frozen
    timeScale = scale
    UpdateGameTime()
end)

--- Show notification
RegisterNetEvent('vogel_weather:notify', function(message, type)
    ShowNotification(message, type)
end)

-- ████████████████████████████████████████████████████████████████
-- ██                      CLIENT COMMANDS                       ██
-- ████████████████████████████████████████████████████████████████

--- Main menu command
RegisterCommand(Config.Commands.openMenu, function()
    OpenMainMenu()
end, false)

-- ████████████████████████████████████████████████████████████████
-- ██                      CLIENT THREADS                        ██
-- ████████████████████████████████████████████████████████████████

--- Weather update thread
CreateThread(function()
    while true do
        Wait(Config.Performance.weatherUpdateInterval)
        
        -- Only enforce weather when not transitioning
        if not isTransitioning then
            SetWeatherTypePersist(currentWeather)
        end
        
        -- Maintain blackout state
        if isBlackoutActive then
            SetArtificialLightsState(true)
        end
    end
end)

--- Time update thread
CreateThread(function()
    while true do
        Wait(Config.Performance.timeUpdateInterval)
        UpdateGameTime()
    end
end)

-- ████████████████████████████████████████████████████████████████
-- ██                    RESOURCE LIFECYCLE                      ██
-- ████████████████████████████████████████████████████████████████

--- Request sync on player load
AddEventHandler('esx:playerLoaded', function(playerData)
    Wait(1000)
    TriggerServerEvent('vogel_weather:requestSync')
end)

--- Request sync on resource start
AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    Wait(2000)
    TriggerServerEvent('vogel_weather:requestSync')
    
    DebugPrint('Client initialized')
end)
