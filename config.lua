Config = {}

-- Repositorio de GitHub para verificar actualizaciones
Config.GithubRepo = 'Dorymes/JorgeDevElevators'

-- Comando para abrir el panel de admin
Config.AdminCommand = 'elevatorcreator'

-- Grupos con permiso de admin (ace permissions)
Config.AdminGroups = { 'admin', 'superadmin', 'god' }

-- Distancia para interactuar con el ascensor
Config.InteractionDistance = 2.0

-- Duración del viaje del ascensor en ms (por planta)
Config.TravelTimePerFloor = 500

-- Duración de la animación de puertas (ms)
Config.DoorAnimationTime = 1500

-- Blip en el mapa
Config.ShowBlips = false
Config.BlipSprite = 476
Config.BlipColor = 0
Config.BlipScale = 0.7

-- Modelo de prop para los marcadores del ascensor (opcional)
Config.UseMarkers = true
Config.MarkerType = 20
Config.MarkerColor = { r = 100, g = 100, b = 255, a = 100 }
Config.MarkerScale = { x = 0.5, y = 0.5, z = 0.5 }

-- Framework detection
Config.Framework = 'esx' -- 'qb', 'esx', or 'custom'

-- Keybind para interactuar
Config.InteractKey = 38 -- E key
Config.InteractKeyLabel = 'E'
