--// Status UI | Mobile Optimized + Device Selector
--// Drag & Drop support + Phone/Emulator modes

if getgenv().StatusUI_Loaded then return end
getgenv().StatusUI_Loaded = true

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

--// Конфиги для разных устройств
local Configs = {
    Phone = {
        Size = UDim2.new(0, 350, 0, 500),      -- Компактный для телефона
        SidebarWidth = 120,
        ButtonHeight = 45,                      -- Больше для пальцев
        FontSize = 14,
        ToggleBtnSize = 55,                     -- Большая плавающая кнопка
        IsPhone = true
    },
    Emulator = {
        Size = UDim2.new(0, 650, 0, 450),      -- Широкий для ПК
        SidebarWidth = 160,
        ButtonHeight = 40,
        FontSize = 14,
        ToggleBtnSize = 50,
        IsPhone = false
    }
}

local CurrentConfig = Configs.Emulator -- По умолчанию
local ScreenGui = nil

--// Utility Functions
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
        ripple.BackgroundTransparency = 0.6
        ripple.BorderSizePixel = 0
        ripple.Position = UDim2.new(0, x - 5, 0, y - 5)
        ripple.Size = UDim2.new(0, 10, 0, 10)
        ripple.Parent = button
        ripple.ZIndex = button.ZIndex + 10
        
        local corner = Instance.new("UICorner", ripple)
        corner.CornerRadius = UDim.new(1, 0)
        
        Tween(ripple, {
            Size = UDim2.new(0, 250, 0, 250), 
            Position = UDim2.new(0, x - 125, 0, y - 125), 
            BackgroundTransparency = 1
        }, 0.6)
        
        wait(0.6)
        ripple:Destroy()
    end)
end

--// Улучшенный Drag (работает и с тачем)
local function MakeDraggable(topbar, frame, isToggleBtn)
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            -- Для мобильных: уменьшаем прозрачность при захвате
            if CurrentConfig.IsPhone then
                Tween(frame, {BackgroundTransparency = 0.2}, 0.1)
            end
        end
    end)
    
    topbar.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                        input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, 
                startPos.X.Offset + delta.X, 
                startPos.Y.Scale, 
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    local function endDrag()
        if dragging then
            dragging = false
            if CurrentConfig.IsPhone then
                Tween(frame, {BackgroundTransparency = 0}, 0.1)
            end
        end
    end
    
    topbar.InputEnded:Connect(endDrag)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            endDrag()
        end
    end)
end

