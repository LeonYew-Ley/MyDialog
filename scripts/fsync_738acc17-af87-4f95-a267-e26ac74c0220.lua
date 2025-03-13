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
    self.currentAudioSource = nil
    self.isAudioPlaying = false -- 音频播放状态跟踪
    self.isAudioPaused = false  -- 新增：音频暂停状态跟踪
    self.practiceButtonAnimator = nil


    -- 订阅KEY消息
    self:SubscribeMsgKey(Fsync_Example_KEY)
end

-- 音频数据接收后的处理逻辑
function FsyncElement:OnAudiosReceived()
    -- 这里可以添加接收到音频数据后的处理逻辑
    -- 例如：更新UI、播放第一个音频等

    if #self.audios > 0 then
        g_Log("@@trigger [对话触发器] 音频数据接收完成，可以使用了")

        -- 示例：打印所有接收到的音频信息
        for i, audioData in ipairs(self.audios) do
            g_Log(string.format("@@trigger [对话触发器] 音频 %d: %s", i, audioData.path or "未知路径"))
        end
    end
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
                dialogs = {},      -- 新增dialogs变量，存储对话内容
                audios = {},       -- 为每个NPC添加音频数组
                isFirstPlay = true -- 新增：是否是第一次播放音频
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
                        -- 加载每句对话的音频
                        for j, dialog in ipairs(npcData.dialogs) do
                            if dialog.url and dialog.url ~= "" then
                                -- 使用正确的URL加载方式
                                g_Log(string.format("@@trigger [对话触发器] 开始加载对话音频URL: %s", dialog.url))
                                -- 捕获当前的j值，避免闭包问题
                                local currentIndex = j
                                -- 使用AudioService加载远程URL音频
                                self.audioService:GetMp3AudioFromGetUrl(
                                    dialog.url,
                                    function(error)
                                        -- 加载失败回调
                                        g_LogError(string.format("@@trigger [对话触发器] 对话音频加载失败，索引: %d, 错误: %s",
                                            currentIndex, tostring(error)))
                                    end,
                                    function(audioClip)
                                        -- 加载成功回调
                                        if audioClip then
                                            npcData.audios[currentIndex] = audioClip
                                            g_Log(string.format("@@trigger [对话触发器] 对话音频加载成功, 索引: %d", currentIndex))
                                        else
                                            g_LogError(string.format("@@trigger [对话触发器] 获取到空的音频资源, 索引: %d", currentIndex))
                                        end
                                    end
                                )
                            end
                        end
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

            -- 查找UI物体并获取练习按钮
            local uiObject = GameObject.Find("UI")
            if uiObject then
                local assetBtn = uiObject.transform:Find("Ley_PracticeAudioBtn/Asset")
                if assetBtn then
                    -- 直接使用Asset按钮，改变其父级
                    assetBtn.transform:SetParent(self.dialogCardCanvas, false)

                    -- 设置按钮位置
                    local rectTransform = assetBtn:GetComponent(typeof(CS.UnityEngine.RectTransform))
                    if rectTransform then
                        -- 设置锚点为底部中心
                        rectTransform.anchorMin = CS.UnityEngine.Vector2(0.5, 0)
                        rectTransform.anchorMax = CS.UnityEngine.Vector2(0.5, 0)
                        -- 设置位置
                        rectTransform.anchoredPosition = CS.UnityEngine.Vector2(-166.48, 280.66)
                        -- 强制刷新布局
                        CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(rectTransform)
                    end

                    -- 为练习按钮添加点击事件
                    self:AddClickEventListener(assetBtn.gameObject, function()
                        self:OnPracticeButtonClick()
                    end)

                    -- 保存按钮引用以便后续使用
                    self.practiceButton = assetBtn.gameObject

                    -- 获取并存储Animator组件
                    local animator = assetBtn.gameObject:GetComponent(typeof(CS.UnityEngine.Animator))
                    if animator then
                        self.practiceButtonAnimator = animator
                        g_Log("@@trigger [对话触发器] 成功获取练习按钮Animator组件")
                    else
                        g_LogError("@@trigger [对话触发器] 练习按钮没有Animator组件")
                    end

                    g_Log("@@trigger [对话触发器] 成功添加练习按钮到对话卡")
                else
                    g_LogError("@@trigger [对话触发器] 未找到练习按钮Asset")
                end
            else
                g_LogError("@@trigger [对话触发器] 未找到UI物体")
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
    g_Log("@@trigger [对话触发器] 退出")

    -- 停止正在播放的音频
    if self.currentAudioSource then
        self.audioService:StopAudioClip(self.currentAudioSource)
        self.currentAudioSource = nil
    end

    FsyncElement.super.Exit(self)
end

