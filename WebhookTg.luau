--// Status UI | Ripple Effect Edition + Telegram Integration
--// Click feedback animation + Telegram Notifications

if getgenv().StatusUI_Loaded then return end
getgenv().StatusUI_Loaded = true

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

--// Telegram Config
local TELEGRAM_ENABLED = false
local TELEGRAM_BOT_TOKEN = ""
local TELEGRAM_CHAT_ID = ""
local TELEGRAM_CHAT_IDS = {} -- Для нескольких аккаунтов
local GOLD_FARMED_TOTAL = 0
local PLAYER_NAME = LocalPlayer.Name or "Player"
local SCRIPT_START_TIME = tick()
local BOT_LOOP_RUNNING = false
local LAST_UPDATE_ID = 0

--// Helper Functions
local function Tween(obj, props, duration, style, dir)
    style = style or Enum.EasingStyle.Quart
    dir = dir or Enum.EasingDirection.Out
    local info = TweenInfo.new(duration or 0.3, style, dir)
    local tween = TweenService:Create(obj, info, props)
    tween:Play()
    return tween
end

--// Ripple Effect Function
local function Ripple(button, x, y)
    spawn(function()
        local ripple = Instance.new("Frame")
        ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ripple.BackgroundTransparency = 0.7
        ripple.BorderSizePixel = 0
        ripple.Position = UDim2.new(0, x - 5, 0, y - 5)
        ripple.Size = UDim2.new(0, 10, 0, 10)
        ripple.Parent = button
        ripple.ZIndex = button.ZIndex + 10
        
        local corner = Instance.new("UICorner", ripple)
        corner.CornerRadius = UDim.new(1, 0)
        
        Tween(ripple, {
            Size = UDim2.new(0, 200, 0, 200), 
            Position = UDim2.new(0, x - 100, 0, y - 100), 
            BackgroundTransparency = 1
        }, 0.6)
        
        wait(0.6)
        ripple:Destroy()
    end)
end

--// Telegram Functions
local function UrlEncode(str)
    str = tostring(str)
    str = str:gsub("\r\n", "\n")
    str = str:gsub("\r", "\n")
    
    local encoded = ""
    for i = 1, #str do
        local c = str:sub(i, i)
        local byte = string.byte(c)
        
        if (byte >= 48 and byte <= 57) or 
           (byte >= 65 and byte <= 90) or 
           (byte >= 97 and byte <= 122) or 
           c == "-" or c == "_" or c == "." or c == "~" then
            encoded = encoded .. c
        elseif c == "\n" then
            encoded = encoded .. "%0A"
        elseif c == " " then
            encoded = encoded .. "+"
        else
            encoded = encoded .. string.format("%%%02X", byte)
        end
    end
    return encoded
end

local function MakeHttpRequest(url)
    local response = nil
    local success = false
    
    if not success then
        pcall(function()
            if http_request then
                local r = http_request({ Url = url, Method = "GET" })
                if r and r.Body then
                    response = r.Body
                    success = true
                end
            end
        end)
    end
    
    if not success then
        pcall(function()
            if syn and syn.request then
                local r = syn.request({ Url = url, Method = "GET" })
                if r and r.Body then
                    response = r.Body
                    success = true
                end
            end
        end)
    end
    
    if not success then
        pcall(function()
            if request then
                local r = request({ Url = url, Method = "GET" })
                if r and r.Body then
                    response = r.Body
                    success = true
                end
            end
        end)
    end
    
    if not success then
        pcall(function()
            response = HttpService:GetAsync(url)
            success = true
        end)
    end
    
    return success, response
end

local function SendTelegramMessage(text)
    if not TELEGRAM_ENABLED or TELEGRAM_BOT_TOKEN == "" or TELEGRAM_CHAT_ID == "" then 
        return false 
    end
    
    local url = "https://api.telegram.org/bot" .. TELEGRAM_BOT_TOKEN .. "/sendMessage?chat_id=" .. UrlEncode(TELEGRAM_CHAT_ID) .. "&text=" .. UrlEncode(text)
    
    local success, response = MakeHttpRequest(url)
    
    if success and response then
        if response:find('"ok":true') then
            return true
        end
    end
    return false
