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

-- ÐžÑ‡Ð¸Ñ‰Ð°Ñ”Ð¼Ð¾ Ð¿Ð¾Ð¿ÐµÑ€ÐµÐ´Ð½Ñ–Ð¹ UI ÑÐºÑ‰Ð¾ Ñ”
local oldUI = PlayerGui:FindFirstChild("SongSelectorUI")
if oldUI then oldUI:Destroy() end

-- Ð¡Ñ‚Ð²Ð¾Ñ€ÑŽÑ”Ð¼Ð¾ ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SongSelectorUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

-- Ð“Ð¾Ð»Ð¾Ð²Ð½Ð° Ð¿Ð°Ð½ÐµÐ»ÑŒ Ð²Ð¸Ð±Ð¾Ñ€Ñƒ Ð¿Ñ–ÑÐ½Ñ– (Ñ†ÐµÐ½Ñ‚Ñ€)
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
panelStroke.Color = Color3.fromRGB(180, 180, 180) -- ÐœÑ–Ð½Ñ–Ð¼Ð°Ð»Ñ–ÑÑ‚Ð¸Ñ‡Ð½Ð¸Ð¹ ÑÑ–Ñ€Ð¸Ð¹ ÐºÐ¾Ð½Ñ‚ÑƒÑ€
panelStroke.Thickness = 2
panelStroke.Parent = panel

-- Ð—Ð°Ð³Ð¾Ð»Ð¾Ð²Ð¾Ðº
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.Position = UDim2.new(0, 0, 0, 10)
title.BackgroundTransparency = 1
title.Text = "SONG SELECTION (FREE PLAY)"
title.TextColor3 = Color3.fromRGB(240, 240, 240)
title.TextSize = 66
title.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
title.Parent = panel

-- ÐŸÑ–Ð´Ð·Ð°Ð³Ð¾Ð»Ð¾Ð²Ð¾Ðº (Ð³Ð°Ñ€ÑÑ‡Ð° ÐºÐ»Ð°Ð²Ñ–ÑˆÐ°)
local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, 0, 0, 20)
subtitle.Position = UDim2.new(0, 0, 0, 55)
subtitle.BackgroundTransparency = 1
subtitle.Text = "[ Press 'G' to Open/Close ]"
subtitle.TextColor3 = Color3.fromRGB(140, 140, 140)
subtitle.TextSize = 57
subtitle.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
subtitle.Parent = panel

-- ÐšÐ½Ð¾Ð¿ÐºÐ° Ð·Ð°ÐºÑ€Ð¸Ñ‚Ñ‚Ñ (âœ•)
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -40, 0, 12)
closeButton.BackgroundTransparency = 1
closeButton.Text = "âœ•"
closeButton.TextColor3 = Color3.fromRGB(130, 130, 130)
closeButton.TextSize = 66
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

-- Ð¡ÐºÑ€Ð¾Ð»Ñ–Ð½Ð³ ÑÐ¿Ð¸ÑÐ¾Ðº Ð¿Ñ–ÑÐµÐ½ÑŒ
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(0.9, 0, 0.72, 0)
scrollFrame.Position = UDim2.new(0.05, 0, 0.16, 0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- ÐÐ²Ñ‚Ð¾-Ñ€Ð¾Ð·ÑˆÐ¸Ñ€ÐµÐ½Ð½Ñ
scrollFrame.ScrollBarThickness = 6
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
scrollFrame.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scrollFrame

-- ÐÐ²Ñ‚Ð¾Ð¼Ð°Ñ‚Ð¸Ñ‡Ð½Ðµ Ð¾Ð½Ð¾Ð²Ð»ÐµÐ½Ð½Ñ Ñ€Ð¾Ð·Ð¼Ñ–Ñ€Ñƒ ÑÐºÑ€Ð¾Ð»Ñ–Ð½Ð³Ñƒ
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
end)

