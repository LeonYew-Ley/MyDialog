---
---  Author: 【黎恩瑜】
---  AuthorID: 【387657】
---  CreateTime: 【2025-3-6 17:13:49】
--- 【FSync】
--- 【SetSpawn】
---

local class = require("middleclass")
local WBElement = require("mworld/worldBaseElement")

---@class fsync_f42386c6_7213_4366_ab74_8f9645c68f40 : WorldBaseElement
local FsyncElement = class("fsync_f42386c6-7213-4366-ab74-8f9645c68f40", WBElement)

local GameObject = CS.UnityEngine.GameObject

---用作Find路径的父节点
---@type string
local envParent = "Environment"
-- local Fsync_Example_KEY = "_Example__Key_"

---@param worldElement CS.Tal.framesync.WorldElement
function FsyncElement:initialize(worldElement)
    FsyncElement.super.initialize(self, worldElement)
    --订阅KEY消息
    -- self:SubscribeMsgKey(Fsync_Example_KEY)
    -- self:Print("开始初始化")
    self:InitService()
    -- self:Print("服务初始化完成")
    self:FindObj()
    -- self:Print("初始化完成")

    self.commonService:StartCoroutine(
        function()
            self.commonService:Yield(
                self.commonService:WaitUntil(
                    function()
                        return self.avatar ~= nil
                    end
                )
            )
            self.avatarService:TeleportAndNotice(self.spawnPos)
            self:Print("传送到:", self.spawnPos)
        end
    )
end

-- 收到/恢复IRC消息
-- @param key  订阅的消息key
-- @param value  消息集合体
-- @param isResume  是否为恢复消息
function FsyncElement:ReceiveMessage(key, value, isResume)
    -- TODO:
end

-- 发送KEY-VALUE 消息
-- @param key 自定义/协议key
-- @param body  table 消息体
function FsyncElement:SendCustomMessage(key, body)
    self:SendMessage(key, body)
end

-- 自己avatar对象创建完成
-- @param avatar 对应自己的Fsync_avatar对象
function FsyncElement:SelfAvatarCreated(avatar)

end

-- 自己avatar对象人物模型加载完成ba
-- @param avatar 对应自己的Fsync_avatar对象
function FsyncElement:SelfAvatarPrefabLoaded(avatar)
    self.avatar = avatar
end

-- avatar对象创建完成，包含他人和自己
-- @param avatar 对应自己的Fsync_avatar对象
function FsyncElement:AvatarCreated(avatar)

end

------------------------蓝图组件相应方法---------------------------------------------
--是否是异步恢复如果是需要改成true
function FsyncElement:LogicMapIsAsyncRecorver()
    return false
end

--开始恢复方法（断线重连的时候用）
function FsyncElement:LogicMapStartRecover()
    FsyncElement.super:LogicMapStartRecover()
    --TODO
end

--结束恢复方法 (断线重连的时候用)
function FsyncElement:LogicMapEndRecover()
    FsyncElement.super:LogicMapEndRecover(self)
    --TODO
end

--所有的组件恢复完成
function FsyncElement:LogicMapAllComponentRecoverComplete()
end

--收到Trigger事件
function FsyncElement:OnReceiveTriggerEvent(interfaceId)
end

--收到GetData事件
function FsyncElement:OnReceiveGetDataEvent(interfaceId)
    return nil
end

------------------------蓝图组件相应方法End---------------------------------------------

-- 脚本释放
function FsyncElement:Exit()
    FsyncElement.super.Exit(self)
end

-----------------------自定义方法----------------------------

--- 封装打印，添加@@SetSpawn前缀
function FsyncElement:Print(...)
    print("@@SetSpawn", ...)
end

--- 找到出生点对象：通过父级节点找Spawnpoint
function FsyncElement:FindObj()
    ---获取配置项出生点空对象名称
    self.spawnObjName = self.configService:GetConfigValueByConfigKey(self.VisElement, "spawnObj")
    local spawnPoint = GameObject.Find(self.spawnObjName)
    self.spawnPos = spawnPoint.transform.position
end

--- 初始化一些Service
function FsyncElement:InitService()
    self.avatarService = CourseEnv.ServicesManager:GetAvatarService()
    self.configService = CourseEnv.ServicesManager:GetConfigService()
    self.jsonService = CourseEnv.ServicesManager:GetJsonService()
    self.commonService = App:GetService("CommonService")
end


return FsyncElement
