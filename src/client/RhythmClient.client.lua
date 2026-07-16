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

-- ÐŸÐ¾Ñ‚Ð¾Ñ‡Ð½Ð¸Ð¹ ÑÑ‚Ð°Ð½ Ð³Ñ€Ð¸
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
local heldTracks = {false, false, false, false} -- ÐœÐ°ÑÐ¸Ð² Ð´Ð»Ñ Ð²Ñ–Ð´ÑÑ‚ÐµÐ¶ÐµÐ½Ð½Ñ Ð·Ð°Ñ‚Ð¸ÑÐ½ÑƒÑ‚Ð¸Ñ… ÐºÐ»Ð°Ð²Ñ–Ñˆ (Ð±Ð»Ð¾ÐºÑƒÑ” Windows KeyRepeat)
local activeSongSound = nil -- ÐžÐ±'Ñ”ÐºÑ‚ Ð¿Ñ€Ð¾Ð³Ñ€Ð°Ð²Ð°Ð½Ð½Ñ Ð¿Ð¾Ñ‚Ð¾Ñ‡Ð½Ð¾Ñ— Ð°ÑƒÐ´Ñ–Ð¾Ð´Ð¾Ñ€Ñ–Ð¶ÐºÐ¸ Ð¿Ñ–ÑÐ½Ñ–

-- ÐœÑ–Ð½Ñ–Ð¼Ð°Ð»Ñ–ÑÑ‚Ð¸Ñ‡Ð½Ð° Ñ‚ÐµÐ¼Ð½Ð¾-Ð±Ñ–Ð»Ð° Ð¿Ð°Ð»Ñ–Ñ‚Ñ€Ð° ÐºÐ¾Ð»ÑŒÐ¾Ñ€Ñ–Ð² (Monochrome Theme)
local TrackColors = {
	Color3.fromRGB(240, 240, 240),   -- 1 Ð´Ð¾Ñ€Ñ–Ð¶ÐºÐ°: Ð§Ð¸ÑÑ‚Ð¸Ð¹ Ð±Ñ–Ð»Ð¸Ð¹
	Color3.fromRGB(200, 200, 200),   -- 2 Ð´Ð¾Ñ€Ñ–Ð¶ÐºÐ°: Ð¡Ð²Ñ–Ñ‚Ð»Ð¾-ÑÑ–Ñ€Ð¸Ð¹
	Color3.fromRGB(160, 160, 160),   -- 3 Ð´Ð¾Ñ€Ñ–Ð¶ÐºÐ°: Ð¡Ñ–Ñ€Ð¸Ð¹
	Color3.fromRGB(120, 120, 120)    -- 4 Ð´Ð¾Ñ€Ñ–Ð¶ÐºÐ°: Ð¢ÐµÐ¼Ð½Ð¾-ÑÑ–Ñ€Ð¸Ð¹
}

-- GUI Ð•Ð»ÐµÐ¼ÐµÐ½Ñ‚Ð¸
local screenGui = nil
local rhythmFrame = nil
local hpBar = nil
local feedbackLabel = nil
local accuracyLabel = nil
local countdownLabel = nil

-- Ð¡Ñ‚Ð°Ñ‚Ð¸ÑÑ‚Ð¸ÐºÐ° Ð´Ð»Ñ Ð²Ñ–ÐºÐ½Ð° Ñ€ÐµÐ·ÑƒÐ»ÑŒÑ‚Ð°Ñ‚Ñ–Ð²
local perfectCount = 0
local goodCount = 0
local badCount = 0
local missCount = 0
local missSeconds = {}
local noteHistory = {}

-- Ð•Ð»ÐµÐ¼ÐµÐ½Ñ‚Ð¸ ÐºÐ°ÑÑ‚Ð¾Ð¼Ð½Ð¾Ð³Ð¾ GUI (MainGui--inGame)
local customGuiMode = false
local customLanes = {}       -- {x, c, n, m}
local customActiveFrames = {} -- {x_active, c_active, n_active, m_active}
local originalParent = nil

-- Ð¡Ð¸Ð½Ñ…Ñ€Ð¾Ð½Ð½Ð¾ Ð¿Ñ€Ð¸Ñ…Ð¾Ð²ÑƒÑ”Ð¼Ð¾ Ñ–Ð½Ñ‚ÐµÑ€Ñ„ÐµÐ¹Ñ Ð³Ñ€Ð¸ Ð¿Ñ€Ð¸ Ð·Ð°Ð¿ÑƒÑÐºÑƒ ÐºÐ»Ñ–Ñ”Ð½Ñ‚Ð° (ÑƒÑÑƒÐ²Ð°Ñ” Ñ€Ð°ÑÑÐ¸Ð½Ñ…Ñ€Ð¾Ð½Ñ–Ð·Ð°Ñ†Ñ–ÑŽ Ñ‚Ð° Ð±Ð°Ð³ Ð·Ð½Ð¸ÐºÐ½ÐµÐ½Ð½Ñ)
local startupGui = PlayerGui:FindFirstChild("MainGui--inGame", true)
if startupGui then
	startupGui.Enabled = false
end

-- ÐžÐ¿Ñ‚Ð¸Ð¼Ñ–Ð·Ð°Ñ†Ñ–Ñ: ÐŸÑƒÐ» Ð¾Ð±'Ñ”ÐºÑ‚Ñ–Ð² Ð´Ð»Ñ Ð½Ð¾Ñ‚ (Object Pooling)
local NOTE_POOL_SIZE = 30
local notePool = {}

