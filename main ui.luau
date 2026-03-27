--// Herkle Hub Mobile | Phone Optimized Edition
--// Адаптивный UI: автоопределение мобильного устройства

if getgenv().HerkleHub_Loaded then return end
getgenv().HerkleHub_Loaded = true

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local packets = require(ReplicatedStorage.Modules.Packets)

--// Определение устройства
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local IsTablet = IsMobile and (workspace.CurrentCamera.ViewportSize.X >= 800)

--// Адаптивный Config
local Config = {
    Title = "STATUS",
    -- На телефоне почти fullscreen, на ПК стандартный размер
    Size = IsMobile and UDim2.new(0.95, 0, 0.9, 0) or UDim2.new(0, 600, 0, 400),
    Position = IsMobile and UDim2.new(0.025, 0, 0.05, 0) or UDim2.new(0.5, -300, 0.5, -200),
    -- Safe Area для современных телефонов (челки, вырезы)
    SafeAreaPadding = IsMobile and 20 or 0,
    Theme = {
        Background = Color3.fromRGB(10, 10, 10),
        Secondary = Color3.fromRGB(20, 20, 20),
        Accent = Color3.fromRGB(255, 255, 255),
        Text = Color3.fromRGB(255, 255, 255),
        SubText = Color3.fromRGB(120, 120, 120),
        Border = Color3.fromRGB(40, 40, 40)
    },
    -- Адаптивные размеры
    TabWidth = IsMobile and (IsTablet and 140 or 100) or 160,
    ButtonHeight = IsMobile and 50 or 40,
    SidebarWidth = IsMobile and (IsTablet and 150 or 110) or 160,
    FontSize = IsMobile and 16 or 14,
    TitleSize = IsMobile and 20 or 18
}

--// States
local States = {
    Walkspeed = false, WalkspeedValue = 16,
    JumpPower = false, JumpPowerValue = 50,
    HipHeight = false, HipHeightValue = 2,
    NoMountainSlip = false,
    KillAura = false, KillAuraRange = 5, KillAuraTargets = 1, KillAuraCooldown = 0.1,
    ResourceAura = false, ResourceAuraRange = 20, ResourceAuraTargets = 1, ResourceAuraCooldown = 0.1,
    CritterAura = false, CritterAuraRange = 20, CritterAuraTargets = 1, CritterAuraCooldown = 0.1,
    AutoPickup = false, ChestPickup = false, PickupRange = 20,
    SelectedItems = {"Leaves", "Log"},
    AutoDrop = false, DropItem = "Bloodfruit",
    AutoDropCustom = false, DropItemCustom = "Bloodfruit",
    SelectedFruit = "Bloodfruit",
    AutoPlant = false, PlantRange = 30, PlantDelay = 0.1,
    AutoHarvest = false, HarvestRange = 30,
    TweenToPlantBox = false, TweenToBush = false, TweenRange = 250,
    ItemOrbit = false, OrbitRange = 20, OrbitRadius = 10, OrbitSpeed = 5, ItemHeight = 3
}

--// Helpers
local function Tween(obj, props, duration, style, dir)
    style = style or Enum.EasingStyle.Quart
    dir = dir or Enum.EasingDirection.Out
    local info = TweenInfo.new(duration or 0.3, style, dir)
    local tween = TweenService:Create(obj, info, props)
    tween:Play()
    return tween
end

local function Ripple(button, x, y)
    spawn(function()
        local ripple = Instance.new("Frame")
        ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ripple.BackgroundTransparency = 0.7
        ripple.BorderSizePixel = 0
        ripple.Position = UDim2.new(0, x - 10, 0, y - 10)
        ripple.Size = UDim2.new(0, 20, 0, 20)
        ripple.Parent = button
        ripple.ZIndex = button.ZIndex + 10
        
        local corner = Instance.new("UICorner", ripple)
        corner.CornerRadius = UDim.new(1, 0)
        
        Tween(ripple, {
            Size = UDim2.new(0, 300, 0, 300), 
            Position = UDim2.new(0, x - 150, 0, y - 150), 
            BackgroundTransparency = 1
        }, 0.6)
        
        wait(0.6)
        ripple:Destroy()
    end)
end

--// Улучшенный Drag (Mouse + Touch)
local function MakeDraggable(topbar, frame)
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X, 
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
    end
    
    -- Mouse
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    
    topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            if dragging then update(input) end
        end
    end)
    
    -- Touch (для телефонов)
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    
    topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            if dragging then update(input) end
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

--// UI Creation
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = HttpService:GenerateGUID(false)
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
-- Safe Area для iPhone X+ и Android с челками
ScreenGui.ScreenInsets = Enum.ScreenInsets.None

pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 0, 0, 0)
MainFrame.Position = Config.Position
MainFrame.BackgroundColor3 = Config.Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

-- Safe Area отступы для современных телефонов
if IsMobile then
    local SafeAreaPadding = Instance.new("UIPadding", MainFrame)
    SafeAreaPadding.PaddingTop = UDim.new(0, GuiService:GetGuiInset().Y + 10)
    SafeAreaPadding.PaddingBottom = UDim.new(0, 10)
    SafeAreaPadding.PaddingLeft = UDim.new(0, 10)
    SafeAreaPadding.PaddingRight = UDim.new(0, 10)
end

Instance.new("UICorner", MainFrame).CornerRadius = IsMobile and UDim.new(0, 15) or UDim.new(0, 10)

local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Size = UDim2.new(1, 0, 0, IsMobile and 60 or 45)
TitleBar.BackgroundColor3 = Config.Theme.Secondary
TitleBar.BorderSizePixel = 0

local TitleText = Instance.new("TextLabel", TitleBar)
TitleText.Size = UDim2.new(1, -150, 1, 0)
TitleText.Position = UDim2.new(0, 20, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = Config.Title
TitleText.TextColor3 = Config.Theme.Text
TitleText.TextSize = Config.TitleSize
TitleText.Font = Enum.Font.GothamBold
TitleText.TextXAlignment = Enum.TextXAlignment.Left

-- Кнопки управления окном (больше для пальцев на мобильных)
local BtnSize = IsMobile and UDim2.new(0, 44, 0, 44) or UDim2.new(0, 30, 0, 30)
local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size = BtnSize
CloseBtn.Position = UDim2.new(1, IsMobile and -54 or -40, 0, IsMobile and 8 or 7)
CloseBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60) -- Красный для visibility
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Config.Theme.Text
CloseBtn.TextSize = IsMobile and 24 or 18
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.AutoButtonColor = false
CloseBtn.ClipsDescendants = true
Instance.new("UICorner", CloseBtn).CornerRadius = IsMobile and UDim.new(0, 12) or UDim.new(0, 8)