--// Экран выбора устройства
local function ShowDeviceSelector()
    local SelectorGui = Instance.new("ScreenGui")
    SelectorGui.Name = "DeviceSelector"
    SelectorGui.ResetOnSpawn = false
    SelectorGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    pcall(function() SelectorGui.Parent = CoreGui end)
    if not SelectorGui.Parent then SelectorGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    
    local Blur = Instance.new("Frame", SelectorGui)
    Blur.Size = UDim2.new(1, 0, 1, 0)
    Blur.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Blur.BackgroundTransparency = 0.5
    
    local Container = Instance.new("Frame", SelectorGui)
    Container.Size = UDim2.new(0, 300, 0, 200)
    Container.Position = UDim2.new(0.5, -150, 0.5, -100)
    Container.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Container.BorderSizePixel = 0
    
    Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 12)
    
    local Title = Instance.new("TextLabel", Container)
    Title.Size = UDim2.new(1, 0, 0, 50)
    Title.Position = UDim2.new(0, 0, 0, 10)
    Title.BackgroundTransparency = 1
    Title.Text = "SELECT DEVICE"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 20
    Title.Font = Enum.Font.GothamBold
    
    -- Кнопка Телефон
    local PhoneBtn = Instance.new("TextButton", Container)
    PhoneBtn.Size = UDim2.new(0.45, 0, 0, 80)
    PhoneBtn.Position = UDim2.new(0.03, 0, 0, 80)
    PhoneBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    PhoneBtn.Text = "📱 PHONE"
    PhoneBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    PhoneBtn.TextSize = 16
    PhoneBtn.Font = Enum.Font.GothamBold
    PhoneBtn.AutoButtonColor = false
    PhoneBtn.ClipsDescendants = true
    
    Instance.new("UICorner", PhoneBtn).CornerRadius = UDim.new(0, 10)
    
    -- Кнопка Эмулятор
    local EmuBtn = Instance.new("TextButton", Container)
    EmuBtn.Size = UDim2.new(0.45, 0, 0, 80)
    EmuBtn.Position = UDim2.new(0.52, 0, 0, 80)
    EmuBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    EmuBtn.Text = "🖥️ EMULATOR"
    EmuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    EmuBtn.TextSize = 16
    EmuBtn.Font = Enum.Font.GothamBold
    EmuBtn.AutoButtonColor = false
    EmuBtn.ClipsDescendants = true
    
    Instance.new("UICorner", EmuBtn).CornerRadius = UDim.new(0, 10)
    
    -- Hover эффекты
    PhoneBtn.MouseEnter:Connect(function() Tween(PhoneBtn, {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}, 0.2) end)
    PhoneBtn.MouseLeave:Connect(function() Tween(PhoneBtn, {BackgroundColor3 = Color3.fromRGB(30, 30, 30)}, 0.2) end)
    
    EmuBtn.MouseEnter:Connect(function() Tween(EmuBtn, {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}, 0.2) end)
    EmuBtn.MouseLeave:Connect(function() Tween(EmuBtn, {BackgroundColor3 = Color3.fromRGB(30, 30, 30)}, 0.2) end)
    
    -- Выбор
    PhoneBtn.MouseButton1Click:Connect(function(x, y)
        local mousePos = UserInputService:GetMouseLocation()
        local btnPos = PhoneBtn.AbsolutePosition
        Ripple(PhoneBtn, mousePos.X - btnPos.X, mousePos.Y - btnPos.Y)
        wait(0.3)
        CurrentConfig = Configs.Phone
        SelectorGui:Destroy()
        BuildUI()
    end)
    
    EmuBtn.MouseButton1Click:Connect(function(x, y)
        local mousePos = UserInputService:GetMouseLocation()
        local btnPos = EmuBtn.AbsolutePosition
        Ripple(EmuBtn, mousePos.X - btnPos.X, mousePos.Y - btnPos.Y)
        wait(0.3)
        CurrentConfig = Configs.Emulator
        SelectorGui:Destroy()
        BuildUI()
    end)
    
    -- Анимация появления
    Container.Size = UDim2.new(0, 0, 0, 0)
    Tween(Container, {Size = UDim2.new(0, 300, 0, 200)}, 0.5, Enum.EasingStyle.Back)
end

