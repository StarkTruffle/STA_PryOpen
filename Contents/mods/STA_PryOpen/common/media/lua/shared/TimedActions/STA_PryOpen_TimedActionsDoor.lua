require "TimedActions/ISBaseTimedAction"

STA_PryOpen_ISPryOpenActionDoor = ISBaseTimedAction:derive("STA_PryOpen_ISPryOpenActionDoor")

STA_PryOpen_ISPryOpenActionDoor.FAIL_CHANCE = 10
STA_PryOpen_ISPryOpenActionDoor.FAIL_CHANCE_BURGLAR = 5

function STA_PryOpen_ISPryOpenActionDoor:isValid()
    return true
end

function STA_PryOpen_ISPryOpenActionDoor:waitToStart()
    self.character:faceThisObject(self.object)
    return self.character:shouldBeTurning() -- or not self.character:isCurrentState(IdleState.instance())
end

function STA_PryOpen_ISPryOpenActionDoor:update()
    self.character:faceThisEdgeElement(self.object)
end

function STA_PryOpen_ISPryOpenActionDoor:start()
    self.character:faceThisEdgeElement(self.object)
    self:setActionAnim("STA_ForceOpenDoorLeftAnimLooped")
    self:setAnimVariable("STA_ForceOpenDoorLeftAnimLooped", "start")
end

function STA_PryOpen_ISPryOpenActionDoor:stop()
    ISBaseTimedAction.stop(self)
end

function STA_PryOpen_ISPryOpenActionDoor:perform()
    ISBaseTimedAction.perform(self)
end

function STA_PryOpen_ISPryOpenActionDoor:complete()
    return self.outcome == "success"
end

function STA_PryOpen_ISPryOpenActionDoor:getDuration()
    return -1
end

function STA_PryOpen_ISPryOpenActionDoor:attempt()
    if not instanceof(self.object, "IsoDoor") then
        return "fail"
    end
    local tool = self.character:getPrimaryHandItem()
    if not tool or not tool:hasTag(ItemTag.CROWBAR) or tool:isBroken() or not IsoGridSquare.isWithinReachOfCharacter(self.character, self.object) then
        return "fail"
    end
    if not self.object:isLocked() then
        return "success"
    end

    self.character:exertForForcing()
    self.object:forceStruggleDamage(self.character)
    
    local failChance = self.character:hasTrait(CharacterTrait.BURGLAR) and STA_PryOpen_ISPryOpenActionDoor.FAIL_CHANCE_BURGLAR or STA_PryOpen_ISPryOpenActionDoor.FAIL_CHANCE
    if ZombRand(100) < failChance then
        self.object:failForceOpen(self.character)
        return "fail"
    end
    local minimumChance = math.max(1, self.character:getPerkLevel(Perks.Strength))
    if ZombRand(100) < math.max(minimumChance, self.character:getBaseForceOpenChance() + self.object:getBaseForceOpenChance(self.character)) then
        return "success"
    end
    return "struggle"
end

function STA_PryOpen_ISPryOpenActionDoor:animEvent(event, parameter)
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
            self.object:setLockedByKey(false)
            self.object:setLocked(false)
            if isServer() then
                self.object:sync()
            else
                triggerEvent("OnContainerUpdate")
            end
            self.object:forceOpen(self.character)
            if isServer() then
                self.object:sync()
                self.netAction:forceComplete()
            else
                self:setAnimVariable("STA_ForceOpenDoorLeftOutcome", "success")
                self:forceComplete()
                triggerEvent("OnContainerUpdate")
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

function STA_PryOpen_ISPryOpenActionDoor:serverStart()
    emulateAnimEventOnce(self.netAction, 400, "STA_ForceOpenStarted", nil)
end

function STA_PryOpen_ISPryOpenActionDoor:new(character, object)
    local o = ISBaseTimedAction.new(self, character)
    o.object = object
    o.maxTime = o:getDuration()
    o.useProgressBar = false
    o.ignoreHandsWounds = true
    o.retriggerLastAction = true
    return o
end