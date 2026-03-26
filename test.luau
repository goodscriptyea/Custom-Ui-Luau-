--// Atlas Status UI | Bugfix Edition
--// Исправлены: Visible not valid, nil value errors

if getgenv().AtlasUI_Loaded then return end
getgenv().AtlasUI_Loaded = true

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
    if not num or type(num) ~= "number" then return "0" end
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
    if not url then return false, nil end
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

--// Get Gold - с проверками на nil
local function GetGold()
    local player = LocalPlayer
    if not player or not player:FindFirstChild("PlayerGui") then return 0 end
    
    local total = 0
    local playerGui = player.PlayerGui
    
    for _, element in ipairs(playerGui:GetDescendants()) do
        if element and element:IsA("GuiObject") then
            local success, isVisible = pcall(function() return element.Visible end)
            if success and isVisible then
                if element:IsA("ImageButton") or element:IsA("ImageLabel") or element:IsA("Frame") then
                    local name = element.Name:lower()
                    if (name:find("raw") and name:find("gold")) or name:find("rawgold") then
                        local amount = 0
                        for _, child in ipairs(element:GetDescendants()) do
                            if child and child:IsA("TextLabel") then
                                local success2, childVisible = pcall(function() return child.Visible end)
                                if success2 and childVisible then
                                    local success3, text = pcall(function() return child.Text end)
                                    if success3 and text then
                                        local cleanText = text:gsub(",", ""):gsub(" ", "")
                                        local num = tonumber(cleanText)
                                        if num and num > 0 then
                                            amount = num
                                            break
                                        end
                                    end
                                end
                            end
                        end
                        total = total + amount
                    end
                end
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
    if not first or not last then return 0 end
    
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
        if point then
            table.insert(labels, tostring(math.floor((point.time - SCRIPT_START_TIME) / 60)) .. "m")
            table.insert(data, point.gold)
        end
    end
    
    local last = AtlasStats.History[#AtlasStats.History]
    if last then
        table.insert(labels, "now")
        table.insert(data, last.gold)
    end
    
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
    
    local success, json = pcall(function() return HttpService:JSONEncode(config) end)
    if not success then return nil end
    
    return "https://quickchart.io/chart?c=" .. UrlEncode(json) .. "&w=800&h=400&f=png"
end

--// Telegram Functions
local function SendMsg(text)
    if not TELEGRAM_ENABLED or TELEGRAM_BOT_TOKEN == "" or TELEGRAM_CHAT_ID == "" then 
        return false 
    end
    
    local url = "https://api.telegram.org/bot" .. TELEGRAM_BOT_TOKEN .. "/sendMessage?chat_id=" .. UrlEncode(TELEGRAM_CHAT_ID) .. "&text=" .. UrlEncode(text) .. "&parse_mode=Markdown"
    local success, response = HttpGet(url)
    return success and response and response:find('"ok":true')
end

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

local function CheckToken()
    if TELEGRAM_BOT_TOKEN == "" then return false, "Empty token" end
    local url = "https://api.telegram.org/bot" .. TELEGRAM_BOT_TOKEN .. "/getMe"
    local success, response = HttpGet(url)
    if not success then return false, "HTTP Error" end
    if response and response:find('"ok":true') then
        local name = response:match('"username":"([^"]+)"')
        return true, "Bot: @" .. (name or "Unknown")
    elseif response and response:find('"error_code":401') then
        return false, "Invalid token"
    end
    return false, "Error"
end

local function GetChatID()
    if TELEGRAM_BOT_TOKEN == "" then return nil, "No token" end
    local url = "https://api.telegram.org/bot" .. TELEGRAM_BOT_TOKEN .. "/getUpdates?offset=-1"
    local success, response = HttpGet(url)
    if not success then return nil, "HTTP Error" end
    if response and response:find('"ok":true') then
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
    local chat = msg.chat
    if not chat then return end
    
    local chatId = tostring(chat.id)
    
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

--// UI Functions
local function Tween(obj, props, duration)
    if not obj or not obj.Parent then return end
    pcall(function()
        TweenService:Create(obj, TweenInfo.new(duration or 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
    end)
end

local function Ripple(button, x, y)
    if not button or not button.Parent then return end
    spawn(function()
        local success, ripple = pcall(function()
            local r = Instance.new("Frame")
            r.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            r.BackgroundTransparency = 0.7
            r.BorderSizePixel = 0
            r.Position = UDim2.new(0, x - 5, 0, y - 5)
            r.Size = UDim2.new(0, 10, 0, 10)
            r.Parent = button
            r.ZIndex = button.ZIndex + 10
            return r
        end)
        
        if not success or not ripple then return end
        
        pcall(function()
            local corner = Instance.new("UICorner", ripple)
            corner.CornerRadius = UDim.new(1, 0)
        end)
        
        pcall(function()
            Tween(ripple, {
                Size = UDim2.new(0, 200, 0, 200), 
                Position = UDim2.new(0, x - 100, 0, y - 100), 
                BackgroundTransparency = 1
            }, 0.6)
        end)
        
        wait(0.6)
        pcall(function() ripple:Destroy() end)
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

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 45)
TitleBar.BackgroundColor3 = Config.Theme.Secondary
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleText = Instance.new("TextLabel")
TitleText.Name = "Title"
TitleText.Size = UDim2.new(1, -100, 1, 0)
TitleText.Position = UDim2.new(0, 20, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = Config.Title
TitleText.TextColor3 = Config.Theme.Accent
TitleText.TextSize = 18
TitleText.Font = Enum.Font.GothamBold
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "Close"
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 7)
CloseBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Config.Theme.Text
CloseBtn.TextSize = 18
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.AutoButtonColor = false
CloseBtn.ClipsDescendants = true
CloseBtn.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseBtn

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name = "Minimize"
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -75, 0, 7)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
MinimizeBtn.Text = "−"
MinimizeBtn.TextColor3 = Config.Theme.Text
MinimizeBtn.TextSize = 18
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.AutoButtonColor = false
MinimizeBtn.ClipsDescendants = true
MinimizeBtn.Parent = TitleBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 8)
MinCorner.Parent = MinimizeBtn

local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 160, 1, -45)
Sidebar.Position = UDim2.new(0, 0, 0, 45)
Sidebar.BackgroundColor3 = Config.Theme.Secondary
Sidebar.BackgroundTransparency = 0.5
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.Size = UDim2.new(1, -160, 1, -45)
TabContainer.Position = UDim2.new(0, 160, 0, 45)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "Toggle"
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
ToggleBtn.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleBtn

