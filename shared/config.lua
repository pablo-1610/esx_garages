Config = {
    esxGetter = "esx:getSharedObject";

    -- ESX.Game.IsSpawnPointClear
    garages = {
        {
            name = "Parking central",
            interactionZone = vector3(213.61, -809.25, 31.01),

            spawnRadius = 2.0,
            availableSpawns = {
                { coords = vector3(207.4, -798.68, 30.98), heading = 249.67 },
                { coords = vector3(231.94, -810.7, 30.41), heading = 70.63 }
            }
        }
    },

    fourrieres = {
        price = 250,
        name = "Fourrière",

        list = {
            { interaction = vector3(3, 3, 3), out = { pos = vector3(0, 0, 0), heading = 90.0 } }
        }
    }
}