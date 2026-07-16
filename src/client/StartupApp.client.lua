local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local MainMenu = require(script.Parent.UI.MainMenu)
local CharacterCreator = require(script.Parent.UI.CharacterCreator)
local MusicPlayer = require(script.Parent.UI.MusicPlayer)

local camera = Workspace.CurrentCamera
local player = Players.LocalPlayer

-- Active camera tracking variables
local currentRigName = nil
local currentTrack = nil
local cameraConnection = nil
local isTransitioning = false

local function setupScene()
	camera.CameraType = Enum.CameraType.Scriptable
end

local function resetCamera()
	camera.CameraType = Enum.CameraType.Custom
end

local function stopCameraRig()
	if cameraConnection then
		cameraConnection:Disconnect()
		cameraConnection = nil
	end
	if currentTrack then
		currentTrack:Stop()
		currentTrack:Destroy()
		currentTrack = nil
	end
end

local function playCameraRig(rigName, animId, loop)
	stopCameraRig()

	local rig = Workspace:FindFirstChild(rigName)
	if not rig then
		warn("Rig not found: " .. tostring(rigName))
		return nil
	end

	local animController = rig:FindFirstChild("AnimationController") or rig:FindFirstChildOfClass("Humanoid")
	local cameraPart = rig:FindFirstChild("CameraPart")
	if not animController or not cameraPart then
		warn("Missing components in " .. tostring(rigName))
		return nil
	end

	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. tostring(animId)
	
	currentTrack = animController:LoadAnimation(anim)
	currentTrack.Looped = not not loop
	currentTrack:Play()

	camera.CameraType = Enum.CameraType.Scriptable
	
	local lastCFrame = cameraPart.CFrame
	cameraConnection = RunService.RenderStepped:Connect(function()
		if currentTrack and currentTrack.IsPlaying then
			lastCFrame = cameraPart.CFrame
		end
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = lastCFrame
	end)

	return currentTrack
end

local function transitionToRig(targetGender)
	if isTransitioning then return end
	isTransitioning = true

	local currentGender = (currentRigName == "CameraRig_Man") and "Male" or "Female"
	if currentRigName == nil or currentRigName == "CameraRig" then
		-- Initial transition (no loop for idle rigs, they hold on last frame)
		if targetGender == "Male" then
			playCameraRig("CameraRig_Man", "136112089522087", false)
			currentRigName = "CameraRig_Man"
		else
			playCameraRig("CameraRig_Girl", "94550503114605", false)
			currentRigName = "CameraRig_Girl"
		end
		isTransitioning = false
	elseif currentGender ~= targetGender then
		-- Transition animation
		if targetGender == "Female" then
			local track = playCameraRig("CameraRig_ManToGirl", "97063760113550", false)
			currentRigName = "CameraRig_ManToGirl"
			if track then
				track.Stopped:Connect(function()
					if currentRigName == "CameraRig_ManToGirl" then
						playCameraRig("CameraRig_Girl", "94550503114605", false)
						currentRigName = "CameraRig_Girl"
					end
				end)
			else
				playCameraRig("CameraRig_Girl", "94550503114605", false)
				currentRigName = "CameraRig_Girl"
			end
		else
			local track = playCameraRig("CameraRig_GirlToMan", "104264847013905", false)
			currentRigName = "CameraRig_GirlToMan"
			if track then
				track.Stopped:Connect(function()
					if currentRigName == "CameraRig_GirlToMan" then
						playCameraRig("CameraRig_Man", "136112089522087", false)
						currentRigName = "CameraRig_Man"
					end
				end)
			else
				playCameraRig("CameraRig_Man", "136112089522087", false)
				currentRigName = "CameraRig_Man"
			end
		end
		isTransitioning = false
	else
		isTransitioning = false
	end
end

local function hideUI(el)
	if not el then return end
	pcall(function()
		if el:IsA("ScreenGui") then el.Enabled = false
		elseif el:IsA("GuiObject") then el.Visible = false end
	end)
end

local function showUI(el)
	if not el then return end
	pcall(function()
		if el:IsA("ScreenGui") then el.Enabled = true
		elseif el:IsA("GuiObject") then el.Visible = true end
	end)
end

local function toggleGameUI(visible)
	local mainHUD = player.PlayerGui:FindFirstChild("MainHUD", true)
	local songSelector = player.PlayerGui:FindFirstChild("SongSelectorUI")
	if visible then
		showUI(mainHUD)
		showUI(songSelector)
	else
		hideUI(mainHUD)
		hideUI(songSelector)
	end
end

