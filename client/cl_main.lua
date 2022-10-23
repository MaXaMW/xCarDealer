ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)

-- Function
local categories = {}
local function getCategories()
    ESX.TriggerServerCallback("xCarDealer:getCategories", function(result) 
        categories = result
    end)
end

local vehicles = {}
local function getVehicles(name)
    ESX.TriggerServerCallback("xCarDealer:getVehicles", function(result) 
        vehicles = result
    end, name)
end

local weight = 0
local function getStockage(name)
    for _,v in pairs(xCarDealer.Stockage) do
        if v.name == name then
            weight = v.weight
        end
    end
end

local entity, car = nil, false
local function TestCar(pPos)
    local test = true
    local result = xCarDealer.TimeForTest * 60
    RageUI.CloseAll()
    FreezeEntityPosition(PlayerPedId(), false)

    while test do
        result = result - 1

        while IsPedInAnyVehicle(PlayerPedId()) == false do
            DeleteEntity(GetClosestVehicle(GetEntityCoords(PlayerPedId()), 15.0, 0, 70))
            ESX.ShowNotification("Vous êtes descendu du véhicule")
            test = false
            SetEntityCoords(PlayerPedId(), pPos.x, pPos.y, pPos.z)
            break
        end
        if result == 0 then
            DeleteEntity(GetVehiclePedIsIn(PlayerPedId(), false))
            ESX.ShowNotification("Test terminé")
            test = false
            SetEntityCoords(PlayerPedId(), pPos.x, pPos.y, pPos.z)
            break
        end
        Wait(1000)
    end
end

function DrawText3Ds(x, y, z, text)
	local onScreen,_x,_y=World3dToScreen2d(x,y,z)

	if onScreen then
		SetTextScale(0.31, 0.31)
		SetTextFont(0)
		SetTextProportional(1)
		SetTextColour(255, 255, 255, 255)
		SetTextEntry("STRING")
		SetTextOutline()
		SetTextDropshadow(0, 0, 0, 0, 0)
		SetTextDropShadow()
		AddTextComponentString(text)
		SetTextCentre(1)
		DrawText(_x,_y)
	end
end

-- Menu

local heading = 0
local select = {}
local open  = false
local mainMenu = RageUI.CreateMenu(nil, "CATEGORIE", nil, nil, "root_cause5", "img_red")
local show_car = RageUI.CreateSubMenu(mainMenu, nil, "VEHICULE")
local selection = RageUI.CreateSubMenu(show_car, nil, "INFORMATION")
mainMenu.Display.Header = true
selection.EnableMouse = true
mainMenu.Closed = function()
    open = false
    FreezeEntityPosition(PlayerPedId(), false)
    select = {} DeleteEntity(entity) entity = nil car = false weight = 0
end
selection.Closed = function() select = {} DeleteEntity(entity) entity = nil car = false end show_car.Closed = function() weight = 0 select = {} DeleteEntity(entity) entity = nil car = false end

local Customs = { List1 = 1, List2 = 1, List3 = 1 }

