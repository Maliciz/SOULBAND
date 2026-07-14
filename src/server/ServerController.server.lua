-- ServerScriptService/ServerController.server.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Connect managers
local DataManager = require(ServerScriptService.ServerController.DataManager)
local ContractManager = require(ServerScriptService.ServerController.ContractManager)
local ShopManager = require(ServerScriptService.ServerController.ShopManager)
local BandManager = require(ServerScriptService.ServerController.BandManager)
local SongData = require(ReplicatedStorage.SongData)

-- Create Remote Events/Functions in ReplicatedStorage
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
	Remotes = Instance.new("Folder")
	Remotes.Name = "Remotes"
	Remotes.Parent = ReplicatedStorage
end

local function getOrCreateRemote(className, name)
	local remote = Remotes:FindFirstChild(name)
	if not remote then
		remote = Instance.new(className)
		remote.Name = name
		remote.Parent = Remotes
	end
	return remote
end

local StartSongEvent = getOrCreateRemote("RemoteEvent", "StartSong")
local FinishSongFunc = getOrCreateRemote("RemoteFunction", "FinishSong")
local AcceptContractFunc = getOrCreateRemote("RemoteFunction", "AcceptContract")
local BuyItemFunc = getOrCreateRemote("RemoteFunction", "BuyItem")
local EquipItemFunc = getOrCreateRemote("RemoteFunction", "EquipItem")
local HireMusicianFunc = getOrCreateRemote("RemoteFunction", "HireMusician")
local UpgradeMusicianFunc = getOrCreateRemote("RemoteFunction", "UpgradeMusician")
local EquipMusicianClothingFunc = getOrCreateRemote("RemoteFunction", "EquipMusicianClothing")
local SetCustomKeybindsEvent = getOrCreateRemote("RemoteEvent", "SetCustomKeybinds")
local RequestStartSongEvent = getOrCreateRemote("RemoteEvent", "RequestStartSong")
local SetGenderFunc = getOrCreateRemote("RemoteFunction", "SetGender")
local RequestPlayerDataFunc = getOrCreateRemote("RemoteFunction", "RequestPlayerData")
local FinishCharacterCreationFunc = getOrCreateRemote("RemoteFunction", "FinishCharacterCreation")
local PreviewHairEvent = getOrCreateRemote("RemoteEvent", "PreviewHair")

local function applyHairToModel(model, hairId)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local desc = Instance.new("HumanoidDescription")
	desc.HairAccessory = tostring(hairId)

	local bc = model:FindFirstChildOfClass("BodyColors")
	if bc then
		desc.HeadColor = bc.HeadColor3
		desc.TorsoColor = bc.TorsoColor3
		desc.LeftArmColor = bc.LeftArmColor3
		desc.RightArmColor = bc.RightArmColor3
		desc.LeftLegColor = bc.LeftLegColor3
		desc.RightLegColor = bc.RightLegColor3
	end
	
	local shirt = model:FindFirstChildOfClass("Shirt")
	if shirt and shirt.ShirtTemplate then
		desc.Shirt = tonumber(shirt.ShirtTemplate:match("%d+")) or 0
	end
	local pants = model:FindFirstChildOfClass("Pants")
	if pants and pants.PantsTemplate then
		desc.Pants = tonumber(pants.PantsTemplate:match("%d+")) or 0
	end

	pcall(function()
		humanoid:ApplyDescription(desc)
	end)
end

local function applyCustomCharacter(player, character)
	local data = DataManager.Get(player)
	if not data or not data.CharacterCreated then return end

	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then return end

	local desc = Instance.new("HumanoidDescription")
	
	if data.Hair and data.Hair > 0 then
		desc.HairAccessory = tostring(data.Hair)
	end

	local SkinColors = {
		Light = Color3.fromRGB(255, 230, 220),
		Normal = Color3.fromRGB(253, 204, 168),
		Tan = Color3.fromRGB(224, 172, 105),
		Dark = Color3.fromRGB(141, 85, 36)
	}
	local color = SkinColors[data.SkinColor or "Normal"] or SkinColors.Normal
	desc.HeadColor = color
	desc.TorsoColor = color
	desc.LeftArmColor = color
	desc.RightArmColor = color
	desc.LeftLegColor = color
	desc.RightLegColor = color

	local starterSkin = nil
	local npcName = "NPC" .. string.char(39) .. "S"
	local npcsFolder = workspace:FindFirstChild(npcName)
	if npcsFolder then
		local mainFolder = npcsFolder:FindFirstChild(npcName .. "--Main")
		if mainFolder then
			starterSkin = mainFolder:FindFirstChild("Starter_Skin")
		end
	end

	if starterSkin then
		local shirt = starterSkin:FindFirstChildOfClass("Shirt")
		if shirt and shirt.ShirtTemplate then
			desc.Shirt = tonumber(shirt.ShirtTemplate:match("%d+")) or 0
		end
		local pants = starterSkin:FindFirstChildOfClass("Pants")
		if pants and pants.PantsTemplate then
			desc.Pants = tonumber(pants.PantsTemplate:match("%d+")) or 0
		end
	end

	local success, err = pcall(function()
		humanoid:ApplyDescription(desc)
	end)
	
	if not success then
		warn("Failed to apply humanoid description for player " .. player.Name .. ": " .. tostring(err))
	end
