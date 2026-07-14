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

local loadingImage = Instance.new("ImageLabel")
loadingImage.Name = "LoadingImage"
loadingImage.Size = UDim2.new(1, 0, 1, 0)
loadingImage.BackgroundTransparency = 1
loadingImage.Image = "rbxassetid://0" -- Користувач додасть картинку сюди
loadingImage.ScaleType = Enum.ScaleType.Crop
loadingImage.BorderSizePixel = 0
loadingImage.Parent = loadingScreen

local loadingText = Instance.new("TextLabel")
loadingText.Name = "LoadingText"
loadingText.Size = UDim2.new(1, 0, 0, 60)
loadingText.Position = UDim2.new(0, 0, 0.82, 0)
loadingText.BackgroundTransparency = 1
loadingText.TextColor3 = Color3.fromRGB(255, 255, 255)
loadingText.TextSize = 36
loadingText.Font = Enum.Font.FredokaOne
loadingText.Text = "ЗАВАНТАЖЕННЯ ГРИ..."
loadingText.Parent = loadingScreen

-- 3. Чекаємо, поки завантажиться весь плейс
if not game:IsLoaded() then
	game.Loaded:Wait()
end

-- Додатковий буфер 3 секунди, щоб все прогрузилося
task.wait(3.0)

-- 4. Плавне зникнення (Tween)
local fadeInfo = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tweenBg = TweenService:Create(loadingScreen, fadeInfo, {BackgroundTransparency = 1})
local tweenImg = TweenService:Create(loadingImage, fadeInfo, {ImageTransparency = 1})
local tweenTxt = TweenService:Create(loadingText, fadeInfo, {TextTransparency = 1})

tweenBg:Play()
tweenImg:Play()
tweenTxt:Play()

tweenBg.Completed:Connect(function()
	screenGui:Destroy() -- Повністю очищаємо GUI
end)