local function MenuConcessionnaire() -- NOM CATEGORIE --
    if open then
        open = false
        RageUI.Visible(mainMenu, false)
    else
        open = true
        RageUI.Visible(mainMenu, true)
        Citizen.CreateThread(function()
            while open do
                Wait(0)
                RageUI.IsVisible(mainMenu, function()
                    for _,v in pairs(categories) do
                        RageUI.Button(("%s"):format(v.label), nil, {RightBadge = RageUI.BadgeStyle.Star}, true, {
                            onSelected = function()
                                getVehicles(v.name)
                                getStockage(v.name)
                            end
                        }, show_car)
                    end
                end)
                RageUI.IsVisible(show_car, function()
                    for _,v in pairs(vehicles) do
                        RageUI.Button(("%s"):format(v.name), nil, {RightBadge = RageUI.BadgeStyle.Tick}, true, {
                            onActive = function()
                                RageUI.Info(("~r~%s~s~"):format(v.name),{"Prix :", "Coffre :"}, {("~g~%s$~s~"):format(v.price), ("~r~%skg~s~"):format(weight)})
                            end,
                            onSelected = function()
                                table.insert(select, {name = v.name, model = v.model, price = v.price})
                            end
                        }, selection)
                    end
                end)
                RageUI.IsVisible(selection, function()
                    for _,v in pairs(select) do
                        heading = heading + 0.1
                        FreezeEntityPosition(entity, true)
                        SetEntityHeading(entity, heading)
                        if car == false then
                            RequestModel(GetHashKey(v.model))
                            while not HasModelLoaded(GetHashKey(v.model)) do 
                              Wait(1) 
                            end
                            entity = CreateVehicle(v.model, xCarDealer.Position.Exposition.x, xCarDealer.Position.Exposition.y, xCarDealer.Position.Exposition.z, heading, true, false)
                            car = true
                        else
                            RageUI.Button(("Essayer le véhicule (~r~%smin~s~)"):format(xCarDealer.TimeForTest), nil, {RightLabel = "→"}, true, {
                                onActive = function()
                                    if car == false then
                                        RequestModel(GetHashKey(v.model))
                                        while not HasModelLoaded(GetHashKey(v.model)) do 
                                        Wait(1) 
                                        end
                                        entity = CreateVehicle(v.model, xCarDealer.Position.Exposition.x, xCarDealer.Position.Exposition.y, xCarDealer.Position.Exposition.z, heading, true, false)
                                        car = true
                                    end
                                end,
                                onSelected = function()
                                    DeleteEntity(entity) entity = nil car = false
                                    RequestModel(GetHashKey(v.model))
                                    while not HasModelLoaded(GetHashKey(v.model)) do 
                                    Wait(1) 
                                    end
                                    local pPos = GetEntityCoords(PlayerPedId())
                                    local vehicle = CreateVehicle(v.model, xCarDealer.Position.SpwanCarForTest.x, xCarDealer.Position.SpwanCarForTest.y, xCarDealer.Position.SpwanCarForTest.z, xCarDealer.Position.HeadingForTest, true, false)
                                    SetVehicleFuelLevel(vehicle, 60.0)
                                    SetVehicleDirtLevel(vehicle, 0)
                                    SetPedIntoVehicle(PlayerPedId(), vehicle, -1)
                                    TestCar(pPos)
                                    select = {}
                                end
                            })
                            RageUI.List("Couleur", {"Noir", "Gris", "Blanc", "Beige", "Vert", "Vert foncé", "Jaune", "Orange", "Rouge", "Rose", "Violet", "Bleu", "Bleu foncé", "Marron", }, Customs.List2, nil, {Preview}, true, {
                                onListChange = function(i, Index)
                                    Customs.List2 = i
                                end,
                                onSelected = function()
                                    if Customs.List2 == 1 then SetVehicleColours(entity, 0, 0) SetVehicleExtraColours(entity, 0, 0) end
                                    if Customs.List2 == 2 then SetVehicleColours(entity, 6, 6) SetVehicleExtraColours(entity, 0, 0) end
                                    if Customs.List2 == 3 then SetVehicleColours(entity, 111, 111) SetVehicleExtraColours(entity, 0, 0) end
                                    if Customs.List2 == 4 then SetVehicleColours(entity, 99, 99) SetVehicleExtraColours(entity, 0, 0) end
                                    if Customs.List2 == 5 then SetVehicleColours(entity, 53, 53) SetVehicleExtraColours(entity, 0, 0) end
                                    if Customs.List2 == 6 then SetVehicleColours(entity, 49, 49) SetVehicleExtraColours(entity, 0, 0) end
                                    if Customs.List2 == 7 then SetVehicleColours(entity, 88, 88) SetVehicleExtraColours(entity, 0, 0) end
                                    if Customs.List2 == 8 then SetVehicleColours(entity, 38, 38) SetVehicleExtraColours(entity, 0, 0) end
                                    if Customs.List2 == 9 then SetVehicleColours(entity, 27, 27) SetVehicleExtraColours(entity, 0, 0) end
                                    if Customs.List2 == 10 then SetVehicleColours(entity, 135, 135) SetVehicleExtraColours(entity, 0, 0) end
                                    if Customs.List2 == 11 then SetVehicleColours(entity, 145, 145) SetVehicleExtraColours(entity, 0, 0) end
                                    if Customs.List2 == 12 then SetVehicleColours(entity, 70, 70) SetVehicleExtraColours(entity, 0, 0) end
                                    if Customs.List2 == 13 then SetVehicleColours(entity, 75, 75) SetVehicleExtraColours(entity, 0, 0) end
                                    if Customs.List2 == 14 then SetVehicleColours(entity, 96, 96) SetVehicleExtraColours(entity, 0, 0) end
                                end
                            })
                            RageUI.Line()
                            RageUI.Separator(("Nombre de place : ~r~%s~s~"):format(GetVehicleMaxNumberOfPassengers(entity) + 1))
                            RageUI.Separator(("Prix : ~g~%s$~s~"):format(v.price))
                            RageUI.Separator(("Coffre : ~r~%skg~s~"):format(weight))

                            RageUI.List("Acheter le véhicule", {"~g~Liquide~s~", "~b~Carte Bancaire~s~"}, Customs.List1, nil, {Preview}, true, {
                                onListChange = function(i, Index)
                                    Customs.List1 = i
                                end,
                                onSelected = function()
                                    local vehicle = ESX.Game.GetVehicleProperties(entity)
                                    if Customs.List1 == 1 then
                                        ESX.TriggerServerCallback("xCarDealer:sellCar_E", function(can) 
                                            if can then
                                                DeleteEntity(entity) entity = nil car = false
                                                select = {}
                                                RequestModel(GetHashKey(v.model))
                                                while not HasModelLoaded(GetHashKey(v.model)) do 
                                                Wait(1) 
                                                end
                                                local car = CreateVehicle(v.model, xCarDealer.Position.SpawnCarWhenBy.x, xCarDealer.Position.SpawnCarWhenBy.y, xCarDealer.Position.SpawnCarWhenBy.z, xCarDealer.Position.HeadingWhenBy, true, false)
                                                ESX.Game.SetVehicleProperties(car, vehicle)
                                                SetPedIntoVehicle(PlayerPedId(), car, -1)
                                                RageUI.CloseAll()
                                                FreezeEntityPosition(PlayerPedId(), false)
                                            end
                                        end, vehicle, tonumber(v.price))
                                    end
                                    if Customs.List1 == 2 then
                                        ESX.TriggerServerCallback("xCarDealer:sellCar_CB", function(can) 
                                            if can then
                                                DeleteEntity(entity) entity = nil car = false
                                                select = {}
                                                RequestModel(GetHashKey(v.model))
                                                while not HasModelLoaded(GetHashKey(v.model)) do 
                                                Wait(1) 
                                                end
                                                local car = CreateVehicle(v.model, xCarDealer.Position.SpawnCarWhenBy.x, xCarDealer.Position.SpawnCarWhenBy.y, xCarDealer.Position.SpawnCarWhenBy.z, xCarDealer.Position.HeadingWhenBy, true, false)
                                                ESX.Game.SetVehicleProperties(car, vehicle)
                                                SetPedIntoVehicle(PlayerPedId(), car, -1)
                                                RageUI.CloseAll()
                                                FreezeEntityPosition(PlayerPedId(), false)
                                            end
                                        end, vehicle, tonumber(v.price))
                                    end
                                end
                            })

                            RageUI.StatisticPanel((GetVehicleModelEstimatedMaxSpeed(GetHashKey(v.model))/60), "Vitesse maximal")
                            RageUI.StatisticPanel((GetVehicleModelMaxBraking(GetHashKey(v.model))/2), "Freinage")
                        end
                    end
                end)
            end
        end)
    end