end

local function CheckBotToken()
    if TELEGRAM_BOT_TOKEN == "" then
        return false, "Token is empty"
    end
    
    local url = "https://api.telegram.org/bot" .. TELEGRAM_BOT_TOKEN .. "/getMe"
    local success, response = MakeHttpRequest(url)
    
    if not success or not response then
        return false, "No HTTP methods available"
    end
    
    if response:find('"ok":true') then
        local botName = response:match('"username":"([^"]+)"')
        return true, "Bot OK: @" .. (botName or "unknown")
    elseif response:find('"error_code":401') then
        return false, "Invalid Bot Token (401)"
    else
        return false, "Unknown error"
    end
end

local function GetChatIdFromUpdates()
    if TELEGRAM_BOT_TOKEN == "" then
        return nil, "Bot token is empty!"
    end
    
    local url = "https://api.telegram.org/bot" .. TELEGRAM_BOT_TOKEN .. "/getUpdates?offset=-1"
    local success, response = MakeHttpRequest(url)
    
    if not success or not response then
        return nil, "HTTP request failed"
    end
    
    if response:find('"ok":true') then
        local chatId = response:match('"chat":{"id":([%-]?%d+)')
        if not chatId then
            chatId = response:match('"from":{"id":([%-]?%d+)')
        end
        
        if chatId then
            return chatId, "Success!"
        else
            return nil, "No messages found. Send /start to bot first!"
        end
    elseif response:find('"error_code":401') then
        return nil, "Invalid token!"
    else
        return nil, "API Error"
    end
end

local function FormatUptime()
    local elapsed = tick() - SCRIPT_START_TIME
    local hours = math.floor(elapsed / 3600)
    local minutes = math.floor((elapsed % 3600) / 60)
    local seconds = math.floor(elapsed % 60)
    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

--// Get Raw Gold Amount (from BoogaX)
local cachedRawGold = 0
local lastGoldCheck = 0

local function GetRawGoldAmount()
    local currentTime = tick()
    if currentTime - lastGoldCheck < 3 then
        return cachedRawGold
    end
    lastGoldCheck = currentTime
    
    local player = LocalPlayer
    if not player or not player.PlayerGui then 
        return 0
    end
    
    local totalRawGold = 0
    
    for _, element in ipairs(player.PlayerGui:GetDescendants()) do
        if (element:IsA("ImageButton") or element:IsA("ImageLabel") or element:IsA("Frame")) and element.Visible then
            local elementName = element.Name:lower()
            local isRawGold = false
            
            if (elementName:find("raw") and elementName:find("gold")) or elementName:find("rawgold") then
                isRawGold = true
            end
            
            if isRawGold then
                local amount = 0
                for _, child in ipairs(element:GetDescendants()) do
                    if child:IsA("TextLabel") and child.Visible then
                        local text = child.Text
                        if not text:lower():find("raw") and not text:lower():find("gold") then
                            local num = tonumber(text)
                            if num and num > 0 then
                                amount = num
                                break
                            end
                        end
                    end
                end
                if amount == 0 then amount = 1 end
                totalRawGold = totalRawGold + amount
            end
        end
    end
    
    cachedRawGold = totalRawGold
    return totalRawGold
end

