local QBCore = exports['qb-core']:GetCoreObject()
local cam = nil
local charPed = nil
local loadingScreen = false

-- Variables locales para el manejo de la cámara
local function LoadCamera()
    DoScreenFadeOut(10)
    SetTimecycleModifier('default')
    SetTimecycleModifierStrength(0.8)
    cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", Config.CamCoords.x, Config.CamCoords.y, Config.CamCoords.z, 0.0, 0.0, Config.CamCoords.w, 60.00, false, 0)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 1, true, true)
end

-- Función para destruir la cámara
local function DeleteCamera()
    if cam then
        SetCamActive(cam, false)
        DestroyCam(cam, true)
        RenderScriptCams(false, false, 1, true, true)
        cam = nil
    end
end

-- Crear PED para la previsualización
local function CreateCharacterPed()
    local model = `mp_m_freemode_01`
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
    
    charPed = CreatePed(2, model, Config.PedCoords.x, Config.PedCoords.y, Config.PedCoords.z - 0.98, Config.PedCoords.w, false, true)
    SetPedComponentVariation(charPed, 0, 0, 0, 2)
    FreezeEntityPosition(charPed, true)
    SetEntityInvincible(charPed, true)
    PlaceObjectOnGroundProperly(charPed)
    SetBlockingOfNonTemporaryEvents(charPed, true)
end

-- Eliminar PED
local function DeleteCharacterPed()
    if charPed then
        DeleteEntity(charPed)
    end
end

-- Función para cargar la interfaz
-- Modificar la función LoadInterface
local function LoadInterface()
    loadingScreen = true
    DoScreenFadeOut(10)
    Wait(1000)
    
    LoadCamera()
    CreateCharacterPed()
    
    Wait(500)
    
    -- Obtener los personajes del servidor
    QBCore.Functions.TriggerCallback('qb-multicharacter:server:GetCharacters', function(chars)
        SendNUIMessage({
            action = "openUI",
            characters = chars or {} -- Asegurarse de que siempre enviamos un array
        })
        SetNuiFocus(true, true)
        DoScreenFadeIn(250)
        loadingScreen = false
    end)
end

-- Eventos NUI
RegisterNUICallback('closeUI', function()
    SetNuiFocus(false, false)
    DeleteCamera()
    DeleteCharacterPed()
    DoScreenFadeOut(250)
    Wait(1000)
    DoScreenFadeIn(250)
end)

RegisterNUICallback('selectCharacter', function(data, cb)
    if not data.citizenid then return cb("error") end
    
    DoScreenFadeOut(150)
    TriggerServerEvent('qb-multicharacter:server:loadUserData', data.citizenid)
    
    CreateThread(function()
        local attempts = 0
        while attempts < 20 do
            local Player = QBCore.Functions.GetPlayerData()
            if Player and Player.citizenid then
                -- Limpiamos la UI y la cámara
                SendNUIMessage({
                    action = "closeUI"
                })
                SetNuiFocus(false, false)
                
                -- Limpiamos los elementos visuales
                if cam then
                    DestroyCam(cam, true)
                    RenderScriptCams(false, true, 500, true, true)
                    SetCamActive(cam, false)
                    cam = nil
                end
                if charPed then
                    DeleteEntity(charPed)
                    charPed = nil
                end
                
                -- Abrimos el spawn selector oficial de QB
                TriggerEvent('qb-spawn:openUI', true)
                break
            end
            attempts = attempts + 1
            Wait(500)
        end
    end)
    
    cb("ok")
end)
-- Eventos del servidor
RegisterNetEvent('qb-multicharacter:client:openUI')
AddEventHandler('qb-multicharacter:client:openUI', function()
    LoadInterface()
end)

-- Actualizar apariencia del PED
RegisterNetEvent('qb-multicharacter:client:updatePed')
AddEventHandler('qb-multicharacter:client:updatePed', function(data)
    if charPed and data then
        SetPedComponentVariation(charPed, 0, data.face, 0, 2)
        SetPedComponentVariation(charPed, 2, data.hair, 0, 2)
        SetPedComponentVariation(charPed, 4, data.pants, 0, 2)
        SetPedComponentVariation(charPed, 6, data.shoes, 0, 2)
        SetPedComponentVariation(charPed, 11, data.jacket, 0, 2)
    end
end)

-- Cleanup al salir del recurso
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        DeleteCamera()
        DeleteCharacterPed()
        SetNuiFocus(false, false)
    end
end)