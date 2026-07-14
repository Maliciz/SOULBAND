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
local heldTracks = {false, false, false, false} -- Масив для відстеження затиснутих клавіш (блокує Windows KeyRepeat)
local activeSongSound = nil -- Об'єкт програвання поточної аудіодоріжки пісні

-- Мінімалістична темно-біла палітра кольорів (Monochrome Theme)
local TrackColors = {
	Color3.fromRGB(240, 240, 240),   -- 1 доріжка: Чистий білий
	Color3.fromRGB(200, 200, 200),   -- 2 доріжка: Світло-сірий
	Color3.fromRGB(160, 160, 160),   -- 3 доріжка: Сірий
	Color3.fromRGB(120, 120, 120)    -- 4 доріжка: Темно-сірий
}

-- GUI Елементи
local screenGui = nil
local rhythmFrame = nil
local hpBar = nil
local feedbackLabel = nil
local accuracyLabel = nil
local countdownLabel = nil

-- Статистика для вікна результатів
local perfectCount = 0
local goodCount = 0
local badCount = 0
local missCount = 0
local missSeconds = {}
local noteHistory = {}

-- Елементи кастомного GUI (MainGui--inGame)
local customGuiMode = false
local customLanes = {}       -- {x, c, n, m}
local customActiveFrames = {} -- {x_active, c_active, n_active, m_active}
local originalParent = nil

-- Синхронно приховуємо інтерфейс гри при запуску клієнта (усуває рассинхронізацію та баг зникнення)
local startupGui = PlayerGui:FindFirstChild("MainGui--inGame", true)
if startupGui then
	startupGui.Enabled = false
end

-- Оптимізація: Пул об'єктів для нот (Object Pooling)
local NOTE_POOL_SIZE = 30
local notePool = {}

-- Звукові ефекти
local soundDefect = Instance.new("Sound")
soundDefect.SoundId = "rbxassetid://1848228518" -- Гітарний скрип/помилка (Guitar Scratches від APM Music)
soundDefect.Volume = 0.6
soundDefect.PlaybackSpeed = 1.0
soundDefect.Parent = game.Workspace.CurrentCamera

local soundPerfect = Instance.new("Sound")
soundPerfect.SoundId = "rbxassetid://876939830" -- Гарантований клік від Roblox
soundPerfect.Volume = 0.4
soundPerfect.PlaybackSpeed = 1.4 -- Вищий тон для влучання
soundPerfect.Parent = game.Workspace.CurrentCamera

-- Логіка приглушення музики на 0.3 сек та керування звуком помилки
local dimThread = nil
local missSoundThread = nil
local function triggerMiss()
	if isPlaying then
		local elapsedSec = os.clock() - songStartTime
		local sec = math.round(elapsedSec * 10) / 10
		if #missSeconds == 0 or missSeconds[#missSeconds] ~= sec then
			table.insert(missSeconds, sec)
		end
	end
	pcall(function()
		soundDefect:Stop()
		soundDefect.Volume = 0.6
	end)
	
	soundDefect:Play()
	
	if activeSongSound and isPlaying then
		pcall(function()
			activeSongSound.Volume = 0.15 -- Приглушуємо гучність
		end)
		
		if dimThread then
			task.cancel(dimThread)
		end
		
		dimThread = task.delay(0.3, function()
			if activeSongSound and isPlaying then
				pcall(function()
					activeSongSound.Volume = 0.7 -- Відновлюємо гучність
				end)
			end
			dimThread = nil
		end)
	end
	
	-- Зупиняємо/затухаємо звук помилки через 0.2 сек
	if missSoundThread then
		task.cancel(missSoundThread)
	end
	
	missSoundThread = task.delay(0.2, function()
		-- Плавне затухання за 0.05 сек
		for vol = 6, 0, -1 do
			pcall(function()
				soundDefect.Volume = vol / 10
			end)
			task.wait(0.01)
		end
		pcall(function()
			soundDefect:Stop()
		end)
		missSoundThread = nil
	end)
end

-- Легке тремтіння камери (Camera Shake) для динаміки
local function cameraShake(amount, duration)
	local camera = workspace.CurrentCamera
	if not camera then return end
	
	local startTime = os.clock()
	local connection
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = os.clock() - startTime
		if elapsed >= duration or not isPlaying then
			connection:Disconnect()
			return
		end
		local dx = (math.random() - 0.5) * amount
		local dy = (math.random() - 0.5) * amount
		camera.CFrame = camera.CFrame * CFrame.new(dx, dy, 0)
	end)
end

-- Ефектна анімація оцінки (Perfect/Good/Miss)
local function popFeedback(text, color)
	feedbackLabel.Text = text
	feedbackLabel.TextColor3 = color
	feedbackLabel.TextSize = 44
	feedbackLabel.Rotation = math.random(-8, 8)
	
	-- Створюємо легкий рух тексту вгору
	local originalPosition = customGuiMode and UDim2.new(0.5, -200, 0.45, 0) or UDim2.new(0, 0, 0.4, 0)
	feedbackLabel.Position = originalPosition
	
	local tweenInfo = TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(feedbackLabel, tweenInfo, {
		TextSize = 32,
		Rotation = 0
	}):Play()
end

-- Пульсація кнопки при влучанні
local function pulseButton(track)
	local button = customLanes[track]
	if not button then return end
	
	-- Створюємо швидкий ефект стиснення/розширення
	local originalSize = UDim2.new(0, 85, 0, 79)
	button.Size = UDim2.new(0, 95, 0, 88)
	
	local tweenInfo = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(button, tweenInfo, {Size = originalSize}):Play()
end

-- Завантаження налаштувань гравця
local function updateKeybinds()
	local success, data = pcall(function()
		return RequestPlayerDataFunc:InvokeServer()
	end)
	if success and data and data.Keybinds then
		currentKeybinds = data.Keybinds
	end
end

