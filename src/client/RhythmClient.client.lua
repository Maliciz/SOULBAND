-- StarterPlayer/StarterPlayerScripts/RhythmClient.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

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
local activeNotes = {}
local spawnedNoteIndex = 1
local notesHit = 0
local notesTotal = 0
local currentHp = 100
local hpLossPerMiss = 5

-- GUI Елементи
local screenGui = nil
local rhythmFrame = nil
local hpBar = nil
local feedbackLabel = nil
local accuracyLabel = nil

-- Елементи кастомного GUI (MainGui--inGame)
local customGuiMode = false
local customLanes = {}       -- {x, c, n, m}
local customActiveFrames = {} -- {x_active, c_active, n_active, m_active}

-- Звукові ефекти
local soundDefect = Instance.new("Sound")
soundDefect.SoundId = "rbxassetid://9114223192"
soundDefect.Volume = 0.5
soundDefect.Parent = SoundService

local soundPerfect = Instance.new("Sound")
soundPerfect.SoundId = "rbxassetid://9113615177"
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
	-- Спочатку пробуємо знайти кастомний інтерфейс користувача MainGui--inGame
	local customGui = PlayerGui:FindFirstChild("MainGui--inGame", true)
	
	if customGui then
		print("🎨 Виявлено кастомний інтерфейс MainGui--inGame. Інтегруємо кнопки...")
		screenGui = customGui
		screenGui.Enabled = true
		customGuiMode = true
		
		-- Знаходимо фоновий фрейм
		rhythmFrame = customGui:FindFirstChild("background", true) or customGui
		rhythmFrame.Visible = true
		
		-- Очищаємо старі кнопки
		customLanes = {}
		customActiveFrames = {}
		
		-- Мапуємо доріжки x, c, n, m та їх активні фрейми x_active, c_active...
		local laneNames = {"x", "c", "n", "m"}
		local activeNames = {"x_active", "c_active", "n_active", "m_active"}
		
		for i = 1, 4 do
			local lane = customGui:FindFirstChild(laneNames[i], true)
			local activeFrame = customGui:FindFirstChild(activeNames[i], true)
			
			if lane then
				customLanes[i] = lane
				lane.ClipsDescendants = true -- Щоб ноти не вилазили за межі доріжки
				
				if activeFrame then
					customActiveFrames[i] = activeFrame
					activeFrame.Visible = false -- Приховуємо за замовчуванням
				end
			else
				warn("⚠️ Не знайдено доріжку " .. laneNames[i] .. " у MainGui--inGame!")
			end
		end
		
		-- Створюємо або знаходимо HPBar, FeedbackLabel та AccuracyLabel
		feedbackLabel = customGui:FindFirstChild("FeedbackLabel", true)
		if not feedbackLabel then
			feedbackLabel = Instance.new("TextLabel")
			feedbackLabel.Name = "FeedbackLabel"
			feedbackLabel.Size = UDim2.new(1, 0, 0, 40)
			feedbackLabel.Position = UDim2.new(0, 0, 0.35, 0)
			feedbackLabel.BackgroundTransparency = 1
			feedbackLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			feedbackLabel.TextSize = 36
			feedbackLabel.Font = Enum.Font.FredokaOne
			feedbackLabel.Text = ""
			feedbackLabel.Parent = rhythmFrame
		end
		
		accuracyLabel = customGui:FindFirstChild("AccuracyLabel", true)
		if not accuracyLabel then
			accuracyLabel = Instance.new("TextLabel")
			accuracyLabel.Name = "AccuracyLabel"
			accuracyLabel.Size = UDim2.new(1, 0, 0, 25)
			accuracyLabel.Position = UDim2.new(0, 0, 0.02, 0)
			accuracyLabel.BackgroundTransparency = 1
			accuracyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			accuracyLabel.TextSize = 18
			accuracyLabel.Font = Enum.Font.SourceSansBold
			accuracyLabel.Text = "Точність: 100% | HP: 100"
			accuracyLabel.Parent = rhythmFrame
		end
		
		local hpBackground = customGui:FindFirstChild("HPBackground", true)
		hpBar = customGui:FindFirstChild("HPBar", true)
		
		if not hpBar then
			hpBackground = Instance.new("Frame")
			hpBackground.Name = "HPBackground"
			hpBackground.Size = UDim2.new(0.8, 0, 0, 10)
			hpBackground.Position = UDim2.new(0.1, 0, 0.08, 0)
			hpBackground.BackgroundColor3 = Color3.fromRGB(50, 10, 10)
			hpBackground.BorderSizePixel = 0
			hpBackground.Parent = rhythmFrame
			
			-- Закруглення кутів
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0.5, 0)
			corner.Parent = hpBackground
			
			hpBar = Instance.new("Frame")
			hpBar.Name = "HPBar"
			hpBar.Size = UDim2.new(1, 0, 1, 0)
			hpBar.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
			hpBar.BorderSizePixel = 0
			hpBar.Parent = hpBackground
			
			local barCorner = Instance.new("UICorner")
			barCorner.CornerRadius = UDim.new(0.5, 0)
			barCorner.Parent = hpBar
		end
	else
		-- ФОЛБЕК РЕЖИМ: якщо кастомного GUI немає, створюємо стандартний
		customGuiMode = false
		print("ℹ️ Кастомний інтерфейс не знайдено. Створюємо стандартний...")
		
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "RhythmGameUI"
		screenGui.ResetOnSpawn = false
		screenGui.Parent = PlayerGui

		rhythmFrame = Instance.new("Frame")
		rhythmFrame.Size = UDim2.new(0, 400, 0, 600)
		rhythmFrame.Position = UDim2.new(0.5, -200, 0.5, -300)
		rhythmFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
		rhythmFrame.BorderSizePixel = 2
		rhythmFrame.BorderColor3 = Color3.fromRGB(0, 170, 255)
		rhythmFrame.Parent = screenGui

		local uiStroke = Instance.new("UIStroke")
		uiStroke.Color = Color3.fromRGB(255, 0, 128)
		uiStroke.Thickness = 3
		uiStroke.Parent = rhythmFrame

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

		local targetLine = Instance.new("Frame")
		targetLine.Name = "TargetLine"
		targetLine.Size = UDim2.new(1, 0, 0, 5)
		targetLine.Position = UDim2.new(0, 0, 1, -85)
		targetLine.BackgroundColor3 = Color3.fromRGB(255, 0, 128)
		targetLine.BorderSizePixel = 0
		targetLine.Parent = rhythmFrame

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
end