--// Основной UI
function BuildUI()
    local cfg = CurrentConfig
    
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "StatusUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    pcall(function() ScreenGui.Parent = CoreGui end)
    if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    
    -- Главное окно
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 0, 0, 0) -- Для анимации
    MainFrame.Position = UDim2.new(0.5, -cfg.Size.X.Offset/2, 0.5, -cfg.Size.Y.Offset/2)
    MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, cfg.IsPhone and 12 or 10)
    
    -- TitleBar
    local TitleBar = Instance.new("Frame", MainFrame)
    TitleBar.Size = UDim2.new(1, 0, 0, cfg.IsPhone and 50 or 45)
    TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    TitleBar.BorderSizePixel = 0
    
    local TitleText = Instance.new("TextLabel", TitleBar)
    TitleText.Size = UDim2.new(1, -100, 1, 0)
    TitleText.Position = UDim2.new(0, cfg.IsPhone and 15 or 20, 0, 0)
    TitleText.BackgroundTransparency = 1
    TitleText.Text = "STATUS"
    TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleText.TextSize = cfg.IsPhone and 20 or 18
    TitleText.Font = Enum.Font.GothamBold
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Кнопки управления
    local btnSize = cfg.IsPhone and 36 or 30
    local CloseBtn = Instance.new("TextButton", TitleBar)
    CloseBtn.Size = UDim2.new(0, btnSize, 0, btnSize)
    CloseBtn.Position = UDim2.new(1, -(btnSize + 10), 0, (TitleBar.Size.Y.Offset - btnSize)/2)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.TextSize = cfg.IsPhone and 22 or 18
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.AutoButtonColor = false
    CloseBtn.ClipsDescendants = true
    
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)
    
    local MinimizeBtn = Instance.new("TextButton", TitleBar)
    MinimizeBtn.Size = UDim2.new(0, btnSize, 0, btnSize)
    MinimizeBtn.Position = UDim2.new(1, -(btnSize*2 + 20), 0, (TitleBar.Size.Y.Offset - btnSize)/2)
    MinimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    MinimizeBtn.Text = "−"
    MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinimizeBtn.TextSize = cfg.IsPhone and 22 or 18
    MinimizeBtn.Font = Enum.Font.GothamBold
    MinimizeBtn.AutoButtonColor = false
    MinimizeBtn.ClipsDescendants = true
    
    Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 8)
    
    -- Sidebar
    local Sidebar = Instance.new("Frame", MainFrame)
    Sidebar.Size = UDim2.new(0, cfg.SidebarWidth, 1, -TitleBar.Size.Y.Offset)
    Sidebar.Position = UDim2.new(0, 0, 0, TitleBar.Size.Y.Offset)
    Sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Sidebar.BackgroundTransparency = 0.5
    Sidebar.BorderSizePixel = 0
    
    local TabContainer = Instance.new("Frame", MainFrame)
    TabContainer.Size = UDim2.new(1, -cfg.SidebarWidth, 1, -TitleBar.Size.Y.Offset)
    TabContainer.Position = UDim2.new(0, cfg.SidebarWidth, 0, TitleBar.Size.Y.Offset)
    TabContainer.BackgroundTransparency = 1
    
    -- Toggle Button (плавающая кнопка)
    local ToggleBtn = Instance.new("TextButton", ScreenGui)
    ToggleBtn.Size = UDim2.new(0, cfg.ToggleBtnSize, 0, cfg.ToggleBtnSize)
    ToggleBtn.Position = UDim2.new(0, 20, 0, 20)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    ToggleBtn.Text = "S"
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleBtn.TextSize = cfg.IsPhone and 24 or 20
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.Visible = false
    ToggleBtn.Active = true
    ToggleBtn.ClipsDescendants = true
    
    Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)
    
    -- Делаем оба элемента draggable
    MakeDraggable(TitleBar, MainFrame)
    MakeDraggable(ToggleBtn, ToggleBtn, true)
    
    -- Логика Toggle UI
    local Minimized = false
    local function ToggleUI()
        Minimized = not Minimized
        if Minimized then
            ToggleBtn.Visible = true
            Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
            wait(0.4)
            MainFrame.Visible = false
        else
            MainFrame.Visible = true
            Tween(MainFrame, {Size = cfg.Size}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            wait(0.4)
            ToggleBtn.Visible = false
        end
    end
    
    -- Табы
    local Tabs = {}
    local ActiveTab = nil
    
    local function CreateTab(name, icon)
        icon = icon or "◆"
        local btnHeight = cfg.ButtonHeight
        local padding = cfg.IsPhone and 12 or 10
        
        local TabBtn = Instance.new("TextButton", Sidebar)
        TabBtn.Size = UDim2.new(1, -padding*2, 0, btnHeight)
        TabBtn.Position = UDim2.new(0, padding, 0, padding + (#Tabs * (btnHeight + 8)))
        TabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        TabBtn.Text = ""
        TabBtn.AutoButtonColor = false
        TabBtn.ClipsDescendants = true
        
        Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 8)
        
        local Indicator = Instance.new("Frame", TabBtn)
        Indicator.Size = UDim2.new(0, 3, 0.5, 0)
        Indicator.Position = UDim2.new(0, 0, 0.25, 0)
        Indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Indicator.Visible = false
        Indicator.BorderSizePixel = 0
        
        Instance.new("UICorner", Indicator).CornerRadius = UDim.new(0, 2)
        
        local TabIcon = Instance.new("TextLabel", TabBtn)
        TabIcon.Size = UDim2.new(0, cfg.IsPhone and 30 or 25, 1, 0)
        TabIcon.Position = UDim2.new(0, 10, 0, 0)
        TabIcon.BackgroundTransparency = 1
        TabIcon.Text = icon
        TabIcon.TextColor3 = Color3.fromRGB(120, 120, 120)
        TabIcon.TextSize = cfg.IsPhone and 20 or 16
        TabIcon.Font = Enum.Font.GothamBold
        
        local TabText = Instance.new("TextLabel", TabBtn)
        TabText.Size = UDim2.new(1, -50, 1, 0)
        TabText.Position = UDim2.new(0, cfg.IsPhone and 40 or 35, 0, 0)
        TabText.BackgroundTransparency = 1
        TabText.Text = name
        TabText.TextColor3 = Color3.fromRGB(120, 120, 120)
        TabText.TextSize = cfg.FontSize
        TabText.Font = Enum.Font.GothamSemibold
        TabText.TextXAlignment = Enum.TextXAlignment.Left
        
        local Content = Instance.new("ScrollingFrame", TabContainer)
        Content.Size = UDim2.new(1, -cfg.IsPhone and 10 or 20, 1, -cfg.IsPhone and 10 or 20)
        Content.Position = UDim2.new(0, cfg.IsPhone and 5 or 10, 0, cfg.IsPhone and 5 or 10)
        Content.BackgroundTransparency = 1
        Content.ScrollBarThickness = cfg.IsPhone and 4 or 3
        Content.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
        Content.Visible = false
        Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Content.CanvasSize = UDim2.new(0, 0, 0, 0)
        
        local UIList = Instance.new("UIListLayout", Content)
        UIList.Padding = UDim.new(0, cfg.IsPhone and 12 or 10)
        
        local function Activate()
            if ActiveTab == Content then return end
            
            if ActiveTab then ActiveTab.Visible = false end
            
            for _, tab in pairs(Tabs) do
                tab.Indicator.Visible = false
                Tween(tab.Button, {BackgroundColor3 = Color3.fromRGB(30, 30, 30)}, 0.2)
                Tween(tab.Icon, {TextColor3 = Color3.fromRGB(120, 120, 120)}, 0.2)
                Tween(tab.Text, {TextColor3 = Color3.fromRGB(120, 120, 120)}, 0.2)
            end
            
            ActiveTab = Content
            Content.Visible = true
            Indicator.Visible = true
            
            Tween(TabBtn, {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}, 0.3)
            Tween(TabIcon, {TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.2)
            Tween(TabText, {TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.2)
            
            -- Анимация контента
            Content.Position = UDim2.new(0.02, Content.Position.X.Offset, 0, Content.Position.Y.Offset)
            Tween(Content, {Position = UDim2.new(0, Content.Position.X.Offset, 0, Content.Position.Y.Offset)}, 0.4)
        end
        
        TabBtn.MouseButton1Click:Connect(function()
            local mousePos = UserInputService:GetMouseLocation()
            local btnPos = TabBtn.AbsolutePosition
            Ripple(TabBtn, mousePos.X - btnPos.X, mousePos.Y - btnPos.Y)
            Activate()
        end)
        
        TabBtn.MouseEnter:Connect(function()
            if ActiveTab ~= Content then
                Tween(TabBtn, {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}, 0.2)
            end
        end)
        
        TabBtn.MouseLeave:Connect(function()
            if ActiveTab ~= Content then
                Tween(TabBtn, {BackgroundColor3 = Color3.fromRGB(30, 30, 30)}, 0.2)
            end
        end)
        
        local TabData = {
            Button = TabBtn,
            Content = Content,
            Indicator = Indicator,
            Icon = TabIcon,
            Text = TabText,
            
            AddButton = function(self, text, callback)
                local Btn = Instance.new("TextButton", Content)
                Btn.Size = UDim2.new(1, 0, 0, cfg.ButtonHeight)
                Btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                Btn.Text = text
                Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                Btn.TextSize = cfg.FontSize
                Btn.Font = Enum.Font.Gotham
                Btn.AutoButtonColor = false
                Btn.ClipsDescendants = true
                
                Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)
                
                Btn.MouseButton1Click:Connect(function()
                    local mousePos = UserInputService:GetMouseLocation()
                    local btnPos = Btn.AbsolutePosition
                    Ripple(Btn, mousePos.X - btnPos.X, mousePos.Y - btnPos.Y)
                    
                    if callback then 
                        pcall(callback)
                    end
                end)
                
                Btn.MouseEnter:Connect(function()
                    Tween(Btn, {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}, 0.2)
                end)
                
                Btn.MouseLeave:Connect(function()
                    Tween(Btn, {BackgroundColor3 = Color3.fromRGB(30, 30, 30)}, 0.2)
                end)
            end,
            
            AddToggle = function(self, text, default, callback)
                local ToggleFrame = Instance.new("Frame", Content)
                ToggleFrame.Size = UDim2.new(1, 0, 0, cfg.ButtonHeight)
                ToggleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                ToggleFrame.BorderSizePixel = 0
                ToggleFrame.ClipsDescendants = true
                
                Instance.new("UICorner", ToggleFrame).CornerRadius = UDim.new(0, 8)
                
                local ToggleText = Instance.new("TextLabel", ToggleFrame)
                ToggleText.Size = UDim2.new(1, -70, 1, 0)
                ToggleText.Position = UDim2.new(0, 15, 0, 0)
                ToggleText.BackgroundTransparency = 1
                ToggleText.Text = text
                ToggleText.TextColor3 = Color3.fromRGB(255, 255, 255)
                ToggleText.TextSize = cfg.FontSize
                ToggleText.Font = Enum.Font.Gotham
                ToggleText.TextXAlignment = Enum.TextXAlignment.Left
                
                local Switch = Instance.new("TextButton", ToggleFrame)
                Switch.Size = UDim2.new(0, 50, 0, 28)
                Switch.Position = UDim2.new(1, -65, 0.5, -14)
                Switch.BackgroundColor3 = default and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(60, 60, 60)
                Switch.Text = ""
                Switch.AutoButtonColor = false
                Switch.ClipsDescendants = true
                
                Instance.new("UICorner", Switch).CornerRadius = UDim.new(1, 0)
                
                local Circle = Instance.new("Frame", Switch)
                Circle.Size = UDim2.new(0, 22, 0, 22)
                Circle.Position = default and UDim2.new(1, -24, 0, 3) or UDim2.new(0, 3, 0, 3)
                Circle.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
                Circle.BorderSizePixel = 0
                
                Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)
                
                local Value = default
                
                Switch.MouseButton1Click:Connect(function()
                    Ripple(Switch, 25, 14)
                    
                    Value = not Value
                    local targetPos = Value and UDim2.new(1, -24, 0, 3) or UDim2.new(0, 3, 0, 3)
                    local targetColor = Value and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(60, 60, 60)
                    
                    Tween(Circle, {Position = targetPos}, 0.3)
                    Tween(Switch, {BackgroundColor3 = targetColor}, 0.3)
                    
                    if callback then pcall(function() callback(Value) end) end
                end)
            end,
            
            AddSlider = function(self, text, min, max, default, callback)
                local SliderFrame = Instance.new("Frame", Content)
                SliderFrame.Size = UDim2.new(1, 0, 0, cfg.IsPhone and 70 or 60)
                SliderFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                SliderFrame.BorderSizePixel = 0
                
                Instance.new("UICorner", SliderFrame).CornerRadius = UDim.new(0, 8)
                
                local SliderText = Instance.new("TextLabel", SliderFrame)
                SliderText.Size = UDim2.new(1, -60, 0, 30)
                SliderText.Position = UDim2.new(0, 15, 0, 5)
                SliderText.BackgroundTransparency = 1
                SliderText.Text = text
                SliderText.TextColor3 = Color3.fromRGB(255, 255, 255)
                SliderText.TextSize = cfg.FontSize
                SliderText.Font = Enum.Font.Gotham
                SliderText.TextXAlignment = Enum.TextXAlignment.Left
                
                local ValueLabel = Instance.new("TextLabel", SliderFrame)
                ValueLabel.Size = UDim2.new(0, 40, 0, 30)
                ValueLabel.Position = UDim2.new(1, -50, 0, 5)
                ValueLabel.BackgroundTransparency = 1
                ValueLabel.Text = tostring(default)
                ValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                ValueLabel.TextSize = cfg.FontSize
                ValueLabel.Font = Enum.Font.GothamBold
                
                local SliderBg = Instance.new("Frame", SliderFrame)
                SliderBg.Size = UDim2.new(1, -30, 0, 8)
                SliderBg.Position = UDim2.new(0, 15, 0, 45)
                SliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                SliderBg.BorderSizePixel = 0
                
                Instance.new("UICorner", SliderBg).CornerRadius = UDim.new(1, 0)
                
                local Fill = Instance.new("Frame", SliderBg)
                Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
                Fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
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
                    
                    if callback then pcall(function() callback(value) end) end
                end
                
                SliderBg.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
                       input.UserInputType == Enum.UserInputType.Touch then
                        Dragging = true
                        Update(input)
                    end
                end)
                
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
        local mousePos = UserInputService:GetMouseLocation()
        local btnPos = CloseBtn.AbsolutePosition
        Ripple(CloseBtn, mousePos.X - btnPos.X, mousePos.Y - btnPos.Y)
        wait(0.2)
        Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
        wait(0.3)
        ScreenGui:Destroy()
        getgenv().StatusUI_Loaded = false
    end)
    
    MinimizeBtn.MouseEnter:Connect(function() Tween(MinimizeBtn, {BackgroundColor3 = Color3.fromRGB(80, 80, 80)}, 0.2) end)
    MinimizeBtn.MouseLeave:Connect(function() Tween(MinimizeBtn, {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}, 0.2) end)
    MinimizeBtn.MouseButton1Click:Connect(function()
        local mousePos = UserInputService:GetMouseLocation()
        local btnPos = MinimizeBtn.AbsolutePosition
        Ripple(MinimizeBtn, mousePos.X - btnPos.X, mousePos.Y - btnPos.Y)
        ToggleUI()
    end)
    
    ToggleBtn.MouseButton1Click:Connect(function()
        local mousePos = UserInputService:GetMouseLocation()
        local btnPos = ToggleBtn.AbsolutePosition
        Ripple(ToggleBtn, mousePos.X - btnPos.X, mousePos.Y - btnPos.Y)
        ToggleUI()
    end)
    
    -- Клавиша только для эмулятора
    if not cfg.IsPhone then
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
                ToggleUI()
            end
        end)
    end
    
    -- Анимация открытия
    MainFrame.Visible = true
    Tween(MainFrame, {Size = cfg.Size}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    
    -- Пример (можешь удалить)
    local Main = CreateTab("Main", "⚡")
    Main:AddButton("Test", function() print("Work!") end)
    Main:AddToggle("Fly", false, function(v) print("Fly:", v) end)
    Main:AddSlider("Speed", 16, 500, 16, function(v) print("Speed:", v) end)
    
    local Player = CreateTab("Player", "👤")
    Player:AddButton("God Mode", function() print("God") end)
    
    return { CreateTab = CreateTab, Toggle = ToggleUI }
end

--// Запуск
ShowDeviceSelector()
