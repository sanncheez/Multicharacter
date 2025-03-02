local QBCore = exports['qb-core']:GetCoreObject()
local cam = nil
local charPed = nil

-- Variables de configuración
local defaultModels = {
    'mp_m_freemode_01',
    'mp_f_freemode_01',
}

CreateThread(function()
    while true do
        Wait(0)
        if NetworkIsSessionStarted() then
            -- Forzar cierre de loading screen
            ShutdownLoadingScreen()
            ShutdownLoadingScreenNui()
            Wait(100)
            -- Iniciar multicharacter
            TriggerEvent('qb-multicharacter:client:chooseChar')
            return
        end
    end
end)

-- Funciones auxiliares
local function DebugPrint(msg)
    if Config.Debug then
        print('^3[QB-Multicharacter] ' .. msg .. '^7')
    end
end

local function loadModel(model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
end

local function createCharacterPed(model)
    if charPed then
        DeleteEntity(charPed)
    end

    if not model then
        model = defaultModels[1]
    end

    loadModel(model)
    
    charPed = CreatePed(2, model, Config.PedCoords.x, Config.PedCoords.y, Config.PedCoords.z - 0.98, Config.PedCoords.w, false, true)
    SetPedComponentVariation(charPed, 0, 0, 0, 2)
    FreezeEntityPosition(charPed, false)
    SetEntityInvincible(charPed, true)
    PlaceObjectOnGroundProperly(charPed)
    SetBlockingOfNonTemporaryEvents(charPed, true)
end

local function setupCamera()
    if cam then
        DestroyCam(cam, true)
    end

    cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", 
        Config.CamCoords.x, 
        Config.CamCoords.y, 
        Config.CamCoords.z, 
        0.0, 0.0, Config.CamCoords.w, 
        60.00, false, 0)
    
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 1, true, true)
end

local function cleanupUI()
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

    SetNuiFocus(false, false)
end

-- Eventos principales
RegisterNetEvent('qb-multicharacter:client:chooseChar', function()
    SetNuiFocus(false, false)
    DoScreenFadeOut(10)
    Wait(1000)
    
    -- Cargar interior
    local interior = GetInteriorAtCoords(Config.Interior.x, Config.Interior.y, Config.Interior.z)
    LoadInterior(interior)
    while not IsInteriorReady(interior) do
        Wait(1000)
    end

    -- Posicionar jugador
    FreezeEntityPosition(PlayerPedId(), true)
    SetEntityCoords(PlayerPedId(), Config.HiddenCoords.x, Config.HiddenCoords.y, Config.HiddenCoords.z)
    Wait(1500)
    
    -- Solicitar personajes
    QBCore.Functions.TriggerCallback('qb-multicharacter:server:GetCharacters', function(chars)
        DebugPrint('Personajes recibidos: ' .. #chars)
        SendNUIMessage({
            action = "setupCharacters",
            characters = chars
        })
        setupCamera()
        createCharacterPed()
        SetNuiFocus(true, true)
        DoScreenFadeIn(1000)
    end)
end)

-- Callbacks NUI
RegisterNUICallback('selectCharacter', function(data, cb)
    if not data.citizenid then return cb("error") end
    
    DoScreenFadeOut(150)
    TriggerServerEvent('qb-multicharacter:server:loadUserData', data.citizenid)
    
    CreateThread(function()
        local attempts = 0
        while attempts < 20 do
            local Player = QBCore.Functions.GetPlayerData()
            if Player and Player.citizenid then
                -- Limpiar UI y elementos visuales
                cleanupUI()
                SendNUIMessage({ action = "closeUI" })
                
                -- Abrir el selector de spawn de QB
                TriggerEvent('qb-spawn:client:openUI', true)
                
                -- Asegurarse de que el jugador está listo para el spawn
                TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
                TriggerEvent('QBCore:Client:OnPlayerLoaded')
                
                break
            end
            attempts = attempts + 1
            Wait(500)
        end

        if attempts >= 20 then
            DebugPrint('Error: Tiempo de espera agotado al cargar datos del jugador')
        end
    end)
    
    cb("ok")
end)

RegisterNUICallback('createCharacter', function(data, cb)
    if not data.firstname or not data.lastname then 
        return cb("error") 
    end
    
    DoScreenFadeOut(150)
    TriggerServerEvent('qb-multicharacter:server:createCharacter', data)
    cb("ok")
end)

RegisterNUICallback('deleteCharacter', function(data, cb)
    if not data.citizenid then return cb("error") end
    
    TriggerServerEvent('qb-multicharacter:server:deleteCharacter', data.citizenid)
    cb("ok")
end)

RegisterNUICallback('closeUI', function(_, cb)
    cleanupUI()
    cb("ok")
end)

-- Thread inicial
CreateThread(function()
    while true do
        Wait(0)
        if NetworkIsSessionStarted() then
            TriggerEvent('qb-multicharacter:client:chooseChar')
            return
        end
    end
end)

-- Cleanup al detener el recurso
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        cleanupUI()
        DoScreenFadeIn(500)
    end
end)