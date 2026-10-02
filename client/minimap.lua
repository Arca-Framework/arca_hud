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

CreateThread(function()
    while not LocalPlayer.state.isLoggedIn do Wait(500) end

    local minimap = hideHealthArmour()

    local lastAnchor
    local nextAnchor = 0

    while true do
        -- 3 = hide the health/armour bars under the radar
        BeginScaleformMovieMethod(minimap, 'SETUP_HEALTH_ARMOUR')
        ScaleformMovieMethodAddParamInt(3)
        EndScaleformMovieMethod()

        -- never let the expanded "big map" open
        if IsBigmapActive() then SetRadarBigmapEnabled(false, false) end

        local now = GetGameTimer()
        if now >= nextAnchor then
            nextAnchor = now + 500
            local anchor = getMinimapAnchor()
            local key = ('%.4f:%.4f:%.4f:%.4f:%s:%d'):format(anchor.left, anchor.top, anchor.width, anchor.height, tostring(HudSettings.minimapFrame), HudSettings.minimapZoom)
            if key ~= lastAnchor then
                lastAnchor = key
                SetRadarZoom(HudSettings.minimapZoom)
                SendNUIMessage({ action = 'minimap', data = { anchor = anchor, style = HudSettings.minimapFrame and 'frame' or 'none' } })
            end
        end

        Wait(0)
    end
end)
