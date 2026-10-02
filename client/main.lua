local PlayerData = exports.arca_core:GetPlayerData() or {}
local visible = true      -- toggled by /hud
local seatbelt = false
local last = {}           -- last values sent per message, to skip duplicates

local function send(action, data)
    local encoded = json.encode(data)
    if last[action] == encoded then return end
    last[action] = encoded
    SendNUIMessage({ action = action, data = data })
end

local function isLoggedIn()
    return LocalPlayer.state.isLoggedIn == true
end

---------------------------------------------------------------------
-- Player data
---------------------------------------------------------------------
local function sendMoney(change)
    local money = PlayerData.money or {}
    SendNUIMessage({
        action = 'money',
        data = { cash = money.cash or 0, bank = money.bank or 0, mode = HudConfig.ShowMoney, change = change },
    })
end

AddEventHandler('arca_core:client:onPlayerLoaded', function(data)
    PlayerData = data
    last = {}
    sendMoney()
end)

AddEventHandler('arca_core:client:onPlayerUnloaded', function()
    PlayerData = {}
    send('visible', false)
end)

AddEventHandler('arca_core:client:onPlayerDataUpdated', function(data)
    PlayerData = data
end)

RegisterNetEvent('arca_core:client:onMoneyChange', function(mType, delta)
    -- PlayerData arrives just before this event, so the totals are already current
    Wait(0)
    sendMoney({ type = mType, amount = delta })
end)

---------------------------------------------------------------------
-- Seatbelt (indicator only — set by your seatbelt resource)
---------------------------------------------------------------------
local function setSeatbelt(state) seatbelt = state and true or false end
exports('SetSeatbelt', setSeatbelt)
AddEventHandler('seatbelt:client:ToggleSeatbelt', function(state)
    if state == nil then seatbelt = not seatbelt else setSeatbelt(state) end
end)

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------
local directions = { 'N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW' }

local function heading()
    local h = (360.0 - GetGameplayCamRot(0).z) % 360.0
    return directions[math.floor((h + 22.5) / 45.0) % 8 + 1]
end

local function healthPercent(ped)
    local max = GetEntityMaxHealth(ped) - 100
    if max <= 0 then return 0 end
    return math.floor(math.max(0, math.min(100, (GetEntityHealth(ped) - 100) / max * 100)))
end

local function fuelLevel(veh)
    local state = Entity(veh).state.fuel -- ox_fuel / statebag fuel scripts
    return math.floor(state or GetVehicleFuelLevel(veh))
end

local function voiceMode()
    local prox = LocalPlayer.state.proximity
    return prox and prox.index or 2
end

---------------------------------------------------------------------
-- Main loop
---------------------------------------------------------------------
CreateThread(function()
    while true do
        local show = visible and isLoggedIn() and not IsPauseMenuActive()
        send('visible', show)

        if show then
            local ped = PlayerPedId()
            local meta = PlayerData.metadata or {}
            local veh = GetVehiclePedIsIn(ped, false)
            local inVeh = veh ~= 0

            send('status', {
                health = healthPercent(ped),
                armor = GetPedArmour(ped),
                hunger = math.floor(meta.hunger or 100),
                thirst = math.floor(meta.thirst or 100),
                stress = HudConfig.ShowStress and math.floor(meta.stress or 0) or nil,
                oxygen = IsPedSwimmingUnderWater(ped) and math.floor(GetPlayerUnderwaterTimeRemaining(PlayerId()) * 10) or nil,
                talking = NetworkIsPlayerTalking(PlayerId()),
                voice = voiceMode(),
                radio = LocalPlayer.state.radioChannel,
            })

            DisplayRadar(inVeh or HudConfig.MinimapOnFoot)

            if inVeh then
                local mult = HudConfig.SpeedUnit == 'kmh' and 3.6 or 2.236936
                send('vehicle', {
                    show = true,
                    speed = math.floor(GetEntitySpeed(veh) * mult),
                    unit = HudConfig.SpeedUnit,
                    rpm = math.floor(GetVehicleCurrentRpm(veh) * 100),
                    gear = GetVehicleCurrentGear(veh),
                    fuel = fuelLevel(veh),
                    engine = math.floor(GetVehicleEngineHealth(veh) / 10),
                    seatbelt = seatbelt,
                    map = true,
                })
            else
                send('vehicle', { show = false, map = HudConfig.MinimapOnFoot })
            end

            if HudConfig.ShowLocation then
                local c = GetEntityCoords(ped)
                local s1, s2 = GetStreetNameAtCoord(c.x, c.y, c.z)
                send('location', {
                    street = GetStreetNameFromHashKey(s1),
                    cross = s2 ~= 0 and GetStreetNameFromHashKey(s2) or nil,
                    zone = GetLabelText(GetNameOfZone(c.x, c.y, c.z)),
                    heading = heading(),
                })
            end
        end

        Wait(HudConfig.UpdateInterval)
    end
end)

-- hide the GTA HUD pieces Arca replaces
CreateThread(function()
    while true do
        if isLoggedIn() then
            for _, id in ipairs(HudConfig.HideComponents) do HideHudComponentThisFrame(id) end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

---------------------------------------------------------------------
-- Commands / exports
---------------------------------------------------------------------
RegisterCommand('hud', function()
    visible = not visible
    exports.arca_core:Notify(visible and 'HUD shown' or 'HUD hidden')
end, false)

exports('ToggleHud', function(state)
    if state == nil then visible = not visible else visible = state end
end)

-- if the resource restarts mid-session
CreateThread(function()
    Wait(500)
    if isLoggedIn() then sendMoney() end
end)
