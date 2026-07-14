-- StarterPlayer/StarterPlayerScripts/ContractUIController.client.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameSettings = require(ReplicatedStorage:WaitForChild("GameSettings"))

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Очікуємо інтерфейс контрактів
local ContractsGui = PlayerGui:WaitForChild("Contract'sGui")
local BackgroundFrame = ContractsGui:WaitForChild("background")

-- Шукаємо або створюємо кнопку закриття (X)
local closeButton = ContractsGui:FindFirstChild("TextButton", true) or BackgroundFrame:FindFirstChild("TextButton", true)

-- Спочатку приховуємо інтерфейс
ContractsGui.Enabled = false
BackgroundFrame.Visible = false

-- Логіка відкриття/закриття меню
local function openMenu()
	ContractsGui.Enabled = true
	BackgroundFrame.Visible = true
	
	-- Subtle pop-in animation
	BackgroundFrame.Size = UDim2.new(0, 0, 0, 0)
	BackgroundFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	BackgroundFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local tween = TweenService:Create(BackgroundFrame, tweenInfo, {
		Size = UDim2.new(0, 450, 0, 500) -- Стандартний розмір меню
	})
	tween:Play()
end

local function closeMenu()
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local tween = TweenService:Create(BackgroundFrame, tweenInfo, {
		Size = UDim2.new(0, 0, 0, 0)
	})
	tween:Play()
	tween.Completed:Connect(function()
		BackgroundFrame.Visible = false
		ContractsGui.Enabled = false
	end)
end

if closeButton then
	closeButton.MouseButton1Click:Connect(closeMenu)
end

-- Створюємо контейнер для кнопок контрактів всередині background
local listFrame = BackgroundFrame:FindFirstChild("ListFrame")
if not listFrame then
	listFrame = Instance.new("Frame")
	listFrame.Name = "ListFrame"
	listFrame.Size = UDim2.new(1, -40, 1, -80)
	listFrame.Position = UDim2.new(0, 20, 0, 60)
	listFrame.BackgroundTransparency = 1
	listFrame.Parent = BackgroundFrame
	
	-- Вертикальне вирівнювання кнопок
	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uiListLayout.Padding = UDim.new(0, 15)
	uiListLayout.Parent = listFrame
end

-- Допоміжна функція створення кнопки контракту
local function createContractButton(contractId, contractData)
	local btn = Instance.new("TextButton")
	btn.Name = contractId .. "_Button"
	btn.Size = UDim2.new(1, 0, 0, 80)
	btn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextSize = 16
	btn.Font = Enum.Font.FredokaOne
	btn.BorderSizePixel = 0
	
	-- Додаємо закруглені кути
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0.15, 0)
	uiCorner.Parent = btn

	-- Додаємо обводку (stroke) для неонового ефекту
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = Color3.fromRGB(0, 170, 255)
	uiStroke.Thickness = 2
	uiStroke.Parent = btn

	-- Текст контракту
	btn.Text = string.format(
		"%s\nСкладність: %s | Нагорода: %d$ | +%d фанів",
		contractData.Name,
		contractData.Difficulty,
		contractData.CashReward,
		contractData.FanReward
	)

	-- Ефекти наведення миші
	btn.MouseEnter:Connect(function()
		btn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
		uiStroke.Color = Color3.fromRGB(255, 0, 128) -- Рожевий неон
	end)

	btn.MouseLeave:Connect(function()
		btn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
		uiStroke.Color = Color3.fromRGB(0, 170, 255) -- Блакитний неон
	end)

	-- Обробка натискання
	btn.MouseButton1Click:Connect(function()
		closeMenu()
		task.wait(0.3) -- Зачекаємо закриття меню
		
		local success, message = ReplicatedStorage.Remotes.AcceptContract:InvokeServer(contractId)
		if not success then
			-- Якщо не вдалося почати (наприклад кулдаун або низький рівень)
			local StarterGui = game:GetService("StarterGui")
			StarterGui:SetCore("SendNotification", {
				Title = "Контракт заблоковано",
				Text = tostring(message),
				Duration = 5
			})
		end
	end)

	btn.Parent = listFrame
end

-- Створюємо кнопки для всіх контрактів з налаштувань
for contractId, contractData in pairs(GameSettings.Contracts) do
	createContractButton(contractId, contractData)
end

-- Підключення до ProximityPrompt NPC
local function bindNpcPrompt()
	-- Шукаємо prompt в Workspace
	-- 1. Спершу шукаємо в очікуваному місці
	local npcFolder = workspace:FindFirstChild("NPC'S") or workspace:FindFirstChild("NPC'S--Main")
	local contractNpc = npcFolder and npcFolder:FindFirstChild("NPC--Contract's")
	local prompt = contractNpc and contractNpc:FindFirstChildWhichIsA("ProximityPrompt", true)
	
	-- 2. Якщо не знайшли, шукаємо будь-який ProximityPrompt у всьому Workspace
	if not prompt then
		for _, desc in ipairs(workspace:GetDescendants()) do
			if desc:IsA("ProximityPrompt") then
				prompt = desc
				break
			end
		end
	end

	if prompt then
		prompt.ObjectText = "NPC Контрактів"
		prompt.ActionText = "Переглянути контракти"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 0.5
		
		prompt.Triggered:Connect(function(player)
			if player == Player then
				openMenu()
			end
		end)
		print("🎉 ProximityPrompt успішно зв'язано з GUI контрактів!")
	else
		warn("⚠️ ProximityPrompt для контрактів не знайдено в Workspace. Перевірте, чи додано його до вашого NPC.")
	end
end

-- Чекаємо завантаження Workspace перед прив'язкою
task.wait(1)
bindNpcPrompt()
