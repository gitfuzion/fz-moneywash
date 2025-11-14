Config = {}

Config.Framework = "auto" -- "qb", "esx", "auto"
Config.Notify = "ox" -- "qb", "esx", "ox"
Config.MoneyType = "cash" -- "cash", "bank" (IF USING ESX USE "money" INSTEAD OF "cash")

Config.debug = false -- Use debug for the box and poly zones.
Config.useTarget = true -- Use ox_target or  TextUi for interaction.
Config.keybind = 38 -- Control index for the TextUI. Default is 'E' (38) Change locals file for UI text. https://docs.fivem.net/docs/game-references/controls/#controls

Config.moneywashCard = 'moneywash_card' -- Moneywash keycard item name.
Config.dirtycashItem = 'black_money' -- Dirty cash item name.
Config.tax = 0.2 -- Tax on washing money also applies to stopping the wash, 0.2 by default being 20%.

Config.maxwashtime = 15 -- Maximum washing time in minutes.

Config.moneywashes = {
    moneywash1 = {
        requireCard = true, -- If true, player needs a moneywash keycard to enter the moneywash.
        entrance = vec4(636.46, 2786.18, 42.21, 2.56),
        exit = vec4(1138.09, -3199.13, -39.67, 185.48),
        washingmachines = {
            [1] = { coords = vec4(1126.97, -3194.25, -40.4, 3.58) },
            [2] = { coords = vec4(1125.5, -3194.27, -40.4, 1.34) },
            [3] = { coords = vec4(1123.76, -3194.28, -40.4, 3.94) },
        },
        zoneOptions = {
            length = 1.0,
            width = 1.0,
        },
    },
    --[[moneywash2 = {
        entrance = vec4(636.46, 2786.18, 42.21, 2.56), -- Coordinates for the entrance.
        exit = vec4(1138.09, -3199.13, -39.67, 185.48), -- Coordinates for the exit.
        washingmachines = {
            [1] = { coords = vec4(1126.97, -3194.25, -40.4, 3.58) }, -- IMPORTANT: Keep each ID unique per machine. ID and coordinates for the washing machines.
            [2] = { coords = vec4(1125.5, -3194.27, -40.4, 1.34) },
            [3] = { coords = vec4(1123.76, -3194.28, -40.4, 3.94) },
        },
        zoneOptions = { -- Used when UseTarget is false.
            length = 1.0, -- Length of the box zone.
            width = 1.0, -- Width of the box zone.
        },
    } ]]
}