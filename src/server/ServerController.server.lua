-- ServerScriptService/ServerController.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Підключення менеджерів
local DataManager = require(script.Parent:WaitForChild("DataManager"))
local ShopManager = require(script.Parent:WaitForChild("ShopManager"))
local ContractManager = require(script.Parent:WaitForChild("ContractManager"))
local BandManager = require(script.Parent:WaitForChild("BandManager"))

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
local SetGenderFunc = getOrCreateRemote("RemoteFunction", "SetGender")
local RequestPlayerDataFunc = getOrCreateRemote("RemoteFunction", "RequestPlayerData")

-- Події входу та виходу гравців
Players.PlayerAdded:Connect(function(player)
	local data = DataManager.LoadData(player)
	print("Дані для гравця " .. player.Name .. " успішно завантажено. Баланс: " .. data.Cash)
	
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

-- Обробники запитів від клієнтів (Remote Functions)

RequestPlayerDataFunc.OnServerInvoke = function(player)
	return DataManager.Get(player)
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
