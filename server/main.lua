local config = Config or {}

local activeWashingMachines = {}

lib.callback.register('fz-moneywash:getMoney', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end
    local moneyAmount = exports.ox_inventory:GetItem(source, config.dirtycashItem, nil, true)
    return moneyAmount
end)

lib.callback.register('fz-moneywash:getMoneywashAmount', function(source, id)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end
    if not activeWashingMachines[id] or not activeWashingMachines[id].player == source then 
        TriggerClientEvent('fz-moneywash:notify', source, locale('error.not_your_machine'), 'error')
        return 0
    end
    return activeWashingMachines[id].moneywashAmount or 0
end)

lib.callback.register('fz-moneywash:checkTimer', function(source, id)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end
    local activemachine = activeWashingMachines[id]
    if not activemachine or not activemachine.timer then
        return true
    end
    if os.time() >= activeWashingMachines[id].timer then
        return false
    end
    return activeWashingMachines[id].timer - os.time()
end)

local function isUsingMachineAlready(source, currentId)
    for id, machine in pairs(activeWashingMachines) do
        if id ~= currentId and machine.player == source then
            return true
        end
    end
    return false
end

RegisterNetEvent('fz-moneywash:collectMoney', function(id, moneywashAmount)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end
    if not activeWashingMachines[id] or not activeWashingMachines[id].player == source then 
        TriggerClientEvent('fz-moneywash:notify', source, locale('error.not_your_machine'), 'error')
        return
    end
    local cleanmoney = moneywashAmount * (1 - config.tax)
    player.Functions.AddMoney('cash', cleanmoney)
    TriggerClientEvent('fz-moneywash:notify', source, locale('success.money_washed', cleanmoney), 'success')
    activeWashingMachines[id] = nil
end)

RegisterNetEvent('fz-moneywash:stopWashing', function(id, moneywashAmount)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end
    if not activeWashingMachines[id] or not activeWashingMachines[id].player == source then 
        TriggerClientEvent('fz-moneywash:notify', source, locale('error.not_your_machine'), 'error')
        return
    end
    if moneywashAmount < 0 then
        TriggerClientEvent('fz-moneywash:notify', source, locale('error.invalid_amount'), 'error')
        return
    end
    local dirtycash = moneywashAmount * (1 - config.tax)
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
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end
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
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end
    if moneywashAmount <= 0 then
        TriggerClientEvent('fz-moneywash:notify', source, locale('error.invalid_amount'), 'error')
        return
    end
    local maxwashtime = config.maxwashtime * 60
    local washingTime = moneywashAmount * 0.007 + 10
    if washingTime > maxwashtime then
        washingTime = maxwashtime
    end
    activeWashingMachines[id] = {
        player = source,
        moneywashAmount = moneywashAmount,
        timer = os.time() + washingTime,
    }
    exports.ox_inventory:RemoveItem(source, config.dirtycashItem, moneywashAmount, nil)
    TriggerClientEvent('fz-moneywash:notify', source, locale('info.money_is_being_washed'), 'info')
end)