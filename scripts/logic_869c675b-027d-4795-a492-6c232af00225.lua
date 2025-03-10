---
---  DateTime: 【2022-8-9 20:13:36】
--- 【Logic】
--- 【触发器】

local class = require("middleclass")
local LogicScript = require("studios/logicscript")

require("common/tableutil")
local Util = require("Main/scripts/common/util"):getInstance()

---@class logic_869c675b_027d_4795_a492_6c232af00225 : LogicScript
local LogicElement  = class("logic_869c675b-027d-4795-a492-6c232af00225",LogicScript)

---@param script CS.Tal.EngineExtends.StudioExtends.LogicScript
function LogicElement : initialize(script)
    LogicElement.super.initialize(self,script)

    -- 教学组件事件处理
    local configService = CourseEnv.ServicesManager:GetConfigService()
    local key = configService:GetConfigValueByConfigKey(self.Script,"_EasyTeachEventId_")
    self.eventId = configService:GetConfigValueByConfigKey(self.Script,"eventId")
    self.paramInfo = configService:GetConfigValueByConfigKey(self.Script,"paramInfo")
    self.Script.gameObject:SetActive(false)
    CourseEnv.ServicesManager:GetObserverService():Watch(key,function(key, args) 
        self:SendEvent(args)
    end)
    --
end

function LogicElement:SendEvent(args)
    if args[0].type==2 then
        local stateInfo
        if args[0].state==1 then 
            stateInfo="on"
        else
            stateInfo="off"
        end
        CourseEnv.ServicesManager:GetObserverService():Fire(self.eventId, {
            type = "switch",
            state = stateInfo,
            param = tostring(self.paramInfo),
            timeStamp = CS.UnityEngine.Time.time,
            isResume = false
        })
    else
        CourseEnv.ServicesManager:GetObserverService():Fire(self.eventId, {
            type = "trigger",
            state = "on",
            param = tostring(self.paramInfo),
            timeStamp = CS.UnityEngine.Time.time,
            isResume = false
        })
    end
end

return LogicElement

