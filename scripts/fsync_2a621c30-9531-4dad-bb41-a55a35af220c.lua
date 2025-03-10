---
---  Author: 【黎恩瑜】
---  AuthorID: 【387657】
---  CreateTime: 【2025-3-7 16:25:45】
--- 【FSync】
--- 【对话卡】
---

local class = require("middleclass")
local WBElement = require("mworld/worldBaseElement")

---@class fsync_2a621c30_9531_4dad_bb41_a55a35af220c : WorldBaseElement
local FsyncElement = class("fsync_2a621c30-9531-4dad-bb41-a55a35af220c", WBElement)

local Fsync_Example_KEY = "_Example__Key_"

---@param worldElement CS.Tal.framesync.WorldElement
function FsyncElement:initialize(worldElement)
    FsyncElement.super.initialize(self, worldElement)
    --订阅KEY消息
    self:SubscribeMsgKey(Fsync_Example_KEY)
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
    self:SendMessage(key,body)
end

-- 自己avatar对象创建完成
-- @param avatar 对应自己的Fsync_avatar对象
function FsyncElement:SelfAvatarCreated(avatar)

end

-- 自己avatar对象人物模型加载完成ba
-- @param avatar 对应自己的Fsync_avatar对象
function FsyncElement:SelfAvatarPrefabLoaded(avatar)

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
function FsyncElement : OnReceiveTriggerEvent(interfaceId)
end
--收到GetData事件
function FsyncElement : OnReceiveGetDataEvent(interfaceId)
    return nil
end

------------------------蓝图组件相应方法End---------------------------------------------

-- 脚本释放
function FsyncElement:Exit()
    FsyncElement.super.Exit(self)
end

return FsyncElement
 

