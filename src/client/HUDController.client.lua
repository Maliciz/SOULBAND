-- StarterPlayer/StarterPlayerScripts/HUDController.client.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local MainHUD = PlayerGui:WaitForChild("MainHUD")

-- Пошук фреймів
local FansFrame = MainHUD:WaitForChild("Fans_Frame")
local LevelFrame = MainHUD:WaitForChild("Level_Frame")
local MoneyFrame = MainHUD:WaitForChild("Money_Frame")

-- Допоміжна функція для отримання або створення TextLabel всередині фрейму
local function getValueLabel(frame)
	local label = frame:FindFirstChildWhichIsA("TextLabel")
	if not label then
		-- Створюємо лейбл програмно, якщо користувач створив лише порожній фрейм
		label = Instance.new("TextLabel")
		label.Name = "ValueLabel"
		label.Size = UDim2.new(1, -20, 1, 0)
		label.Position = UDim2.new(0, 10, 0, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextSize = 18
		label.Font = Enum.Font.FredokaOne
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