local MinimizeBtn = Instance.new("TextButton", TitleBar)
MinimizeBtn.Size = BtnSize
MinimizeBtn.Position = UDim2.new(1, IsMobile and -104 or -75, 0, IsMobile and 8 or 7)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
MinimizeBtn.Text = "−"
MinimizeBtn.TextColor3 = Config.Theme.Text
MinimizeBtn.TextSize = IsMobile and 24 or 18
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.AutoButtonColor = false
MinimizeBtn.ClipsDescendants = true
Instance.new("UICorner", MinimizeBtn).CornerRadius = IsMobile and UDim.new(0, 12) or UDim.new(0, 8)

-- Sidebar (адаптивная ширина)
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, Config.SidebarWidth, 1, IsMobile and -60 or -45)
Sidebar.Position = UDim2.new(0, 0, 0, IsMobile and 60 or 45)
Sidebar.BackgroundColor3 = Config.Theme.Secondary
Sidebar.BackgroundTransparency = 0.5
Sidebar.BorderSizePixel = 0

local TabContainer = Instance.new("Frame", MainFrame)
TabContainer.Size = UDim2.new(1, -Config.SidebarWidth, 1, IsMobile and -60 or -45)
TabContainer.Position = UDim2.new(0, Config.SidebarWidth, 0, IsMobile and 60 or 45)
TabContainer.BackgroundTransparency = 1

-- Кнопка переключения (большая для пальца)
local ToggleBtn = Instance.new("TextButton", ScreenGui)
ToggleBtn.Size = UDim2.new(0, 70, 0, 70)
ToggleBtn.Position = UDim2.new(0, 20, 0.8, -35)
ToggleBtn.BackgroundColor3 = Config.Theme.Secondary
ToggleBtn.Text = "H"
ToggleBtn.TextColor3 = Config.Theme.Text
ToggleBtn.TextSize = 30
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Visible = false
ToggleBtn.Active = true
ToggleBtn.Draggable = true
ToggleBtn.ClipsDescendants = true
ToggleBtn.BorderSizePixel = 0
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)

-- Тень для кнопки
local ToggleShadow = Instance.new("ImageLabel", ToggleBtn)
ToggleShadow.BackgroundTransparency = 1
ToggleShadow.Position = UDim2.new(0, -10, 0, -10)
ToggleShadow.Size = UDim2.new(1, 20, 1, 20)
ToggleShadow.Image = "rbxassetid://5554236805"
ToggleShadow.ImageColor3 = Color3.new(0, 0, 0)
ToggleShadow.ImageTransparency = 0.6

MakeDraggable(TitleBar, MainFrame)
MakeDraggable(ToggleBtn, ToggleBtn)

local Tabs = {}
local ActiveTab = nil
local Minimized = false

local function ToggleUI()
    Minimized = not Minimized
    if Minimized then
        ToggleBtn.Visible = true
        Tween(ToggleBtn, {Position = UDim2.new(0, 20, 0.8, -35)}, 0.3)
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

