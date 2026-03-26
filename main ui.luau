--// Status UI | Rounded Edition
--// Monochrome + Rounded Corners

if getgenv().StatusUI_Loaded then return end
getgenv().StatusUI_Loaded = true

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

--// Config
local Config = {
    Title = "STATUS",
    Size = UDim2.new(0, 600, 0, 400),
    Position = UDim2.new(0.5, -300, 0.5, -200),
    Theme = {
        Background = Color3.fromRGB(10, 10, 10),
        Secondary = Color3.fromRGB(20, 20, 20),
        Accent = Color3.fromRGB(255, 255, 255),
        Text = Color3.fromRGB(255, 255, 255),
        SubText = Color3.fromRGB(120, 120, 120),
        Border = Color3.fromRGB(40, 40, 40)
    }
}

local function Tween(obj, props, duration, style, dir)
    style = style or Enum.EasingStyle.Quart
    dir = dir or Enum.EasingDirection.Out
    local info = TweenInfo.new(duration or 0.3, style, dir)
    local tween = TweenService:Create(obj, info, props)
    tween:Play()
    return tween
end

local function MakeDraggable(topbar, frame)
    local dragging, dragInput, dragStart, startPos
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

--// UI Creation
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = HttpService:GenerateGUID(false)
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 0, 0, 0)
MainFrame.Position = Config.Position
MainFrame.BackgroundColor3 = Config.Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Size = UDim2.new(1, 0, 0, 45)
TitleBar.BackgroundColor3 = Config.Theme.Secondary
TitleBar.BorderSizePixel = 0

Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 0)

local TitleText = Instance.new("TextLabel", TitleBar)
TitleText.Size = UDim2.new(1, -100, 1, 0)
TitleText.Position = UDim2.new(0, 20, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = Config.Title
TitleText.TextColor3 = Config.Theme.Text
TitleText.TextSize = 18
TitleText.Font = Enum.Font.GothamBold
TitleText.TextXAlignment = Enum.TextXAlignment.Left

-- Control Buttons (серые с округлением)
local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 7)
CloseBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Config.Theme.Text
CloseBtn.TextSize = 18
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.AutoButtonColor = false

Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

local MinimizeBtn = Instance.new("TextButton", TitleBar)
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -75, 0, 7)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
MinimizeBtn.Text = "−"
MinimizeBtn.TextColor3 = Config.Theme.Text
MinimizeBtn.TextSize = 18
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.AutoButtonColor = false

Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 8)

local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 160, 1, -45)
Sidebar.Position = UDim2.new(0, 0, 0, 45)
Sidebar.BackgroundColor3 = Config.Theme.Secondary
Sidebar.BackgroundTransparency = 0.5
Sidebar.BorderSizePixel = 0

Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 0)

local TabContainer = Instance.new("Frame", MainFrame)
TabContainer.Size = UDim2.new(1, -160, 1, -45)
TabContainer.Position = UDim2.new(0, 160, 0, 45)
TabContainer.BackgroundTransparency = 1

-- Toggle Button (округлый)
local ToggleBtn = Instance.new("TextButton", ScreenGui)
ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
ToggleBtn.Position = UDim2.new(0, 20, 0, 20)
ToggleBtn.BackgroundColor3 = Config.Theme.Secondary
ToggleBtn.Text = "S"
ToggleBtn.TextColor3 = Config.Theme.Text
ToggleBtn.TextSize = 20
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Visible = false
ToggleBtn.Active = true
ToggleBtn.Draggable = true

Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)

local Tabs = {}
local ActiveTab = nil
local Minimized = false

MakeDraggable(TitleBar, MainFrame)
MakeDraggable(ToggleBtn, ToggleBtn)

