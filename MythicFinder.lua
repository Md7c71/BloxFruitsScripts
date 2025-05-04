local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- استيراد قاعدة بيانات المهام التي قدمتها
local QuestDatabase = {
    -- ... (أدخل هنا كل بيانات المهام التي قدمتها) ...
}

-- إعدادات المستخدم
local Settings = {
    FastTeleport = true,
    AutoFarm = true,
    AutoQuest = true,
    AutoBones = true,
    FruitFarm = true,
    GunFarm = true,
    
    CombatMoves = {"Click", "Z", "X", "F", "V"},
    
    CombatStrategy = {
        NormalAttacksUntilLowHP = 0.2,
        UseGunAtHP = 0.3,
        UseFruitAtHP = 0.5
    }
}

-- متغيرات النظام
local CurrentLevel = LocalPlayer:GetAttribute("Level") or 1
local CurrentQuest = nil
local QuestProgress = 0
local TargetNPC = nil
local TargetEnemies = {}
local FarmEnabled = true

-- نظام التلفيل المحسن
local function FastTeleport(target)
    if typeof(target) == "Instance" and target:IsA("BasePart") then
        HumanoidRootPart.CFrame = target.CFrame * CFrame.new(0, 5, 0)
    elseif typeof(target) == "CFrame" then
        HumanoidRootPart.CFrame = target
    elseif typeof(target) == "Vector3" then
        HumanoidRootPart.CFrame = CFrame.new(target)
    end
    task.wait(0.1)
end

-- نظام البحث عن NPCs
local function FindClosestNPC()
    local closestNPC = nil
    local closestDistance = math.huge
    
    for npcName, npcData in pairs(QuestDatabase.NPCs) do
        local npc = workspace:FindFirstChild(npcData, true)
        if npc and npc:FindFirstChild("HumanoidRootPart") then
            local distance = (HumanoidRootPart.Position - npc.HumanoidRootPart.Position).Magnitude
            if distance < closestDistance then
                closestDistance = distance
                closestNPC = npc
            end
        end
    end
    
    return closestNPC
end

-- نظام اختيار المهمة بناءً على المستوى
local function GetAppropriateQuest()
    local playerLevel = LocalPlayer:GetAttribute("Level") or 1
    local bestQuest = nil
    local highestLevel = 0
    
    for questName, questData in pairs(QuestDatabase) do
        if questName ~= "NPCs" then
            for _, questStep in ipairs(questData) do
                if questStep.LevelReq <= playerLevel and questStep.LevelReq > highestLevel then
                    highestLevel = questStep.LevelReq
                    bestQuest = {
                        Name = questName,
                        Step = questStep,
                        NPC = QuestDatabase.NPCs[questName]
                    }
                end
            end
        end
    end
    
    return bestQuest
end

-- نظام البحث عن الأعداء
local function FindTargetEnemies(quest)
    if not quest then return {} end
    
    local enemies = {}
    for enemyName, _ in pairs(quest.Step.Task) do
        for _, enemy in ipairs(workspace:GetChildren()) do
            if string.find(enemy.Name, enemyName) and enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
                table.insert(enemies, enemy)
            end
        end
    end
    
    return enemies
end