--// Создание вкладки (оптимизировано под тач)
local function CreateTab(name, icon)
    local TabBtn = Instance.new("TextButton", Sidebar)
    -- Большие кнопки для пальцев на мобильных
    local tabHeight = IsMobile and 60 or 40
    local spacing = IsMobile and 70 or 50
    TabBtn.Size = UDim2.new(1, IsMobile and -10 or -20, 0, tabHeight)
    TabBtn.Position = UDim2.new(0, IsMobile and 5 or 10, 0, 10 + (#Tabs * spacing))
    TabBtn.BackgroundColor3 = Config.Theme.Secondary
    TabBtn.Text = ""
    TabBtn.AutoButtonColor = false
    TabBtn.ClipsDescendants = true
    
    Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, IsMobile and 12 or 8)
    
    -- Индикатор активной вкладки (шире на мобильных)
    local Indicator = Instance.new("Frame", TabBtn)
    Indicator.Size = UDim2.new(0, IsMobile and 4 or 3, 0, IsMobile and 30 or 20)
    Indicator.Position = UDim2.new(0, 0, 0.5, IsMobile and -15 or -10)
    Indicator.BackgroundColor3 = Config.Theme.Accent
    Indicator.Visible = false
    Indicator.BorderSizePixel = 0
    Instance.new("UICorner", Indicator).CornerRadius = UDim.new(0, 2)
    
    local TabText = Instance.new("TextLabel", TabBtn)
    TabText.Size = UDim2.new(1, IsMobile and -10 or -20, 1, 0)
    TabText.Position = UDim2.new(0, IsMobile and 10 or 15, 0, 0)
    TabText.BackgroundTransparency = 1
    TabText.Text = name
    TabText.TextColor3 = Config.Theme.SubText
    TabText.TextSize = IsMobile and 18 or 14
    TabText.Font = Enum.Font.GothamSemibold
    TabText.TextXAlignment = Enum.TextXAlignment.Left
    
    local Content = Instance.new("ScrollingFrame", TabContainer)
    Content.Size = UDim2.new(1, IsMobile and -10 or -20, 1, IsMobile and -10 or -20)
    Content.Position = UDim2.new(0, IsMobile and 5 or 10, 0, IsMobile and 5 or 10)
    Content.BackgroundTransparency = 1
    Content.ScrollBarThickness = IsMobile and 6 or 3 -- Толще скролл на телефоне
    Content.ScrollBarImageColor3 = Config.Theme.Accent
    Content.Visible = false
    Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Content.ScrollingDirection = Enum.ScrollingDirection.Y
    
    local UIList = Instance.new("UIListLayout", Content)
    UIList.Padding = UDim.new(0, IsMobile and 15 or 10)
    UIList.SortOrder = Enum.SortOrder.LayoutOrder
    
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
    
    -- Touch и Mouse поддержка
    TabBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            local pos = input.Position
            local btnPos = TabBtn.AbsolutePosition
            Ripple(TabBtn, pos.X - btnPos.X, pos.Y - btnPos.Y)
            Activate()
        end
    end)
    
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
        
        -- Кнопка (большая для пальца)
        AddButton = function(self, text, callback)
            local Btn = Instance.new("TextButton", Content)
            Btn.Size = UDim2.new(1, 0, 0, Config.ButtonHeight)
            Btn.BackgroundColor3 = Config.Theme.Secondary
            Btn.Text = text
            Btn.TextColor3 = Config.Theme.Text
            Btn.TextSize = Config.FontSize
            Btn.Font = Enum.Font.GothamBold -- Жирнее для читаемости
            Btn.AutoButtonColor = false
            Btn.ClipsDescendants = true
            Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, IsMobile and 12 or 8)
            
            -- Touch target больше невидимой зоной
            local TouchZone = Instance.new("Frame", Btn)
            TouchZone.Size = UDim2.new(1, 20, 1, 20)
            TouchZone.Position = UDim2.new(0, -10, 0, -10)
            TouchZone.BackgroundTransparency = 1
            TouchZone.ZIndex = 0
            
            Btn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or 
                   input.UserInputType == Enum.UserInputType.Touch then
                    local pos = input.Position
                    local btnPos = Btn.AbsolutePosition
                    Ripple(Btn, pos.X - btnPos.X, pos.Y - btnPos.Y)
                    if callback then 
                        pcall(callback)
                    end
                end
            end)
            
            Btn.MouseEnter:Connect(function()
                Tween(Btn, {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}, 0.2)
            end)
            
            Btn.MouseLeave:Connect(function()
                Tween(Btn, {BackgroundColor3 = Config.Theme.Secondary}, 0.2)
            end)
        end,
        
        -- Тоггл (большой свитч для пальца)
        AddToggle = function(self, text, default, callback)
            local ToggleFrame = Instance.new("Frame", Content)
            ToggleFrame.Size = UDim2.new(1, 0, 0, IsMobile and 70 or 50)
            ToggleFrame.BackgroundColor3 = Config.Theme.Secondary
            ToggleFrame.BorderSizePixel = 0
            ToggleFrame.ClipsDescendants = true
            Instance.new("UICorner", ToggleFrame).CornerRadius = UDim.new(0, IsMobile and 12 or 8)
            
            local ToggleText = Instance.new("TextLabel", ToggleFrame)
            ToggleText.Size = UDim2.new(1, IsMobile and -100 or -70, 1, 0)
            ToggleText.Position = UDim2.new(0, 15, 0, 0)
            ToggleText.BackgroundTransparency = 1
            ToggleText.Text = text
            ToggleText.TextColor3 = Config.Theme.Text
            ToggleText.TextSize = Config.FontSize
            ToggleText.Font = Enum.Font.Gotham
            ToggleText.TextXAlignment = Enum.TextXAlignment.Left
            
            -- Большой свитч для телефона
            local switchWidth = IsMobile and 60 or 44
            local switchHeight = IsMobile and 34 or 24
            local Switch = Instance.new("TextButton", ToggleFrame)
            Switch.Size = UDim2.new(0, switchWidth, 0, switchHeight)
            Switch.Position = UDim2.new(1, -(switchWidth + (IsMobile and 20 or 15)), 0.5, -switchHeight/2)
            Switch.BackgroundColor3 = default and Config.Theme.Text or Color3.fromRGB(60, 60, 60)
            Switch.Text = ""
            Switch.AutoButtonColor = false
            Switch.ClipsDescendants = true
            Instance.new("UICorner", Switch).CornerRadius = UDim.new(1, 0)
            
            local circleSize = IsMobile and 28 or 18
            local Circle = Instance.new("Frame", Switch)
            Circle.Size = UDim2.new(0, circleSize, 0, circleSize)
            Circle.Position = default and UDim2.new(1, -(circleSize + 3), 0, 3) or UDim2.new(0, 3, 0, 3)
            Circle.BackgroundColor3 = Config.Theme.Background
            Circle.BorderSizePixel = 0
            Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)
            
            local Value = default
            
            Switch.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or 
                   input.UserInputType == Enum.UserInputType.Touch then
                    Ripple(Switch, switchWidth/2, switchHeight/2)
                    Value = not Value
                    local targetPos = Value and UDim2.new(1, -(circleSize + 3), 0, 3) or UDim2.new(0, 3, 0, 3)
                    local targetColor = Value and Config.Theme.Text or Color3.fromRGB(60, 60, 60)
                    
                    Tween(Circle, {Position = targetPos}, 0.3)
                    Tween(Switch, {BackgroundColor3 = targetColor}, 0.3)
                    
                    if callback then pcall(function() callback(Value) end) end
                end
            end)
            
            return {
                SetValue = function(v)
                    Value = v
                    Circle.Position = v and UDim2.new(1, -(circleSize + 3), 0, 3) or UDim2.new(0, 3, 0, 3)
                    Switch.BackgroundColor3 = v and Config.Theme.Text or Color3.fromRGB(60, 60, 60)
                    if callback then callback(v) end
                end
            }
        end,
        
        -- Слайдер (толще для точного управления пальцем)
        AddSlider = function(self, text, min, max, default, callback, useFloat)
            local SliderFrame = Instance.new("Frame", Content)
            SliderFrame.Size = UDim2.new(1, 0, 0, IsMobile and 80 or 60)
            SliderFrame.BackgroundColor3 = Config.Theme.Secondary
            SliderFrame.BorderSizePixel = 0
            Instance.new("UICorner", SliderFrame).CornerRadius = UDim.new(0, IsMobile and 12 or 8)
            
            local SliderText = Instance.new("TextLabel", SliderFrame)
            SliderText.Size = UDim2.new(1, -20, 0, 25)
            SliderText.Position = UDim2.new(0, 15, 0, 5)
            SliderText.BackgroundTransparency = 1
            SliderText.Text = text
            SliderText.TextColor3 = Config.Theme.Text
            SliderText.TextSize = Config.FontSize
            SliderText.Font = Enum.Font.Gotham
            SliderText.TextXAlignment = Enum.TextXAlignment.Left
            
            local ValueLabel = Instance.new("TextLabel", SliderFrame)
            ValueLabel.Size = UDim2.new(0, 50, 0, 25)
            ValueLabel.Position = UDim2.new(1, -60, 0, 5)
            ValueLabel.BackgroundTransparency = 1
            ValueLabel.Text = tostring(default)
            ValueLabel.TextColor3 = Config.Theme.Text
            ValueLabel.TextSize = Config.FontSize
            ValueLabel.Font = Enum.Font.GothamBold
            
            local sliderHeight = IsMobile and 10 or 6
            local SliderBg = Instance.new("Frame", SliderFrame)
            SliderBg.Size = UDim2.new(1, -30, 0, sliderHeight)
            SliderBg.Position = UDim2.new(0, 15, 0, IsMobile and 50 or 40)
            SliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            SliderBg.BorderSizePixel = 0
            Instance.new("UICorner", SliderBg).CornerRadius = UDim.new(1, 0)
            
            local Fill = Instance.new("Frame", SliderBg)
            Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            Fill.BackgroundColor3 = Config.Theme.Text
            Fill.BorderSizePixel = 0
            Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)
            
            local knobSize = IsMobile and 24 or 16
            local Knob = Instance.new("Frame", SliderBg)
            Knob.Size = UDim2.new(0, knobSize, 0, knobSize)
            Knob.Position = UDim2.new((default - min) / (max - min), -knobSize/2, 0, (sliderHeight - knobSize)/2)
            Knob.BackgroundColor3 = Config.Theme.Text
            Knob.BorderSizePixel = 0
            Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)
            
            -- Увеличенная невидимая зона для тача
            local TouchZone = Instance.new("TextButton", SliderBg)
            TouchZone.Size = UDim2.new(1, 0, 1, IsMobile and 40 or 20)
            TouchZone.Position = UDim2.new(0, 0, 0, IsMobile and -20 or -10)
            TouchZone.BackgroundTransparency = 1
            TouchZone.Text = ""
            
            local Dragging = false
            
            local function Update(input)
                local sizeX = math.clamp((input.Position.X - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X, 0, 1)
                local value = min + (max - min) * sizeX
                if not useFloat then
                    value = math.floor(value)
                else
                    value = math.floor(value * 100) / 100
                end
                
                Tween(Fill, {Size = UDim2.new(sizeX, 0, 1, 0)}, 0.1)
                Tween(Knob, {Position = UDim2.new(sizeX, -knobSize/2, 0, (sliderHeight - knobSize)/2)}, 0.1)
                ValueLabel.Text = tostring(value)
                
                if callback then pcall(function() callback(value) end) end
            end
            
            local function onInputBegan(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or 
                   input.UserInputType == Enum.UserInputType.Touch then
                    Dragging = true
                    Update(input)
                end
            end
            
            TouchZone.InputBegan:Connect(onInputBegan)
            SliderBg.InputBegan:Connect(onInputBegan)
            
            UserInputService.InputChanged:Connect(function(input)
                if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                                input.UserInputType == Enum.UserInputType.Touch) then
                    Update(input)
                end
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or 
                   input.UserInputType == Enum.UserInputType.Touch then
                    Dragging = false
                end
            end)
        end,
        
        AddTextBox = function(self, text, placeholder, callback)
            local BoxFrame = Instance.new("Frame", Content)
            BoxFrame.Size = UDim2.new(1, 0, 0, IsMobile and 90 or 70)
            BoxFrame.BackgroundColor3 = Config.Theme.Secondary
            BoxFrame.BorderSizePixel = 0
            Instance.new("UICorner", BoxFrame).CornerRadius = UDim.new(0, IsMobile and 12 or 8)
            
            local Label = Instance.new("TextLabel", BoxFrame)
            Label.Size = UDim2.new(1, -20, 0, 25)
            Label.Position = UDim2.new(0, 15, 0, 5)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = Config.Theme.Text
            Label.TextSize = Config.FontSize
            Label.Font = Enum.Font.Gotham
            Label.TextXAlignment = Enum.TextXAlignment.Left
            
            local TextBox = Instance.new("TextBox", BoxFrame)
            TextBox.Size = UDim2.new(1, -30, 0, IsMobile and 40 or 30)
            TextBox.Position = UDim2.new(0, 15, 0, IsMobile and 45 or 35)
            TextBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            TextBox.Text = ""
            TextBox.PlaceholderText = placeholder or "..."
            TextBox.TextColor3 = Config.Theme.Text
            TextBox.PlaceholderColor3 = Config.Theme.SubText
            TextBox.TextSize = IsMobile and 18 or 14
            TextBox.Font = Enum.Font.Gotham
            TextBox.ClearTextOnFocus = false
            Instance.new("UICorner", TextBox).CornerRadius = UDim.new(0, 8)
            
            -- На мобильных увеличиваем область нажатия
            if IsMobile then
                TextBox.Focused:Connect(function()
                    -- Автоскролл к текстбоксу когда открывается клавиатура
                    Content.CanvasPosition = Vector2.new(0, TextBox.AbsolutePosition.Y - BoxFrame.AbsolutePosition.Y - 100)
                end)
            end
            
            TextBox.FocusLost:Connect(function(enterPressed)
                if callback then pcall(function() callback(TextBox.Text) end) end
            end)
        end,
        
        AddDropdown = function(self, text, options, callback)
            local DropdownFrame = Instance.new("Frame", Content)
            DropdownFrame.Size = UDim2.new(1, 0, 0, IsMobile and 60 or 40)
            DropdownFrame.BackgroundColor3 = Config.Theme.Secondary
            DropdownFrame.BorderSizePixel = 0
            DropdownFrame.ClipsDescendants = true
            Instance.new("UICorner", DropdownFrame).CornerRadius = UDim.new(0, IsMobile and 12 or 8)
            
            local DropdownBtn = Instance.new("TextButton", DropdownFrame)
            DropdownBtn.Size = UDim2.new(1, 0, 0, IsMobile and 60 or 40)
            DropdownBtn.BackgroundTransparency = 1
            DropdownBtn.Text = ""
            DropdownBtn.ClipsDescendants = true
            
            local Label = Instance.new("TextLabel", DropdownBtn)
            Label.Size = UDim2.new(1, -60, 1, 0)
            Label.Position = UDim2.new(0, 15, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = text .. ": " .. options[1]
            Label.TextColor3 = Config.Theme.Text
            Label.TextSize = Config.FontSize
            Label.Font = Enum.Font.Gotham
            Label.TextXAlignment = Enum.TextXAlignment.Left
            
            local Arrow = Instance.new("TextLabel", DropdownBtn)
            Arrow.Size = UDim2.new(0, 40, 1, 0)
            Arrow.Position = UDim2.new(1, -50, 0, 0)
            Arrow.BackgroundTransparency = 1
            Arrow.Text = "▼"
            Arrow.TextColor3 = Config.Theme.SubText
            Arrow.TextSize = IsMobile and 18 or 12
            Arrow.Font = Enum.Font.GothamBold
            
            local OptionsContainer = Instance.new("Frame", DropdownFrame)
            OptionsContainer.Size = UDim2.new(1, -20, 0, #options * (IsMobile and 50 or 32))
            OptionsContainer.Position = UDim2.new(0, 10, 0, IsMobile and 65 or 45)
            OptionsContainer.BackgroundTransparency = 1
            
            local UIList = Instance.new("UIListLayout", OptionsContainer)
            UIList.Padding = UDim.new(0, IsMobile and 8 or 4)
            
            local Opened = false
            
            for i, option in pairs(options) do
                local OptionBtn = Instance.new("TextButton", OptionsContainer)
                OptionBtn.Size = UDim2.new(1, 0, 0, IsMobile and 50 or 32)
                OptionBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                OptionBtn.Text = option
                OptionBtn.TextColor3 = Config.Theme.Text
                OptionBtn.TextSize = IsMobile and 16 or 13
                OptionBtn.Font = Enum.Font.Gotham
                OptionBtn.AutoButtonColor = false
                OptionBtn.ClipsDescendants = true
                Instance.new("UICorner", OptionBtn).CornerRadius = UDim.new(0, IsMobile and 10 or 6)
                
                OptionBtn.MouseEnter:Connect(function()
                    Tween(OptionBtn, {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}, 0.2)
                end)
                
                OptionBtn.MouseLeave:Connect(function()
                    Tween(OptionBtn, {BackgroundColor3 = Color3.fromRGB(35, 35, 35)}, 0.2)
                end)
                
                OptionBtn.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
                       input.UserInputType == Enum.UserInputType.Touch then
                        local pos = input.Position
                        local btnPos = OptionBtn.AbsolutePosition
                        Ripple(OptionBtn, pos.X - btnPos.X, pos.Y - btnPos.Y)
                        Label.Text = text .. ": " .. option
                        if callback then callback(option) end
                        DropdownBtn:Fire()
                    end
                end)
            end
            
            DropdownBtn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or 
                   input.UserInputType == Enum.UserInputType.Touch then
                    Opened = not Opened
                    local targetSize = Opened and UDim2.new(1, 0, 0, (IsMobile and 75 or 55) + #options * (IsMobile and 50 or 32)) 
                                                or UDim2.new(1, 0, 0, IsMobile and 60 or 40)
                    Tween(DropdownFrame, {Size = targetSize}, 0.3, Enum.EasingStyle.Quart)
                    Tween(Arrow, {Rotation = Opened and 180 or 0}, 0.3)
                end
            end)
        end,
        
        AddLabel = function(self, text)
            local Label = Instance.new("TextLabel", Content)
            Label.Size = UDim2.new(1, 0, 0, IsMobile and 40 or 30)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = Config.Theme.SubText
            Label.TextSize = IsMobile and 14 or 12
            Label.Font = Enum.Font.GothamBold
            Label.TextXAlignment = Enum.TextXAlignment.Left
            return Label
        end
    }
    
    table.insert(Tabs, TabData)
    if #Tabs == 1 then Activate() end
    return TabData
end

--// Event Handlers (крупные кнопки для пальцев)
CloseBtn.MouseEnter:Connect(function() Tween(CloseBtn, {BackgroundColor3 = Color3.fromRGB(200, 60, 50)}, 0.2) end)
CloseBtn.MouseLeave:Connect(function() Tween(CloseBtn, {BackgroundColor3 = Color3.fromRGB(231, 76, 60)}, 0.2) end)
CloseBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
       input.UserInputType == Enum.UserInputType.Touch then
        local pos = input.Position
        local btnPos = CloseBtn.AbsolutePosition
        Ripple(CloseBtn, pos.X - btnPos.X, pos.Y - btnPos.Y)
        wait(0.2)
        Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
        wait(0.3)
        ScreenGui:Destroy()
        getgenv().HerkleHub_Loaded = false
    end
end)

