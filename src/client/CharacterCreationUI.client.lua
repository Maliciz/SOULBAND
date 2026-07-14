-- StarterPlayer/StarterPlayerScripts/CharacterCreationUI.client.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local PlayerGui = Player:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestPlayerDataFunc = Remotes:WaitForChild("RequestPlayerData")
local FinishCharacterCreationFunc = Remotes:WaitForChild("FinishCharacterCreation")
local PreviewHairEvent = Remotes:WaitForChild("PreviewHair")

local hairList = { 11103884344, 11103880280, 18428787351, 117475707430348 }

local SkinColors = {
	Light = Color3.fromRGB(255, 230, 220),
	Normal = Color3.fromRGB(253, 204, 168),
	Tan = Color3.fromRGB(224, 172, 105),
	Dark = Color3.fromRGB(141, 85, 36)
}

-- Cleanup old UI
local oldUI = PlayerGui:FindFirstChild("CharacterCreationUI")
if oldUI then oldUI:Destroy() end

-- Check if player needs character creation
local success, data = pcall(function()
	return RequestPlayerDataFunc:InvokeServer()
end)

if not success or not data then
	warn("Не вдалося завантажити дані гравця для редактора персонажа.")
	return
end

print("DEBUG: character creation data received. CharacterCreated =", data.CharacterCreated)
if data.CharacterCreated then
	-- Already created, do nothing!
	return
end

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CharacterCreationUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

-- Disable Roblox CoreGUI HUD features during creation (like chat and player list)
local StarterGui = game:GetService("StarterGui")
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end)

-- Main Layout
local background = Instance.new("Frame")
background.Size = UDim2.new(1, 0, 1, 0)
background.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
background.BackgroundTransparency = 0.5 -- Show the 3D world behind slightly
background.Parent = screenGui

-- Left Panel
local leftPanel = Instance.new("Frame")
leftPanel.Size = UDim2.new(0, 320, 0, 440)
leftPanel.Position = UDim2.new(0, 40, 0.5, -220)
leftPanel.BackgroundColor3 = Color3.fromRGB(16, 16, 18)
leftPanel.BackgroundTransparency = 0.1
leftPanel.Parent = background

local lpCorner = Instance.new("UICorner")
lpCorner.CornerRadius = UDim.new(0, 8)
lpCorner.Parent = leftPanel

local lpStroke = Instance.new("UIStroke")
lpStroke.Color = Color3.fromRGB(60, 60, 60)
lpStroke.Thickness = 2
lpStroke.Parent = leftPanel

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 60)
titleLabel.Position = UDim2.new(0, 0, 0, 15)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 22
titleLabel.Font = Enum.Font.FredokaOne
titleLabel.Text = "СТВОРЕННЯ ПЕРСОНАЖА"
titleLabel.Parent = leftPanel

-- Gender Section
local genderTitle = Instance.new("TextLabel")
genderTitle.Size = UDim2.new(1, 0, 0, 30)
genderTitle.Position = UDim2.new(0, 0, 0, 95)
genderTitle.BackgroundTransparency = 1
genderTitle.TextColor3 = Color3.fromRGB(160, 160, 160)
genderTitle.TextSize = 14
genderTitle.Font = Enum.Font.FredokaOne
genderTitle.Text = "ОБЕРІТЬ СТАТЬ"
genderTitle.Parent = leftPanel

local maleBtn = Instance.new("TextButton")
maleBtn.Size = UDim2.new(0.8, 0, 0, 50)
maleBtn.Position = UDim2.new(0.1, 0, 0, 135)
maleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
maleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
maleBtn.TextSize = 16
maleBtn.Font = Enum.Font.FredokaOne
maleBtn.Text = "ЧОЛОВІК"
maleBtn.Parent = leftPanel

local maleCorner = Instance.new("UICorner")
maleCorner.CornerRadius = UDim.new(0, 6)
maleCorner.Parent = maleBtn

local maleStroke = Instance.new("UIStroke")
maleStroke.Thickness = 1.5
maleStroke.Color = Color3.fromRGB(80, 80, 80)
maleStroke.Parent = maleBtn

local femaleBtn = Instance.new("TextButton")
femaleBtn.Size = UDim2.new(0.8, 0, 0, 50)
femaleBtn.Position = UDim2.new(0.1, 0, 0, 195)
femaleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
femaleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
femaleBtn.TextSize = 16
femaleBtn.Font = Enum.Font.FredokaOne
femaleBtn.Text = "ЖІНКА"
femaleBtn.Parent = leftPanel

local femaleCorner = Instance.new("UICorner")
femaleCorner.CornerRadius = UDim.new(0, 6)
femaleCorner.Parent = femaleBtn

local femaleStroke = Instance.new("UIStroke")
femaleStroke.Thickness = 1.5
femaleStroke.Color = Color3.fromRGB(80, 80, 80)
femaleStroke.Parent = femaleBtn

