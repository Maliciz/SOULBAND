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

local InsertService = game:GetService("InsertService")

local function applyCustomCharacter(player, character)
	local data = DataManager.Get(player)
	if not data then return end

	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then return end

	-- Create HumanoidDescription to copy appearance from Starter_Skin natively
	local desc = Instance.new("HumanoidDescription")
	
	-- Apply Hair
	if data.Hair and data.Hair > 0 then
		desc.HairAccessory = tostring(data.Hair)
	end

	-- Extract colors and clothing from Starter_Skin
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
		local bc = starterSkin:FindFirstChildOfClass("BodyColors")
		if bc then
			desc.HeadColor = bc.HeadColor3
			desc.TorsoColor = bc.TorsoColor3
			desc.LeftArmColor = bc.LeftArmColor3
			desc.RightArmColor = bc.RightArmColor3
			desc.LeftLegColor = bc.LeftLegColor3
			desc.RightLegColor = bc.RightLegColor3
		end
		
		-- Match clothes (extract ID from ShirtTemplate and PantsTemplate)
		local shirt = starterSkin:FindFirstChildOfClass("Shirt")
		if shirt and shirt.ShirtTemplate then
			desc.Shirt = tonumber(shirt.ShirtTemplate:match("%d+")) or 0
		end
		local pants = starterSkin:FindFirstChildOfClass("Pants")
		if pants and pants.PantsTemplate then
			desc.Pants = tonumber(pants.PantsTemplate:match("%d+")) or 0
		end
	end

	-- Apply description natively (handles downloading assets, styling, and welding)
	local success, err = pcall(function()
		humanoid:ApplyDescription(desc)
	end)
	
	if not success then
		warn("Failed to apply humanoid description for player " .. player.Name .. ": " .. tostring(err))
	end
end

-- Події входу та виходу гравців
Players.PlayerAdded:Connect(function(player)
	local data = DataManager.LoadData(player)
	print("Дані для гравця " .. player.Name .. " успішно завантажено. Баланс: " .. data.Cash)
	
	-- Рандомизация волос на старте, если запуск первый
	if not data.Hair or data.Hair == 0 then
		local hairList = { 11103884344, 11103880280, 18428787351, 117475707430348 }
		local randomHair = hairList[math.random(1, #hairList)]
		DataManager.Set(player, "Hair", randomHair)
		print("🎲 Рандомна зачіска обрана для гравця " .. player.Name .. ": " .. tostring(randomHair))
	end
	
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