-- Ефект вибуху частинок-бульбашок при успішному натисканні (Juice Effect) - у монохромних кольорах
local function spawnHitParticles(track, rating)
	local targetButton = customLanes[track]
	if not targetButton then return end

	local trackColor = TrackColors[track] or Color3.fromRGB(240, 240, 240)
	if rating == "PERFECT!" then
		trackColor = Color3.fromRGB(255, 255, 255)
	elseif rating == "GOOD!" then
		trackColor = Color3.fromRGB(200, 200, 200)
	elseif rating == "BAD!" then
		trackColor = Color3.fromRGB(100, 100, 100)
	end

	local originX = targetButton.AbsolutePosition.X + targetButton.AbsoluteSize.X / 2
	local originY = targetButton.AbsolutePosition.Y + targetButton.AbsoluteSize.Y / 2

	-- Створюємо 12 круглих частинок, що розлітаються швидше
	for i = 1, 12 do
		local particle = Instance.new("Frame")
		particle.Name = "HitParticle"
		particle.Size = UDim2.new(0, math.random(8, 14), 0, math.random(8, 14))
		particle.Position = UDim2.new(0, originX, 0, originY)
		particle.AnchorPoint = Vector2.new(0.5, 0.5)
		particle.BackgroundColor3 = trackColor
		particle.BackgroundTransparency = 0.2
		particle.BorderSizePixel = 0
		particle.ZIndex = 1000
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = particle
		
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(255, 255, 255)
		stroke.Thickness = 1.5
		stroke.Parent = particle
		
		particle.Parent = screenGui

		local angle = math.rad(math.random(0, 360))
		local distance = math.random(50, 140)
		local targetX = originX + math.cos(angle) * distance
		local targetY = originY + math.sin(angle) * distance

		local tweenInfo = TweenInfo.new(
			math.random(2, 4) / 10, -- 0.2 - 0.4 сек
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		)
		
		local tween = TweenService:Create(particle, tweenInfo, {
			Position = UDim2.new(0, targetX, 0, targetY),
			Size = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1
		})
		
		tween:Play()
		tween.Completed:Connect(function()
			particle:Destroy()
		end)
	end
end

-- Створення пулу нот
local function createNotePool()
	for _, obj in ipairs(notePool) do
		pcall(function() obj:Destroy() end)
	end
	notePool = {}
	
	for i = 1, NOTE_POOL_SIZE do
		-- Красива кругла нота у вигляді бульбашки (Glossy Bubble)
		local noteObj = Instance.new("Frame")
		noteObj.Name = "NoteNode"
		noteObj.BorderSizePixel = 0
		noteObj.BackgroundColor3 = Color3.fromRGB(25, 25, 25) -- Темно-чорне тіло
		noteObj.BackgroundTransparency = 0.25 -- Менше прозорості для вираженого чорно-сірого вигляду
		noteObj.AnchorPoint = Vector2.new(0.5, 0.5)
		noteObj.ZIndex = 10
		noteObj.Visible = false
		
		local uiCorner = Instance.new("UICorner")
		uiCorner.CornerRadius = UDim.new(0.5, 0)
		uiCorner.Parent = noteObj
		
		-- Блискучий відблиск світла у верхньому лівому кутку (Bubble Reflection)
		local reflection = Instance.new("Frame")
		reflection.Name = "Reflection"
		reflection.Size = UDim2.new(0.22, 0, 0.22, 0)
		reflection.Position = UDim2.new(0.22, 0, 0.22, 0)
		reflection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		reflection.BackgroundTransparency = 0.3
		reflection.BorderSizePixel = 0
		reflection.ZIndex = noteObj.ZIndex + 2
		reflection.Parent = noteObj
		
		local refCorner = Instance.new("UICorner")
		refCorner.CornerRadius = UDim.new(0.5, 0)
		refCorner.Parent = reflection
		
		-- Обводка (темно-білий контур бульбашки)
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2.5
		stroke.Parent = noteObj
		
		-- Кольорове м'яке ядро (Core) всередині
		local core = Instance.new("Frame")
		core.Name = "Core"
		core.Size = UDim2.new(0.3, 0, 0.3, 0)
		core.Position = UDim2.new(0.35, 0, 0.35, 0)
		core.BorderSizePixel = 0
		core.ZIndex = noteObj.ZIndex + 1
		core.Parent = noteObj
		
		local coreCorner = Instance.new("UICorner")
		coreCorner.CornerRadius = UDim.new(0.5, 0)
		coreCorner.Parent = core
		
		-- Шлейф для затискання (Hold Trail)
		local trail = Instance.new("Frame")
		trail.Name = "Trail"
		trail.AnchorPoint = Vector2.new(0.5, 1)
		trail.Position = UDim2.new(0.5, 0, 0.5, 0)
		trail.Size = UDim2.new(0, 24, 0, 0)
		trail.BorderSizePixel = 0
		trail.Visible = false
		trail.ZIndex = noteObj.ZIndex - 1
		trail.Parent = noteObj
		
		local trailCorner = Instance.new("UICorner")
		trailCorner.CornerRadius = UDim.new(0.5, 0)
		trailCorner.Parent = trail
		
		local trailStroke = Instance.new("UIStroke")
		trailStroke.Thickness = 1.5
		trailStroke.Parent = trail
		
		noteObj.Parent = screenGui
		table.insert(notePool, noteObj)
	end
end

