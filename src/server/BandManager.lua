-- ServerScriptService/BandManager.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameSettings = require(ReplicatedStorage:WaitForChild("GameSettings"))
local DataManager = require(script.Parent:WaitForChild("DataManager"))

local BandManager = {}

-- Найм музиканта
function BandManager.HireMusician(player, musicianId)
	local data = DataManager.Get(player)
	if not data then return false, "Дані гравця не знайдено." end

	-- Перевіряємо, чи вже найнятий
	for _, m in ipairs(data.HiredMusicians) do
		if m.Id == musicianId then
			return false, "Цей музикант вже грає у вашій групі."
		end
	end

	-- Шукаємо музиканта у списку доступних
	local config = nil
	for _, m in ipairs(GameSettings.MusiciansList) do
		if m.Id == musicianId then
			config = m
			break
		end
	end

	if not config then
		return false, "Музиканта не знайдено в базі даних."
	end

	-- Перевірка вимоги по фанах
	if data.Fans < config.MinFans then
		return false, "Недостатньо фанів для найму. Потрібно: " .. config.MinFans .. ", у вас: " .. data.Fans
	end

	-- Перевірка грошей
	if data.Cash < config.Price then
		return false, "Недостатньо коштів. Потрібно: " .. config.Price .. "$, у вас: " .. data.Cash .. "$"
	end

	-- Здійснюємо найм
	data.Cash = data.Cash - config.Price
	
	local newMusician = {
		Id = musicianId,
		Level = 1,
		EquippedClothing = "default_outfit"
	}
	table.insert(data.HiredMusicians, newMusician)

	DataManager.Set(player, "Cash", data.Cash)
	DataManager.Set(player, "HiredMusicians", data.HiredMusicians)

	return true, "Ви успішно найняли " .. config.Name .. " у свій гурт!"
end

-- Прокачування музиканта (Level Up)
function BandManager.UpgradeMusician(player, musicianId)
	local data = DataManager.Get(player)
	if not data then return false, "Дані не завантажено." end

	local musician = nil
	for _, m in ipairs(data.HiredMusicians) do
		if m.Id == musicianId then
			musician = m
			break
		end
	end

	if not musician then
		return false, "Музикант не найнятий."
	end

	-- Вартість оновлення залежить від рівня
	local upgradeCost = musician.Level * 300

	if data.Cash < upgradeCost then
		return false, "Недостатньо коштів для тренування. Потрібно: " .. upgradeCost .. "$, у вас: " .. data.Cash .. "$"
	end

	-- Здійснюємо прокачування
	data.Cash = data.Cash - upgradeCost
	musician.Level = musician.Level + 1

	DataManager.Set(player, "Cash", data.Cash)
	DataManager.Set(player, "HiredMusicians", data.HiredMusicians)

	return true, "Музикант підвищив рівень до " .. musician.Level .. "!"
end

-- Одягнути музиканта в одяг, яким володіє гравець
function BandManager.EquipMusicianClothing(player, musicianId, clothingId)
	local data = DataManager.Get(player)
	if not data then return false, "Дані не завантажено." end

	-- Перевіряємо, чи є такий одяг у гравця
	local hasClothing = false
	for _, id in ipairs(data.OwnedClothing) do
		if id == clothingId then
			hasClothing = true
			break
		end
	end

	if not hasClothing and clothingId ~= "default_outfit" then
		return false, "У вас немає цього одягу у гардеробі. Спочатку купіть його в магазині Токіо."
	end

	-- Знаходимо музиканта
	local musician = nil
	for _, m in ipairs(data.HiredMusicians) do
		if m.Id == musicianId then
			musician = m
			break
		end
	end

	if not musician then
		return false, "Цього музиканта немає у вашій групі."
	end

	-- Екіпіруємо одяг на музиканта
	musician.EquippedClothing = clothingId
	DataManager.Set(player, "HiredMusicians", data.HiredMusicians)

	return true, "Ви успішно одягли музиканта!"
end

return BandManager
