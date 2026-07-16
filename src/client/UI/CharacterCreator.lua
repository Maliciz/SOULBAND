local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local HAIR_POOLS = {
	Male = { 117507240044338, 323476364, 116370675366789, 135506916870785, 16630147, 96798036721020, 6323887109, 9244014391 },
	Female = { 135155177954115, 107293851535602, 133916675233924, 77486416495383, 81200214773652, 101106085278254, 123689663512363 }
}

local SHIRT_POOLS = {
	Male = { 108960428758609, 9592807408, 10875659145, 13707005008, 104190928434681, 76997048714989, 18835449648, 18660348672, 137902478383071, 6554200369, 14173374711 },
	Female = { 129441329773194, 9362987703, 133818856662212, 102386567517522, 18274001828, 14802695879, 12254851653, 13112718134, 71456654300961, 94281511461352 }
}

local PANTS_POOLS = {
	Male = { 4080983570, 91151766440767, 13063157758, 7581780596, 10546832797, 11372689045, 15376281287, 6008652263, 16469248428, 15074051700, 9638809291, 109655854018329, 97760987071166 },
	Female = { 5706164157, 127208370579986, 113947226961382, 139721083684709, 121322491543545, 11164834217, 11573089344, 116066388451807, 70862450675651, 123726090805165, 18270430948, 14712307968, 122101164939992, 84691255490993, 91356299567190 }
}

local function indexOf(t, value)
	for i, v in ipairs(t) do
		if v == value then
			return i
		end
	end
	return 1
end

