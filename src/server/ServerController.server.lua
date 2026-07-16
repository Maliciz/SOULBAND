-- ServerScriptService/ServerController.server.lua
local Players = game:GetService("Players")
Players.CharacterAutoLoads = false -- Забороняємо автоматичний спавн

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
local SpawnCharacterEvent = getOrCreateRemote("RemoteEvent", "SpawnCharacter")
local PreviewHairEvent = getOrCreateRemote("RemoteEvent", "PreviewHair")

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
			starterSkin = mainFolder:FindFirstChild("Starter_Skin_Man")
		end
	end

	if data.Shirt and data.Shirt > 0 then
		desc.Shirt = data.Shirt
	elseif starterSkin then
		local shirt = starterSkin:FindFirstChildOfClass("Shirt")
		if shirt and shirt.ShirtTemplate then
			desc.Shirt = tonumber(shirt.ShirtTemplate:match("%d+")) or 0
		end
	end

	if data.Pants and data.Pants > 0 then
		desc.Pants = data.Pants
	elseif starterSkin then
		local pants = starterSkin:FindFirstChildOfClass("Pants")
		if pants and pants.PantsTemplate then
			desc.Pants = tonumber(pants.PantsTemplate:match("%d+")) or 0
		end
	end

	local success, err = pcall(function()
		humanoid:ApplyDescription(desc)
	end)
	
	if success then
		if data.HairColor and type(data.HairColor) == "table" then
			task.wait(0.1)
			local c = Color3.new(data.HairColor[1], data.HairColor[2], data.HairColor[3])
			for _, acc in pairs(character:GetChildren()) do
				if acc:IsA("Accessory") and acc.AccessoryType == Enum.AccessoryType.Hair then
					local handle = acc:FindFirstChild("Handle")
					if handle then
						handle.Color = c
						local mesh = handle:FindFirstChildOfClass("SpecialMesh")
						if mesh then
							mesh.VertexColor = Vector3.new(c.R, c.G, c.B)
						end
					end
				end
			end
		end
	else
		warn("Failed to apply humanoid description for player " .. player.Name .. ": " .. tostring(err))
	end
end

-- Player Join and Leave events
Players.PlayerAdded:Connect(function(player)
	local data = DataManager.LoadData(player)
	print("Data for player " .. player.Name .. " loaded successfully. Balance: " .. data.Cash)
	
	-- Hook to reset for character creation testing removed
	
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

FinishCharacterCreationFunc.OnServerInvoke = function(player, gender, hairId, skinColor, artistName, hairColor, shirtId, pantsId)
	if gender == "Male" or gender == "Female" then
		local filteredName = player.Name
		if artistName and type(artistName) == "string" and artistName ~= "" then
			local success, filterResult = pcall(function()
				local TextService = game:GetService("TextService")
				return TextService:FilterStringAsync(artistName, player.UserId):GetNonChatStringForBroadcastAsync()
			end)
			if success and filterResult ~= "" then
				filteredName = filterResult
			end
		end

		DataManager.Set(player, "Gender", gender)
		DataManager.Set(player, "Hair", hairId)
		DataManager.Set(player, "SkinColor", skinColor or "Normal")
		DataManager.Set(player, "ArtistName", filteredName)
		DataManager.Set(player, "CharacterCreated", true)
		if hairColor and type(hairColor) == "table" then
			DataManager.Set(player, "HairColor", hairColor)
		end
		if shirtId and type(shirtId) == "number" then
			DataManager.Set(player, "Shirt", shirtId)
		end
		if pantsId and type(pantsId) == "number" then
			DataManager.Set(player, "Pants", pantsId)
		end
		
		player:LoadCharacter()
		return true, "Character created successfully!"
	end
	return false, "Invalid gender selection."
end

PreviewHairEvent.OnServerEvent:Connect(function(player, gender, hairId, color, shirtId, pantsId)
	local npcName = "NPC" .. string.char(39) .. "S"
	local npcsFolder = workspace:FindFirstChild(npcName)
	if not npcsFolder then return end
	local mainFolder = npcsFolder:FindFirstChild(npcName .. "--Main")
	if not mainFolder then return end
	local skinTarget = gender == "Female" and "Starter_Skin--Woman" or "Starter_Skin--Man"
	local previewModel = mainFolder:FindFirstChild(skinTarget)
	if not previewModel then return end

	local humanoid = previewModel:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local desc = humanoid:GetAppliedDescription()
		desc.HairAccessory = tostring(hairId)
		if shirtId and type(shirtId) == "number" then
			desc.Shirt = shirtId
		end
		if pantsId and type(pantsId) == "number" then
			desc.Pants = pantsId
		end
		
		local success = pcall(function()
			humanoid:ApplyDescription(desc)
		end)
		if success then
			task.wait(0.1)
			for _, acc in pairs(previewModel:GetChildren()) do
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

SpawnCharacterEvent.OnServerEvent:Connect(function(player)
	if not player.Character then
		player:LoadCharacter()
	end
end)
