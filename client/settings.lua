-- Per-player HUD settings, saved on the player's PC (resource KVP) and edited with /hud.
-- Defaults come from config.lua.

local KVP_KEY = 'arca_hud:settings'

local defaults = {
    visible = true,
    speedUnit = HudConfig.SpeedUnit,
    minimapOnFoot = HudConfig.MinimapOnFoot,
    minimapFrame = HudConfig.Minimap.Style ~= 'none',
    minimapZoom = HudConfig.Minimap.Zoom,
    money = HudConfig.ShowMoney,
    location = HudConfig.ShowLocation,
    stress = HudConfig.ShowStress,
    rings = { health = true, armor = true, hunger = true, thirst = true, stress = true, voice = true },
    scale = 100,
    cinematic = false,
}

local function load()
    local saved = GetResourceKvpString(KVP_KEY)
    local data = saved and json.decode(saved) or {}
    local settings = {}
    for k, v in pairs(defaults) do
        if type(v) == 'table' then
            settings[k] = {}
            for rk, rv in pairs(v) do
                local s = data[k] and data[k][rk]
                settings[k][rk] = s == nil and rv or s
            end
        else
            settings[k] = data[k] == nil and v or data[k]
        end
    end
    return settings
end

HudSettings = load()

local function save()
    SetResourceKvp(KVP_KEY, json.encode(HudSettings))
end

---Sends the settings the NUI cares about (ring toggles, scale, cinematic bars, money mode)
function SyncHudSettings()
    SendNUIMessage({ action = 'settings', data = HudSettings })
end

local menuOpen = false

local function openMenu()
    if menuOpen then return end
    menuOpen = true
    SendNUIMessage({ action = 'menu', data = { open = true, settings = HudSettings, defaults = defaults } })
    SetNuiFocus(true, true)
    -- real game blur behind the menu (CSS backdrop-filter doesn't work in FiveM's NUI)
    TriggerScreenblurFadeIn(200)
end

local function closeMenu()
    menuOpen = false
    SendNUIMessage({ action = 'menu', data = { open = false } })
    SetNuiFocus(false, false)
    TriggerScreenblurFadeOut(200)
end

RegisterNUICallback('settings:update', function(data, cb)
    cb(1)
    local key, value = data.key, data.value
    if key == 'ring' and type(value) == 'table' and HudSettings.rings[value.name] ~= nil then
        HudSettings.rings[value.name] = value.enabled and true or false
    elseif defaults[key] ~= nil and type(defaults[key]) == type(value) then
        if key == 'scale' then value = math.max(70, math.min(130, math.floor(value))) end
        if key == 'minimapZoom' then value = math.max(0, math.min(1400, math.floor(value))) end
        HudSettings[key] = value
    else
        return
    end
    save()
    SyncHudSettings()
end)

RegisterNUICallback('settings:reset', function(_, cb)
    cb(1)
    DeleteResourceKvp(KVP_KEY)
    HudSettings = load()
    SyncHudSettings()
    SendNUIMessage({ action = 'menu', data = { open = true, settings = HudSettings, defaults = defaults } })
end)

RegisterNUICallback('settings:close', function(_, cb)
    cb(1)
    closeMenu()
end)

RegisterCommand('hud', function()
    if not LocalPlayer.state.isLoggedIn then return end
    if menuOpen then closeMenu() else openMenu() end
end, false)

exports('OpenHudMenu', openMenu)

CreateThread(function()
    Wait(250)
    SyncHudSettings()
end)
