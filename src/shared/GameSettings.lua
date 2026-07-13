-- ReplicatedStorage/GameSettings.lua
local GameSettings = {}

-- Стандартні клавіші для ритм-гри
GameSettings.DefaultKeybinds = {
	"X", "C", "N", "M"
}

-- Магазин одягу (Брендовий одяг у Токіо)
-- Дає буст до отримання фанів (Fan Multiplier)
GameSettings.ClothingShop = {
	{ Id = "casual_tokyo", Name = "Tokyo Casual Outfit", Price = 100, FanBoost = 1.1 },
	{ Id = "harajuku_punk", Name = "Harajuku Punk Leather", Price = 500, FanBoost = 1.4 },
	{ Id = "cyberpunk_neon", Name = "Shibuya Neon Cyber-Suit", Price = 2500, FanBoost = 2.0 },
	{ Id = "gothic_lolita", Name = "Gothic Lolita Dress", Price = 7500, FanBoost = 3.5 },
	{ Id = "legendary_rockstar", Name = "Legendary Rockstar Kimono", Price = 25000, FanBoost = 6.0 }
}

-- Магазин музичних інструментів (Гітари)
-- Дає пасивний буст до фанів
GameSettings.GuitarShop = {
	{ Id = "classic_acoustic", Name = "Classic Acoustic Guitar", Price = 150, FanBoost = 1.15 },
	{ Id = "stratocaster_red", Name = "Red Stratocaster Electric", Price = 800, FanBoost = 1.5 },
	{ Id = "cyber_bass", Name = "Cyberpunk Bass Synth", Price = 3500, FanBoost = 2.5 },
	{ Id = "double_neck_god", Name = "Double-Neck Guitar of Gods", Price = 12000, FanBoost = 5.0 }
}

-- Список музикантів для найму (Hiring Musicians)
GameSettings.MusiciansList = {
	{ Id = "drummer_takeshi", Name = "Takeshi (Drummer)", Price = 500, MinFans = 100, BaseFanBoost = 1.2 },
	{ Id = "bassist_yuki", Name = "Yuki (Bassist)", Price = 2000, MinFans = 500, BaseFanBoost = 1.5 },
	{ Id = "synth_ren", Name = "Ren (Keyboardist/Synth)", Price = 10000, MinFans = 2500, BaseFanBoost = 2.2 },
	{ Id = "vocal_sakura", Name = "Sakura (Backing Vocals)", Price = 30000, MinFans = 10000, BaseFanBoost = 4.0 }
}

-- Контракти
GameSettings.Contracts = {
	Bar = {
		Name = "Виступ в барі (Токіо)",
		MinLevel = 0,
		MinFans = 0,
		Difficulty = "Easy",
		CashReward = 50,
		FanReward = 20,
		Cooldown = 30 -- секунд
	},
	Event = {
		Name = "Вуличний івент (Сібуя)",
		MinLevel = 2,
		MinFans = 300,
		Difficulty = "Medium",
		CashReward = 250,
		FanReward = 120,
		Cooldown = 120
	},
	Concert = {
		Name = "Концерт у клубі (Womb Tokyo)",
		MinLevel = 5,
		MinFans = 2000,
		Difficulty = "Hard",
		CashReward = 1200,
		FanReward = 600,
		Cooldown = 300
	},
	MegaFestival = {
		Name = "Рок-Фестиваль (Tokyo Dome)",
		MinLevel = 10,
		MinFans = 15000,
		Difficulty = "Extreme",
		CashReward = 8000,
		FanReward = 4000,
		Cooldown = 900
	}
}

return GameSettings
