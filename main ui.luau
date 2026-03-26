--// Status UI v1.0 | Premium Exploit Interface
--// One-File Edition | No Infinite Yield Issues

if getgenv().StatusUI_Loaded then return end
getgenv().StatusUI_Loaded = true

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

--// Config
local Config = {
    Title = "STATUS",
    SubTitle = "Premium | v1.0",
    ToggleKey = Enum.KeyCode.RightShift,
    Size = UDim2.new(0, 650, 0, 450),
    Position = UDim2.new(0.5, -325, 0.5, -225),
    Theme = {
        Background = Color3.fromRGB(10, 10, 15),
        Secondary = Color3.fromRGB(20, 20, 28),
        Accent = Color3.fromRGB(0, 255, 136), -- Мятный/зеленый акцент
        Accent2 = Color3.fromRGB(0, 200, 255), -- Голубой
        Text = Color3.fromRGB(255, 255, 255),
        SubText = Color3.fromRGB(150, 150, 170),
        Border = Color3.fromRGB(40, 40, 55),
        Glow = Color3.fromRGB(0, 255, 136),
        Success = Color3.fromRGB(0, 255, 136),
        Error = Color3.fromRGB(255, 50, 50),
        Warning = Color3.fromRGB(255, 200, 0)
    }
}

--// Utility Functions
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
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    
    topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
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
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function Ripple(button, x, y)
    spawn(function()
        local ripple = Instance.new("Frame")
        ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ripple.BackgroundTransparency = 0.7
        ripple.BorderSizePixel = 0
        ripple.Position = UDim2.new(0, x - 5, 0, y - 5)
        ripple.Size = UDim2.new(0, 10, 0, 10)
        ripple.Parent = button
        ripple.ZIndex = button.ZIndex + 1
        
        Instance.new("UICorner", ripple).CornerRadius = UDim.new(1, 0)
        
        Tween(ripple, {Size = UDim2.new(0, 200, 0, 200), Position = UDim2.new(0, x - 100, 0, y - 100), BackgroundTransparency = 1}, 0.8)
        wait(0.8)
        ripple:Destroy()
    end)
end

--// Create UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = HttpService:GenerateGUID(false)
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
    ScreenGui.Parent = CoreGui
end)

if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 0, 0, 0)
MainFrame.Position = Config.Position
MainFrame.BackgroundColor3 = Config.Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

-- Stroke
local Stroke = Instance.new("UIStroke", MainFrame)
Stroke.Color = Config.Theme.Border
Stroke.Thickness = 1.5

-- Glow Effect
local Glow = Instance.new("ImageLabel", MainFrame)
Glow.Name = "Glow"
Glow.Size = UDim2.new(1, 40, 1, 40)
Glow.Position = UDim2.new(0, -20, 0, -20)
Glow.BackgroundTransparency = 1
Glow.Image = "rbxassetid://5028857084"
Glow.ImageColor3 = Config.Theme.Glow
Glow.ImageTransparency = 0.8

-- Gradient Background
local Gradient = Instance.new("UIGradient", MainFrame)
Gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Config.Theme.Background),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 22))
})
Gradient.Rotation = 45

-- Top Accent Line
local TopLine = Instance.new("Frame", MainFrame)
TopLine.Size = UDim2.new(1, 0, 0, 2)
TopLine.BackgroundColor3 = Config.Theme.Accent
TopLine.BorderSizePixel = 0

local TopLineGradient = Instance.new("UIGradient", TopLine)
TopLineGradient.Color = ColorSequence.new(Config.Theme.Accent, Config.Theme.Accent2)

-- Title Bar
local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Size = UDim2.new(1, 0, 0, 50)
TitleBar.BackgroundColor3 = Config.Theme.Secondary
TitleBar.BackgroundTransparency = 0.5
TitleBar.BorderSizePixel = 0

Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 12)

local TitleText = Instance.new("TextLabel", TitleBar)
TitleText.Size = UDim2.new(0, 200, 1, 0)
TitleText.Position = UDim2.new(0, 20, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = Config.Title
TitleText.TextColor3 = Config.Theme.Text
TitleText.TextSize = 24
TitleText.Font = Enum.Font.GothamBold
TitleText.TextXAlignment = Enum.TextXAlignment.Left

local SubTitle = Instance.new("TextLabel", TitleBar)
SubTitle.Size = UDim2.new(0, 200, 0, 20)
SubTitle.Position = UDim2.new(0, 20, 0, 30)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = Config.SubTitle
SubTitle.TextColor3 = Config.Theme.SubText
SubTitle.TextSize = 12
SubTitle.Font = Enum.Font.Gotham

-- Control Buttons
local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -42, 0, 9)
CloseBtn.BackgroundColor3 = Config.Theme.Error
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 20
CloseBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