-- Ð ÐµÐ½Ð´ÐµÑ€Ð¸Ð¼Ð¾ Ð²ÑÑ– Ð¿Ñ–ÑÐ½Ñ– Ð·Ñ– ÑÐ¿Ð¸ÑÐºÑƒ SongData
local function populateSongList()
	-- ÐžÑ‡Ð¸Ñ‰Ð°Ñ”Ð¼Ð¾ ÑÑ‚Ð°Ñ€Ñ– ÐµÐ»ÐµÐ¼ÐµÐ½Ñ‚Ð¸
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
		
		-- ÐÐ°Ð·Ð²Ð° Ð¿Ñ–ÑÐ½Ñ–
		local songTitle = Instance.new("TextLabel")
		songTitle.Size = UDim2.new(0.6, 0, 0.5, 0)
		songTitle.Position = UDim2.new(0.04, 0, 0.1, 0)
		songTitle.BackgroundTransparency = 1
		songTitle.Text = song.Title
		songTitle.TextColor3 = Color3.fromRGB(240, 240, 240)
		songTitle.TextSize = 59
		songTitle.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
		songTitle.TextXAlignment = Enum.TextXAlignment.Left
		songTitle.Parent = item
		
		-- Ð†Ð½Ñ„Ð¾ (BPM / Ð¡ÐºÐ»Ð°Ð´Ð½Ñ–ÑÑ‚ÑŒ / Ð¢Ñ€Ð¸Ð²Ð°Ð»Ñ–ÑÑ‚ÑŒ)
		local durationMins = string.format("%d:%02d", math.floor(song.Length / 60), song.Length % 60)
		local infoText = string.format("Difficulty: %s | BPM: %d | Time: %s", song.Difficulty, song.Bpm, durationMins)
		
		local songInfo = Instance.new("TextLabel")
		songInfo.Size = UDim2.new(0.6, 0, 0.35, 0)
		songInfo.Position = UDim2.new(0.04, 0, 0.55, 0)
		songInfo.BackgroundTransparency = 1
		songInfo.Text = infoText
		songInfo.TextColor3 = Color3.fromRGB(150, 150, 150)
		songInfo.TextSize = 56
		songInfo.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
		songInfo.TextXAlignment = Enum.TextXAlignment.Left
		songInfo.Parent = item
		
		-- ÐšÐ½Ð¾Ð¿ÐºÐ° Ð“Ñ€Ð°Ñ‚Ð¸ (Play)
		local playBtn = Instance.new("TextButton")
		playBtn.Name = "PlayButton"
		playBtn.Size = UDim2.new(0.18, 0, 0.65, 0)
		playBtn.Position = UDim2.new(0.78, 0, 0.175, 0)
		playBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
		playBtn.Text = "PLAY"
		playBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
		playBtn.TextSize = 58
		playBtn.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
		playBtn.Parent = item
		
		local playCorner = Instance.new("UICorner")
		playCorner.CornerRadius = UDim.new(0, 4)
		playCorner.Parent = playBtn
		
		local playStroke = Instance.new("UIStroke")
		playStroke.Color = Color3.fromRGB(100, 100, 105)
		playStroke.Thickness = 1
		playStroke.Parent = playBtn
		
		-- ÐšÐ½Ð¾Ð¿ÐºÐ° Ð—Ð°Ð¿Ð¸Ñ (Record)
		local recordBtn = Instance.new("TextButton")
		recordBtn.Name = "RecordButton"
		recordBtn.Size = UDim2.new(0.18, 0, 0.65, 0)
		recordBtn.Position = UDim2.new(0.58, 0, 0.175, 0)
		recordBtn.BackgroundColor3 = Color3.fromRGB(45, 25, 25)
		recordBtn.Text = "RECORD"
		recordBtn.TextColor3 = Color3.fromRGB(255, 180, 180)
		recordBtn.TextSize = 57
		recordBtn.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
		recordBtn.Parent = item
		
		local recordCorner = Instance.new("UICorner")
		recordCorner.CornerRadius = UDim.new(0, 4)
		recordCorner.Parent = recordBtn
		
		local recordStroke = Instance.new("UIStroke")
		recordStroke.Color = Color3.fromRGB(120, 60, 60)
		recordStroke.Thickness = 1
		recordStroke.Parent = recordBtn
		
		-- ÐÐ½Ñ–Ð¼Ð°Ñ†Ñ–Ñ Ð½Ð°Ð²ÐµÐ´ÐµÐ½Ð½Ñ
		playBtn.MouseEnter:Connect(function()
			TweenService:Create(playBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 60), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
			TweenService:Create(playStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(200, 200, 200)}):Play()
		end)
		playBtn.MouseLeave:Connect(function()
			TweenService:Create(playBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 35, 45), TextColor3 = Color3.fromRGB(220, 220, 220)}):Play()
			TweenService:Create(playStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(100, 100, 105)}):Play()
		end)
		
		recordBtn.MouseEnter:Connect(function()
			TweenService:Create(recordBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(65, 35, 35), TextColor3 = Color3.fromRGB(255, 220, 220)}):Play()
			TweenService:Create(recordStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(200, 100, 100)}):Play()
		end)
		recordBtn.MouseLeave:Connect(function()
			TweenService:Create(recordBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 25, 25), TextColor3 = Color3.fromRGB(255, 180, 180)}):Play()
			TweenService:Create(recordStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(120, 60, 60)}):Play()
		end)
		
		-- ÐšÐ»Ñ–Ðº Ð¿Ð¾ ÐºÐ½Ð¾Ð¿Ñ†Ñ– PLAY
		playBtn.MouseButton1Click:Connect(function()
			panel.Visible = false -- ÐŸÑ€Ð¸Ñ…Ð¾Ð²ÑƒÑ”Ð¼Ð¾ Ð¼ÐµÐ½ÑŽ
			RequestStartSongEvent:FireServer(song.Id) -- Ð—Ð°Ð¿ÑƒÑÐºÐ°Ñ”Ð¼Ð¾ Ð³Ñ€Ñƒ
		end)
		
		-- ÐšÐ»Ñ–Ðº Ð¿Ð¾ ÐºÐ½Ð¾Ð¿Ñ†Ñ– RECORD
		recordBtn.MouseButton1Click:Connect(function()
			panel.Visible = false
			local startRecordingEvent = ReplicatedStorage.Remotes:FindFirstChild("StartRecordingSong")
			if not startRecordingEvent then
				startRecordingEvent = Instance.new("BindableEvent")
				startRecordingEvent.Name = "StartRecordingSong"
				startRecordingEvent.Parent = ReplicatedStorage.Remotes
			end
			startRecordingEvent:Fire(song)
		end)
	end