-- Ð—Ð²ÑƒÐºÐ¾Ð²Ñ– ÐµÑ„ÐµÐºÑ‚Ð¸
local soundDefect = Instance.new("Sound")
soundDefect.SoundId = "rbxassetid://1848228518" -- Ð“Ñ–Ñ‚Ð°Ñ€Ð½Ð¸Ð¹ ÑÐºÑ€Ð¸Ð¿/Ð¿Ð¾Ð¼Ð¸Ð»ÐºÐ° (Guitar Scratches Ð²Ñ–Ð´ APM Music)
soundDefect.Volume = 0.6
soundDefect.PlaybackSpeed = 1.0
soundDefect.Parent = game.Workspace.CurrentCamera

local soundPerfect = Instance.new("Sound")
soundPerfect.SoundId = "rbxassetid://876939830" -- Ð“Ð°Ñ€Ð°Ð½Ñ‚Ð¾Ð²Ð°Ð½Ð¸Ð¹ ÐºÐ»Ñ–Ðº Ð²Ñ–Ð´ Roblox
soundPerfect.Volume = 0.4
soundPerfect.PlaybackSpeed = 1.4 -- Ð’Ð¸Ñ‰Ð¸Ð¹ Ñ‚Ð¾Ð½ Ð´Ð»Ñ Ð²Ð»ÑƒÑ‡Ð°Ð½Ð½Ñ
soundPerfect.Parent = game.Workspace.CurrentCamera

