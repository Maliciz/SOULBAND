-- ReplicatedStorage/SongData.lua
local SongData = {}

SongData.DifficultyXP = {
	Easy = 5,
	Medium = 22,
	Hard = 50,
	Extreme = 68
}

-- Процедурний генератор нот на основі темпу (BPM) та тривалості пісні
local function generateProceduralNotes(length, bpm)
	local notes = {}
	local step = 60 / bpm -- Час між основними ударами
	local elapsed = 1.5   -- Початкова затримка перед першою нотою
	
	-- Ініціалізуємо генератор випадкових чисел для унікальності кожного чарту
	local pseudoRandom = math.randomseed(bpm + length)
	
	while elapsed < length - 3.0 do
		local track = math.random(1, 4)
		local duration = nil
		
		-- 15% шанс створити Hold-ноту (затискання)
		if math.random(1, 100) <= 15 then
			duration = step * (math.random(1, 2)) -- Утримання на 1-2 удари
		end
		
		table.insert(notes, {
			time = math.round(elapsed * 100) / 100,
			track = track,
			duration = duration
		})
		
		-- Випадковий вибір інтервалу до наступної ноти (ритмічний малюнок)
		local pattern = math.random(1, 6)
		if pattern == 1 or pattern == 2 then
			elapsed = elapsed + step -- На кожен удар
		elseif pattern == 3 then
			elapsed = elapsed + step * 2 -- Кожні два удари
		elseif pattern == 4 then
			elapsed = elapsed + step * 0.5 -- Швидкі ноти (пів-удару)
		elseif pattern == 5 then
			elapsed = elapsed + step * 1.5 -- Синкопований ритм
		else
			elapsed = elapsed + step * 4 -- Пауза на 4 удари
		end
	end
	return notes
end

SongData.Songs = {
	-- НОВІ ПІСНІ З ТЕКИ TokyoBandSimulator (Процедурно генеруються при завантаженні)
	{
		Id = "100_days",
		Title = "100 Days",
		Difficulty = "Medium",
		LevelRequired = 0,
		Gender = "Universal",
		Bpm = 120,
		Length = 175,
		AudioId = "rbxassetid://137826305796855"
	},
	{
		Id = "15_song",
		Title = "15",
		Difficulty = "Easy",
		LevelRequired = 0,
		Gender = "Universal",
		Bpm = 110,
		Length = 125,
		AudioId = "rbxassetid://99185739490618"
	},
	{
		Id = "deathmetal_panchiko",
		Title = "DEATHMETAL (Panchiko)",
		Difficulty = "Hard",
		LevelRequired = 0,
		Gender = "Universal",
		Bpm = 135,
		Length = 250,
		AudioId = "rbxassetid://104113977201104"
	},
	{
		Id = "everlong",
		Title = "Everlong (Foo Fighters)",
		Difficulty = "Hard",
		LevelRequired = 0,
		Gender = "Universal",
		Bpm = 158,
		Length = 250,
		AudioId = "rbxassetid://84031772165316"
	},
	{
		Id = "mac_demarco_love",
		Title = "The Way You'd Love Her",
		Difficulty = "Medium",
		LevelRequired = 0,
		Gender = "Universal",
		Bpm = 125,
		Length = 160,
		AudioId = "rbxassetid://122997674282351"
	},
	{
		Id = "laputa_panchiko",
		Title = "Laputa (Panchiko)",
		Difficulty = "Medium",
		LevelRequired = 0,
		Gender = "Universal",
		Bpm = 120,
		Length = 170,
		AudioId = "rbxassetid://122914704082509"
	},
	{
		Id = "kuuchuu_buranko",
		Title = "Kuuchuu Buranko",
		Difficulty = "Hard",
		LevelRequired = 0,
		Gender = "Universal",
		Bpm = 140,
		Length = 260,
		AudioId = "rbxassetid://73479694911085"
	},
	{
		Id = "starting_over",
		Title = "Starting Over (LSD & Search for God)",
		Difficulty = "Medium",
		LevelRequired = 0,
		Gender = "Universal",
		Bpm = 128,
		Length = 280,
		AudioId = "rbxassetid://103996773702588"
	}
}

-- Генеруємо ноти для пісень, які не мають готових чартів (економить ручну роботу!)
for _, song in ipairs(SongData.Songs) do
	if not song.Notes or #song.Notes == 0 then
		song.Notes = generateProceduralNotes(song.Length, song.Bpm)
	end
end

function SongData.GetSongById(songId)
	for _, song in ipairs(SongData.Songs) do
		if song.Id == songId then
			return song
		end
	end
	return nil
end

function SongData.GetSongsByGenderAndLevel(gender, level)
	local result = {}
	for _, song in ipairs(SongData.Songs) do
		if (song.Gender == gender or song.Gender == "Universal") and level >= song.LevelRequired then
			table.insert(result, song)
		end
	end
	return result
end

return SongData
