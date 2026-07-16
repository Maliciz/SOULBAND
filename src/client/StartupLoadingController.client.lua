-- ReplicatedFirst/StartupLoadingController.client.lua
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- 1. Вимикаємо стандартний завантажувальний екран Roblox
ReplicatedFirst:RemoveDefaultLoadingScreen()

-- 2. Створюємо наш кастомний екран завантаження на весь екран
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StartupLoadingUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true -- Перекриває навіть верхню панель Roblox
screenGui.Parent = PlayerGui

local loadingScreen = Instance.new("Frame")
loadingScreen.Name = "LoadingScreen"
loadingScreen.Size = UDim2.new(1, 0, 1, 0)
loadingScreen.Position = UDim2.new(0, 0, 0, 0)
loadingScreen.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
loadingScreen.BorderSizePixel = 0
loadingScreen.ZIndex = 999999
loadingScreen.Parent = screenGui

local loadingText = Instance.new("TextLabel")
loadingText.Name = "LoadingText"
loadingText.Size = UDim2.new(1, 0, 0, 40)
loadingText.Position = UDim2.new(0, 0, 0.87, 0)
loadingText.BackgroundTransparency = 1
loadingText.TextColor3 = Color3.fromRGB(255, 255, 255)
loadingText.TextSize = 36
loadingText.FontFace = Font.new("rbxasset://fonts/families/AmaticSC.json")
loadingText.Text = "LOADING GAME..."
loadingText.Parent = loadingScreen

-- Progress Bar
local barBackground = Instance.new("Frame")
barBackground.Name = "BarBackground"
barBackground.Size = UDim2.new(0.4, 0, 0, 8)
barBackground.Position = UDim2.new(0.5, 0, 0.95, 0)
barBackground.AnchorPoint = Vector2.new(0.5, 0.5)
barBackground.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
barBackground.BorderSizePixel = 0
barBackground.Parent = loadingScreen

local barCornerBg = Instance.new("UICorner")
barCornerBg.CornerRadius = UDim.new(1, 0)
barCornerBg.Parent = barBackground

local barFill = Instance.new("Frame")
barFill.Name = "BarFill"
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Біла лінія
barFill.BorderSizePixel = 0
barFill.Parent = barBackground

local barCornerFill = Instance.new("UICorner")
barCornerFill.CornerRadius = UDim.new(1, 0)
barCornerFill.Parent = barFill

-- Start progress animation
local progressTween = TweenService:Create(barFill, TweenInfo.new(12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0.9, 0, 1, 0)})
progressTween:Play()

-- 3. Чекаємо, поки завантажиться весь плейс
if not game:IsLoaded() then
	game.Loaded:Wait()
end

-- Додатковий буфер 3 секунди
task.wait(3.0)

-- Finish progress
progressTween:Cancel()
local finishTween = TweenService:Create(barFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 1, 0)})
finishTween:Play()
finishTween.Completed:Wait()

-- 4. Плавне зникнення (Tween)
local fadeInfo = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tweenBg = TweenService:Create(loadingScreen, fadeInfo, {BackgroundTransparency = 1})
local tweenTxt = TweenService:Create(loadingText, fadeInfo, {TextTransparency = 1})
local tweenBarBg = TweenService:Create(barBackground, fadeInfo, {BackgroundTransparency = 1})
local tweenBarFill = TweenService:Create(barFill, fadeInfo, {BackgroundTransparency = 1})

tweenBg:Play()
tweenTxt:Play()
tweenBarBg:Play()
tweenBarFill:Play()

tweenBg.Completed:Connect(function()
	screenGui:Destroy() -- Повністю очищаємо GUI
end)
