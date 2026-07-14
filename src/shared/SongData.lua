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
		AudioId = "rbxassetid://137826305796855",
		Notes = {
			{ time = 4.50, track = 1 },
			{ time = 5.07, track = 3 },
			{ time = 5.53, track = 3 },
			{ time = 6.00, track = 4 },
			{ time = 6.48, track = 1 },
			{ time = 9.33, track = 1 },
			{ time = 9.78, track = 3 },
			{ time = 10.30, track = 3 },
			{ time = 10.78, track = 4 },
			{ time = 11.28, track = 1 },
			{ time = 11.80, track = 1 },
			{ time = 12.27, track = 1 },
			{ time = 13.17, track = 1 },
			{ time = 13.63, track = 3 },
			{ time = 14.08, track = 3 },
			{ time = 14.57, track = 4 },
			{ time = 15.03, track = 1 },
			{ time = 17.03, track = 3 },
			{ time = 17.48, track = 1 },
			{ time = 17.98, track = 4 },
			{ time = 18.42, track = 4 },
			{ time = 19.36, track = 1 },
			{ time = 21.37, track = 3 },
			{ time = 22.35, track = 4 },
			{ time = 23.38, track = 1 },
			{ time = 25.15, track = 1 },
			{ time = 26.18, track = 3 },
			{ time = 27.12, track = 4 },
			{ time = 29.03, track = 1 },
			{ time = 30.00, track = 3 },
			{ time = 30.50, track = 4 },
			{ time = 31.87, track = 1 },
			{ time = 32.25, track = 3 },
			{ time = 32.83, track = 4 },
			{ time = 33.87, track = 1 },
			{ time = 34.35, track = 4 },
			{ time = 34.78, track = 3 },
			{ time = 35.76, track = 4 },
			{ time = 36.25, track = 1 },
			{ time = 36.73, track = 3 },
			{ time = 37.18, track = 4 },
			{ time = 38.18, track = 1 },
			{ time = 38.63, track = 3 },
			{ time = 39.10, track = 4 },
			{ time = 39.63, track = 4 },
			{ time = 40.10, track = 4 },
			{ time = 40.57, track = 4 },
			{ time = 41.51, track = 3 },
			{ time = 41.73, track = 1 },
			{ time = 41.96, track = 4 },
			{ time = 42.88, track = 3 },
			{ time = 43.13, track = 1 },
			{ time = 43.31, track = 4 },
			{ time = 43.86, track = 4 },
			{ time = 44.31, track = 4 },
			{ time = 44.76, track = 3 },
			{ time = 45.37, track = 3 },
			{ time = 45.80, track = 1 },
			{ time = 46.00, track = 4 },
			{ time = 46.73, track = 4 },
			{ time = 46.93, track = 3 },
			{ time = 47.48, track = 3 },
			{ time = 47.85, track = 3 },
			{ time = 48.26, track = 3 },
			{ time = 48.77, track = 4 },
			{ time = 49.22, track = 4 },
			{ time = 49.71, track = 4 },
			{ time = 50.20, track = 3 },
			{ time = 50.66, track = 3 },
			{ time = 51.16, track = 3 },
			{ time = 51.62, track = 4 },
			{ time = 52.10, track = 1 },
			{ time = 52.58, track = 1 },
			{ time = 53.48, track = 3 },
			{ time = 53.70, track = 1 },
			{ time = 54.33, track = 3 },
			{ time = 54.83, track = 4 },
			{ time = 55.45, track = 1 },
			{ time = 55.93, track = 1 },
			{ time = 56.48, track = 1 },
			{ time = 56.96, track = 1 },
			{ time = 57.40, track = 3 },
			{ time = 58.23, track = 4 },
			{ time = 58.53, track = 1 },
			{ time = 59.05, track = 3 },
			{ time = 59.41, track = 3 },
			{ time = 59.86, track = 3 },
			{ time = 60.28, track = 4 },
			{ time = 60.78, track = 4 },
			{ time = 61.23, track = 4 },
			{ time = 61.63, track = 3 },
			{ time = 62.13, track = 3 },
			{ time = 62.58, track = 1 },
			{ time = 63.06, track = 4 },
			{ time = 64.55, track = 1 },
			{ time = 65.03, track = 4 },
			{ time = 66.00, track = 3 },
			{ time = 66.53, track = 1 },
			{ time = 66.93, track = 4 },
			{ time = 67.90, track = 3 },
			{ time = 68.40, track = 1 },
			{ time = 68.86, track = 4 },
			{ time = 70.81, track = 1 },
			{ time = 71.28, track = 3 },
			{ time = 71.76, track = 3 },
			{ time = 72.25, track = 1 },
			{ time = 73.16, track = 4 },
			{ time = 73.66, track = 4 },
			{ time = 74.18, track = 3 },
			{ time = 74.65, track = 1 },
			{ time = 75.11, track = 4 },
			{ time = 76.08, track = 3 },
			{ time = 76.55, track = 3 },
			{ time = 77.03, track = 4 },
			{ time = 78.00, track = 3 },
			{ time = 78.46, track = 3 },
			{ time = 78.98, track = 1 },
			{ time = 79.43, track = 3 },
			{ time = 79.90, track = 4 },
			{ time = 80.36, track = 4 },
			{ time = 80.88, track = 3 },
			{ time = 81.36, track = 1 },
			{ time = 82.81, track = 1 },
			{ time = 83.28, track = 3 },
			{ time = 83.78, track = 3 },
			{ time = 84.25, track = 4 },
			{ time = 84.75, track = 4 },
			{ time = 85.20, track = 4 },
			{ time = 85.66, track = 3 },
			{ time = 86.15, track = 1 },
			{ time = 87.61, track = 1 },
			{ time = 88.08, track = 3 },
			{ time = 88.56, track = 3 },
			{ time = 89.01, track = 4 },
			{ time = 89.45, track = 3 },
			{ time = 90.45, track = 1 },
			{ time = 90.93, track = 3 },
			{ time = 91.43, track = 3 },
			{ time = 91.95, track = 3 },
			{ time = 92.30, track = 4 },
			{ time = 92.76, track = 4 },
			{ time = 93.33, track = 4 },
			{ time = 93.81, track = 3 },
			{ time = 94.16, track = 1 },
			{ time = 94.36, track = 3 },
			{ time = 94.81, track = 3 },
			{ time = 95.25, track = 3 },
			{ time = 95.50, track = 1 },
			{ time = 95.71, track = 4 },
			{ time = 96.13, track = 3 },
			{ time = 96.31, track = 1 },
			{ time = 96.51, track = 3 },
			{ time = 96.83, track = 3 },
			{ time = 97.35, track = 3 },
			{ time = 97.61, track = 3 },
			{ time = 98.01, track = 4 },
			{ time = 98.28, track = 3 },
			{ time = 98.48, track = 1 },
			{ time = 99.25, track = 3 },
			{ time = 99.66, track = 4 },
			{ time = 99.91, track = 3 },
			{ time = 100.45, track = 1 },
			{ time = 100.66, track = 3 },
			{ time = 101.10, track = 4 },
			{ time = 101.38, track = 1 },
			{ time = 101.60, track = 3 },
			{ time = 101.96, track = 3 },
			{ time = 102.21, track = 3 },
			{ time = 102.60, track = 4 },
			{ time = 102.98, track = 4 },
			{ time = 103.25, track = 3 },
			{ time = 103.75, track = 1 },
			{ time = 104.23, track = 3 },
			{ time = 104.73, track = 3 },
			{ time = 104.98, track = 1 },
			{ time = 105.21, track = 3 },
			{ time = 105.41, track = 4 },
			{ time = 105.90, track = 3 },
			{ time = 106.06, track = 1 },
			{ time = 106.26, track = 4 },
			{ time = 106.83, track = 4 },
			{ time = 107.20, track = 3 },
			{ time = 107.45, track = 1 },
			{ time = 108.16, track = 3 },
			{ time = 108.68, track = 4 },
			{ time = 110.60, track = 1 },
			{ time = 111.06, track = 3 },
			{ time = 112.00, track = 3 },
			{ time = 112.34, track = 1 },
			{ time = 112.78, track = 4 },
			{ time = 114.98, track = 3 },
			{ time = 115.18, track = 1 },
			{ time = 116.14, track = 4 },
			{ time = 118.91, track = 3 },
			{ time = 119.13, track = 1 },
			{ time = 119.99, track = 4 },
			{ time = 123.78, track = 3 },
			{ time = 124.33, track = 1 },
			{ time = 125.49, track = 4 },
			{ time = 125.99, track = 3 },
			{ time = 126.48, track = 1 },
			{ time = 126.96, track = 4 },
			{ time = 127.96, track = 3 },
			{ time = 128.39, track = 1 },
			{ time = 128.83, track = 3 },
			{ time = 129.38, track = 1 },
			{ time = 129.79, track = 4 },
			{ time = 130.78, track = 3 },
			{ time = 131.30, track = 1 },
			{ time = 131.71, track = 3 },
			{ time = 133.73, track = 4 },
			{ time = 134.58, track = 3 },
			{ time = 135.19, track = 1 },
			{ time = 137.99, track = 3 },
			{ time = 139.04, track = 4 },
			{ time = 141.99, track = 1 },
			{ time = 142.78, track = 3 },
			{ time = 145.76, track = 1 },
			{ time = 146.71, track = 3 },
			{ time = 149.73, track = 1 },
			{ time = 150.41, track = 4 },
			{ time = 154.94, track = 1 },
			{ time = 156.71, track = 3 },
			{ time = 157.64, track = 4 },
			{ time = 158.16, track = 1 },
			{ time = 161.18, track = 3 },
			{ time = 162.23, track = 1 },
			{ time = 164.48, track = 2 },
			{ time = 164.89, track = 1 },
			{ time = 168.69, track = 2 },
			{ time = 169.96, track = 3 },
			{ time = 172.58, track = 1 },
			{ time = 172.81, track = 2 },
			{ time = 173.73, track = 4 },
			{ time = 176.31, track = 1 },
			{ time = 177.53, track = 3 },
		}
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
