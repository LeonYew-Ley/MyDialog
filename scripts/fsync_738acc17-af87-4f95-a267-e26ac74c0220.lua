---
---  Author: 【黎恩瑜】
---  AuthorID: 【387657】
---  CreateTime: 【2025-3-7 12:25:47】
--- 【FSync】
--- 【对话触发器】
---
--- 配置项说明：
--- @config npc1 ObjectSelector NPC对象1
--- @config npc2 ObjectSelector NPC对象2
---

local class = require("middleclass")
local WBElement = require("mworld/worldBaseElement")

---@class fsync_738acc17_af87_4f95_a267_e26ac74c0220 : WorldBaseElement
local FsyncElement = class("fsync_738acc17-af87-4f95-a267-e26ac74c0220", WBElement)

local Fsync_Example_KEY = "_Example__Key_"
local Vector3 = CS.UnityEngine.Vector3

---@param worldElement CS.Tal.framesync.WorldElement
function FsyncElement:initialize(worldElement)
    FsyncElement.super.initialize(self, worldElement)
    
    -- 初始化基础变量
    self.npcRoot = nil
    self.btnCanvas = nil        -- 对话按钮画布的屏幕画布
    self.npcs = {}
    self.dialogDistance = 2.0
    self.isInRange = false
    self.distance = math.huge
    self.taskBubble = nil
    self.dialogCardCanvas = nil  -- 对话卡的屏幕画布
    
    -- 订阅KEY消息
    self:SubscribeMsgKey(Fsync_Example_KEY)
    
    g_Log("@@trigger [对话触发器] 初始化完成，对话触发距离: " .. tostring(self.dialogDistance))
end

-- 自己avatar创建完成
function FsyncElement:SelfAvatarCreated(avatar)
    g_Log("@@trigger [对话触发器] Avatar已创建")
    if avatar then
        self.selfAvatar = avatar
        g_Log("@@trigger [对话触发器] Avatar引用已保存")
    else
        g_LogError("@@trigger [对话触发器] 收到的avatar为空")
    end
end

-- 自己avatar预制体加载完成
function FsyncElement:SelfAvatarPrefabLoaded(avatar)
    g_Log("@@trigger [对话触发器] Avatar预制体加载完成，开始初始化场景对象")
    self.avatarGameObject = avatar.Body
    self:InitSceneObjects()
end

-- 初始化场景对象
function FsyncElement:InitSceneObjects()
    -- 查找NPC根节点
    self.npcRoot = GameObject.Find("NPC")
    if not self.npcRoot then
        g_LogError("@@trigger [对话触发器] 未找到NPC根节点")
        return
    end
    
    -- 从配置中获取NPC列表
    local npc1 = self.configHandler:GetGameObjectByConfigKey("npc1")
    local npc2 = self.configHandler:GetGameObjectByConfigKey("npc2")
    
    -- 检查并添加NPC
    if npc1 then 
        table.insert(self.npcs, npc1)
        g_Log("@@trigger [对话触发器] 成功添加NPC1")
    else
        g_LogError("@@trigger [对话触发器] 未配置NPC1或NPC1不存在")
    end
    
    if npc2 then 
        table.insert(self.npcs, npc2)
        g_Log("@@trigger [对话触发器] 成功添加NPC2")
    else
        g_LogError("@@trigger [对话触发器] 未配置NPC2或NPC2不存在")
    end
    
    -- 获取NPC1的任务气泡
    if npc1 then
        self.taskBubble = npc1.transform:Find("场景画布/任务气泡")
        if self.taskBubble then
            g_Log("@@trigger [对话触发器] 成功找到任务气泡")
        else
            g_LogError("@@trigger [对话触发器] 未找到任务气泡")
        end
    end
    
    -- 查找对话按钮画布
    local dialogBtnCanvas = GameObject.Find("对话按钮画布")
    if dialogBtnCanvas then
        self.btnCanvas = dialogBtnCanvas.transform:Find("屏幕画布")
        if self.btnCanvas then
            -- 初始时隐藏按钮画布
            self.btnCanvas.gameObject:SetActive(false)
            
            -- 查找对话按钮并添加点击事件
            local dialogBtn = self.btnCanvas.transform:Find("对话按钮")
            if dialogBtn then
                self:AddClickEventListener(dialogBtn.gameObject, function()
                    self:OnDialogButtonClick()
                end)
                g_Log("@@trigger [对话触发器] 成功初始化对话按钮点击事件")
            else
                g_LogError("@@trigger [对话触发器] 未找到对话按钮")
            end
            
            g_Log("@@trigger [对话触发器] 成功初始化按钮画布")
        else
            g_LogError("@@trigger [对话触发器] 未找到屏幕画布")
        end
    else
        g_LogError("@@trigger [对话触发器] 未找到对话按钮画布")
    end

    -- 查找对话卡画布
    local dialogCard = GameObject.Find("对话卡")
    if dialogCard then
        self.dialogCardCanvas = dialogCard.transform:Find("屏幕画布")
        if self.dialogCardCanvas then
            -- 初始时隐藏对话卡
            self.dialogCardCanvas.gameObject:SetActive(false)
            
            -- 查找并添加黑色背景按钮的点击事件
            local blackBgBtn = self.dialogCardCanvas.transform:Find("黑色背景按钮")
            if blackBgBtn then
                self:AddClickEventListener(blackBgBtn.gameObject, function()
                    self:OnDialogCardBackgroundClick()
                end)
                g_Log("@@trigger [对话触发器] 成功初始化对话卡背景点击事件")
            else
                g_LogError("@@trigger [对话触发器] 未找到对话卡黑色背景按钮")
            end
            
            g_Log("@@trigger [对话触发器] 成功找到对话卡画布")
        else
            g_LogError("@@trigger [对话触发器] 未找到对话卡画布")
        end
    else
        g_LogError("@@trigger [对话触发器] 未找到对话卡")
    end