MinimizeBtn.MouseEnter:Connect(function() Tween(MinimizeBtn, {BackgroundColor3 = Color3.fromRGB(80, 80, 80)}, 0.2) end)
MinimizeBtn.MouseLeave:Connect(function() Tween(MinimizeBtn, {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}, 0.2) end)
MinimizeBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
       input.UserInputType == Enum.UserInputType.Touch then
        local pos = input.Position
        local btnPos = MinimizeBtn.AbsolutePosition
        Ripple(MinimizeBtn, pos.X - btnPos.X, pos.Y - btnPos.Y)
        ToggleUI()
    end
end)

ToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
       input.UserInputType == Enum.UserInputType.Touch then
        local pos = input.Position
        local btnPos = ToggleBtn.AbsolutePosition
        Ripple(ToggleBtn, pos.X - btnPos.X, pos.Y - btnPos.Y)
        ToggleUI()
    end
end)

-- Горячая клавиша (на ПК RightShift, на мобильных можно добавить кнопку на экране)
if not IsMobile then
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
            ToggleUI()
        end
    end)
else
    -- На мобильных показываем кнопку сразу если свернуто
    ToggleBtn.Visible = false
end

-- Intro Animation
MainFrame.Visible = true
Tween(MainFrame, {Size = Config.Size}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

print("Loading Herkle Hub Mobile -- Booga Booga Reborn")
print("Device: " .. (IsMobile and (IsTablet and "Tablet" or "Phone") or "PC"))

--// Game Logic (стандартный код Herkle Hub)
local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")
local hum = char:WaitForChild("Humanoid")

LocalPlayer.CharacterAdded:Connect(function(newChar)
    char = newChar
    root = char:WaitForChild("HumanoidRootPart")
    hum = char:WaitForChild("Humanoid")
end)

-- Encoding Functions
local function decode(str)
    local b1, b2, b3 = string.byte(str, -4, -2)
    return b1 + b2 * 256 + b3 * 65536
end

local function swingencode(ids)
    if typeof(ids) ~= "table" then ids = {ids} end
    local count = #ids
    local out = {string.char(0x00, 0x11, count, 0x00)}
    for i = 1, count do
        local num = ids[i]
        out[#out + 1] = string.char(num % 256, math.floor(num / 256) % 256, math.floor(num / 65536) % 256, 0x00)
    end
    return table.concat(out)
end

local function pickupencode(entityid)
    local b1 = entityid % 256
    local b2 = math.floor(entityid / 256) % 256
    local b3 = math.floor(entityid / 65536) % 256
    return string.char(0x00, 0xD5, b1, b2, b3, 0x00)
end

local function interactstructureencode(entityid, itemid)
    local b1 = entityid % 256
    local b2 = math.floor(entityid / 256) % 256
    local b3 = math.floor(entityid / 65536) % 256
    local i1 = itemid % 256
    local i2 = math.floor(itemid / 256) % 256
    return string.char(0x00, 0xC9, b1, b2, b3, 0x00, i1, i2)
end

local function run(stringg, packett, itemid)
    local id = typeof(stringg) == "string" and decode(stringg) or stringg
    local packet
    if packett == "swing" then
        packet = swingencode(id)
    elseif packett == "pickup" then
        packet = pickupencode(id)
    elseif packett == "interactstructure" then
        packet = interactstructureencode(id, typeof(itemid) == "number" and itemid or nil)
    end
    ReplicatedStorage:WaitForChild("ByteNetReliable"):FireServer(buffer.fromstring(packet))
end

local function drop(itemname)
    local inventory = LocalPlayer.PlayerGui.MainGui.RightPanel.Inventory:FindFirstChild("List")
    if not inventory then return end
    for _, child in ipairs(inventory:GetChildren()) do
        if child:IsA("ImageLabel") and child.Name == itemname then
            if packets and packets.DropBagItem and packets.DropBagItem.send then
                packets.DropBagItem.send(child.LayoutOrder)
            end
        end
    end
end

--// UI Tabs Setup
local MainTab = CreateTab("Main")
local CombatTab = CreateTab("Combat")
local MapTab = CreateTab("Map")
local PickupTab = CreateTab("Pickup")
local FarmingTab = CreateTab("Farming")
local ExtraTab = CreateTab("Extra")

-- Main Tab
MainTab:AddToggle("Walkspeed", false, function(v) States.Walkspeed = v end)
MainTab:AddSlider("Walkspeed Value", 1, 35, 16, function(v) States.WalkspeedValue = v end)
MainTab:AddToggle("JumpPower", false, function(v) States.JumpPower = v end)
MainTab:AddSlider("JumpPower Value", 1, 65, 50, function(v) States.JumpPowerValue = v end)
MainTab:AddToggle("HipHeight", false, function(v) States.HipHeight = v end)
MainTab:AddSlider("HipHeight Value", 0.1, 6.5, 2, function(v) States.HipHeightValue = v end, true)
MainTab:AddToggle("No Mountain Slip", false, function(v) States.NoMountainSlip = v end)
MainTab:AddButton("Copy Job ID", function() setclipboard(game.JobId) end)
MainTab:AddButton("Copy HWID", function() setclipboard(game:GetService("RbxAnalyticsService"):GetClientId()) end)
MainTab:AddButton("Copy SID", function() setclipboard(game:GetService("RbxAnalyticsService"):GetSessionId()) end)

-- Combat Tab
CombatTab:AddToggle("Kill Aura", false, function(v) States.KillAura = v end)
CombatTab:AddSlider("Kill Aura Range", 1, 9, 5, function(v) States.KillAuraRange = v end)
CombatTab:AddDropdown("Max Targets", {"1", "2", "3", "4", "5", "6"}, function(v) States.KillAuraTargets = tonumber(v) end)
CombatTab:AddSlider("Attack Cooldown", 0.01, 1.01, 0.1, function(v) States.KillAuraCooldown = v end, true)

-- Map Tab
MapTab:AddToggle("Resource Aura", false, function(v) States.ResourceAura = v end)
MapTab:AddSlider("Resource Range", 1, 20, 20, function(v) States.ResourceAuraRange = v end)
MapTab:AddDropdown("Resource Max Targets", {"1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20"}, function(v) States.ResourceAuraTargets = tonumber(v) end)
MapTab:AddSlider("Resource Cooldown", 0.01, 1.01, 0.1, function(v) States.ResourceAuraCooldown = v end, true)

MapTab:AddToggle("Critter Aura", false, function(v) States.CritterAura = v end)
MapTab:AddSlider("Critter Range", 1, 20, 20, function(v) States.CritterAuraRange = v end)
MapTab:AddDropdown("Critter Max Targets", {"1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20"}, function(v) States.CritterAuraTargets = tonumber(v) end)
MapTab:AddSlider("Critter Cooldown", 0.01, 1.01, 0.1, function(v) States.CritterAuraCooldown = v end, true)

-- Pickup Tab
PickupTab:AddToggle("Auto Pickup", false, function(v) States.AutoPickup = v end)
PickupTab:AddToggle("Auto Pickup From Chests", false, function(v) States.ChestPickup = v end)
PickupTab:AddSlider("Pickup Range", 1, 35, 20, function(v) States.PickupRange = v end)
PickupTab:AddLabel("Items (comma separated):")
local itemsBox = PickupTab:AddTextBox("Items", "Leaves, Log", function(text)
    States.SelectedItems = {}
    for item in text:gmatch("([^,]+)") do
        table.insert(States.SelectedItems, item:match("^%s*(.-)%s*$"))
    end
end)
PickupTab:AddToggle("Auto Drop", false, function(v) States.AutoDrop = v end)
PickupTab:AddDropdown("Drop Item", {"Bloodfruit", "Jelly", "Bluefruit", "Log", "Leaves", "Wood"}, function(v) States.DropItem = v end)
PickupTab:AddToggle("Auto Drop Custom", false, function(v) States.AutoDropCustom = v end)
PickupTab:AddTextBox("Custom Item", "Bloodfruit", function(v) States.DropItemCustom = v end)

-- Farming Tab
FarmingTab:AddDropdown("Select Fruit", {"Bloodfruit", "Bluefruit", "Lemon", "Coconut", "Jelly", "Banana", "Orange", "Oddberry", "Berry", "Strangefruit", "Strawberry", "Sunfruit", "Pumpkin", "Prickly Pear", "Apple", "Barley", "Cloudberry", "Carrot"}, function(v) States.SelectedFruit = v end)
FarmingTab:AddToggle("Auto Plant", false, function(v) States.AutoPlant = v end)
FarmingTab:AddSlider("Plant Range", 1, 30, 30, function(v) States.PlantRange = v end)
FarmingTab:AddSlider("Plant Delay", 0.01, 1, 0.1, function(v) States.PlantDelay = v end, true)
FarmingTab:AddToggle("Auto Harvest", false, function(v) States.AutoHarvest = v end)
FarmingTab:AddSlider("Harvest Range", 1, 30, 30, function(v) States.HarvestRange = v end)

FarmingTab:AddLabel("-- Tween Settings --")
FarmingTab:AddToggle("Tween to Plant Box", false, function(v) States.TweenToPlantBox = v end)
FarmingTab:AddToggle("Tween to Bush + Plant", false, function(v) States.TweenToBush = v end)
FarmingTab:AddSlider("Tween Range", 1, 250, 250, function(v) States.TweenRange = v end)

FarmingTab:AddLabel("-- Place Structure --")
FarmingTab:AddButton("Place 16x16 Plantboxes (256)", function() placestructure(16) end)
FarmingTab:AddButton("Place 15x15 Plantboxes (225)", function() placestructure(15) end)
FarmingTab:AddButton("Place 10x10 Plantboxes (100)", function() placestructure(10) end)
FarmingTab:AddButton("Place 5x5 Plantboxes (25)", function() placestructure(5) end)

-- Extra Tab
ExtraTab:AddButton("Infinite Yield", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/decryp1/herklesiy/refs/heads/main/hiy"))()
end)
ExtraTab:AddLabel("-- Item Orbit (can break) --")
ExtraTab:AddToggle("Item Orbit", false, function(v) States.ItemOrbit = v end)
ExtraTab:AddSlider("Grab Range", 1, 50, 20, function(v) States.OrbitRange = v end)
ExtraTab:AddSlider("Orbit Radius", 0, 30, 10, function(v) States.OrbitRadius = v end)
ExtraTab:AddSlider("Orbit Speed", 0, 10, 5, function(v) States.OrbitSpeed = v end)
ExtraTab:AddSlider("Item Height", -3, 10, 3, function(v) States.ItemHeight = v end)

--// Logic Loops (полный функционал Herkle Hub)
RunService.RenderStepped:Connect(function()
    if hum then
        if States.Walkspeed then hum.WalkSpeed = States.WalkspeedValue end
        if States.JumpPower then hum.JumpPower = States.JumpPowerValue end
        if States.HipHeight then hum.HipHeight = States.HipHeightValue end
        if States.NoMountainSlip then hum.MaxSlopeAngle = 90 else hum.MaxSlopeAngle = 46 end
    end
end)

task.spawn(function()
    while true do
        if not States.KillAura then task.wait(0.1) continue end
        local targets = {}
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local playerfolder = workspace.Players:FindFirstChild(player.Name)
                if playerfolder then
                    local rootpart = playerfolder:FindFirstChild("HumanoidRootPart")
                    local entityid = playerfolder:GetAttribute("EntityID")
                    if rootpart and entityid then
                        local dist = (rootpart.Position - root.Position).Magnitude
                        if dist <= States.KillAuraRange then
                            table.insert(targets, {eid = entityid, dist = dist})
                        end
                    end
                end
            end
        end
        if #targets > 0 then
            table.sort(targets, function(a, b) return a.dist < b.dist end)
            local selectedTargets = {}
            for i = 1, math.min(States.KillAuraTargets, #targets) do
                table.insert(selectedTargets, targets[i].eid)
            end
            run(selectedTargets, "swing")
        end
        task.wait(States.KillAuraCooldown)
    end
end)

task.spawn(function()
    while true do
        if not States.ResourceAura then task.wait(0.1) continue end
        local targets = {}
        local allresources = {}
        for _, r in pairs(workspace.Resources:GetChildren()) do table.insert(allresources, r) end
        for _, r in pairs(workspace:GetChildren()) do
            if r:IsA("Model") and r.Name == "Gold Node" then table.insert(allresources, r) end
        end
        for _, res in pairs(allresources) do
            if res:IsA("Model") and res:GetAttribute("EntityID") then
                local eid = res:GetAttribute("EntityID")
                local ppart = res.PrimaryPart or res:FindFirstChildWhichIsA("BasePart")
                if ppart then
                    local dist = (ppart.Position - root.Position).Magnitude
                    if dist <= States.ResourceAuraRange then
                        table.insert(targets, {eid = eid, dist = dist})
                    end
                end
            end
        end
        if #targets > 0 then
            table.sort(targets, function(a, b) return a.dist < b.dist end)
            local selectedTargets = {}
            for i = 1, math.min(States.ResourceAuraTargets, #targets) do
                table.insert(selectedTargets, targets[i].eid)
            end
            run(selectedTargets, "swing")
        end
        task.wait(States.ResourceAuraCooldown)
    end
end)

task.spawn(function()
    while true do
        if not States.CritterAura then task.wait(0.1) continue end
        local targets = {}
        for _, critter in pairs(workspace.Critters:GetChildren()) do
            if critter:IsA("Model") and critter:GetAttribute("EntityID") then
                local eid = critter:GetAttribute("EntityID")
                local ppart = critter.PrimaryPart or critter:FindFirstChildWhichIsA("BasePart")
                if ppart then
                    local dist = (ppart.Position - root.Position).Magnitude
                    if dist <= States.CritterAuraRange then
                        table.insert(targets, {eid = eid, dist = dist})
                    end
                end
            end
        end
        if #targets > 0 then
            table.sort(targets, function(a, b) return a.dist < b.dist end)
            local selectedTargets = {}
            for i = 1, math.min(States.CritterAuraTargets, #targets) do
                table.insert(selectedTargets, targets[i].eid)
            end
            run(selectedTargets, "swing")
        end
        task.wait(States.CritterAuraCooldown)
    end
end)

task.spawn(function()
    while true do
        if States.AutoPickup then
            for _, item in ipairs(workspace.Items:GetChildren()) do
                if item:IsA("BasePart") or item:IsA("MeshPart") then
                    local entityid = item:GetAttribute("EntityID")
                    if entityid and table.find(States.SelectedItems, item.Name) then
                        local dist = (item.Position - root.Position).Magnitude
                        if dist <= States.PickupRange then
                            run(entityid, "pickup")
                        end
                    end
                end
            end
        end
        if States.ChestPickup then
            for _, chest in ipairs(workspace.Deployables:GetChildren()) do
                if chest:IsA("Model") and chest:FindFirstChild("Contents") then
                    for _, item in ipairs(chest.Contents:GetChildren()) do
                        if item:IsA("BasePart") or item:IsA("MeshPart") then
                            local entityid = item:GetAttribute("EntityID")
                            if entityid and table.find(States.SelectedItems, item.Name) then
                                local dist = (chest.PrimaryPart.Position - root.Position).Magnitude
                                if dist <= States.PickupRange then
                                    run(entityid, "pickup")
                                end
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.01)
    end
end)

local debounce = 0
RunService.Heartbeat:Connect(function()
    if States.AutoDrop then
        if tick() - debounce >= 0 then
            drop(States.DropItem)
            debounce = tick()
        end
    end
    if States.AutoDropCustom then
        if tick() - debounce >= 0 then
            drop(States.DropItemCustom)
            debounce = tick()
        end
    end
end)

local fruittoitemid = {
    Bloodfruit = 94, Bluefruit = 377, Lemon = 99, Coconut = 1,
    Jelly = 604, Banana = 606, Orange = 602, Oddberry = 32,
    Berry = 35, Strangefruit = 302, Strawberry = 282, Sunfruit = 128,
    Pumpkin = 80, ["Prickly Pear"] = 378, Apple = 243,
    Barley = 247, Cloudberry = 101, Carrot = 147
}

local function getpbs(range)
    local plantboxes = {}
    for _, deployable in ipairs(workspace.Deployables:GetChildren()) do
        if deployable:IsA("Model") and deployable.Name == "Plant Box" then
            local entityid = deployable:GetAttribute("EntityID")
            local ppart = deployable.PrimaryPart or deployable:FindFirstChildWhichIsA("BasePart")
            if entityid and ppart then
                local dist = (ppart.Position - root.Position).Magnitude
                if dist <= range then
                    table.insert(plantboxes, {entityid = entityid, deployable = deployable, dist = dist})
                end
            end
        end
    end
    return plantboxes
end

local function getbushes(range, fruitname)
    local bushes = {}
    for _, model in ipairs(workspace:GetChildren()) do
        if model:IsA("Model") and model.Name:find(fruitname) then
            local ppart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
            if ppart then
                local dist = (ppart.Position - root.Position).Magnitude
                if dist <= range then
                    local entityid = model:GetAttribute("EntityID")
                    if entityid then
                        table.insert(bushes, {entityid = entityid, model = model, dist = dist})
                    end
                end
            end
        end
    end
    return bushes
end

local tspmo = game:GetService("TweenService")
local tweening = nil

local function tween(target)
    if tweening then tweening:Cancel() end
    local distance = (root.Position - target.Position).Magnitude
    local duration = distance / 21
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tw = tspmo:Create(root, tweenInfo, {CFrame = target})
    tw:Play()
    tweening = tw
end

task.spawn(function()
    while true do
        if not States.AutoPlant then task.wait(0.1) continue end
        local plantboxes = getpbs(States.PlantRange)
        table.sort(plantboxes, function(a, b) return a.dist < b.dist end)
        local itemID = fruittoitemid[States.SelectedFruit] or 94
        for _, box in ipairs(plantboxes) do
            if not box.deployable:FindFirstChild("Seed") then
                run(box.entityid, "interactstructure", itemID)
            end
        end
        task.wait(States.PlantDelay)
    end
end)

task.spawn(function()
    while true do
        if not States.AutoHarvest then task.wait(0.1) continue end
        local bushes = getbushes(States.HarvestRange, States.SelectedFruit)
        table.sort(bushes, function(a, b) return a.dist < b.dist end)
        for _, bush in ipairs(bushes) do
            run(bush.entityid, "pickup")
        end
        task.wait(0.1)
    end
end)

task.spawn(function()
    while true do
        if States.TweenToPlantBox then
            local plantboxes = getpbs(States.TweenRange)
            table.sort(plantboxes, function(a, b) return a.dist < b.dist end)
            for _, box in ipairs(plantboxes) do
                if not box.deployable:FindFirstChild("Seed") then
                    local target = box.deployable.PrimaryPart.CFrame + Vector3.new(0, 5, 0)
                    tween(target)
                    break
                end
            end
        end
        task.wait(0.1)
    end
end)

task.spawn(function()
    while true do
        if States.TweenToBush then
            local bushes = getbushes(States.TweenRange, States.SelectedFruit)
            table.sort(bushes, function(a, b) return a.dist < b.dist end)
            if #bushes > 0 then
                for _, bush in ipairs(bushes) do
                    local target = bush.model.PrimaryPart.CFrame + Vector3.new(0, 5, 0)
                    tween(target)
                    break
                end
            else
                local plantboxes = getpbs(States.TweenRange)
                table.sort(plantboxes, function(a, b) return a.dist < b.dist end)
                for _, box in ipairs(plantboxes) do
                    if not box.deployable:FindFirstChild("Seed") then
                        local target = box.deployable.PrimaryPart.CFrame + Vector3.new(0, 5, 0)
                        tween(target)
                        break
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

function placestructure(gridsize)
    if not LocalPlayer or not LocalPlayer.Character then return end
    local torso = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not torso then return end
    local startpos = torso.Position - Vector3.new(0, 3, 0)
    local spacing = 6.04
    for x = 0, gridsize - 1 do
        for z = 0, gridsize - 1 do
            task.wait(0.3)
            local position = startpos + Vector3.new(x * spacing, 0, z * spacing)
            if packets.PlaceStructure and packets.PlaceStructure.send then
                packets.PlaceStructure.send({
                    ["buildingName"] = "Plant Box",
                    ["yrot"] = 45,
                    ["vec"] = position,
                    ["isMobile"] = false
                })
            end
        end
    end
end

local attacheditems, itemangles = {}, {}
local itemsfolder = workspace:WaitForChild("Items")

RunService.RenderStepped:Connect(function()
    if not States.ItemOrbit then
        for _, bp in pairs(attacheditems) do bp:Destroy() end
        table.clear(attacheditems)
        table.clear(itemangles)
        return
    end
    local time = tick() * States.OrbitSpeed
    for item, bp in pairs(attacheditems) do
        if item then
            local angle = itemangles[item] + time
            bp.Position = root.Position + Vector3.new(
                math.cos(angle) * States.OrbitRadius, 
                States.ItemHeight, 
                math.sin(angle) * States.OrbitRadius
            )
        end
    end
end)

task.spawn(function()
    while true do
        if States.ItemOrbit then
            local children = itemsfolder:GetChildren()
            local anglestep = (math.pi * 2) / math.max(#children, 1)
            local index = 0
            for _, item in pairs(children) do
                local primary = item:IsA("BasePart") and item or item:IsA("Model") and item.PrimaryPart
                if primary and (primary.Position - root.Position).Magnitude <= States.OrbitRange then
                    if not attacheditems[primary] then
                        local bp = Instance.new("BodyPosition")
                        bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                        bp.D = 1500
                        bp.P = 25000
                        bp.Parent = primary
                        attacheditems[primary] = bp
                        itemangles[primary] = index * anglestep
                        index = index + 1
                    end
                end
            end
            for item, bp in pairs(attacheditems) do
                if item and (item.Position - root.Position).Magnitude > States.OrbitRange * 1.5 then
                    bp:Destroy()
                    attacheditems[item] = nil
                    itemangles[item] = nil
                end
            end
        end
        task.wait(0.1)
    end
end)

print("Done! Herkle Hub Mobile Loaded")
