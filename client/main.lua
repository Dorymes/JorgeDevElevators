local Elevators = {}
local nearestElevator = nil
local nearestFloor = nil
local isInsideElevator = false
local currentElevatorId = nil
local isTraveling = false
local targetZones = {}

-- Cargar ascensores
CreateThread(function()
    Wait(1000)
    LoadElevators()
end)

function LoadElevators()
    Elevators = lib.callback.await('jorgedev-elevator:server:getElevators', false)
    if not Elevators then Elevators = {} end
    SetupInteractions()
end

RegisterNetEvent('jorgedev-elevator:client:refreshElevators', function()
    print('[JorgeDev-Elevator] Received refresh request from server')
    LoadElevators()
end)

RegisterCommand('debugElevators', function()
    LoadElevators()
    print('[JorgeDev-Elevator] Manual reload. Current Data:')
    for _, elev in pairs(Elevators) do
        print('Elevator:', elev.name)
        for _, floor in ipairs(elev.floors) do
            print(string.format(' - Floor: %s | Job: %s', floor.label, tostring(floor.restricted_job)))
        end
    end
end)

-- Parse marker color string "r,g,b,a" -> table
function ParseMarkerColor(colorStr)
    if not colorStr or colorStr == '' then
        return { r = 100, g = 100, b = 255, a = 100 }
    end
    local parts = {}
    for v in string.gmatch(colorStr, '([^,]+)') do
        parts[#parts + 1] = tonumber(v) or 100
    end
    return {
        r = parts[1] or 100,
        g = parts[2] or 100,
        b = parts[3] or 255,
        a = parts[4] or 100,
    }
end

-- Setup interactions (ox_target zones or marker detection)
function SetupInteractions()
    -- Remove existing ox_target zones
    for _, zoneId in ipairs(targetZones) do
        pcall(function() exports.ox_target:removeZone(zoneId) end)
    end
    targetZones = {}

    -- Create ox_target zones for elevators that use ox_target
    for elevId, elevator in pairs(Elevators) do
        if elevator.interact_type == 'ox_target' and elevator.floors then
            for _, floor in ipairs(elevator.floors) do
                local zoneId = exports.ox_target:addSphereZone({
                    coords = vector3(floor.x, floor.y, floor.z),
                    radius = Config.InteractionDistance,
                    debug = false,
                    options = {
                        {
                            name = 'elevator_' .. elevId .. '_' .. floor.id,
                            icon = 'fa-solid fa-elevator',
                            label = 'Ascensor - ' .. elevator.name,
                            onSelect = function()
                                nearestElevator = elevator
                                nearestFloor = floor
                                OpenElevatorPanel(elevator)
                            end,
                        },
                    },
                })
                table.insert(targetZones, zoneId)
            end
        end
    end
end

-- Bucle principal para detectar ascensores cercanos (solo para tipo marker)
CreateThread(function()
    while true do
        local sleep = 1000
        local playerCoords = GetEntityCoords(PlayerPedId())
        local closestDist = Config.InteractionDistance + 1
        nearestElevator = nil
        nearestFloor = nil
        local hasMarkerElevators = false

        for elevId, elevator in pairs(Elevators) do
            if elevator.interact_type ~= 'ox_target' and elevator.floors then
                hasMarkerElevators = true
                for _, floor in ipairs(elevator.floors) do
                    local dist = #(playerCoords - vector3(floor.x, floor.y, floor.z))
                    if dist < closestDist then
                        closestDist = dist
                        nearestElevator = elevator
                        nearestFloor = floor
                    end
                end
            end
        end

        if nearestElevator and closestDist <= Config.InteractionDistance then
            sleep = 0
            -- Dibujar marcador con color del ascensor
            if Config.UseMarkers then
                local mc = ParseMarkerColor(nearestElevator.marker_color)
                local mt = nearestElevator.marker_type or Config.MarkerType
                DrawMarker(
                    mt,
                    nearestFloor.x, nearestFloor.y, nearestFloor.z - 0.95,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    Config.MarkerScale.x, Config.MarkerScale.y, Config.MarkerScale.z,
                    mc.r, mc.g, mc.b, mc.a,
                    false, true, 2, false, nil, nil, false
                )
            end

            -- Mostrar texto de interacción
            lib.showTextUI('[' .. Config.InteractKeyLabel .. '] Ascensor - ' .. nearestElevator.name, {
                position = 'right-center',
                icon = 'elevator',
                style = {
                    borderRadius = 5,
                    backgroundColor = 'rgba(0, 0, 0, 0.7)',
                    color = 'white'
                }
            })

            if IsControlJustPressed(0, Config.InteractKey) and not isTraveling then
                OpenElevatorPanel(nearestElevator)
            end
        else
            lib.hideTextUI()
            sleep = 500
        end

        Wait(sleep)
    end
end)

-- Abrir panel del ascensor
function OpenElevatorPanel(elevator)
    if not elevator or not elevator.floors or #elevator.floors == 0 then
        lib.notify({
            title = 'Ascensor',
            description = 'Este ascensor no tiene plantas configuradas',
            type = 'error'
        })
        return
    end

    -- Obtener job del jugador desde el servidor
    local playerJob, playerGrade = lib.callback.await('jorgedev-elevator:server:getPlayerJob', false)
    playerJob = playerJob or 'unemployed'
    playerGrade = playerGrade or 0

    local floorsData = {}
    for _, floor in ipairs(elevator.floors) do
        local isRestricted = false

        if floor.restricted_job and floor.restricted_job ~= '' then
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
                isRestricted = true -- No tiene ninguno de los trabajos requeridos
            elseif floor.restricted_grade and floor.restricted_grade > 0 and playerGrade < floor.restricted_grade then
                isRestricted = true -- Tiene el trabajo pero no el grado suficiente
            end
        end

        table.insert(floorsData, {
            id = floor.id,
            label = floor.label,
            floorIndex = floor.floor_index,
            restricted = isRestricted,
            restrictedJob = floor.restricted_job or '',
            restrictedGrade = floor.restricted_grade or 0,
        })
    end

    isInsideElevator = true
    currentElevatorId = elevator.id

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openPanel',
        elevatorName = elevator.name,
        floors = floorsData,
        currentFloor = nearestFloor and nearestFloor.id or nil,
    })
