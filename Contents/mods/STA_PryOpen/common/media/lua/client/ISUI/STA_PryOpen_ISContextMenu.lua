local Utils = require "STA_PryOpen_Utils"
local ContextMenu = STA_PryOpen_ISContextMenu or {}

local function predicateNotBroken(item)
	return not item:isBroken()
end

function ContextMenu.onPrySelectDoor(worldObjects, object, player)
    local playerObj = getSpecificPlayer(player)
    local square = object:getSquare()
    if (not playerObj:isBlockMovement()) then
        if luautils.walkAdjWindowOrDoor(playerObj, square, object) then
            local crowbar = playerObj:getInventory():getFirstTagEvalRecurse(ItemTag.CROWBAR, predicateNotBroken)
            if not crowbar then
                return
            end
            ISWorldObjectContextMenu.transferIfNeeded(playerObj, crowbar)
            ISInventoryPaneContextMenu.equipWeapon(crowbar, true, true, player)
            ISTimedActionQueue.add(STA_PryOpen_ISPryOpenActionDoor:new(playerObj, object))
        end
    end
end

function ContextMenu.onPrySelectVehicle(playerObj, square, object)
    -- if luautils.walkAdj(playerObj, square, false) then
    local crowbar = playerObj:getInventory():getFirstTagEvalRecurse(ItemTag.CROWBAR, predicateNotBroken)
    if not crowbar then return end
    ISWorldObjectContextMenu.transferIfNeeded(playerObj, crowbar)
    ISInventoryPaneContextMenu.equipWeapon(crowbar, true, true, playerObj:getIndex())
    ISTimedActionQueue.add(STA_PryOpen_ISPryOpenActionVehicle:new(playerObj, object))
    -- end
end

function ContextMenu.onFillWorldContext(playerIdx, context, worldObjects, test)
    if test and ISWorldObjectContextMenu.Test then return true end

    local playerObj = getSpecificPlayer(playerIdx)

    if playerObj:getVehicle() then return false end

    local securityDoor, vehicle, part
    if ISVehicleMenu and ISVehicleMenu.gettVehicleToInteractWith then
        vehicle = ISVehicleMenu.getVehicleToInteractWith(playerObj)
    end
    for i,v in ipairs(worldObjects) do
        if (instanceof(v, "IsoDoor") or (instanceof(v, "IsoThumpable") and v:isDoor())) then ---and Utils.isSecurityDoor(v) then
            securityDoor = v
        end
        if not vehicle and instanceof(v, "BaseVehicle") then
            vehicle = v
        end
    end
    if vehicle then
        local p = vehicle:getUseablePart(playerObj)
        if part:getDoor() and tostring(p:getId() or ""):lower():find("door") or tostring(p:getId() or ""):lower():find("trunk") then
            part = p:getDoor() and p:getDoor():isLocked()
        end
    end

    if securityDoor then
        local subMenu = context:getOptionFromName(getText("ContextMenu_Door_option")) and context:getSubMenu(context:getOptionFromName(getText("ContextMenu_Door_option")).subOption)
        local option = subMenu:addOptionOnTop(getText("Force"), worldObjects, ContextMenu.onPrySelectDoor, securityDoor, playerIdx)
    end
    if vehicle and part then
        local option = context:addOptionOnTop(getText("Force"), getSpecificPlayer(playerIdx), ContextMenu.onPrySelectVehicle, worldObjects:get(0):getSquare(), part)
    end
end

Events.OnFillWorldObjectContextMenu.Add(ContextMenu.onFillWorldContext)

_G.STA_PryOpen_ISContextMenu = ContextMenu
return ContextMenu