local function ToggleUI()
    Minimized = not Minimized
    if Minimized then
        ToggleBtn.Visible = true
        Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        wait(0.4)
        MainFrame.Visible = false
    else
        MainFrame.Visible = true
        Tween(MainFrame, {Size = Config.Size}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        wait(0.4)
        ToggleBtn.Visible = false
    end
end

local function CreateTab(name)
    local TabBtn = Instance.new("TextButton", Sidebar)
    TabBtn.Size = UDim2.new(1, -20, 0, 40)
    TabBtn.Position = UDim2.new(0, 10, 0, 10 + (#Tabs * 50))
    TabBtn.BackgroundColor3 = Config.Theme.Secondary
    TabBtn.Text = ""
    TabBtn.AutoButtonColor = false
    
    Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 8)
    
    local Indicator = Instance.new("Frame", TabBtn)
    Indicator.Size = UDim2.new(0, 3, 0, 20)
    Indicator.Position = UDim2.new(0, 0, 0.5, -10)
    Indicator.BackgroundColor3 = Config.Theme.Accent
    Indicator.Visible = false
    Indicator.BorderSizePixel = 0
    
    Instance.new("UICorner", Indicator).CornerRadius = UDim.new(0, 2)
    
    local TabText = Instance.new("TextLabel", TabBtn)
    TabText.Size = UDim2.new(1, -20, 1, 0)
    TabText.Position = UDim2.new(0, 15, 0, 0)
    TabText.BackgroundTransparency = 1
    TabText.Text = name
    TabText.TextColor3 = Config.Theme.SubText
    TabText.TextSize = 14
    TabText.Font = Enum.Font.GothamSemibold
    TabText.TextXAlignment = Enum.TextXAlignment.Left
    
    local Content = Instance.new("ScrollingFrame", TabContainer)
    Content.Size = UDim2.new(1, -20, 1, -20)
    Content.Position = UDim2.new(0, 10, 0, 10)
    Content.BackgroundTransparency = 1
    Content.ScrollBarThickness = 3
    Content.ScrollBarImageColor3 = Config.Theme.Accent
    Content.Visible = false
    Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    
    local UIList = Instance.new("UIListLayout", Content)
    UIList.Padding = UDim.new(0, 10)
    
    local function Activate()
        if ActiveTab == Content then return end
        
        if ActiveTab then ActiveTab.Visible = false end
        
        for _, tab in pairs(Tabs) do
            tab.Indicator.Visible = false
            Tween(tab.Button, {BackgroundColor3 = Config.Theme.Secondary}, 0.2)
            Tween(tab.Text, {TextColor3 = Config.Theme.SubText}, 0.2)
        end
        
        ActiveTab = Content
        Content.Visible = true
        Indicator.Visible = true
        
        Tween(TabBtn, {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}, 0.3)
        Tween(TabText, {TextColor3 = Config.Theme.Text}, 0.2)
    end
    
    TabBtn.MouseButton1Click:Connect(Activate)
    
    TabBtn.MouseEnter:Connect(function()
        if ActiveTab ~= Content then
            Tween(TabBtn, {BackgroundColor3 = Color3.fromRGB(35, 35, 35)}, 0.2)
        end
    end)
    
    TabBtn.MouseLeave:Connect(function()
        if ActiveTab ~= Content then
            Tween(TabBtn, {BackgroundColor3 = Config.Theme.Secondary}, 0.2)
        end
    end)
    
    local TabData = {
        Button = TabBtn,
        Content = Content,
        Indicator = Indicator,
        Text = TabText,
        
        AddButton = function(self, text, callback)
            local Btn = Instance.new("TextButton", Content)
            Btn.Size = UDim2.new(1, 0, 0, 40)
            Btn.BackgroundColor3 = Config.Theme.Secondary
            Btn.Text = text
            Btn.TextColor3 = Config.Theme.Text
            Btn.TextSize = 14
            Btn.Font = Enum.Font.Gotham
            Btn.AutoButtonColor = false
            
            Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)
            
            Btn.MouseEnter:Connect(function()
                Tween(Btn, {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}, 0.2)
            end)
            
            Btn.MouseLeave:Connect(function()
                Tween(Btn, {BackgroundColor3 = Config.Theme.Secondary}, 0.2)
            end)
            
            Btn.MouseButton1Click:Connect(function()
                if callback then 
                    local success, err = pcall(callback)
                    if not success then print("Error:", err) end
                end
            end)
        end,
        
        AddToggle = function(self, text, default, callback)
            local ToggleFrame = Instance.new("Frame", Content)
            ToggleFrame.Size = UDim2.new(1, 0, 0, 40)
            ToggleFrame.BackgroundColor3 = Config.Theme.Secondary
            ToggleFrame.BorderSizePixel = 0
            
            Instance.new("UICorner", ToggleFrame).CornerRadius = UDim.new(0, 8)
            
            local ToggleText = Instance.new("TextLabel", ToggleFrame)
            ToggleText.Size = UDim2.new(1, -70, 1, 0)
            ToggleText.Position = UDim2.new(0, 15, 0, 0)
            ToggleText.BackgroundTransparency = 1
            ToggleText.Text = text
            ToggleText.TextColor3 = Config.Theme.Text
            ToggleText.TextSize = 14
            ToggleText.Font = Enum.Font.Gotham
            ToggleText.TextXAlignment = Enum.TextXAlignment.Left
            
            -- Switch с округлением (pill shape)
            local Switch = Instance.new("TextButton", ToggleFrame)
            Switch.Size = UDim2.new(0, 44, 0, 24)
            Switch.Position = UDim2.new(1, -60, 0.5, -12)
            Switch.BackgroundColor3 = default and Config.Theme.Text or Color3.fromRGB(60, 60, 60)
            Switch.Text = ""
            Switch.AutoButtonColor = false
            
            Instance.new("UICorner", Switch).CornerRadius = UDim.new(1, 0)
            
            local Circle = Instance.new("Frame", Switch)
            Circle.Size = UDim2.new(0, 18, 0, 18)
            Circle.Position = default and UDim2.new(1, -21, 0, 3) or UDim2.new(0, 3, 0, 3)
            Circle.BackgroundColor3 = Config.Theme.Background
            Circle.BorderSizePixel = 0
            
            Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)
            
            local Value = default
            
            Switch.MouseButton1Click:Connect(function()
                Value = not Value
                local targetPos = Value and UDim2.new(1, -21, 0, 3) or UDim2.new(0, 3, 0, 3)
                local targetColor = Value and Config.Theme.Text or Color3.fromRGB(60, 60, 60)
                
                Tween(Circle, {Position = targetPos}, 0.3)
                Tween(Switch, {BackgroundColor3 = targetColor}, 0.3)
                
                if callback then
                    pcall(function() callback(Value) end)
                end
            end)
        end,
        
        AddSlider = function(self, text, min, max, default, callback)
            local SliderFrame = Instance.new("Frame", Content)
            SliderFrame.Size = UDim2.new(1, 0, 0, 60)
            SliderFrame.BackgroundColor3 = Config.Theme.Secondary
            SliderFrame.BorderSizePixel = 0
            
            Instance.new("UICorner", SliderFrame).CornerRadius = UDim.new(0, 8)
            
            local SliderText = Instance.new("TextLabel", SliderFrame)
            SliderText.Size = UDim2.new(1, -20, 0, 25)
            SliderText.Position = UDim2.new(0, 15, 0, 5)
            SliderText.BackgroundTransparency = 1
            SliderText.Text = text
            SliderText.TextColor3 = Config.Theme.Text
            SliderText.TextSize = 14
            SliderText.Font = Enum.Font.Gotham
            SliderText.TextXAlignment = Enum.TextXAlignment.Left
            
            local ValueLabel = Instance.new("TextLabel", SliderFrame)
            ValueLabel.Size = UDim2.new(0, 40, 0, 25)
            ValueLabel.Position = UDim2.new(1, -55, 0, 5)
            ValueLabel.BackgroundTransparency = 1
            ValueLabel.Text = tostring(default)
            ValueLabel.TextColor3 = Config.Theme.Text
            ValueLabel.TextSize = 14
            ValueLabel.Font = Enum.Font.GothamBold
            
            local SliderBg = Instance.new("Frame", SliderFrame)
            SliderBg.Size = UDim2.new(1, -30, 0, 6)
            SliderBg.Position = UDim2.new(0, 15, 0, 40)
            SliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            SliderBg.BorderSizePixel = 0
            
            Instance.new("UICorner", SliderBg).CornerRadius = UDim.new(1, 0)
            
            local Fill = Instance.new("Frame", SliderBg)
            Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            Fill.BackgroundColor3 = Config.Theme.Text
            Fill.BorderSizePixel = 0
            
            Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)
            
            local Knob = Instance.new("Frame", SliderBg)
            Knob.Size = UDim2.new(0, 16, 0, 16)
            Knob.Position = UDim2.new((default - min) / (max - min), -8, 0, -5)
            Knob.BackgroundColor3 = Config.Theme.Text
            Knob.BorderSizePixel = 0
            
            Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)
            
            local Dragging = false
            
            local function Update(input)
                local sizeX = math.clamp((input.Position.X - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X, 0, 1)
                local value = math.floor(min + (max - min) * sizeX)
                
                Tween(Fill, {Size = UDim2.new(sizeX, 0, 1, 0)}, 0.1)
                Tween(Knob, {Position = UDim2.new(sizeX, -8, 0, -5)}, 0.1)
                ValueLabel.Text = tostring(value)
                
                if callback then
                    pcall(function() callback(value) end)
                end
            end
            
            SliderBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    Dragging = true
                    Update(input)
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    Update(input)
                end
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    Dragging = false
                end
            end)
        end,
        
        AddTextBox = function(self, text, placeholder, callback)
            local BoxFrame = Instance.new("Frame", Content)
            BoxFrame.Size = UDim2.new(1, 0, 0, 70)
            BoxFrame.BackgroundColor3 = Config.Theme.Secondary
            BoxFrame.BorderSizePixel = 0
            
            Instance.new("UICorner", BoxFrame).CornerRadius = UDim.new(0, 8)
            
            local Label = Instance.new("TextLabel", BoxFrame)
            Label.Size = UDim2.new(1, -20, 0, 25)
            Label.Position = UDim2.new(0, 15, 0, 5)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = Config.Theme.Text
            Label.TextSize = 14
            Label.Font = Enum.Font.Gotham
            Label.TextXAlignment = Enum.TextXAlignment.Left
            
            local TextBox = Instance.new("TextBox", BoxFrame)
            TextBox.Size = UDim2.new(1, -30, 0, 30)
            TextBox.Position = UDim2.new(0, 15, 0, 35)
            TextBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            TextBox.Text = ""
            TextBox.PlaceholderText = placeholder or "..."
            TextBox.TextColor3 = Config.Theme.Text
            TextBox.PlaceholderColor3 = Config.Theme.SubText
            TextBox.TextSize = 14
            TextBox.Font = Enum.Font.Gotham
            TextBox.ClearTextOnFocus = false
            
            Instance.new("UICorner", TextBox).CornerRadius = UDim.new(0, 6)
            
            TextBox.FocusLost:Connect(function(enterPressed)
                if callback and enterPressed then
                    pcall(function() callback(TextBox.Text) end)
                end
            end)
        end,
        
        AddDropdown = function(self, text, options, callback)
            local DropdownFrame = Instance.new("Frame", Content)
            DropdownFrame.Size = UDim2.new(1, 0, 0, 40)
            DropdownFrame.BackgroundColor3 = Config.Theme.Secondary
            DropdownFrame.BorderSizePixel = 0
            DropdownFrame.ClipsDescendants = true
            
            Instance.new("UICorner", DropdownFrame).CornerRadius = UDim.new(0, 8)
            
            local DropdownBtn = Instance.new("TextButton", DropdownFrame)
            DropdownBtn.Size = UDim2.new(1, 0, 0, 40)
            DropdownBtn.BackgroundTransparency = 1
            DropdownBtn.Text = ""
            
            local Label = Instance.new("TextLabel", DropdownBtn)
            Label.Size = UDim2.new(1, -50, 1, 0)
            Label.Position = UDim2.new(0, 15, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = Config.Theme.Text
            Label.TextSize = 14
            Label.Font = Enum.Font.Gotham
            Label.TextXAlignment = Enum.TextXAlignment.Left
            
            local Arrow = Instance.new("TextLabel", DropdownBtn)
            Arrow.Size = UDim2.new(0, 30, 0, 40)
            Arrow.Position = UDim2.new(1, -35, 0, 0)
            Arrow.BackgroundTransparency = 1
            Arrow.Text = "▼"
            Arrow.TextColor3 = Config.Theme.SubText
            Arrow.TextSize = 12
            Arrow.Font = Enum.Font.GothamBold
            
            local OptionsContainer = Instance.new("Frame", DropdownFrame)
            OptionsContainer.Size = UDim2.new(1, -20, 0, #options * 32)
            OptionsContainer.Position = UDim2.new(0, 10, 0, 45)
            OptionsContainer.BackgroundTransparency = 1
            
            local UIList = Instance.new("UIListLayout", OptionsContainer)
            UIList.Padding = UDim.new(0, 4)
            
            local Opened = false
            
            for i, option in pairs(options) do
                local OptionBtn = Instance.new("TextButton", OptionsContainer)
                OptionBtn.Size = UDim2.new(1, 0, 0, 32)
                OptionBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                OptionBtn.Text = option
                OptionBtn.TextColor3 = Config.Theme.Text
                OptionBtn.TextSize = 13
                OptionBtn.Font = Enum.Font.Gotham
                OptionBtn.AutoButtonColor = false
                
                Instance.new("UICorner", OptionBtn).CornerRadius = UDim.new(0, 6)
                
                OptionBtn.MouseEnter:Connect(function()
                    Tween(OptionBtn, {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}, 0.2)
                end)
                
                OptionBtn.MouseLeave:Connect(function()
                    Tween(OptionBtn, {BackgroundColor3 = Color3.fromRGB(35, 35, 35)}, 0.2)
                end)
                
                OptionBtn.MouseButton1Click:Connect(function()
                    Label.Text = text .. ": " .. option
                    if callback then callback(option) end
                    DropdownBtn:Fire()
                end)
            end
            
            DropdownBtn.MouseButton1Click:Connect(function()
                Opened = not Opened
                local targetSize = Opened and UDim2.new(1, 0, 0, 50 + #options * 32) or UDim2.new(1, 0, 0, 40)
                Tween(DropdownFrame, {Size = targetSize}, 0.3, Enum.EasingStyle.Quart)
                Tween(Arrow, {Rotation = Opened and 180 or 0}, 0.3)
            end)
        end
    }
    
    table.insert(Tabs, TabData)
    if #Tabs == 1 then Activate() end
    return TabData
end

-- Event Handlers
CloseBtn.MouseEnter:Connect(function() Tween(CloseBtn, {BackgroundColor3 = Color3.fromRGB(80, 80, 80)}, 0.2) end)
CloseBtn.MouseLeave:Connect(function() Tween(CloseBtn, {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}, 0.2) end)
CloseBtn.MouseButton1Click:Connect(function()
    Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
    wait(0.3)
    ScreenGui:Destroy()
    getgenv().StatusUI_Loaded = false
end)

MinimizeBtn.MouseEnter:Connect(function() Tween(MinimizeBtn, {BackgroundColor3 = Color3.fromRGB(80, 80, 80)}, 0.2) end)
MinimizeBtn.MouseLeave:Connect(function() Tween(MinimizeBtn, {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}, 0.2) end)
MinimizeBtn.MouseButton1Click:Connect(ToggleUI)

ToggleBtn.MouseButton1Click:Connect(ToggleUI)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
        ToggleUI()
    end
end)

-- Intro Animation
MainFrame.Visible = true
Tween(MainFrame, {Size = Config.Size}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- Return
local Status = { CreateTab = CreateTab, Toggle = ToggleUI }

-- Example (удали если не нужно)
local Main = CreateTab("Main")
Main:AddButton("Test Button", function() print("Clicked") end)
Main:AddToggle("Test Toggle", false, function(v) print(v) end)
Main:AddSlider("Test Slider", 0, 100, 50, function(v) print(v) end)
Main:AddDropdown("Test Dropdown", {"Option 1", "Option 2", "Option 3"}, function(v) print(v) end)

return Status
