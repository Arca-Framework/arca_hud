HudConfig = {
    SpeedUnit = 'mph',          -- 'mph' or 'kmh'
    MinimapOnFoot = false,      -- show the minimap while walking
    ShowMoney = 'change',       -- 'always', 'change' (pops up when money changes) or 'never'
    ShowLocation = true,        -- street, area and compass
    ShowStress = true,
    UpdateInterval = 200,       -- ms between HUD updates

    -- colour of the waypoint / GPS route on the map and minimap, { r, g, b } (false = GTA's purple)
    RouteColour = { 0, 255, 106 },

    Minimap = {
        Zoom = 1100,            -- radar zoom (0 = closest, 1400 = furthest)
        Style = 'frame',        -- 'frame' draws an Arca border around the radar, 'none' leaves it bare
    },

    -- GTA's own HUD pieces. true = hidden, false = shown.
    DisableComponents = {
        WANTED_STARS = true,            -- 1  wanted level stars
        WEAPON_ICON = true,             -- 2  weapon + ammo in the top-right
        CASH = true,                    -- 3  single-player cash
        MP_CASH = true,                 -- 4  online cash
        MP_MESSAGE = true,             -- 5  online messages
        VEHICLE_NAME = true,            -- 6  vehicle name when entering a car
        AREA_NAME = true,               -- 7  area name (Arca shows this)
        VEHICLE_CLASS = true,           -- 8  vehicle class
        STREET_NAME = true,             -- 9  street name (Arca shows this)
        HELP_TEXT = false,              -- 10 top-left help text
        FLOATING_HELP_TEXT_1 = false,   -- 11 floating help text
        FLOATING_HELP_TEXT_2 = false,   -- 12 floating help text
        CASH_CHANGE = true,             -- 13 +$/-$ popups (Arca shows this)
        RETICLE = true,                -- 14 aiming dot / crosshair
        SUBTITLE_TEXT = false,          -- 15 subtitles
        RADIO_STATIONS = false,         -- 16 radio station wheel
        SAVING_GAME = true,             -- 17 saving spinner
        GAME_STREAM = false,            -- 18 loading / feed messages
        WEAPON_WHEEL = true,           -- 19 weapon wheel (true blocks it entirely)
        WEAPON_WHEEL_STATS = true,      -- 20 weapon stats on the wheel
        HUD_COMPONENTS = false,         -- 21 all of the above at once
        HUD_WEAPONS = true,            -- 22 weapon HUD group
    },
}