end

-- NUI Callbacks
RegisterNUICallback('selectFloor', function(data, cb)
    local floorId = data.floorId
    local elevatorId = currentElevatorId

    if not elevatorId or isTraveling then
        cb('busy')
        return
    end

    -- Verificar acceso
    local canAccess, reason = lib.callback.await('jorgedev-elevator:server:canAccessFloor', false, elevatorId, floorId)

    if not canAccess then
        SendNUIMessage({
            action = 'accessDenied',
            message = reason or 'No tienes acceso a esta planta'
        })
        cb('denied')
        return
    end

    -- Es la misma planta?
    if nearestFloor and nearestFloor.id == floorId then
        SendNUIMessage({
            action = 'sameFloor',
        })
        cb('same')
        return
    end

    TriggerServerEvent('jorgedev-elevator:server:teleportToFloor', elevatorId, floorId)
    cb('ok')
end)

RegisterNUICallback('closePanel', function(data, cb)
    SetNuiFocus(false, false)
    isInsideElevator = false
    currentElevatorId = nil
    cb('ok')
end)

-- Evento de viaje
RegisterNetEvent('jorgedev-elevator:client:travelToFloor', function(elevatorId, floor)
    if isTraveling then return end
    isTraveling = true

    local ped = PlayerPedId()

    -- Calcular tiempo de viaje basado en distancia de plantas
    local currentCoords = GetEntityCoords(ped)
    local targetCoords = vector3(floor.x, floor.y, floor.z)
    local heightDiff = math.abs(currentCoords.z - targetCoords.z)
    local travelTime = math.max(2000, math.min(heightDiff * 200, 8000))

    -- Animación de cierre de puertas
    SendNUIMessage({
        action = 'closeDoors',
    })

    Wait(1200)

    -- Efecto de viaje (screen fade)
    SendNUIMessage({
        action = 'traveling',
        floorLabel = floor.label,
        travelTime = travelTime,
    })

    -- Freezar al jugador
    FreezeEntityPosition(ped, true)

    Wait(travelTime)

    -- Teleportar
    SetEntityCoords(ped, floor.x, floor.y, floor.z, false, false, false, false)
    SetEntityHeading(ped, floor.heading or 0.0)

    Wait(500)

    -- Animación de apertura de puertas + ding
    SendNUIMessage({
        action = 'openDoors',
        floorLabel = floor.label,
    })

    Wait(Config.DoorAnimationTime)

    -- Liberar jugador
    FreezeEntityPosition(ped, false)

    -- Cerrar panel
    Wait(500)
    SendNUIMessage({
        action = 'arrived',
    })

    Wait(1500)
    SetNuiFocus(false, false)
    isInsideElevator = false
    currentElevatorId = nil
    isTraveling = false

    lib.notify({
        title = 'Ascensor',
        description = 'Has llegado a: ' .. floor.label,
        type = 'success',
        duration = 3000,
    })
end)

-- Blips
CreateThread(function()
    while true do
        Wait(5000)
        if Config.ShowBlips then
            for elevId, elevator in pairs(Elevators) do
                if elevator.floors and #elevator.floors > 0 and not elevator._blipCreated then
                    for _, floor in ipairs(elevator.floors) do
                        local blip = AddBlipForCoord(floor.x, floor.y, floor.z)
                        SetBlipSprite(blip, Config.BlipSprite)
                        SetBlipDisplay(blip, 4)
                        SetBlipScale(blip, Config.BlipScale)
                        SetBlipColour(blip, Config.BlipColor)
                        SetBlipAsShortRange(blip, true)
                        BeginTextCommandSetBlipName("STRING")
                        AddTextComponentSubstringPlayerName(elevator.name .. ' - ' .. floor.label)
                        EndTextCommandSetBlipName(blip)
                    end
                    elevator._blipCreated = true
                end
            end
        end
    end
end)
