local weaponProps = nil
local bagProps = nil
local isPlayingAnim = false
local currentDict = nil
local currentAnim = nil

-- Función para obtener el ped existente
local function GetExistingPed()
    -- Obtener todos los peds en un radio de 3.0 unidades de las coordenadas
    local coords = Config.PedCoords
    local peds = GetGamePool('CPed')
    
    for _, ped in ipairs(peds) do
        if DoesEntityExist(ped) then
            local pedCoords = GetEntityCoords(ped)
            local distance = #(vector3(coords.x, coords.y, coords.z) - pedCoords)
            
            if distance < 3.0 then
                return ped
            end
        end
    end
    return nil
end

-- Función para limpiar props y animaciones
local function ClearCurrentAnim()
    local ped = GetExistingPed()
    if not ped then return end
    
    ClearPedTasksImmediately(ped)
    RemoveAllPedWeapons(ped, true)
    
    if weaponProps then
        DeleteObject(weaponProps)
        weaponProps = nil
    end
    
    if bagProps then
        DeleteObject(bagProps)
        bagProps = nil
    end
    
    isPlayingAnim = false
    currentDict = nil
    currentAnim = nil
end

RegisterNUICallback('updatePlayerAnim', function(data, cb)
    local ped = GetExistingPed()
    if not ped then 
        print("No se encontró el ped")
        cb('error')
        return 
    end
    
    if data.anim == "robber" then
        ClearCurrentAnim()
        currentDict = "random@arrests"
        currentAnim = "arrest_weapon"
        
        -- Cargar la escopeta
        GiveWeaponToPed(ped, GetHashKey("WEAPON_PUMPSHOTGUN"), 0, false, true)
        SetCurrentPedWeapon(ped, GetHashKey("WEAPON_PUMPSHOTGUN"), true)
        
        -- Crear y adjuntar la bolsa
        local bagHash = GetHashKey("prop_cs_heist_bag_01")
        RequestModel(bagHash)
        while not HasModelLoaded(bagHash) do Wait(0) end
        
        bagProps = CreateObject(bagHash, 0, 0, 0, true, true, true)
        AttachEntityToEntity(bagProps, ped, GetPedBoneIndex(ped, 57005), 0.15, 0, -0.05, 0, 270.0, 180.0, true, true, false, true, 1, true)
        
        -- Cargar y reproducir animación
        RequestAnimDict(currentDict)
        while not HasAnimDictLoaded(currentDict) do Wait(0) end
        
        TaskPlayAnim(ped, currentDict, currentAnim, 8.0, -8.0, -1, 1, 0, false, false, false)
        RemoveAnimDict(currentDict)
        
    elseif data.anim == "cop2" then
        ClearCurrentAnim()
        currentDict = "amb@world_human_cop_idles@male@idle_b"
        currentAnim = "idle_d"
        
        RequestAnimDict(currentDict)
        while not HasAnimDictLoaded(currentDict) do Wait(0) end
        
        TaskPlayAnim(ped, currentDict, currentAnim, 8.0, -8.0, -1, 1, 0, false, false, false)
        RemoveAnimDict(currentDict)
        
    elseif data.anim == "nothing" then
        ClearCurrentAnim()
    end
    
    isPlayingAnim = true
    cb('ok')
end)

-- Agregar un evento para debug
RegisterNetEvent('qb-multicharacter:client:setupCharacters', function()
    Wait(1000) -- Esperar a que el ped se cree
    local ped = GetExistingPed()
    if ped then
        print("Ped encontrado:", ped)
    else
        print("No se encontró el ped")
    end
end)