-- Створення візуальної ноти
local function spawnNote(track, targetTime)
	local laneParent = nil
	if customGuiMode then
		laneParent = customLanes[track]
	else
		laneParent = rhythmFrame:FindFirstChild("Lane" .. track)
	end
	
	if not laneParent then return end

	local noteObj = Instance.new("Frame")
	noteObj.Size = UDim2.new(1, 0, 0, 18)
	noteObj.Position = UDim2.new(0, 0, 0, -20) -- Створюється вгорі доріжки
	noteObj.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
	noteObj.BorderSizePixel = 0
	noteObj.Parent = laneParent

	-- Округлення кутів для краси
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

	-- Надсилаємо результати на сервер
	local success, rewards = FinishSongFunc:InvokeServer(finalAccuracy)

	-- Закриття/очищення інтерфейсу
	if customGuiMode then
		screenGui.Enabled = false
		feedbackLabel.Text = ""
	else
		if screenGui then
			screenGui:Destroy()
			screenGui = nil
		end
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
	notesHit = 0
	notesTotal = #song.Notes
	currentHp = 100

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

		-- Спавн нот відповідно до розкладу
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

			-- Розрахунок прогресу польоту ноти: 0 - вгорі, 1 - на лінії натискання
			local progress = 1 - (timeDiff / spawnPreDelay)

			-- Точка натискання: 85% від висоти доріжки (scale = 0.85)
			local targetYScale = 0.85
			local yPosScale = progress * targetYScale

			if not note.Hit then
				if timeDiff < -0.25 then
					-- Пропуск ноти (Miss)
					note.Gui:Destroy()
					table.remove(activeNotes, i)

					soundDefect:Play()
					feedbackLabel.Text = "MISS!"
					feedbackLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
					
					currentHp = math.max(0, currentHp - hpLossPerMiss)
					hpBar.Size = UDim2.new(currentHp / 100, 0, 1, 0)
					
					if currentHp <= 0 then
						connection:Disconnect()
						endSong(true)
					end
				else
					-- Візуальне зміщення ноти по доріжці
					note.Gui.Position = UDim2.new(0, 0, yPosScale, 0)
				end
			else
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

	local pressedTrack = nil
	for trackIdx, bindName in ipairs(currentKeybinds) do
		if input.KeyCode == Enum.KeyCode[bindName] then
			pressedTrack = trackIdx
			break
		end
	end

	if not pressedTrack then return end

	-- Підсвітка клавіші на екрані (активний фрейм)
	local activeFrame = customGuiMode and customActiveFrames[pressedTrack]
	if activeFrame then
		activeFrame.Visible = true
		activeFrame.BackgroundColor3 = Color3.fromRGB(150, 150, 150) -- Сірий колір по дефолту при натисканні
	end

	local elapsed = os.clock() - songStartTime
	local bestNote = nil
	local minTimeDiff = 999

	-- Шукаємо найближчу ноту на цій доріжці
	for _, note in ipairs(activeNotes) do
		if note.Track == pressedTrack and not note.Hit then
			local diff = math.abs(note.TargetTime - elapsed)
			if diff < minTimeDiff then
				minTimeDiff = diff
				bestNote = note
			end
		end
	end

	-- Вікно влучання
	if bestNote and minTimeDiff <= 0.25 then
		bestNote.Hit = true

		if minTimeDiff <= 0.08 then
			feedbackLabel.Text = "PERFECT!"
			feedbackLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
			notesHit = notesHit + 1
			soundPerfect:Play()
			
			-- Коли натискаємо в таймінг - кнопка підсвічується ЗЕЛЕНИМ!
			if activeFrame then
				activeFrame.BackgroundColor3 = Color3.fromRGB(0, 255, 100) -- Яскравий зелений
			end
		elif minTimeDiff <= 0.15 then
			feedbackLabel.Text = "GOOD!"
			feedbackLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
			notesHit = notesHit + 0.75
			soundPerfect:Play()
			
			if activeFrame then
				activeFrame.BackgroundColor3 = Color3.fromRGB(0, 255, 100) -- Яскравий зелений
			end
		else
			feedbackLabel.Text = "OK"
			feedbackLabel.TextColor3 = Color3.fromRGB(200, 200, 100)
			notesHit = notesHit + 0.5
			
			if activeFrame then
				activeFrame.BackgroundColor3 = Color3.fromRGB(200, 200, 100) -- Жовтий неон
			end
		end
	else
		-- Повз таймінг (BAD TIMING)
		soundDefect:Play()
		feedbackLabel.Text = "BAD TIMING!"
		feedbackLabel.TextColor3 = Color3.fromRGB(255, 150, 0)
		currentHp = math.max(0, currentHp - (hpLossPerMiss / 2))
		hpBar.Size = UDim2.new(currentHp / 100, 0, 1, 0)
		
		-- Кнопка стає червоною при поганому таймінгу
		if activeFrame then
			activeFrame.BackgroundColor3 = Color3.fromRGB(255, 50, 50) -- Червоний неон
		end

		if currentHp <= 0 then
			endSong(true)
		end
	end
end)

-- Обробка відпускання клавіш гравцем
UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if not isPlaying then return end

	local releasedTrack = nil
	for trackIdx, bindName in ipairs(currentKeybinds) do
		if input.KeyCode == Enum.KeyCode[bindName] then
			releasedTrack = trackIdx
			break
		end
	end

	if not releasedTrack then return end

	-- Вимикаємо підсвітку кнопки
	local activeFrame = customGuiMode and customActiveFrames[releasedTrack]
	if activeFrame then
		activeFrame.Visible = false
	end
end)
