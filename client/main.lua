ESX, isMenuActive, canInteractWithZone, interactWithServer = nil, false, true, false

local function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

local function showbox(TextEntry, ExampleText, MaxStringLenght, isValueInt)
    AddTextEntry('FMMC_KEY_TIP1', TextEntry)
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", ExampleText, "", "", "", MaxStringLenght)
    local blockinput = true
    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
        Wait(0)
    end
    if UpdateOnscreenKeyboard() ~= 2 then
        local result = GetOnscreenKeyboardResult()
        Wait(500)
        blockinput = false
        if isValueInt then
            local isNumber = tonumber(result)
            if isNumber and tonumber(result) > 0 then
                return result
            else
                return nil
            end
        end

        return result
    else
        Wait(500)
        blockinput = false
        return nil
    end
end

local function sub(subName)
    return "garage"..subName
end

local title, desc, cat, cam = "Garage", "~g~Sortez et rangez vos véhicules", "zGarage", nil
local function createMenuPanes()
    RMenu.Add(cat, sub("main"), RageUI.CreateMenu(title, desc, nil, nil, "pablo", "black"))
    RMenu:Get(cat, sub("main")).Closed = function()
    end

    RMenu.Add(cat, sub("cam_selector_in"), RageUI.CreateSubMenu(RMenu:Get(cat, sub("main")), title, desc, nil, nil, "pablo", "black"))
    RMenu:Get(cat, sub("cam_selector_in")).Closed = function()
        RenderScriptCams(0,0,0,0,0)
    end

    RMenu.Add(cat, sub("out"), RageUI.CreateSubMenu(RMenu:Get(cat, sub("main")), title, desc, nil, nil, "pablo", "black"))
    RMenu:Get(cat, sub("out")).Closed = function()
    end

    RMenu.Add(cat, sub("cam_selector_out"), RageUI.CreateSubMenu(RMenu:Get(cat, sub("out")), title, desc, nil, nil, "pablo", "black"))
    RMenu:Get(cat, sub("cam_selector_out")).Closed = function()
        RenderScriptCams(0,0,0,0,0)
    end
end

Citizen.CreateThread(function()
    TriggerEvent(Config.esxGetter, function(obj)
        ESX = obj
    end)

    createMenuPanes()

    for _, data in pairs(Config.garages) do
        local blip = AddBlipForCoord(data.interactionZone)
        SetBlipAsShortRange(blip, true)
        SetBlipScale(blip, 1.0)
        SetBlipSprite(blip, 50)
        SetBlipColour(blip, 30)

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(data.name or "Garage public")
        EndTextCommandSetBlipName(blip)
    end

    while true do
        local interval, pos = 250, GetEntityCoords(PlayerPedId())
        for id, data in pairs(Config.garages) do
            local itrPos = data.interactionZone
            local dst = #(pos-itrPos)
            if (dst <= 40.0) then
                interval = 0
                DrawMarker(22, itrPos, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 0.45, 0.45, 0.45, 150, 220, 255, 255, 55555, false, true, 2, false, false, false, false)
                if dst <= 1.0 then
                    ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour ouvrir le garage")
                    if IsControlJustPressed(0, 51) then
                        TriggerServerEvent("garage:openMenu", id)
                        canInteractWithZone = false
                    end
                end
            end
        end
        Wait(interval)
    end
end)

local function getRelativeCamCoords(coords)
    coords = {x = coords.x, y = coords.y, z = coords.z}
    coords.x = coords.x + 3
    coords.y = coords.y - 3
    coords.z = coords.z + 2
    return vector3(coords.x, coords.y, coords.z)
end

local function validatePlace(coords, radius)
    return ESX.Game.IsSpawnPointClear(coords, radius)
end

