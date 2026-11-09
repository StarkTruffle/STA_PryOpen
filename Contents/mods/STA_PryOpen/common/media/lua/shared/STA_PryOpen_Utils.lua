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


---@param part VehiclePart
---@return string | nil
function Utils.getVehicleCategoryForPart(part)
    local id = tostring(part and part:getId() or ""):lower()
    if id:find("trunk") then
        return "Trunk"
    elseif (id:find("door") and part:getDoor()) or (part and part.getDoor and part:getDoor()) then
        return "Vehicle"
    else
        return nil
    end
end

---@param partId string
---@return string
function Utils.vehicleDoorLabelKeyFromId(partId)
    local mod = "ContextMenu_STA_PryOpen_Vehicle_"
    local id = tostring(partId or ""):lower()

    local loc, side = nil, nil
    local plural = ""

    local locations = { "Front", "Middle", "Rear", "Trunk" }
    local sides = { "Left", "Right" }

    for _, l in ipairs(locations) do
        if id:find(l:lower()) then
            loc = l
            break
        end
    end

    for _, s in ipairs(sides) do
        if id:find(s:lower()) then
            side = s
            break
        end
    end

    if loc == "Rear" and not side then
        plural = "P"
    end

    local locText = loc and getText(mod .. "Loc_" .. loc .. plural) or ""
    local sideText = side and getText(mod .. "Side_" .. side) or ""
    local nounText = ""
    if loc ~= "Trunk" then
        local nounKey = mod .. "Door" .. plural
        -- local nounKey = plural and (mod .. "Doors") or (mod .. "Door")
        nounText = getText(nounKey)
    end

    if not loc and not side then
        return getText(mod .. "Generic")
    else
        return ((getText("ContextMenu_STA_PryOpen_Vehicle", locText, sideText, nounText):gsub("%s+", " ")):gsub("^%s*(.-)%s*$", "%1"))
    end
end

_G.STA_PryOpen_Utils = Utils
return Utils