local function CharacterCreator(props)
	local name, setName = useState("")
	local gender, setGender = useState(props.initialGender or "Male")

	local initialHPool = HAIR_POOLS[gender]
	local initialSPool = SHIRT_POOLS[gender]
	local initialPPool = PANTS_POOLS[gender]

	local hairId, setHairId = useState(initialHPool[1])
	local shirtId, setShirtId = useState(initialSPool[1])
	local pantsId, setPantsId = useState(initialPPool[1])

	local color, setColor = useState(Color3.fromRGB(255, 255, 255)) -- Neutral white default color

	-- Update hair and clothing when gender changes
	useEffect(function()
		local hPool = HAIR_POOLS[gender]
		local sPool = SHIRT_POOLS[gender]
		local pPool = PANTS_POOLS[gender]
		setHairId(hPool[1])
		setShirtId(sPool[1])
		setPantsId(pPool[1])
	end, {gender})

	-- Trigger preview change
	useEffect(function()
		if props.onPreviewChange then
			props.onPreviewChange(gender, hairId, color, shirtId, pantsId)
		end
	end, {gender, hairId, color, shirtId, pantsId})

	local function rollHair()
		local pool = HAIR_POOLS[gender]
		local randomHair = pool[math.random(1, #pool)]
		setHairId(randomHair)
	end

	local function rollShirt()
		local pool = SHIRT_POOLS[gender]
		local randomShirt = pool[math.random(1, #pool)]
		setShirtId(randomShirt)
	end

	local function rollPants()
		local pool = PANTS_POOLS[gender]
		local randomPants = pool[math.random(1, #pool)]
		setPantsId(randomPants)
	end

	local function onFinish()
		local finalName = name
		if finalName == "" then
			finalName = "Artist"
		end
		if props.onFinish then
			props.onFinish(finalName, gender, hairId, color, shirtId, pantsId)
		end
	end

	return e("Frame", {
		Size = UDim2.fromScale(0.3, 1),
		Position = UDim2.fromScale(0, 0),
		BackgroundColor3 = Color3.fromRGB(20, 20, 25),
		BackgroundTransparency = 0.6, -- 0.6 transparency as requested
		BorderSizePixel = 0,
	}, {
		Title = e("TextLabel", {
			Text = "CREATE ARTIST",
			Font = Enum.Font.AmaticSC,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 64,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.08),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(0.8, 0.1),
		}),

		-- Name input
		NameInput = e("TextBox", {
			Text = name,
			PlaceholderText = "Stage Name...",
			Font = Enum.Font.AmaticSC,
			TextSize = 40,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundColor3 = Color3.fromRGB(30, 30, 35),
			Position = UDim2.fromScale(0.5, 0.2),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(0.8, 0.08),
			[React.Change.Text] = function(rbx)
				setName(rbx.Text:gsub("[^%w%s]", ""))
			end,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
			Stroke = e("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Thickness = 1 })
		}),

		-- Gender Select (Male / Female)
		GenderContainer = e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.33),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(0.8, 0.08),
		}, {
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 20)
			}),
			MaleBtn = e("TextButton", {
				Text = "MALE",
				Font = Enum.Font.AmaticSC,
				TextColor3 = gender == "Male" and Color3.fromRGB(20, 20, 25) or Color3.fromRGB(255, 255, 255),
				TextSize = 36,
				BackgroundColor3 = gender == "Male" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(40, 40, 45),
				Size = UDim2.fromOffset(100, 50),
				[React.Event.Activated] = function() setGender("Male") end
			}, { Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }) }),
			FemaleBtn = e("TextButton", {
				Text = "FEMALE",
				Font = Enum.Font.AmaticSC,
				TextColor3 = gender == "Female" and Color3.fromRGB(20, 20, 25) or Color3.fromRGB(255, 255, 255),
				TextSize = 36,
				BackgroundColor3 = gender == "Female" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(40, 40, 45),
				Size = UDim2.fromOffset(100, 50),
				[React.Event.Activated] = function() setGender("Female") end
			}, { Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }) })
		}),

		-- Roll Hair Button
		RollHairContainer = e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.46),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(0.8, 0.09),
		}, {
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 5)
			}),
			RollBtn = e("TextButton", {
				Text = "ROLL HAIR",
				Font = Enum.Font.AmaticSC,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 36,
				BackgroundColor3 = Color3.fromRGB(40, 40, 45),
				Size = UDim2.fromOffset(220, 45),
				[React.Event.Activated] = rollHair
			}, { Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }) }),
			HairNameLabel = e("TextLabel", {
				Text = "Hair: Style #" .. tostring(indexOf(HAIR_POOLS[gender], hairId)),
				Font = Enum.Font.AmaticSC,
				TextColor3 = Color3.fromRGB(150, 150, 150),
				TextSize = 24,
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(220, 20),
			})
		}),

		-- Roll Shirt Button
		RollShirtContainer = e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.59),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(0.8, 0.09),
		}, {
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 5)
			}),
			RollBtn = e("TextButton", {
				Text = "ROLL SHIRT",
				Font = Enum.Font.AmaticSC,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 36,
				BackgroundColor3 = Color3.fromRGB(40, 40, 45),
				Size = UDim2.fromOffset(220, 45),
				[React.Event.Activated] = rollShirt
			}, { Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }) }),
			ShirtNameLabel = e("TextLabel", {
				Text = "Shirt: Style #" .. tostring(indexOf(SHIRT_POOLS[gender], shirtId)),
				Font = Enum.Font.AmaticSC,
				TextColor3 = Color3.fromRGB(150, 150, 150),
				TextSize = 24,
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(220, 20),
			})
		}),

		-- Roll Pants Button
		RollPantsContainer = e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.72),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(0.8, 0.09),
		}, {
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 5)
			}),
			RollBtn = e("TextButton", {
				Text = "ROLL PANTS",
				Font = Enum.Font.AmaticSC,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 36,
				BackgroundColor3 = Color3.fromRGB(40, 40, 45),
				Size = UDim2.fromOffset(220, 45),
				[React.Event.Activated] = rollPants
			}, { Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }) }),
			PantsNameLabel = e("TextLabel", {
				Text = "Pants: Style #" .. tostring(indexOf(PANTS_POOLS[gender], pantsId)),
				Font = Enum.Font.AmaticSC,
				TextColor3 = Color3.fromRGB(150, 150, 150),
				TextSize = 24,
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(220, 20),
			})
		}),

		-- Finish Button
		FinishBtn = e("TextButton", {
			Text = "FINISH",
			Font = Enum.Font.AmaticSC,
			TextColor3 = Color3.fromRGB(20, 20, 25),
			TextSize = 48,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Position = UDim2.fromScale(0.5, 0.88),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(0.8, 0.1),
			[React.Event.Activated] = onFinish
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) })
		})
	})
end

return CharacterCreator
