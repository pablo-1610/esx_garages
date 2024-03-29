ESX = nil

TriggerEvent(Config.esxGetter, function(obj)
    ESX = obj
    MySQL.Async.execute("UPDATE owned_vehicles SET stored = 1", {})
end)

RegisterNetEvent("garage:openMenu")
AddEventHandler("garage:openMenu", function(garageId)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local identifier = xPlayer.identifier
    MySQL.Async.fetchAll("SELECT * FROM owned_vehicles WHERE owner = @a", {
        ["a"] = identifier
    }, function(result)
        for k, v in pairs(result) do
            result[k].vehicle = json.decode(v.vehicle)
        end
        TriggerClientEvent("garage:openMenu", _src, garageId, result)
    end)
end)

RegisterNetEvent("garage:openFourriere")
AddEventHandler("garage:openFourriere", function(fourriereId)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local identifier = xPlayer.identifier
    MySQL.Async.fetchAll("SELECT * FROM owned_vehicles WHERE owner = @a AND stored = 0", {
        ["a"] = identifier
    }, function(result)
        for k, v in pairs(result) do
            result[k].vehicle = json.decode(v.vehicle)
        end
        TriggerClientEvent("garage:openFourriere", _src, fourriereId, result)
    end)
end)

RegisterNetEvent("garage:spawnVehicle")
AddEventHandler("garage:spawnVehicle", function(garage, place, vehicleData)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local identifier = xPlayer.identifier

    MySQL.Async.execute("UPDATE owned_vehicles SET stored = @a WHERE owner = @b AND plate = @c", {
        ["a"] = false,
        ["b"] = identifier,
        ["c"] = vehicleData.plate
    })

    local spawnData = Config.garages[garage].availableSpawns[place]
    TriggerClientEvent("garage:cbSpawn", _src, spawnData.coords, spawnData.heading, vehicleData)
end)

RegisterNetEvent("garage:spawnFourriere")
AddEventHandler("garage:spawnFourriere", function(fourriere, vehicleData)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local identifier = xPlayer.identifier
    local price = Config.fourrieres.price 

    if xPlayer.getMoney() >= price then
        xPlayer.removeMoney(price)
    elseif xPlayer.getAccount("bank").money >= price then
        xPlayer.removeAccountMoney("bank", price)
    else
        TriggerClientEvent("garage:cbServer", _src, "~r~Vous n'avez pas assez pour payer")
        return
    end


    MySQL.Async.execute("UPDATE owned_vehicles SET stored = @a WHERE owner = @b AND plate = @c", {
        ["a"] = true,
        ["b"] = identifier,
        ["c"] = vehicleData.plate
    })

    local d = Config.fourrieres.list[fourriere].out
    TriggerClientEvent("garage:cbSpawn", _src, d.pos, d.heading, vehicleData)
end)

RegisterNetEvent("garage:cbVehicle")
AddEventHandler("garage:cbVehicle", function(garage, vehicleData, netID)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local identifier = xPlayer.identifier

    print(identifier)
    print(vehicleData.plate)
    MySQL.Async.fetchAll("SELECT * FROM owned_vehicles WHERE owner = @a AND plate = @b", {
        ["a"] = identifier,
        ["b"] = vehicleData.plate
    }, function(result)
        if(result[1]) then
            print("Resultat")
            MySQL.Async.execute("UPDATE owned_vehicles SET stored = @a, vehicle = @d WHERE owner = @b AND plate = @c", {
                ["a"] = 1,
                ["b"] = identifier,
                ["c"] = vehicleData.plate,
                ["d"] = json.encode(vehicleData)
            })
            TriggerClientEvent("garage:cbKill", _src, netID)
        else
            TriggerClientEvent("garage:cbServer", _src, "~r~Ce véhicule ne vous appartient pas")
            return
        end
    end)
end)
  
  