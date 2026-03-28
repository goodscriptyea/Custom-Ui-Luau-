--// Загружаем Status UI (если еще не загружено)
local Status = loadstring(game:HttpGet('https://raw.githubusercontent.com/goodscriptyea/Custom-Ui-Luau-/refs/heads/main/main%20ui.luau'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer

local SETTINGS = {
    Water = false, 
    Gold = false, 
    Speed = 3, 
    IsFarming = false,
    AutoClick = false
}

--// Функция проверки цели
local function isTarget(obj)
    if not obj or not obj.Parent then return false end
    local n = obj.Name:lower()
    if SETTINGS.Water and (n:find("water pot") or n:find("waterpot")) then return true end
    if SETTINGS.Gold and (n:find("gold") or n:find("golden")) then return true end
    return false
end

--// Создаем таб
local FarmTab = Status.CreateTab("Farm")

--// Water Pots Toggle
FarmTab:AddToggle("Water Pots", false, function(v)
    SETTINGS.Water = v
end)

--// Gold Pots Toggle  
FarmTab:AddToggle("Gold Pots", false, function(v)
    SETTINGS.Gold = v
end)

--// Speed Slider (1-50)
FarmTab:AddSlider("Fly Speed", 1, 50, 3, function(v)
    SETTINGS.Speed = v
end)

--// Auto Clicker (просто тапает по экрану)
local autoClickConnection = nil
FarmTab:AddToggle("Auto Clicker", false, function(v)
    SETTINGS.AutoClick = v
    
    if v then
        -- Запускаем авто-клик в отдельном потоке
        task.spawn(function()
            while SETTINGS.AutoClick do
                -- Кликаем в центр экрана (1920x1080 дефолт, но работает везде)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                task.wait(0.05) -- 10 кликов в секунду (100мс задержка между кликами)
            end
        end)
    end
end)

--// Main Farm Toggle
FarmTab:AddToggle("🚀 Start Smooth Farm", false, function(v)
    SETTINGS.IsFarming = v
    
    if v then
        task.spawn(function()
            while SETTINGS.IsFarming do
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                
                if not hrp then 
                    task.wait(1) 
                    continue 
                end
                
                -- Ищем ближайшую цель
                local target, minDist = nil, math.huge
                local deployables = workspace:FindFirstChild("Deployables")
                
                if deployables then
                    for _, obj in pairs(deployables:GetChildren()) do
                        if isTarget(obj) then
                            local success, pos = pcall(function()
                                return obj:GetModelCFrame().p
                            end)
                            if success and pos then
                                local d = (hrp.Position - pos).Magnitude
                                if d < minDist then 
                                    minDist = d
                                    target = obj 
                                end
                            end
                        end
                    end
                end
                
                if target then
                    local targetPos = target:GetModelCFrame().p + Vector3.new(0, 2, 0)
                    
                    -- ПЛАВНЫЙ РУХ К ЦЕЛИ
                    while target.Parent and SETTINGS.IsFarming and (hrp.Position - targetPos).Magnitude > 0.5 do
                        local direction = (targetPos - hrp.Position).Unit
                        hrp.Velocity = Vector3.new(0, 0, 0)
                        hrp.CFrame = hrp.CFrame + (direction * (SETTINGS.Speed / 5))
                        RunService.Heartbeat:Wait()
                    end
                    
                    -- ЗАВИСАНИЕ НАД ЦЕЛЬЮ (ждем пока сломают)
                    while target.Parent and SETTINGS.IsFarming do
                        hrp.CFrame = CFrame.new(target:GetModelCFrame().p + Vector3.new(0, 2, 0))
                        hrp.Velocity = Vector3.new(0, 0, 0)
                        task.wait(0.1)
                    end
                else
                    task.wait(0.5)
                end
            end
        end)
    end
end)

--// Дополнительно: кнопка для телепорта к случайному водному горшку (для теста)
FarmTab:AddButton("Find Nearest Pot", function()
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local target, minDist = nil, math.huge
    local deployables = workspace:FindFirstChild("Deployables")
    
    if deployables then
        for _, obj in pairs(deployables:GetChildren()) do
            if isTarget(obj) then
                local success, pos = pcall(function()
                    return obj:GetModelCFrame().p
                end)
                if success and pos then
                    local d = (hrp.Position - pos).Magnitude
                    if d < minDist then 
                        minDist = d
                        target = obj 
                    end
                end
            end
        end
    end
    
    if target then
        hrp.CFrame = target:GetModelCFrame().p + Vector3.new(0, 3, 0)
    else
        print("No pots found!")
    end
end)
