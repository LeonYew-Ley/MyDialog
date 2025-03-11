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
local GameObject = CS.UnityEngine.GameObject
local Fsync_Example_KEY = "_Example__Key_"

---@param worldElement CS.Tal.framesync.WorldElement
function FsyncElement:initialize(worldElement)
    FsyncElement.super.initialize(self, worldElement)

    -- 初始化基础变量
    self.npcRoot = nil
    self.btnCanvas = nil -- 对话按钮画布的屏幕画布
    self.npcs = {}       -- 存储所有NPC数据
    self.dialogDistance = tonumber(self.configHandler:GetStringByConfigKey("dialogDistance")) or 2
    self.isInRange = false
    self.distance = math.huge
    self.taskBubble = nil
    self.dialogCardCanvas = nil -- 对话卡的屏幕画布
    self.currentDialogIndex = 1 -- 当前显示的对话索引

    -- 订阅KEY消息
    self:SubscribeMsgKey(Fsync_Example_KEY)
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
    local listConfigHandler = self.configHandler:GetListSubConfigHandler("NPCList")
    for i, configHandler in ipairs(listConfigHandler) do
        -- 创建NPC数据表
        local npcGameObject = configHandler:GetGameObjectByConfigKey("npc")

        if npcGameObject then
            -- 创建NPC数据结构
            local npcData = {
                gameObject = npcGameObject,
                avatar = configHandler:GetSpriteByConfigKey("npcAvatar"),
                dialogJson = nil,
                taskBubble = nil,
                name = configHandler:GetStringByConfigKey("npcName") or "unknown",
                dialogs = {} -- 新增dialogs变量，存储对话内容
            }

            -- 查找任务气泡
            local taskBubble = npcGameObject.transform:Find("场景画布/任务气泡")
            if taskBubble then
                npcData.taskBubble = taskBubble
                g_Log(string.format("@@trigger [对话触发器] NPC%d找到任务气泡", i))
            else
                g_Log(string.format("@@trigger [对话触发器] NPC%d未找到任务气泡", i))
            end

            -- 获取对话文件内容
            local dialogFile = configHandler:GetStringByConfigKey("dialogFile")
            if dialogFile then
                -- 直接解析JSON字符串
                local dialogJson = self.jsonService:decode(dialogFile)
                if dialogJson then
                    -- 保存解析后的JSON对象
                    npcData.dialogJson = dialogJson

                    -- 解析对话内容到dialogs数组
                    if dialogJson.dialogs and type(dialogJson.dialogs) == "table" then
                        npcData.dialogs = dialogJson.dialogs
                        g_Log(string.format("@@trigger [对话触发器] NPC%d成功加载%d条对话", i, #dialogJson.dialogs))
                    else
                        g_LogError(string.format("@@trigger [对话触发器] NPC%d的对话文件格式不正确", i))
                    end
                else
                    g_LogError(string.format("@@trigger [对话触发器] NPC%d的对话文件解析失败", i))
                end
            else
                g_Log(string.format("@@trigger [对话触发器] NPC%d未配置对话文件", i))
            end

            -- 添加到NPC列表
            table.insert(self.npcs, npcData)
            g_Log(string.format("@@trigger [对话触发器] 成功添加NPC%d及其相关数据", i))
        else
            g_LogError(string.format("@@trigger [对话触发器] 未配置NPC%d或NPC%d不存在", i, i))
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

            -- 查找并添加翻页按钮的点击事件
            local nextPageBtn = self.dialogCardCanvas.transform:Find("翻页按钮")
            if nextPageBtn then
                self:AddClickEventListener(nextPageBtn.gameObject, function()
                    self:OnDialogCardBackgroundClick()
                end)
                g_Log("@@trigger [对话触发器] 成功初始化翻页按钮点击事件")
            else
                g_LogError("@@trigger [对话触发器] 未找到翻页按钮")
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

    -- 更新所有NPC的任务气泡朝向
    for i, npc in ipairs(self.npcs) do
        if npc.taskBubble then
            -- 获取当前的欧拉角
            local currentRotation = npc.taskBubble.transform.eulerAngles
            -- 计算朝向玩家的角度
            local direction = playerPos - npc.taskBubble.transform.position
            local targetRotation = CS.UnityEngine.Quaternion.LookRotation(direction)
            local targetEulerY = targetRotation.eulerAngles.y
            -- 只更新Y轴旋转
            npc.taskBubble.transform.eulerAngles = NextMath.Vector3(currentRotation.x, targetEulerY, currentRotation.z)
        end
    end

    -- 检查与每个NPC的距离
    self.distance = math.huge -- 初始化为最大值
    local closestNpcIndex = nil

    -- 遍历所有NPC计算距离
    for i, npc in ipairs(self.npcs) do
        if npc.gameObject and npc.gameObject.transform and npc.gameObject.transform.position then
            -- 确保所有参数都有效再进行距离计算
            local distance = NextMath.DistanceSqrt(playerPos, npc.gameObject.transform.position)
            -- 确保distance不为nil再进行比较
            if distance and type(distance) == "number" then
                if distance < self.distance then
                    self.distance = distance
                    closestNpcIndex = i
                end
            end
        end
    end

    -- 记录最近的NPC索引，用于对话内容显示
    if closestNpcIndex then
        self.currentNpcIndex = closestNpcIndex
    end

    -- 更新是否在范围内的状态
    local newInRange = self.distance and self.distance <= self.dialogDistance

    -- 只在状态发生改变时更新UI和输出日志
    if newInRange ~= self.isInRange then
        self.isInRange = newInRange

        if self.btnCanvas then
            self.btnCanvas.gameObject:SetActive(self.isInRange)

            if self.isInRange and self.currentNpcIndex then
                g_Log(string.format("@@trigger [对话触发器] 进入NPC%d的对话范围", self.currentNpcIndex))
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
    self:SendMessage(key, body)
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

-- 对话卡背景点击处理
function FsyncElement:OnDialogCardBackgroundClick()
    -- 检查是否有当前NPC数据
    if not self.currentNpcIndex or not self.npcs[self.currentNpcIndex] then
        g_LogError("@@trigger [对话触发器] 未找到当前NPC数据")
        return
    end

    local npcData = self.npcs[self.currentNpcIndex]

    -- 检查是否有对话数据
    if not npcData.dialogJson or not npcData.dialogJson.dialogs then
        g_LogError("@@trigger [对话触发器] 未找到对话数据")
        self:CloseDialogCard()
        return
    end

    -- 检查是否还有下一句对话
    if self.currentDialogIndex < #npcData.dialogJson.dialogs then
        -- 更新到下一句对话
        self.currentDialogIndex = self.currentDialogIndex + 1
        g_Log(string.format("@@trigger [对话触发器] 显示下一句对话 %d/%d",
            self.currentDialogIndex, #npcData.dialogJson.dialogs))

        -- 更新对话内容
        self:UpdateDialogContent()
    else
        -- 已经是最后一句，关闭对话卡
        g_Log("@@trigger [对话触发器] 已显示全部对话，关闭对话卡")
        self:CloseDialogCard()
    end
end

-- 关闭对话卡的方法（提取为单独函数以便复用）
function FsyncElement:CloseDialogCard()
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
end

-- 对话按钮点击处理
function FsyncElement:OnDialogButtonClick()
    if self.dialogCardCanvas then
        -- 显示对话卡
        self.dialogCardCanvas.gameObject:SetActive(true)

        -- 隐藏当前NPC的任务气泡
        if self.currentNpcIndex and self.npcs[self.currentNpcIndex] and self.npcs[self.currentNpcIndex].taskBubble then
            self.npcs[self.currentNpcIndex].taskBubble.gameObject:SetActive(false)
        end

        -- 隐藏对话按钮
        if self.btnCanvas then
            self.btnCanvas.gameObject:SetActive(false)
        end

        -- 禁用移动控制
        self.joystickService:SetJoyStickInteractable(false)

        -- 重置对话索引为第一句
        self.currentDialogIndex = 1

        -- 更新对话内容，使用当前最近的NPC
        self:UpdateDialogContent()
    else
        g_LogError("@@trigger [对话触发器] 对话卡画布未初始化")
    end
end

-- 更新对话内容
function FsyncElement:UpdateDialogContent()
    g_Log("@@trigger [对话触发器] 更新对话内容")
    if not self.currentNpcIndex or not self.npcs[self.currentNpcIndex] then
        g_LogError("@@trigger [对话触发器] 未找到当前NPC数据")
        return
    end

    local npcData = self.npcs[self.currentNpcIndex]
    g_Log("@@trigger [对话触发器] 当前NPCid:" .. self.currentNpcIndex)
    -- 查找对话卡中的相关UI元素
    local npcImage = self.dialogCardCanvas.transform:Find("dialog_avatar")
    local npcNameText = self.dialogCardCanvas.transform:Find("dialog_name")
    local dialogText = self.dialogCardCanvas.transform:Find("dialog_text")
    -- 更新NPC半身像
    if npcImage and npcData.avatar then
        local image = npcImage:GetComponent(typeof(CS.UnityEngine.UI.Image))
        if image then
            image.sprite = npcData.avatar
        end
    end

    -- 更新NPC名称和对话内容
    if npcNameText then
        local nameText = npcNameText:GetComponent(typeof(CS.UnityEngine.UI.Text))
        if nameText then
            -- 使用配置的名称
            nameText.text = npcData.name
        end
    end

    -- 更新对话内容
    if dialogText then
        local contentText = dialogText:GetComponent(typeof(CS.TMPro.TextMeshProUGUI))
        if contentText and npcData.dialogJson and npcData.dialogJson.dialogs and
            self.currentDialogIndex <= #npcData.dialogJson.dialogs then
            local dialog = npcData.dialogJson.dialogs[self.currentDialogIndex]
            local content = dialog.content or ""
            local translation = dialog.translation or ""

            -- 组合内容，使用换行符分隔
            if content ~= "" and translation ~= "" then
                contentText.text = content .. "\n" .. translation
            end

            g_Log(string.format("@@trigger [对话触发器] 设置对话内容(%d/%d): %s",
                self.currentDialogIndex, #npcData.dialogJson.dialogs, contentText.text))
        else
            contentText.text = "..."
            g_LogError("@@trigger [对话触发器] 未找到有效的对话内容")
        end
    end

    g_Log(string.format("@@trigger [对话触发器] 已更新NPC%d的对话内容", self.currentNpcIndex))
end

return FsyncElement
