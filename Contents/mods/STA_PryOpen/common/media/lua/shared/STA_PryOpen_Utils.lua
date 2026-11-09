local Utils = STA_PryOpen_Utils or {}

local SECURITY_DOORS = {
    "fixtures_doors_01_32",
    "fixtures_doors_01_33",
    "location_community_police_01_4",
    "location_community_police_01_5",
}

---@param obj IsoObject
---@return String|nil
local function getSpriteName(obj)
    local sp = obj and obj:getSprite() or nil
    if sp and sp.getName then return sp:getName() end
    return nil
end

---@param obj IsoThumpable
---@return boolean
function Utils.isSecurityDoor(obj)
    if not obj then return false end

    if instanceof(obj, "IsoDoor") or (instanceof(obj, "IsoThumpable") and obj:isDoor()) then
        local name = getSpriteName(obj)
        for _, value in ipairs(SECURITY_DOORS) do
            if name == value then return true end
        end
    end
    return false
end

_G.STA_PryOpen_Utils = Utils
return Utils