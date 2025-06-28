local config = Config or {}

RegisterNetEvent('fz-moneywash:notify', function(message, type)
    lib.notify({
        description = message,
        type = type,
        duration = 5000
    })
end)

RegisterNetEvent('fz-moneywash:openWashingMachine', function(id)
    lib.registerContext({
        id = 'washingmachine_' .. id,
        title = locale('washing_machine.title'),
        options = {
            {
                title = locale('currency.symbol') .. lib.callback.await('fz-moneywash:getMoneywashAmount', false, id) .. ' ' .. locale('washing_machine.subtitle_wash_money'),
                description = locale('washing_machine.description_wash_money'),
                icon = 'fas fa-dollar-sign',
            },
            {
                title = locale('washing_machine.collect_money'),
                description = locale('washing_machine.collect_money_description'),
                icon = 'fas fa-dollar-sign',
                onSelect = function()
                    local timerLeft = lib.callback.await('fz-moneywash:checkTimer', false, id)
                    if timerLeft == false then
                        TriggerServerEvent('fz-moneywash:collectMoney', id)
                    elseif timerLeft == true then 
                        lib.notify({
                            description = locale('washing_machine.not_started'),
                            type = 'error',
                            duration = 5000
                        })
                    else
                        local time = tonumber(timerLeft)
                        local minutes = math.floor(time / 60)
                        local seconds = math.floor(time % 60)
                        lib.notify({
                            description = string.format("Time left: %02d:%02d", minutes, seconds),
                            type = 'error',
                            duration = 5000
                        })
                    end
                end,
            },
            {
                title = locale('washing_machine.stop_washing'),
                description = locale('washing_machine.stop_washing_description'),
                icon = 'fas fa-dollar-sign',
                onSelect = function()
                    local timerLeft = lib.callback.await('fz-moneywash:checkTimer', false, id)
                    if timerLeft == false then
                        lib.notify({
                            description = locale('error.timer_finished'),
                            type = 'error',
                            duration = 5000
                        })
                    elseif timerLeft == true then
                        lib.notify({
                            description = locale('error.not_started'),
                            type = 'error',
                            duration = 5000
                        })
                    elseif timerLeft >= 10 then
                        TriggerServerEvent('fz-moneywash:stopWashing', id)
                    else
                        lib.notify({
                            description = locale('error.too_late_to_cancel'),
                            type = 'error',
                            duration = 5000
                        })
                    end
                end,
            },
        }
    })
    lib.showContext('washingmachine_' .. id)
end)

local function enterMoneywash(moneywash, coords)
    local playerPed = PlayerPedId()
    if moneywash == "entrance" then 
        TriggerEvent('fz-moneywash:notify', locale('info.entering_moneywash'), 'info')
    elseif moneywash == "exit" then
        TriggerEvent('fz-moneywash:notify', locale('info.exiting_moneywash'), 'info')
    else 
        TriggerEvent('fz-moneywash:notify', locale('error.invalid_moneywash'), 'error')
        return
    end
    DoScreenFadeOut(1000)
    Wait(1000)
    SetEntityCoords(playerPed, coords.xyz)
    Wait(1000)
    DoScreenFadeIn(1000)
end

local function setupEnterAndExitMoneywash()
    for i, current in pairs (config.moneywashes) do
        local entranceCoords = current.entrance
        local exitCoords = current.exit
        if config.useTarget then
            exports.ox_target:addBoxZone({
                coords = entranceCoords.xyz,
                size = vec3(1, 1, 1),
                rotation = entranceCoords.w,
                debug = config.debug,
                options = {
                    {
                        name = 'moneywash_entrance',
                        label = locale('moneywash.target_enter'),
                        icon = 'fas fa-door-open',
                        onSelect = function()
                            enterMoneywash("entrance", exitCoords)
                        end,
                    },
                },
            })
            exports.ox_target:addBoxZone({
                coords = exitCoords.xyz,
                size = vec3(1, 1, 1),
                rotation = exitCoords.w,
                debug = config.debug,
                options = {
                    {
                        name = 'moneywash_exit',
                        label = locale('moneywash.target_exit'),
                        icon = 'fas fa-door-open',
                        onSelect = function()
                            enterMoneywash("exit", entranceCoords)
                        end,
                    },
                },
            })
        else
            lib.zones.box({
                name = 'moneywash_entrance_' .. i,
                coords = entranceCoords.xyz,
                size = vec3(1, 1, 1),
                rotation = entranceCoords.w,
                debug = config.debug,
                onEnter = function()
                    lib.showTextUI(locale('textui_enter'))
                end,
                onExit = function()
                    lib.hideTextUI()
                end,
                inside = function()
                    if IsControlJustPressed(0, config.keybind) then
                        TriggerEvent('fz-moneywash:enterMoneyWash', i)
                        lib.hideTextUI()
                    end
                end,
            })
            lib.zones.box({
                name = 'moneywash_exit_' .. i,
                coords = exitCoords.xyz,
                size = vec3(1, 1, 1),
                rotation = exitCoords.w,
                debug = config.debug,
                onEnter = function()
                    lib.showTextUI(locale('textui_exit'))
                end,
                onExit = function()
                    lib.hideTextUI()
                end,
                inside = function()
                    if IsControlJustPressed(0, config.keybind) then
                        TriggerEvent('fz-moneywash:exitMoneyWash', i)
                        lib.hideTextUI()
                    end
                end,
            })
        end
    end
end
        

local function setupWashingMachines()
    for i, current in pairs (config.moneywashes) do
        for id in pairs (current.washingmachines) do
            local washingmachine = current.washingmachines[id]
            local coords = washingmachine.coords
            if config.useTarget then
                exports.ox_target:addBoxZone({
                    coords = coords.xyz,
                    size = vec3(1, 1, 1),
                    rotation = coords.w,
                    debug = config.debug,
                    options = {
                        {
                            name = 'washingmachine_' .. id,
                            label = locale('washing_machine.target_open_washing_machine'),
                            icon = 'fas fa-dollar-sign',
                            onSelect = function()
                                TriggerServerEvent('fz-moneywash:checkWashingMachine', id)
                            end,
                        },
                    },
                })
            else
                local options = current.zoneOptions
                if options then
                    lib.zones.box({
                        name = 'washingmachine_zone_' .. id,
                        coords = coords.xyz,
                        size = vec3(options.length, options.width, 2),
                        rotation = coords.w,
                        debug = config.debug,
                        onEnter = function()
                            lib.showTextUI(locale('washing_machine.textui_open_washing_machine'))
                        end,
                        onExit = function()
                            lib.hideTextUI()
                        end,
                        inside = function()
                            if IsControlJustPressed(0, config.keybind) then
                                TriggerServerEvent('fz-moneywash:checkWashingMachine', id)
                                lib.hideTextUI()
                            end
                        end,
                    })
                end
            end
        end
    end
end

RegisterNetEvent('fz-moneywash:startWashingMachine', function(id)
    local input = lib.inputDialog('Wash Amount', {
        {
            type = 'slider',
            label = 'How much cash do you want to wash?',
            default = 0,
            min = 0,
            max = lib.callback.await('fz-moneywash:getMoney', false),
        }
    })
    if not input then return end
    local moneywashAmount = tonumber(input[1])
    if not moneywashAmount or moneywashAmount <= 0 then
        lib.notify({ description = locale('error.invalid_amount'), type = 'error' })
        return
    end
    TriggerServerEvent('fz-moneywash:washMoney', id, moneywashAmount)
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    setupEnterAndExitMoneywash()
    setupWashingMachines()
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    setupEnterAndExitMoneywash()
    setupWashingMachines()
end)