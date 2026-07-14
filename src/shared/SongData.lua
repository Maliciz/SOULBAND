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
	-- Рівень 0 - Початкові пісні
	{
		Id = "tokyo_drift_m",
		Title = "Tokyo Drift (Male Cover)",
		Difficulty = "Easy",
		LevelRequired = 0,
		Gender = "Male",
		Bpm = 120,
		Length = 90,
		AudioId = "rbxassetid://0",
		Notes = {
			{time = 1.0, track = 1}, {time = 1.5, track = 2}, {time = 2.0, track = 3}, {time = 2.5, track = 4},
			{time = 3.0, track = 2}, {time = 3.5, track = 3}, {time = 4.0, track = 1}, {time = 4.5, track = 4},
			{time = 5.0, track = 1}, {time = 5.2, track = 2}, {time = 5.4, track = 3}, {time = 5.6, track = 4},
			{time = 7.0, track = 3, duration = 1.2}, {time = 9.0, track = 2, duration = 1.5}, {time = 11.0, track = 1, duration = 2.0}, {time = 14.0, track = 4}
		}
	},
	{
		Id = "tokyo_drift_f",
		Title = "Tokyo Drift (Female Cover)",
		Difficulty = "Easy",
		LevelRequired = 0,
		Gender = "Female",
		Bpm = 120,
		Length = 90,
		AudioId = "rbxassetid://0",
		Notes = {
			{time = 1.0, track = 4}, {time = 1.5, track = 3}, {time = 2.0, track = 2}, {time = 2.5, track = 1},
			{time = 3.0, track = 3}, {time = 3.5, track = 2}, {time = 4.0, track = 4}, {time = 4.5, track = 1},
			{time = 5.0, track = 4}, {time = 5.2, track = 3}, {time = 5.4, track = 2}, {time = 5.6, track = 1},
			{time = 7.0, track = 2, duration = 1.2}, {time = 9.0, track = 3, duration = 1.5}, {time = 11.0, track = 4, duration = 2.0}, {time = 14.0, track = 1}
		}
	},
	{
		Id = "neon_lights_m",
		Title = "Neon Lights (Male Vocals)",
		Difficulty = "Medium",
		LevelRequired = 0,
		Gender = "Male",
		Bpm = 130,
		Length = 120,
		AudioId = "rbxassetid://0",
		Notes = {
			{time = 0.8, track = 1}, {time = 1.2, track = 3}, {time = 1.6, track = 2}, {time = 2.0, track = 4},
			{time = 2.4, track = 1}, {time = 2.8, track = 3}, {time = 3.2, track = 2}, {time = 3.6, track = 4},
			{time = 4.0, track = 1}, {time = 4.2, track = 2}, {time = 4.4, track = 3}, {time = 4.6, track = 4},
			{time = 5.0, track = 2}, {time = 5.2, track = 1}, {time = 5.4, track = 4}, {time = 5.6, track = 3}
		}
	},
	{
		Id = "neon_lights_f",
		Title = "Neon Lights (Female Vocals)",
		Difficulty = "Medium",
		LevelRequired = 0,
		Gender = "Female",
		Bpm = 130,
		Length = 120,
		AudioId = "rbxassetid://0",
		Notes = {
			{time = 0.8, track = 4}, {time = 1.2, track = 2}, {time = 1.6, track = 3}, {time = 2.0, track = 1},
			{time = 2.4, track = 4}, {time = 2.8, track = 2}, {time = 3.2, track = 3}, {time = 3.6, track = 1},
			{time = 4.0, track = 4}, {time = 4.2, track = 3}, {time = 4.4, track = 2}, {time = 4.6, track = 1},
			{time = 5.0, track = 3}, {time = 5.2, track = 4}, {time = 5.4, track = 1}, {time = 5.6, track = 2}
		}
	},
	{
		Id = "sakura_rock_m",
		Title = "Sakura Rock (Male)",
		Difficulty = "Hard",
		LevelRequired = 2,
		Gender = "Male",
		Bpm = 145,
		Length = 150,
		AudioId = "rbxassetid://0",
		Notes = {
			{time = 0.5, track = 1}, {time = 0.7, track = 2}, {time = 0.9, track = 3}, {time = 1.1, track = 4},
			{time = 1.5, track = 4}, {time = 1.7, track = 3}, {time = 1.9, track = 2}, {time = 2.1, track = 1},
			{time = 2.5, track = 2}, {time = 2.7, track = 2}, {time = 3.0, track = 3}, {time = 3.2, track = 3},
			{time = 3.5, track = 1}, {time = 3.7, track = 4}, {time = 4.0, track = 2}, {time = 4.2, track = 3}
		}
	},
	{
		Id = "sakura_rock_f",
		Title = "Sakura Rock (Female)",
		Difficulty = "Hard",
		LevelRequired = 2,
		Gender = "Female",
		Bpm = 145,
		Length = 150,
		AudioId = "rbxassetid://0",
		Notes = {
			{time = 0.5, track = 4}, {time = 0.7, track = 3}, {time = 0.9, track = 2}, {time = 1.1, track = 1},
			{time = 1.5, track = 1}, {time = 1.7, track = 2}, {time = 1.9, track = 3}, {time = 2.1, track = 4},
			{time = 2.5, track = 3}, {time = 2.7, track = 3}, {time = 3.0, track = 2}, {time = 3.2, track = 2},
			{time = 3.5, track = 4}, {time = 3.7, track = 1}, {time = 4.0, track = 3}, {time = 4.2, track = 2}
		}
	},
	
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
		Id = "9_dean_blunt",
		Title = "9 (Dean Blunt & Panda Bear)",
		Difficulty = "Easy",
		LevelRequired = 0,
		Gender = "Universal",
		Bpm = 115,
		Length = 100,
		AudioId = "rbxassetid://0"
	},
	{
		Id = "deathmetal_panchiko",
		Title = "DEATHMETAL (Panchiko)",
		Difficulty = "Hard",
		LevelRequired = 0,
		Gender = "Universal",
		Bpm = 135,
		Length = 250,
		AudioId = "rbxassetid://0"
	},
	{
		Id = "everlong",
		Title = "Everlong (Foo Fighters)",
		Difficulty = "Hard",
		LevelRequired = 0,
		Gender = "Universal",
		Bpm = 158,
		Length = 250,
		AudioId = "rbxassetid://0"
	},
	{
		Id = "mac_demarco_love",
		Title = "The Way You'd Love Her",
		Difficulty = "Medium",
		LevelRequired = 0,
		Gender = "Universal",
		Bpm = 125,
		Length = 160,
		AudioId = "rbxassetid://0"
	},
	{
		Id = "laputa_panchiko",
		Title = "Laputa (Panchiko)",
		Difficulty = "Medium",
		LevelRequired = 0,
		Gender = "Universal",
		Bpm = 120,
		Length = 170,
		AudioId = "rbxassetid://0"
	},
	{
		Id = "kuuchuu_buranko",
		Title = "Kuuchuu Buranko",
		Difficulty = "Hard",
		LevelRequired = 0,
		Gender = "Universal",
		Bpm = 140,
		Length = 260,
		AudioId = "rbxassetid://0"
	},
	{
		Id = "black_hole_sun",
		Title = "Black Hole Sun (Soundgarden)",
		Difficulty = "Hard",
		LevelRequired = 0,
		Gender = "Universal",
		Bpm = 104,
		Length = 318,
		AudioId = "rbxassetid://0"
	},
	{
		Id = "cause_for_sorrow",
		Title = "Cause for Sorrow (Deadman Slowed)",
		Difficulty = "Easy",
		LevelRequired = 0,
		Gender = "Universal",
		Bpm = 95,
		Length = 220,
		AudioId = "rbxassetid://0"
	},
	{
		Id = "stitches_nervepitch",
		Title = "Stitches (Nervepitch loop)",
		Difficulty = "Extreme",
		LevelRequired = 0,
		Gender = "Universal",
		Bpm = 160,
		Length = 165,
		AudioId = "rbxassetid://0"
	},
	{
		Id = "slide_plastic_tree",
		Title = "Slide (Plastic Tree)",
		Difficulty = "Medium",
		LevelRequired = 0,
		Gender = "Universal",
		Bpm = 130,
		Length = 140,
		AudioId = "rbxassetid://0"
	},
	{
		Id = "starting_over",
		Title = "Starting Over (LSD & Search for God)",
		Difficulty = "Medium",
		LevelRequired = 0,
		Gender = "Universal",
		Bpm = 128,
		Length = 280,
		AudioId = "rbxassetid://0"
	},
	{
		Id = "too_much",
		Title = "Too Much",
		Difficulty = "Easy",
		LevelRequired = 0,
		Gender = "Universal",
		Bpm = 100,
		Length = 170,
		AudioId = "rbxassetid://0"
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
