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
			activeSongSound.Volume = 0.5
			activeSongSound.Parent = game.Workspace.CurrentCamera
			activeSongSound:Play()
		end)
	end
	
	print("🔴 ЗАПИС РОЗПОЧАТО для пісні: " .. song.Title)
	print("👉 Слухайте ритм та натискайте клавіші X, C, N, M (або ваші кастомні)!")
	print("👉 Натисніть клавішу 'K' знову, щоб завершити запис та отримати код.")
end

-- Функція для зупинки запису
local function stopRecording()
	if not recording then return end
	recording = false
	
	if activeSongSound then
		pcall(function()
			activeSongSound:Stop()
			activeSongSound:Destroy()
		end)
		activeSongSound = nil
	end
	
	print("⏹️ ЗАПИС ЗАВЕРШЕНО!")
	
	-- Створюємо гарно відформатований Luau-код
	local code = "\nNotes = {\n"
	for i, note in ipairs(recordedNotes) do
		code = code .. string.format("\t{ time = %.2f, track = %d },\n", note.time, note.track)
	end
	code = code .. "}"
	
	print("📋 Скопіюйте цей код у SongData.lua для пісні '" .. selectedSong.Title .. "':")
	print(code)
end

-- Допоміжна довідка при старті
task.spawn(function()
	task.wait(3)
	print("🎹 [Записувач нот завантажено]")
	print("👉 Натисніть 'K', щоб розпочати запис таймінгів під музику.")
	print("👉 Доступні пісні для запису:")
	for idx, song in ipairs(SongData.Songs) do
		print(string.format("  [%d] %s", idx, song.Title))
	end
	print("ℹ️ Ви можете обрати потрібну пісню, натиснувши цифрові клавіші (наприклад, '1', '2', '3' тощо) перед початком запису!")
end)

local currentSelectionIdx = 1

-- Слухаємо клавішу 'K' для перемикання запису
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	-- Вибір пісні перед стартом
	if not recording then
		local num = tonumber(input.KeyCode.Name:sub(-1)) -- беремо останній символ назви клавіші (наприклад, Digit1 -> 1)
		if not num then
			num = tonumber(input.KeyCode.Name:match("%d+"))
		end
		if num and num >= 1 and num <= #SongData.Songs then
			currentSelectionIdx = num
			print("🎯 Обрано пісню для запису: [" .. num .. "] " .. SongData.Songs[num].Title)
			return
		end
	end
	
	-- Запуск/зупинка запису
	if input.KeyCode == Enum.KeyCode.K then
		if not recording then
			local song = SongData.Songs[currentSelectionIdx]
			if song then
				startRecording(song)
			else
				print("⚠️ Не знайдено обраної пісні!")
			end
		else
			stopRecording()
		end
		return
	end
	
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
			table.insert(recordedNotes, {
				time = math.round(elapsed * 100) / 100,
				track = pressedTrack
			})
			print(string.format("🎵 Записано: %.2fs ➔ доріжка %d", elapsed, pressedTrack))
		end
	end
end)
