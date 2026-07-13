-- StarterPlayer/StarterPlayerScripts/RhythmClient.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local SongData = require(ReplicatedStorage:WaitForChild("SongData"))
local GameSettings = require(ReplicatedStorage:WaitForChild("GameSettings"))

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local StartSongEvent = Remotes:WaitForChild("StartSong")
local FinishSongFunc = Remotes:WaitForChild("FinishSong")
local RequestPlayerDataFunc = Remotes:WaitForChild("RequestPlayerData")

-- Поточний стан гри
local isPlaying = false
local currentSong = nil
local currentContractName = ""
local currentKeybinds = GameSettings.DefaultKeybinds
local songStartTime = 0
local activeNotes = {} -- Список нот, які зараз рухаються
local spawnedNoteIndex = 1
local scoreTotal = 0
local notesHit = 0
local notesTotal = 0
local currentHp = 100
local hpLossPerMiss = 5 -- Змінюється залежно від складності

-- GUI Елементи (Створюються програмно для простоти встановлення)
local screenGui = nil
local rhythmFrame = nil
local hpBar = nil
local feedbackLabel = nil
local accuracyLabel = nil

-- Звукові ефекти (можна замінити на власні звуки в Roblox)
local soundDefect = Instance.new("Sound")
soundDefect.SoundId = "rbxassetid://9114223192" -- Замініть на свій ID звуку дефекту гітари
soundDefect.Volume = 0.5
soundDefect.Parent = SoundService

local soundPerfect = Instance.new("Sound")
soundPerfect.SoundId = "rbxassetid://9113615177" -- Звук попадання
soundPerfect.Volume = 0.3
soundPerfect.Parent = SoundService

-- Завантаження налаштувань гравця
local function updateKeybinds()
	local success, data = pcall(function()
		return RequestPlayerDataFunc:InvokeServer()
	end)
	if success and data and data.Keybinds then
		currentKeybinds = data.Keybinds
	end
end

-- Створення інтерфейсу ритм-гри
local function createRhythmGui()
	if screenGui then screenGui:Destroy() end

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "RhythmGameUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = PlayerGui

	-- Головне поле гри
	rhythmFrame = Instance.new("Frame")
	rhythmFrame.Size = UDim2.new(0, 400, 0, 600)
	rhythmFrame.Position = UDim2.new(0.5, -200, 0.5, -300)
	rhythmFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	rhythmFrame.BorderSizePixel = 2
	rhythmFrame.BorderColor3 = Color3.fromRGB(0, 170, 255)
	rhythmFrame.Parent = screenGui

	-- Тінь/Світіння у стилі Токіо
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = Color3.fromRGB(255, 0, 128)
	uiStroke.Thickness = 3
	uiStroke.Parent = rhythmFrame

	-- Доріжки (4 штуки)
	for i = 1, 4 do
		local lane = Instance.new("Frame")
		lane.Name = "Lane" .. i
		lane.Size = UDim2.new(0.25, 0, 1, -80)
		lane.Position = UDim2.new(0.25 * (i - 1), 0, 0, 0)
		lane.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
		lane.BackgroundTransparency = 0.8
		lane.BorderSizePixel = 1
		lane.BorderColor3 = Color3.fromRGB(50, 50, 50)
		lane.Parent = rhythmFrame

		-- Візуальний індикатор клавіші знизу
		local keyLabel = Instance.new("TextLabel")
		keyLabel.Size = UDim2.new(1, 0, 0, 50)
		keyLabel.Position = UDim2.new(0, 0, 1, 0)
		keyLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
		keyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		keyLabel.TextSize = 20
		keyLabel.Text = currentKeybinds[i]
		keyLabel.Font = Enum.Font.FredokaOne
		keyLabel.Parent = lane
	end

	-- Лінія натискання (Target Line)
	local targetLine = Instance.new("Frame")
	targetLine.Name = "TargetLine"
	targetLine.Size = UDim2.new(1, 0, 0, 5)
	targetLine.Position = UDim2.new(0, 0, 1, -85)
	targetLine.BackgroundColor3 = Color3.fromRGB(255, 0, 128)
	targetLine.BorderSizePixel = 0
	targetLine.Parent = rhythmFrame

	-- Смуга здоров'я HP
	local hpBackground = Instance.new("Frame")
	hpBackground.Size = UDim2.new(1, 0, 0, 15)
	hpBackground.Position = UDim2.new(0, 0, 0, -25)
	hpBackground.BackgroundColor3 = Color3.fromRGB(50, 10, 10)
	hpBackground.Parent = rhythmFrame

	hpBar = Instance.new("Frame")
	hpBar.Size = UDim2.new(1, 0, 1, 0)
	hpBar.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
	hpBar.BorderSizePixel = 0
	hpBar.Parent = hpBackground

	-- Текст точності та статусу натискань
	feedbackLabel = Instance.new("TextLabel")
	feedbackLabel.Size = UDim2.new(1, 0, 0, 50)
	feedbackLabel.Position = UDim2.new(0, 0, 0.4, 0)
	feedbackLabel.BackgroundTransparency = 1
	feedbackLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	feedbackLabel.TextSize = 32
	feedbackLabel.Font = Enum.Font.FredokaOne
	feedbackLabel.Text = ""
	feedbackLabel.Parent = rhythmFrame

	accuracyLabel = Instance.new("TextLabel")
	accuracyLabel.Size = UDim2.new(1, 0, 0, 30)
	accuracyLabel.Position = UDim2.new(0, 0, 0, -60)
	accuracyLabel.BackgroundTransparency = 1
	accuracyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	accuracyLabel.TextSize = 22
	accuracyLabel.Font = Enum.Font.SourceSansBold
	accuracyLabel.Text = "Точність: 100% | HP: 100"
	accuracyLabel.Parent = rhythmFrame
