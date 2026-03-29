--// Status UI | Ripple Effect Edition
--// Improved Luau version

if getgenv().StatusUI_Loaded then
	return
end
getgenv().StatusUI_Loaded = true

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

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
		Border = Color3.fromRGB(40, 40, 40),
	},
}

local function tween(obj: Instance, props: {}, duration: number?, style: Enum.EasingStyle?, direction: Enum.EasingDirection?)
	local info = TweenInfo.new(duration or 0.25, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

local function addStroke(parent: Instance, transparency: number?)
	local s = Instance.new("UIStroke")
	s.Color = Config.Theme.Border
	s.Thickness = 1
	s.Transparency = transparency or 0.25
	s.Parent = parent
	return s
end

local function getMouseRelative(guiObject: GuiObject)
	local mouse = UserInputService:GetMouseLocation()
	local pos = guiObject.AbsolutePosition
	return mouse.X - pos.X, mouse.Y - pos.Y
end

local function ripple(button: GuiObject)
	local x, y = getMouseRelative(button)

	local rippleFrame = Instance.new("Frame")
	rippleFrame.Name = "Ripple"
	rippleFrame.BackgroundColor3 = Color3.new(1, 1, 1)
	rippleFrame.BackgroundTransparency = 0.72
	rippleFrame.BorderSizePixel = 0
	rippleFrame.ZIndex = button.ZIndex + 20
	rippleFrame.ClipsDescendants = false
	rippleFrame.Size = UDim2.fromOffset(10, 10)
	rippleFrame.Position = UDim2.fromOffset(x - 5, y - 5)
	rippleFrame.Parent = button

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1, 0)
	c.Parent = rippleFrame

	local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2.2
	tween(rippleFrame, {
		Size = UDim2.fromOffset(maxSize, maxSize),
		Position = UDim2.fromOffset(x - maxSize / 2, y - maxSize / 2),
		BackgroundTransparency = 1,
	}, 0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

	task.delay(0.55, function()
		if rippleFrame and rippleFrame.Parent then
			rippleFrame:Destroy()
		end
	end)
end

local function makeDraggable(dragHandle: GuiObject, frame: GuiObject)
	local dragging = false
	local dragInput: InputObject?
	local dragStart: Vector3?
	local startPos: UDim2?

	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
		end
	end)

	dragHandle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input == dragInput and dragStart and startPos then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
end

local function makeButton(parent: Instance, text: string)
	local b = Instance.new("TextButton")
	b.Name = text
	b.Size = UDim2.new(1, 0, 0, 40)
	b.BackgroundColor3 = Config.Theme.Secondary
	b.Text = text
	b.TextColor3 = Config.Theme.Text
	b.TextSize = 14
	b.Font = Enum.Font.Gotham
	b.AutoButtonColor = false
	b.BorderSizePixel = 0
	b.ClipsDescendants = true
	b.Parent = parent

	corner(b, 8)
	addStroke(b, 0.6)

	b.MouseEnter:Connect(function()
		tween(b, { BackgroundColor3 = Color3.fromRGB(35, 35, 35) }, 0.15)
	end)

	b.MouseLeave:Connect(function()
		tween(b, { BackgroundColor3 = Config.Theme.Secondary }, 0.15)
	end)

	return b
end

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

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.Size = UDim2.fromOffset(0, 0)
MainFrame.Position = Config.Position
MainFrame.BackgroundColor3 = Config.Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Visible = true

corner(MainFrame, 10)
addStroke(MainFrame, 0.35)

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Parent = MainFrame
TitleBar.Size = UDim2.new(1, 0, 0, 45)
TitleBar.BackgroundColor3 = Config.Theme.Secondary
TitleBar.BorderSizePixel = 0

local TitleText = Instance.new("TextLabel")
TitleText.Parent = TitleBar
TitleText.BackgroundTransparency = 1
TitleText.Size = UDim2.new(1, -100, 1, 0)
TitleText.Position = UDim2.fromOffset(20, 0)
TitleText.Text = Config.Title
TitleText.TextColor3 = Config.Theme.Text
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 18
TitleText.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = TitleBar
CloseBtn.Size = UDim2.fromOffset(30, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 7)
CloseBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Config.Theme.Text
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18
CloseBtn.AutoButtonColor = false
CloseBtn.BorderSizePixel = 0
CloseBtn.ClipsDescendants = true
corner(CloseBtn, 8)

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Parent = TitleBar
MinimizeBtn.Size = UDim2.fromOffset(30, 30)
MinimizeBtn.Position = UDim2.new(1, -75, 0, 7)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
MinimizeBtn.Text = "−"
MinimizeBtn.TextColor3 = Config.Theme.Text
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 18
MinimizeBtn.AutoButtonColor = false
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.ClipsDescendants = true
corner(MinimizeBtn, 8)