-- Отримання ноти з пулу
local function getNoteFromPool(track, targetTime, duration)
	local noteObj = nil
	for _, obj in ipairs(notePool) do
		if not obj.Visible then
			noteObj = obj
			break
		end
	end
	
	if not noteObj then
		noteObj = Instance.new("Frame")
		noteObj.Name = "NoteNode"
		noteObj.BorderSizePixel = 0
		noteObj.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		noteObj.BackgroundTransparency = 0.25
		noteObj.AnchorPoint = Vector2.new(0.5, 0.5)
		noteObj.ZIndex = 10
		
		local uiCorner = Instance.new("UICorner")
		uiCorner.CornerRadius = UDim.new(0.5, 0)
		uiCorner.Parent = noteObj
		
		local reflection = Instance.new("Frame")
		reflection.Name = "Reflection"
		reflection.Size = UDim2.new(0.22, 0, 0.22, 0)
		reflection.Position = UDim2.new(0.22, 0, 0.22, 0)
		reflection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		reflection.BackgroundTransparency = 0.3
		reflection.BorderSizePixel = 0
		reflection.ZIndex = noteObj.ZIndex + 2
		reflection.Parent = noteObj
		
		local refCorner = Instance.new("UICorner")
		refCorner.CornerRadius = UDim.new(0.5, 0)
		refCorner.Parent = reflection
		
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2.5
		stroke.Parent = noteObj
		
		local core = Instance.new("Frame")
		core.Name = "Core"
		core.Size = UDim2.new(0.3, 0, 0.3, 0)
		core.Position = UDim2.new(0.35, 0, 0.35, 0)
		core.BorderSizePixel = 0
		core.ZIndex = noteObj.ZIndex + 1
		core.Parent = noteObj
		
		local coreCorner = Instance.new("UICorner")
		coreCorner.CornerRadius = UDim.new(0.5, 0)
		coreCorner.Parent = core
		
		local trail = Instance.new("Frame")
		trail.Name = "Trail"
		trail.AnchorPoint = Vector2.new(0.5, 1)
		trail.Position = UDim2.new(0.5, 0, 0.5, 0)
		trail.Size = UDim2.new(0, 24, 0, 0)
		trail.BorderSizePixel = 0
		trail.Visible = false
		trail.ZIndex = noteObj.ZIndex - 1
		trail.Parent = noteObj
		
		local trailCorner = Instance.new("UICorner")
		trailCorner.CornerRadius = UDim.new(0.5, 0)
		trailCorner.Parent = trail
		
		local trailStroke = Instance.new("UIStroke")
		trailStroke.Thickness = 1.5
		trailStroke.Parent = trail
		
		noteObj.Parent = screenGui
		table.insert(notePool, noteObj)
	end
	
	local trackColor = TrackColors[track] or Color3.fromRGB(240, 240, 240)
	
	-- Відновлення прозорості бульбашки
	noteObj.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	noteObj.BackgroundTransparency = 0.25
	
	local stroke = noteObj:FindFirstChildWhichIsA("UIStroke")
	if stroke then
		stroke.Color = trackColor
		stroke.Transparency = 0
	end
	
	local core = noteObj:FindFirstChild("Core")
	if core then
		core.BackgroundColor3 = Color3.fromRGB(150, 150, 150) -- Сіре ядро
		core.BackgroundTransparency = 0.4
	end
	
	local reflection = noteObj:FindFirstChild("Reflection")
	if reflection then
		reflection.BackgroundTransparency = 0.3
	end
	
	local targetButton = customGuiMode and customLanes[track]
	local trail = noteObj:FindFirstChild("Trail")
	
	if customGuiMode and targetButton then
		noteObj.Size = UDim2.new(0, 70, 0, 70)
		
		local targetXScale = targetButton.Position.X.Scale
		local targetXOffset = targetButton.Position.X.Offset + (targetButton.AbsoluteSize.X / 2)
		local startY = 0.1
		
		noteObj.Position = UDim2.new(targetXScale, targetXOffset, startY, 0)
		noteObj.Parent = screenGui
		
		if trail then
			if duration and duration > 0 then
				local endY = targetButton.Position.Y.Scale
				local pathLengthScale = endY - startY
				
				local screenHeight = screenGui.AbsoluteSize.Y
				if screenHeight == 0 then screenHeight = 800 end
				local totalHeightPixels = (duration / 1.1) * pathLengthScale * screenHeight
				
				trail.Size = UDim2.new(0, 24, 0, totalHeightPixels)
				trail.BackgroundColor3 = trackColor
				trail.BackgroundTransparency = 0.8
				trail.Visible = true
				
				local tStroke = trail:FindFirstChildWhichIsA("UIStroke")
				if tStroke then
					tStroke.Color = trackColor
					tStroke.Transparency = 0.3
				end
			else
				trail.Visible = false
			end
		end
	else
		local laneParent = rhythmFrame:FindFirstChild("Lane" .. track)
		noteObj.Size = UDim2.new(0, 70, 0, 70)
		noteObj.Position = UDim2.new(0.5, 0, 0, -35)
		noteObj.Parent = laneParent
		
		if trail then
			if duration and duration > 0 then
				local trackHeight = rhythmFrame.Size.Y.Offset - 85
				local totalHeightPixels = (duration / 1.1) * trackHeight
				trail.Size = UDim2.new(0, 24, 0, totalHeightPixels)
				trail.BackgroundColor3 = trackColor
				trail.BackgroundTransparency = 0.8
				trail.Visible = true
			else
				trail.Visible = false
			end
		end
	end
	
	noteObj.Visible = true
	return noteObj
end

-- Повернення ноти в пул
local function returnNoteToPool(note)
	note.Gui.Visible = false
	local trail = note.Gui:FindFirstChild("Trail")
	if trail then trail.Visible = false end
	note.Gui.Parent = screenGui
end

