local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'))()
local player = game:GetService("Players").LocalPlayer
local runService = game:GetService("RunService")

local SETTINGS = {
    SelectedTypes = {},
    Speed = 3, 
    IsFarming = false
}

local CurrentTarget = nil
local ESPHighlight = nil

-- ESP Highlight Function
local function CreateESP(target)
    if ESPHighlight then
        ESPHighlight:Destroy()
        ESPHighlight = nil
    end
    
    if not target or not target.Parent then return end
    
    local targetName = target.Name:lower()
    local fillColor = Color3.fromRGB(255, 255, 0)
    local outlineColor = Color3.fromRGB(200, 200, 0)
    
    if targetName:find("water") then
        fillColor = Color3.fromRGB(0, 150, 255)
        outlineColor = Color3.fromRGB(0, 100, 200)
    elseif targetName:find("gold") or targetName:find("golden") then
        fillColor = Color3.fromRGB(255, 215, 0)
        outlineColor = Color3.fromRGB(200, 150, 0)
    end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "FarmTargetESP"
    highlight.Adornee = target
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = fillColor
    highlight.OutlineColor = outlineColor
    highlight.FillTransparency = 0.6
    highlight.OutlineTransparency = 0.2
    highlight.Parent = target
    
    ESPHighlight = highlight
end

local function RemoveESP()
    if ESPHighlight then
        ESPHighlight:Destroy()
        ESPHighlight = nil
    end
end

local function isTarget(obj)
    if not obj or not obj.Parent then return false end
    local n = obj.Name:lower()
    
    if n:find("omega") then return false end
    
    for _, selectedType in pairs(SETTINGS.SelectedTypes) do
        if selectedType == "Water Pots" and (n:find("water pot") or n:find("waterpot")) then 
            return true 
        end
        if selectedType == "Gold Pots" and (n:find("gold") or n:find("golden")) then 
            return true 
        end
    end
    return false
end

local Window = Rayfield:CreateWindow({Name = "Booga Slow Farm 2026", KeySystem = false})
local Tab = Window:CreateTab("Farming")

Tab:CreateDropdown({
    Name = "Select Pot Types", 
    Options = {"Water Pots", "Gold Pots"},
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "PotTypes",
    Callback = function(selectedOptions)
        SETTINGS.SelectedTypes = selectedOptions
    end
})

Tab:CreateSlider({
    Name = "Fly Speed (1 = slow)", 
    Range = {1, 50}, 
    Increment = 1, 
    CurrentValue = 3, 
    Callback = function(v) 
        SETTINGS.Speed = v 
    end
})

Tab:CreateToggle({
    Name = "Start Smooth Farm", 
    CurrentValue = false, 
    Callback = function(v)
        SETTINGS.IsFarming = v
        
        if not v then
            RemoveESP()
            CurrentTarget = nil
        end
        
        task.spawn(function()
            while SETTINGS.IsFarming do
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                
                if not hrp then 
                    task.wait(1) 
                    continue 
                end
                
                if #SETTINGS.SelectedTypes == 0 then
                    task.wait(0.5)
                    continue
                end
                
                local target, minDist = nil, math.huge
                for _, obj in pairs(workspace.Deployables:GetChildren()) do
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
                
                if target ~= CurrentTarget then
                    CurrentTarget = target
                    if target then
                        CreateESP(target)
                    else
                        RemoveESP()
                    end
                end
                
                if target then
                    local success, targetCF = pcall(function()
                        return target:GetModelCFrame()
                    end)
                    
                    if success and targetCF then
                        local targetPos = targetCF.p + Vector3.new(0, 2, 0)
                        
                        while target.Parent and SETTINGS.IsFarming and CurrentTarget == target do
                            local currentPos = hrp.Position
                            local distance = (currentPos - targetPos).Magnitude
                            
                            if distance <= 0.5 then break end
                            
                            local direction = (targetPos - currentPos).Unit
                            hrp.Velocity = Vector3.new(0, 0, 0)
                            hrp.CFrame = hrp.CFrame + (direction * (SETTINGS.Speed / 5))
                            runService.Heartbeat:Wait()
                        end
                        
                        while target.Parent and SETTINGS.IsFarming and CurrentTarget == target do
                            local success, cf = pcall(function()
                                return target:GetModelCFrame()
                            end)
                            if success and cf then
                                hrp.CFrame = CFrame.new(cf.p + Vector3.new(0, 2, 0))
                            end
                            hrp.Velocity = Vector3.new(0,0,0)
                            task.wait(0.1)
                        end
                    end
                else
                    task.wait(0.5)
                end
            end
            
            RemoveESP()
            CurrentTarget = nil
        end)
    end
})
