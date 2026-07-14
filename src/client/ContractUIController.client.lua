-- StarterPlayer/StarterPlayerScripts/ContractUIController.client.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameSettings = require(ReplicatedStorage:WaitForChild("GameSettings"))

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Функція для рекурсивного пошуку GUI контрактів (на випадок, якщо воно лежить всередині інших папок/фреймів)
local function findContractsGui()
	local gui = PlayerGui:FindFirstChild("Contract'sGui", true)
	if gui then return gui end
	
	-- Якщо ще не завантажилося, почекаємо
	for i = 1, 20 do
		gui = PlayerGui:FindFirstChild("Contract'sGui", true)
		if gui then return gui end
		task.wait(0.5)
	end
	return nil
end

local ContractsGui = findContractsGui()
if not ContractsGui then
	warn("⚠️ Не вдалося знайти Contract'sGui у PlayerGui! Перевірте назву та розташування GUI.")
	return
end

local BackgroundFrame = ContractsGui:FindFirstChild("background", true)
if not BackgroundFrame then
	warn("⚠️ Не вдалося знайти фрейм 'background' всередині Contract'sGui!")
	return
end

-- Шукаємо або створюємо кнопку закриття (X)
local closeButton = ContractsGui:FindFirstChild("TextButton", true) or BackgroundFrame:FindFirstChild("TextButton", true)

-- Спочатку приховуємо інтерфейс
ContractsGui.Enabled = false
BackgroundFrame.Visible = false

-- Логіка відкриття/закриття меню
local function openMenu()
	ContractsGui.Enabled = true
	BackgroundFrame.Visible = true
	
	-- Анімація випливання
	BackgroundFrame.Size = UDim2.new(0, 0, 0, 0)
	BackgroundFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	BackgroundFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local tween = TweenService:Create(BackgroundFrame, tweenInfo, {
		Size = UDim2.new(0, 450, 0, 500)
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
	
	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uiListLayout.Padding = UDim.new(0, 15)
	uiListLayout.Parent = listFrame
end

-- Допоміжна функція створення кнопки контракту
local function createContractButton(contractId, contractData)
	local btn = listFrame:FindFirstChild(contractId .. "_Button")
	if btn then return end -- Уникаємо дублювання кнопок при повторних викликах

	btn = Instance.new("TextButton")
	btn.Name = contractId .. "_Button"
	btn.Size = UDim2.new(1, 0, 0, 80)
	btn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextSize = 16
	btn.Font = Enum.Font.FredokaOne
	btn.BorderSizePixel = 0
	
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0.15, 0)
	uiCorner.Parent = btn

	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = Color3.fromRGB(0, 170, 255)
	uiStroke.Thickness = 2
	uiStroke.Parent = btn

	btn.Text = string.format(
		"%s\nСкладність: %s | Нагорода: %d$ | +%d фанів",
		contractData.Name,
		contractData.Difficulty,
		contractData.CashReward,
		contractData.FanReward
	)

	btn.MouseEnter:Connect(function()
		btn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
		uiStroke.Color = Color3.fromRGB(255, 0, 128)
	end)

	btn.MouseLeave:Connect(function()
		btn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
		uiStroke.Color = Color3.fromRGB(0, 170, 255)
	end)

	btn.MouseButton1Click:Connect(function()
		closeMenu()
		task.wait(0.3)
		
		local success, message = ReplicatedStorage.Remotes.AcceptContract:InvokeServer(contractId)
		if not success then
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

-- Створюємо кнопки для всіх контрактів
for contractId, contractData in pairs(GameSettings.Contracts) do
	createContractButton(contractId, contractData)
end

-- Підключення до ProximityPrompt NPC
local function bindNpcPrompt()
	local prompt = nil
	
	-- 1. Шукаємо за точним шляхом, вказаним користувачем: Workspace -> NPC'S -> NPC'S--Main -> Contract_NPC's
	local npcsFolder = workspace:FindFirstChild("NPC'S") or workspace:FindFirstChild("NPC--Main")
	if npcsFolder then
		local mainNpcs = npcsFolder:FindFirstChild("NPC'S--Main") or npcsFolder:FindFirstChild("NPC--Main") or npcsFolder
		if mainNpcs then
			local contractNpc = mainNpcs:FindFirstChild("Contract_NPC's") or mainNpcs:FindFirstChild("Contract_NPCs") or mainNpcs:FindFirstChild("NPC--Contract's")
			if contractNpc then
				prompt = contractNpc:FindFirstChildWhichIsA("ProximityPrompt", true)
			end
		end
	end
	
	-- 2. Резервний пошук по всьому Workspace
	if not prompt then
		for _, desc in ipairs(workspace:GetDescendants()) do
			if desc:IsA("ProximityPrompt") then
				local parentName = desc.Parent.Name:lower()
				if string.find(parentName, "npc") or string.find(parentName, "contract") then
					prompt = desc
					break
				end
			end
		end
	end
	
	-- 3. Крайній випадок: беремо перший ліпший prompt
	if not prompt then
		for _, desc in ipairs(workspace:GetDescendants()) do
			if desc:IsA("ProximityPrompt") then
				prompt = desc
				break
			end
		end
	end

	if prompt then
		prompt.ObjectText = "Контракти"
		prompt.ActionText = "Відкрити меню"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 0.5
		
		prompt.Triggered:Connect(function(player)
			if player == Player then
				openMenu()
			end
		end)
		print("🎉 ProximityPrompt успішно зв'язано з GUI контрактів!")
	else
		warn("⚠️ ProximityPrompt для контрактів не знайдено в Workspace. Створіть prompt всередині Contract_NPC's.")
	end
end

-- Почекаємо повного завантаження світу
task.wait(1.5)
bindNpcPrompt()