-- Створення інтерфейсу ритм-гри
local function createRhythmGui()
	local customGui = PlayerGui:FindFirstChild("MainGui--inGame", true)
	
	if customGui then
		print("🎨 Виявлено кастомний інтерфейс MainGui--inGame. Інтегруємо кнопки...")
		screenGui = customGui
		originalParent = customGui.Parent
		customGui.Parent = PlayerGui
		
		customGui.Enabled = true
		screenGui.Enabled = true
		customGuiMode = true
		
		rhythmFrame = customGui
		customLanes = {}
		customActiveFrames = {}
		
		local laneNames = {"x", "c", "n", "m"}
		local activeNames = {"x_active", "c_active", "n_active", "m_active"}
		
		for i = 1, 4 do
			local lane = customGui:FindFirstChild(laneNames[i], true)
			if lane then
				customLanes[i] = lane
				lane.Visible = true
				lane.BackgroundTransparency = 0.45 -- Робимо менш прозорим для кращої видимості
				
				local activeFrame = lane:FindFirstChild(activeNames[i], true)
				if activeFrame then
					customActiveFrames[i] = activeFrame
					activeFrame.Visible = false
				end
			else
				warn("⚠️ Не знайдено доріжку " .. laneNames[i] .. " у MainGui--inGame!")
			end
		end
		
		feedbackLabel = customGui:FindFirstChild("FeedbackLabel", true)
		if not feedbackLabel then
			feedbackLabel = Instance.new("TextLabel")
			feedbackLabel.Name = "FeedbackLabel"
			feedbackLabel.Size = UDim2.new(0, 400, 0, 50)
			feedbackLabel.Position = UDim2.new(0.5, -200, 0.45, 0)
			feedbackLabel.BackgroundTransparency = 1
			feedbackLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			feedbackLabel.TextSize = 36
			feedbackLabel.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
			feedbackLabel.Text = ""
			feedbackLabel.Parent = customGui
		end
		
		accuracyLabel = customGui:FindFirstChild("AccuracyLabel", true)
		if not accuracyLabel then
			accuracyLabel = Instance.new("TextLabel")
			accuracyLabel.Name = "AccuracyLabel"
			accuracyLabel.Size = UDim2.new(0, 400, 0, 30)
			accuracyLabel.Position = UDim2.new(0.5, -200, 0.05, 0)
			accuracyLabel.BackgroundTransparency = 1
			accuracyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			accuracyLabel.TextSize = 20
			accuracyLabel.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
			accuracyLabel.Text = "Accuracy: 100% | HP: 100"
			accuracyLabel.Parent = customGui
		end
		
		countdownLabel = customGui:FindFirstChild("CountdownLabel", true)
		if not countdownLabel then
			countdownLabel = Instance.new("TextLabel")
			countdownLabel.Name = "CountdownLabel"
			countdownLabel.Size = UDim2.new(0, 400, 0, 40)
			countdownLabel.Position = UDim2.new(0.5, -200, 0.78, 0) -- Розмістимо в нижній частині екрана
			countdownLabel.BackgroundTransparency = 1
			countdownLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
			countdownLabel.TextSize = 24
			countdownLabel.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
			countdownLabel.Text = ""
			countdownLabel.Visible = false
			countdownLabel.Parent = customGui
			
			local stroke = Instance.new("UIStroke")
			stroke.Thickness = 2
			stroke.Color = Color3.fromRGB(0, 0, 0)
			stroke.Parent = countdownLabel
		end
		
		hpBar = customGui:FindFirstChild("HPBar", true)
		if hpBar then
			hpBar.Visible = false
			local bg = hpBar.Parent
			if bg and bg:IsA("GuiObject") then
				bg.Visible = false
			end
		else
			local hpBackground = Instance.new("Frame")
			hpBackground.Name = "HPBackground"
			hpBackground.Size = UDim2.new(0.4, 0, 0, 12)
			hpBackground.Position = UDim2.new(0.3, 0, 0.1, 0)
			hpBackground.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			hpBackground.BorderSizePixel = 0
			hpBackground.Visible = false -- Приховуємо
			hpBackground.Parent = customGui
			
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0.5, 0)
			corner.Parent = hpBackground
			
			hpBar = Instance.new("Frame")
			hpBar.Name = "HPBar"
			hpBar.Size = UDim2.new(1, 0, 1, 0)
			hpBar.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
			hpBar.BorderSizePixel = 0
			hpBar.Visible = false -- Приховуємо
			hpBar.Parent = hpBackground
		end
	else
		customGuiMode = false
		print("ℹ️ Кастомний інтерфейс не знайдено. Створюємо стандартний...")
		
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "RhythmGameUI"
		screenGui.ResetOnSpawn = false
		screenGui.Parent = PlayerGui

		rhythmFrame = Instance.new("Frame")
		rhythmFrame.Size = UDim2.new(0, 400, 0, 600)
		rhythmFrame.Position = UDim2.new(0.5, -200, 0.5, -300)
		rhythmFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
		rhythmFrame.BorderSizePixel = 1
		rhythmFrame.BorderColor3 = Color3.fromRGB(180, 180, 180)
		rhythmFrame.Parent = screenGui

		local uiStroke = Instance.new("UIStroke")
		uiStroke.Color = Color3.fromRGB(220, 220, 220)
		uiStroke.Thickness = 2
		uiStroke.Parent = rhythmFrame

		for i = 1, 4 do
			local lane = Instance.new("Frame")
			lane.Name = "Lane" .. i
			lane.Size = UDim2.new(0.25, 0, 1, -80)
			lane.Position = UDim2.new(0.25 * (i - 1), 0, 0, 0)
			lane.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
			lane.BackgroundTransparency = 0.8
			lane.BorderSizePixel = 1
			lane.BorderColor3 = Color3.fromRGB(60, 60, 60)
			lane.Parent = rhythmFrame

			local keyLabel = Instance.new("TextLabel")
			keyLabel.Size = UDim2.new(1, 0, 0, 50)
			keyLabel.Position = UDim2.new(0, 0, 1, 0)
			keyLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
			keyLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
			keyLabel.TextSize = 20
			keyLabel.Text = currentKeybinds[i]
			keyLabel.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
			keyLabel.Parent = lane
		end

		local targetLine = Instance.new("Frame")
		targetLine.Name = "TargetLine"
		targetLine.Size = UDim2.new(1, 0, 0, 5)
		targetLine.Position = UDim2.new(0, 0, 1, -85)
		targetLine.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
		targetLine.BorderSizePixel = 0
		targetLine.Parent = rhythmFrame

		local hpBackground = Instance.new("Frame")
		hpBackground.Size = UDim2.new(1, 0, 0, 15)
		hpBackground.Position = UDim2.new(0, 0, 0, -25)
		hpBackground.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		hpBackground.Visible = false -- Приховуємо
		hpBackground.Parent = rhythmFrame

		hpBar = Instance.new("Frame")
		hpBar.Size = UDim2.new(1, 0, 1, 0)
		hpBar.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
		hpBar.BorderSizePixel = 0
		hpBar.Visible = false -- Приховуємо
		hpBar.Parent = hpBackground

		feedbackLabel = Instance.new("TextLabel")
		feedbackLabel.Size = UDim2.new(1, 0, 0, 50)
		feedbackLabel.Position = UDim2.new(0, 0, 0.4, 0)
		feedbackLabel.BackgroundTransparency = 1
		feedbackLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		feedbackLabel.TextSize = 32
		feedbackLabel.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
		feedbackLabel.Text = ""
		feedbackLabel.Parent = rhythmFrame

		accuracyLabel = Instance.new("TextLabel")
		accuracyLabel.Size = UDim2.new(1, 0, 0, 30)
		accuracyLabel.Position = UDim2.new(0, 0, 0, -60)
		accuracyLabel.BackgroundTransparency = 1
		accuracyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		accuracyLabel.TextSize = 22
		accuracyLabel.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
		accuracyLabel.Text = "Accuracy: 100% | HP: 100"
		accuracyLabel.Parent = rhythmFrame
		
		countdownLabel = Instance.new("TextLabel")
		countdownLabel.Name = "CountdownLabel"
		countdownLabel.Size = UDim2.new(1, 0, 0, 40)
		countdownLabel.Position = UDim2.new(0, 0, 1, 15) -- Трохи нижче за рамку гри
		countdownLabel.BackgroundTransparency = 1
		countdownLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
		countdownLabel.TextSize = 20
		countdownLabel.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
		countdownLabel.Text = ""
		countdownLabel.Visible = false
		countdownLabel.Parent = rhythmFrame
		
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 1.5
		stroke.Color = Color3.fromRGB(0, 0, 0)
		stroke.Parent = countdownLabel
	end
	
	createNotePool()
end

-- Створення візуальної ноти через пул
local function spawnNote(track, targetTime, duration)
	local noteGui = getNoteFromPool(track, targetTime, duration)
	
	table.insert(activeNotes, {
		Gui = noteGui,
		Track = track,
		TargetTime = targetTime,
		Duration = duration or 0,
		Hit = false,
		IsHolding = false,
		ScoreTicks = 0
	})
end

