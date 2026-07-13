-- ServerScriptService/DataManager.lua
local DataStoreService = game:GetService("DataStoreService")
local GameDataStore = DataStoreService:GetDataStore("BandSimulator_SaveSystem_v1")

local DataManager = {}
local sessionData = {} -- Збереження даних гравців, які зараз онлайн

local DEFAULT_DATA = {
	Cash = 100,
	Fans = 0,
	Level = 0,
	XP = 0,
	Gender = "Male", -- "Male" або "Female"
	OwnedClothing = {"default_outfit"},
	OwnedGuitars = {"default_guitar"},
	HiredMusicians = {}, -- { {Id = "drummer_takeshi", Level = 1, Clothing = "default_outfit"} }
	EquippedClothing = "default_outfit",
	EquippedGuitar = "default_guitar",
	Keybinds = {"X", "C", "N", "M"},
	LastContractTimes = {}
}

-- Глибоке копіювання таблиці для уникнення посилань на один і той же об'єкт
local function deepCopy(tbl)
	local copy = {}
	for k, v in pairs(tbl) do
		if type(v) == "table" then
			copy[k] = deepCopy(v)
		else
			copy[k] = v
		end
	end
	return copy
end

-- Завантаження даних
function DataManager.LoadData(player)
	local userId = player.UserId
	local success, data = pcall(function()
		return GameDataStore:GetAsync("Player_" .. userId)
	end)

	if success and data then
		-- Перевіряємо наявність нових полів (у разі оновлення гри)
		for k, v in pairs(DEFAULT_DATA) do
			if data[k] == nil then
				data[k] = deepCopy(v)
			end
		end
		sessionData[player] = data
	else
		-- Якщо гравець новий або помилка зчитування
		sessionData[player] = deepCopy(DEFAULT_DATA)
	end
	
	return sessionData[player]
end

-- Збереження даних
function DataManager.SaveData(player)
	local data = sessionData[player]
	if not data then return end

	local userId = player.UserId
	local success, err = pcall(function()
		GameDataStore:SetAsync("Player_" .. userId, data)
	end)

	if not success then
		warn("Не вдалося зберегти дані гравця " .. player.Name .. ": " .. tostring(err))
	end
end

-- Отримання даних поточного гравця
function DataManager.Get(player)
	return sessionData[player]
end

-- Оновлення значень
function DataManager.Set(player, key, value)
	local data = sessionData[player]
	if data and data[key] ~= nil then
		data[key] = value
	end
end

-- Очищення при виході гравця
function DataManager.RemovePlayer(player)
	sessionData[player] = nil
end

return DataManager