end

-- Створення візуальної ноти
local function spawnNote(track, targetTime)
	local lane = rhythmFrame:FindFirstChild("Lane" .. track)
	if not lane then return end

	local noteObj = Instance.new("Frame")
	noteObj.Size = UDim2.new(0.8, 0, 0, 20)
	noteObj.Position = UDim2.new(0.1, 0, 0, -20) -- Створюється вгорі доріжки
	noteObj.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
	noteObj.BorderSizePixel = 0
	noteObj.Parent = lane

	-- Округлення кутів
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0.5, 0)
	uiCorner.Parent = noteObj

	table.insert(activeNotes, {
		Gui = noteObj,
		Track = track,
		TargetTime = targetTime,
		Hit = false
	})
end

-- Завершення гри
local function endSong(failed)
	if not isPlaying then return end
	isPlaying = false

	local finalAccuracy = 0
	if notesTotal > 0 and not failed then
		finalAccuracy = math.round((notesHit / notesTotal) * 100)
	end
	
	if failed then
		feedbackLabel.Text = "ГРУ ПРОВАЛЕНО!"
		feedbackLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
		finalAccuracy = 0
	else
		feedbackLabel.Text = "ПІСНЮ ЗАВЕРШЕНО!"
		feedbackLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
	end

	task.wait(2)

	-- Надсилаємо результати на сервер для нарахування нагород
	local success, rewards = FinishSongFunc:InvokeServer(finalAccuracy)

	-- Очищення інтерфейсу та вивід результатів
	if screenGui then
		screenGui:Destroy()
		screenGui = nil
	end

	if success and rewards then
		local summary = string.format(
			"Результати виступу (%s):\nТочність: %d%%\nДосвід: +%d XP\nГроші: +%d$\nФани: +%d",
			currentContractName,
			rewards.Accuracy,
			rewards.XPEarned,
			rewards.CashEarned,
			rewards.FansEarned
		)
		if rewards.LeveledUp then
			summary = summary .. "\n\n🎉 РІВЕНЬ ГУРТУ ПІДВИЩЕНО ДО " .. rewards.NewLevel .. "! 🎉"
		end
		
		-- Показуємо системне сповіщення
		local StarterGui = game:GetService("StarterGui")
		StarterGui:SetCore("SendNotification", {
			Title = "Контракт Виконано!",
			Text = summary,
			Duration = 10
		})
	end
end