--// Save/Load Settings
local function SaveTelegramSettings()
    local folderPath = "BoogaX"
    local filePath = folderPath .. "/telegram.json"
    
    local allChatIds = {}
    local existingBotToken = TELEGRAM_BOT_TOKEN
    
    pcall(function()
        if readfile then
            local content = readfile(filePath)
            if content and content ~= "" then
                local data = HttpService:JSONDecode(content)
                allChatIds = data.chat_ids or {}
                if TELEGRAM_BOT_TOKEN == "" and data.bot_token then
                    existingBotToken = tostring(data.bot_token)
                end
            end
        end
    end)
    
    if TELEGRAM_CHAT_ID ~= "" then
        local found = false
        for _, id in ipairs(allChatIds) do
            if tostring(id) == tostring(TELEGRAM_CHAT_ID) then
                found = true
                break
            end
        end
        if not found then
            table.insert(allChatIds, TELEGRAM_CHAT_ID)
        end
    end
    
    TELEGRAM_CHAT_IDS = allChatIds
    
    local data = {
        bot_token = existingBotToken,
        chat_id = TELEGRAM_CHAT_ID,
        chat_ids = allChatIds,
        enabled = TELEGRAM_ENABLED,
        gold_total = GOLD_FARMED_TOTAL,
    }
    
    pcall(function()
        if writefile then
            writefile(filePath, HttpService:JSONEncode(data))
        end
    end)
end

local function LoadTelegramSettings()
    local folderPath = "BoogaX"
    local filePath = folderPath .. "/telegram.json"
    
    pcall(function()
        if readfile then
            local content = readfile(filePath)
            if content and content ~= "" then
                local data = HttpService:JSONDecode(content)
                TELEGRAM_BOT_TOKEN = tostring(data.bot_token or "")
                TELEGRAM_CHAT_ID = tostring(data.chat_id or "")
                TELEGRAM_CHAT_IDS = data.chat_ids or {}
                TELEGRAM_ENABLED = data.enabled == true
                GOLD_FARMED_TOTAL = tonumber(data.gold_total or 0) or 0
            end
        end
    end)
end

--// Bot Command Handler
local function HandleTelegramCommand(message)
    if not message or not message.text then return end
    
    local text = message.text
    local chatId = tostring(message.chat.id)
    
    -- Get all chat IDs from file
    local allChatIds = {}
    pcall(function()
        if readfile then
            local content = readfile("BoogaX/telegram.json")
            if content and content ~= "" then
                local data = HttpService:JSONDecode(content)
                allChatIds = data.chat_ids or {}
            end
        end
    end)
    
    -- Check authorization
    local isAuthorized = false
    for _, id in ipairs(allChatIds) do
        if tostring(id) == chatId then
            isAuthorized = true
            break
        end
    end
    
    -- Allow /start for new users
    if text == "/start" and not isAuthorized then
        table.insert(allChatIds, chatId)
        pcall(function()
            if readfile and writefile then
                local content = readfile("BoogaX/telegram.json")
                local data = {}
                if content and content ~= "" then
                    data = HttpService:JSONDecode(content) or {}
                end
                data.chat_ids = allChatIds
                writefile("BoogaX/telegram.json", HttpService:JSONEncode(data))
            end
        end)
        isAuthorized = true
    end
    
    if not isAuthorized then return end

    if text == "/start" then
        local currentGold = GetRawGoldAmount()
        local msg = "🎮 *BoogaX Dashboard*\n\n"
        msg = msg .. "👤 Player: " .. PLAYER_NAME .. "\n"
        msg = msg .. "💰 Raw Gold: " .. currentGold .. "\n"
        msg = msg .. "⏰ Uptime: " .. FormatUptime() .. "\n\n"
        msg = msg .. "Commands:\n/start - Show status\n/gold - Check gold amount"
        
        local url = "https://api.telegram.org/bot" .. TELEGRAM_BOT_TOKEN .. "/sendMessage?chat_id=" .. UrlEncode(chatId) .. "&text=" .. UrlEncode(msg) .. "&parse_mode=Markdown"
        MakeHttpRequest(url)
    elseif text == "/gold" then
        local currentGold = GetRawGoldAmount()
        local msg = "💰 Current Raw Gold: " .. currentGold .. "\n👤 " .. PLAYER_NAME
        local url = "https://api.telegram.org/bot" .. TELEGRAM_BOT_TOKEN .. "/sendMessage?chat_id=" .. UrlEncode(chatId) .. "&text=" .. UrlEncode(msg)
        MakeHttpRequest(url)
    end