-- 对话卡背景点击处理
function FsyncElement:OnDialogCardBackgroundClick()
    -- 如果音频正在播放，不允许继续操作
    if self.isAudioPlaying then
        g_Log("@@trigger [对话触发器] 音频播放中，请等待播放完成...")
        return
    end

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
        self.npcs[self.currentNpcIndex].isFirstPlay = false
        self.currentDialogIndex = self.currentDialogIndex + 1
        g_Log(string.format("@@trigger [对话触发器] 显示下一句对话 %d/%d",
            self.currentDialogIndex, #npcData.dialogJson.dialogs))

        -- 更新对话内容
        self:UpdateDialogContent()
    else
        -- 已经是最后一句，关闭对话卡
        self:CloseDialogCard()
        g_Log("@@trigger [对话触发器] 已显示全部对话，关闭对话卡")
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

    -- 关闭第一次对话
    -- self.npcs[self.currentNpcIndex].isFirstPlay = false
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
    npcData.isFirstPlay = true
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

    -- 更新NPC名称
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

            -- 播放对应的音频
            self:PlayAudio(self.currentDialogIndex)
        else
            contentText.text = "..."
            g_LogError("@@trigger [对话触发器] 未找到有效的对话内容")
        end
    end

    g_Log(string.format("@@trigger [对话触发器] 已更新NPC%d的对话内容", self.currentNpcIndex))
end

-- 播放对话音频
function FsyncElement:PlayAudio(index)
    g_Log(string.format("@@trigger [对话触发器] 尝试播放对话音频 %d", index))

    if not self.currentNpcIndex or not self.npcs[self.currentNpcIndex] then
        g_LogError("@@trigger [对话触发器] 未找到当前NPC数据")
        return
    end

    local npcData = self.npcs[self.currentNpcIndex]

    -- 检查音频是否存在
    if not npcData.audios or not npcData.audios[index] then
        g_LogError(string.format("@@trigger [对话触发器] 没有可播放的音频 NPC:%d, 对话索引:%d", self.currentNpcIndex, index))
        return
    end

    -- 如果有正在播放的音频，先停止
    if self.currentAudioSource then
        self.audioService:StopAudioClip(self.currentAudioSource)
        self.currentAudioSource = nil
    end

    -- 获取音频剪辑
    local audioClip = npcData.audios[index]
    if audioClip then
        -- 设置正在播放标志
        self.isAudioPlaying = true

        if npcData.isFirstPlay then
            self.practiceButtonAnimator:SetTrigger("forbid")
        else
            self.practiceButtonAnimator:ResetTrigger("forbid")
            self.practiceButtonAnimator:ResetTrigger("active")
            self.practiceButtonAnimator:SetTrigger("play")
        end

        self.currentAudioSource = self.audioService:PlayClipOneShot(audioClip, function()
            g_Log("@@trigger [对话触发器] 音频播放完成")

            self.currentAudioSource = nil

            -- 重置播放状态
            self.isAudioPlaying = false
            self.practiceButtonAnimator:ResetTrigger("forbid")
            self.practiceButtonAnimator:ResetTrigger("play")
            self.practiceButtonAnimator:SetTrigger("active")
            npcData.isFirstPlay = false
        end, 1.0, 1.0) -- 音量和音调参数

        g_Log(string.format("@@trigger [对话触发器] 开始播放对话音频 NPC:%d, 对话索引:%d", self.currentNpcIndex, index))
    else
        g_LogError(string.format("@@trigger [对话触发器] 音频剪辑无效 NPC:%d, 对话索引:%d", self.currentNpcIndex, index))
    end
end

-- 练习按钮点击处理
function FsyncElement:OnPracticeButtonClick()
    g_Log("@@trigger [对话触发器] 练习按钮被点击")

    local npcData = self.npcs[self.currentNpcIndex]

    -- 如果是第一次播放，直接返回，不执行任何操作
    if npcData.isFirstPlay then
        g_Log("@@trigger [对话触发器] 首次播放中，练习按钮不可用")
        return
    end

    -- 如果没有当前播放的音频，则开始播放
    if not self.currentAudioSource then
        -- 重新播放当前对话的音频，用于练习
        self:PlayAudio(self.currentDialogIndex)
    else
        -- 切换暂停/播放状态
        if self.isAudioPlaying then
            -- 当前正在播放，需要暂停
            g_Log("@@trigger [对话触发器] 暂停音频播放")

            -- 暂停音频
            if self.currentAudioSource then
                self.currentAudioSource:Pause()
                self.isAudioPlaying = false
                self.isAudioPaused = true

                -- 更新按钮动画状态为active
                if self.practiceButtonAnimator then
                    self.practiceButtonAnimator:ResetTrigger("play")
                    self.practiceButtonAnimator:ResetTrigger("forbid")
                    self.practiceButtonAnimator:SetTrigger("active")
                end
            end
        else
            -- 当前已暂停，需要恢复播放
            g_Log("@@trigger [对话触发器] 恢复音频播放")

            -- 恢复音频播放
            if self.currentAudioSource and self.isAudioPaused then
                self.currentAudioSource:Play()
                self.isAudioPlaying = true
                self.isAudioPaused = false

                -- 更新按钮动画状态为播放中
                if self.practiceButtonAnimator then
                    self.practiceButtonAnimator:ResetTrigger("active")
                    self.practiceButtonAnimator:ResetTrigger("forbid")
                    self.practiceButtonAnimator:SetTrigger("play")
                end
            end
        end
    end
end

return FsyncElement