-- Right Panel
local rightPanel = Instance.new("Frame")
rightPanel.Size = UDim2.new(0, 320, 0, 440)
rightPanel.Position = UDim2.new(1, -360, 0.5, -220)
rightPanel.BackgroundColor3 = Color3.fromRGB(16, 16, 18)
rightPanel.BackgroundTransparency = 0.1
rightPanel.Parent = background

local rpCorner = Instance.new("UICorner")
rpCorner.CornerRadius = UDim.new(0, 8)
rpCorner.Parent = rightPanel

local rpStroke = Instance.new("UIStroke")
rpStroke.Color = Color3.fromRGB(60, 60, 60)
rpStroke.Thickness = 2
rpStroke.Parent = rightPanel

-- Hair Section
local hairTitle = Instance.new("TextLabel")
hairTitle.Size = UDim2.new(1, 0, 0, 30)
hairTitle.Position = UDim2.new(0, 0, 0, 25)
hairTitle.BackgroundTransparency = 1
hairTitle.TextColor3 = Color3.fromRGB(160, 160, 160)
hairTitle.TextSize = 14
hairTitle.Font = Enum.Font.FredokaOne
hairTitle.Text = "ЗАЧІСКА"
hairTitle.Parent = rightPanel

local randomHairBtn = Instance.new("TextButton")
randomHairBtn.Size = UDim2.new(0.8, 0, 0, 50)
randomHairBtn.Position = UDim2.new(0.1, 0, 0, 65)
randomHairBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 26)
randomHairBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
randomHairBtn.TextSize = 15
randomHairBtn.Font = Enum.Font.FredokaOne
randomHairBtn.Text = "РАНДОМНЕ ВОЛОССЯ 🎲"
randomHairBtn.Parent = rightPanel

local rhCorner = Instance.new("UICorner")
rhCorner.CornerRadius = UDim.new(0, 6)
rhCorner.Parent = randomHairBtn

local rhStroke = Instance.new("UIStroke")
rhStroke.Thickness = 1.5
rhStroke.Color = Color3.fromRGB(150, 150, 150)
rhStroke.Parent = randomHairBtn

-- Skin Tone Section
local skinTitle = Instance.new("TextLabel")
skinTitle.Size = UDim2.new(1, 0, 0, 30)
skinTitle.Position = UDim2.new(0, 0, 0, 145)
skinTitle.BackgroundTransparency = 1
skinTitle.TextColor3 = Color3.fromRGB(160, 160, 160)
skinTitle.TextSize = 14
skinTitle.Font = Enum.Font.FredokaOne
skinTitle.Text = "КОЛІР ШКІРИ"
skinTitle.Parent = rightPanel

local skinFrame = Instance.new("Frame")
skinFrame.Size = UDim2.new(0.8, 0, 0, 60)
skinFrame.Position = UDim2.new(0.1, 0, 0, 185)
skinFrame.BackgroundTransparency = 1
skinFrame.Parent = rightPanel

local skinList = Instance.new("UIListLayout")
skinList.FillDirection = Enum.FillDirection.Horizontal
skinList.HorizontalAlignment = Enum.HorizontalAlignment.Center
skinList.Padding = UDim.new(0, 12)
skinList.Parent = skinFrame

-- Finish Button (Bottom Centered)
local finishBtn = Instance.new("TextButton")
finishBtn.Size = UDim2.new(0, 240, 0, 50)
finishBtn.Position = UDim2.new(0.5, -120, 1, -85)
finishBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 26)
finishBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
finishBtn.TextSize = 18
finishBtn.Font = Enum.Font.FredokaOne
finishBtn.Text = "ПОЧАТИ ГРУ"
finishBtn.Parent = background

local fbCorner = Instance.new("UICorner")
fbCorner.CornerRadius = UDim.new(0, 8)
fbCorner.Parent = finishBtn

local fbStroke = Instance.new("UIStroke")
fbStroke.Thickness = 2
fbStroke.Color = Color3.fromRGB(200, 200, 200)
fbStroke.Parent = finishBtn

-- Selections
local selectedGender = "Male"
local selectedHair = hairList[1]
local selectedSkinColor = "Normal"

local function updateGenderVisuals()
	if selectedGender == "Male" then
		maleStroke.Color = Color3.fromRGB(255, 255, 255)
		maleStroke.Thickness = 2
		maleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
		
		femaleStroke.Color = Color3.fromRGB(80, 80, 80)
		femaleStroke.Thickness = 1.5
		femaleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
	else
		femaleStroke.Color = Color3.fromRGB(255, 255, 255)
		femaleStroke.Thickness = 2
		femaleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
		
		maleStroke.Color = Color3.fromRGB(80, 80, 80)
		maleStroke.Thickness = 1.5
		maleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
	end
end

maleBtn.MouseButton1Click:Connect(function()
	selectedGender = "Male"
	updateGenderVisuals()
end)

femaleBtn.MouseButton1Click:Connect(function()
	selectedGender = "Female"
	updateGenderVisuals()
end)

