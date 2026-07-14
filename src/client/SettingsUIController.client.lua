-- StarterPlayer/StarterPlayerScripts/SettingsUIController.client.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local SetCustomKeybindsEvent = Remotes:WaitForChild("SetCustomKeybinds")
local RequestPlayerDataFunc = Remotes:WaitForChild("RequestPlayerData")
local GameSettings = require(ReplicatedStorage:WaitForChild("GameSettings"))

-- Отримуємо збережені налаштування
local currentKeybinds = { "X", "C", "N", "M" }
local function loadKeybinds()
	local success, data = pcall(function()
		return RequestPlayerDataFunc:InvokeServer()
	end)
	if success and data and data.Keybinds then
		currentKeybinds = data.Keybinds
	end
end
loadKeybinds()

-- Очищаємо попередній UI якщо є
local oldUI = PlayerGui:FindFirstChild("SettingsUI")
if oldUI then oldUI:Destroy() end

-- Створюємо ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SettingsUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

-- Кнопка налаштувань (зліва зверху) - Темно-білий стиль
local openButton = Instance.new("TextButton")
openButton.Name = "OpenButton"
openButton.Size = UDim2.new(0, 45, 0, 45)
openButton.Position = UDim2.new(0, 15, 0, 15)
openButton.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
openButton.BackgroundTransparency = 0.4
openButton.Text = "⚙️"
openButton.TextColor3 = Color3.fromRGB(220, 220, 220)
openButton.TextSize = 24
openButton.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
openButton.Parent = screenGui

local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(0.5, 0)
openCorner.Parent = openButton

local openStroke = Instance.new("UIStroke")
openStroke.Color = Color3.fromRGB(180, 180, 180) -- Сірий контур
openStroke.Thickness = 1.2
openStroke.Parent = openButton

-- Анімація наведення на кнопку
openButton.MouseEnter:Connect(function()
	TweenService:Create(openButton, TweenInfo.new(0.2), {BackgroundTransparency = 0.2, TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
	TweenService:Create(openStroke, TweenInfo.new(0.2), {Thickness = 2.0, Color = Color3.fromRGB(240, 240, 240)}):Play()
end)
openButton.MouseLeave:Connect(function()
	TweenService:Create(openButton, TweenInfo.new(0.2), {BackgroundTransparency = 0.4, TextColor3 = Color3.fromRGB(220, 220, 220)}):Play()
	TweenService:Create(openStroke, TweenInfo.new(0.2), {Thickness = 1.2, Color = Color3.fromRGB(180, 180, 180)}):Play()
end)

-- Панель налаштувань (центр) - Мінімалістичний темно-білий стиль
local panel = Instance.new("Frame")
panel.Name = "SettingsPanel"
panel.Size = UDim2.new(0, 360, 0, 420)
panel.Position = UDim2.new(0.5, -180, 0.5, -210)
panel.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
panel.BackgroundTransparency = 0.2
panel.Visible = false
panel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 10)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(150, 150, 150) -- Чистий сірий/срібний контур
panelStroke.Thickness = 2
panelStroke.Parent = panel

-- Заголовок
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.Position = UDim2.new(0, 0, 0, 10)
title.BackgroundTransparency = 1
title.Text = "KEYBINDS SETTINGS"
title.TextColor3 = Color3.fromRGB(240, 240, 240)
title.TextSize = 20
title.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
title.Parent = panel

-- Кнопка закриття
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -40, 0, 10)
closeButton.BackgroundTransparency = 1
closeButton.Text = "✕"
closeButton.TextColor3 = Color3.fromRGB(130, 130, 130)
closeButton.TextSize = 20
closeButton.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
closeButton.Parent = panel

closeButton.MouseEnter:Connect(function()
	closeButton.TextColor3 = Color3.fromRGB(240, 240, 240)
end)
closeButton.MouseLeave:Connect(function()
	closeButton.TextColor3 = Color3.fromRGB(130, 130, 130)
end)
closeButton.MouseButton1Click:Connect(function()
	panel.Visible = false
end)

