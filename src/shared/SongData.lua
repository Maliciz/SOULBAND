-- ReplicatedStorage/SongData.lua
local SongData = {}

SongData.DifficultyXP = {
	Easy = 5,
	Medium = 22,
	Hard = 50,
	Extreme = 68
}

SongData.Songs = {
	-- Рівень 0 - Початкові пісні (12 пісень: по 6 для чоловічого та жіночого голосів)
	{
		Id = "tokyo_drift_m",
		Title = "Tokyo Drift (Male Cover)",
		Difficulty = "Easy",
		LevelRequired = 0,
		Gender = "Male",
		Bpm = 120,
		Length = 90, -- секунди
		-- Список нот: {час у секундах, трек (1-4)}
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
		Notes = {
			{time = 0.5, track = 4}, {time = 0.7, track = 3}, {time = 0.9, track = 2}, {time = 1.1, track = 1},
			{time = 1.5, track = 1}, {time = 1.7, track = 2}, {time = 1.9, track = 3}, {time = 2.1, track = 4},
			{time = 2.5, track = 3}, {time = 2.7, track = 3}, {time = 3.0, track = 2}, {time = 3.2, track = 2},
			{time = 3.5, track = 4}, {time = 3.7, track = 1}, {time = 4.0, track = 3}, {time = 4.2, track = 2}
		}
	},
	-- Можна легко розширити до 56 пісень за цією структурою
}

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
