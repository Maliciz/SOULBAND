-- ServerScriptService/ServerController.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SongData = require(ReplicatedStorage:WaitForChild("SongData"))

-- Підключення менеджерів
local DataManager = require(script:WaitForChild("DataManager"))
local ShopManager = require(script:WaitForChild("ShopManager"))
local ContractManager = require(script:WaitForChild("ContractManager"))
local BandManager = require(script:WaitForChild("BandManager"))

-- Створення Remote Events/Functions у ReplicatedStorage (якщо вони не створені вручну в Studio)
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage
end

local function getOrCreateRemote(className, name)
	local remote = remotesFolder:FindFirstChild(name)
	if not remote then
		remote = Instance.new(className)
		remote.Name = name
		remote.Parent = remotesFolder
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

local InsertService = game:GetService("InsertService")

local function applyHairToModel(model, hairId)
	if not model or not model:FindFirstChild("Humanoid") then return end
	
	-- Clean existing accessories on the model
	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("Accessory") then
			child:Destroy()
		end
	end
	
	-- Try loading the accessory via InsertService
	local success, assetModel = pcall(function()
		return InsertService:LoadAsset(hairId)
	end)
	
	if success and assetModel then
		local accessory = assetModel:FindFirstChildWhichIsA("Accessory")
		if accessory then
			accessory.Parent = model
			model.Humanoid:AddAccessory(accessory)
		end
		assetModel:Destroy()
	else
		-- Fallback: create manual accessory mesh if asset fails to load
		local accessory = Instance.new("Accessory")
		accessory.Name = "CustomHair_" .. tostring(hairId)
		
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(1.2, 1.2, 1.2)
		handle.Color = Color3.fromRGB(20, 20, 20) -- Default dark hair color
		handle.Parent = accessory
		
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshId = "rbxassetid://" .. tostring(hairId)
		mesh.Parent = handle
		
		local attachment = Instance.new("Attachment")
		attachment.Name = "HairAttachment"
		attachment.Parent = handle
		
		accessory.Parent = model
		model.Humanoid:AddAccessory(accessory)
	end
end

local function applyCustomCharacter(player, character)
	local data = DataManager.Get(player)
	if not data or not data.CharacterCreated then return end

	-- Wait for humanoid
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then return end

	-- Clear default Roblox accessories
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Accessory") then
			child:Destroy()
		end
	end

	-- Apply clothes and body colors from Starter_Skin if available
	local starterSkin = nil
	local npcsFolder = workspace:FindFirstChild("NPC'S")
	if npcsFolder then
		local mainFolder = npcsFolder:FindFirstChild("NPC'S--Main")
		if mainFolder then
			starterSkin = mainFolder:FindFirstChild("Starter_Skin")
		end
	end

	if starterSkin then
		-- Copy and set Body Colors according to selection
		local SkinColors = {
			Light = Color3.fromRGB(255, 230, 220),
			Normal = Color3.fromRGB(253, 204, 168),
			Tan = Color3.fromRGB(224, 172, 105),
			Dark = Color3.fromRGB(141, 85, 36)
		}
		local color = SkinColors[data.SkinColor or "Normal"] or SkinColors.Normal
		local bodyColors = character:FindFirstChildOfClass("BodyColors")
		if not bodyColors then
			bodyColors = Instance.new("BodyColors")
			bodyColors.Parent = character
		end
		bodyColors.HeadColor3 = color
		bodyColors.TorsoColor3 = color
		bodyColors.LeftArmColor3 = color
		bodyColors.RightArmColor3 = color
		bodyColors.LeftLegColor3 = color
		bodyColors.RightLegColor3 = color
		-- Copy clothes
		for _, child in ipairs(starterSkin:GetChildren()) do
			if child:IsA("Shirt") or child:IsA("Pants") then
				-- Remove existing
				for _, oldChild in ipairs(character:GetChildren()) do
					if oldChild.ClassName == child.ClassName then
						oldChild:Destroy()
					end
				end
				child:Clone().Parent = character
			end
		end
	end

	-- Apply saved hair accessory
	if data.Hair and data.Hair > 0 then
		applyHairToModel(character, data.Hair)
	end
end

-- Події входу та виходу гравців
Players.PlayerAdded:Connect(function(player)
	local data = DataManager.LoadData(player)
	print("Дані для гравця " .. player.Name .. " успішно завантажено. Баланс: " .. data.Cash)
	DataManager.Set(player, "CharacterCreated", false) -- Скидаємо прапорець для тестування створення персонажа!
	
	player.CharacterAdded:Connect(function(character)
		applyCustomCharacter(player, character)
	end)
	
	-- Створюємо папки лідерборду (для відображення фанів та грошей у списку гравців)
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

	-- Оновлюємо лідерборд при зміні даних
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

-- Періодичне автозбереження даних для всіх онлайн-гравців (кожні 5 хвилин / 300 секунд)
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
		print("💾 [Auto-Save] Дані всіх гравців успішно збережено!")
	end
end)

-- Обробники запитів від клієнтів (Remote Functions)

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
		return true, "Стать змінена на " .. (gender == "Male" and "Чоловічу" or "Жіночу")
	end
	return false, "Невірна стать."
end

FinishCharacterCreationFunc.OnServerInvoke = function(player, gender, hairId, skinColor)
	if gender == "Male" or gender == "Female" then
		DataManager.Set(player, "Gender", gender)
		DataManager.Set(player, "Hair", hairId)
		DataManager.Set(player, "SkinColor", skinColor or "Normal")
		DataManager.Set(player, "CharacterCreated", true)
		
		-- Перевантажуємо персонажа, щоб застосувати вигляд
		player:LoadCharacter()
		return true, "Персонажа створено!"
	end
	return false, "Невірна стать."
end

PreviewHairEvent.OnServerEvent:Connect(function(player, hairId)
	local starterSkin = nil
	local npcsFolder = workspace:FindFirstChild("NPC'S")
	if npcsFolder then
		local mainFolder = npcsFolder:FindFirstChild("NPC'S--Main")
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
		-- Повідомляємо клієнтський скрипт про старт гри
		StartSongEvent:FireClient(player, result.Song, result.ContractName)
		return true, "Успішно розпочато!"
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
		print("Користувацькі клавіші збережено для " .. player.Name)
	end
end)

RequestStartSongEvent.OnServerEvent:Connect(function(player, songId)
	local song = SongData.GetSongById(songId)
	if song then
		StartSongEvent:FireClient(player, song, "Вільна гра: " .. song.Title)
	end
end)