end

-- Player Join and Leave events
Players.PlayerAdded:Connect(function(player)
	local data = DataManager.LoadData(player)
	print("Data for player " .. player.Name .. " loaded successfully. Balance: " .. data.Cash)
	
	-- Hook to reset for character creation testing
	DataManager.Set(player, "CharacterCreated", false)
	
	player.CharacterAdded:Connect(function(character)
		applyCustomCharacter(player, character)
	end)
	
	-- Leaderboard setup
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local levelVal = Instance.new("IntValue")
	levelVal.Name = "Level"
	levelVal.Value = data.Level
	levelVal.Parent = leaderstats

	local fansVal = Instance.new("IntValue")
	fansVal.Name = "Fans"
	fansVal.Value = data.Fans
	fansVal.Parent = leaderstats

	local cashVal = Instance.new("IntValue")
	cashVal.Name = "Cash"
	cashVal.Value = data.Cash
	cashVal.Parent = leaderstats

	-- Update stats
	spawn(function()
		while player.Parent do
			local currentData = DataManager.Get(player)
			if currentData then
				levelVal.Value = currentData.Level
				fansVal.Value = currentData.Fans
				cashVal.Value = currentData.Cash
			end
			task.wait(1)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	DataManager.SaveData(player)
	DataManager.RemovePlayer(player)
end)

-- Auto-Save Thread (Every 5 minutes)
task.spawn(function()
	while true do
		task.wait(300)
		for _, player in ipairs(Players:GetPlayers()) do
			local data = DataManager.Get(player)
			if data then
				pcall(function()
					DataManager.SaveData(player)
				end)
			end
		end
		print("💾 [Auto-Save] All player data auto-saved successfully!")
	end
end)

-- Remote Invokes and Connections
RequestPlayerDataFunc.OnServerInvoke = function(player)
	local data = DataManager.Get(player)
	local retries = 0
	while not data and retries < 15 do
		task.wait(0.2)
		data = DataManager.Get(player)
		retries = retries + 1
	end
	return data
end

SetGenderFunc.OnServerInvoke = function(player, gender)
	if gender == "Male" or gender == "Female" then
		DataManager.Set(player, "Gender", gender)
		return true, "Gender changed to " .. (gender == "Male" and "Male" or "Female")
	end
	return false, "Invalid gender selection."
end

FinishCharacterCreationFunc.OnServerInvoke = function(player, gender, hairId, skinColor)
	if gender == "Male" or gender == "Female" then
		DataManager.Set(player, "Gender", gender)
		DataManager.Set(player, "Hair", hairId)
		DataManager.Set(player, "SkinColor", skinColor or "Normal")
		DataManager.Set(player, "CharacterCreated", true)
		
		player:LoadCharacter()
		return true, "Character created successfully!"
	end
	return false, "Invalid gender selection."
end

PreviewHairEvent.OnServerEvent:Connect(function(player, hairId)
	local starterSkin = nil
	local npcName = "NPC" .. string.char(39) .. "S"
	local npcsFolder = workspace:FindFirstChild(npcName)
	if npcsFolder then
		local mainFolder = npcsFolder:FindFirstChild(npcName .. "--Main")
		if mainFolder then
			starterSkin = mainFolder:FindFirstChild("Starter_Skin")
		end
	end
	
	if starterSkin then
		applyHairToModel(starterSkin, hairId)
	end
end)

AcceptContractFunc.OnServerInvoke = function(player, contractId)
	local success, result = ContractManager.StartContract(player, contractId)
	if success then
		StartSongEvent:FireClient(player, result.Song, result.ContractName)
		return true, "Successfully started!"
	else
		return false, result
	end
end

FinishSongFunc.OnServerInvoke = function(player, accuracy)
	return ContractManager.CompleteContract(player, accuracy)
end

BuyItemFunc.OnServerInvoke = function(player, category, itemId)
	return ShopManager.BuyItem(player, category, itemId)
end

EquipItemFunc.OnServerInvoke = function(player, category, itemId)
	return ShopManager.EquipItem(player, category, itemId)
end

HireMusicianFunc.OnServerInvoke = function(player, musicianId)
	return BandManager.HireMusician(player, musicianId)
end

UpgradeMusicianFunc.OnServerInvoke = function(player, musicianId)
	return BandManager.UpgradeMusician(player, musicianId)
end

EquipMusicianClothingFunc.OnServerInvoke = function(player, musicianId, clothingId)
	return BandManager.EquipMusicianClothing(player, musicianId, clothingId)
end

SetCustomKeybindsEvent.OnServerEvent:Connect(function(player, keybinds)
	if type(keybinds) == "table" and #keybinds == 4 then
		DataManager.Set(player, "Keybinds", keybinds)
		print("Custom keybinds saved for " .. player.Name)
	end
end)

RequestStartSongEvent.OnServerEvent:Connect(function(player, songId)
	local song = SongData.GetSongById(songId)
	if song then
		StartSongEvent:FireClient(player, song, "Free Play: " .. song.Title)
	end
end)