-- Відображення результатів виступу
local function showResultsScreen(finalAccuracy, rewards)
	local resultsFrame = Instance.new("Frame")
	resultsFrame.Name = "ResultsFrame"
	resultsFrame.Size = UDim2.new(1, 0, 1, 0)
	resultsFrame.Position = UDim2.new(0, 0, 0, 0)
	resultsFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
	resultsFrame.BackgroundTransparency = 0.08
	resultsFrame.BorderSizePixel = 0
	resultsFrame.Parent = screenGui

	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "ContentFrame"
	contentFrame.Size = UDim2.new(0, 600, 0, 520)
	contentFrame.Position = UDim2.new(0.5, -300, 0.5, -260)
	contentFrame.BackgroundTransparency = 1
	contentFrame.Parent = resultsFrame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 45)
	title.Position = UDim2.new(0, 0, 0, 15)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 28
	title.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
	title.Text = "PERFORMANCE STATS"
	title.Parent = contentFrame

	local songTitle = Instance.new("TextLabel")
	songTitle.Size = UDim2.new(1, 0, 0, 25)
	songTitle.Position = UDim2.new(0, 0, 0, 55)
	songTitle.BackgroundTransparency = 1
	songTitle.TextColor3 = Color3.fromRGB(160, 160, 160)
	songTitle.TextSize = 18
	songTitle.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
	songTitle.Text = string.format("%s (%s)", currentSong.Title, currentSong.Difficulty)
	songTitle.Parent = contentFrame

	local accuracyVal = Instance.new("TextLabel")
	accuracyVal.Size = UDim2.new(0.5, -20, 0, 70)
	accuracyVal.Position = UDim2.new(0, 20, 0, 95)
	accuracyVal.BackgroundTransparency = 1
	accuracyVal.TextColor3 = Color3.fromRGB(255, 255, 255)
	accuracyVal.TextSize = 56
	accuracyVal.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
	accuracyVal.Text = string.format("%d%%", finalAccuracy)
	accuracyVal.Parent = contentFrame

	local accuracyLabel = Instance.new("TextLabel")
	accuracyLabel.Size = UDim2.new(0.5, -20, 0, 20)
	accuracyLabel.Position = UDim2.new(0, 20, 0, 160)
	accuracyLabel.BackgroundTransparency = 1
	accuracyLabel.TextColor3 = Color3.fromRGB(130, 130, 130)
	accuracyLabel.TextSize = 15
	accuracyLabel.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
	accuracyLabel.Text = "ACCURACY"
	accuracyLabel.Parent = contentFrame

	local ratingsFrame = Instance.new("Frame")
	ratingsFrame.Size = UDim2.new(0.5, -20, 0, 100)
	ratingsFrame.Position = UDim2.new(0.5, 20, 0, 90)
	ratingsFrame.BackgroundTransparency = 1
	ratingsFrame.Parent = contentFrame

	local ratings = {
		{ name = "PERFECT", count = perfectCount, color = Color3.fromRGB(255, 255, 255) },
		{ name = "GOOD", count = goodCount, color = Color3.fromRGB(190, 190, 190) },
		{ name = "BAD", count = badCount, color = Color3.fromRGB(120, 120, 120) },
		{ name = "MISS", count = missCount, color = Color3.fromRGB(70, 70, 70) }
	}

	for idx, r in ipairs(ratings) do
		local yOffset = (idx - 1) * 24
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0.6, 0, 0, 20)
		label.Position = UDim2.new(0, 0, 0, yOffset)
		label.BackgroundTransparency = 1
		label.TextColor3 = r.color
		label.TextSize = 16
		label.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Text = r.name
		label.Parent = ratingsFrame

		local val = Instance.new("TextLabel")
		val.Size = UDim2.new(0.4, 0, 0, 20)
		val.Position = UDim2.new(0.6, 0, 0, yOffset)
		val.BackgroundTransparency = 1
		val.TextColor3 = Color3.fromRGB(220, 220, 220)
		val.TextSize = 16
		val.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
		val.TextXAlignment = Enum.TextXAlignment.Right
		val.Text = tostring(r.count)
		val.Parent = ratingsFrame
	end

	local rewardsFrame = Instance.new("Frame")
	rewardsFrame.Size = UDim2.new(1, -40, 0, 55)
	rewardsFrame.Position = UDim2.new(0, 20, 0, 195)
	rewardsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
	rewardsFrame.BorderSizePixel = 1
	rewardsFrame.BorderColor3 = Color3.fromRGB(60, 60, 60)
	rewardsFrame.Parent = contentFrame

	local rCorner = Instance.new("UICorner")
	rCorner.CornerRadius = UDim.new(0, 6)
	rCorner.Parent = rewardsFrame

	local xpVal = rewards and rewards.XPEarned or 0
	local cashVal = rewards and rewards.CashEarned or 0
	local fansVal = rewards and rewards.FansEarned or 0

	local rewardList = {
		{ name = "XP", val = "+" .. tostring(xpVal), color = Color3.fromRGB(240, 240, 240) },
		{ name = "Cash", val = "+" .. tostring(cashVal) .. "$", color = Color3.fromRGB(255, 255, 255) },
		{ name = "Fans", val = "+" .. tostring(fansVal), color = Color3.fromRGB(180, 180, 180) }
	}

	for idx, rew in ipairs(rewardList) do
		local xPos = (idx - 1) * 0.33
		local container = Instance.new("Frame")
		container.Size = UDim2.new(0.33, 0, 1, 0)
		container.Position = UDim2.new(xPos, 0, 0, 0)
		container.BackgroundTransparency = 1
		container.Parent = rewardsFrame

		local valLbl = Instance.new("TextLabel")
		valLbl.Size = UDim2.new(1, 0, 0.6, 0)
		valLbl.Position = UDim2.new(0, 0, 0.1, 0)
		valLbl.BackgroundTransparency = 1
		valLbl.TextColor3 = rew.color
		valLbl.TextSize = 20
		valLbl.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
		valLbl.Text = rew.val
		valLbl.Parent = container

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size = UDim2.new(1, 0, 0.4, 0)
		nameLbl.Position = UDim2.new(0, 0, 0.55, 0)
		nameLbl.BackgroundTransparency = 1
		nameLbl.TextColor3 = Color3.fromRGB(130, 130, 130)
		nameLbl.TextSize = 13
		nameLbl.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
		nameLbl.Text = rew.name:upper()
		nameLbl.Parent = container
	end

	local graphTitle = Instance.new("TextLabel")
	graphTitle.Size = UDim2.new(1, -40, 0, 20)
	graphTitle.Position = UDim2.new(0, 20, 0, 260)
	graphTitle.BackgroundTransparency = 1
	graphTitle.TextColor3 = Color3.fromRGB(160, 160, 160)
	graphTitle.TextSize = 14
	graphTitle.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
	graphTitle.TextXAlignment = Enum.TextXAlignment.Left
	graphTitle.Text = "PERFORMANCE TIMELINE (White = Perfect, Gray = Okay, Black = Miss):"
	graphTitle.Parent = contentFrame

	local graphBg = Instance.new("Frame")
	graphBg.Size = UDim2.new(1, -40, 0, 30)
	graphBg.Position = UDim2.new(0, 20, 0, 285)
	graphBg.BackgroundColor3 = Color3.fromRGB(16, 16, 18)
	graphBg.BorderSizePixel = 1
	graphBg.BorderColor3 = Color3.fromRGB(50, 50, 50)
	graphBg.Parent = contentFrame

	local gCorner = Instance.new("UICorner")
	gCorner.CornerRadius = UDim.new(0, 6)
	gCorner.Parent = graphBg

	local gLine = Instance.new("Frame")
	gLine.Size = UDim2.new(1, -20, 0, 2)
	gLine.Position = UDim2.new(0, 10, 0.5, -1)
	gLine.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	gLine.BorderSizePixel = 0
	gLine.Parent = graphBg

	local songLength = currentSong.Length
	for _, note in ipairs(noteHistory) do
		local ratio = math.clamp(note.time / songLength, 0, 1)
		
		local dot = Instance.new("Frame")
		dot.Size = UDim2.new(0, 4, 0, 12)
		dot.Position = UDim2.new(ratio, -2, 0.5, -6)
		dot.BorderSizePixel = 0
		
		if note.rating == "PERFECT" or note.rating == "GOOD" then
			dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		elseif note.rating == "BAD" then
			dot.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
		else
			dot.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			local dotStroke = Instance.new("UIStroke")
			dotStroke.Thickness = 1
			dotStroke.Color = Color3.fromRGB(100, 100, 100)
			dotStroke.Parent = dot
		end
		
		dot.Parent = gLine
	end

	local missTitle = Instance.new("TextLabel")
	missTitle.Size = UDim2.new(1, -40, 0, 20)
	missTitle.Position = UDim2.new(0, 20, 0, 325)
	missTitle.BackgroundTransparency = 1
	missTitle.TextColor3 = Color3.fromRGB(160, 160, 160)
	missTitle.TextSize = 14
	missTitle.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
	missTitle.TextXAlignment = Enum.TextXAlignment.Left
	missTitle.Text = "MISSED SECONDS:"
	missTitle.Parent = contentFrame

	local missScroll = Instance.new("ScrollingFrame")
	missScroll.Size = UDim2.new(1, -40, 0, 80)
	missScroll.Position = UDim2.new(0, 20, 0, 345)
	missScroll.BackgroundTransparency = 1
	missScroll.BorderSizePixel = 0
	missScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	missScroll.ScrollBarThickness = 4
	missScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
	missScroll.Parent = contentFrame

	local missListText = ""
	if #missSeconds == 0 then
		missListText = "Perfect! No mistakes! 🎉"
	else
		local secsStr = {}
		for _, sec in ipairs(missSeconds) do
			table.insert(secsStr, string.format("%.1fs", sec))
		end
		missListText = table.concat(secsStr, ", ")
	end

	local missTxtLabel = Instance.new("TextLabel")
	missTxtLabel.Size = UDim2.new(1, 0, 1, 0)
	missTxtLabel.BackgroundTransparency = 1
	missTxtLabel.TextColor3 = #missSeconds == 0 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(190, 190, 190)
	missTxtLabel.TextSize = 14
	missTxtLabel.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
	missTxtLabel.TextWrapped = true
	missTxtLabel.TextXAlignment = Enum.TextXAlignment.Left
	missTxtLabel.TextYAlignment = Enum.TextYAlignment.Top
	missTxtLabel.Text = missListText
	missTxtLabel.Parent = missScroll

	local continueBtn = Instance.new("TextButton")
	continueBtn.Size = UDim2.new(0, 220, 0, 45)
	continueBtn.Position = UDim2.new(0.5, -110, 1, -65)
	continueBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 26)
	continueBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	continueBtn.TextSize = 18
	continueBtn.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
	continueBtn.Text = "CONTINUE"
	continueBtn.Parent = contentFrame

	local cCorner = Instance.new("UICorner")
	cCorner.CornerRadius = UDim.new(0, 8)
	cCorner.Parent = continueBtn

	local cStroke = Instance.new("UIStroke")
	cStroke.Color = Color3.fromRGB(200, 200, 200)
	cStroke.Thickness = 1.5
	cStroke.Parent = continueBtn

	continueBtn.MouseEnter:Connect(function()
		TweenService:Create(continueBtn, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			TextColor3 = Color3.fromRGB(12, 12, 14)
		}):Play()
	end)

	continueBtn.MouseLeave:Connect(function()
		TweenService:Create(continueBtn, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(24, 24, 26),
			TextColor3 = Color3.fromRGB(255, 255, 255)
		}):Play()
	end)

	continueBtn.MouseButton1Click:Connect(function()
		if customGuiMode then
			screenGui.Enabled = false
			feedbackLabel.Text = ""
			if countdownLabel then
				countdownLabel.Text = ""
				countdownLabel.Visible = false
			end
			if originalParent then
				screenGui.Parent = originalParent
			end
		else
			if screenGui then
				screenGui:Destroy()
				screenGui = nil
				countdownLabel = nil
			end
		end
	end)
