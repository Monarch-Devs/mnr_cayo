---@class cayo
local cayo = {}
cayo.__index = cayo

cayo.coords = vec3(5046.0, -5106.0, 6.0)
cayo.radius = 1500.0
cayo.active = false

function cayo:toggleIpls(toggle)
    local toggleIpl = toggle and RequestIpl or RemoveIpl
    for _, name in ipairs(config.ipls) do
        toggleIpl(name)
    end
end

function cayo:adapt()
    local islandZoneId = GetZoneFromNameId('PrLog')
    SetAudioFlag('DisableFlightMusic', true)
    SetAmbientZoneListStatePersistent('AZL_DLC_Hei4_Island_Zones', true, true)
    SetAmbientZoneListStatePersistent('AZL_DLC_Hei4_Island_Disabled_Zones', false, true)
    SetZoneEnabled(islandZoneId, false)
end

function cayo:waterDetect()
    if water.detector == 'auto' then
        self.water_resource = false
        for _, resource in ipairs(water.supported) do
            if GetResourceState(resource.name) == 'started' then
                self.water_resource = resource.name
                self.water_default = resource.defaultFile
                self.water_cayo = resource.cayoFile
                break
            end
        end
    elseif water.detector == 'force' then
        self.water_resource = water.waterResource
        self.water_default = water.defaultFile
        self.water_cayo = water.cayoFile
    end
end

function cayo:ensureWater(toggle)
    if not self.water_resource then return end

    local fileToLoad = toggle and self.water_cayo or self.water_default

    if not fileToLoad then return end

    Wait(0)
    LoadWaterFromPath(self.water_resource, fileToLoad)
end

function cayo:toggleState(toggle)
    if self.active == toggle then return end

    local status = toggle and 1 or 0
    SetAiGlobalPathNodesType(status)
    LoadGlobalWaterType(status)
    self:ensureWater(toggle)
    self.active = toggle
end

function cayo:update()
    local playerPed = PlayerPedId()
    local distance = #(GetEntityCoords(playerPed) - self.coords)

    self:toggleState(distance < self.radius)
end

CreateThread(function()
    cayo:toggleIpls(true)
    cayo:adapt()
    cayo:waterDetect()
    while true do
        cayo:update()
        Wait(1000)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    cayo:toggleIpls(false)
    cayo:toggleState(false)
end)