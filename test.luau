local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua '))()
local player = game:GetService("Players").LocalPlayer
local runService = game:GetService("RunService")

local SETTINGS = {
    Water = false, Gold = false, 
    Speed = 3, IsFarming = false
}

-- Функція перевірки цілі
local function isTarget(obj)
    if not obj or not obj.Parent then return false end
    local n = obj.Name:lower()
    if SETTINGS.Water and (n:find("water pot") or n:find("waterpot")) then return true end
    if SETTINGS.Gold and (n:find("gold") or n:find("golden")) then return true end
    return false
end

local Window = Rayfield:CreateWindow({Name = "Booga Slow Farm 2026", KeySystem = false})
local Tab = Window:CreateTab("Farm")

Tab:CreateToggle({Name = "Water Pots", CurrentValue = false, Callback = function(v) SETTINGS.Water = v end})
Tab:CreateToggle({Name = "Gold Pots", CurrentValue = false, Callback = function(v) SETTINGS.Gold = v end})

-- Зробив слайдер більш чутливим для повільного руху
Tab:CreateSlider({Name = "Fly Speed (1 - повільно)", Range = {1, 50}, Increment = 1, CurrentValue = 3, Callback = function(v) SETTINGS.Speed = v end})

Tab:CreateToggle({Name = "🚀 Start Smooth Farm", CurrentValue = false, Callback = function(v)
    SETTINGS.IsFarming = v
    task.spawn(function()
        while SETTINGS.IsFarming do
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then task.wait(1) continue end
            
            local target, minDist = nil, math.huge
            for _, obj in pairs(workspace.Deployables:GetChildren()) do
                if isTarget(obj) then
                    local pos = obj:GetModelCFrame().p
                    local d = (hrp.Position - pos).Magnitude
                    if d < minDist then minDist = d; target = obj end
                end
            end
            
            if target then
                local targetPos = target:GetModelCFrame().p + Vector3.new(0, 2, 0)
                
                -- ПЛАВНИЙ РУХ ЗАМІСТЬ ТВІНА
                while target.Parent and SETTINGS.IsFarming and (hrp.Position - targetPos).Magnitude > 0.5 do
                    local direction = (targetPos - hrp.Position).Unit
                    -- Швидкість тепер реально плавна
                    hrp.Velocity = Vector3.new(0, 0, 0) -- Обнуляємо фізику, щоб не трусило
                    hrp.CFrame = hrp.CFrame + (direction * (SETTINGS.Speed / 5))
                    runService.Heartbeat:Wait()
                end
                
                -- ЗАВИСАННЯ (чекаємо поки зламаєш)
                while target.Parent and SETTINGS.IsFarming do
                    hrp.CFrame = CFrame.new(target:GetModelCFrame().p + Vector3.new(0, 2, 0))
                    hrp.Velocity = Vector3.new(0,0,0)
                    task.wait(0.1)
                end
            else
                task.wait(0.5)
            end
        end
    end)