end

-- 每帧检测距离
function FsyncElement:Tick()
    -- 确保所有必要条件都满足才执行
    if not self.selfAvatar then
        return
    end
    -- 获取玩家位置
    local playerPos = self.avatarGameObject.transform.position
    -- 更新任务气泡朝向
    if self.taskBubble then
        -- 获取当前的欧拉角
        local currentRotation = self.taskBubble.transform.eulerAngles
        -- 计算朝向玩家的角度
        local direction = playerPos - self.taskBubble.transform.position
        local targetRotation = CS.UnityEngine.Quaternion.LookRotation(direction)
        local targetEulerY = targetRotation.eulerAngles.y
        -- 只更新Y轴旋转
        self.taskBubble.transform.eulerAngles = CS.UnityEngine.Vector3(currentRotation.x, targetEulerY, currentRotation.z)
    end

    -- 检查与每个NPC的距离
    self.distance = math.huge  -- 初始化为最大值
    for i, npc in ipairs(self.npcs) do
        if npc and npc.transform and npc.transform.position then
            -- 确保所有参数都有效再进行距离计算
            local distance = Vector3.Distance(playerPos, npc.transform.position)
            -- 确保distance不为nil再进行比较
            if distance and type(distance) == "number" then
                self.distance = math.min(self.distance, distance)
                -- g_Log(string.format("@@trigger [对话触发器] NPC_%d 距离: %.2f, 最小距离: %.2f", i, distance, self.distance))
            end
        end
    end
    
    -- 更新是否在范围内的状态
    local newInRange = self.distance and self.distance <= self.dialogDistance
    
    -- 只在状态发生改变时更新UI和输出日志
    if newInRange ~= self.isInRange then
        self.isInRange = newInRange
        
        if self.btnCanvas then
            self.btnCanvas.gameObject:SetActive(self.isInRange)
            if self.isInRange then
                g_Log(string.format("@@trigger [对话触发器] 进入对话范围，显示按钮，距离: %.2f", self.distance))
            else
                g_Log(string.format("@@trigger [对话触发器] 离开对话范围，隐藏按钮，恢复移动控制，距离: %.2f", self.distance or 0))
            end
        end
    end
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

-- 对话卡背景点击处理
function FsyncElement:OnDialogCardBackgroundClick()
    g_Log("@@trigger [对话触发器] 点击对话卡背景，关闭对话卡")
    
    -- 隐藏对话卡
    if self.dialogCardCanvas then
        self.dialogCardCanvas.gameObject:SetActive(false)
    end
    
    -- 显示对话按钮
    if self.btnCanvas then
        self.btnCanvas.gameObject:SetActive(true)
    end

    -- 启用移动控制
    self.joystickService:SetJoyStickInteractable(true)
    g_Log("@@trigger [对话触发器] 启用移动控制")
end

-- 对话按钮点击处理
function FsyncElement:OnDialogButtonClick()
    if self.dialogCardCanvas then
        -- 显示对话卡
        self.dialogCardCanvas.gameObject:SetActive(true)
        -- 隐藏任务气泡
        self.taskBubble.gameObject:SetActive(false)
        -- 隐藏对话按钮
        if self.btnCanvas then
            self.btnCanvas.gameObject:SetActive(false)
        end
        -- 禁用移动控制
        self.joystickService:SetJoyStickInteractable(false)
        g_Log("@@trigger [对话触发器] 显示对话卡，禁用移动控制")
        
        -- 发送对话更新事件
        self:UpdateDialogContent()
    else
        g_LogError("@@trigger [对话触发器] 对话卡画布未初始化")
    end
end

return FsyncElement
 

