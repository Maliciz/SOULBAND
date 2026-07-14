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

-- Кнопка налаштувань (зліва зверху)
local openButton = Instance.new("TextButton")
openButton.Name = "OpenButton"
openButton.Size = UDim2.new(0, 45, 0, 45)
openButton.Position = UDim2.new(0, 15, 0, 15)
openButton.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
openButton.BackgroundTransparency = 0.3
openButton.Text = "⚙️"
openButton.TextColor3 = Color3.fromRGB(255, 255, 255)
openButton.TextSize = 24
openButton.Font = Enum.Font.FredokaOne
openButton.Parent = screenGui

local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(0.5, 0)
openCorner.Parent = openButton

local openStroke = Instance.new("UIStroke")
openStroke.Color = Color3.fromRGB(0, 255, 255)
openStroke.Thickness = 1.5
openStroke.Parent = openButton

-- Анімація наведення на кнопку
openButton.MouseEnter:Connect(function()
	TweenService:Create(openButton, TweenInfo.new(0.2), {BackgroundTransparency = 0.1, TextColor3 = Color3.fromRGB(0, 255, 255)}):Play()
	TweenService:Create(openStroke, TweenInfo.new(0.2), {Thickness = 2.5}):Play()
end)
openButton.MouseLeave:Connect(function()
	TweenService:Create(openButton, TweenInfo.new(0.2), {BackgroundTransparency = 0.3, TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
	TweenService:Create(openStroke, TweenInfo.new(0.2), {Thickness = 1.5}):Play()
end)

-- Панель налаштувань (центр)
local panel = Instance.new("Frame")
panel.Name = "SettingsPanel"
panel.Size = UDim2.new(0, 360, 0, 420)
panel.Position = UDim2.new(0.5, -180, 0.5, -210)
panel.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
panel.BackgroundTransparency = 0.15
panel.Visible = false
panel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(170, 85, 255) -- Неоновий фіолетовий
panelStroke.Thickness = 3
panelStroke.Parent = panel

-- Заголовок
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.Position = UDim2.new(0, 0, 0, 10)
title.BackgroundTransparency = 1
title.Text = "НАЛАШТУВАННЯ КЛАВІШ"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 22
title.Font = Enum.Font.FredokaOne
title.Parent = panel

-- Кнопка закриття
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -40, 0, 10)
closeButton.BackgroundTransparency = 1
closeButton.Text = "✕"
closeButton.TextColor3 = Color3.fromRGB(150, 150, 150)
closeButton.TextSize = 20
closeButton.Font = Enum.Font.SourceSansBold
closeButton.Parent = panel

closeButton.MouseEnter:Connect(function()
	closeButton.TextColor3 = Color3.fromRGB(255, 50, 50)
end)
closeButton.MouseLeave:Connect(function()
	closeButton.TextColor3 = Color3.fromRGB(150, 150, 150)
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
local laneNames = { "Доріжка 1 (Ліва)", "Доріжка 2", "Доріжка 3", "Доріжка 4 (Права)" }
local bindButtons = {}
local isBinding = nil

local TrackColors = {
	Color3.fromRGB(0, 255, 255),
	Color3.fromRGB(255, 0, 128),
	Color3.fromRGB(255, 215, 0),
	Color3.fromRGB(170, 85, 255)
}

-- Функція оновлення відображення кнопок
local function refreshBindTexts()
	for i = 1, 4 do
		bindButtons[i].Text = currentKeybinds[i]
		bindButtons[i].TextColor3 = Color3.fromRGB(255, 255, 255)
	end
end

for i = 1, 4 do
	local container = Instance.new("Frame")
	container.Size = UDim2.new(0.9, 0, 0, 60)
	container.Position = UDim2.new(0.05, 0, 0, 60 + (i - 1) * 70)
	container.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	container.BackgroundTransparency = 0.5
	container.BorderSizePixel = 0
	container.Parent = panel
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = container
	
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(0.5, 0, 1, 0)
	textLabel.Position = UDim2.new(0.05, 0, 0, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = laneNames[i]
	textLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	textLabel.TextSize = 16
	textLabel.Font = Enum.Font.FredokaOne
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.Parent = container
	
	local bindBtn = Instance.new("TextButton")
	bindBtn.Name = "BindButton" .. i
	bindBtn.Size = UDim2.new(0.35, 0, 0.7, 0)
	bindBtn.Position = UDim2.new(0.6, 0, 0.15, 0)
	bindBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	bindBtn.Text = currentKeybinds[i]
	bindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	bindBtn.TextSize = 18
	bindBtn.Font = Enum.Font.FredokaOne
	bindBtn.Parent = container
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = bindBtn
	
	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = TrackColors[i]
	btnStroke.Thickness = 1.5
	btnStroke.Parent = bindBtn
	
	bindButtons[i] = bindBtn
	
	bindBtn.MouseButton1Click:Connect(function()
		if isBinding then return end
		isBinding = i
		bindBtn.Text = "[ Натисніть ]"
		bindBtn.TextColor3 = TrackColors[i]
	end)
end

-- Скидання за замовчуванням
local resetBtn = Instance.new("TextButton")
resetBtn.Name = "ResetButton"
resetBtn.Size = UDim2.new(0.9, 0, 0, 45)
resetBtn.Position = UDim2.new(0.05, 0, 0, 350)
resetBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 20)
resetBtn.Text = "СКИДАННЯ"
resetBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
resetBtn.TextSize = 16
resetBtn.Font = Enum.Font.FredokaOne
resetBtn.Parent = panel

local resetCorner = Instance.new("UICorner")
resetCorner.CornerRadius = UDim.new(0, 8)
resetCorner.Parent = resetBtn

local resetStroke = Instance.new("UIStroke")
resetStroke.Color = Color3.fromRGB(255, 50, 50)
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