-- Ð›Ð¾Ð³Ñ–ÐºÐ° Ð¿Ñ€Ð¸Ð³Ð»ÑƒÑˆÐµÐ½Ð½Ñ Ð¼ÑƒÐ·Ð¸ÐºÐ¸ Ð½Ð° 0.3 ÑÐµÐº Ñ‚Ð° ÐºÐµÑ€ÑƒÐ²Ð°Ð½Ð½Ñ Ð·Ð²ÑƒÐºÐ¾Ð¼ Ð¿Ð¾Ð¼Ð¸Ð»ÐºÐ¸
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
			activeSongSound.Volume = 0.15 -- ÐŸÑ€Ð¸Ð³Ð»ÑƒÑˆÑƒÑ”Ð¼Ð¾ Ð³ÑƒÑ‡Ð½Ñ–ÑÑ‚ÑŒ
		end)
		
		if dimThread then
			task.cancel(dimThread)
		end
		
		dimThread = task.delay(0.3, function()
			if activeSongSound and isPlaying then
				pcall(function()
					activeSongSound.Volume = 0.7 -- Ð’Ñ–Ð´Ð½Ð¾Ð²Ð»ÑŽÑ”Ð¼Ð¾ Ð³ÑƒÑ‡Ð½Ñ–ÑÑ‚ÑŒ
				end)
			end
			dimThread = nil
		end)
	end
	
	-- Ð—ÑƒÐ¿Ð¸Ð½ÑÑ”Ð¼Ð¾/Ð·Ð°Ñ‚ÑƒÑ…Ð°Ñ”Ð¼Ð¾ Ð·Ð²ÑƒÐº Ð¿Ð¾Ð¼Ð¸Ð»ÐºÐ¸ Ñ‡ÐµÑ€ÐµÐ· 0.2 ÑÐµÐº
	if missSoundThread then
		task.cancel(missSoundThread)
	end
	
	missSoundThread = task.delay(0.2, function()
		-- ÐŸÐ»Ð°Ð²Ð½Ðµ Ð·Ð°Ñ‚ÑƒÑ…Ð°Ð½Ð½Ñ Ð·Ð° 0.05 ÑÐµÐº
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

-- Ð›ÐµÐ³ÐºÐµ Ñ‚Ñ€ÐµÐ¼Ñ‚Ñ–Ð½Ð½Ñ ÐºÐ°Ð¼ÐµÑ€Ð¸ (Camera Shake) Ð´Ð»Ñ Ð´Ð¸Ð½Ð°Ð¼Ñ–ÐºÐ¸
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

-- Ð•Ñ„ÐµÐºÑ‚Ð½Ð° Ð°Ð½Ñ–Ð¼Ð°Ñ†Ñ–Ñ Ð¾Ñ†Ñ–Ð½ÐºÐ¸ (Perfect/Good/Miss)
local function popFeedback(text, color)
	feedbackLabel.Text = text
	feedbackLabel.TextColor3 = color
	feedbackLabel.TextSize = 88
	feedbackLabel.Rotation = math.random(-8, 8)
	
	-- Ð¡Ñ‚Ð²Ð¾Ñ€ÑŽÑ”Ð¼Ð¾ Ð»ÐµÐ³ÐºÐ¸Ð¹ Ñ€ÑƒÑ… Ñ‚ÐµÐºÑÑ‚Ñƒ Ð²Ð³Ð¾Ñ€Ñƒ
	local originalPosition = customGuiMode and UDim2.new(0.5, -200, 0.45, 0) or UDim2.new(0, 0, 0.4, 0)
	feedbackLabel.Position = originalPosition
	
	local tweenInfo = TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(feedbackLabel, tweenInfo, {
		TextSize = 76,
		Rotation = 0
	}):Play()
end

-- ÐŸÑƒÐ»ÑŒÑÐ°Ñ†Ñ–Ñ ÐºÐ½Ð¾Ð¿ÐºÐ¸ Ð¿Ñ€Ð¸ Ð²Ð»ÑƒÑ‡Ð°Ð½Ð½Ñ–
local function pulseButton(track)
	local button = customLanes[track]
	if not button then return end
	
	-- Ð¡Ñ‚Ð²Ð¾Ñ€ÑŽÑ”Ð¼Ð¾ ÑˆÐ²Ð¸Ð´ÐºÐ¸Ð¹ ÐµÑ„ÐµÐºÑ‚ ÑÑ‚Ð¸ÑÐ½ÐµÐ½Ð½Ñ/Ñ€Ð¾Ð·ÑˆÐ¸Ñ€ÐµÐ½Ð½Ñ
	local originalSize = UDim2.new(0, 85, 0, 79)
	button.Size = UDim2.new(0, 95, 0, 88)
	
	local tweenInfo = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(button, tweenInfo, {Size = originalSize}):Play()
end

-- Ð—Ð°Ð²Ð°Ð½Ñ‚Ð°Ð¶ÐµÐ½Ð½Ñ Ð½Ð°Ð»Ð°ÑˆÑ‚ÑƒÐ²Ð°Ð½ÑŒ Ð³Ñ€Ð°Ð²Ñ†Ñ
local function updateKeybinds()
	local success, data = pcall(function()
		return RequestPlayerDataFunc:InvokeServer()
	end)
	if success and data and data.Keybinds then
		currentKeybinds = data.Keybinds
	end
end

-- Ð•Ñ„ÐµÐºÑ‚ Ð²Ð¸Ð±ÑƒÑ…Ñƒ Ñ‡Ð°ÑÑ‚Ð¸Ð½Ð¾Ðº-Ð±ÑƒÐ»ÑŒÐ±Ð°ÑˆÐ¾Ðº Ð¿Ñ€Ð¸ ÑƒÑÐ¿Ñ–ÑˆÐ½Ð¾Ð¼Ñƒ Ð½Ð°Ñ‚Ð¸ÑÐºÐ°Ð½Ð½Ñ– (Juice Effect) - Ñƒ Ð¼Ð¾Ð½Ð¾Ñ…Ñ€Ð¾Ð¼Ð½Ð¸Ñ… ÐºÐ¾Ð»ÑŒÐ¾Ñ€Ð°Ñ…
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

	-- Ð¡Ñ‚Ð²Ð¾Ñ€ÑŽÑ”Ð¼Ð¾ 12 ÐºÑ€ÑƒÐ³Ð»Ð¸Ñ… Ñ‡Ð°ÑÑ‚Ð¸Ð½Ð¾Ðº, Ñ‰Ð¾ Ñ€Ð¾Ð·Ð»Ñ–Ñ‚Ð°ÑŽÑ‚ÑŒÑÑ ÑˆÐ²Ð¸Ð´ÑˆÐµ
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
			math.random(2, 4) / 10, -- 0.2 - 0.4 ÑÐµÐº
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

-- Ð¡Ñ‚Ð²Ð¾Ñ€ÐµÐ½Ð½Ñ Ð¿ÑƒÐ»Ñƒ Ð½Ð¾Ñ‚
local function createNotePool()
	for _, obj in ipairs(notePool) do
		pcall(function() obj:Destroy() end)
	end
	notePool = {}
	
	for i = 1, NOTE_POOL_SIZE do
		-- ÐšÑ€Ð°ÑÐ¸Ð²Ð° ÐºÑ€ÑƒÐ³Ð»Ð° Ð½Ð¾Ñ‚Ð° Ñƒ Ð²Ð¸Ð³Ð»ÑÐ´Ñ– Ð±ÑƒÐ»ÑŒÐ±Ð°ÑˆÐºÐ¸ (Glossy Bubble)
		local noteObj = Instance.new("Frame")
		noteObj.Name = "NoteNode"
		noteObj.BorderSizePixel = 0
		noteObj.BackgroundColor3 = Color3.fromRGB(25, 25, 25) -- Ð¢ÐµÐ¼Ð½Ð¾-Ñ‡Ð¾Ñ€Ð½Ðµ Ñ‚Ñ–Ð»Ð¾
		noteObj.BackgroundTransparency = 0.25 -- ÐœÐµÐ½ÑˆÐµ Ð¿Ñ€Ð¾Ð·Ð¾Ñ€Ð¾ÑÑ‚Ñ– Ð´Ð»Ñ Ð²Ð¸Ñ€Ð°Ð¶ÐµÐ½Ð¾Ð³Ð¾ Ñ‡Ð¾Ñ€Ð½Ð¾-ÑÑ–Ñ€Ð¾Ð³Ð¾ Ð²Ð¸Ð³Ð»ÑÐ´Ñƒ
		noteObj.AnchorPoint = Vector2.new(0.5, 0.5)
		noteObj.ZIndex = 10
		noteObj.Visible = false
		
		local uiCorner = Instance.new("UICorner")
		uiCorner.CornerRadius = UDim.new(0.5, 0)
		uiCorner.Parent = noteObj
		
		-- Ð‘Ð»Ð¸ÑÐºÑƒÑ‡Ð¸Ð¹ Ð²Ñ–Ð´Ð±Ð»Ð¸ÑÐº ÑÐ²Ñ–Ñ‚Ð»Ð° Ñƒ Ð²ÐµÑ€Ñ…Ð½ÑŒÐ¾Ð¼Ñƒ Ð»Ñ–Ð²Ð¾Ð¼Ñƒ ÐºÑƒÑ‚ÐºÑƒ (Bubble Reflection)
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
		
		-- ÐžÐ±Ð²Ð¾Ð´ÐºÐ° (Ñ‚ÐµÐ¼Ð½Ð¾-Ð±Ñ–Ð»Ð¸Ð¹ ÐºÐ¾Ð½Ñ‚ÑƒÑ€ Ð±ÑƒÐ»ÑŒÐ±Ð°ÑˆÐºÐ¸)
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2.5
		stroke.Parent = noteObj
		
		-- ÐšÐ¾Ð»ÑŒÐ¾Ñ€Ð¾Ð²Ðµ Ð¼'ÑÐºÐµ ÑÐ´Ñ€Ð¾ (Core) Ð²ÑÐµÑ€ÐµÐ´Ð¸Ð½Ñ–
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
		
		-- Ð¨Ð»ÐµÐ¹Ñ„ Ð´Ð»Ñ Ð·Ð°Ñ‚Ð¸ÑÐºÐ°Ð½Ð½Ñ (Hold Trail)
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

-- ÐžÑ‚Ñ€Ð¸Ð¼Ð°Ð½Ð½Ñ Ð½Ð¾Ñ‚Ð¸ Ð· Ð¿ÑƒÐ»Ñƒ
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
	
	-- Ð’Ñ–Ð´Ð½Ð¾Ð²Ð»ÐµÐ½Ð½Ñ Ð¿Ñ€Ð¾Ð·Ð¾Ñ€Ð¾ÑÑ‚Ñ– Ð±ÑƒÐ»ÑŒÐ±Ð°ÑˆÐºÐ¸
	noteObj.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	noteObj.BackgroundTransparency = 0.25
	
	local stroke = noteObj:FindFirstChildWhichIsA("UIStroke")
	if stroke then
		stroke.Color = trackColor
		stroke.Transparency = 0
	end
	
	local core = noteObj:FindFirstChild("Core")
	if core then
		core.BackgroundColor3 = Color3.fromRGB(150, 150, 150) -- Ð¡Ñ–Ñ€Ðµ ÑÐ´Ñ€Ð¾
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

-- ÐŸÐ¾Ð²ÐµÑ€Ð½ÐµÐ½Ð½Ñ Ð½Ð¾Ñ‚Ð¸ Ð² Ð¿ÑƒÐ»
local function returnNoteToPool(note)
	note.Gui.Visible = false
	local trail = note.Gui:FindFirstChild("Trail")
	if trail then trail.Visible = false end
	note.Gui.Parent = screenGui
end

-- Ð¡Ñ‚Ð²Ð¾Ñ€ÐµÐ½Ð½Ñ Ñ–Ð½Ñ‚ÐµÑ€Ñ„ÐµÐ¹ÑÑƒ Ñ€Ð¸Ñ‚Ð¼-Ð³Ñ€Ð¸
local function createRhythmGui()
	local customGui = PlayerGui:FindFirstChild("MainGui--inGame", true)
	
	if customGui then
		print("ðŸŽ¨ Ð’Ð¸ÑÐ²Ð»ÐµÐ½Ð¾ ÐºÐ°ÑÑ‚Ð¾Ð¼Ð½Ð¸Ð¹ Ñ–Ð½Ñ‚ÐµÑ€Ñ„ÐµÐ¹Ñ MainGui--inGame. Ð†Ð½Ñ‚ÐµÐ³Ñ€ÑƒÑ”Ð¼Ð¾ ÐºÐ½Ð¾Ð¿ÐºÐ¸...")
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
				lane.BackgroundTransparency = 0.45 -- Ð Ð¾Ð±Ð¸Ð¼Ð¾ Ð¼ÐµÐ½Ñˆ Ð¿Ñ€Ð¾Ð·Ð¾Ñ€Ð¸Ð¼ Ð´Ð»Ñ ÐºÑ€Ð°Ñ‰Ð¾Ñ— Ð²Ð¸Ð´Ð¸Ð¼Ð¾ÑÑ‚Ñ–
				
				local activeFrame = lane:FindFirstChild(activeNames[i], true)
				if activeFrame then
					customActiveFrames[i] = activeFrame
					activeFrame.Visible = false
				end
			else
				warn("âš ï¸ ÐÐµ Ð·Ð½Ð°Ð¹Ð´ÐµÐ½Ð¾ Ð´Ð¾Ñ€Ñ–Ð¶ÐºÑƒ " .. laneNames[i] .. " Ñƒ MainGui--inGame!")
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
			feedbackLabel.TextSize = 80
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
			accuracyLabel.TextSize = 64
			accuracyLabel.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
			accuracyLabel.Text = "Accuracy: 100% | HP: 100"
			accuracyLabel.Parent = customGui
		end
		
		countdownLabel = customGui:FindFirstChild("CountdownLabel", true)
		if not countdownLabel then
			countdownLabel = Instance.new("TextLabel")
			countdownLabel.Name = "CountdownLabel"
			countdownLabel.Size = UDim2.new(0, 400, 0, 40)
			countdownLabel.Position = UDim2.new(0.5, -200, 0.78, 0) -- Ð Ð¾Ð·Ð¼Ñ–ÑÑ‚Ð¸Ð¼Ð¾ Ð² Ð½Ð¸Ð¶Ð½Ñ–Ð¹ Ñ‡Ð°ÑÑ‚Ð¸Ð½Ñ– ÐµÐºÑ€Ð°Ð½Ð°
			countdownLabel.BackgroundTransparency = 1
			countdownLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
			countdownLabel.TextSize = 68
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
			hpBackground.Visible = false -- ÐŸÑ€Ð¸Ñ…Ð¾Ð²ÑƒÑ”Ð¼Ð¾
			hpBackground.Parent = customGui
			
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0.5, 0)
			corner.Parent = hpBackground
			
			hpBar = Instance.new("Frame")
			hpBar.Name = "HPBar"
			hpBar.Size = UDim2.new(1, 0, 1, 0)
			hpBar.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
			hpBar.BorderSizePixel = 0
			hpBar.Visible = false -- ÐŸÑ€Ð¸Ñ…Ð¾Ð²ÑƒÑ”Ð¼Ð¾
			hpBar.Parent = hpBackground
		end
	else
		customGuiMode = false
		print("â„¹ï¸ ÐšÐ°ÑÑ‚Ð¾Ð¼Ð½Ð¸Ð¹ Ñ–Ð½Ñ‚ÐµÑ€Ñ„ÐµÐ¹Ñ Ð½Ðµ Ð·Ð½Ð°Ð¹Ð´ÐµÐ½Ð¾. Ð¡Ñ‚Ð²Ð¾Ñ€ÑŽÑ”Ð¼Ð¾ ÑÑ‚Ð°Ð½Ð´Ð°Ñ€Ñ‚Ð½Ð¸Ð¹...")
		
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
			keyLabel.TextSize = 64
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
		hpBackground.Visible = false -- ÐŸÑ€Ð¸Ñ…Ð¾Ð²ÑƒÑ”Ð¼Ð¾
		hpBackground.Parent = rhythmFrame

		hpBar = Instance.new("Frame")
		hpBar.Size = UDim2.new(1, 0, 1, 0)
		hpBar.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
		hpBar.BorderSizePixel = 0
		hpBar.Visible = false -- ÐŸÑ€Ð¸Ñ…Ð¾Ð²ÑƒÑ”Ð¼Ð¾
		hpBar.Parent = hpBackground

		feedbackLabel = Instance.new("TextLabel")
		feedbackLabel.Size = UDim2.new(1, 0, 0, 50)
		feedbackLabel.Position = UDim2.new(0, 0, 0.4, 0)
		feedbackLabel.BackgroundTransparency = 1
		feedbackLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		feedbackLabel.TextSize = 76
		feedbackLabel.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
		feedbackLabel.Text = ""
		feedbackLabel.Parent = rhythmFrame

		accuracyLabel = Instance.new("TextLabel")
		accuracyLabel.Size = UDim2.new(1, 0, 0, 30)
		accuracyLabel.Position = UDim2.new(0, 0, 0, -60)
		accuracyLabel.BackgroundTransparency = 1
		accuracyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		accuracyLabel.TextSize = 66
		accuracyLabel.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
		accuracyLabel.Text = "Accuracy: 100% | HP: 100"
		accuracyLabel.Parent = rhythmFrame
		
		countdownLabel = Instance.new("TextLabel")
		countdownLabel.Name = "CountdownLabel"
		countdownLabel.Size = UDim2.new(1, 0, 0, 40)
		countdownLabel.Position = UDim2.new(0, 0, 1, 15) -- Ð¢Ñ€Ð¾Ñ…Ð¸ Ð½Ð¸Ð¶Ñ‡Ðµ Ð·Ð° Ñ€Ð°Ð¼ÐºÑƒ Ð³Ñ€Ð¸
		countdownLabel.BackgroundTransparency = 1
		countdownLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
		countdownLabel.TextSize = 64
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

