Elevators = {}

-- Auto-crear tablas al iniciar
CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `jorge_elevators` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `name` VARCHAR(100) NOT NULL,
            `created_by` VARCHAR(60) DEFAULT NULL,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `jorge_elevator_floors` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `elevator_id` INT NOT NULL,
            `floor_index` INT NOT NULL DEFAULT 0,
            `label` VARCHAR(100) NOT NULL,
            `x` FLOAT NOT NULL,
            `y` FLOAT NOT NULL,
            `z` FLOAT NOT NULL,
            `heading` FLOAT NOT NULL DEFAULT 0.0,
            `restricted_job` VARCHAR(60) DEFAULT NULL,
            `restricted_grade` INT DEFAULT NULL,
            FOREIGN KEY (`elevator_id`) REFERENCES `jorge_elevators`(`id`) ON DELETE CASCADE
        )
    ]])

    -- Migrate: add interact_type, marker_type and marker_color if not exist
    pcall(function()
        MySQL.query.await("ALTER TABLE `jorge_elevators` ADD COLUMN `interact_type` VARCHAR(20) NOT NULL DEFAULT 'marker'")
    end)
    pcall(function()
        MySQL.query.await("ALTER TABLE `jorge_elevators` ADD COLUMN `marker_type` INT NOT NULL DEFAULT 20")
    end)
    pcall(function()
        MySQL.query.await("ALTER TABLE `jorge_elevators` ADD COLUMN `marker_color` VARCHAR(30) DEFAULT '100,100,255,100'")
    end)

    -- Cargar ascensores
    Wait(500)
    local elevators = MySQL.query.await('SELECT * FROM jorge_elevators')
    if not elevators then
        print('^2[JorgeDev-Elevator]^0 Loaded 0 elevators')
        return
    end

    for _, elevator in ipairs(elevators) do
        local floors = MySQL.query.await('SELECT * FROM jorge_elevator_floors WHERE elevator_id = ? ORDER BY floor_index ASC', { elevator.id })
        Elevators[elevator.id] = {
            id = elevator.id,
            name = elevator.name,
            created_by = elevator.created_by,
            interact_type = elevator.interact_type or 'marker',
            marker_type = elevator.marker_type or 20,
            marker_color = elevator.marker_color or '100,100,255,100',
            floors = floors or {}
        }
    end

    print('^2[JorgeDev-Elevator]^0 Loaded ' .. #elevators .. ' elevators')
end)

-- Callback para obtener todos los ascensores
lib.callback.register('jorgedev-elevator:server:getElevators', function(source)
    return Elevators
end)

-- Callback para obtener el job del jugador
lib.callback.register('jorgedev-elevator:server:getPlayerJob', function(source)
    local job, grade = GetPlayerJobInfo(source)
    return job, grade
end)

-- Callback para obtener las plantas de un ascensor
lib.callback.register('jorgedev-elevator:server:getFloors', function(source, elevatorId)
    if not Elevators[elevatorId] then return {} end
    return Elevators[elevatorId].floors
end)

-- Callback para verificar si el jugador puede acceder a una planta
lib.callback.register('jorgedev-elevator:server:canAccessFloor', function(source, elevatorId, floorId)
    if not Elevators[elevatorId] then return false end

    local floor = nil
    for _, f in ipairs(Elevators[elevatorId].floors) do
        if f.id == floorId then
            floor = f
            break
        end
    end

    if not floor then return false end

    -- Si no hay restricción, acceso libre
    if not floor.restricted_job or floor.restricted_job == '' then
        return true
    end

    -- Verificar job y grado
    local playerJob, playerGrade = GetPlayerJobInfo(source)

    local requiredJobs = {}
    for job in string.gmatch(floor.restricted_job, "[^,]+") do
        local cleanJob = job:match("^%s*(.-)%s*$")
        if cleanJob and cleanJob ~= "" then
            table.insert(requiredJobs, string.lower(cleanJob))
        end
    end

    local jobMatch = false
    local playerJobLower = string.lower(playerJob)
    
    for _, job in ipairs(requiredJobs) do
        if playerJobLower == job then
            jobMatch = true
            break
        end
    end

    if not jobMatch then
        return false, 'No tienes el trabajo requerido para esta planta'
    end

    if floor.restricted_grade and playerGrade < floor.restricted_grade then
        return false, 'No tienes el grado suficiente para esta planta'
    end

    return true
end)

-- Teleportar jugador a una planta
RegisterNetEvent('jorgedev-elevator:server:teleportToFloor', function(elevatorId, floorId)
    local source = source
    if not Elevators[elevatorId] then return end

    local floor = nil
    for _, f in ipairs(Elevators[elevatorId].floors) do
        if f.id == floorId then
            floor = f
            break
        end
    end

    if not floor then return end

    -- Verificar acceso server-side
    if floor.restricted_job and floor.restricted_job ~= '' then
        local playerJob, playerGrade = GetPlayerJobInfo(source)
        if playerJob ~= floor.restricted_job then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Ascensor',
                description = 'No tienes acceso a esta planta',
                type = 'error'
            })
            return
        end
        if floor.restricted_grade and playerGrade < floor.restricted_grade then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Ascensor',
                description = 'No tienes el grado suficiente',
                type = 'error'
            })
            return
        end
    end

    TriggerClientEvent('jorgedev-elevator:client:travelToFloor', source, elevatorId, floor)
end)

-- Obtener info del job del jugador
function GetPlayerJobInfo(source)
    if Config.Framework == 'qb' then
        local success, jobName, jobGrade = pcall(function()
            local QBCore = exports['qb-core']:GetCoreObject()
            local Player = QBCore.Functions.GetPlayer(source)
            if Player then
                return Player.PlayerData.job.name, Player.PlayerData.job.grade.level
            end
            return 'unemployed', 0
        end)
        if success then
            return jobName, jobGrade
        end
    elseif Config.Framework == 'esx' then
        local success, jobName, jobGrade = pcall(function()
            local ESX = exports['es_extended']:getSharedObject()
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then
                return xPlayer.getJob().name, xPlayer.getJob().grade
            end
            return 'unemployed', 0
        end)
        if success then
            return jobName, jobGrade
        end
    end
    return 'unemployed', 0
end

-- Obtener identificador del jugador de forma segura
function GetPlayerIdentifier(source)
    local identifier = nil
    pcall(function()
        identifier = GetPlayerIdentifierByType(source, 'license')
    end)
    if not identifier then
        local ids = GetPlayerIdentifiers(source)
        for _, id in ipairs(ids) do
            if string.find(id, 'license:') then
                identifier = id
                break
            end
        end
    end
    return identifier or 'unknown'
end

-- Refrescar ascensores para todos los clientes
function RefreshElevatorsForAll()
    TriggerClientEvent('jorgedev-elevator:client:refreshElevators', -1)
end