-- Початок ритм-гри
StartSongEvent.OnClientEvent:Connect(function(song, contractName)
	updateKeybinds()
	currentSong = song
	currentContractName = contractName
	isPlaying = true
	songStartTime = os.clock()
	activeNotes = {}
	spawnedNoteIndex = 1
	scoreTotal = 0
	notesHit = 0
	notesTotal = #song.Notes
	currentHp = 100

	-- Встановлення шкоди від промаху в залежності від складності
	if song.Difficulty == "Easy" then
		hpLossPerMiss = 2
	elseif song.Difficulty == "Medium" then
		hpLossPerMiss = 10
	elseif song.Difficulty == "Hard" then
		hpLossPerMiss = 20
	elseif song.Difficulty == "Extreme" then
		hpLossPerMiss = 35
	end

	createRhythmGui()

	-- Ігровий цикл
	local connection
	connection = RunService.RenderStepped:Connect(function()
		if not isPlaying then
			connection:Disconnect()
			return
		end

		local elapsed = os.clock() - songStartTime

		-- Перевірка завершення пісні за часом
		if elapsed >= currentSong.Length then
			connection:Disconnect()
			endSong(false)
			return
		end

		-- Спавн нот відповідно до розкладу пісні (ноти з'являються за 2 секунди до моменту натискання)
		local spawnPreDelay = 2.0
		while spawnedNoteIndex <= #currentSong.Notes do
			local note = currentSong.Notes[spawnedNoteIndex]
			if note.time - spawnPreDelay <= elapsed then
				spawnNote(note.track, note.time)
				spawnedNoteIndex = spawnedNoteIndex + 1
			else
				break
			end
		end

		-- Оновлення позиції активних нот
		for i = #activeNotes, 1, -1 do
			local note = activeNotes[i]
			local timeDiff = note.TargetTime - elapsed

			-- Координата Y: 0 вгорі доріжки, 1 на лінії натискання (після 2 сек польоту)
			-- Лінія натискання знаходиться на висоті: rhythmFrame.Height - 85
			local trackHeight = rhythmFrame.Size.Y.Offset - 85
			local yPos = (1 - (timeDiff / spawnPreDelay)) * trackHeight

			if not note.Hit then
				if timeDiff < -0.25 then
					-- Пропуск ноти (Miss)
					note.Gui:Destroy()
					table.remove(activeNotes, i)

					-- Звук помилки гітари
					soundDefect:Play()
					feedbackLabel.Text = "MISS!"
					feedbackLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
					
					-- Зменшення HP
					currentHp = math.max(0, currentHp - hpLossPerMiss)
					hpBar.Size = UDim2.new(currentHp / 100, 0, 1, 0)
					
					if currentHp <= 0 then
						connection:Disconnect()
						endSong(true)
					end
				else
					-- Візуальне зміщення ноти
					note.Gui.Position = UDim2.new(0.1, 0, 0, yPos)
				end
			else
				-- Нота була натиснута
				note.Gui:Destroy()
				table.remove(activeNotes, i)
			end
		end

		-- Оновлення статус-панелі
		local currentAcc = (notesTotal > 0) and math.round((notesHit / notesTotal) * 100) or 100
		accuracyLabel.Text = string.format("Точність: %d%% | HP: %d", currentAcc, currentHp)
	end)
end)

-- Обробка натискання клавіш гравцем
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or not isPlaying then return end

	-- Перевіряємо, чи натиснута клавіша відповідає одній із біндів X, C, N, M
	local pressedTrack = nil
	for trackIdx, bindName in ipairs(currentKeybinds) do
		if input.KeyCode == Enum.KeyCode[bindName] then
			pressedTrack = trackIdx
			break
		end
	end

	if not pressedTrack then return end

	local elapsed = os.clock() - songStartTime
	local bestNote = nil
	local bestNoteIndex = nil
	local minTimeDiff = 999

	-- Шукаємо найближчу невідіграну ноту на відповідній доріжці
	for idx, note in ipairs(activeNotes) do
		if note.Track == pressedTrack and not note.Hit then
			local diff = math.abs(note.TargetTime - elapsed)
			if diff < minTimeDiff then
				minTimeDiff = diff
				bestNote = note
				bestNoteIndex = idx
			end
		end
	end

	-- Вікно влучання:
	-- Perfect: < 0.08с
	-- Good: < 0.15с
	-- Ok: < 0.25с
	if bestNote and minTimeDiff <= 0.25 then
		bestNote.Hit = true

		if minTimeDiff <= 0.08 then
			feedbackLabel.Text = "PERFECT!"
			feedbackLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
			notesHit = notesHit + 1
			soundPerfect:Play()
		elseif minTimeDiff <= 0.15 then
			feedbackLabel.Text = "GOOD!"
			feedbackLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
			notesHit = notesHit + 0.75
			soundPerfect:Play()
		else
			feedbackLabel.Text = "OK"
			feedbackLabel.TextColor3 = Color3.fromRGB(200, 200, 100)
			notesHit = notesHit + 0.5
		end
	else
		-- Натискання повз ноту
		soundDefect:Play()
		feedbackLabel.Text = "BAD TIMING!"
		feedbackLabel.TextColor3 = Color3.fromRGB(255, 150, 0)
		currentHp = math.max(0, currentHp - (hpLossPerMiss / 2))
		hpBar.Size = UDim2.new(currentHp / 100, 0, 1, 0)
		
		if currentHp <= 0 then
			endSong(true)
		end
	end
end)
