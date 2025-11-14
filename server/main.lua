local config = Config or {}

local activeWashingMachines = {}

local Framework = nil

CreateThread(function()
    if config.Framework == 'auto' then
        if GetResourceState('qb-core') == 'started' then
            Framework = 'qb'
            QBCore = exports['qb-core']:GetCoreObject()
        elseif GetResourceState('es_extended') == 'started' then
            Framework = 'esx'
            ESX = exports['es_extended']:getSharedObject()
        else
            print('Missing a supported framework.')
        end
    elseif config.Framework == 'qb' then
        Framework = 'qb'
        QBCore = exports['qb-core']:GetCoreObject()
    elseif config.Framework == 'esx' then
        Framework = 'esx'
        ESX = exports['es_extended']:getSharedObject()
    else 
        print("Invalid framework in config.lua")
    end
end)

local function GetPlayer(source)
    if Framework == 'qb' then
        return QBCore.Functions.GetPlayer(source)
    elseif Framework == 'esx' then
        return ESX.GetPlayerFromId(source)
    else
        print("Invalid framework in config.lua")
        return nil
    end
end

lib.callback.register('fz-moneywash:checkMoneywashCard', function(source)
    if not config.moneywashCard then return true end
    local cardAmount = exports.ox_inventory:GetItem(source, config.moneywashCard, nil, true)
    if cardAmount and cardAmount > 0 then
        return true
    else
        return false
    end
end)

lib.callback.register('fz-moneywash:getMoney', function(source)
    local moneyAmount = exports.ox_inventory:GetItem(source, config.dirtycashItem, nil, true)
    return moneyAmount
end)

lib.callback.register('fz-moneywash:getMoneywashAmount', function(source, id)
    local player = GetPlayer(source)

    if not activeWashingMachines[id] or activeWashingMachines[id].player ~= source then 
        TriggerClientEvent('fz-moneywash:notify', source, locale('error.not_your_machine'), 'error')
        return 0
    end
    return activeWashingMachines[id].moneywashAmount or 0
end)

lib.callback.register('fz-moneywash:checkTimer', function(source, id)
    local activemachine = activeWashingMachines[id]
    if not activemachine or not activemachine.timer then
        return true
    end
    if os.time() >= activeWashingMachines[id].timer then
        return false
    end
    return activeWashingMachines[id].timer - os.time()
end)

local function AddMoney(source, type, amount)
    if not amount or amount <= 0 then
        print("Invalid amount specified")
        return
    end

    if not type or (type ~= 'cash' and type ~= 'bank' and type ~= 'money') then
        print("Invalid money type specified")
        return
    end

    if Framework == 'qb' then
        local Player = GetPlayer(source)
        if not Player then return end

        Player.Functions.AddMoney(type, amount)
    elseif Framework == 'esx' then
        local xPlayer = GetPlayer(source)
        if not xPlayer then return end

        xPlayer.addAccountMoney(type, amount)
    else
        print("Invalid framework in config.lua")
        return
    end
end

local function isUsingMachineAlready(source, currentId)
    for id, machine in pairs(activeWashingMachines) do
        if id ~= currentId and machine.player == source then
            return true
        end
    end
    return false
end

RegisterNetEvent('fz-moneywash:collectMoney', function(id)
    local player = GetPlayer(source)

    if not activeWashingMachines[id] or activeWashingMachines[id].player ~= source then 
        TriggerClientEvent('fz-moneywash:notify', source, locale('error.not_your_machine'), 'error')
        return
    end
    local moneywashAmount = activeWashingMachines[id].moneywashAmount
    local cleanmoney = math.floor(moneywashAmount * (1 - config.tax))
    AddMoney(source, config.MoneyType, cleanmoney)
    TriggerClientEvent('fz-moneywash:notify', source, locale('success.money_washed', cleanmoney), 'success')
    activeWashingMachines[id] = nil
end)

RegisterNetEvent('fz-moneywash:stopWashing', function(id)
    local player = GetPlayer(source)

    if not activeWashingMachines[id] or activeWashingMachines[id].player ~= source then 
        TriggerClientEvent('fz-moneywash:notify', source, locale('error.not_your_machine'), 'error')
        return
    end
    local moneywashAmount = activeWashingMachines[id].moneywashAmount
    if moneywashAmount < 0 then
        TriggerClientEvent('fz-moneywash:notify', source, locale('error.invalid_amount'), 'error')
        return
    end
    local dirtycash = math.floor(moneywashAmount * (1 - config.tax))
    if exports.ox_inventory:CanCarryItem(source, config.dirtycashItem, dirtycash) then
        exports.ox_inventory:AddItem(source, config.dirtycashItem, dirtycash)
    else
        TriggerClientEvent('fz-moneywash:notify', source, locale('error.not_enough_inventory_space'), 'error')
        return
    end
    activeWashingMachines[id] = nil
    TriggerClientEvent('fz-moneywash:notify', source, locale('success.washing_stopped') .. locale('currency.symbol') .. dirtycash, 'success')
end)

RegisterNetEvent('fz-moneywash:checkWashingMachine', function(id)
    local player = GetPlayer(source)

    if isUsingMachineAlready(source, id) then
        TriggerClientEvent('fz-moneywash:notify', source, locale('error.already_using_machine'), 'error')
        return
    elseif activeWashingMachines[id] and activeWashingMachines[id].player == source then
        TriggerClientEvent('fz-moneywash:openWashingMachine', source, id)
        return
    elseif activeWashingMachines[id] then
        TriggerClientEvent('fz-moneywash:notify', source, locale('error.washing_machine_busy'), 'error')
        return
    end
    TriggerClientEvent('fz-moneywash:startWashingMachine', source, id)
end)

RegisterNetEvent('fz-moneywash:washMoney', function(id, moneywashAmount)
    local player = GetPlayer(source)

    if moneywashAmount <= 0 then
        TriggerClientEvent('fz-moneywash:notify', source, locale('error.invalid_amount'), 'error')
        return
    end
    local maxwashtime = config.maxwashtime * 60
    local washingTime = moneywashAmount * 0.007 + 10
    if washingTime > maxwashtime then
        washingTime = maxwashtime
    end
    local playerdirtycash = exports.ox_inventory:GetItem(source, config.dirtycashItem, nil, true)
    if playerdirtycash < moneywashAmount then
        TriggerClientEvent('fz-moneywash:notify', source, locale('error.missing_items'), 'error')
        return
    end
    activeWashingMachines[id] = {
        player = source,
        moneywashAmount = moneywashAmount,
        timer = os.time() + washingTime,
    }
    exports.ox_inventory:RemoveItem(source, config.dirtycashItem, moneywashAmount, nil)
    TriggerClientEvent('fz-moneywash:notify', source, locale('info.money_is_being_washed'), 'info')
end)
