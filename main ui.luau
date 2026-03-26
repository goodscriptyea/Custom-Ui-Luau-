local NebulaUI = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Настройки темы
local Theme = {
    Background = Color3.fromRGB(15, 15, 20),
    Secondary = Color3.fromRGB(25, 25, 35),
    Accent = Color3.fromRGB(124, 58, 237), -- Фиолетовый
    Accent2 = Color3.fromRGB(59, 130, 246), -- Синий
    Text = Color3.fromRGB(255, 255, 255),
    SubText = Color3.fromRGB(175, 175, 175),
    Glow = Color3.fromRGB(139, 92, 246),
    Border = Color3.fromRGB(40, 40, 50)
}

-- Утилиты для анимаций
local function Tween(obj, props, duration, easing, direction)
    local info = TweenInfo.new(duration or 0.3, easing or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out)
    local tween = TweenService:Create(obj, info, props)
    tween:Play()
    return tween
end

local function Ripple(button, x, y)
    local ripple = Instance.new("Frame")
    ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ripple.BackgroundTransparency = 0.8
    ripple.BorderSizePixel = 0
    ripple.Position = UDim2.new(0, x - 5, 0, y - 5)
    ripple.Size = UDim2.new(0, 10, 0, 10)
    ripple.Parent = button
    ripple.ZIndex = 10
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ripple
    
    Tween(ripple, {Size = UDim2.new(0, 100, 0, 100), Position = UDim2.new(0, x - 50, 0, y - 50), BackgroundTransparency = 1}, 0.6)
    task.delay(0.6, function() ripple:Destroy() end)
end