end

-- Initialisation

Citizen.CreateThread(function()
    while true do
        local wait = 1000

        for k in pairs(xCarDealer.Position.Menu) do
            local pos = xCarDealer.Position.Menu
            local pPos = GetEntityCoords(PlayerPedId())
            local dst = Vdist(pPos.x, pPos.y, pPos.z, pos[k].x, pos[k].y, pos[k].z)

            if dst <= 10.0 then
                wait = 0
                DrawMarker(xCarDealer.MarkerType, pos[k].x, pos[k].y, (pos[k].z) - 1.0, 0.0, 0.0, 0.0, -90.0, 0.0, 0.0, xCarDealer.MarkerSizeLargeur, xCarDealer.MarkerSizeEpaisseur, xCarDealer.MarkerSizeHauteur, xCarDealer.MarkerColorR, xCarDealer.MarkerColorG, xCarDealer.MarkerColorB, xCarDealer.MarkerOpacite, xCarDealer.MarkerSaute, true, p19, xCarDealer.MarkerTourne)
            end
            if dst <= 2.0 then
                wait = 0
                if (not open) then 
                    DrawText3Ds(pos[k].x, pos[k].y, (pos[k].z), "Appuyer sur ~b~E~s~ pour ~b~consulter le catalogue~s~")
                end
                if IsControlJustPressed(1, 51) then
                    --FreezeEntityPosition(PlayerPedId(), true)
                    MenuConcessionnaire()
                    getCategories()
                end
            end
        end
        Citizen.Wait(wait)
    end
end)

-- Blips

Citizen.CreateThread(function()
    for k,v in pairs (xCarDealer.Blips.Pos) do
        local blips = AddBlipForCoord(v.x, v.y, v.z)
        SetBlipSprite(blips, xCarDealer.Blips.Model)
        SetBlipColour(blips, xCarDealer.Blips.Couleur)
        SetBlipScale(blips, xCarDealer.Blips.Taille)
        SetBlipAsShortRange(blips, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(xCarDealer.Blips.Title)
        EndTextCommandSetBlipName(blips)
    end
end)

--- Xed#1188 | https://discord.gg/HvfAsbgVpM