-- Ð¡Ñ‚Ð²Ð¾Ñ€ÐµÐ½Ð½Ñ Ð²Ñ–Ð·ÑƒÐ°Ð»ÑŒÐ½Ð¾Ñ— Ð½Ð¾Ñ‚Ð¸ Ñ‡ÐµÑ€ÐµÐ· Ð¿ÑƒÐ»
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

-- Ð’Ñ–Ð´Ð¾Ð±Ñ€Ð°Ð¶ÐµÐ½Ð½Ñ Ñ€ÐµÐ·ÑƒÐ»ÑŒÑ‚Ð°Ñ‚Ñ–Ð² Ð²Ð¸ÑÑ‚ÑƒÐ¿Ñƒ
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
	title.TextSize = 72
	title.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
	title.Text = "PERFORMANCE STATS"
	title.Parent = contentFrame

	local songTitle = Instance.new("TextLabel")
	songTitle.Size = UDim2.new(1, 0, 0, 25)
	songTitle.Position = UDim2.new(0, 0, 0, 55)
	songTitle.BackgroundTransparency = 1
	songTitle.TextColor3 = Color3.fromRGB(160, 160, 160)
	songTitle.TextSize = 62
	songTitle.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
	songTitle.Text = string.format("%s (%s)", currentSong.Title, currentSong.Difficulty)
	songTitle.Parent = contentFrame

	local accuracyVal = Instance.new("TextLabel")
	accuracyVal.Size = UDim2.new(0.5, -20, 0, 70)
	accuracyVal.Position = UDim2.new(0, 20, 0, 95)
	accuracyVal.BackgroundTransparency = 1
	accuracyVal.TextColor3 = Color3.fromRGB(255, 255, 255)
	accuracyVal.TextSize = 100
	accuracyVal.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
	accuracyVal.Text = string.format("%d%%", finalAccuracy)
	accuracyVal.Parent = contentFrame

	local accuracyLabel = Instance.new("TextLabel")
	accuracyLabel.Size = UDim2.new(0.5, -20, 0, 20)
	accuracyLabel.Position = UDim2.new(0, 20, 0, 160)
	accuracyLabel.BackgroundTransparency = 1
	accuracyLabel.TextColor3 = Color3.fromRGB(130, 130, 130)
	accuracyLabel.TextSize = 59
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
		label.TextSize = 60
		label.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Text = r.name
		label.Parent = ratingsFrame

		local val = Instance.new("TextLabel")
		val.Size = UDim2.new(0.4, 0, 0, 20)
		val.Position = UDim2.new(0.6, 0, 0, yOffset)
		val.BackgroundTransparency = 1
		val.TextColor3 = Color3.fromRGB(220, 220, 220)
		val.TextSize = 60
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
		valLbl.TextSize = 64
		valLbl.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
		valLbl.Text = rew.val
		valLbl.Parent = container

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size = UDim2.new(1, 0, 0.4, 0)
		nameLbl.Position = UDim2.new(0, 0, 0.55, 0)
		nameLbl.BackgroundTransparency = 1
		nameLbl.TextColor3 = Color3.fromRGB(130, 130, 130)
		nameLbl.TextSize = 57
		nameLbl.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
		nameLbl.Text = rew.name:upper()
		nameLbl.Parent = container
	end

	local graphTitle = Instance.new("TextLabel")
	graphTitle.Size = UDim2.new(1, -40, 0, 20)
	graphTitle.Position = UDim2.new(0, 20, 0, 260)
	graphTitle.BackgroundTransparency = 1
	graphTitle.TextColor3 = Color3.fromRGB(160, 160, 160)
	graphTitle.TextSize = 58
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
	missTitle.TextSize = 58
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
		missListText = "Perfect! No mistakes! ðŸŽ‰"
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
	missTxtLabel.TextSize = 58
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
	continueBtn.TextSize = 62
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
		resultsFrame:Destroy() -- Ð’Ð˜Ð”ÐÐ›Ð¯Ð„ÐœÐž Ð’Ð†ÐšÐÐž Ð¡Ð¢ÐÐ¢Ð˜Ð¡Ð¢Ð˜ÐšÐ˜!
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

