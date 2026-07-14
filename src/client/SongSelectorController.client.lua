-- StarterPlayer/StarterPlayerScripts/SongSelectorController.client.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestStartSongEvent = Remotes:WaitForChild("RequestStartSong")
local SongData = require(ReplicatedStorage:WaitForChild("SongData"))

-- Очищаємо попередній UI якщо є
local oldUI = PlayerGui:FindFirstChild("SongSelectorUI")
if oldUI then oldUI:Destroy() end

-- Створюємо ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SongSelectorUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

-- Головна панель вибору пісні (центр)
local panel = Instance.new("Frame")
panel.Name = "SelectorPanel"
panel.Size = UDim2.new(0, 500, 0, 550)
panel.Position = UDim2.new(0.5, -250, 0.5, -275)
panel.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
panel.BackgroundTransparency = 0.2
panel.Visible = false
panel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(180, 180, 180) -- Мінімалістичний сірий контур
panelStroke.Thickness = 2
panelStroke.Parent = panel

-- Заголовок
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.Position = UDim2.new(0, 0, 0, 10)
title.BackgroundTransparency = 1
title.Text = "ВИБІР ПІСНІ (ВІЛЬНА ГРА)"
title.TextColor3 = Color3.fromRGB(240, 240, 240)
title.TextSize = 22
title.Font = Enum.Font.FredokaOne
title.Parent = panel

-- Підзаголовок (гаряча клавіша)
local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, 0, 0, 20)
subtitle.Position = UDim2.new(0, 0, 0, 55)
subtitle.BackgroundTransparency = 1
subtitle.Text = "[ Натисніть клавішу 'G' для відкриття/закриття ]"
subtitle.TextColor3 = Color3.fromRGB(140, 140, 140)
subtitle.TextSize = 13
subtitle.Font = Enum.Font.SourceSansItalic
subtitle.Parent = panel

-- Кнопка закриття (✕)
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -40, 0, 12)
closeButton.BackgroundTransparency = 1
closeButton.Text = "✕"
closeButton.TextColor3 = Color3.fromRGB(130, 130, 130)
closeButton.TextSize = 22
closeButton.Font = Enum.Font.SourceSansBold
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

-- Скролінг список пісень
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(0.9, 0, 0.72, 0)
scrollFrame.Position = UDim2.new(0.05, 0, 0.16, 0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Авто-розширення
scrollFrame.ScrollBarThickness = 6
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
scrollFrame.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scrollFrame

-- Автоматичне оновлення розміру скролінгу
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
end)

-- Рендеримо всі пісні зі списку SongData
local function populateSongList()
	-- Очищаємо старі елементи
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	local sortedSongs = {}
	for _, song in ipairs(SongData.Songs) do
		table.insert(sortedSongs, song)
	end
	
	for idx, song in ipairs(sortedSongs) do
		local item = Instance.new("Frame")
		item.Name = "SongItem_" .. song.Id
		item.Size = UDim2.new(0.98, 0, 0, 65)
		item.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
		item.BackgroundTransparency = 0.5
		item.BorderSizePixel = 0
		item.LayoutOrder = idx
		item.Parent = scrollFrame
		
		local itemCorner = Instance.new("UICorner")
		itemCorner.CornerRadius = UDim.new(0, 6)
		itemCorner.Parent = item
		
		local itemStroke = Instance.new("UIStroke")
		itemStroke.Color = Color3.fromRGB(50, 50, 55)
		itemStroke.Thickness = 1
		itemStroke.Parent = item
		
		-- Назва пісні
		local songTitle = Instance.new("TextLabel")
		songTitle.Size = UDim2.new(0.6, 0, 0.5, 0)
		songTitle.Position = UDim2.new(0.04, 0, 0.1, 0)
		songTitle.BackgroundTransparency = 1
		songTitle.Text = song.Title
		songTitle.TextColor3 = Color3.fromRGB(240, 240, 240)
		songTitle.TextSize = 15
		songTitle.Font = Enum.Font.FredokaOne
		songTitle.TextXAlignment = Enum.TextXAlignment.Left
		songTitle.Parent = item
		
		-- Інфо (BPM / Складність / Тривалість)
		local durationMins = string.format("%d:%02d", math.floor(song.Length / 60), song.Length % 60)
		local infoText = string.format("Складність: %s | BPM: %d | Час: %s", song.Difficulty, song.Bpm, durationMins)
		
		local songInfo = Instance.new("TextLabel")
		songInfo.Size = UDim2.new(0.6, 0, 0.35, 0)
		songInfo.Position = UDim2.new(0.04, 0, 0.55, 0)
		songInfo.BackgroundTransparency = 1
		songInfo.Text = infoText
		songInfo.TextColor3 = Color3.fromRGB(150, 150, 150)
		songInfo.TextSize = 12
		songInfo.Font = Enum.Font.SourceSansBold
		songInfo.TextXAlignment = Enum.TextXAlignment.Left
		songInfo.Parent = item
		
		-- Кнопка Грати (Play)
		local playBtn = Instance.new("TextButton")
		playBtn.Name = "PlayButton"
		playBtn.Size = UDim2.new(0.28, 0, 0.65, 0)
		playBtn.Position = UDim2.new(0.68, 0, 0.175, 0)
		playBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
		playBtn.Text = "ГРАТИ"
		playBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
		playBtn.TextSize = 14
		playBtn.Font = Enum.Font.FredokaOne
		playBtn.Parent = item
		
		local playCorner = Instance.new("UICorner")
		playCorner.CornerRadius = UDim.new(0, 4)
		playCorner.Parent = playBtn
		
		local playStroke = Instance.new("UIStroke")
		playStroke.Color = Color3.fromRGB(100, 100, 105)
		playStroke.Thickness = 1
		playStroke.Parent = playBtn
		
		-- Анімація наведення
		playBtn.MouseEnter:Connect(function()
			TweenService:Create(playBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 60), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
			TweenService:Create(playStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(200, 200, 200)}):Play()
		end)
		playBtn.MouseLeave:Connect(function()
			TweenService:Create(playBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 35, 45), TextColor3 = Color3.fromRGB(220, 220, 220)}):Play()
			TweenService:Create(playStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(100, 100, 105)}):Play()
		end)
		
		-- Клік по кнопці PLAY
		playBtn.MouseButton1Click:Connect(function()
			panel.Visible = false -- Приховуємо меню
			RequestStartSongEvent:FireServer(song.Id) -- Запускаємо гру
		end)
	end
end

populateSongList()

-- Прослуховувач клавіші 'G' для відкриття та закриття
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.G then
		panel.Visible = not panel.Visible
	end
end)
