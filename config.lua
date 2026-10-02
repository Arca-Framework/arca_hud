HudConfig = {
    SpeedUnit = 'mph',          -- 'mph' or 'kmh'
    MinimapOnFoot = false,      -- show the minimap while walking
    ShowMoney = 'change',       -- 'always', 'change' (pops up when money changes) or 'never'
    ShowLocation = true,        -- street, area and compass
    ShowStress = true,
    UpdateInterval = 200,       -- ms between HUD updates

    Minimap = {
        Zoom = 1100,            -- radar zoom (0 = closest, 1400 = furthest)
        Style = 'frame',        -- 'frame' draws an Arca border around the radar, 'none' leaves it bare
    },

    -- hide GTA's own HUD pieces that Arca replaces
    HideComponents = { 3, 4, 6, 7, 8, 9, 13 },
}