local Sidebar = Instance.new("Frame")
Sidebar.Parent = MainFrame
Sidebar.Size = UDim2.new(0, 160, 1, -45)
Sidebar.Position = UDim2.new(0, 0, 0, 45)
Sidebar.BackgroundColor3 = Config.Theme.Secondary
Sidebar.BackgroundTransparency = 0.45
Sidebar.BorderSizePixel = 0
addStroke(Sidebar, 0.75)

local TabContainer = Instance.new("Frame")
TabContainer.Parent = MainFrame
TabContainer.Size = UDim2.new(1, -160, 1, -45)
TabContainer.Position = UDim2.new(0, 160, 0, 45)
TabContainer.BackgroundTransparency = 1
TabContainer.BorderSizePixel = 0

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleButton"
ToggleBtn.Parent = ScreenGui
ToggleBtn.Size = UDim2.fromOffset(50, 50)
ToggleBtn.Position = UDim2.fromOffset(20, 20)
ToggleBtn.BackgroundColor3 = Config.Theme.Secondary
ToggleBtn.Text = "S"
ToggleBtn.TextColor3 = Config.Theme.Text
ToggleBtn.TextSize = 20
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Visible = false
ToggleBtn.Active = true
ToggleBtn.AutoButtonColor = false
ToggleBtn.BorderSizePixel = 0
ToggleBtn.ClipsDescendants = true
corner(ToggleBtn, 25)
addStroke(ToggleBtn, 0.6)

makeDraggable(TitleBar, MainFrame)
makeDraggable(ToggleBtn, ToggleBtn)

local Tabs = {}
local ActiveTab: ScrollingFrame? = nil
local Minimized = false
local DefaultSize = Config.Size

local function setTabState(tab, active: boolean)
	tab.Indicator.Visible = active
	tween(tab.Button, {
		BackgroundColor3 = active and Color3.fromRGB(40, 40, 40) or Config.Theme.Secondary,
	}, 0.15)
	tween(tab.Text, {
		TextColor3 = active and Config.Theme.Text or Config.Theme.SubText,
	}, 0.15)
end

