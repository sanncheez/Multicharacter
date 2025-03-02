local QBCore = exports['qb-core']:GetCoreObject()

-- Debug inicial
print('^2[QB-Multicharacter] Recurso iniciado correctamente^7')

local function DebugPrint(msg)
    if Config.Debug then
        print('^3[QB-Multicharacter] ' .. msg .. '^7')
    end
end

local function CreateCitizenId()
    local UniqueFound = false
    local CitizenId = nil
    while not UniqueFound do
        -- Generar ID único
        CitizenId = tostring(QBCore.Shared.RandomStr(3) .. QBCore.Shared.RandomInt(5)):upper()
        
        -- Verificar que no exista
        local result = exports.oxmysql:executeSync('SELECT COUNT(*) as count FROM qbcoreframework_b99476.players WHERE citizenid = ?', {CitizenId})
        if result[1].count == 0 then
            UniqueFound = true
        end
    end
    return CitizenId
end

-- Verificar conexión a la base de datos
CreateThread(function()
    if GetResourceState('oxmysql') ~= 'started' then
        print('^1[QB-Multicharacter] Error: oxmysql no está iniciado^7')
        return
    end

    Wait(1000) -- Esperar a que todo esté listo

    exports.oxmysql:execute('SELECT COUNT(*) as count FROM qbcoreframework_b99476.players', {}, function(result)
        if result and result[1] then
            print('^2[QB-Multicharacter] Base de datos conectada - Total jugadores: ' .. result[1].count .. '^7')
        else
            print('^1[QB-Multicharacter] Error: No se pudo obtener el conteo de jugadores^7')
        end
    end)
end)

-- Función para dar items iniciales
local function GiveStarterItems(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    for _, item in pairs(QBCore.Shared.StarterItems) do
        local info = {}
        if item.item == "id_card" then
            info = {
                citizenid = Player.PlayerData.citizenid,
                firstname = Player.PlayerData.charinfo.firstname,
                lastname = Player.PlayerData.charinfo.lastname,
                birthdate = Player.PlayerData.charinfo.birthdate,
                gender = Player.PlayerData.charinfo.gender,
                nationality = Player.PlayerData.charinfo.nationality
            }
        elseif item.item == "driver_license" then
            info = {
                firstname = Player.PlayerData.charinfo.firstname,
                lastname = Player.PlayerData.charinfo.lastname,
                birthdate = Player.PlayerData.charinfo.birthdate,
                type = "Class C Driver License"
            }
        end
        Player.Functions.AddItem(item.item, item.amount, false, info)
    end
end

-- Callbacks
QBCore.Functions.CreateCallback('qb-multicharacter:server:GetCharacters', function(source, cb)
    local src = source
    local license = QBCore.Functions.GetIdentifier(src, 'license')
    
    if not license then 
        DebugPrint('Error: No se encontró licencia para source: ' .. src)
        cb({})
        return
    end

    exports.oxmysql:execute('SELECT * FROM qbcoreframework_b99476.players WHERE license = ?', {license}, function(result)
        if not result then
            cb({})
            return
        end

        local characters = {}
        for i = 1, #result do
            local charData = result[i]
            
            -- Decodificar JSON con manejo de errores
            local success, charinfo = pcall(json.decode, charData.charinfo)
            if not success then charinfo = {} end
            
            success, money = pcall(json.decode, charData.money)
            if not success then money = {cash = Config.StartingCash, bank = Config.StartingBank} end
            
            success, job = pcall(json.decode, charData.job)
            if not success then job = {name = "unemployed", label = "Desempleado"} end

            table.insert(characters, {
                citizenid = charData.citizenid,
                license = charData.license,
                charinfo = charinfo,
                money = money,
                job = job
            })
            
            DebugPrint('Personaje cargado - CitizenID: ' .. charData.citizenid)
        end

        cb(characters)
    end)
end)

-- Eventos
RegisterNetEvent('qb-multicharacter:server:createCharacter', function(data)
    local src = source
    local license = QBCore.Functions.GetIdentifier(src, 'license')
    
    if not license or not data.firstname or not data.lastname then 
        DebugPrint('Error: Datos inválidos para crear personaje')
        return 
    end

    local citizenid = CreateCitizenId()
    local newCharData = {
        citizenid = citizenid,
        license = license,
        name = data.firstname .. ' ' .. data.lastname,
        charinfo = json.encode({
            firstname = data.firstname,
            lastname = data.lastname,
            birthdate = data.birthdate,
            gender = data.gender,
            nationality = data.nationality
        }),
        money = json.encode({
            cash = Config.StartingCash,
            bank = Config.StartingBank
        }),
        job = json.encode({
            name = "unemployed",
            label = "Desempleado",
            payment = 10,
            type = "none"
        }),
        position = json.encode(Config.DefaultSpawn),
        metadata = json.encode({})
    }

    exports.oxmysql:insert('INSERT INTO qbcoreframework_b99476.players (citizenid, license, name, charinfo, money, job, position, metadata) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        {
            newCharData.citizenid, 
            newCharData.license, 
            newCharData.name,
            newCharData.charinfo, 
            newCharData.money, 
            newCharData.job,
            newCharData.position,
            newCharData.metadata
        },
        function(id)
            if id then
                DebugPrint('Personaje creado con CitizenID: ' .. citizenid)
                
                -- Hacer login del jugador
                QBCore.Player.Login(src, citizenid, false, function()
                    local Player = QBCore.Functions.GetPlayer(src)
                    if Player then
                        -- Dar items iniciales si está configurado
                        if Config.GiveStarterItems then
                            GiveStarterItems(src)
                        end
                        
                        -- Abrir el selector de spawn
                        TriggerClientEvent('qb-spawn:client:setupSpawns', src, nil, true) -- true indica que es nuevo personaje
                        TriggerClientEvent('qb-spawn:client:openUI', src, true)
                        
                        -- Guardar que es un nuevo personaje para abrir clothing después
                        Player.Functions.SetMetaData("isNewCharacter", true)
                    end
                end)
            else
                DebugPrint('Error al crear personaje para license: ' .. license)
            end
        end
    )
end)

