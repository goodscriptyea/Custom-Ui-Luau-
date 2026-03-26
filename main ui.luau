local Nebula = loadstring(game:HttpGet("path_to_script"))()

-- Создание окна
local Window = Nebula:CreateWindow({
    Title = "NEBULA",
    SubTitle = "v2.0 | Premium",
    ToggleKey = Enum.KeyCode.RightShift -- Клавиша для скрытия/показа
})

-- Вкладки
local MainTab = Window:CreateTab("Main", "⚡")
local PlayerTab = Window:CreateTab("Player", "👤")
local VisualsTab = Window:CreateTab("Visuals", "👁️")
local MiscTab = Window:CreateTab("Misc", "⚙️")

-- Элементы
MainTab:AddButton("Auto Farm", function()
    print("Auto Farm Enabled!")
end)

MainTab:AddToggle("Speed Hack", false, function(value)
    print("Speed:", value)
end)

MainTab:AddSlider("WalkSpeed", 16, 500, 50, function(value)
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
end)

PlayerTab:AddButton("God Mode", function()
    print("God Mode activated")
end)