end

local function GetTelegramUpdates()
    if not TELEGRAM_ENABLED or TELEGRAM_BOT_TOKEN == "" then return nil end
    
    local offset = LAST_UPDATE_ID + 1
    local url = "https://api.telegram.org/bot" .. TELEGRAM_BOT_TOKEN .. "/getUpdates?offset=" .. tostring(offset) .. "&timeout=1"
    
    local success, response = MakeHttpRequest(url)
    
    if not success or not response then return nil end
    
    local decodeSuccess, data = pcall(function()
        return HttpService:JSONDecode(response)
    end)
    
    if decodeSuccess and data and data.ok and data.result then
        return data.result
    end
    
    return nil
end

local function StartTelegramBot()
    if not TELEGRAM_ENABLED or TELEGRAM_BOT_TOKEN == "" then return end
    if BOT_LOOP_RUNNING then return end
    
    BOT_LOOP_RUNNING = true
    
    -- Get last update ID
    task.spawn(function()
        local testUrl = "https://api.telegram.org/bot" .. TELEGRAM_BOT_TOKEN .. "/getUpdates?offset=-1&limit=1"
        local success, response = MakeHttpRequest(testUrl)
        if success and response then
            local decodeSuccess, data = pcall(function()
                return HttpService:JSONDecode(response)
            end)
            if decodeSuccess and data and data.ok and data.result and #data.result > 0 then
                LAST_UPDATE_ID = data.result[1].update_id
            end
        end
    end)
    
    -- Main loop
    task.spawn(function()
        task.wait(1)
        while TELEGRAM_ENABLED do
            local updates = GetTelegramUpdates()
            
            if updates then
                for _, update in ipairs(updates) do
                    if update.update_id then
                        LAST_UPDATE_ID = math.max(LAST_UPDATE_ID, update.update_id)
                    end
                    if update.message then
                        pcall(function()
                            HandleTelegramCommand(update.message)
                        end)
                    end
                end
            end
            
            task.wait(2)
        end
        BOT_LOOP_RUNNING = false
    end)
    
    -- Auto update account info
    task.spawn(function()
        while TELEGRAM_ENABLED do
            if TELEGRAM_CHAT_ID ~= "" then
                -- Update account info logic here if needed
            end
            task.wait(30)
        end
    end)
end

--// UI Creation Functions (Original Status UI)
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

--// Main UI Creation
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

local TitleText = Instance.new("TextLabel", TitleBar)
TitleText.Size = UDim2.new(1, -100, 1, 0)
TitleText.Position = UDim2.new(0, 20, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = Config.Title
TitleText.TextColor3 = Config.Theme.Text
TitleText.TextSize = 18
TitleText.Font = Enum.Font.GothamBold
TitleText.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 7)
CloseBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Config.Theme.Text
CloseBtn.TextSize = 18
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.AutoButtonColor = false
CloseBtn.ClipsDescendants = true

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
MinimizeBtn.ClipsDescendants = true

Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 8)

local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 160, 1, -45)
Sidebar.Position = UDim2.new(0, 0, 0, 45)
Sidebar.BackgroundColor3 = Config.Theme.Secondary
Sidebar.BackgroundTransparency = 0.5
Sidebar.BorderSizePixel = 0

local TabContainer = Instance.new("Frame", MainFrame)
TabContainer.Size = UDim2.new(1, -160, 1, -45)
TabContainer.Position = UDim2.new(0, 160, 0, 45)
TabContainer.BackgroundTransparency = 1

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
ToggleBtn.ClipsDescendants = true

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