local function replaceSceneModel(gender, hairId, color)
	local sceneModel = Workspace:FindFirstChild("SCENE_MODEL")
	if not sceneModel then
		warn("SCENE_MODEL not found in Workspace")
		return
	end

	local npcName = "NPC" .. string.char(39) .. "S"
	local npcsFolder = Workspace:FindFirstChild(npcName)
	if not npcsFolder then return end
	local mainFolder = npcsFolder:FindFirstChild(npcName .. "--Main")
	if not mainFolder then return end
	local skinTarget = gender == "Female" and "Starter_Skin--Woman" or "Starter_Skin--Man"
	local previewModel = mainFolder:FindFirstChild(skinTarget)
	if not previewModel then return end

	local transform = sceneModel:GetPivot()

	local clone = previewModel:Clone()
	clone.Name = "SCENE_MODEL"

	-- Unanchor all parts except HumanoidRootPart to allow R15 animations to play on joints
	for _, part in pairs(clone:GetDescendants()) do
		if part:IsA("BasePart") then
			if part.Name == "HumanoidRootPart" then
				part.Anchored = true
			else
				part.Anchored = false
			end
		end
	end

	sceneModel:Destroy()
	clone:PivotTo(transform)
	clone.Parent = Workspace

	local humanoid = clone:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local desc = humanoid:GetAppliedDescription()
		desc.HairAccessory = tostring(hairId)
		
		task.spawn(function()
			local success = pcall(function()
				humanoid:ApplyDescription(desc)
			end)
			if success then
				task.wait(0.1) -- Wait a moment for instances to initialize
				for _, acc in pairs(clone:GetChildren()) do
					if acc:IsA("Accessory") and acc.AccessoryType == Enum.AccessoryType.Hair then
						local handle = acc:FindFirstChild("Handle")
						if handle then
							handle.Color = color
							local mesh = handle:FindFirstChildOfClass("SpecialMesh")
							if mesh then
								mesh.VertexColor = Vector3.new(color.R, color.G, color.B)
							end
						end
					end
				end
			end

			-- Start animation AFTER ApplyDescription has completed to avoid it stopping the body joints track
			local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
			if animator then
				local anim = Instance.new("Animation")
				anim.AnimationId = "rbxassetid://103786020375484"
				local track = animator:LoadAnimation(anim)
				track.Looped = true
				track:Play()
			end
		end)
	end
end

local function App()
	local appState, setAppState = React.useState("Intro")
	local selectedGender, setSelectedGender = React.useState("Male")

	local function onSelectGender(gender)
		setSelectedGender(gender)
		setAppState("CharacterCreator")
		transitionToRig(gender)
	end

	local function onFinish(name, gender, hairId, color)
		local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
		local finishRemote = Remotes and Remotes:FindFirstChild("FinishCharacterCreation")
		if finishRemote then
			finishRemote:InvokeServer(gender, hairId, "Normal", name, {color.R, color.G, color.B})
		end

		replaceSceneModel(gender, hairId, color)
		playCameraRig("CameraRig_Scene", "139506285558789", false) -- Set loop to false as requested
		currentRigName = "CameraRig_Scene"

		setAppState("None")
		toggleGameUI(true)
	end

	local function onPreviewChange(gender, hairId, color)
		local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
		local previewRemote = Remotes and Remotes:FindFirstChild("PreviewHair")
		if previewRemote then
			previewRemote:FireServer(gender, hairId, color)
		end

		transitionToRig(gender)
	end

	React.useEffect(function()
		if appState ~= "None" then
			setupScene()
			local isMenu = true
			
			if appState == "Intro" then
				task.spawn(function()
					local loadingUI = player.PlayerGui:WaitForChild("StartupLoadingUI", 10)
					
					playCameraRig("CameraRig", "138969127699705", false)
					currentRigName = "CameraRig"
					if currentTrack then
						currentTrack:AdjustSpeed(0)
					end
					
					if loadingUI then
						while loadingUI.Parent do task.wait(0.1) end
					end
					
					if isMenu and currentTrack and currentRigName == "CameraRig" then
						currentTrack:AdjustSpeed(1)
						currentTrack.Stopped:Wait()
						if isMenu then
							setAppState("GenderSelect")
						end
					else
						setAppState("GenderSelect")
					end
				end)
			end
			
			task.spawn(function()
				while isMenu do
					hideUI(player.PlayerGui:FindFirstChild("MainHUD", true))
					hideUI(player.PlayerGui:FindFirstChild("SongSelectorUI"))
					hideUI(player.PlayerGui:FindFirstChild("MainGui--inGame", true))
					task.wait(0.1)
				end
			end)
			return function()
				isMenu = false
			end
		else
			local mainHUD = player.PlayerGui:FindFirstChild("MainHUD", true)
			showUI(mainHUD)
			local songSelector = player.PlayerGui:FindFirstChild("SongSelectorUI")
			showUI(songSelector) -- Keep song selector UI visible on appState None
		end
	end, {appState})

	if appState == "Intro" then
		return React.createElement("ScreenGui", { ResetOnSpawn = false, IgnoreGuiInset = true }, 
			React.createElement(MusicPlayer)
		)
	elseif appState == "GenderSelect" then
		return React.createElement("ScreenGui", { ResetOnSpawn = false, IgnoreGuiInset = true }, 
			React.createElement(MainMenu, { onSelectGender = onSelectGender }),
			React.createElement(MusicPlayer)
		)
	elseif appState == "CharacterCreator" then
		return React.createElement("ScreenGui", { ResetOnSpawn = false, IgnoreGuiInset = true }, 
			React.createElement(CharacterCreator, { 
				initialGender = selectedGender,
				onFinish = onFinish,
				onPreviewChange = onPreviewChange
			}),
			React.createElement(MusicPlayer)
		)
	else
		-- Keep MusicPlayer active during gameplay (appState None)
		return React.createElement("ScreenGui", { ResetOnSpawn = false, IgnoreGuiInset = true }, 
			React.createElement(MusicPlayer)
		)
	end
end

local reactContainer = Instance.new("ScreenGui")
reactContainer.Name = "ReactContainer"
reactContainer.ResetOnSpawn = false
reactContainer.Parent = player.PlayerGui

local root = ReactRoblox.createRoot(reactContainer)
root:render(React.createElement(App))
