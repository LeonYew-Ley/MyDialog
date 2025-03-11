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

    -- 解析配置，获取音频列表
    -- self:JsonParseConfig()

    -- 初始化音频列表数组
    self.audios = {}

    -- 获取配置中的音频列表
    local audioList = self.configHandler:GetListSubConfigHandler("audioList")
    if audioList then
        for i, subConfigHandler in ipairs(audioList) do
            local audioClip = subConfigHandler:GetAudioByConfigKey("audioFile")
            if audioClip then
                table.insert(self.audios, audioClip)
            end
        end
    end

    g_Log("@@card [对话卡] 加载音频列表完成，共加载 " .. #self.audios .. " 个音频文件")

    -- 使用fire函数发送self.audios数组
    local audioEventKey = "DIALOG_CARD_AUDIOS_LOADED"
    self:Fire(audioEventKey, self.audios)
    g_Log("@@card [对话卡] 已发送音频列表事件: " .. audioEventKey)

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
    self:SendMessage(key, body)
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

return FsyncElement
