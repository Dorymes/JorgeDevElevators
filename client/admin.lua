local isAdminOpen = false

-- Comando de admin para abrir el panel NUI
RegisterCommand(Config.AdminCommand, function()
    OpenAdminPanel()
end, false)

function OpenAdminPanel()
    if isAdminOpen then return end

    -- Pedir la data de ascensores al server
    local elevators = lib.callback.await('jorgedev-elevator:server:getElevators', false)
    if not elevators then elevators = {} end

    isAdminOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openAdmin',
        elevators = elevators,
    })
end

-- Cerrar panel admin
RegisterNUICallback('closeAdmin', function(data, cb)
    SetNuiFocus(false, false)
    isAdminOpen = false
    cb('ok')
end)

-- Obtener coordenadas actuales del jugador
RegisterNUICallback('admin:getCoords', function(data, cb)
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    SendNUIMessage({
        action = 'updateCoords',
        x = pos.x,
        y = pos.y,
        z = pos.z,
        heading = heading,
    })
    cb('ok')
end)

-- Teleportar a una planta (admin)
RegisterNUICallback('admin:teleport', function(data, cb)
    local ped = PlayerPedId()
    SetEntityCoords(ped, data.x + 0.0, data.y + 0.0, data.z + 0.0, false, false, false, false)
    SetEntityHeading(ped, data.heading + 0.0)
    cb('ok')
end)

-- Crear ascensor
RegisterNUICallback('admin:createElevator', function(data, cb)
    local success, id = lib.callback.await('jorgedev-elevator:server:createElevator', false, data.name)

    if success then
        SendNUIMessage({
            action = 'adminNotify',
            message = 'Ascensor "' .. data.name .. '" creado correctamente',
            type = 'success',
        })
        RefreshAdminData()
    else
        SendNUIMessage({
            action = 'adminNotify',
            message = id or 'Error al crear el ascensor',
            type = 'error',
        })
    end
    cb('ok')
end)

-- Renombrar ascensor
RegisterNUICallback('admin:renameElevator', function(data, cb)
    local success = lib.callback.await('jorgedev-elevator:server:renameElevator', false, data.elevatorId, data.name)

    if success then
        SendNUIMessage({
            action = 'adminNotify',
            message = 'Nombre actualizado correctamente',
            type = 'success',
        })
        RefreshAdminData()
    else
        SendNUIMessage({
            action = 'adminNotify',
            message = 'Error al renombrar',
            type = 'error',
        })
    end
    cb('ok')
end)

-- Eliminar ascensor
RegisterNUICallback('admin:deleteElevator', function(data, cb)
    local success = lib.callback.await('jorgedev-elevator:server:deleteElevator', false, data.elevatorId)

    if success then
        SendNUIMessage({
            action = 'adminNotify',
            message = 'Ascensor eliminado correctamente',
            type = 'success',
        })
        RefreshAdminData()
    else
        SendNUIMessage({
            action = 'adminNotify',
            message = 'Error al eliminar el ascensor',
            type = 'error',
        })
    end
    cb('ok')
end)

-- Añadir planta
RegisterNUICallback('admin:addFloor', function(data, cb)
    local floorData = data.floorData
    floorData.restricted_job = floorData.restricted_job or ''
    floorData.restricted_grade = floorData.restricted_grade or ''

    local success, id = lib.callback.await('jorgedev-elevator:server:addFloor', false, data.elevatorId, floorData)

    if success then
        SendNUIMessage({
            action = 'adminNotify',
            message = 'Planta "' .. floorData.label .. '" añadida correctamente',
            type = 'success',
        })
        RefreshAdminData()
    else
        SendNUIMessage({
            action = 'adminNotify',
            message = id or 'Error al añadir la planta',
            type = 'error',
        })
    end
    cb('ok')
end)

-- Editar planta
RegisterNUICallback('admin:editFloor', function(data, cb)
    local floorData = data.floorData
    floorData.restricted_job = floorData.restricted_job or ''
    floorData.restricted_grade = floorData.restricted_grade or ''

    local success = lib.callback.await('jorgedev-elevator:server:editFloor', false, data.elevatorId, data.floorId, floorData)

    if success then
        SendNUIMessage({
            action = 'adminNotify',
            message = 'Planta actualizada correctamente',
            type = 'success',
        })
        RefreshAdminData()
    else
        SendNUIMessage({
            action = 'adminNotify',
            message = 'Error al editar la planta',
            type = 'error',
        })
    end
    cb('ok')
end)