--// Draggable
local function MakeDraggable(topbar, frame)
    if not topbar or not frame then return end
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
            pcall(function()
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

MakeDraggable(TitleBar, MainFrame)

local Tabs = {}
local ActiveTab = nil
local Minimized = false

local function ToggleUI()
    Minimized = not Minimized
    if Minimized then
        ToggleBtn.Visible = true
        Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.4)
        wait(0.4)
        MainFrame.Visible = false
    else
        MainFrame.Visible = true
        Tween(MainFrame, {Size = Config.Size}, 0.4)
        wait(0.4)
        ToggleBtn.Visible = false
    end
end

--// Tab Creation
local function CreateTab(name)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(1, -20, 0, 40)
    TabBtn.Position = UDim2.new(0, 10, 0, 10 + (#Tabs * 50))
    TabBtn.BackgroundColor3 = Config.Theme.Secondary
    TabBtn.Text = ""
    TabBtn.AutoButtonColor = false
    TabBtn.ClipsDescendants = true
    TabBtn.Parent = Sidebar
    
    local TabCorner = Instance.new("UICorner")
    TabCorner.CornerRadius = UDim.new(0, 8)
    TabCorner.Parent = TabBtn
    
    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 3, 0, 20)
    Indicator.Position = UDim2.new(0, 0, 0.5, -10)
    Indicator.BackgroundColor3 = Config.Theme.Accent
    Indicator.Visible = false
    Indicator.Parent = TabBtn
    
    local IndCorner = Instance.new("UICorner")
    IndCorner.CornerRadius = UDim.new(0, 2)
    IndCorner.Parent = Indicator
    
    local TabText = Instance.new("TextLabel")
    TabText.Size = UDim2.new(1, -20, 1, 0)
    TabText.Position = UDim2.new(0, 15, 0, 0)
    TabText.BackgroundTransparency = 1
    TabText.Text = name
    TabText.TextColor3 = Config.Theme.SubText
    TabText.TextSize = 14
    TabText.Font = Enum.Font.GothamSemibold
    TabText.TextXAlignment = Enum.TextXAlignment.Left
    TabText.Parent = TabBtn
    
    local Content = Instance.new("ScrollingFrame")
    Content.Name = name .. "Content"
    Content.Size = UDim2.new(1, -20, 1, -20)
    Content.Position = UDim2.new(0, 10, 0, 10)
    Content.BackgroundTransparency = 1
    Content.ScrollBarThickness = 3
    Content.ScrollBarImageColor3 = Config.Theme.Accent
    Content.Visible = false
    Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Content.Parent = TabContainer
    
    local UIList = Instance.new("UIListLayout")
    UIList.Padding = UDim.new(0, 10)
    UIList.Parent = Content
    
    local function Activate()
        if ActiveTab == Content then return end
        if ActiveTab then ActiveTab.Visible = false end
        
        for _, tab in pairs(Tabs) do
            if tab.Indicator and tab.Indicator.Parent then
                tab.Indicator.Visible = false
            end
            if tab.Button and tab.Button.Parent then
                Tween(tab.Button, {BackgroundColor3 = Config.Theme.Secondary}, 0.2)
            end
            if tab.Text and tab.Text.Parent then
                tab.Text.TextColor3 = Config.Theme.SubText
            end
        end
        
        ActiveTab = Content
        Content.Visible = true
        Indicator.Visible = true
        Tween(TabBtn, {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}, 0.3)
        TabText.TextColor3 = Config.Theme.Text
    end
    
    TabBtn.MouseButton1Click:Connect(function()
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
            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, 0, 0, 40)
            Btn.BackgroundColor3 = Config.Theme.Secondary
            Btn.Text = text
            Btn.TextColor3 = Config.Theme.Text
            Btn.TextSize = 14
            Btn.Font = Enum.Font.Gotham
            Btn.AutoButtonColor = false
            Btn.ClipsDescendants = true
            Btn.Parent = Content
            
            local BtnCorner = Instance.new("UICorner")
            BtnCorner.CornerRadius = UDim.new(0, 8)
            BtnCorner.Parent = Btn
            
            Btn.MouseButton1Click:Connect(function()
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
            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, 0, 0, 40)
            Frame.BackgroundColor3 = Config.Theme.Secondary
            Frame.Parent = Content
            
            local FrameCorner = Instance.new("UICorner")
            FrameCorner.CornerRadius = UDim.new(0, 8)
            FrameCorner.Parent = Frame
            
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -70, 1, 0)
            Label.Position = UDim2.new(0, 15, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = Config.Theme.Text
            Label.TextSize = 14
            Label.Font = Enum.Font.Gotham
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Frame
            
            local Switch = Instance.new("TextButton")
            Switch.Size = UDim2.new(0, 44, 0, 24)
            Switch.Position = UDim2.new(1, -60, 0.5, -12)
            Switch.BackgroundColor3 = default and Config.Theme.Accent or Color3.fromRGB(60, 60, 60)
            Switch.Text = ""
            Switch.Parent = Frame
            
            local SwitchCorner = Instance.new("UICorner")
            SwitchCorner.CornerRadius = UDim.new(1, 0)
            SwitchCorner.Parent = Switch
            
            local Circle = Instance.new("Frame")
            Circle.Size = UDim2.new(0, 18, 0, 18)
            Circle.Position = default and UDim2.new(1, -21, 0, 3) or UDim2.new(0, 3, 0, 3)
            Circle.BackgroundColor3 = Config.Theme.Background
            Circle.Parent = Switch
            
            local CircleCorner = Instance.new("UICorner")
            CircleCorner.CornerRadius = UDim.new(1, 0)
            CircleCorner.Parent = Circle
            
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
            local BoxFrame = Instance.new("Frame")
            BoxFrame.Size = UDim2.new(1, 0, 0, 70)
            BoxFrame.BackgroundColor3 = Config.Theme.Secondary
            BoxFrame.Parent = Content
            
            local BoxCorner = Instance.new("UICorner")
            BoxCorner.CornerRadius = UDim.new(0, 8)
            BoxCorner.Parent = BoxFrame
            
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -20, 0, 25)
            Label.Position = UDim2.new(0, 15, 0, 5)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = Config.Theme.Text
            Label.TextSize = 14
            Label.Font = Enum.Font.Gotham
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = BoxFrame
            
            local TextBox = Instance.new("TextBox")
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
            TextBox.Parent = BoxFrame
            
            local TBCorner = Instance.new("UICorner")
            TBCorner.CornerRadius = UDim.new(0, 6)
            TBCorner.Parent = TextBox
            
            TextBox.FocusLost:Connect(function()
                if callback then
                    pcall(function() callback(TextBox.Text) end)
                end
            end)
            
            return TextBox
        end,
        
        AddLabel = function(self, text, color)
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, 0, 0, 20)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = color or Config.Theme.SubText
            Label.TextSize = 12
            Label.Font = Enum.Font.Gotham
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Content
            return Label
        end
    }
    
    table.insert(Tabs, TabData)
    if #Tabs == 1 then Activate() end
    return TabData
end

--// Event Handlers
CloseBtn.MouseEnter:Connect(function() 
    Tween(CloseBtn, {BackgroundColor3 = Color3.fromRGB(80, 80, 80)}, 0.2) 
end)

CloseBtn.MouseLeave:Connect(function() 
    Tween(CloseBtn, {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}, 0.2) 
end)

CloseBtn.MouseButton1Click:Connect(function()
    Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
    wait(0.3)
    pcall(function() ScreenGui:Destroy() end)
    getgenv().AtlasUI_Loaded = false
end)

MinimizeBtn.MouseEnter:Connect(function() 
    Tween(MinimizeBtn, {BackgroundColor3 = Color3.fromRGB(80, 80, 80)}, 0.2) 
end)

MinimizeBtn.MouseLeave:Connect(function() 
    Tween(MinimizeBtn, {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}, 0.2) 
end)

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
            SendMsg("✅ *Atlas Connected!*")
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
        task.wait(300)
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
Tween(MainFrame, {Size = Config.Size}, 0.5)

print("✅ Atlas UI Loaded!")

getgenv().AtlasUI = {
    SendReport = SendReport,
    GetGPH = CalculateGPH,
    GetGold = GetGold
}