local starterSkin = nil
local npcsFolder = workspace:FindFirstChild("NPC'S")
if npcsFolder then
	local mainFolder = npcsFolder:FindFirstChild("NPC'S--Main")
	if mainFolder then
		starterSkin = mainFolder:FindFirstChild("Starter_Skin")
	end
end

-- Clean initial hair accessories locally on rig
if starterSkin then
	for _, child in ipairs(starterSkin:GetChildren()) do
		if child:IsA("Accessory") then
			child:Destroy()
		end
	end
end

-- Function to set skin color locally on the customization rig
local function setLocalRigSkinColor(colorName)
	if not starterSkin then return end
	local color3 = SkinColors[colorName]
	for _, part in ipairs(starterSkin:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.Color = color3
		end
	end
end

-- Create skin color buttons
local skinButtons = {}
local function selectSkinColor(name)
	selectedSkinColor = name
	setLocalRigSkinColor(name)
	
	-- Highlight chosen color button
	for n, entry in pairs(skinButtons) do
		if n == name then
			entry.stroke.Color = Color3.fromRGB(255, 255, 255)
			entry.stroke.Thickness = 2.5
		else
			entry.stroke.Color = Color3.fromRGB(80, 80, 80)
			entry.stroke.Thickness = 1.5
		end
	end
end

for name, color in pairs(SkinColors) do
	local sBtn = Instance.new("TextButton")
	sBtn.Name = name
	sBtn.Size = UDim2.new(0, 45, 0, 45)
	sBtn.BackgroundColor3 = color
	sBtn.Text = ""
	sBtn.Parent = skinFrame
	
	local sCorner = Instance.new("UICorner")
	sCorner.CornerRadius = UDim.new(0.5, 0)
	sCorner.Parent = sBtn
	
	local sStroke = Instance.new("UIStroke")
	sStroke.Thickness = 1.5
	sStroke.Color = Color3.fromRGB(80, 80, 80)
	sStroke.Parent = sBtn
	
	skinButtons[name] = { btn = sBtn, stroke = sStroke }
	
	sBtn.MouseButton1Click:Connect(function()
		selectSkinColor(name)
	end)
end

-- Trigger default selections
updateGenderVisuals()
selectSkinColor(selectedSkinColor)

-- Random Hair event hook
randomHairBtn.MouseButton1Click:Connect(function()
	local randIndex = math.random(1, #hairList)
	local nextHair = hairList[randIndex]
	-- Avoid picking same hair twice in a row if possible
	if nextHair == selectedHair and #hairList > 1 then
		randIndex = (randIndex % #hairList) + 1
		nextHair = hairList[randIndex]
	end
	selectedHair = nextHair
	PreviewHairEvent:FireServer(selectedHair)
end)

-- Fire initial random hair preview
task.spawn(function()
	task.wait(0.5)
	PreviewHairEvent:FireServer(selectedHair)
end)

-- Camera and movement freeze
local camera = workspace.CurrentCamera
camera.CameraType = Enum.CameraType.Scriptable

local camConnection
if starterSkin then
	camConnection = RunService.RenderStepped:Connect(function()
		local skinCF = starterSkin:GetPivot()
		-- Place camera 8.5 studs in front of customizer rig and 4.8 studs high
		local camPosition = (skinCF * CFrame.new(0, 4.8, -8.5)).Position
		local lookAt = (skinCF * CFrame.new(0, 4.2, 0)).Position
		camera.CFrame = CFrame.lookAt(camPosition, lookAt)
	end)
end

-- Freeze player character
local char = Player.Character or Player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart", 5)
if hrp then
	hrp.Anchored = true
end

-- Finish customizer and start play
finishBtn.MouseEnter:Connect(function()
	TweenService:Create(finishBtn, TweenInfo.new(0.15), {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		TextColor3 = Color3.fromRGB(12, 12, 14)
	}):Play()
end)
finishBtn.MouseLeave:Connect(function()
	TweenService:Create(finishBtn, TweenInfo.new(0.15), {
		BackgroundColor3 = Color3.fromRGB(24, 24, 26),
		TextColor3 = Color3.fromRGB(255, 255, 255)
	}):Play()
end)

finishBtn.MouseButton1Click:Connect(function()
	-- Disable buttons during saving
	finishBtn.Active = false
	finishBtn.Text = "ЗБЕРЕЖЕННЯ..."
	
	local ok, err = FinishCharacterCreationFunc:InvokeServer(selectedGender, selectedHair, selectedSkinColor)
	if ok then
		-- Clean up camera scriptable mode and connections
		if camConnection then camConnection:Disconnect() end
		camera.CameraType = Enum.CameraType.Custom
		
		-- Enable CoreGui elements back
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
		end)
		
		screenGui:Destroy()
	else
		finishBtn.Active = true
		finishBtn.Text = "ПОМИЛКА: " .. tostring(err)
		task.wait(2)
		finishBtn.Text = "ПОЧАТИ ГРУ"
	end
end)

print("🎉 CharacterCustomizer UI initialized successfully!")