end

-- Завершення гри
local function endSong(failed)
	if not isPlaying then return end
	isPlaying = false

	-- ЗУПИНЯЄМО І ВИДАЛЯЄМО ЗВУК ПІСНІ
	if activeSongSound then
		pcall(function()
			activeSongSound:Stop()
			activeSongSound:Destroy()
		end)
		activeSongSound = nil
	end

	local finalAccuracy = 0
	if notesTotal > 0 and not failed then
		finalAccuracy = math.round((notesHit / notesTotal) * 100)
	end
	
	if failed then
		feedbackLabel.Text = "GAME OVER!"
		feedbackLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		finalAccuracy = 0
	else
		feedbackLabel.Text = "SONG COMPLETED!"
		feedbackLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	end

	-- Очищаємо всі ноти
	for _, note in ipairs(activeNotes) do
		returnNoteToPool(note)
	end
	activeNotes = {}
	heldTracks = {false, false, false, false}

	-- Надсилаємо результати на сервер та отримуємо нагороди
	local success, rewards = FinishSongFunc:InvokeServer(finalAccuracy)

	if not failed then
		-- Приховуємо ігровий інтерфейс
		for _, child in ipairs(screenGui:GetChildren()) do
			if child:IsA("GuiObject") and child.Name ~= "ResultsFrame" and child.Name ~= "FeedbackLabel" then
				child.Visible = false
			end
		end
		
		-- Показуємо екран результатів
		showResultsScreen(finalAccuracy, rewards)
	else
		task.wait(2)
		-- Закриття/очищення інтерфейсу при провалі
		if customGuiMode then
			screenGui.Enabled = false
			feedbackLabel.Text = ""
			if countdownLabel then
				countdownLabel.Text = ""
				countdownLabel.Visible = false
			end
			if originalParent then
				screenGui.Parent = originalParent
			end
		else
			if screenGui then
				screenGui:Destroy()
				screenGui = nil
				countdownLabel = nil
			end
		end
	end
end