local function toggleUI()
	Minimized = not Minimized

	if Minimized then
		ToggleBtn.Visible = true
		tween(MainFrame, { Size = UDim2.fromOffset(0, 0) }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.delay(0.35, function()
			MainFrame.Visible = false
		end)
	else
		MainFrame.Visible = true
		tween(MainFrame, { Size = DefaultSize }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		task.delay(0.35, function()
			ToggleBtn.Visible = false
		end)
	end
end

local function CreateTab(name: string)
	local TabBtn = Instance.new("TextButton")
	TabBtn.Name = name .. "_TabButton"
	TabBtn.Parent = Sidebar
	TabBtn.Size = UDim2.new(1, -20, 0, 40)
	TabBtn.Position = UDim2.new(0, 10, 0, 10 + (#Tabs * 50))
	TabBtn.BackgroundColor3 = Config.Theme.Secondary
	TabBtn.Text = ""
	TabBtn.AutoButtonColor = false
	TabBtn.BorderSizePixel = 0
	TabBtn.ClipsDescendants = true
	corner(TabBtn, 8)
	addStroke(TabBtn, 0.7)

	local Indicator = Instance.new("Frame")
	Indicator.Name = "Indicator"
	Indicator.Parent = TabBtn
	Indicator.Size = UDim2.fromOffset(3, 20)
	Indicator.Position = UDim2.new(0, 0, 0.5, -10)
	Indicator.BackgroundColor3 = Config.Theme.Accent
	Indicator.Visible = false
	Indicator.BorderSizePixel = 0
	corner(Indicator, 2)

	local TabText = Instance.new("TextLabel")
	TabText.Parent = TabBtn
	TabText.BackgroundTransparency = 1
	TabText.Size = UDim2.new(1, -20, 1, 0)
	TabText.Position = UDim2.fromOffset(15, 0)
	TabText.Text = name
	TabText.TextColor3 = Config.Theme.SubText
	TabText.TextSize = 14
	TabText.Font = Enum.Font.GothamSemibold
	TabText.TextXAlignment = Enum.TextXAlignment.Left

	local Content = Instance.new("ScrollingFrame")
	Content.Name = name .. "_Content"
	Content.Parent = TabContainer
	Content.Size = UDim2.new(1, -20, 1, -20)
	Content.Position = UDim2.fromOffset(10, 10)
	Content.BackgroundTransparency = 1
	Content.BorderSizePixel = 0
	Content.ScrollBarThickness = 3
	Content.ScrollBarImageColor3 = Config.Theme.Accent
	Content.Visible = false
	Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Content.CanvasSize = UDim2.new()

	local UIList = Instance.new("UIListLayout")
	UIList.Parent = Content
	UIList.Padding = UDim.new(0, 10)
	UIList.SortOrder = Enum.SortOrder.LayoutOrder

	local UIPadding = Instance.new("UIPadding")
	UIPadding.Parent = Content
	UIPadding.PaddingTop = UDim.new(0, 2)
	UIPadding.PaddingBottom = UDim.new(0, 2)

	local function Activate()
		if ActiveTab == Content then
			return
		end

		if ActiveTab then
			ActiveTab.Visible = false
		end

		for _, tab in ipairs(Tabs) do
			setTabState(tab, false)
		end

		ActiveTab = Content
		Content.Visible = true
		setTabState({
			Button = TabBtn,
			Text = TabText,
			Indicator = Indicator,
		}, true)
	end

	TabBtn.MouseButton1Click:Connect(function()
		ripple(TabBtn)
		Activate()
	end)

	TabBtn.MouseEnter:Connect(function()
		if ActiveTab ~= Content then
			tween(TabBtn, { BackgroundColor3 = Color3.fromRGB(35, 35, 35) }, 0.15)
		end
	end)

	TabBtn.MouseLeave:Connect(function()
		if ActiveTab ~= Content then
			tween(TabBtn, { BackgroundColor3 = Config.Theme.Secondary }, 0.15)
		end
	end)

	local TabData = {
		Button = TabBtn,
		Content = Content,
		Indicator = Indicator,
		Text = TabText,
	}

	function TabData:AddButton(text: string, callback)
		local Btn = makeButton(Content, text)
		Btn.MouseButton1Click:Connect(function()
			ripple(Btn)
			if callback then
				local ok, err = pcall(callback)
				if not ok then
					warn("Button callback error:", err)
				end
			end
		end)
		return Btn
	end

	function TabData:AddToggle(text: string, defaultValue: boolean, callback)
		local ToggleFrame = Instance.new("Frame")
		ToggleFrame.Parent = Content
		ToggleFrame.Size = UDim2.new(1, 0, 0, 40)
		ToggleFrame.BackgroundColor3 = Config.Theme.Secondary
		ToggleFrame.BorderSizePixel = 0
		ToggleFrame.ClipsDescendants = true
		corner(ToggleFrame, 8)
		addStroke(ToggleFrame, 0.65)

		local ToggleText = Instance.new("TextLabel")
		ToggleText.Parent = ToggleFrame
		ToggleText.BackgroundTransparency = 1
		ToggleText.Size = UDim2.new(1, -70, 1, 0)
		ToggleText.Position = UDim2.fromOffset(15, 0)
		ToggleText.Text = text
		ToggleText.TextColor3 = Config.Theme.Text
		ToggleText.TextSize = 14
		ToggleText.Font = Enum.Font.Gotham
		ToggleText.TextXAlignment = Enum.TextXAlignment.Left

		local Switch = Instance.new("TextButton")
		Switch.Parent = ToggleFrame
		Switch.Size = UDim2.fromOffset(44, 24)
		Switch.Position = UDim2.new(1, -60, 0.5, -12)
		Switch.BackgroundColor3 = defaultValue and Config.Theme.Text or Color3.fromRGB(60, 60, 60)
		Switch.Text = ""
		Switch.AutoButtonColor = false
		Switch.BorderSizePixel = 0
		Switch.ClipsDescendants = true
		corner(Switch, 12)

		local Circle = Instance.new("Frame")
		Circle.Parent = Switch
		Circle.Size = UDim2.fromOffset(18, 18)
		Circle.Position = defaultValue and UDim2.new(1, -21, 0, 3) or UDim2.new(0, 3, 0, 3)
		Circle.BackgroundColor3 = Config.Theme.Background
		Circle.BorderSizePixel = 0
		corner(Circle, 9)

		local value = defaultValue

		local function setState(v: boolean)
			value = v
			tween(Circle, {
				Position = value and UDim2.new(1, -21, 0, 3) or UDim2.new(0, 3, 0, 3)
			}, 0.2)
			tween(Switch, {
				BackgroundColor3 = value and Config.Theme.Text or Color3.fromRGB(60, 60, 60)
			}, 0.2)
			if callback then
				local ok, err = pcall(callback, value)
				if not ok then
					warn("Toggle callback error:", err)
				end
			end
		end

		Switch.MouseButton1Click:Connect(function()
			ripple(Switch)
			setState(not value)
		end)

		if callback then
			task.defer(function()
				callback(value)
			end)
		end

		return {
			Set = setState,
			Get = function()
				return value
			end,
		}
	end

	function TabData:AddSlider(text: string, min: number, max: number, defaultValue: number, callback)
		local SliderFrame = Instance.new("Frame")
		SliderFrame.Parent = Content
		SliderFrame.Size = UDim2.new(1, 0, 0, 60)
		SliderFrame.BackgroundColor3 = Config.Theme.Secondary
		SliderFrame.BorderSizePixel = 0
		corner(SliderFrame, 8)
		addStroke(SliderFrame, 0.65)

		local SliderText = Instance.new("TextLabel")
		SliderText.Parent = SliderFrame
		SliderText.BackgroundTransparency = 1
		SliderText.Size = UDim2.new(1, -20, 0, 25)
		SliderText.Position = UDim2.fromOffset(15, 5)
		SliderText.Text = text
		SliderText.TextColor3 = Config.Theme.Text
		SliderText.TextSize = 14
		SliderText.Font = Enum.Font.Gotham
		SliderText.TextXAlignment = Enum.TextXAlignment.Left

		local ValueLabel = Instance.new("TextLabel")
		ValueLabel.Parent = SliderFrame
		ValueLabel.BackgroundTransparency = 1
		ValueLabel.Size = UDim2.fromOffset(50, 25)
		ValueLabel.Position = UDim2.new(1, -60, 0, 5)
		ValueLabel.Text = tostring(defaultValue)
		ValueLabel.TextColor3 = Config.Theme.Text
		ValueLabel.TextSize = 14
		ValueLabel.Font = Enum.Font.GothamBold

		local SliderBg = Instance.new("Frame")
		SliderBg.Parent = SliderFrame
		SliderBg.Size = UDim2.new(1, -30, 0, 6)
		SliderBg.Position = UDim2.fromOffset(15, 40)
		SliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		SliderBg.BorderSizePixel = 0
		SliderBg.ClipsDescendants = true
		corner(SliderBg, 3)

		local Fill = Instance.new("Frame")
		Fill.Parent = SliderBg
		Fill.BackgroundColor3 = Config.Theme.Text
		Fill.BorderSizePixel = 0
		Fill.Size = UDim2.new((defaultValue - min) / (max - min), 0, 1, 0)
		corner(Fill, 3)

		local Knob = Instance.new("Frame")
		Knob.Parent = SliderBg
		Knob.Size = UDim2.fromOffset(16, 16)
		Knob.Position = UDim2.new((defaultValue - min) / (max - min), -8, 0, -5)
		Knob.BackgroundColor3 = Config.Theme.Text
		Knob.BorderSizePixel = 0
		corner(Knob, 8)

		local dragging = false
		local currentValue = defaultValue

		local function update(input: InputObject)
			local alpha = math.clamp(
				(input.Position.X - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X,
				0,
				1
			)

			local value = math.floor(min + (max - min) * alpha)
			currentValue = value

			tween(Fill, { Size = UDim2.new(alpha, 0, 1, 0) }, 0.08)
			tween(Knob, { Position = UDim2.new(alpha, -8, 0, -5) }, 0.08)
			ValueLabel.Text = tostring(value)

			if callback then
				local ok, err = pcall(callback, value)
				if not ok then
					warn("Slider callback error:", err)
				end
			end
		end

		SliderBg.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				update(input)
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				update(input)
			end
		end)

		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
			end
		end)

		if callback then
			task.defer(function()
				callback(currentValue)
			end)
		end

		return {
			Set = function(v: number)
				v = math.clamp(v, min, max)
				local alpha = (v - min) / (max - min)
				currentValue = v
				tween(Fill, { Size = UDim2.new(alpha, 0, 1, 0) }, 0.08)
				tween(Knob, { Position = UDim2.new(alpha, -8, 0, -5) }, 0.08)
				ValueLabel.Text = tostring(v)
				if callback then
					callback(v)
				end
			end,
			Get = function()
				return currentValue
			end,
		}
	end

	function TabData:AddTextBox(text: string, placeholder: string?, callback)
		local BoxFrame = Instance.new("Frame")
		BoxFrame.Parent = Content
		BoxFrame.Size = UDim2.new(1, 0, 0, 70)
		BoxFrame.BackgroundColor3 = Config.Theme.Secondary
		BoxFrame.BorderSizePixel = 0
		corner(BoxFrame, 8)
		addStroke(BoxFrame, 0.65)

		local Label = Instance.new("TextLabel")
		Label.Parent = BoxFrame
		Label.Size = UDim2.new(1, -20, 0, 25)
		Label.Position = UDim2.fromOffset(15, 5)
		Label.BackgroundTransparency = 1
		Label.Text = text
		Label.TextColor3 = Config.Theme.Text
		Label.TextSize = 14
		Label.Font = Enum.Font.Gotham
		Label.TextXAlignment = Enum.TextXAlignment.Left

		local TextBox = Instance.new("TextBox")
		TextBox.Parent = BoxFrame
		TextBox.Size = UDim2.new(1, -30, 0, 30)
		TextBox.Position = UDim2.fromOffset(15, 35)
		TextBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		TextBox.Text = ""
		TextBox.PlaceholderText = placeholder or "..."
		TextBox.TextColor3 = Config.Theme.Text
		TextBox.PlaceholderColor3 = Config.Theme.SubText
		TextBox.TextSize = 14
		TextBox.Font = Enum.Font.Gotham
		TextBox.ClearTextOnFocus = false
		TextBox.BorderSizePixel = 0
		corner(TextBox, 6)
		addStroke(TextBox, 0.8)

		TextBox.FocusLost:Connect(function(enterPressed)
			if callback and enterPressed then
				local ok, err = pcall(callback, TextBox.Text)
				if not ok then
					warn("Textbox callback error:", err)
				end
			end
		end)

		return TextBox
	end

	function TabData:AddDropdown(text: string, options: {string}, callback)
		local DropdownFrame = Instance.new("Frame")
		DropdownFrame.Parent = Content
		DropdownFrame.Size = UDim2.new(1, 0, 0, 40)
		DropdownFrame.BackgroundColor3 = Config.Theme.Secondary
		DropdownFrame.BorderSizePixel = 0
		DropdownFrame.ClipsDescendants = true
		corner(DropdownFrame, 8)
		addStroke(DropdownFrame, 0.65)

		local DropdownBtn = Instance.new("TextButton")
		DropdownBtn.Parent = DropdownFrame
		DropdownBtn.Size = UDim2.new(1, 0, 0, 40)
		DropdownBtn.BackgroundTransparency = 1
		DropdownBtn.Text = ""
		DropdownBtn.BorderSizePixel = 0
		DropdownBtn.ClipsDescendants = true
		DropdownBtn.AutoButtonColor = false

		local Label = Instance.new("TextLabel")
		Label.Parent = DropdownBtn
		Label.Size = UDim2.new(1, -50, 1, 0)
		Label.Position = UDim2.fromOffset(15, 0)
		Label.BackgroundTransparency = 1
		Label.Text = text
		Label.TextColor3 = Config.Theme.Text
		Label.TextSize = 14
		Label.Font = Enum.Font.Gotham
		Label.TextXAlignment = Enum.TextXAlignment.Left

		local Arrow = Instance.new("TextLabel")
		Arrow.Parent = DropdownBtn
		Arrow.Size = UDim2.fromOffset(30, 40)
		Arrow.Position = UDim2.new(1, -35, 0, 0)
		Arrow.BackgroundTransparency = 1
		Arrow.Text = "▼"
		Arrow.TextColor3 = Config.Theme.SubText
		Arrow.TextSize = 12
		Arrow.Font = Enum.Font.GothamBold

		local OptionsContainer = Instance.new("Frame")
		OptionsContainer.Parent = DropdownFrame
		OptionsContainer.BackgroundTransparency = 1
		OptionsContainer.Position = UDim2.fromOffset(10, 45)
		OptionsContainer.Size = UDim2.new(1, -20, 0, 0)
		OptionsContainer.ClipsDescendants = true

		local OptionsLayout = Instance.new("UIListLayout")
		OptionsLayout.Parent = OptionsContainer
		OptionsLayout.Padding = UDim.new(0, 4)
		OptionsLayout.SortOrder = Enum.SortOrder.LayoutOrder

		local opened = false
		local selected: string? = nil

		local function setOpen(state: boolean)
			opened = state
			local height = state and (50 + #options * 36) or 40
			tween(DropdownFrame, { Size = UDim2.new(1, 0, 0, height) }, 0.22)
			tween(Arrow, { Rotation = state and 180 or 0 }, 0.22)
		end

		for _, option in ipairs(options) do
			local OptionBtn = Instance.new("TextButton")
			OptionBtn.Parent = OptionsContainer
			OptionBtn.Size = UDim2.new(1, 0, 0, 32)
			OptionBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
			OptionBtn.Text = option
			OptionBtn.TextColor3 = Config.Theme.Text
			OptionBtn.TextSize = 13
			OptionBtn.Font = Enum.Font.Gotham
			OptionBtn.AutoButtonColor = false
			OptionBtn.BorderSizePixel = 0
			OptionBtn.ClipsDescendants = true
			corner(OptionBtn, 6)
			addStroke(OptionBtn, 0.8)

			OptionBtn.MouseEnter:Connect(function()
				tween(OptionBtn, { BackgroundColor3 = Color3.fromRGB(50, 50, 50) }, 0.15)
			end)

			OptionBtn.MouseLeave:Connect(function()
				tween(OptionBtn, { BackgroundColor3 = Color3.fromRGB(35, 35, 35) }, 0.15)
			end)

			OptionBtn.MouseButton1Click:Connect(function()
				ripple(OptionBtn)
				selected = option
				Label.Text = text .. ": " .. option
				if callback then
					local ok, err = pcall(callback, option)
					if not ok then
						warn("Dropdown callback error:", err)
					end
				end
				setOpen(false)
			end)
		end

		DropdownBtn.MouseButton1Click:Connect(function()
			ripple(DropdownBtn)
			setOpen(not opened)
		end)

		return {
			Set = function(v: string)
				selected = v
				Label.Text = text .. ": " .. v
			end,
			Get = function()
				return selected
			end,
			Toggle = function()
				setOpen(not opened)
			end,
		}
	end

	table.insert(Tabs, TabData)

	if #Tabs == 1 then
		Activate()
	end

	return TabData
end

CloseBtn.MouseEnter:Connect(function()
	tween(CloseBtn, { BackgroundColor3 = Color3.fromRGB(80, 80, 80) }, 0.15)
end)

CloseBtn.MouseLeave:Connect(function()
	tween(CloseBtn, { BackgroundColor3 = Color3.fromRGB(60, 60, 60) }, 0.15)
end)

CloseBtn.MouseButton1Click:Connect(function()
	ripple(CloseBtn)
	tween(MainFrame, { Size = UDim2.fromOffset(0, 0) }, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
	task.delay(0.27, function()
		if ScreenGui then
			ScreenGui:Destroy()
		end
		getgenv().StatusUI_Loaded = false
	end)
end)

MinimizeBtn.MouseEnter:Connect(function()
	tween(MinimizeBtn, { BackgroundColor3 = Color3.fromRGB(80, 80, 80) }, 0.15)
end)

MinimizeBtn.MouseLeave:Connect(function()
	tween(MinimizeBtn, { BackgroundColor3 = Color3.fromRGB(60, 60, 60) }, 0.15)
end)

MinimizeBtn.MouseButton1Click:Connect(function()
	ripple(MinimizeBtn)
	toggleUI()
end)

ToggleBtn.MouseButton1Click:Connect(function()
	ripple(ToggleBtn)
	toggleUI()
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.RightShift then
		toggleUI()
	end
end)

MainFrame.Visible = true
tween(MainFrame, { Size = DefaultSize }, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local Status = {
	CreateTab = CreateTab,
	Toggle = toggleUI,
}

-- Example
local Main = CreateTab("Main")
Main:AddButton("Test Button", function()
	print("Clicked!")
end)

Main:AddToggle("Test Toggle", false, function(v)
	print("Toggle:", v)
end)

Main:AddSlider("Test Slider", 0, 100, 50, function(v)
	print("Slider:", v)
end)

Main:AddTextBox("Test TextBox", "Type here...", function(text)
	print("Text:", text)
end)

Main:AddDropdown("Test Dropdown", { "One", "Two", "Three" }, function(option)
	print("Selected:", option)
end)

return Status
