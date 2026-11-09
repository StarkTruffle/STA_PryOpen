require "TimedActions/ISBaseTimedAction"

STA_PryOpen_ISPryOpenActionVehicle = ISBaseTimedAction:derive("STA_PryOpen_ISPryOpenActionVehicle")

STA_PryOpen_ISPryOpenActionVehicle.FAIL_CHANCE = 10
STA_PryOpen_ISPryOpenActionVehicle.FAIL_CHANCE_BURGLAR = 5

function STA_PryOpen_ISPryOpenActionVehicle:isValid()
    return true
end

function STA_PryOpen_ISPryOpenActionVehicle:waitToStart()
    self.character:faceThisObject(self.object)
    return self.character:shouldBeTurning() -- or not self.character:isCurrentState(IdleState.instance())
end

function STA_PryOpen_ISPryOpenActionVehicle:update()
    self.character:faceLocation(self.object:getVehicle():getX(), self.object:getVehicle():getY())
    return self.character:shouldBeTurning()
end

function STA_PryOpen_ISPryOpenActionVehicle:start()
    self.character:faceLocation(self.object:getVehicle():getX(), self.object:getVehicle():getY())
    self:setActionAnim("STA_ForceOpenDoorLeftAnimLooped")
    self:setAnimVariable("STA_ForceOpenDoorLeftAnimLooped", "start")
end

function STA_PryOpen_ISPryOpenActionVehicle:stop()
    ISBaseTimedAction.stop(self)
end

function STA_PryOpen_ISPryOpenActionVehicle:perform()
    ISBaseTimedAction.perform(self)
end

function STA_PryOpen_ISPryOpenActionVehicle:complete()
    return self.outcome == "success"
end

function STA_PryOpen_ISPryOpenActionVehicle:getDuration()
    return -1
end

function STA_PryOpen_ISPryOpenActionVehicle:attempt()
    if not instanceof(self.object, "VehiclePart") then
        return "fail"
    end
    local tool = self.character:getPrimaryHandItem()
    local area = self.object:getVehicle():getAreaCenter(self.object:getArea())
    if not tool or not tool:hasTag(ItemTag.CROWBAR) or tool:isBroken() or not self.object:getDoor() or self.character:DistToSquared(area:getX()+0.5, area:getY()+0.5) > 4 then
        return "fail"
    end
    if not self.object:getDoor():isLocked() then
        return "success"
    end

    self.character:exertForForcing()
    
    local failChance = self.character:hasTrait(CharacterTrait.BURGLAR) and STA_PryOpen_ISPryOpenActionDoor.FAIL_CHANCE_BURGLAR or STA_PryOpen_ISPryOpenActionDoor.FAIL_CHANCE
    if ZombRand(100) < failChance then
        self.object:failForceOpen(self.character)
        return "fail"
    end
    local minimumChance = math.max(1, self.character:getPerkLevel(Perks.Strength))
    if ZombRand(100) < math.max(minimumChance, self.character:getBaseForceOpenChance() + (self.character:hasTrait(CharacterTrait.BURGLAR) and 5 or -15)) then
        return "success"
    end
    return "struggle"
end

function STA_PryOpen_ISPryOpenActionVehicle:animEvent(event, parameter)
    if isServer() and event == "STA_ForceOpenStarted" then
        emulateAnimEvent(self.netAction, 1040, "STA_ForceOpenAttempt", nil)
    end
    if event == "STA_ForceOpenDoorLeftAnimLooped" then
        if parameter == "start" then
            self:setActionAnim("STA_ForceOpenDoorLeftOutcome")
            self:setAnimVariable("STA_ForceOpenDoorLeftOutcome", "struggle")
        end
    end
    if not isClient() and event == "STA_ForceOpenAttempt" then
        self.outcome = self:attempt()
        print("Outcome: "..self.outcome)
        if self.outcome == "success" then
            self.object:getDoor():setLocked(false)
            if self.object:getVehicle().transmitPartDoor then self.object:getVehicle():transmitPartDoor(self.object) end
            if isServer() then
                self.netAction:forceComplete()
            else
                self:setAnimVariable("STA_ForceOpenDoorLeftOutcome", "success")
                self:forceComplete()
            end
        elseif self.outcome == "fail" then
            if isServer() then
                self.netAction:forceComplete()
            else
                self:setAnimVariable("STA_ForceOpenDoorLeftOutcome", "fail")
                self:forceStop()
            end
        end
    end
end

function STA_PryOpen_ISPryOpenActionVehicle:serverStart()
    emulateAnimEventOnce(self.netAction, 400, "STA_ForceOpenStarted", nil)
end

function STA_PryOpen_ISPryOpenActionVehicle:new(character, object)
    local o = ISBaseTimedAction.new(self, character)
    o.object = object
    o.maxTime = o:getDuration()
    o.useProgressBar = false
    o.ignoreHandsWounds = true
    o.retriggerLastAction = true
    return o
end