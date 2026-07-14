-- StarterPlayer/StarterPlayerScripts/ChartRecorder.client.lua
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameSettings = require(ReplicatedStorage:WaitForChild("GameSettings"))
local SongData = require(ReplicatedStorage:WaitForChild("SongData"))

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local recording = false
local startTime = 0
local recordedNotes = {}
local activeSongSound = nil
local selectedSong = nil
local recordHud = nil

-- Функція для виклику модального вікна з кодом
local function showCodeModal(codeText)
	local screenGui = PlayerGui:FindFirstChild("SongSelectorUI") or Instance.new("ScreenGui", PlayerGui)
	
	local modal = Instance.new("Frame")
	modal.Name = "RecordCodeModal"
	modal.Size = UDim2.new(0, 520, 0, 420)
	modal.Position = UDim2.new(0.5, -260, 0.5, -210)
	modal.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	modal.BackgroundTransparency = 0.1
	modal.Parent = screenGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = modal
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(180, 180, 180)
	stroke.Thickness = 2
	stroke.Parent = modal
	
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.Position = UDim2.new(0, 0, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "ЗАПИС ЗАВЕРШЕНО! СКОПІЮЙТЕ КОД:"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 16
	title.Font = Enum.Font.FredokaOne
	title.Parent = modal
	
	local textBox = Instance.new("TextBox")
	textBox.Size = UDim2.new(0.9, 0, 0.68, 0)
	textBox.Position = UDim2.new(0.05, 0, 0.15, 0)
	textBox.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	textBox.Text = codeText
	textBox.TextColor3 = Color3.fromRGB(220, 220, 220)
	textBox.TextSize = 12
	textBox.Font = Enum.Font.Code
	textBox.ClearTextOnFocus = false
	textBox.MultiLine = true
	textBox.TextEditable = false -- Користувач може лише виділяти та копіювати
	textBox.Parent = modal
	
	local textCorner = Instance.new("UICorner")
	textCorner.CornerRadius = UDim.new(0, 6)
	textCorner.Parent = textBox
	
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 140, 0, 32)
	closeBtn.Position = UDim2.new(0.5, -70, 0.88, 0)
	closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	closeBtn.Text = "ЗАКРИТИ"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Font = Enum.Font.FredokaOne
	closeBtn.TextSize = 14
	closeBtn.Parent = modal
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 4)
	btnCorner.Parent = closeBtn
	
	closeBtn.MouseButton1Click:Connect(function()
		modal:Destroy()
	end)
end

-- Функція для зупинки запису (визначена раніше для виклику з кнопки)
local stopRecording -- Попереднє оголошення

-- Функція для запуску запису
local function startRecording(song)
	if recording then return end
	recording = true
	selectedSong = song
	recordedNotes = {}
	startTime = os.clock()
	
	-- Граємо пісню
	if song.AudioId and song.AudioId ~= "" and song.AudioId ~= "rbxassetid://0" then
		pcall(function()
			activeSongSound = Instance.new("Sound")
			activeSongSound.SoundId = song.AudioId
			activeSongSound.Volume = 0.6
			activeSongSound.Parent = game.Workspace.CurrentCamera
			activeSongSound:Play()
		end)
	end
	
	-- Створюємо HUD запису
	local screenGui = PlayerGui:FindFirstChild("SongSelectorUI") or Instance.new("ScreenGui", PlayerGui)
	recordHud = Instance.new("Frame")
	recordHud.Name = "RecordHUD"
	recordHud.Size = UDim2.new(0, 400, 0, 120)
	recordHud.Position = UDim2.new(0.5, -200, 0.1, 0)
	recordHud.BackgroundColor3 = Color3.fromRGB(20, 10, 10)
	recordHud.BackgroundTransparency = 0.2
	recordHud.Parent = screenGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = recordHud
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(150, 50, 50)
	stroke.Thickness = 2
	stroke.Parent = recordHud
	
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Position = UDim2.new(0, 0, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "🔴 ЗАПИС: " .. song.Title
	title.TextColor3 = Color3.fromRGB(255, 100, 100)
	title.TextSize = 16
	title.Font = Enum.Font.FredokaOne
	title.Parent = recordHud
	
	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1, 0, 0, 30)
	desc.Position = UDim2.new(0, 0, 0, 35)
	desc.BackgroundTransparency = 1
	desc.Text = "Натискайте X, C, N, M в ритм музики"
	desc.TextColor3 = Color3.fromRGB(200, 200, 200)
	desc.TextSize = 12
	desc.Font = Enum.Font.SourceSansBold
	desc.Parent = recordHud
	
	local stopBtn = Instance.new("TextButton")
	stopBtn.Size = UDim2.new(0, 160, 0, 30)
	stopBtn.Position = UDim2.new(0.5, -80, 0, 75)
	stopBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
	stopBtn.Text = "⏹️ ЗУПИНИТИ ЗАПИС"
	stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	stopBtn.Font = Enum.Font.FredokaOne
	stopBtn.TextSize = 12
	stopBtn.Parent = recordHud
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 4)
	btnCorner.Parent = stopBtn
	
	stopBtn.MouseButton1Click:Connect(function()
		stopRecording()
	end)
	
	print("🔴 ЗАПИС РОЗПОЧАТО для пісні: " .. song.Title)
