local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement

local function MainMenu(props)
	local onSelectGender = props.onSelectGender

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, {
		Title = e("TextLabel", {
			Text = "SELECT GENDER",
			Font = Enum.Font.AmaticSC,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 96,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.35),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(0.8, 0.15),
		}),

		ButtonsContainer = e("Frame", {
			Size = UDim2.fromScale(0.6, 0.3),
			Position = UDim2.fromScale(0.5, 0.55),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
		}, {
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 50),
			}),

			-- Swapped order: GIRL first (left)
			GirlButton = e("TextButton", {
				Text = "GIRL ♀",
				Font = Enum.Font.AmaticSC,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 64,
				BackgroundColor3 = Color3.fromRGB(15, 15, 25),
				BackgroundTransparency = 0.5, -- Set transparency to 0.5
				Size = UDim2.fromOffset(220, 100),
				[React.Event.Activated] = function() onSelectGender("Female") end,
			}, {
				Corner = e("UICorner", { CornerRadius = UDim.new(0.5, 0) }), -- Fully rounded corner (pill style)
			}),

			-- Swapped order: BOY second (right)
			BoyButton = e("TextButton", {
				Text = "BOY ♂",
				Font = Enum.Font.AmaticSC,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 64,
				BackgroundColor3 = Color3.fromRGB(15, 15, 25),
				BackgroundTransparency = 0.5, -- Set transparency to 0.5
				Size = UDim2.fromOffset(220, 100),
				[React.Event.Activated] = function() onSelectGender("Male") end,
			}, {
				Corner = e("UICorner", { CornerRadius = UDim.new(0.5, 0) }), -- Fully rounded corner (pill style)
			}),
		})
	})
end

return MainMenu
