-- ServerScriptService/ShopManager.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameSettings = require(ReplicatedStorage:WaitForChild("GameSettings"))
local DataManager = require(script.Parent:WaitForChild("DataManager"))

local ShopManager = {}

-- Розрахунок загального бусту до фанів (Fan Multiplier)
function ShopManager.CalculateTotalFanBoost(player)
	local data = DataManager.Get(player)
	if not data then return 1.0 end

	local multiplier = 1.0

	-- 1. Буст від одягу гравця
	local equippedClothingId = data.EquippedClothing
	for _, item in ipairs(GameSettings.ClothingShop) do
		if item.Id == equippedClothingId then
			multiplier = multiplier * item.FanBoost
			break
		end
	end

	-- 2. Буст від гітари
	local equippedGuitarId = data.EquippedGuitar
	for _, item in ipairs(GameSettings.GuitarShop) do
		if item.Id == equippedGuitarId then
			multiplier = multiplier * item.FanBoost
			break
		end
	end

	-- 3. Буст від найнятих музикантів
	for _, musician in ipairs(data.HiredMusicians) do
		local musicianConfig = nil
		for _, m in ipairs(GameSettings.MusiciansList) do
			if m.Id == musician.Id then
				musicianConfig = m
				break
			end
		end

		if musicianConfig then
			-- Кожен рівень музиканта дає додатковий бонус (наприклад, +5% за рівень)
			local levelMultiplier = 1 + (musician.Level - 1) * 0.05
			multiplier = multiplier * (musicianConfig.BaseFanBoost * levelMultiplier)
		end
	end

	return multiplier
end

-- Купівля предмета (Одяг або Гітара)
function ShopManager.BuyItem(player, category, itemId)
	local data = DataManager.Get(player)
	if not data then return false, "Помилка завантаження даних гравця." end

	local catalog = nil
	local inventoryKey = nil

	if category == "Clothing" then
		catalog = GameSettings.ClothingShop
		inventoryKey = "OwnedClothing"
	elseif category == "Guitar" then
		catalog = GameSettings.GuitarShop
		inventoryKey = "OwnedGuitars"
	else
		return false, "Невідома категорія магазину."
	end

	-- Знаходимо предмет у каталозі
	local item = nil
	for _, i in ipairs(catalog) do
		if i.Id == itemId then
			item = i
			break
		end
	end

	if not item then
		return false, "Предмет не знайдено в каталозі."
	end

	-- Перевіряємо, чи гравець вже володіє предметом
	for _, ownedId in ipairs(data[inventoryKey]) do
		if ownedId == itemId then
			return false, "Ви вже володієте цим предметом."
		end
	end

	-- Перевіряємо баланс грошей
	if data.Cash < item.Price then
		return false, "Недостатньо коштів. Потрібно: " .. item.Price .. "$, у вас: " .. data.Cash .. "$"
	end

	-- Здійснюємо покупку
	data.Cash = data.Cash - item.Price
	table.insert(data[inventoryKey], itemId)
	
	-- Автоматично одягаємо придбаний предмет
	if category == "Clothing" then
		data.EquippedClothing = itemId
	elseif category == "Guitar" then
		data.EquippedGuitar = itemId
	end

	DataManager.Set(player, "Cash", data.Cash)
	DataManager.Set(player, inventoryKey, data[inventoryKey])

	return true, "Купівля успішна! Ви екіпірували: " .. item.Name
end

-- Екіпірування предметів, якими гравець вже володіє
function ShopManager.EquipItem(player, category, itemId)
	local data = DataManager.Get(player)
	if not data then return false, "Дані не завантажено." end

	local inventoryKey = (category == "Clothing") and "OwnedClothing" or "OwnedGuitars"
	local equipKey = (category == "Clothing") and "EquippedClothing" or "EquippedGuitar"

	local hasItem = false
	for _, id in ipairs(data[inventoryKey]) do
		if id == itemId then
			hasItem = true
			break
		end
	end

	if not hasItem then
		return false, "Ви не володієте цим предметом."
	end

	data[equipKey] = itemId
	return true, "Екіпіровано успішно!"
end

return ShopManager