RegisterNetEvent('qb-multicharacter:server:deleteCharacter', function(citizenid)
    local src = source
    local license = QBCore.Functions.GetIdentifier(src, 'license')
    
    if not license or not citizenid then 
        DebugPrint('Error: Datos inválidos para eliminar personaje')
        return 
    end

    exports.oxmysql:execute('DELETE FROM qbcoreframework_b99476.players WHERE citizenid = ? AND license = ?', {citizenid, license},
        function(result)
            if result and result.affectedRows > 0 then
                DebugPrint('Personaje eliminado: ' .. citizenid)
                TriggerClientEvent('qb-multicharacter:client:setupCharacters', src)
            else
                DebugPrint('Error al eliminar personaje: ' .. citizenid)
            end
        end
    )
end)

RegisterNetEvent('qb-multicharacter:server:loadUserData', function(citizenid)
    local src = source
    local license = QBCore.Functions.GetIdentifier(src, 'license')
    
    if not license or not citizenid then 
        DebugPrint('Error: Falta license o citizenid')
        return 
    end

    -- Usar el método Login de QB-Core
    QBCore.Player.Login(src, citizenid, false, function()
        DebugPrint('Jugador cargado: ' .. citizenid)
        
        -- Obtener los datos actualizados del jugador
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            Wait(1000) -- Esperamos a que todo esté listo
            
            -- Trigger para el cliente con la posición guardada
            if Player.PlayerData.position then
                TriggerClientEvent('qb-spawn:client:setupSpawns', src, Player.PlayerData.position)
                TriggerClientEvent('qb-spawn:client:openUI', src)
            else
                TriggerClientEvent('qb-spawn:client:setupSpawns', src)
                TriggerClientEvent('qb-spawn:client:openUI', src)
            end
        end
    end)
end)