local MinimizeBtn = Instance.new("TextButton", TitleBar)
MinimizeBtn.Size = UDim2.new(0, 32, 0, 32)
MinimizeBtn.Position = UDim2.new(1, -80, 0, 9)
MinimizeBtn.BackgroundColor3 = Config.Theme.Warning
MinimizeBtn.Text = "−"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 20
MinimizeBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 8)

-- Sidebar
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 180, 1, -50)
Sidebar.Position = UDim2.new(0, 0, 0, 50)
Sidebar.BackgroundColor3 = Config.Theme.Secondary
Sidebar.BackgroundTransparency = 0.8
Sidebar.BorderSizePixel = 0

Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 0)

-- Tab Container
local TabContainer = Instance.new("Frame", MainFrame)
TabContainer.Size = UDim2.new(1, -180, 1, -50)
TabContainer.Position = UDim2.new(0, 180, 0, 50)
TabContainer.BackgroundTransparency = 1

-- Toggle Button (Floating)
local ToggleBtn = Instance.new("TextButton", ScreenGui)
ToggleBtn.Size = UDim2.new(0, 55, 0, 55)
ToggleBtn.Position = UDim2.new(0, 30, 0, 30)
ToggleBtn.BackgroundColor3 = Config.Theme.Accent
ToggleBtn.Text = "S"
ToggleBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
ToggleBtn.TextSize = 28
ToggleBtn.Font = Enum.Font.GothamBlack
ToggleBtn.Visible = false
ToggleBtn.Active = true
ToggleBtn.Draggable = true

Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)

local ToggleStroke = Instance.new("UIStroke", ToggleBtn)
ToggleStroke.Color = Config.Theme.Glow
ToggleStroke.Thickness = 3

local ToggleGlow = Instance.new("ImageLabel", ToggleBtn)
ToggleGlow.Size = UDim2.new(1.6, 0, 1.6, 0)
ToggleGlow.Position = UDim2.new(0, -15, 0, -15)
ToggleGlow.BackgroundTransparency = 1
ToggleGlow.Image = "rbxassetid://5028857084"
ToggleGlow.ImageColor3 = Config.Theme.Accent
ToggleGlow.ImageTransparency = 0.4

-- Notification Container
local NotifContainer = Instance.new("Frame", ScreenGui)
NotifContainer.Size = UDim2.new(0, 320, 1, -50)
NotifContainer.Position = UDim2.new(1, -340, 0, 25)
NotifContainer.BackgroundTransparency = 1
NotifContainer.ClipsDescendants = true

--// Variables
local Tabs = {}
local ActiveTab = nil
local Minimized = false

--// Functions
MakeDraggable(TitleBar, MainFrame)
MakeDraggable(ToggleBtn, ToggleBtn)