-- نظام القتال المتقدم
local function AttackEnemy(enemy)
    if not enemy or not enemy:FindFirstChild("Humanoid") then return end
    
    local enemyHRP = enemy:FindFirstChild("HumanoidRootPart")
    if not enemyHRP then return end
    
    -- التوجه نحو العدو
    FastTeleport(enemyHRP.CFrame * CFrame.new(0, 0, 5))
    
    -- حساب نسبة حياة العدو
    local enemyHPPercent = enemy.Humanoid.Health / enemy.Humanoid.MaxHealth
    
    -- تطبيق استراتيجية القتال
    if Settings.FruitFarm and enemyHPPercent <= Settings.CombatStrategy.UseFruitAtHP then
        -- استخدام مهارة الفاكهة
        for _, move in ipairs(Settings.CombatMoves) do
            game:GetService("VirtualInputManager"):SendKeyEvent(true, move, false, game)
            task.wait(0.1)
            game:GetService("VirtualInputManager"):SendKeyEvent(false, move, false, game)
        end
    elseif Settings.GunFarm and enemyHPPercent <= Settings.CombatStrategy.UseGunAtHP then
        -- استخدام القن
        game:GetService("VirtualInputManager"):SendKeyEvent(true, "Click", false, game)
        task.wait(0.1)
        game:GetService("VirtualInputManager"):SendKeyEvent(false, "Click", false, game)
    else
        -- استخدام الحركات العادية
        local move = Settings.CombatMoves[math.random(1, #Settings.CombatMoves)]
        game:GetService("VirtualInputManager"):SendKeyEvent(true, move, false, game)
        task.wait(0.1)
        game:GetService("VirtualInputManager"):SendKeyEvent(false, move, false, game)
    end
end

-- نظام المهام التلقائي
local function AutoQuestSystem()
    while FarmEnabled do
        -- تحديث المستوى الحالي
        CurrentLevel = LocalPlayer:GetAttribute("Level") or 1
        
        -- البحث عن مهمة مناسبة
        if not CurrentQuest then
            CurrentQuest = GetAppropriateQuest()
            if CurrentQuest then
                -- البحث عن NPC الخاص بالمهمة
                TargetNPC = FindClosestNPC()
                if TargetNPC then
                    FastTeleport(TargetNPC.HumanoidRootPart)
                    -- محاكاة قبول المهمة
                    task.wait(1)
                    QuestProgress = 0
                    TargetEnemies = FindTargetEnemies(CurrentQuest)
                end
            end
        end
        
        -- إذا كانت هناك مهمة نشطة
        if CurrentQuest and #TargetEnemies > 0 then
            for _, enemy in ipairs(TargetEnemies) do
                if enemy and enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
                    AttackEnemy(enemy)
                    
                    -- إذا هزم العدو، زيادة التقدم
                    if enemy.Humanoid.Health <= 0 then
                        QuestProgress = QuestProgress + 1
                        
                        -- التحقق من إكمال المهمة
                        local required = CurrentQuest.Step.Task[next(CurrentQuest.Step.Task)]
                        if QuestProgress >= required then
                            -- العودة إلى NPC لتسليم المهمة
                            if TargetNPC then
                                FastTeleport(TargetNPC.HumanoidRootPart)
                                task.wait(1)
                            end
                            CurrentQuest = nil
                            break
                        end
                    end
                end
            end
            
            -- تحديث قائمة الأعداء
            TargetEnemies = FindTargetEnemies(CurrentQuest)
        else
            -- إذا لم تكن هناك مهمة، البحث عن أعداء عامين للفارم
            local enemies = workspace:GetChildren()
            for _, enemy in ipairs(enemies) do
                if enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
                    AttackEnemy(enemy)
                end
            end
        end
        
        task.wait(0.5)
    end
end

-- نظام تجميع العظام
local function BoneCollector()
    while FarmEnabled and Settings.AutoBones do
        local bones = workspace:FindFirstChild("Bones") or workspace:FindFirstChild("Bone")
        if bones then
            for _, bone in ipairs(bones:GetChildren()) do
                if bone:IsA("BasePart") then
                    FastTeleport(bone)
                    task.wait(0.2)
                end
            end
        end
        task.wait(5)
    end
end

-- بدء الأنظمة
task.spawn(AutoQuestSystem)
task.spawn(BoneCollector)

-- واجهة تحكم بسيطة
local function ToggleFarm()
    FarmEnabled = not FarmEnabled
    print("Farm status:", FarmEnabled and "Enabled" or "Disabled")
end

-- تعيين زر للتحكم (مثال: زر F5)
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.F5 then
        ToggleFarm()
    end
end)

print("Blox Fruits Advanced Farm Script Loaded!")
