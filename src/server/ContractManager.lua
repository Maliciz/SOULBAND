-- ServerScriptService/ContractManager.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameSettings = require(ReplicatedStorage:WaitForChild("GameSettings"))
local SongData = require(ReplicatedStorage:WaitForChild("SongData"))
local DataManager = require(script.Parent:WaitForChild("DataManager"))
local ShopManager = require(script.Parent:WaitForChild("ShopManager"))

local ContractManager = {}
local activeSessions = {} -- Таблиця для відстеження активних ігор гравців {Player = {ContractId = string, StartTime = number}}

-- Початок виконання контракту
function ContractManager.StartContract(player, contractId)
	local data = DataManager.Get(player)
	if not data then return false, "Гравець не завантажений." end

	local contract = GameSettings.Contracts[contractId]
	if not contract then return false, "Контракт не знайдено." end

	-- Перевірка рівня та фанів
	if data.Level < contract.MinLevel then
		return false, "Необхідний рівень гурту: " .. contract.MinLevel .. ". Ваш рівень: " .. data.Level
	end
	if data.Fans < contract.MinFans then
		return false, "Необхідно фанів: " .. contract.MinFans .. ". У вас: " .. data.Fans
	end

	-- Перевірка кулдауну
	local currentTime = os.time()
	local lastTime = data.LastContractTimes[contractId] or 0
	local elapsed = currentTime - lastTime
	if elapsed < contract.Cooldown then
		local timeLeft = contract.Cooldown - elapsed
		return false, "Контракт перезаряджається. Зачекайте " .. timeLeft .. " сек."
	end

	-- Обираємо випадкову пісню відповідної складності, яка підходить для гендера гравця
	local suitableSongs = {}
	for _, song in ipairs(SongData.Songs) do
		if song.Difficulty == contract.Difficulty and (song.Gender == data.Gender or song.Gender == "Universal") then
			table.insert(suitableSongs, song)
		end
	end

	if #suitableSongs == 0 then
		return false, "Не знайдено пісень для вашої статі зі складністю " .. contract.Difficulty
	end

	local selectedSong = suitableSongs[math.random(1, #suitableSongs)]

	-- Реєструємо ігрову сесію
	activeSessions[player] = {
		ContractId = contractId,
		SongId = selectedSong.Id,
		StartTime = os.clock()
	}

	-- Оновлюємо час останнього запуску контракту
	data.LastContractTimes[contractId] = currentTime
	DataManager.Set(player, "LastContractTimes", data.LastContractTimes)

	return true, {
		Song = selectedSong,
		ContractName = contract.Name
	}
end

-- Завершення контракту та нарахування нагород
function ContractManager.CompleteContract(player, accuracy)
	local session = activeSessions[player]
	if not session then
		return false, "Гра не була розпочата або вже завершилася."
	end

	local contractId = session.ContractId
	local songId = session.SongId
	local startTime = session.StartTime
	activeSessions[player] = nil -- Видаляємо сесію

	local contract = GameSettings.Contracts[contractId]
	local song = SongData.GetSongById(songId)
	if not contract or not song then
		return false, "Невідома помилка конфігурації."
	end

	-- Перевірка на чітерство (занадто швидке завершення пісні)
	local timeElapsed = os.clock() - startTime
	if timeElapsed < (song.Length * 0.5) then -- Якщо пройшло менше половини довжини пісні
		return false, "Помилка валідації: пісня завершилась підозріло швидко."
	end

	local data = DataManager.Get(player)
	if not data then return false, "Дані не знайдено." end

	-- Розрахунок досвіду (XP) відповідно до плану:
	-- Якщо точність менша за 60%, досвід = 0
	-- Легкий: 90%+ -> 5 XP, інакше 1-2 XP (дамо 2)
	-- Середній: 90%+ -> 22 XP, інакше 10 XP
	-- Важкий: 90%+ -> 50 XP, інакше 20 XP
	-- Екстрим: 90%+ -> 68 XP, інакше 35 XP
	local xpEarned = 0
	if accuracy >= 60 then
		if contract.Difficulty == "Easy" then
			xpEarned = (accuracy >= 90) and 5 or 2
		elseif contract.Difficulty == "Medium" then
			xpEarned = (accuracy >= 90) and 22 or 10
		elseif contract.Difficulty == "Hard" then
			xpEarned = (accuracy >= 90) and 50 or 20
		elseif contract.Difficulty == "Extreme" then
			xpEarned = (accuracy >= 90) and 68 or 35
		end
	end

	-- Розрахунок нагороди у грошах та фанах
	local cashReward = 0
	local fansEarned = 0

	if accuracy >= 60 then
		-- Гроші та фани масштабуються відповідно до точності
		local accuracyFactor = accuracy / 100
		
		-- Бусти від одягу, гітари та музикантів
		local fanMultiplier = ShopManager.CalculateTotalFanBoost(player)

		cashReward = math.round(contract.CashReward * accuracyFactor)
		fansEarned = math.round(contract.FanReward * accuracyFactor * fanMultiplier)

		-- Нараховуємо нагороду
		data.Cash = data.Cash + cashReward
		data.Fans = data.Fans + fansEarned
		data.XP = data.XP + xpEarned

		-- Логіка підвищення рівня (Level Up)
		-- Кожні 100 XP дають новий рівень (можна налаштувати іншу формулу)
		local nextLevelXp = (data.Level + 1) * 100
		local leveledUp = false
		while data.XP >= nextLevelXp do
			data.XP = data.XP - nextLevelXp
			data.Level = data.Level + 1
			nextLevelXp = (data.Level + 1) * 100
			leveledUp = true
		end

		-- Зберігаємо дані
		DataManager.Set(player, "Cash", data.Cash)
		DataManager.Set(player, "Fans", data.Fans)
		DataManager.Set(player, "XP", data.XP)
		if leveledUp then
			DataManager.Set(player, "Level", data.Level)
		end
		
		DataManager.SaveData(player)

		return true, {
			XPEarned = xpEarned,
			CashEarned = cashReward,
			FansEarned = fansEarned,
			NewLevel = data.Level,
			LeveledUp = leveledUp,
			Accuracy = accuracy
		}
	else
		return true, {
			XPEarned = 0,
			CashEarned = 0,
			FansEarned = 0,
			NewLevel = data.Level,
			LeveledUp = false,
			Accuracy = accuracy,
			Message = "Точність менше 60%! Нагороду не отримано."
		}
	end
end

return ContractManager