-- Початок ритм-гри
StartSongEvent.OnClientEvent:Connect(function(song, contractName)
	updateKeybinds()
	currentSong = song
	currentContractName = contractName
	isPlaying = true
	activeNotes = {}
	spawnedNoteIndex = 1
	notesHit = 0
	notesTotal = #song.Notes
	currentHp = 100
	heldTracks = {false, false, false, false}
	perfectCount = 0
	goodCount = 0
	badCount = 0
	missCount = 0
	missSeconds = {}
	noteHistory = {}
	local songEndTime = nil

	-- СТВОРЕННЯ ТА ПРОГРАВАННЯ МУЗИЧНОЇ ДОРІЖКИ ПІСНІ
	if song.AudioId and song.AudioId ~= "" and song.AudioId ~= "rbxassetid://0" then
		local success, err = pcall(function()
			print("🎵 Спроба запуску аудіодоріжки:", song.AudioId)
			activeSongSound = Instance.new("Sound")
			activeSongSound.SoundId = song.AudioId
			activeSongSound.Volume = 0.7 -- Хороший рівень гучності
			activeSongSound.Parent = game.Workspace.CurrentCamera -- 2D звук безпосередньо у вуха гравця
			activeSongSound:Play()
		end)
		if not success then
			warn("⚠️ Помилка створення або запуску звуку:", err)
		end
	else
		warn("⚠️ Аудіодоріжку не запущено: ID порожній або rbxassetid://0")
	end

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

	-- Запускаємо пісню негайно
	songStartTime = os.clock()

	-- Ігровий цикл
	local connection
	connection = RunService.RenderStepped:Connect(function()
		if not isPlaying then
			connection:Disconnect()
			return
		end

		local elapsed = os.clock() - songStartTime

		-- Динамічне завершення пісні після останньої ноти з затримкою в 3 секунди
		if spawnedNoteIndex > #currentSong.Notes and #activeNotes == 0 then
			if not songEndTime then
				songEndTime = os.clock() + 3.0
			elseif os.clock() >= songEndTime then
				connection:Disconnect()
				endSong(false)
				return
			end
		end

		-- Захисний ліміт на випадок багів (якщо ноти застрягли)
		if elapsed >= currentSong.Length + 15 then
			connection:Disconnect()
			endSong(false)
			return
		end

		-- Спавн нот відповідно до розкладу
		local spawnPreDelay = 1.1
		while spawnedNoteIndex <= #currentSong.Notes do
			local note = currentSong.Notes[spawnedNoteIndex]
			if note.time - spawnPreDelay <= elapsed then
				spawnNote(note.track, note.time, note.duration)
				spawnedNoteIndex = spawnedNoteIndex + 1
			else
				break
			end
		end

		-- Оновлення позиції активних нот
		for i = #activeNotes, 1, -1 do
			local note = activeNotes[i]
			local timeDiff = note.TargetTime - elapsed
			local progress = 1 - (timeDiff / spawnPreDelay)

			local targetButton = customLanes[note.Track]
			local startY = 0.1
			local endY = targetButton and targetButton.Position.Y.Scale or 0.85
			local pathLengthScale = endY - startY

			local trackColor = TrackColors[note.Track] or Color3.fromRGB(240, 240, 240)

			if note.IsHolding then
				if targetButton then
					local targetXScale = targetButton.Position.X.Scale
					local targetXOffset = targetButton.Position.X.Offset + (targetButton.AbsoluteSize.X / 2)
					local targetYScale = targetButton.Position.Y.Scale
					local targetYOffset = targetButton.Position.Y.Offset + (targetButton.AbsoluteSize.Y / 2)
					
					note.Gui.Position = UDim2.new(targetXScale, targetXOffset, targetYScale, targetYOffset)
				end
				
				-- Розрахунок залишку часу затискання
				local timeLeft = (note.TargetTime + note.Duration) - elapsed
				local trail = note.Gui:FindFirstChild("Trail")
				
				if timeLeft > 0 then
					if trail then
						local screenHeight = screenGui.AbsoluteSize.Y
						if screenHeight == 0 then screenHeight = 800 end
						
						local currentHeightPixels = math.max(0, (timeLeft / spawnPreDelay) * pathLengthScale * screenHeight)
						trail.Size = UDim2.new(0, 24, 0, currentHeightPixels)
					end
					
					-- Очки за тримання (Hold tick)
					note.ScoreTicks = note.ScoreTicks + 1
					if note.ScoreTicks % 10 == 0 then
						notesHit = notesHit + 0.08
						
						local activeFrame = customGuiMode and customActiveFrames[note.Track]
						if activeFrame then
							activeFrame.Visible = true
							activeFrame.BackgroundColor3 = trackColor
							activeFrame.BackgroundTransparency = 0.3
						end
					end
				else
					-- Затискання успішно завершено! Лінія зникає повністю!
					note.IsHolding = false
					if trail then trail.Visible = false end
					returnNoteToPool(note)
					table.remove(activeNotes, i)
					
					soundPerfect:Play()
					popFeedback("HOLD COMPLETE!", Color3.fromRGB(255, 255, 255))
					notesHit = notesHit + 1.2
					perfectCount = perfectCount + 1
					table.insert(noteHistory, { time = note.TargetTime + note.Duration, rating = "PERFECT" })
					
					local activeFrame = customGuiMode and customActiveFrames[note.Track]
					if activeFrame then
						activeFrame.Visible = false
					end
				end
			else
				-- Як звичайні, так і влучені ноти продовжують летіти вниз!
				if timeDiff < -0.25 then
					-- Нота вийшла за межі доріжки
					if not note.Hit then
						-- Пропуск ноти (Miss) - тільки якщо по ній НЕ попали!
						triggerMiss()
						popFeedback("MISS!", Color3.fromRGB(120, 120, 120))
						missCount = missCount + 1
						table.insert(noteHistory, { time = note.TargetTime, rating = "MISS" })
					end
					
					returnNoteToPool(note)
					table.remove(activeNotes, i)
				else
					-- Рух ноти вниз
					if customGuiMode and targetButton then
						local targetXScale = targetButton.Position.X.Scale
						local targetXOffset = targetButton.Position.X.Offset + (targetButton.AbsoluteSize.X / 2)
						local currentYScale = startY + progress * pathLengthScale
						
						note.Gui.Position = UDim2.new(targetXScale, targetXOffset, currentYScale, 0)
					else
						local yPosScale = progress * 0.85
						note.Gui.Position = UDim2.new(0.5, 0, yPosScale, 0)
					end
					
					-- Візуальний ефект для влученої ноти (стає напівпрозорою)
					if note.Hit then
						note.Gui.BackgroundTransparency = 0.95
						local stroke = note.Gui:FindFirstChildWhichIsA("UIStroke")
						if stroke then stroke.Transparency = 0.95 end
						
						local core = note.Gui:FindFirstChild("Core")
						if core then core.BackgroundTransparency = 0.95 end
						
						local reflection = note.Gui:FindFirstChild("Reflection")
						if reflection then reflection.BackgroundTransparency = 0.95 end
						
						local trail = note.Gui:FindFirstChild("Trail")
						if trail then
							trail.BackgroundTransparency = 0.98
							local tStroke = trail:FindFirstChildWhichIsA("UIStroke")
							if tStroke then tStroke.Transparency = 0.98 end
						end
					else
						note.Gui.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
						note.Gui.BackgroundTransparency = 0.25
						
						local stroke = note.Gui:FindFirstChildWhichIsA("UIStroke")
						if stroke then
							stroke.Color = trackColor
							stroke.Transparency = 0
						end
						
						local core = note.Gui:FindFirstChild("Core")
						if core then
							core.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
							core.BackgroundTransparency = 0.4
						end
						
						local reflection = note.Gui:FindFirstChild("Reflection")
						if reflection then
							reflection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
							reflection.BackgroundTransparency = 0.3
						end
					end
				end
			end
		end

		-- Оновлення статус-панелі
		local currentAcc = (notesTotal > 0) and math.round((notesHit / notesTotal) * 100) or 100
		accuracyLabel.Text = string.format("Accuracy: %d%%", currentAcc)

		-- Відображення таймера до появи наступної ноти
		local nextNote = currentSong.Notes[spawnedNoteIndex]
		if nextNote and #activeNotes == 0 and countdownLabel then
			local timeUntilSpawn = (nextNote.time - spawnPreDelay) - elapsed
			if timeUntilSpawn > 0.1 then
				if timeUntilSpawn > 2.0 or countdownLabel.Visible then
					countdownLabel.Visible = true
					countdownLabel.Text = tostring(math.ceil(timeUntilSpawn))
					
					-- Пульсуючий ефект прозорості
					countdownLabel.TextTransparency = 0.15 + math.sin(os.clock() * 6.5) * 0.15
				end
			else
				countdownLabel.Visible = false
			end
		elseif countdownLabel then
			countdownLabel.Visible = false
		end
	end)
end)

