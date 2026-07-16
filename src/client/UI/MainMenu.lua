local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState

local function MainMenu(props)
	local onSelectGender = props.onSelectGender
	local isHoveredMan, setIsHoveredMan = useState(false)
	local isHoveredGirl, setIsHoveredGirl = useState(false)

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

			ManButton = e("TextButton", {
				Text = "BOY ♂",
				Font = Enum.Font.AmaticSC,
				TextColor3 = isHoveredMan and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(255, 255, 255),
				TextSize = 64,
				BackgroundColor3 = Color3.fromRGB(15, 15, 25),
				BackgroundTransparency = 0.3,
				Size = UDim2.fromOffset(220, 100),
				[React.Event.Activated] = function() onSelectGender("Male") end,
				[React.Event.MouseEnter] = function() setIsHoveredMan(true) end,
				[React.Event.MouseLeave] = function() setIsHoveredMan(false) end,
			}, {
				Corner = e("UICorner", { CornerRadius = UDim.new(0, 10) }),
				Stroke = e("UIStroke", {
					Color = isHoveredMan and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(100, 100, 100),
					Thickness = isHoveredMan and 3 or 1.5,
				})
			}),

			GirlButton = e("TextButton", {
				Text = "GIRL ♀",
				Font = Enum.Font.AmaticSC,
				TextColor3 = isHoveredGirl and Color3.fromRGB(255, 0, 255) or Color3.fromRGB(255, 255, 255),
				TextSize = 64,
				BackgroundColor3 = Color3.fromRGB(15, 15, 25),
				BackgroundTransparency = 0.3,
				Size = UDim2.fromOffset(220, 100),
				[React.Event.Activated] = function() onSelectGender("Female") end,
				[React.Event.MouseEnter] = function() setIsHoveredGirl(true) end,
				[React.Event.MouseLeave] = function() setIsHoveredGirl(false) end,
			}, {
				Corner = e("UICorner", { CornerRadius = UDim.new(0, 10) }),
				Stroke = e("UIStroke", {
					Color = isHoveredGirl and Color3.fromRGB(255, 0, 255) or Color3.fromRGB(100, 100, 100),
					Thickness = isHoveredGirl and 3 or 1.5,
				})
			}),
		})
	})
end

return MainMenu
