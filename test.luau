--// Atlas Status UI | Working Edition
--// URL: https://raw.githubusercontent.com/goodscriptyea/Custom-Ui-Luau-/main/WebhookTg.luau

if getgenv().AtlasUI_Loaded then return end
getgenv().AtlasUI_Loaded = true

--// Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer

--// Config
local Config = {
    Title = "ATLAS STATUS",
    Size = UDim2.new(0, 600, 0, 400),
    Position = UDim2.new(0.5, -300, 0.5, -200),
    Theme = {
        Background = Color3.fromRGB(10, 10, 10),
        Secondary = Color3.fromRGB(20, 20, 20),
        Accent = Color3.fromRGB(255, 215, 0),
        Text = Color3.fromRGB(255, 255, 255),
        SubText = Color3.fromRGB(120, 120, 120)
    }
}

--// State
local TELEGRAM_ENABLED = false
local TELEGRAM_BOT_TOKEN = ""
local TELEGRAM_CHAT_ID = ""
local TELEGRAM_CHAT_IDS = {}
local SCRIPT_START_TIME = tick()
local BOT_LOOP_RUNNING = false
local LAST_UPDATE_ID = 0

--// Stats
local AtlasStats = {
    History = {},
    StartGold = 0,
    PeakGPH = 0
}

