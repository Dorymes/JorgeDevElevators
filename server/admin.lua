-- Verificar si un jugador es admin
function IsPlayerAdmin(source)
    -- 1. Verificar ace permissions
    for _, group in ipairs(Config.AdminGroups) do
        if IsPlayerAceAllowed(source, 'group.' .. group) then
            return true
        end
    end

    -- 2. Verificar con QBCore
    if Config.Framework == 'qb' then
        local success, QBCore = pcall(function()
            return exports['qb-core']:GetCoreObject()
        end)
        if success and QBCore then
            local Player = QBCore.Functions.GetPlayer(source)
            if Player then
                -- Verificar permisos QBCore
                for _, group in ipairs(Config.AdminGroups) do
                    if QBCore.Functions.HasPermission(source, group) then
                        return true
                    end
                end
                -- También verificar si es god/admin por PlayerData
                local permission = Player.PlayerData.permission or ''
                for _, group in ipairs(Config.AdminGroups) do
                    if permission == group then
                        return true
                    end
                end
            end
        end
    end

    -- 3. Verificar con ESX
    if Config.Framework == 'esx' then
        local success, ESX = pcall(function()
            return exports['es_extended']:getSharedObject()
        end)
        if success and ESX then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then
                local playerGroup = xPlayer.getGroup()
                for _, group in ipairs(Config.AdminGroups) do
                    if playerGroup == group then
                        return true
                    end
                end
            end
        end
    end

    return false
end

-- Crear un nuevo ascensor
lib.callback.register('jorgedev-elevator:server:createElevator', function(source, name)
    if not IsPlayerAdmin(source) then
        return false, 'No tienes permisos'
    end

    local identifier = GetPlayerIdentifier(source)

    local success, id = pcall(function()
        return MySQL.insert.await('INSERT INTO jorge_elevators (name, created_by, interact_type, marker_type, marker_color) VALUES (?, ?, ?, ?, ?)', {
            name,
            identifier,
            'marker',
            20,
            '100,100,255,100'
        })
    end)

    if success and id then
        Elevators[id] = {
            id = id,
            name = name,
            created_by = identifier,
            interact_type = 'marker',
            marker_type = 20,
            marker_color = '100,100,255,100',
            floors = {}
        }
        RefreshElevatorsForAll()
        return true, id
    end

    print('^1[JorgeDev-Elevator]^0 Error creating elevator: ' .. tostring(id))
    return false, 'Error al crear el ascensor (revisa la consola)'
end)

-- Añadir una planta a un ascensor
lib.callback.register('jorgedev-elevator:server:addFloor', function(source, elevatorId, floorData)
    if not IsPlayerAdmin(source) then
        return false, 'No tienes permisos'
    end

    if not Elevators[elevatorId] then
        return false, 'Ascensor no encontrado'
    end

    local floorIndex = floorData.floor_index or #Elevators[elevatorId].floors

    local success, id = pcall(function()
        return MySQL.insert.await([[
            INSERT INTO jorge_elevator_floors (elevator_id, floor_index, label, x, y, z, heading, restricted_job, restricted_grade)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]], {
            elevatorId,
            floorIndex,
            floorData.label,
            floorData.x + 0.0,
            floorData.y + 0.0,
            floorData.z + 0.0,
            floorData.heading + 0.0,
            floorData.restricted_job ~= '' and floorData.restricted_job or nil,
            floorData.restricted_grade ~= '' and tonumber(floorData.restricted_grade) or nil
        })
    end)

    if success and id then
        local newFloor = {
            id = id,
            elevator_id = elevatorId,
            floor_index = floorIndex,
            label = floorData.label,
            x = floorData.x,
            y = floorData.y,
            z = floorData.z,
            heading = floorData.heading,
            restricted_job = floorData.restricted_job ~= '' and floorData.restricted_job or nil,
            restricted_grade = floorData.restricted_grade ~= '' and tonumber(floorData.restricted_grade) or nil
        }
        table.insert(Elevators[elevatorId].floors, newFloor)
        RefreshElevatorsForAll()
        return true, id
    end

    print('^1[JorgeDev-Elevator]^0 Error adding floor: ' .. tostring(id))
    return false, 'Error al añadir la planta'
end)