RegisterNetEvent("garage:openMenu")
AddEventHandler("garage:openMenu", function(garageId, ownedVehicles)
    if isMenuActive then return end
    FreezeEntityPosition(PlayerPedId(), true)
    canInteractWithZone = true
    isMenuActive = true
    RageUI.Visible(RMenu:Get(cat, sub("main")), true)
    Citizen.CreateThread(function()
        local selectedPlace, selectedVehicle, lastPosActive = 1, nil, 1
        cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", 0)
        SetCamActive(cam, true)
        while isMenuActive do
            local shouldStayOpened = false
            local function tick()
                shouldStayOpened = true
            end
            RageUI.IsVisible(RMenu:Get(cat, sub("main")), true, true, true, function()
                tick()
                RageUI.ButtonWithStyle("Mes Vehicules", "Appuyez pour ouvrir le menu de mes véhicules", {}, true, nil, RMenu:Get(cat, sub("out")))
                RageUI.ButtonWithStyle("Ranger un véhicule", "Appuyez pour ouvrir le menu pour ranger les véhicules", {}, true, function(_,_,s)
                    if s then
                        local loc = Config.garages[garageId].availableSpawns[1].coords
                        SetCamCoord(cam, getRelativeCamCoords(loc))
                        PointCamAtCoord(cam, loc)
                        RenderScriptCams(1, 0, 0, 0, 0)
                    end
                end, RMenu:Get(cat, sub("cam_selector_in")))
            end, function()
            end)

            RageUI.IsVisible(RMenu:Get(cat, sub("out")), true, true, true, function()
                tick()
                for id, data in pairs(ownedVehicles) do
                    local model = data.vehicle.model
                    RageUI.ButtonWithStyle((data.customname ~= nil and data.customname or firstToUpper(GetDisplayNameFromVehicleModel(model):lower())..(" (~b~%s~s~)"):format(data.plate)), "Appuyez pour selectionner ce véhicule", {RightLabel = (data.stored and "~g~Rentré" or "~s~Sorti")}, data.stored, function(_,_,s)
                        if s then
                            local loc = Config.garages[garageId].availableSpawns[1].coords
                            selectedVehicle = id
                            SetCamCoord(cam, getRelativeCamCoords(loc))
                            PointCamAtCoord(cam, loc)
                            RenderScriptCams(1, 0, 0, 0, 0)
                        end
                    end, RMenu:Get(cat, sub("cam_selector_out")))
                end
            end, function()
            end)

            RageUI.IsVisible(RMenu:Get(cat, sub("cam_selector_out")), true, true, true, function()
                tick()
                local model = ownedVehicles[selectedVehicle].vehicle.model
                RageUI.Separator(("Véhicule: ~y~%s"):format(firstToUpper(GetDisplayNameFromVehicleModel(model):lower())))
                RageUI.Separator("↓ ~o~Places disponibles ~s~↓")
                for k, v in pairs(Config.garages[garageId].availableSpawns) do
                    local canSpawn = validatePlace(v.coords, Config.garages[garageId].spawnRadius)
                    RageUI.ButtonWithStyle(("Place #%i"):format(k), nil, {RightLabel = (canSpawn and "→" or "~r~Occupée")},true, function(_,a,s)
                        if a then
                            if lastPosActive ~= k then
                                --print(("Update to %s"):format(k))
                                SetCamCoord(cam, getRelativeCamCoords(v.coords))
                                PointCamAtCoord(cam, v.coords)
                                lastPosActive = k
                            end
                        end

                        if s then
                            if canSpawn then
                                shouldStayOpened = false
                                canInteractWithZone = false
                                TriggerServerEvent("garage:spawnVehicle", garageId, k, ownedVehicles[selectedVehicle])
                            end
                        end
                    end)
                end
            end, function()
            end)

            RageUI.IsVisible(RMenu:Get(cat, sub("cam_selector_in")), true, true, true, function()
                tick()
                RageUI.Separator("↓ ~o~Places ~s~↓")
                for k, v in pairs(Config.garages[garageId].availableSpawns) do
                    local existingVehicle = validatePlace(v.coords, Config.garages[garageId].spawnRadius)
                    existingVehicle = not existingVehicle
                    RageUI.ButtonWithStyle(("Place #%i"):format(k), nil, {RightLabel = (existingVehicle and "~r~Ranger ~s~→" or "Vide")},true, function(_, a, s)
                        if a then
                            if lastPosActive ~= k then
                                --print(("Update to %s"):format(k))
                                SetCamCoord(cam, getRelativeCamCoords(v.coords))
                                PointCamAtCoord(cam, v.coords)
                                lastPosActive = k
                            end
                        end

                        if s then
                            if existingVehicle then
                                local vehicle = ESX.Game.GetVehiclesInArea(v.coords, Config.garages[garageId].spawnRadius)[1]
                                shouldStayOpened = false
                                canInteractWithZone = false
                                TriggerServerEvent("garage:cbVehicle", garageId, ESX.Game.GetVehicleProperties(vehicle), vehicle)
                            end
                        end
                    end)
                end
            end, function()
            end)

            if not shouldStayOpened and isMenuActive then
                FreezeEntityPosition(PlayerPedId(), false)
                RenderScriptCams(0,0,0,0,0)
                isMenuActive = false
            end
            Wait(0)
        end
    end)
end)

RegisterNetEvent("garage:cbServer")
AddEventHandler("garage:cbServer", function(message)
    canInteractWithZone = true
    if message ~= nil then ESX.ShowNotification(message) end
end)

RegisterNetEvent("garage:cbSpawn")
AddEventHandler("garage:cbSpawn", function(coords, heading, data)
    local model = data.vehicle.model
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(1) end
    local vehicle = CreateVehicle(model, coords, heading, true, true)
    ESX.Game.SetVehicleProperties(vehicle, data)
    TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    SetEntityAsMissionEntity(vehicle, 0,0)
    ESX.Game.SetVehicleProperties(vehicle, data)
    canInteractWithZone = true
end)

RegisterNetEvent("garage:cbKill")
AddEventHandler("garage:cbKill", function(vehicle)
    NetworkRequestControlOfEntity(vehicle)
    while not NetworkHasControlOfEntity(vehicle) do Wait(1) end
    DeleteEntity(vehicle)
    canInteractWithZone = true
    ESX.ShowNotification("~g~Véhicule rangé")
end)