--// Helper: Format Numbers
local function FormatNumber(num)
    if not num then return "0" end
    if num >= 1000000000 then
        return string.format("%.2fB", num / 1000000000)
    elseif num >= 1000000 then
        return string.format("%.2fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    end
    return tostring(math.floor(num))
end

--// Helper: Format Time
local function FormatTime()
    local elapsed = tick() - SCRIPT_START_TIME
    local hrs = math.floor(elapsed / 3600)
    local mins = math.floor((elapsed % 3600) / 60)
    local secs = math.floor(elapsed % 60)
    return string.format("%02d:%02d:%02d", hrs, mins, secs)
end

--// Helper: URL Encode
local function UrlEncode(str)
    if not str then return "" end
    str = tostring(str)
    str = str:gsub("\r\n", "\n"):gsub("\r", "\n")
    local encoded = ""
    for i = 1, #str do
        local c = str:sub(i, i)
        local byte = string.byte(c)
        if (byte >= 48 and byte <= 57) or (byte >= 65 and byte <= 90) or (byte >= 97 and byte <= 122) or c == "-" or c == "_" or c == "." or c == "~" then
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

--// Helper: HTTP Request
local function HttpGet(url)
    local response = nil
    local success = false
    
    pcall(function()
        if syn and syn.request then
            local r = syn.request({Url = url, Method = "GET"})
            if r and r.Body then
                response = r.Body
                success = true
            end
        end
    end)
    
    if not success then
        pcall(function()
            if http_request then
                local r = http_request({Url = url, Method = "GET"})
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
                local r = request({Url = url, Method = "GET"})
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

--// Get Gold
local function GetGold()
    local player = LocalPlayer
    if not player or not player.PlayerGui then return 0 end
    
    local total = 0
    for _, element in ipairs(player.PlayerGui:GetDescendants()) do
        if element.Visible and (element:IsA("ImageButton") or element:IsA("ImageLabel") or element:IsA("Frame")) then
            local name = element.Name:lower()
            if (name:find("raw") and name:find("gold")) or name:find("rawgold") then
                local amount = 0
                for _, child in ipairs(element:GetDescendants()) do
                    if child:IsA("TextLabel") and child.Visible then
                        local text = child.Text:gsub(",", ""):gsub(" ", "")
                        local num = tonumber(text)
                        if num and num > 0 then
                            amount = num
                            break
                        end
                    end
                end
                total = total + (amount > 0 and amount or 0)
            end
        end
    end
    return total
end

--// Calculate GPH
local function CalculateGPH()
    if #AtlasStats.History < 2 then return 0 end
    local first = AtlasStats.History[1]
    local last = AtlasStats.History[#AtlasStats.History]
    local hours = (last.time - first.time) / 3600
    if hours <= 0 then return 0 end
    local gph = math.floor((last.gold - first.gold) / hours)
    if gph > AtlasStats.PeakGPH then
        AtlasStats.PeakGPH = gph
    end
    return gph
end

--// Generate Chart URL
local function GetChartURL()
    if #AtlasStats.History < 2 then return nil end
    
    local labels = {}
    local data = {}
    local step = math.max(1, math.floor(#AtlasStats.History / 10))
    
    for i = 1, #AtlasStats.History, step do
        local point = AtlasStats.History[i]
        table.insert(labels, tostring(math.floor((point.time - SCRIPT_START_TIME) / 60)) .. "m")
        table.insert(data, point.gold)
    end
    
    local last = AtlasStats.History[#AtlasStats.History]
    table.insert(labels, "now")
    table.insert(data, last.gold)
    
    local config = {
        type = "line",
        data = {
            labels = labels,
            datasets = {{
                label = "Gold",
                data = data,
                borderColor = "rgb(255, 215, 0)",
                backgroundColor = "rgba(255, 215, 0, 0.2)",
                borderWidth = 3,
                fill = true,
                tension = 0.4
            }}
        },
        options = {
            title = {
                display = true,
                text = "Gold Progress | " .. LocalPlayer.Name,
                fontColor = "#ffd700",
                fontSize = 18
            },
            legend = {display = false},
            scales = {
                yAxes = {{
                    ticks = {fontColor = "#ffffff"},
                    gridLines = {color = "rgba(255,255,255,0.1)"}
                }},
                xAxes = {{
                    ticks = {fontColor = "#ffffff"},
                    gridLines = {color = "rgba(255,255,255,0.05)"}
                }}
            },
            backgroundColor = "#0a0a0a"
        }
    }
    
    local json = HttpService:JSONEncode(config)
    return "https://quickchart.io/chart?c=" .. UrlEncode(json) .. "&w=800&h=400&f=png"
end

--// Telegram: Send Message
local function SendMsg(text)
    if not TELEGRAM_ENABLED or TELEGRAM_BOT_TOKEN == "" or TELEGRAM_CHAT_ID == "" then 
        return false 
    end
    
    local url = "https://api.telegram.org/bot" .. TELEGRAM_BOT_TOKEN .. "/sendMessage?chat_id=" .. UrlEncode(TELEGRAM_CHAT_ID) .. "&text=" .. UrlEncode(text) .. "&parse_mode=Markdown"
    local success, response = HttpGet(url)
    return success and response and response:find('"ok":true')
end

--// Telegram: Send Photo
local function SendPhoto(photoUrl, caption)
    if not TELEGRAM_ENABLED or TELEGRAM_BOT_TOKEN == "" or TELEGRAM_CHAT_ID == "" then 
        return false 
    end
    
    local url = "https://api.telegram.org/bot" .. TELEGRAM_BOT_TOKEN .. "/sendPhoto?chat_id=" .. UrlEncode(TELEGRAM_CHAT_ID) .. "&photo=" .. UrlEncode(photoUrl) .. "&caption=" .. UrlEncode(caption) .. "&parse_mode=Markdown"
    local success, response = HttpGet(url)
    
    if not success then
        SendMsg(caption .. "\n\n[Graph failed]")
    end
    return success
end

--// Send Full Report
local function SendReport()
    local current = GetGold()
    local gph = CalculateGPH()
    local earned = current - AtlasStats.StartGold
    
    local text = "📊 *ATLAS REPORT*\n\n"
    text = text .. "👤 Player: `" .. LocalPlayer.Name .. "`\n"
    text = text .. "⏱ Time: `" .. FormatTime() .. "`\n\n"
    text = text .. "💰 Gold: `" .. FormatNumber(current) .. "`\n"
    text = text .. "📈 Earned: `+" .. FormatNumber(earned) .. "`\n"
    text = text .. "⚡ GPH: `" .. FormatNumber(gph) .. "/h`\n"
    text = text .. "🏆 Peak: `" .. FormatNumber(AtlasStats.PeakGPH) .. "/h`\n\n"
    text = text .. "_Updated: " .. os.date("%H:%M:%S") .. "_"
    
    local chart = GetChartURL()
    if chart then
        SendPhoto(chart, text)
    else
        SendMsg(text)
    end
end

--// Check Bot Token
local function CheckToken()
    if TELEGRAM_BOT_TOKEN == "" then return false, "Empty token" end
    local url = "https://api.telegram.org/bot" .. TELEGRAM_BOT_TOKEN .. "/getMe"
    local success, response = HttpGet(url)
    if not success then return false, "HTTP Error" end
    if response:find('"ok":true') then
        local name = response:match('"username":"([^"]+)"')
        return true, "Bot: @" .. (name or "Unknown")
    elseif response:find('"error_code":401') then
        return false, "Invalid token"
    end
    return false, "Error"
end

--// Get Chat ID
local function GetChatID()
    if TELEGRAM_BOT_TOKEN == "" then return nil, "No token" end
    local url = "https://api.telegram.org/bot" .. TELEGRAM_BOT_TOKEN .. "/getUpdates?offset=-1"
    local success, response = HttpGet(url)
    if not success then return nil, "HTTP Error" end
    if response:find('"ok":true') then
        local id = response:match('"chat":{"id":([-%d]+)') or response:match('"from":{"id":([-%d]+)')
        if id then return id, "Success" end
        return nil, "Send /start to bot first"
    end
    return nil, "Invalid token"
end

--// Save/Load
local function SaveSettings()
    pcall(function()
        if not isfolder("AtlasUI") then
            makefolder("AtlasUI")
        end
        local data = {
            token = TELEGRAM_BOT_TOKEN,
            chat = TELEGRAM_CHAT_ID,
            chats = TELEGRAM_CHAT_IDS,
            enabled = TELEGRAM_ENABLED,
            startGold = AtlasStats.StartGold
        }
        writefile("AtlasUI/config.json", HttpService:JSONEncode(data))
    end)
end

local function LoadSettings()
    pcall(function()
        if readfile then
            local content = readfile("AtlasUI/config.json")
            if content then
                local data = HttpService:JSONDecode(content)
                TELEGRAM_BOT_TOKEN = data.token or ""
                TELEGRAM_CHAT_ID = data.chat or ""
                TELEGRAM_CHAT_IDS = data.chats or {}
                TELEGRAM_ENABLED = data.enabled or false
                AtlasStats.StartGold = data.startGold or 0
            end
        end
    end)
end

--// Bot Handler
local function HandleCommand(msg)
    if not msg or not msg.text then return end
    local text = msg.text
    local chatId = tostring(msg.chat.id)
    
    local authorized = false
    for _, id in ipairs(TELEGRAM_CHAT_IDS) do
        if tostring(id) == chatId then authorized = true break end
    end
    
    if text == "/start" and not authorized then
        table.insert(TELEGRAM_CHAT_IDS, chatId)
        SaveSettings()
        authorized = true
    end
    
    if not authorized then return end
    
    if text == "/start" then
        local gold = GetGold()
        local gph = CalculateGPH()
        local msgText = "🎮 *Atlas Dashboard*\n\nPlayer: `" .. LocalPlayer.Name .. "`\nGold: `" .. FormatNumber(gold) .. "`\nGPH: `" .. FormatNumber(gph) .. "/h`\n\nCommands:\n/start, /gold, /stats, /gph, /chart"
        local url = "https://api.telegram.org/bot" .. TELEGRAM_BOT_TOKEN .. "/sendMessage?chat_id=" .. UrlEncode(chatId) .. "&text=" .. UrlEncode(msgText) .. "&parse_mode=Markdown"
        HttpGet(url)
        
    elseif text == "/gold" then
        local gold = GetGold()
        local gph = CalculateGPH()
        local msgText = "💰 *Gold*\nAmount: `" .. FormatNumber(gold) .. "`\nGPH: `" .. FormatNumber(gph) .. "/h`"
        local url = "https://api.telegram.org/bot" .. TELEGRAM_BOT_TOKEN .. "/sendMessage?chat_id=" .. UrlEncode(chatId) .. "&text=" .. UrlEncode(msgText) .. "&parse_mode=Markdown"
        HttpGet(url)
        
    elseif text == "/stats" then
        SendReport()
        
    elseif text == "/gph" then
        local gph = CalculateGPH()
        local msgText = "⚡ *GPH*\nCurrent: `" .. FormatNumber(gph) .. "/h`\nPeak: `" .. FormatNumber(AtlasStats.PeakGPH) .. "/h`"
        local url = "https://api.telegram.org/bot" .. TELEGRAM_BOT_TOKEN .. "/sendMessage?chat_id=" .. UrlEncode(chatId) .. "&text=" .. UrlEncode(msgText) .. "&parse_mode=Markdown"
        HttpGet(url)
        
    elseif text == "/chart" then
        local chart = GetChartURL()
        if chart then
            local url = "https://api.telegram.org/bot" .. TELEGRAM_BOT_TOKEN .. "/sendPhoto?chat_id=" .. UrlEncode(chatId) .. "&photo=" .. UrlEncode(chart)
            HttpGet(url)
        end
    end
end

--// Start Bot
local function StartBot()
    if not TELEGRAM_ENABLED or TELEGRAM_BOT_TOKEN == "" or BOT_LOOP_RUNNING then return end
    BOT_LOOP_RUNNING = true
    
    task.spawn(function()
        while TELEGRAM_ENABLED do
            local offset = LAST_UPDATE_ID + 1
            local url = "https://api.telegram.org/bot" .. TELEGRAM_BOT_TOKEN .. "/getUpdates?offset=" .. tostring(offset) .. "&timeout=1"
            local success, response = HttpGet(url)
            
            if success and response then
                local ok, data = pcall(function() return HttpService:JSONDecode(response) end)
                if ok and data and data.ok and data.result then
                    for _, update in ipairs(data.result) do
                        if update.update_id then
                            LAST_UPDATE_ID = math.max(LAST_UPDATE_ID, update.update_id)
                        end
                        if update.message then
                            pcall(function() HandleCommand(update.message) end)
                        end
                    end
                end
            end
            
            task.wait(2)
        end
        BOT_LOOP_RUNNING = false
    end)
end

--// UI: Tween
local function Tween(obj, props, duration)
    TweenService:Create(obj, TweenInfo.new(duration or 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
end

--// UI: Ripple
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

--// UI: Draggable
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

local TitleText = Instance.new("TextLabel", TitleBar)
TitleText.Size = UDim2.new(1, -100, 1, 0)
TitleText.Position = UDim2.new(0, 20, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = Config.Title
TitleText.TextColor3 = Config.Theme.Accent
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
ToggleBtn.Text = "A"
ToggleBtn.TextColor3 = Config.Theme.Accent
ToggleBtn.TextSize = 20
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Visible = false
ToggleBtn.Active = true
ToggleBtn.Draggable = true
ToggleBtn.ClipsDescendants = true
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)

MakeDraggable(TitleBar, MainFrame)

local Tabs = {}
local ActiveTab = nil
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
        Tween(MainFrame, {Size = Config.Size}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        wait(0.4)
        ToggleBtn.Visible = false
    end
end

--// Tab Creation
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
                    pcall(callback)
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
            local Frame = Instance.new("Frame", Content)
            Frame.Size = UDim2.new(1, 0, 0, 40)
            Frame.BackgroundColor3 = Config.Theme.Secondary
            Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)
            
            local Label = Instance.new("TextLabel", Frame)
            Label.Size = UDim2.new(1, -70, 1, 0)
            Label.Position = UDim2.new(0, 15, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = Config.Theme.Text
            Label.TextSize = 14
            Label.Font = Enum.Font.Gotham
            Label.TextXAlignment = Enum.TextXAlignment.Left
            
            local Switch = Instance.new("TextButton", Frame)
            Switch.Size = UDim2.new(0, 44, 0, 24)
            Switch.Position = UDim2.new(1, -60, 0.5, -12)
            Switch.BackgroundColor3 = default and Config.Theme.Accent or Color3.fromRGB(60, 60, 60)
            Switch.Text = ""
            Instance.new("UICorner", Switch).CornerRadius = UDim.new(1, 0)
            
            local Circle = Instance.new("Frame", Switch)
            Circle.Size = UDim2.new(0, 18, 0, 18)
            Circle.Position = default and UDim2.new(1, -21, 0, 3) or UDim2.new(0, 3, 0, 3)
            Circle.BackgroundColor3 = Config.Theme.Background
            Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)
            
            local Value = default
            
            Switch.MouseButton1Click:Connect(function()
                Value = not Value
                Tween(Circle, {Position = Value and UDim2.new(1, -21, 0, 3) or UDim2.new(0, 3, 0, 3)}, 0.3)
                Tween(Switch, {BackgroundColor3 = Value and Config.Theme.Accent or Color3.fromRGB(60, 60, 60)}, 0.3)
                if callback then
                    pcall(function() callback(Value) end)
                end
            end)
        end,
        
        AddTextBox = function(self, text, placeholder, callback, isPassword)
            local BoxFrame = Instance.new("Frame", Content)
            BoxFrame.Size = UDim2.new(1, 0, 0, 70)
            BoxFrame.BackgroundColor3 = Config.Theme.Secondary
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
            if isPassword then
                TextBox.TextInputType = Enum.TextInputType.Password
            end
            Instance.new("UICorner", TextBox).CornerRadius = UDim.new(0, 6)
            
            TextBox.FocusLost:Connect(function()
                if callback then
                    pcall(function() callback(TextBox.Text) end)
                end
            end)
            
            return TextBox
        end,
        
        AddLabel = function(self, text, color)
            local Label = Instance.new("TextLabel", Content)
            Label.Size = UDim2.new(1, 0, 0, 20)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = color or Config.Theme.SubText
            Label.TextSize = 12
            Label.Font = Enum.Font.Gotham
            Label.TextXAlignment = Enum.TextXAlignment.Left
            return Label
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
    Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
    wait(0.3)
    ScreenGui:Destroy()
    getgenv().AtlasUI_Loaded = false
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

--// Load Settings
LoadSettings()
if AtlasStats.StartGold == 0 then
    AtlasStats.StartGold = GetGold()
end

--// Create Tabs
local StatsTab = CreateTab("Statistics")
local TelegramTab = CreateTab("Telegram")

--// Stats Tab
StatsTab:AddLabel("📊 Gold Tracking", Config.Theme.Accent)
local GphLabel = StatsTab:AddLabel("⚡ GPH: Calculating...")
local PeakLabel = StatsTab:AddLabel("🏆 Peak: 0")
local EarnedLabel = StatsTab:AddLabel("📈 Earned: 0")

StatsTab:AddButton("🔄 Refresh", function()
    local current = GetGold()
    local gph = CalculateGPH()
    local earned = current - AtlasStats.StartGold
    GphLabel.Text = "⚡ GPH: " .. FormatNumber(gph) .. "/h"
    PeakLabel.Text = "🏆 Peak: " .. FormatNumber(AtlasStats.PeakGPH) .. "/h"
    EarnedLabel.Text = "📈 Earned: " .. FormatNumber(earned)
end)

StatsTab:AddButton("📤 Send Report", function()
    if TELEGRAM_ENABLED then
        SendReport()
        StarterGui:SetCore("SendNotification", {Title = "Atlas", Text = "Report sent!", Duration = 3})
    else
        StarterGui:SetCore("SendNotification", {Title = "Error", Text = "Enable Telegram first!", Duration = 3})
    end
end)

StatsTab:AddButton("🗑️ Reset", function()
    AtlasStats.History = {}
    AtlasStats.StartGold = GetGold()
    AtlasStats.PeakGPH = 0
    StarterGui:SetCore("SendNotification", {Title = "Atlas", Text = "Reset!", Duration = 2})
end)

--// Telegram Tab
TelegramTab:AddLabel("📱 Configuration", Config.Theme.Accent)

local tokenBox = TelegramTab:AddTextBox("Bot Token", "Enter token...", function(text)
    TELEGRAM_BOT_TOKEN = text
    SaveSettings()
end, true)

if TELEGRAM_BOT_TOKEN ~= "" then
    tokenBox.Text = TELEGRAM_BOT_TOKEN
end

TelegramTab:AddButton("🔍 Check Token", function()
    local ok, msg = CheckToken()
    StarterGui:SetCore("SendNotification", {Title = "Bot", Text = msg, Duration = 5})
end)

TelegramTab:AddButton("📱 Get Chat ID", function()
    local id, msg = GetChatID()
    if id then
        TELEGRAM_CHAT_ID = id
        SaveSettings()
        StarterGui:SetCore("SendNotification", {Title = "Chat ID", Text = id, Duration = 5})
    else
        StarterGui:SetCore("SendNotification", {Title = "Error", Text = msg, Duration = 5})
    end
end)

TelegramTab:AddToggle("Enable Bot", TELEGRAM_ENABLED, function(state)
    TELEGRAM_ENABLED = state
    SaveSettings()
    if state and TELEGRAM_BOT_TOKEN ~= "" then
        StartBot()
        if TELEGRAM_CHAT_ID ~= "" then
            SendMsg("✅ *Atlas Connected!*\nPlayer: `" .. LocalPlayer.Name .. "`")
        end
        StarterGui:SetCore("SendNotification", {Title = "Telegram", Text = "Started!", Duration = 3})
    end
end)

TelegramTab:AddButton("📤 Test", function()
    if SendMsg("🧪 Test from Atlas") then
        StarterGui:SetCore("SendNotification", {Title = "Telegram", Text = "Sent!", Duration = 3})
    else
        StarterGui:SetCore("SendNotification", {Title = "Error", Text = "Failed!", Duration = 3})
    end
end)

TelegramTab:AddLabel("Commands: /start, /gold, /stats, /gph, /chart")

--// Data Collection
task.spawn(function()
    while true do
        task.wait(300) -- 5 min
        local current = GetGold()
        table.insert(AtlasStats.History, {
            time = tick(),
            gold = current
        })
        if #AtlasStats.History > 50 then
            table.remove(AtlasStats.History, 1)
        end
        CalculateGPH()
    end
end)

--// Auto-start
if TELEGRAM_ENABLED and TELEGRAM_BOT_TOKEN ~= "" then
    task.delay(2, StartBot)
end

--// Show UI
MainFrame.Visible = true
Tween(MainFrame, {Size = Config.Size}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

print("✅ Atlas UI Loaded!")
print("Commands: /stats for graph report")

getgenv().AtlasUI = {
    SendReport = SendReport,
    GetGPH = CalculateGPH,
    GetGold = GetGold
}