end

stopRecording = function()
	if not recording then return end
	recording = false
	
	if activeSongSound then
		pcall(function()
			activeSongSound:Stop()
			activeSongSound:Destroy()
		end)
		activeSongSound = nil
	end
	
	if recordHud then
		recordHud:Destroy()
		recordHud = nil
	end
	
	print("⏹️ ЗАПИС ЗАВЕРШЕНО!")
	
	-- Сортуємо записані ноти за часом спавну
	table.sort(recordedNotes, function(a, b)
		return a.time < b.time
	end)
	
	-- Створюємо Luau-код
	local code = "Notes = {\n"
	for i, note in ipairs(recordedNotes) do
		if note.duration and note.duration > 0 then
			code = code .. string.format("\t{ time = %.2f, track = %d, duration = %.2f },\n", note.time, note.track, note.duration)
		else
			code = code .. string.format("\t{ time = %.2f, track = %d },\n", note.time, note.track)
		end
	end
	code = code .. "}"
	
	print(code)
	showCodeModal(code)
end

-- Підключення до BindableEvent від меню вибору пісень
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local startRecordingEvent = remotesFolder:FindFirstChild("StartRecordingSong")
if not startRecordingEvent then
	startRecordingEvent = Instance.new("BindableEvent")
	startRecordingEvent.Name = "StartRecordingSong"
	startRecordingEvent.Parent = remotesFolder
end

startRecordingEvent.Event:Connect(function(song)
	startRecording(song)
end)

-- Таблиця для відстеження активних утримань клавіш (холдів)
local activeHolds = {}

-- Слухаємо клавіші для фіксації нот
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	-- Фіксація натискань під час запису
	if recording then
		local keybinds = GameSettings.DefaultKeybinds
		local pressedTrack = nil
		for trackIdx, bindName in ipairs(keybinds) do
			if input.KeyCode == Enum.KeyCode[bindName] then
				pressedTrack = trackIdx
				break
			end
		end
		
		if pressedTrack then
			local elapsed = os.clock() - startTime
			activeHolds[pressedTrack] = elapsed
			print(string.format("🎵 Початок натискання: %.2fs ➔ доріжка %d", elapsed, pressedTrack))
		end
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if not recording then return end
	
	local keybinds = GameSettings.DefaultKeybinds
	local releasedTrack = nil
	for trackIdx, bindName in ipairs(keybinds) do
		if input.KeyCode == Enum.KeyCode[bindName] then
			releasedTrack = trackIdx
			break
		end
	end
	
	if releasedTrack then
		local holdStart = activeHolds[releasedTrack]
		if holdStart then
			local elapsed = os.clock() - startTime
			local duration = elapsed - holdStart
			activeHolds[releasedTrack] = nil
			
			local timeVal = math.round(holdStart * 100) / 100
			local durationVal = math.round(duration * 100) / 100
			
			if durationVal > 0.25 then
				table.insert(recordedNotes, {
					time = timeVal,
					track = releasedTrack,
					duration = durationVal
				})
				print(string.format("🎵 Записано HOLD: %.2fs (тривалість %.2fs) ➔ доріжка %d", timeVal, durationVal, releasedTrack))
			else
				table.insert(recordedNotes, {
					time = timeVal,
					track = releasedTrack
				})
				print(string.format("🎵 Записано TAP: %.2fs ➔ доріжка %d", timeVal, releasedTrack))
			end
		end
	end
end)