-- Создание основного GUI
function NebulaUI:CreateWindow(config)
    config = config or {}
    local Window = {
        Tabs = {},
        ActiveTab = nil,
        Minimized = false,
        Dragging = false,
        DragStart = nil,
        StartPos = nil
    }
    
    -- ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NebulaUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = PlayerGui
    
    -- Main Frame с тенью и glow эффектом
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 600, 0, 400)
    MainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    
    -- Glow эффект (внешнее свечение)
    local Glow = Instance.new("ImageLabel")
    Glow.Name = "Glow"
    Glow.Size = UDim2.new(1, 40, 1, 40)
    Glow.Position = UDim2.new(0, -20, 0, -20)
    Glow.BackgroundTransparency = 1
    Glow.Image = "rbxassetid://5028857084"
    Glow.ImageColor3 = Theme.Glow
    Glow.ImageTransparency = 0.8
    Glow.Parent = MainFrame
    
    -- Gradient фон
    local Gradient = Instance.new("UIGradient")
    Gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Background),
        ColorSequenceKeypoint.new(1, Theme.Secondary)
    })
    Gradient.Rotation = 45
    Gradient.Parent = MainFrame
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12)
    Corner.Parent = MainFrame
    
    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Theme.Border
    Stroke.Thickness = 1.5
    Stroke.Parent = MainFrame
    
    -- Акцентная линия сверху
    local TopLine = Instance.new("Frame")
    TopLine.Name = "TopLine"
    TopLine.Size = UDim2.new(1, 0, 0, 2)
    TopLine.BackgroundColor3 = Theme.Accent
    TopLine.BorderSizePixel = 0
    TopLine.Parent = MainFrame
    
    local TopLineGradient = Instance.new("UIGradient")
    TopLineGradient.Color = ColorSequence.new(Theme.Accent, Theme.Accent2)
    TopLineGradient.Parent = TopLine
    
    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 45)
    TitleBar.BackgroundColor3 = Theme.Secondary
    TitleBar.BackgroundTransparency = 0.5
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 12)
    TitleCorner.Parent = TitleBar
    
    local TitleText = Instance.new("TextLabel")
    TitleText.Name = "Title"
    TitleText.Size = UDim2.new(0, 200, 1, 0)
    TitleText.Position = UDim2.new(0, 20, 0, 0)
    TitleText.BackgroundTransparency = 1
    TitleText.Text = config.Title or "Nebula UI"
    TitleText.TextColor3 = Theme.Text
    TitleText.TextSize = 20
    TitleText.Font = Enum.Font.GothamBold
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    TitleText.Parent = TitleBar
    
    -- Subtitle
    local Subtitle = Instance.new("TextLabel")
    Subtitle.Name = "Subtitle"
    Subtitle.Size = UDim2.new(0, 200, 0, 20)
    Subtitle.Position = UDim2.new(0, 20, 0, 25)
    Subtitle.BackgroundTransparency = 1
    Subtitle.Text = config.SubTitle or "Premium Exploit"
    Subtitle.TextColor3 = Theme.SubText
    Subtitle.TextSize = 12
    Subtitle.Font = Enum.Font.Gotham
    Subtitle.TextXAlignment = Enum.TextXAlignment.Left
    Subtitle.Parent = TitleBar
    
    -- Кнопки управления окном
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "Close"
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -40, 0, 8)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.TextSize = 18
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Parent = TitleBar
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 8)
    CloseCorner.Parent = CloseBtn
    
    local MinimizeBtn = Instance.new("TextButton")
    MinimizeBtn.Name = "Minimize"
    MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
    MinimizeBtn.Position = UDim2.new(1, -75, 0, 8)
    MinimizeBtn.BackgroundColor3 = Color3.fromRGB(234, 179, 8)
    MinimizeBtn.Text = "−"
    MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinimizeBtn.TextSize = 18
    MinimizeBtn.Font = Enum.Font.GothamBold
    MinimizeBtn.Parent = TitleBar
    
    local MinCorner = Instance.new("UICorner")
    MinCorner.CornerRadius = UDim.new(0, 8)
    MinCorner.Parent = MinimizeBtn
    
    -- Sidebar
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 160, 1, -45)
    Sidebar.Position = UDim2.new(0, 0, 0, 45)
    Sidebar.BackgroundColor3 = Theme.Secondary
    Sidebar.BackgroundTransparency = 0.8
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainFrame
    
    local SideCorner = Instance.new("UICorner")
    SideCorner.CornerRadius = UDim.new(0, 0)
    SideCorner.Parent = Sidebar
    
    local SideCornerFix = Instance.new("Frame")
    SideCornerFix.Size = UDim2.new(0, 10, 0, 10)
    SideCornerFix.Position = UDim2.new(1, -10, 0, 0)
    SideCornerFix.BackgroundColor3 = Theme.Secondary
    SideCornerFix.BorderSizePixel = 0
    SideCornerFix.Parent = Sidebar
    
    -- Container для вкладок
    local TabContainer = Instance.new("Frame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(1, -160, 1, -45)
    TabContainer.Position = UDim2.new(0, 160, 0, 45)
    TabContainer.BackgroundTransparency = 1
    TabContainer.Parent = MainFrame
    
    -- Toggle Button (плавающая кнопка для скрытия/показа)
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Name = "ToggleBtn"
    ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
    ToggleBtn.Position = UDim2.new(0, 20, 0, 20)
    ToggleBtn.BackgroundColor3 = Theme.Accent
    ToggleBtn.Text = "N"
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleBtn.TextSize = 24
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.Visible = false
    ToggleBtn.Parent = ScreenGui
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(1, 0)
    ToggleCorner.Parent = ToggleBtn
    
    local ToggleStroke = Instance.new("UIStroke")
    ToggleStroke.Color = Theme.Glow
    ToggleStroke.Thickness = 2
    ToggleStroke.Parent = ToggleBtn
    
    local ToggleGlow = Instance.new("ImageLabel")
    ToggleGlow.Size = UDim2.new(1.5, 0, 1.5, 0)
    ToggleGlow.Position = UDim2.new(0, -12, 0, -12)
    ToggleGlow.BackgroundTransparency = 1
    ToggleGlow.Image = "rbxassetid://5028857084"
    ToggleGlow.ImageColor3 = Theme.Accent
    ToggleGlow.ImageTransparency = 0.6
    ToggleGlow.Parent = ToggleBtn
    
    -- Drag функционал
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Window.Dragging = true
            Window.DragStart = input.Position
            Window.StartPos = MainFrame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if Window.Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - Window.DragStart
            MainFrame.Position = UDim2.new(
                Window.StartPos.X.Scale,
                Window.StartPos.X.Offset + delta.X,
                Window.StartPos.Y.Scale,
                Window.StartPos.Y.Offset + delta.Y
            )
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Window.Dragging = false
        end
    end)
    
    -- Анимации кнопок управления
    CloseBtn.MouseEnter:Connect(function()
        Tween(CloseBtn, {BackgroundColor3 = Color3.fromRGB(220, 38, 38)}, 0.2)
    end)
    
    CloseBtn.MouseLeave:Connect(function()
        Tween(CloseBtn, {BackgroundColor3 = Color3.fromRGB(239, 68, 68)}, 0.2)
    end)
    
    CloseBtn.MouseButton1Click:Connect(function()
        Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}, 0.3)
        task.wait(0.3)
        ScreenGui:Destroy()
    end)
    
    MinimizeBtn.MouseEnter:Connect(function()
        Tween(MinimizeBtn, {BackgroundColor3 = Color3.fromRGB(202, 138, 4)}, 0.2)
    end)
    
    MinimizeBtn.MouseLeave:Connect(function()
        Tween(MinimizeBtn, {BackgroundColor3 = Color3.fromRGB(234, 179, 8)}, 0.2)
    end)
    
    -- Toggle функционал (скрыть/показать)
    local function ToggleUI()
        Window.Minimized = not Window.Minimized
        if Window.Minimized then
            ToggleBtn.Visible = true
            Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
            Tween(Glow, {ImageTransparency = 1}, 0.4)
        else
            Tween(MainFrame, {Size = UDim2.new(0, 600, 0, 400)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            Tween(Glow, {ImageTransparency = 0.8}, 0.4)
            task.wait(0.4)
            ToggleBtn.Visible = false
        end
    end
    
    MinimizeBtn.MouseButton1Click:Connect(ToggleUI)
    ToggleBtn.MouseButton1Click:Connect(ToggleUI)
    
    -- Keybind для toggle (RightShift по умолчанию)
    local ToggleKey = config.ToggleKey or Enum.KeyCode.RightShift
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == ToggleKey then
            ToggleUI()
        end
    end)
    
    -- Hover эффекты для ToggleBtn
    ToggleBtn.MouseEnter:Connect(function()
        Tween(ToggleBtn, {Size = UDim2.new(0, 55, 0, 55)}, 0.2)
        Tween(ToggleGlow, {ImageTransparency = 0.4}, 0.2)
    end)
    
    ToggleBtn.MouseLeave:Connect(function()
        Tween(ToggleBtn, {Size = UDim2.new(0, 50, 0, 50)}, 0.2)
        Tween(ToggleGlow, {ImageTransparency = 0.6}, 0.2)
    end)
    
    -- Создание вкладки
    function Window:CreateTab(name, icon)
        local Tab = {
            Elements = {}
        }
        
        -- Кнопка вкладки в сайдбаре
        local TabBtn = Instance.new("TextButton")
        TabBtn.Name = name .. "Btn"
        TabBtn.Size = UDim2.new(1, -20, 0, 40)
        TabBtn.Position = UDim2.new(0, 10, 0, 10 + (#Window.Tabs * 50))
        TabBtn.BackgroundColor3 = Theme.Secondary
        TabBtn.Text = ""
        TabBtn.Parent = Sidebar
        
        local TabBtnCorner = Instance.new("UICorner")
        TabBtnCorner.CornerRadius = UDim.new(0, 8)
        TabBtnCorner.Parent = TabBtn
        
        -- Индикатор активной вкладки (слева)
        local Indicator = Instance.new("Frame")
        Indicator.Name = "Indicator"
        Indicator.Size = UDim2.new(0, 4, 0, 20)
        Indicator.Position = UDim2.new(0, -2, 0.5, -10)
        Indicator.BackgroundColor3 = Theme.Accent
        Indicator.BorderSizePixel = 0
        Indicator.Visible = false
        Indicator.Parent = TabBtn
        
        local IndicatorCorner = Instance.new("UICorner")
        IndicatorCorner.CornerRadius = UDim.new(0, 2)
        IndicatorCorner.Parent = Indicator
        
        local TabIcon = Instance.new("TextLabel")
        TabIcon.Name = "Icon"
        TabIcon.Size = UDim2.new(0, 30, 1, 0)
        TabIcon.Position = UDim2.new(0, 10, 0, 0)
        TabIcon.BackgroundTransparency = 1
        TabIcon.Text = icon or "◆"
        TabIcon.TextColor3 = Theme.SubText
        TabIcon.TextSize = 18
        TabIcon.Font = Enum.Font.GothamBold
        TabIcon.Parent = TabBtn
        
        local TabText = Instance.new("TextLabel")
        TabText.Name = "Text"
        TabText.Size = UDim2.new(1, -50, 1, 0)
        TabText.Position = UDim2.new(0, 40, 0, 0)
        TabText.BackgroundTransparency = 1
        TabText.Text = name
        TabText.TextColor3 = Theme.SubText
        TabText.TextSize = 14
        TabText.Font = Enum.Font.GothamSemibold
        TabText.TextXAlignment = Enum.TextXAlignment.Left
        TabText.Parent = TabBtn
        
        -- Контент вкладки
        local TabContent = Instance.new("ScrollingFrame")
        TabContent.Name = name .. "Content"
        TabContent.Size = UDim2.new(1, -20, 1, -20)
        TabContent.Position = UDim2.new(0, 10, 0, 10)
        TabContent.BackgroundTransparency = 1
        TabContent.BorderSizePixel = 0
        TabContent.ScrollBarThickness = 4
        TabContent.ScrollBarImageColor3 = Theme.Accent
        TabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
        TabContent.Visible = false
        TabContent.Parent = TabContainer
        
        local UIList = Instance.new("UIListLayout")
        UIList.Padding = UDim.new(0, 10)
        UIList.SortOrder = Enum.SortOrder.LayoutOrder
        UIList.Parent = TabContent
        
        -- Активация вкладки
        local function Activate()
            if Window.ActiveTab == Tab then return end
            
            -- Деактивировать текущую
            if Window.ActiveTab then
                Window.ActiveTab.Content.Visible = false
                Window.ActiveTab.Indicator.Visible = false
                Tween(Window.ActiveTab.Button, {BackgroundColor3 = Theme.Secondary}, 0.2)
                Tween(Window.ActiveTab.Button.TextLabel, {TextColor3 = Theme.SubText}, 0.2)
            end
            
            -- Активировать новую
            Window.ActiveTab = Tab
            TabContent.Visible = true
            Indicator.Visible = true
            
            Tween(TabBtn, {BackgroundColor3 = Theme.Accent}, 0.3)
            Tween(TabText, {TextColor3 = Theme.Text}, 0.2)
            Tween(TabIcon, {TextColor3 = Theme.Text}, 0.2)
            
            -- Анимация появления контента
            TabContent.Position = UDim2.new(0.05, 10, 0, 10)
            Tween(TabContent, {Position = UDim2.new(0, 10, 0, 10)}, 0.4, Enum.EasingStyle.Quart)
        end
        
        TabBtn.MouseButton1Click:Connect(Activate)
        
        -- Hover эффекты
        TabBtn.MouseEnter:Connect(function()
            if Window.ActiveTab ~= Tab then
                Tween(TabBtn, {BackgroundColor3 = Color3.fromRGB(45, 45, 60)}, 0.2)
            end
        end)
        
        TabBtn.MouseLeave:Connect(function()
            if Window.ActiveTab ~= Tab then
                Tween(TabBtn, {BackgroundColor3 = Theme.Secondary}, 0.2)
            end
        end)
        
        Tab.Button = TabBtn
        Tab.Indicator = Indicator
        Tab.Content = TabContent
        
        table.insert(Window.Tabs, Tab)
        
        -- Автоактивация первой вкладки
        if #Window.Tabs == 1 then
            Activate()
        end
        
        -- Добавление элементов
        function Tab:AddButton(text, callback)
            local Button = Instance.new("TextButton")
            Button.Name = text .. "Btn"
            Button.Size = UDim2.new(1, 0, 0, 40)
            Button.BackgroundColor3 = Theme.Secondary
            Button.Text = ""
            Button.Parent = TabContent
            
            local BtnCorner = Instance.new("UICorner")
            BtnCorner.CornerRadius = UDim.new(0, 8)
            BtnCorner.Parent = Button
            
            local BtnStroke = Instance.new("UIStroke")
            BtnStroke.Color = Theme.Border
            BtnStroke.Thickness = 1
            BtnStroke.Parent = Button
            
            local BtnText = Instance.new("TextLabel")
            BtnText.Size = UDim2.new(1, -20, 1, 0)
            BtnText.Position = UDim2.new(0, 10, 0, 0)
            BtnText.BackgroundTransparency = 1
            BtnText.Text = text
            BtnText.TextColor3 = Theme.Text
            BtnText.TextSize = 14
            BtnText.Font = Enum.Font.GothamSemibold
            BtnText.TextXAlignment = Enum.TextXAlignment.Left
            BtnText.Parent = Button
            
            -- Arrow icon
            local Arrow = Instance.new("TextLabel")
            Arrow.Size = UDim2.new(0, 30, 1, 0)
            Arrow.Position = UDim2.new(1, -35, 0, 0)
            Arrow.BackgroundTransparency = 1
            Arrow.Text = "→"
            Arrow.TextColor3 = Theme.Accent
            Arrow.TextSize = 18
            Arrow.Font = Enum.Font.GothamBold
            Arrow.Parent = Button
            
            -- Анимации
            Button.MouseEnter:Connect(function()
                Tween(Button, {BackgroundColor3 = Color3.fromRGB(50, 50, 70)}, 0.2)
                Tween(Arrow, {Position = UDim2.new(1, -30, 0, 0)}, 0.2)
            end)
            
            Button.MouseLeave:Connect(function()
                Tween(Button, {BackgroundColor3 = Theme.Secondary}, 0.2)
                Tween(Arrow, {Position = UDim2.new(1, -35, 0, 0)}, 0.2)
            end)
            
            Button.MouseButton1Click:Connect(function(x, y)
                Ripple(Button, x or 100, y or 20)
                if callback then callback() end
            end)
            
            -- Обновление CanvasSize
            TabContent.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 20)
            UIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                TabContent.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 20)
            end)
            
            return Button
        end
        
        function Tab:AddToggle(text, default, callback)
            local Toggle = {
                Value = default or false
            }
            
            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.Name = text .. "Toggle"
            ToggleFrame.Size = UDim2.new(1, 0, 0, 50)
            ToggleFrame.BackgroundColor3 = Theme.Secondary
            ToggleFrame.BorderSizePixel = 0
            ToggleFrame.Parent = TabContent
            
            local FrameCorner = Instance.new("UICorner")
            FrameCorner.CornerRadius = UDim.new(0, 8)
            FrameCorner.Parent = ToggleFrame
            
            local ToggleText = Instance.new("TextLabel")
            ToggleText.Size = UDim2.new(1, -70, 1, 0)
            ToggleText.Position = UDim2.new(0, 15, 0, 0)
            ToggleText.BackgroundTransparency = 1
            ToggleText.Text = text
            ToggleText.TextColor3 = Theme.Text
            ToggleText.TextSize = 14
            ToggleText.Font = Enum.Font.GothamSemibold
            ToggleText.TextXAlignment = Enum.TextXAlignment.Left
            ToggleText.Parent = ToggleFrame
            
            -- Свитч
            local SwitchBg = Instance.new("TextButton")
            SwitchBg.Name = "Switch"
            SwitchBg.Size = UDim2.new(0, 50, 0, 26)
            SwitchBg.Position = UDim2.new(1, -60, 0.5, -13)
            SwitchBg.BackgroundColor3 = Toggle.Value and Theme.Accent or Color3.fromRGB(60, 60, 70)
            SwitchBg.Text = ""
            SwitchBg.Parent = ToggleFrame
            
            local SwitchCorner = Instance.new("UICorner")
            SwitchCorner.CornerRadius = UDim.new(1, 0)
            SwitchCorner.Parent = SwitchBg
            
            local Circle = Instance.new("Frame")
            Circle.Name = "Circle"
            Circle.Size = UDim2.new(0, 20, 0, 20)
            Circle.Position = Toggle.Value and UDim2.new(1, -23, 0, 3) or UDim2.new(0, 3, 0, 3)
            Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Circle.BorderSizePixel = 0
            Circle.Parent = SwitchBg
            
            local CircleCorner = Instance.new("UICorner")
            CircleCorner.CornerRadius = UDim.new(1, 0)
            CircleCorner.Parent = Circle
            
            local function Update()
                Toggle.Value = not Toggle.Value
                local targetPos = Toggle.Value and UDim2.new(1, -23, 0, 3) or UDim2.new(0, 3, 0, 3)
                local targetColor = Toggle.Value and Theme.Accent or Color3.fromRGB(60, 60, 70)
                
                Tween(Circle, {Position = targetPos}, 0.3, Enum.EasingStyle.Quart)
                Tween(SwitchBg, {BackgroundColor3 = targetColor}, 0.3)
                
                if callback then callback(Toggle.Value) end
            end
            
            SwitchBg.MouseButton1Click:Connect(Update)
            
            -- Обновление CanvasSize
            TabContent.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 20)
            UIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                TabContent.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 20)
            end)
            
            return Toggle
        end
        
        function Tab:AddSlider(text, min, max, default, callback)
            local SliderFrame = Instance.new("Frame")
            SliderFrame.Name = text .. "Slider"
            SliderFrame.Size = UDim2.new(1, 0, 0, 60)
            SliderFrame.BackgroundColor3 = Theme.Secondary
            SliderFrame.BorderSizePixel = 0
            SliderFrame.Parent = TabContent
            
            local FrameCorner = Instance.new("UICorner")
            FrameCorner.CornerRadius = UDim.new(0, 8)
            FrameCorner.Parent = SliderFrame
            
            local SliderText = Instance.new("TextLabel")
            SliderText.Size = UDim2.new(1, -20, 0, 25)
            SliderText.Position = UDim2.new(0, 15, 0, 5)
            SliderText.BackgroundTransparency = 1
            SliderText.Text = text
            SliderText.TextColor3 = Theme.Text
            SliderText.TextSize = 14
            SliderText.Font = Enum.Font.GothamSemibold
            SliderText.TextXAlignment = Enum.TextXAlignment.Left
            SliderText.Parent = SliderFrame
            
            local ValueText = Instance.new("TextLabel")
            ValueText.Size = UDim2.new(0, 50, 0, 25)
            ValueText.Position = UDim2.new(1, -60, 0, 5)
            ValueText.BackgroundTransparency = 1
            ValueText.Text = tostring(default)
            ValueText.TextColor3 = Theme.Accent
            ValueText.TextSize = 14
            ValueText.Font = Enum.Font.GothamBold
            ValueText.Parent = SliderFrame
            
            -- Полоса слайдера
            local SliderBg = Instance.new("Frame")
            SliderBg.Name = "Background"
            SliderBg.Size = UDim2.new(1, -30, 0, 6)
            SliderBg.Position = UDim2.new(0, 15, 0, 38)
            SliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            SliderBg.BorderSizePixel = 0
            SliderBg.Parent = SliderFrame
            
            local SliderBgCorner = Instance.new("UICorner")
            SliderBgCorner.CornerRadius = UDim.new(1, 0)
            SliderBgCorner.Parent = SliderBg
            
            local Fill = Instance.new("Frame")
            Fill.Name = "Fill"
            Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            Fill.BackgroundColor3 = Theme.Accent
            Fill.BorderSizePixel = 0
            Fill.Parent = SliderBg
            
            local FillCorner = Instance.new("UICorner")
            FillCorner.CornerRadius = UDim.new(1, 0)
            FillCorner.Parent = Fill
            
            local Knob = Instance.new("Frame")
            Knob.Name = "Knob"
            Knob.Size = UDim2.new(0, 16, 0, 16)
            Knob.Position = UDim2.new((default - min) / (max - min), -8, 0, -5)
            Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Knob.BorderSizePixel = 0
            Knob.Parent = SliderBg
            
            local KnobCorner = Instance.new("UICorner")
            KnobCorner.CornerRadius = UDim.new(1, 0)
            KnobCorner.Parent = Knob
            
            -- Логика слайдера
            local dragging = false
            
            local function Update(input)
                local sizeX = math.clamp((input.Position.X - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X, 0, 1)
                local value = math.floor(min + (max - min) * sizeX)
                
                Tween(Fill, {Size = UDim2.new(sizeX, 0, 1, 0)}, 0.1)
                Tween(Knob, {Position = UDim2.new(sizeX, -8, 0, -5)}, 0.1)
                ValueText.Text = tostring(value)
                
                if callback then callback(value) end
            end
            
            SliderBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    Update(input)
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    Update(input)
                end
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
            
            -- Обновление CanvasSize
            TabContent.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 20)
            UIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                TabContent.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 20)
            end)
        end
        
        return Tab
    end
    
    -- Анимация открытия окна
    MainFrame.Size = UDim2.new(0, 0, 0, 0)
    Tween(MainFrame, {Size = UDim2.new(0, 600, 0, 400)}, 0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    
    return Window
end

return NebulaUI