openButton.MouseButton1Click:Connect(function()
	panel.Visible = not panel.Visible
	if panel.Visible then
		loadKeybinds()
	end
end)

-- Доріжки та налаштування бінду
local laneNames = { "Lane 1 (Left)", "Lane 2", "Lane 3", "Lane 4 (Right)" }
local bindButtons = {}
local isBinding = nil

local TrackColors = {
	Color3.fromRGB(240, 240, 240),
	Color3.fromRGB(200, 200, 200),
	Color3.fromRGB(160, 160, 160),
	Color3.fromRGB(120, 120, 120)
}

-- Функція оновлення відображення кнопок
local function refreshBindTexts()
	for i = 1, 4 do
		bindButtons[i].Text = currentKeybinds[i]
		bindButtons[i].TextColor3 = Color3.fromRGB(240, 240, 240)
	end
end

for i = 1, 4 do
	local container = Instance.new("Frame")
	container.Size = UDim2.new(0.9, 0, 0, 60)
	container.Position = UDim2.new(0.05, 0, 0, 60 + (i - 1) * 70)
	container.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	container.BackgroundTransparency = 0.6
	container.BorderSizePixel = 0
	container.Parent = panel
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = container
	
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(0.5, 0, 1, 0)
	textLabel.Position = UDim2.new(0.05, 0, 0, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = laneNames[i]
	textLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	textLabel.TextSize = 15
	textLabel.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.Parent = container
	
	local bindBtn = Instance.new("TextButton")
	bindBtn.Name = "BindButton" .. i
	bindBtn.Size = UDim2.new(0.35, 0, 0.7, 0)
	bindBtn.Position = UDim2.new(0.6, 0, 0.15, 0)
	bindBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	bindBtn.Text = currentKeybinds[i]
	bindBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
	bindBtn.TextSize = 16
	bindBtn.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
	bindBtn.Parent = container
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 4)
	btnCorner.Parent = bindBtn
	
	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = TrackColors[i]
	btnStroke.Thickness = 1
	btnStroke.Parent = bindBtn
	
	bindButtons[i] = bindBtn
	
	bindBtn.MouseButton1Click:Connect(function()
		if isBinding then return end
		isBinding = i
		bindBtn.Text = "[ Press Key ]"
		bindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	end)
end

-- Скидання за замовчуванням
local resetBtn = Instance.new("TextButton")
resetBtn.Name = "ResetButton"
resetBtn.Size = UDim2.new(0.9, 0, 0, 45)
resetBtn.Position = UDim2.new(0.05, 0, 0, 350)
resetBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
resetBtn.Text = "RESET"
resetBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
resetBtn.TextSize = 15
resetBtn.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
resetBtn.Parent = panel

local resetCorner = Instance.new("UICorner")
resetCorner.CornerRadius = UDim.new(0, 6)
resetCorner.Parent = resetBtn

local resetStroke = Instance.new("UIStroke")
resetStroke.Color = Color3.fromRGB(100, 100, 100)
resetStroke.Thickness = 1
resetStroke.Parent = resetBtn

resetBtn.MouseButton1Click:Connect(function()
	currentKeybinds = { "X", "C", "N", "M" }
	refreshBindTexts()
	SetCustomKeybindsEvent:FireServer(currentKeybinds)
end)

-- Прослуховувач натискань клавіатури для бінду
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not isBinding then return end
	
	if input.UserInputType == Enum.UserInputType.Keyboard then
		local key = input.KeyCode.Name
		-- Дозволяємо лише прості літери та цифри
		if #key == 1 or key:match("^%d$") then
			currentKeybinds[isBinding] = key
			refreshBindTexts()
			
			-- Збереження на сервер
			SetCustomKeybindsEvent:FireServer(currentKeybinds)
			
			isBinding = nil
		end
	end
end)
