local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local HAIR_POOLS = {
	Male = { 11103884344, 37819385, 11103880280, 16630147 },
	Female = { 18428787351, 6223444093, 117475707430348, 1662442848 }
}

local HAIR_NAMES = {
	[11103884344] = "Emo Hair",
	[37819385] = "Charmer Hair",
	[11103880280] = "Backwards Hat",
	[16630147] = "Action Hair",
	[18428787351] = "Pigtails",
	[6223444093] = "Ponytail",
	[117475707430348] = "Moe Kitty Hair",
	[1662442848] = "Curly Hair"
}

local function CharacterCreator(props)
	local name, setName = useState("")
	local gender, setGender = useState(props.initialGender or "Male")

	-- Initial hair ID from simplified pool
	local initialPool = HAIR_POOLS[gender]
	local hairId, setHairId = useState(initialPool[1])
	local color, setColor = useState(Color3.fromRGB(255, 0, 255))

	local colorPresets = {
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(200, 200, 200),
		Color3.fromRGB(150, 150, 150),
		Color3.fromRGB(100, 100, 100),
		Color3.fromRGB(255, 0, 255), -- Pink
		Color3.fromRGB(0, 255, 255), -- Cyan
		Color3.fromRGB(255, 255, 0), -- Yellow
	}

	-- Update hair when gender changes
	useEffect(function()
		local pool = HAIR_POOLS[gender]
		setHairId(pool[1])
	end, {gender})

	-- Trigger preview change
	useEffect(function()
		if props.onPreviewChange then
			props.onPreviewChange(gender, hairId, color)
		end
	end, {gender, hairId, color})

	local function rollHair()
		local pool = HAIR_POOLS[gender]
		local randomHair = pool[math.random(1, #pool)]
		setHairId(randomHair)
	end

	local function onFinish()
		local finalName = name
		if finalName == "" then
			finalName = "Artist"
		end
		if props.onFinish then
			props.onFinish(finalName, gender, hairId, color)
		end
	end

	return e("Frame", {
		Size = UDim2.fromScale(0.3, 1),
		Position = UDim2.fromScale(0, 0),
		BackgroundColor3 = Color3.fromRGB(20, 20, 25),
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
			Position = UDim2.fromScale(0.5, 0.35),
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

		-- Roll Hair Button (Removed 🎲 emoji from text as requested)
		RollHairContainer = e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.50),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(0.8, 0.08),
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
				Size = UDim2.fromOffset(220, 50),
				[React.Event.Activated] = rollHair
			}, { Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }) }),
			HairNameLabel = e("TextLabel", {
				Text = "Hair: " .. (HAIR_NAMES[hairId] or "Unknown"),
				Font = Enum.Font.AmaticSC,
				TextColor3 = Color3.fromRGB(150, 150, 150),
				TextSize = 24,
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(220, 20),
			})
		}),

		-- Color Picker
		ColorPicker = e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.68),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(0.8, 0.1),
		}, {
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 10)
			}),
			Colors = e(React.Fragment, nil, (function()
				local btns = {}
				for i, c in ipairs(colorPresets) do
					btns["Color" .. i] = e("TextButton", {
						Text = "",
						BackgroundColor3 = c,
						Size = UDim2.fromOffset(36, 36),
						[React.Event.Activated] = function() setColor(c) end
					}, {
						Corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
						Stroke = color == c and e("UIStroke", {
							Color = Color3.fromRGB(255, 255, 255),
							Thickness = 2
						})
					})
				end
				return btns
			end)())
		}),

		-- Finish Button
		FinishBtn = e("TextButton", {
			Text = "FINISH",
			Font = Enum.Font.AmaticSC,
			TextColor3 = Color3.fromRGB(20, 20, 25),
			TextSize = 48,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Position = UDim2.fromScale(0.5, 0.85),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(0.8, 0.1),
			[React.Event.Activated] = onFinish
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) })
		})
	})
end

return CharacterCreator