-- Обробка натискання клавіш
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

	-- Захист від Windows KeyRepeat: якщо клавіша вже затиснута, ігноруємо повторні події
	if heldTracks[pressedTrack] then return end
	heldTracks[pressedTrack] = true

	local trackColor = TrackColors[pressedTrack] or Color3.fromRGB(240, 240, 240)

	local activeFrame = customGuiMode and customActiveFrames[pressedTrack]
	if activeFrame then
		activeFrame.Visible = true
		activeFrame.BackgroundColor3 = trackColor
		activeFrame.BackgroundTransparency = 0.3 -- Приглушене біле світіння
	end

	local elapsed = os.clock() - songStartTime
	local bestNote = nil
	local minTimeDiff = 999

	for _, note in ipairs(activeNotes) do
		if note.Track == pressedTrack and not note.Hit and not note.IsHolding then
			local diff = math.abs(note.TargetTime - elapsed)
			if diff < minTimeDiff then
				minTimeDiff = diff
				bestNote = note
			end
		end
	end

	if bestNote and minTimeDiff <= 0.25 then
		if bestNote.Duration > 0 then
			bestNote.IsHolding = true
			
			if activeFrame then
				activeFrame.BackgroundColor3 = trackColor
				activeFrame.BackgroundTransparency = 0.3
			end
			popFeedback("HOLD START!", Color3.fromRGB(255, 255, 255))
			soundPerfect:Play()
			spawnHitParticles(pressedTrack, "PERFECT!")
			pulseButton(pressedTrack)
			cameraShake(0.04, 0.06)
			perfectCount = perfectCount + 1
			table.insert(noteHistory, { time = bestNote.TargetTime, rating = "PERFECT" })
		else
			bestNote.Hit = true

			if minTimeDiff <= 0.08 then
				popFeedback("PERFECT!", Color3.fromRGB(255, 255, 255))
				notesHit = notesHit + 1
				soundPerfect:Play()
				spawnHitParticles(pressedTrack, "PERFECT!")
				pulseButton(pressedTrack)
				cameraShake(0.05, 0.08)
				perfectCount = perfectCount + 1
				table.insert(noteHistory, { time = bestNote.TargetTime, rating = "PERFECT" })
				
				if activeFrame then
					activeFrame.BackgroundColor3 = trackColor
					activeFrame.BackgroundTransparency = 0.3
				end
			elseif minTimeDiff <= 0.18 then
				popFeedback("GOOD!", Color3.fromRGB(200, 200, 200))
				notesHit = notesHit + 0.75
				soundPerfect:Play()
				spawnHitParticles(pressedTrack, "GOOD!")
				pulseButton(pressedTrack)
				cameraShake(0.02, 0.06)
				goodCount = goodCount + 1
				table.insert(noteHistory, { time = bestNote.TargetTime, rating = "GOOD" })
				
				if activeFrame then
					activeFrame.BackgroundColor3 = trackColor
					activeFrame.BackgroundTransparency = 0.4
				end
			else
				popFeedback("BAD!", Color3.fromRGB(120, 120, 120))
				notesHit = notesHit + 0.25
				triggerMiss()
				spawnHitParticles(pressedTrack, "BAD!")
				badCount = badCount + 1
				table.insert(noteHistory, { time = bestNote.TargetTime, rating = "BAD" })
				
				if activeFrame then
					activeFrame.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
					activeFrame.BackgroundTransparency = 0.5
				end
			end
		end
	else
		triggerMiss()
		popFeedback("BAD!", Color3.fromRGB(120, 120, 120))
		badCount = badCount + 1
		table.insert(noteHistory, { time = elapsed, rating = "BAD" })
		
		if activeFrame then
			activeFrame.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
			activeFrame.BackgroundTransparency = 0.5
		end
	end
end)

-- Обробка відпускання клавіш
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

	-- Скидаємо статус утримання клавіші
	heldTracks[releasedTrack] = false

	local activeFrame = customGuiMode and customActiveFrames[releasedTrack]
	if activeFrame then
		activeFrame.Visible = false
	end

	local elapsed = os.clock() - songStartTime
	for _, note in ipairs(activeNotes) do
		if note.Track == releasedTrack and note.IsHolding then
			local endHoldTime = note.TargetTime + note.Duration
			
			if elapsed < endHoldTime - 0.15 then
				-- Ранній відпуск (Hold Break). Лінія зникає відразу!
				note.IsHolding = false
				local trail = note.Gui:FindFirstChild("Trail")
				if trail then trail.Visible = false end
				returnNoteToPool(note)
				
				triggerMiss()
				popFeedback("HOLD BREAK!", Color3.fromRGB(100, 100, 100))
				missCount = missCount + 1
				table.insert(noteHistory, { time = elapsed, rating = "MISS" })
			end
		end
	end
end)
