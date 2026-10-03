-- Restyled native radar: removes GTA's health/armour bars and big-map, keeps the radar
-- itself (accurate roads + blips) and lets the NUI draw an Arca frame exactly around it.

---Screen-space rectangle of the default radar (0-1 of screen), from safezone + aspect ratio
local function getMinimapAnchor()
    local safezone = GetSafeZoneSize()
    local aspect = GetAspectRatio(false)
    local resX, resY = GetActiveScreenResolution()
    local xScale, yScale = 1.0 / resX, 1.0 / resY
    local offset = 1.0 / 20.0 * (math.abs(safezone - 1.0) * 10)

    local width = xScale * (resX / (4 * aspect))
    local height = yScale * (resY / 5.674)
    local left = xScale * (resX * offset)
    local bottom = 1.0 - yScale * (resY * offset)

    return { left = left, top = bottom - height, width = width, height = height }
end

local function hideHealthArmour()
    local minimap = RequestScaleformMovie('minimap')
    local timeout = GetGameTimer() + 3000
    while not HasScaleformMovieLoaded(minimap) and GetGameTimer() < timeout do Wait(0) end
    -- toggling the big map once forces the scaleform to rebuild with our settings
    SetRadarBigmapEnabled(true, false)
    Wait(0)
    SetRadarBigmapEnabled(false, false)
    return minimap
end

local lastAnchor
-- the page (re)loaded: send the radar frame again
AddEventHandler('arca_hud:client:nuiReady', function() lastAnchor = nil end)

---------------------------------------------------------------------
-- Route colour (waypoint line + GPS) from config.lua
---------------------------------------------------------------------
-- 142-144 = HUD_COLOUR_WAYPOINT / _WAYPOINTLIGHT / _WAYPOINTDARK; GTA's default is purple
local ROUTE_HUD_COLOURS = { 142, 143, 144 }
local DEFAULT_ROUTE = { 164, 76, 242 }

local function setRouteColour(rgb)
    for _, id in ipairs(ROUTE_HUD_COLOURS) do
        ReplaceHudColourWithRgba(id, rgb[1], rgb[2], rgb[3], 255)
    end
end

if HudConfig.RouteColour then setRouteColour(HudConfig.RouteColour) end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and HudConfig.RouteColour then setRouteColour(DEFAULT_ROUTE) end
end)

CreateThread(function()
    while not LocalPlayer.state.isLoggedIn do Wait(500) end

    local minimap = hideHealthArmour()

    local nextAnchor = 0

    while true do
        -- nothing to do while the radar is hidden (on foot): check again in a bit
        if IsRadarHidden() then
            Wait(250)
            goto continue
        end

        -- 3 = hide the health/armour bars under the radar
        BeginScaleformMovieMethod(minimap, 'SETUP_HEALTH_ARMOUR')
        ScaleformMovieMethodAddParamInt(3)
        EndScaleformMovieMethod()

        -- never let the expanded "big map" open
        if IsBigmapActive() then SetRadarBigmapEnabled(false, false) end

        local now = GetGameTimer()
        if now >= nextAnchor then
            nextAnchor = now + 2000
            local anchor = getMinimapAnchor()
            local key = ('%.4f:%.4f:%.4f:%.4f:%s:%d'):format(anchor.left, anchor.top, anchor.width, anchor.height, tostring(HudSettings.minimapFrame), HudSettings.minimapZoom)
            if key ~= lastAnchor then
                lastAnchor = key
                SetRadarZoom(HudSettings.minimapZoom)
                SendNUIMessage({ action = 'minimap', data = { anchor = anchor, style = HudSettings.minimapFrame and 'frame' or 'none' } })
            end
        end

        Wait(0)
        ::continue::
    end
end)