-- Eliminar planta
RegisterNUICallback('admin:removeFloor', function(data, cb)
    local success = lib.callback.await('jorgedev-elevator:server:removeFloor', false, data.elevatorId, data.floorId)

    if success then
        SendNUIMessage({
            action = 'adminNotify',
            message = 'Planta eliminada correctamente',
            type = 'success',
        })
        RefreshAdminData()
    else
        SendNUIMessage({
            action = 'adminNotify',
            message = 'Error al eliminar la planta',
            type = 'error',
        })
    end
    cb('ok')
end)

-- Actualizar tipo de interacción
RegisterNUICallback('admin:updateInteraction', function(data, cb)
    local success = lib.callback.await('jorgedev-elevator:server:updateInteraction', false,
        data.elevatorId, data.interactType, data.markerType, data.markerColor)

    if success then
        SendNUIMessage({
            action = 'adminNotify',
            message = 'Configuración de interacción actualizada',
            type = 'success',
        })
        RefreshAdminData()
    else
        SendNUIMessage({
            action = 'adminNotify',
            message = 'Error al actualizar la interacción',
            type = 'error',
        })
    end
    cb('ok')
end)

-- Refrescar datos del admin
function RefreshAdminData()
    if not isAdminOpen then return end

    local elevators = lib.callback.await('jorgedev-elevator:server:getElevators', false)
    if not elevators then elevators = {} end

    SendNUIMessage({
        action = 'updateElevators',
        elevators = elevators,
    })
end

-- =============================================
-- MODO POSICIONAMIENTO
-- Permite al admin moverse libremente para elegir posición
-- =============================================
local isPositioning = false

RegisterNUICallback('admin:enterPositionMode', function(data, cb)
    if isPositioning then
        cb('already')
        return
    end

    isPositioning = true

    -- Ocultar NUI admin y liberar cursor
    SetNuiFocus(true, false) -- NUI activa pero sin cursor (para que reciba mensajes)
    SendNUIMessage({ action = 'hideAdmin' })
    SendNUIMessage({ action = 'showPositioning' })

    -- Loop para actualizar coordenadas en vivo y esperar input
    CreateThread(function()
        while isPositioning do
            Wait(200)

            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)

            -- Actualizar coordenadas en la barra
            SendNUIMessage({
                action = 'updatePositionCoords',
                x = pos.x,
                y = pos.y,
                z = pos.z,
            })
        end
    end)

    CreateThread(function()
        -- Liberar NUI focus para que el jugador pueda moverse
        Wait(100)
        SetNuiFocus(false, false)
        -- Mantener el NUI frame activo para recibir mensajes
        SetNuiFocusKeepInput(false)

        while isPositioning do
            Wait(0)

            -- E para confirmar
            if IsControlJustPressed(0, 38) then
                local ped = PlayerPedId()
                local pos = GetEntityCoords(ped)
                local heading = GetEntityHeading(ped)

                isPositioning = false

                -- Ocultar barra y reabrir NUI
                SendNUIMessage({ action = 'hidePositioning' })
                SetNuiFocus(true, true)
                SendNUIMessage({ action = 'showAdmin' })
                SendNUIMessage({
                    action = 'updateCoords',
                    x = pos.x,
                    y = pos.y,
                    z = pos.z,
                    heading = heading,
                })
                SendNUIMessage({
                    action = 'adminNotify',
                    message = 'Posición confirmada',
                    type = 'success',
                })
                break
            end

            -- Backspace para cancelar
            if IsControlJustPressed(0, 177) then
                isPositioning = false

                -- Ocultar barra y reabrir NUI sin cambios
                SendNUIMessage({ action = 'hidePositioning' })
                SetNuiFocus(true, true)
                SendNUIMessage({ action = 'showAdmin' })
                SendNUIMessage({
                    action = 'adminNotify',
                    message = 'Posicionamiento cancelado',
                    type = 'info',
                })
                break
            end
        end
    end)

    cb('ok')
end)