-- Eliminar una planta
lib.callback.register('jorgedev-elevator:server:removeFloor', function(source, elevatorId, floorId)
    if not IsPlayerAdmin(source) then
        return false, 'No tienes permisos'
    end

    if not Elevators[elevatorId] then
        return false, 'Ascensor no encontrado'
    end

    local success, err = pcall(function()
        MySQL.query.await('DELETE FROM jorge_elevator_floors WHERE id = ?', { floorId })
    end)

    if not success then
        print('^1[JorgeDev-Elevator]^0 Error deleting floor: ' .. tostring(err))
        return false, 'Error al eliminar la planta'
    end

    for i, floor in ipairs(Elevators[elevatorId].floors) do
        if floor.id == floorId then
            table.remove(Elevators[elevatorId].floors, i)
            break
        end
    end

    RefreshElevatorsForAll()
    return true
end)

-- Eliminar un ascensor completo
lib.callback.register('jorgedev-elevator:server:deleteElevator', function(source, elevatorId)
    if not IsPlayerAdmin(source) then
        return false, 'No tienes permisos'
    end

    if not Elevators[elevatorId] then
        return false, 'Ascensor no encontrado'
    end

    local success, err = pcall(function()
        -- Borrar pisos primero (por si no hay CASCADE)
        MySQL.query.await('DELETE FROM jorge_elevator_floors WHERE elevator_id = ?', { elevatorId })
        MySQL.query.await('DELETE FROM jorge_elevators WHERE id = ?', { elevatorId })
    end)

    if not success then
        print('^1[JorgeDev-Elevator]^0 Error deleting elevator: ' .. tostring(err))
        return false, 'Error al eliminar el ascensor'
    end

    Elevators[elevatorId] = nil

    RefreshElevatorsForAll()
    return true
end)

-- Editar una planta
lib.callback.register('jorgedev-elevator:server:editFloor', function(source, elevatorId, floorId, floorData)
    if not IsPlayerAdmin(source) then
        return false, 'No tienes permisos'
    end

    if not Elevators[elevatorId] then
        return false, 'Ascensor no encontrado'
    end

    MySQL.query.await([[
        UPDATE jorge_elevator_floors
        SET label = ?, x = ?, y = ?, z = ?, heading = ?, restricted_job = ?, restricted_grade = ?
        WHERE id = ?
    ]], {
        floorData.label,
        floorData.x,
        floorData.y,
        floorData.z,
        floorData.heading,
        floorData.restricted_job ~= '' and floorData.restricted_job:match("^%s*(.-)%s*$") or nil,
        floorData.restricted_grade ~= '' and tonumber(floorData.restricted_grade) or nil,
        floorId
    })

    for i, floor in ipairs(Elevators[elevatorId].floors) do
        if floor.id == floorId then
            Elevators[elevatorId].floors[i] = {
                id = floorId,
                elevator_id = elevatorId,
                floor_index = floor.floor_index,
                label = floorData.label,
                x = floorData.x,
                y = floorData.y,
                z = floorData.z,
                heading = floorData.heading,
                restricted_job = floorData.restricted_job ~= '' and floorData.restricted_job or nil,
                restricted_grade = floorData.restricted_grade ~= '' and tonumber(floorData.restricted_grade) or nil
            }
            break
        end
    end

    RefreshElevatorsForAll()
    return true
end)

-- Renombrar ascensor
lib.callback.register('jorgedev-elevator:server:renameElevator', function(source, elevatorId, newName)
    if not IsPlayerAdmin(source) then
        return false, 'No tienes permisos'
    end

    if not Elevators[elevatorId] then
        return false, 'Ascensor no encontrado'
    end

    MySQL.query.await('UPDATE jorge_elevators SET name = ? WHERE id = ?', { newName, elevatorId })
    Elevators[elevatorId].name = newName

    RefreshElevatorsForAll()
    return true
end)

-- Actualizar tipo de interacción (marker / ox_target), tipo de marker y color
lib.callback.register('jorgedev-elevator:server:updateInteraction', function(source, elevatorId, interactType, markerType, markerColor)
    if not IsPlayerAdmin(source) then
        return false, 'No tienes permisos'
    end

    if not Elevators[elevatorId] then
        return false, 'Ascensor no encontrado'
    end

    interactType = interactType or 'marker'
    markerType = tonumber(markerType) or 20
    markerColor = markerColor or '100,100,255,100'

    MySQL.query.await('UPDATE jorge_elevators SET interact_type = ?, marker_type = ?, marker_color = ? WHERE id = ?', {
        interactType, markerType, markerColor, elevatorId
    })

    Elevators[elevatorId].interact_type = interactType
    Elevators[elevatorId].marker_type = markerType
    Elevators[elevatorId].marker_color = markerColor

    RefreshElevatorsForAll()
    return true
end)