--// Enhanced Tab Creation with Telegram Support
local function CreateTab(name)
    local TabBtn = Instance.new("TextButton", Sidebar)
    TabBtn.Size = UDim2.new(1, -20, 0, 40)
    TabBtn.Position = UDim2.new(0, 10, 0, 10 + (#Tabs * 50))
    TabBtn.BackgroundColor3 = Config.Theme.Secondary
    TabBtn.Text = ""
    TabBtn.AutoButtonColor = false
    TabBtn.ClipsDescendants = true
    
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
    
    TabBtn.MouseButton1Click:Connect(function(x, y)
        local mousePos = UserInputService:GetMouseLocation()
        local buttonPos = TabBtn.AbsolutePosition
        Ripple(TabBtn, mousePos.X - buttonPos.X, mousePos.Y - buttonPos.Y)
        Activate()
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
        
        AddButton = function(self, text, callback)
            local Btn = Instance.new("TextButton", Content)
            Btn.Size = UDim2.new(1, 0, 0, 40)
            Btn.BackgroundColor3 = Config.Theme.Secondary
            Btn.Text = text
            Btn.TextColor3 = Config.Theme.Text
            Btn.TextSize = 14
            Btn.Font = Enum.Font.Gotham
            Btn.AutoButtonColor = false
            Btn.ClipsDescendants = true
            
            Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)
            
            Btn.MouseButton1Click:Connect(function(x, y)
                local mousePos = UserInputService:GetMouseLocation()
                local buttonPos = Btn.AbsolutePosition
                Ripple(Btn, mousePos.X - buttonPos.X, mousePos.Y - buttonPos.Y)
                
                if callback then 
                    local success, err = pcall(callback)
                    if not success then print("Error:", err) end
                end
            end)
            
            Btn.MouseEnter:Connect(function()
                Tween(Btn, {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}, 0.2)
            end)
            
            Btn.MouseLeave:Connect(function()
                Tween(Btn, {BackgroundColor3 = Config.Theme.Secondary}, 0.2)
            end)
        end,
        
        AddToggle = function(self, text, default, callback)
            local ToggleFrame = Instance.new("Frame", Content)
            ToggleFrame.Size = UDim2.new(1, 0, 0, 40)
            ToggleFrame.BackgroundColor3 = Config.Theme.Secondary
            ToggleFrame.BorderSizePixel = 0
            ToggleFrame.ClipsDescendants = true
            
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
            
            local Switch = Instance.new("TextButton", ToggleFrame)
            Switch.Size = UDim2.new(0, 44, 0, 24)
            Switch.Position = UDim2.new(1, -60, 0.5, -12)
            Switch.BackgroundColor3 = default and Config.Theme.Text or Color3.fromRGB(60, 60, 60)
            Switch.Text = ""
            Switch.AutoButtonColor = false
            Switch.ClipsDescendants = true
            
            Instance.new("UICorner", Switch).CornerRadius = UDim.new(1, 0)
            
            local Circle = Instance.new("Frame", Switch)
            Circle.Size = UDim2.new(0, 18, 0, 18)
            Circle.Position = default and UDim2.new(1, -21, 0, 3) or UDim2.new(0, 3, 0, 3)
            Circle.BackgroundColor3 = Config.Theme.Background
            Circle.BorderSizePixel = 0
            
            Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)
            
            local Value = default
            
            Switch.MouseButton1Click:Connect(function()
                Ripple(Switch, 22, 12)
                
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
        
        AddTextBox = function(self, text, placeholder, callback, isPassword)
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
            
            if isPassword then
                TextBox.TextInputType = Enum.TextInputType.Password
            end
            
            Instance.new("UICorner", TextBox).CornerRadius = UDim.new(0, 6)
            
            TextBox.FocusLost:Connect(function(enterPressed)
                if callback then
                    pcall(function() callback(TextBox.Text) end)
                end
            end)
            
            return TextBox
        end,
        
        AddLabel = function(self, text)
            local Label = Instance.new("TextLabel", Content)
            Label.Size = UDim2.new(1, 0, 0, 20)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = Config.Theme.SubText
            Label.TextSize = 12
            Label.Font = Enum.Font.Gotham
            Label.TextXAlignment = Enum.TextXAlignment.Left
        end
    }
    
    table.insert(Tabs, TabData)
    if #Tabs == 1 then Activate() end
    return TabData
end

--// Event Handlers
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

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
        ToggleUI()
    end
end)