-- Ð—Ð°Ð²ÐµÑ€ÑˆÐµÐ½Ð½Ñ Ð³Ñ€Ð¸
local function endSong(failed)
	if not isPlaying then return end
	isPlaying = false

	-- Ð—Ð£ÐŸÐ˜ÐÐ¯Ð„ÐœÐž Ð† Ð’Ð˜Ð”ÐÐ›Ð¯Ð„ÐœÐž Ð—Ð’Ð£Ðš ÐŸÐ†Ð¡ÐÐ†
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

	-- ÐžÑ‡Ð¸Ñ‰Ð°Ñ”Ð¼Ð¾ Ð²ÑÑ– Ð½Ð¾Ñ‚Ð¸
	for _, note in ipairs(activeNotes) do
		returnNoteToPool(note)
	end
	activeNotes = {}
	heldTracks = {false, false, false, false}

	-- ÐÐ°Ð´ÑÐ¸Ð»Ð°Ñ”Ð¼Ð¾ Ñ€ÐµÐ·ÑƒÐ»ÑŒÑ‚Ð°Ñ‚Ð¸ Ð½Ð° ÑÐµÑ€Ð²ÐµÑ€ Ñ‚Ð° Ð¾Ñ‚Ñ€Ð¸Ð¼ÑƒÑ”Ð¼Ð¾ Ð½Ð°Ð³Ð¾Ñ€Ð¾Ð´Ð¸
	local success, rewards = FinishSongFunc:InvokeServer(finalAccuracy)

	if not failed then
		-- ÐŸÑ€Ð¸Ñ…Ð¾Ð²ÑƒÑ”Ð¼Ð¾ Ñ–Ð³Ñ€Ð¾Ð²Ð¸Ð¹ Ñ–Ð½Ñ‚ÐµÑ€Ñ„ÐµÐ¹Ñ
		for _, child in ipairs(screenGui:GetChildren()) do
			if child:IsA("GuiObject") and child.Name ~= "ResultsFrame" and child.Name ~= "FeedbackLabel" then
				child.Visible = false
			end
		end
		
		-- ÐŸÐ¾ÐºÐ°Ð·ÑƒÑ”Ð¼Ð¾ ÐµÐºÑ€Ð°Ð½ Ñ€ÐµÐ·ÑƒÐ»ÑŒÑ‚Ð°Ñ‚Ñ–Ð²
		showResultsScreen(finalAccuracy, rewards)
	else
		task.wait(2)
		-- Ð—Ð°ÐºÑ€Ð¸Ñ‚Ñ‚Ñ/Ð¾Ñ‡Ð¸Ñ‰ÐµÐ½Ð½Ñ Ñ–Ð½Ñ‚ÐµÑ€Ñ„ÐµÐ¹ÑÑƒ Ð¿Ñ€Ð¸ Ð¿Ñ€Ð¾Ð²Ð°Ð»Ñ–
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