local function ToggleUI()
    Minimized = not Minimized
    if Minimized then
        ToggleBtn.Visible = true
        Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        Tween(Glow, {ImageTransparency = 1}, 0.4)
        wait(0.4)
        MainFrame.Visible = false
    else
        MainFrame.Visible = true
        Tween(MainFrame, {Size = Config.Size}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        Tween(Glow, {ImageTransparency = 0.8}, 0.4)
        wait(0.4)
        ToggleBtn.Visible = false
    end
end

local function Notify(text, type, duration)
    type = type or "Info"
    duration = duration or 3
    
    local color = type == "Success" and Config.Theme.Success or type == "Error" and Config.Theme.Error or Config.Theme.Accent
    
    local Notif = Instance.new("Frame", NotifContainer)
    Notif.Size = UDim2.new(1, 0, 0, 75)
    Notif.Position = UDim2.new(0, 0, 0, -100)
    Notif.BackgroundColor3 = Config.Theme.Secondary
    Notif.BorderSizePixel = 0
    
    Instance.new("UICorner", Notif).CornerRadius = UDim.new(0, 10)
    
    local NotifStroke = Instance.new("UIStroke", Notif)
    NotifStroke.Color = color
    NotifStroke.Thickness = 1.5
    
    local Icon = Instance.new("TextLabel", Notif)
    Icon.Size = UDim2.new(0, 40, 0, 40)
    Icon.Position = UDim2.new(0, 15, 0, 17)
    Icon.BackgroundTransparency = 1
    Icon.Text = type == "Success" and "✓" or type == "Error" and "✕" or "ℹ"
    Icon.TextColor3 = color
    Icon.TextSize = 26
    Icon.Font = Enum.Font.GothamBold
    
    local NotifText = Instance.new("TextLabel", Notif)
    NotifText.Size = UDim2.new(1, -70, 0, 40)
    NotifText.Position = UDim2.new(0, 60, 0, 17)
    NotifText.BackgroundTransparency = 1
    NotifText.Text = text
    NotifText.TextColor3 = Config.Theme.Text
    NotifText.TextSize = 15
    NotifText.Font = Enum.Font.Gotham
    NotifText.TextWrapped = true
    NotifText.TextXAlignment = Enum.TextXAlignment.Left
    
    Tween(Notif, {Position = UDim2.new(0, 0, 0, 10)}, 0.5, Enum.EasingStyle.Back)
    
    spawn(function()
        wait(duration)
        Tween(Notif, {Position = UDim2.new(1, 0, 0, 10)}, 0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        wait(0.5)
        Notif:Destroy()
    end)
end

--// Tab System
local function CreateTab(name, icon)
    icon = icon or "◆"
    
    local TabBtn = Instance.new("TextButton", Sidebar)
    TabBtn.Size = UDim2.new(1, -20, 0, 45)
    TabBtn.Position = UDim2.new(0, 10, 0, 15 + (#Tabs * 55))
    TabBtn.BackgroundColor3 = Config.Theme.Secondary
    TabBtn.Text = ""
    TabBtn.AutoButtonColor = false
    
    Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 10)
    
    local Indicator = Instance.new("Frame", TabBtn)
    Indicator.Size = UDim2.new(0, 4, 0, 24)
    Indicator.Position = UDim2.new(0, -2, 0.5, -12)
    Indicator.BackgroundColor3 = Config.Theme.Accent
    Indicator.Visible = false
    Instance.new("UICorner", Indicator).CornerRadius = UDim.new(0, 2)
    
    local TabIcon = Instance.new("TextLabel", TabBtn)
    TabIcon.Size = UDim2.new(0, 35, 1, 0)
    TabIcon.Position = UDim2.new(0, 12, 0, 0)
    TabIcon.BackgroundTransparency = 1
    TabIcon.Text = icon
    TabIcon.TextColor3 = Config.Theme.SubText
    TabIcon.TextSize = 18
    TabIcon.Font = Enum.Font.GothamBold
    
    local TabText = Instance.new("TextLabel", TabBtn)
    TabText.Size = UDim2.new(1, -60, 1, 0)
    TabText.Position = UDim2.new(0, 45, 0, 0)
    TabText.BackgroundTransparency = 1
    TabText.Text = name
    TabText.TextColor3 = Config.Theme.SubText
    TabText.TextSize = 15
    TabText.Font = Enum.Font.GothamSemibold
    TabText.TextXAlignment = Enum.TextXAlignment.Left
    
    local Content = Instance.new("ScrollingFrame", TabContainer)
    Content.Name = name .. "Content"
    Content.Size = UDim2.new(1, -20, 1, -20)
    Content.Position = UDim2.new(0, 10, 0, 10)
    Content.BackgroundTransparency = 1
    Content.BorderSizePixel = 0
    Content.ScrollBarThickness = 4
    Content.ScrollBarImageColor3 = Config.Theme.Accent
    Content.Visible = false
    Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Content.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    local UIList = Instance.new("UIListLayout", Content)
    UIList.Padding = UDim.new(0, 12)
    UIList.SortOrder = Enum.SortOrder.LayoutOrder
    
    local function Activate()
        if ActiveTab == Content then return end
        
        if ActiveTab then
            ActiveTab.Visible = false
        end
        
        for _, tab in pairs(Tabs) do
            tab.Indicator.Visible = false
            Tween(tab.Button, {BackgroundColor3 = Config.Theme.Secondary}, 0.2)
            Tween(tab.Text, {TextColor3 = Config.Theme.SubText}, 0.2)
            Tween(tab.Icon, {TextColor3 = Config.Theme.SubText}, 0.2)
        end
        
        ActiveTab = Content
        Content.Visible = true
        Indicator.Visible = true
        
        Tween(TabBtn, {BackgroundColor3 = Config.Theme.Accent}, 0.3)
        Tween(TabText, {TextColor3 = Color3.fromRGB(0, 0, 0)}, 0.2)
        Tween(TabIcon, {TextColor3 = Color3.fromRGB(0, 0, 0)}, 0.2)
        
        Content.Position = UDim2.new(0.02, 10, 0, 10)
        Tween(Content, {Position = UDim2.new(0, 10, 0, 10)}, 0.4, Enum.EasingStyle.Quart)
    end
    
    TabBtn.MouseButton1Click:Connect(Activate)
    
    TabBtn.MouseEnter:Connect(function()
        if ActiveTab ~= Content then
            Tween(TabBtn, {BackgroundColor3 = Color3.fromRGB(35, 35, 50)}, 0.2)
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
        Icon = TabIcon,
        
        AddButton = function(self, text, callback)
            local Btn = Instance.new("TextButton", Content)
            Btn.Size = UDim2.new(1, 0, 0, 45)
            Btn.BackgroundColor3 = Config.Theme.Secondary
            Btn.Text = ""
            Btn.AutoButtonColor = false
            
            Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 10)
            
            local BtnStroke = Instance.new("UIStroke", Btn)
            BtnStroke.Color = Config.Theme.Border
            BtnStroke.Thickness = 1
            
            local Label = Instance.new("TextLabel", Btn)
            Label.Size = UDim2.new(1, -50, 1, 0)
            Label.Position = UDim2.new(0, 15, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = Config.Theme.Text
            Label.TextSize = 15
            Label.Font = Enum.Font.GothamSemibold
            Label.TextXAlignment = Enum.TextXAlignment.Left
            
            local Arrow = Instance.new("TextLabel", Btn)
            Arrow.Size = UDim2.new(0, 30, 1, 0)
            Arrow.Position = UDim2.new(1, -35, 0, 0)
            Arrow.BackgroundTransparency = 1
            Arrow.Text = "→"
            Arrow.TextColor3 = Config.Theme.Accent
            Arrow.TextSize = 20
            Arrow.Font = Enum.Font.GothamBold
            
            Btn.MouseEnter:Connect(function()
                Tween(Btn, {BackgroundColor3 = Color3.fromRGB(40, 40, 60)}, 0.2)
                Tween(Arrow, {Position = UDim2.new(1, -30, 0, 0)}, 0.2)
                BtnStroke.Color = Config.Theme.Accent
            end)
            
            Btn.MouseLeave:Connect(function()
                Tween(Btn, {BackgroundColor3 = Config.Theme.Secondary}, 0.2)
                Tween(Arrow, {Position = UDim2.new(1, -35, 0, 0)}, 0.2)
                BtnStroke.Color = Config.Theme.Border
            end)
            
            Btn.MouseButton1Click:Connect(function()
                local absPos = Btn.AbsolutePosition
                local mousePos = UserInputService:GetMouseLocation()
                Ripple(Btn, mousePos.X - absPos.X, mousePos.Y - absPos.Y)
                if callback then 
                    local success, err = pcall(callback)
                    if not success then
                        Notify("Error: " .. tostring(err), "Error")
                    else
                        Notify(text .. " executed!", "Success")
                    end
                end
            end)
        end,
        
        AddToggle = function(self, text, default, callback)
            local ToggleFrame = Instance.new("Frame", Content)
            ToggleFrame.Size = UDim2.new(1, 0, 0, 55)
            ToggleFrame.BackgroundColor3 = Config.Theme.Secondary
            ToggleFrame.BorderSizePixel = 0
            
            Instance.new("UICorner", ToggleFrame).CornerRadius = UDim.new(0, 10)
            
            local ToggleText = Instance.new("TextLabel", ToggleFrame)
            ToggleText.Size = UDim2.new(1, -80, 1, 0)
            ToggleText.Position = UDim2.new(0, 15, 0, 0)
            ToggleText.BackgroundTransparency = 1
            ToggleText.Text = text
            ToggleText.TextColor3 = Config.Theme.Text
            ToggleText.TextSize = 15
            ToggleText.Font = Enum.Font.GothamSemibold
            ToggleText.TextXAlignment = Enum.TextXAlignment.Left
            
            local Switch = Instance.new("TextButton", ToggleFrame)
            Switch.Size = UDim2.new(0, 52, 0, 28)
            Switch.Position = UDim2.new(1, -65, 0.5, -14)
            Switch.BackgroundColor3 = default and Config.Theme.Accent or Color3.fromRGB(50, 50, 65)
            Switch.Text = ""
            Switch.AutoButtonColor = false
            
            Instance.new("UICorner", Switch).CornerRadius = UDim.new(1, 0)
            
            local Circle = Instance.new("Frame", Switch)
            Circle.Size = UDim2.new(0, 22, 0, 22)
            Circle.Position = default and UDim2.new(1, -25, 0, 3) or UDim2.new(0, 3, 0, 3)
            Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Circle.BorderSizePixel = 0
            
            Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)
            
            local Value = default
            
            Switch.MouseButton1Click:Connect(function()
                Value = not Value
                local targetPos = Value and UDim2.new(1, -25, 0, 3) or UDim2.new(0, 3, 0, 3)
                local targetColor = Value and Config.Theme.Accent or Color3.fromRGB(50, 50, 65)
                
                Tween(Circle, {Position = targetPos}, 0.3, Enum.EasingStyle.Quart)
                Tween(Switch, {BackgroundColor3 = targetColor}, 0.3)
                
                if callback then
                    local success, err = pcall(function() callback(Value) end)
                    if not success then
                        Notify("Toggle Error: " .. tostring(err), "Error")
                    end
                end
            end)
        end,
        
        AddSlider = function(self, text, min, max, default, callback)
            local SliderFrame = Instance.new("Frame", Content)
            SliderFrame.Size = UDim2.new(1, 0, 0, 70)
            SliderFrame.BackgroundColor3 = Config.Theme.Secondary
            SliderFrame.BorderSizePixel = 0
            
            Instance.new("UICorner", SliderFrame).CornerRadius = UDim.new(0, 10)
            
            local SliderText = Instance.new("TextLabel", SliderFrame)
            SliderText.Size = UDim2.new(1, -20, 0, 30)
            SliderText.Position = UDim2.new(0, 15, 0, 5)
            SliderText.BackgroundTransparency = 1
            SliderText.Text = text
            SliderText.TextColor3 = Config.Theme.Text
            SliderText.TextSize = 15
            SliderText.Font = Enum.Font.GothamSemibold
            SliderText.TextXAlignment = Enum.TextXAlignment.Left
            
            local ValueLabel = Instance.new("TextLabel", SliderFrame)
            ValueLabel.Size = UDim2.new(0, 50, 0, 30)
            ValueLabel.Position = UDim2.new(1, -65, 0, 5)
            ValueLabel.BackgroundTransparency = 1
            ValueLabel.Text = tostring(default)
            ValueLabel.TextColor3 = Config.Theme.Accent
            ValueLabel.TextSize = 15
            ValueLabel.Font = Enum.Font.GothamBold
            
            local SliderBg = Instance.new("Frame", SliderFrame)
            SliderBg.Size = UDim2.new(1, -30, 0, 8)
            SliderBg.Position = UDim2.new(0, 15, 0, 45)
            SliderBg.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
            SliderBg.BorderSizePixel = 0
            
            Instance.new("UICorner", SliderBg).CornerRadius = UDim.new(1, 0)
            
            local Fill = Instance.new("Frame", SliderBg)
            Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            Fill.BackgroundColor3 = Config.Theme.Accent
            Fill.BorderSizePixel = 0
            
            Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)
            
            local Knob = Instance.new("Frame", SliderBg)
            Knob.Size = UDim2.new(0, 18, 0, 18)
            Knob.Position = UDim2.new((default - min) / (max - min), -9, 0, -5)
            Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Knob.BorderSizePixel = 0
            
            Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)
            
            local Dragging = false
            
            local function Update(input)
                local sizeX = math.clamp((input.Position.X - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X, 0, 1)
                local value = math.floor(min + (max - min) * sizeX)
                
                Tween(Fill, {Size = UDim2.new(sizeX, 0, 1, 0)}, 0.1)
                Tween(Knob, {Position = UDim2.new(sizeX, -9, 0, -5)}, 0.1)
                ValueLabel.Text = tostring(value)
                
                if callback then
                    local success, err = pcall(function() callback(value) end)
                    if not success then
                        Notify("Slider Error: " .. tostring(err), "Error")
                    end
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
        
        AddDropdown = function(self, text, options, callback)
            local DropdownFrame = Instance.new("Frame", Content)
            DropdownFrame.Size = UDim2.new(1, 0, 0, 50)
            DropdownFrame.BackgroundColor3 = Config.Theme.Secondary
            DropdownFrame.BorderSizePixel = 0
            DropdownFrame.ClipsDescendants = true
            
            Instance.new("UICorner", DropdownFrame).CornerRadius = UDim.new(0, 10)
            
            local DropdownBtn = Instance.new("TextButton", DropdownFrame)
            DropdownBtn.Size = UDim2.new(1, 0, 0, 50)
            DropdownBtn.BackgroundTransparency = 1
            DropdownBtn.Text = ""
            
            local Label = Instance.new("TextLabel", DropdownBtn)
            Label.Size = UDim2.new(1, -50, 1, 0)
            Label.Position = UDim2.new(0, 15, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = Config.Theme.Text
            Label.TextSize = 15
            Label.Font = Enum.Font.GothamSemibold
            Label.TextXAlignment = Enum.TextXAlignment.Left
            
            local Arrow = Instance.new("TextLabel", DropdownBtn)
            Arrow.Size = UDim2.new(0, 30, 0, 50)
            Arrow.Position = UDim2.new(1, -35, 0, 0)
            Arrow.BackgroundTransparency = 1
            Arrow.Text = "▼"
            Arrow.TextColor3 = Config.Theme.Accent
            Arrow.TextSize = 14
            Arrow.Font = Enum.Font.GothamBold
            
            local OptionsContainer = Instance.new("Frame", DropdownFrame)
            OptionsContainer.Size = UDim2.new(1, -20, 0, #options * 35)
            OptionsContainer.Position = UDim2.new(0, 10, 0, 55)
            OptionsContainer.BackgroundTransparency = 1
            
            local UIList = Instance.new("UIListLayout", OptionsContainer)
            UIList.Padding = UDim.new(0, 5)
            
            local Opened = false
            
            for i, option in pairs(options) do
                local OptionBtn = Instance.new("TextButton", OptionsContainer)
                OptionBtn.Size = UDim2.new(1, 0, 0, 35)
                OptionBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
                OptionBtn.Text = option
                OptionBtn.TextColor3 = Config.Theme.Text
                OptionBtn.TextSize = 14
                OptionBtn.Font = Enum.Font.Gotham
                
                Instance.new("UICorner", OptionBtn).CornerRadius = UDim.new(0, 6)
                
                OptionBtn.MouseEnter:Connect(function()
                    Tween(OptionBtn, {BackgroundColor3 = Config.Theme.Accent}, 0.2)
                    OptionBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
                end)
                
                OptionBtn.MouseLeave:Connect(function()
                    Tween(OptionBtn, {BackgroundColor3 = Color3.fromRGB(30, 30, 42)}, 0.2)
                    OptionBtn.TextColor3 = Config.Theme.Text
                end)
                
                OptionBtn.MouseButton1Click:Connect(function()
                    Label.Text = text .. ": " .. option
                    if callback then callback(option) end
                    DropdownBtn:Fire()
                end)
            end
            
            DropdownBtn.MouseButton1Click:Connect(function()
                Opened = not Opened
                local targetSize = Opened and UDim2.new(1, 0, 0, 60 + #options * 35) or UDim2.new(1, 0, 0, 50)
                Tween(DropdownFrame, {Size = targetSize}, 0.3, Enum.EasingStyle.Quart)
                Tween(Arrow, {Rotation = Opened and 180 or 0}, 0.3)
            end)
        end,
        
        AddTextBox = function(self, text, placeholder, callback)
            local BoxFrame = Instance.new("Frame", Content)
            BoxFrame.Size = UDim2.new(1, 0, 0, 80)
            BoxFrame.BackgroundColor3 = Config.Theme.Secondary
            BoxFrame.BorderSizePixel = 0
            
            Instance.new("UICorner", BoxFrame).CornerRadius = UDim.new(0, 10)
            
            local Label = Instance.new("TextLabel", BoxFrame)
            Label.Size = UDim2.new(1, -20, 0, 30)
            Label.Position = UDim2.new(0, 15, 0, 5)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = Config.Theme.Text
            Label.TextSize = 15
            Label.Font = Enum.Font.GothamSemibold
            Label.TextXAlignment = Enum.TextXAlignment.Left
            
            local TextBox = Instance.new("TextBox", BoxFrame)
            TextBox.Size = UDim2.new(1, -30, 0, 35)
            TextBox.Position = UDim2.new(0, 15, 0, 40)
            TextBox.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
            TextBox.Text = ""
            TextBox.PlaceholderText = placeholder or "Enter text..."
            TextBox.TextColor3 = Config.Theme.Text
            TextBox.PlaceholderColor3 = Config.Theme.SubText
            TextBox.TextSize = 14
            TextBox.Font = Enum.Font.Gotham
            TextBox.ClearTextOnFocus = false
            
            Instance.new("UICorner", TextBox).CornerRadius = UDim.new(0, 8)
            
            TextBox.FocusLost:Connect(function(enterPressed)
                if callback and enterPressed then
                    callback(TextBox.Text)
                end
            end)
        end
    }
    
    table.insert(Tabs, TabData)
    
    if #Tabs == 1 then
        Activate()
    end
    
    return TabData
end

--// Event Handlers
CloseBtn.MouseEnter:Connect(function()
    Tween(CloseBtn, {BackgroundColor3 = Color3.fromRGB(220, 38, 38)}, 0.2)
end)

CloseBtn.MouseLeave:Connect(function()
    Tween(CloseBtn, {BackgroundColor3 = Config.Theme.Error}, 0.2)
end)

CloseBtn.MouseButton1Click:Connect(function()
    Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    wait(0.3)
    ScreenGui:Destroy()
    getgenv().StatusUI_Loaded = false
end)

MinimizeBtn.MouseEnter:Connect(function()
    Tween(MinimizeBtn, {BackgroundColor3 = Color3.fromRGB(220, 180, 0)}, 0.2)
end)

MinimizeBtn.MouseLeave:Connect(function()
    Tween(MinimizeBtn, {BackgroundColor3 = Config.Theme.Warning}, 0.2)
end)

MinimizeBtn.MouseButton1Click:Connect(ToggleUI)

ToggleBtn.MouseButton1Click:Connect(ToggleUI)

ToggleBtn.MouseEnter:Connect(function()
    Tween(ToggleBtn, {Size = UDim2.new(0, 60, 0, 60)}, 0.2)
    ToggleGlow.ImageTransparency = 0.2
end)

ToggleBtn.MouseLeave:Connect(function()
    Tween(ToggleBtn, {Size = UDim2.new(0, 55, 0, 55)}, 0.2)
    ToggleGlow.ImageTransparency = 0.4
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Config.ToggleKey then
        ToggleUI()
    end
end)

--// Intro Animation
MainFrame.Visible = true
Tween(MainFrame, {Size = Config.Size}, 0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

--// Return API
local Status = {
    CreateTab = CreateTab,
    Notify = Notify,
    Toggle = ToggleUI
}

--// Example Usage (можешь удалить это и использовать свой код)
local Main = CreateTab("Main", "⚡")
local Player = CreateTab("Player", "👤")
local Visuals = CreateTab("Visuals", "👁️")
local Misc = CreateTab("Misc", "⚙️")

Main:AddButton("Infinite Jump", function()
    local infiniteJump = false
    game:GetService("UserInputService").JumpRequest:Connect(function()
        if infiniteJump then
            game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
        end
    end)
    infiniteJump = true
end)

Main:AddToggle("Speed Hack", false, function(value)
    if value then
        LocalPlayer.Character.Humanoid.WalkSpeed = 100
    else
        LocalPlayer.Character.Humanoid.WalkSpeed = 16
    end
end)

Main:AddSlider("WalkSpeed", 16, 500, 16, function(value)
    LocalPlayer.Character.Humanoid.WalkSpeed = value
end)

Main:AddDropdown("Teleport", {"Spawn", "Shop", "Boss"}, function(location)
    print("Teleporting to:", location)
end)

Player:AddButton("God Mode", function()
    print("God mode activated")
end)

Player:AddTextBox("Username", "Enter username...", function(text)
    print("Selected user:", text)
end)

Notify("Status UI Loaded!", "Success", 3)

return Status