--// Create Tabs
local MainTab = CreateTab("Main")
local TelegramTab = CreateTab("Telegram")

--// Main Tab Content
MainTab:AddLabel("Welcome to Status UI")
MainTab:AddButton("Test Button", function() 
    print("Clicked!") 
end)
MainTab:AddToggle("Test Toggle", false, function(v) 
    print("Toggle:", v) 
end)

--// Telegram Tab Content
LoadTelegramSettings()

TelegramTab:AddLabel("📱 Telegram Bot Configuration")

local tokenBox = TelegramTab:AddTextBox("Bot Token", "Enter your bot token...", function(text)
    TELEGRAM_BOT_TOKEN = text
    SaveTelegramSettings()
end, true) -- true = password mode

if TELEGRAM_BOT_TOKEN ~= "" then
    tokenBox.Text = TELEGRAM_BOT_TOKEN
end

TelegramTab:AddButton("🔍 Check Token", function()
    local ok, msg = CheckBotToken()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Bot Check",
        Text = msg,
        Duration = 5
    })
end)

TelegramTab:AddButton("📱 Get Chat ID (send /start to bot first)", function()
    local chatId, msg = GetChatIdFromUpdates()
    if chatId then
        TELEGRAM_CHAT_ID = chatId
        SaveTelegramSettings()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Chat ID Found",
            Text = "Chat ID: " .. chatId,
            Duration = 5
        })
    else
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Error",
            Text = msg,
            Duration = 5
        })
    end
end)

TelegramTab:AddToggle("Enable Notifications", TELEGRAM_ENABLED, function(state)
    TELEGRAM_ENABLED = state
    SaveTelegramSettings()
    if state and TELEGRAM_BOT_TOKEN ~= "" then
        StartTelegramBot()
        if TELEGRAM_CHAT_ID ~= "" then
            SendTelegramMessage("✅ Telegram notifications enabled!\n👤 Player: " .. PLAYER_NAME)
        end
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Telegram",
            Text = "Bot started! Send /start to your bot",
            Duration = 3
        })
    end
end)

TelegramTab:AddButton("📤 Send Test Message", function()
    if SendTelegramMessage("🧪 Test message from " .. PLAYER_NAME .. "\n⏰ " .. FormatUptime()) then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Telegram",
            Text = "Test message sent!",
            Duration = 3
        })
    else
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Error",
            Text = "Failed to send message",
            Duration = 3
        })
    end
end)

TelegramTab:AddButton("💰 Send Gold Status", function()
    local gold = GetRawGoldAmount()
    if SendTelegramMessage("💰 Raw Gold: " .. gold .. "\n👤 " .. PLAYER_NAME .. "\n⏰ " .. FormatUptime()) then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Telegram",
            Text = "Gold status sent!",
            Duration = 3
        })
    end
end)

TelegramTab:AddLabel("Commands: /start, /gold")

--// Intro Animation
MainFrame.Visible = true
Tween(MainFrame, {Size = Config.Size}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

--// Auto-start bot if enabled
if TELEGRAM_ENABLED and TELEGRAM_BOT_TOKEN ~= "" then
    task.delay(2, function()
        StartTelegramBot()
    end)
end

--// Return
getgenv().StatusUI = {
    CreateTab = CreateTab,
    Toggle = ToggleUI,
    SendTelegramMessage = SendTelegramMessage,
    GetRawGoldAmount = GetRawGoldAmount
}