-- ÐŸÐ¾Ñ‡Ð°Ñ‚Ð¾Ðº Ñ€Ð¸Ñ‚Ð¼-Ð³Ñ€Ð¸
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

	-- Ð¡Ð¢Ð’ÐžÐ Ð•ÐÐÐ¯ Ð¢Ð ÐŸÐ ÐžÐ“Ð ÐÐ’ÐÐÐÐ¯ ÐœÐ£Ð—Ð˜Ð§ÐÐžÐ‡ Ð”ÐžÐ Ð†Ð–ÐšÐ˜ ÐŸÐ†Ð¡ÐÐ†
	if song.AudioId and song.AudioId ~= "" and song.AudioId ~= "rbxassetid://0" then
		local success, err = pcall(function()
			print("ðŸŽµ Ð¡Ð¿Ñ€Ð¾Ð±Ð° Ð·Ð°Ð¿ÑƒÑÐºÑƒ Ð°ÑƒÐ´Ñ–Ð¾Ð´Ð¾Ñ€Ñ–Ð¶ÐºÐ¸:", song.AudioId)
			activeSongSound = Instance.new("Sound")
			activeSongSound.SoundId = song.AudioId
			activeSongSound.Volume = 0.7 -- Ð¥Ð¾Ñ€Ð¾ÑˆÐ¸Ð¹ Ñ€Ñ–Ð²ÐµÐ½ÑŒ Ð³ÑƒÑ‡Ð½Ð¾ÑÑ‚Ñ–
			activeSongSound.Parent = game.Workspace.CurrentCamera -- 2D Ð·Ð²ÑƒÐº Ð±ÐµÐ·Ð¿Ð¾ÑÐµÑ€ÐµÐ´Ð½ÑŒÐ¾ Ñƒ Ð²ÑƒÑ…Ð° Ð³Ñ€Ð°Ð²Ñ†Ñ
			activeSongSound:Play()
		end)
		if not success then
			warn("âš ï¸ ÐŸÐ¾Ð¼Ð¸Ð»ÐºÐ° ÑÑ‚Ð²Ð¾Ñ€ÐµÐ½Ð½Ñ Ð°Ð±Ð¾ Ð·Ð°Ð¿ÑƒÑÐºÑƒ Ð·Ð²ÑƒÐºÑƒ:", err)
		end
	else
		warn("âš ï¸ ÐÑƒÐ´Ñ–Ð¾Ð´Ð¾Ñ€Ñ–Ð¶ÐºÑƒ Ð½Ðµ Ð·Ð°Ð¿ÑƒÑ‰ÐµÐ½Ð¾: ID Ð¿Ð¾Ñ€Ð¾Ð¶Ð½Ñ–Ð¹ Ð°Ð±Ð¾ rbxassetid://0")
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

	-- Ð—Ð°Ð¿ÑƒÑÐºÐ°Ñ”Ð¼Ð¾ Ð¿Ñ–ÑÐ½ÑŽ Ð½ÐµÐ³Ð°Ð¹Ð½Ð¾
	songStartTime = os.clock()

	-- Ð†Ð³Ñ€Ð¾Ð²Ð¸Ð¹ Ñ†Ð¸ÐºÐ»
	local connection
	connection = RunService.RenderStepped:Connect(function()
		if not isPlaying then
			connection:Disconnect()
			return
		end

		local elapsed = os.clock() - songStartTime

		-- Ð”Ð¸Ð½Ð°Ð¼Ñ–Ñ‡Ð½Ðµ Ð·Ð°Ð²ÐµÑ€ÑˆÐµÐ½Ð½Ñ Ð¿Ñ–ÑÐ½Ñ– Ð¿Ñ–ÑÐ»Ñ Ð¾ÑÑ‚Ð°Ð½Ð½ÑŒÐ¾Ñ— Ð½Ð¾Ñ‚Ð¸ Ð· Ð·Ð°Ñ‚Ñ€Ð¸Ð¼ÐºÐ¾ÑŽ Ð² 3 ÑÐµÐºÑƒÐ½Ð´Ð¸
		if spawnedNoteIndex > #currentSong.Notes and #activeNotes == 0 then
			if not songEndTime then
				songEndTime = os.clock() + 3.0
			elseif os.clock() >= songEndTime then
				connection:Disconnect()
				endSong(false)
				return
			end
		end

		-- Ð—Ð°Ñ…Ð¸ÑÐ½Ð¸Ð¹ Ð»Ñ–Ð¼Ñ–Ñ‚ Ð½Ð° Ð²Ð¸Ð¿Ð°Ð´Ð¾Ðº Ð±Ð°Ð³Ñ–Ð² (ÑÐºÑ‰Ð¾ Ð½Ð¾Ñ‚Ð¸ Ð·Ð°ÑÑ‚Ñ€ÑÐ³Ð»Ð¸)
		if elapsed >= currentSong.Length + 15 then
			connection:Disconnect()
			endSong(false)
			return
		end

		-- Ð¡Ð¿Ð°Ð²Ð½ Ð½Ð¾Ñ‚ Ð²Ñ–Ð´Ð¿Ð¾Ð²Ñ–Ð´Ð½Ð¾ Ð´Ð¾ Ñ€Ð¾Ð·ÐºÐ»Ð°Ð´Ñƒ
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

		-- ÐžÐ½Ð¾Ð²Ð»ÐµÐ½Ð½Ñ Ð¿Ð¾Ð·Ð¸Ñ†Ñ–Ñ— Ð°ÐºÑ‚Ð¸Ð²Ð½Ð¸Ñ… Ð½Ð¾Ñ‚
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
				
				-- Ð Ð¾Ð·Ñ€Ð°Ñ…ÑƒÐ½Ð¾Ðº Ð·Ð°Ð»Ð¸ÑˆÐºÑƒ Ñ‡Ð°ÑÑƒ Ð·Ð°Ñ‚Ð¸ÑÐºÐ°Ð½Ð½Ñ
				local timeLeft = (note.TargetTime + note.Duration) - elapsed
				local trail = note.Gui:FindFirstChild("Trail")
				
				if timeLeft > 0 then
					if trail then
						local screenHeight = screenGui.AbsoluteSize.Y
						if screenHeight == 0 then screenHeight = 800 end
						
						local currentHeightPixels = math.max(0, (timeLeft / spawnPreDelay) * pathLengthScale * screenHeight)
						trail.Size = UDim2.new(0, 24, 0, currentHeightPixels)
					end
					
					-- ÐžÑ‡ÐºÐ¸ Ð·Ð° Ñ‚Ñ€Ð¸Ð¼Ð°Ð½Ð½Ñ (Hold tick)
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
					-- Ð—Ð°Ñ‚Ð¸ÑÐºÐ°Ð½Ð½Ñ ÑƒÑÐ¿Ñ–ÑˆÐ½Ð¾ Ð·Ð°Ð²ÐµÑ€ÑˆÐµÐ½Ð¾! Ð›Ñ–Ð½Ñ–Ñ Ð·Ð½Ð¸ÐºÐ°Ñ” Ð¿Ð¾Ð²Ð½Ñ–ÑÑ‚ÑŽ!
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
				-- Ð¯Ðº Ð·Ð²Ð¸Ñ‡Ð°Ð¹Ð½Ñ–, Ñ‚Ð°Ðº Ñ– Ð²Ð»ÑƒÑ‡ÐµÐ½Ñ– Ð½Ð¾Ñ‚Ð¸ Ð¿Ñ€Ð¾Ð´Ð¾Ð²Ð¶ÑƒÑŽÑ‚ÑŒ Ð»ÐµÑ‚Ñ–Ñ‚Ð¸ Ð²Ð½Ð¸Ð·!
				if timeDiff < -0.25 then
					-- ÐÐ¾Ñ‚Ð° Ð²Ð¸Ð¹ÑˆÐ»Ð° Ð·Ð° Ð¼ÐµÐ¶Ñ– Ð´Ð¾Ñ€Ñ–Ð¶ÐºÐ¸
					if not note.Hit then
						-- ÐŸÑ€Ð¾Ð¿ÑƒÑÐº Ð½Ð¾Ñ‚Ð¸ (Miss) - Ñ‚Ñ–Ð»ÑŒÐºÐ¸ ÑÐºÑ‰Ð¾ Ð¿Ð¾ Ð½Ñ–Ð¹ ÐÐ• Ð¿Ð¾Ð¿Ð°Ð»Ð¸!
						triggerMiss()
						popFeedback("MISS!", Color3.fromRGB(120, 120, 120))
						missCount = missCount + 1
						table.insert(noteHistory, { time = note.TargetTime, rating = "MISS" })
					end
					
					returnNoteToPool(note)
					table.remove(activeNotes, i)
				else
					-- Ð ÑƒÑ… Ð½Ð¾Ñ‚Ð¸ Ð²Ð½Ð¸Ð·
					if customGuiMode and targetButton then
						local targetXScale = targetButton.Position.X.Scale
						local targetXOffset = targetButton.Position.X.Offset + (targetButton.AbsoluteSize.X / 2)
						local currentYScale = startY + progress * pathLengthScale
						
						note.Gui.Position = UDim2.new(targetXScale, targetXOffset, currentYScale, 0)
					else
						local yPosScale = progress * 0.85
						note.Gui.Position = UDim2.new(0.5, 0, yPosScale, 0)
					end
					
					-- Ð’Ñ–Ð·ÑƒÐ°Ð»ÑŒÐ½Ð¸Ð¹ ÐµÑ„ÐµÐºÑ‚ Ð´Ð»Ñ Ð²Ð»ÑƒÑ‡ÐµÐ½Ð¾Ñ— Ð½Ð¾Ñ‚Ð¸ (ÑÑ‚Ð°Ñ” Ð½Ð°Ð¿Ñ–Ð²Ð¿Ñ€Ð¾Ð·Ð¾Ñ€Ð¾ÑŽ)
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

		-- ÐžÐ½Ð¾Ð²Ð»ÐµÐ½Ð½Ñ ÑÑ‚Ð°Ñ‚ÑƒÑ-Ð¿Ð°Ð½ÐµÐ»Ñ–
		local currentAcc = (notesTotal > 0) and math.round((notesHit / notesTotal) * 100) or 100
		accuracyLabel.Text = string.format("Accuracy: %d%%", currentAcc)

		-- Ð’Ñ–Ð´Ð¾Ð±Ñ€Ð°Ð¶ÐµÐ½Ð½Ñ Ñ‚Ð°Ð¹Ð¼ÐµÑ€Ð° Ð´Ð¾ Ð¿Ð¾ÑÐ²Ð¸ Ð½Ð°ÑÑ‚ÑƒÐ¿Ð½Ð¾Ñ— Ð½Ð¾Ñ‚Ð¸
		local nextNote = currentSong.Notes[spawnedNoteIndex]
		if nextNote and #activeNotes == 0 and countdownLabel then
			local timeUntilSpawn = (nextNote.time - spawnPreDelay) - elapsed
			if timeUntilSpawn > 0.1 then
				if timeUntilSpawn > 2.0 or countdownLabel.Visible then
					countdownLabel.Visible = true
					countdownLabel.Text = tostring(math.ceil(timeUntilSpawn))
					
					-- ÐŸÑƒÐ»ÑŒÑÑƒÑŽÑ‡Ð¸Ð¹ ÐµÑ„ÐµÐºÑ‚ Ð¿Ñ€Ð¾Ð·Ð¾Ñ€Ð¾ÑÑ‚Ñ–
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

-- ÐžÐ±Ñ€Ð¾Ð±ÐºÐ° Ð½Ð°Ñ‚Ð¸ÑÐºÐ°Ð½Ð½Ñ ÐºÐ»Ð°Ð²Ñ–Ñˆ
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

	-- Ð—Ð°Ñ…Ð¸ÑÑ‚ Ð²Ñ–Ð´ Windows KeyRepeat: ÑÐºÑ‰Ð¾ ÐºÐ»Ð°Ð²Ñ–ÑˆÐ° Ð²Ð¶Ðµ Ð·Ð°Ñ‚Ð¸ÑÐ½ÑƒÑ‚Ð°, Ñ–Ð³Ð½Ð¾Ñ€ÑƒÑ”Ð¼Ð¾ Ð¿Ð¾Ð²Ñ‚Ð¾Ñ€Ð½Ñ– Ð¿Ð¾Ð´Ñ–Ñ—
	if heldTracks[pressedTrack] then return end
	heldTracks[pressedTrack] = true

	local trackColor = TrackColors[pressedTrack] or Color3.fromRGB(240, 240, 240)

	local activeFrame = customGuiMode and customActiveFrames[pressedTrack]
	if activeFrame then
		activeFrame.Visible = true
		activeFrame.BackgroundColor3 = trackColor
		activeFrame.BackgroundTransparency = 0.3 -- ÐŸÑ€Ð¸Ð³Ð»ÑƒÑˆÐµÐ½Ðµ Ð±Ñ–Ð»Ðµ ÑÐ²Ñ–Ñ‚Ñ–Ð½Ð½Ñ
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

-- ÐžÐ±Ñ€Ð¾Ð±ÐºÐ° Ð²Ñ–Ð´Ð¿ÑƒÑÐºÐ°Ð½Ð½Ñ ÐºÐ»Ð°Ð²Ñ–Ñˆ
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

	-- Ð¡ÐºÐ¸Ð´Ð°Ñ”Ð¼Ð¾ ÑÑ‚Ð°Ñ‚ÑƒÑ ÑƒÑ‚Ñ€Ð¸Ð¼Ð°Ð½Ð½Ñ ÐºÐ»Ð°Ð²Ñ–ÑˆÑ–
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
				-- Ð Ð°Ð½Ð½Ñ–Ð¹ Ð²Ñ–Ð´Ð¿ÑƒÑÐº (Hold Break). Ð›Ñ–Ð½Ñ–Ñ Ð·Ð½Ð¸ÐºÐ°Ñ” Ð²Ñ–Ð´Ñ€Ð°Ð·Ñƒ!
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


