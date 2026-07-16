-- StarterPlayer/StarterPlayerScripts/HUDController.client.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Рекурсивний пошук MainHUD на випадок, якщо він лежить всередині папок інтерфейсу
local function findHUD()
	local hud = PlayerGui:FindFirstChild("MainHUD", true)
	if hud then return hud end
	
	for i = 1, 20 do
		hud = PlayerGui:FindFirstChild("MainHUD", true)
		if hud then return hud end
		task.wait(0.5)
	end
	return nil
end

local MainHUD = findHUD()
if not MainHUD then
	warn("⚠️ MainHUD не знайдено в PlayerGui! Перевірте назву та розташування GUI.")
	return
end

-- Пошук фреймів (теж рекурсивний на випадок змін ієрархії)
local FansFrame = MainHUD:FindFirstChild("Fans_Frame", true)
local LevelFrame = MainHUD:FindFirstChild("Level_Frame", true)
local MoneyFrame = MainHUD:FindFirstChild("Money_Frame", true)

if not (FansFrame and LevelFrame and MoneyFrame) then
	warn("⚠️ Один з фреймів (Fans_Frame, Level_Frame або Money_Frame) не знайдено в MainHUD!")
	return
end

-- Допоміжна функція для отримання або створення TextLabel всередині фрейму
local function getValueLabel(frame)
	local label = frame:FindFirstChildWhichIsA("TextLabel")
	if not label then
		label = Instance.new("TextLabel")
		label.Name = "ValueLabel"
		label.Size = UDim2.new(1, -20, 1, 0)
		label.Position = UDim2.new(0, 10, 0, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextSize = 50 -- Значно збільшено
		label.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
		label.TextXAlignment = Enum.TextXAlignment.Center
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.Parent = frame
	end
	return label
end

local fansLabel = getValueLabel(FansFrame)
local levelLabel = getValueLabel(LevelFrame)
local moneyLabel = getValueLabel(MoneyFrame)

-- Функції оновлення тексту
local function updateFans(value)
	fansLabel.Text = tostring(value) .. " Fans"
end

local function updateLevel(value)
	levelLabel.Text = "LVL " .. tostring(value)
end

local function updateMoney(value)
	moneyLabel.Text = "$" .. tostring(value)
end

-- Очікуємо створення папки leaderstats
local leaderstats = Player:WaitForChild("leaderstats")
local levelVal = leaderstats:WaitForChild("Level")
local fansVal = leaderstats:WaitForChild("Fans")
local cashVal = leaderstats:WaitForChild("Cash")

-- Початкове оновлення
updateLevel(levelVal.Value)
updateFans(fansVal.Value)
updateMoney(cashVal.Value)

-- Слухаємо зміни значень
levelVal.Changed:Connect(updateLevel)
fansVal.Changed:Connect(updateFans)
cashVal.Changed:Connect(updateMoney)

print("🎉 HUDController успішно запущено та підключено до MainHUD!")