end

populateSongList()

-- Ð¡Ñ‚Ð²Ð¾Ñ€ÐµÐ½Ð½Ñ Ð¿Ð¾ÑÑ‚Ñ–Ð¹Ð½Ð¾Ñ— Ð¿Ñ–Ð´ÐºÐ°Ð·ÐºÐ¸ "ÐÐ°Ñ‚Ð¸ÑÐ½Ñ–Ñ‚ÑŒ G" Ð½Ð° ÐµÐºÑ€Ð°Ð½Ñ– (Ð¼Ð¾Ð½Ð¾Ñ…Ñ€Ð¾Ð¼Ð½Ð¸Ð¹ ÑÑ‚Ð¸Ð»ÑŒ)
local hintFrame = Instance.new("Frame")
hintFrame.Name = "GPlayHint"
hintFrame.Size = UDim2.new(0, 300, 0, 32)
hintFrame.Position = UDim2.new(0.5, -150, 0.92, 0) -- Ð’Ð½Ð¸Ð·Ñƒ Ð¿Ð¾ Ñ†ÐµÐ½Ñ‚Ñ€Ñƒ
hintFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
hintFrame.BackgroundTransparency = 0.3
hintFrame.BorderSizePixel = 0
hintFrame.Parent = screenGui

local hintCorner = Instance.new("UICorner")
hintCorner.CornerRadius = UDim.new(0, 6)
hintCorner.Parent = hintFrame

local hintStroke = Instance.new("UIStroke")
hintStroke.Color = Color3.fromRGB(120, 120, 125)
hintStroke.Thickness = 1
hintStroke.Parent = hintFrame

local hintText = Instance.new("TextLabel")
hintText.Size = UDim2.new(1, 0, 1, 0)
hintText.BackgroundTransparency = 1
hintText.Text = "Press 'G' to select song"
hintText.TextColor3 = Color3.fromRGB(200, 200, 200)
hintText.TextSize = 58
hintText.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
hintText.Parent = hintFrame

-- ÐŸÐ¾Ñ‚Ñ–Ðº Ð´Ð»Ñ Ð°Ð²Ñ‚Ð¾Ð¼Ð°Ñ‚Ð¸Ñ‡Ð½Ð¾Ð³Ð¾ Ð¿Ñ€Ð¸Ñ…Ð¾Ð²Ð°Ð½Ð½Ñ Ð¿Ñ–Ð´ÐºÐ°Ð·ÐºÐ¸ Ð¿Ñ–Ð´ Ñ‡Ð°Ñ Ð³Ñ€Ð¸ Ð°Ð±Ð¾ Ð²Ñ–Ð´ÐºÑ€Ð¸Ñ‚Ð¾Ð¼Ñƒ Ð¼ÐµÐ½ÑŽ
task.spawn(function()
	while true do
		local inGameUI = PlayerGui:FindFirstChild("MainGui--inGame", true)
		local standardGameUI = PlayerGui:FindFirstChild("RhythmGameUI", true)
		
		local isGameActive = false
		if (inGameUI and inGameUI.Enabled) or standardGameUI then
			isGameActive = true
		end
		
		if isGameActive or panel.Visible then
			hintFrame.Visible = false
		else
			hintFrame.Visible = true
		end
		
		task.wait(0.5)
	end
end)

-- ÐŸÑ€Ð¾ÑÐ»ÑƒÑ…Ð¾Ð²ÑƒÐ²Ð°Ñ‡ ÐºÐ»Ð°Ð²Ñ–ÑˆÑ– 'G' Ð´Ð»Ñ Ð²Ñ–Ð´ÐºÑ€Ð¸Ñ‚Ñ‚Ñ Ñ‚Ð° Ð·Ð°ÐºÑ€Ð¸Ñ‚Ñ‚Ñ
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.G then
		panel.Visible = not panel.Visible
	end
end)


