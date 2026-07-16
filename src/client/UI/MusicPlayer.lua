local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local SongData = require(ReplicatedStorage.SongData)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local function MusicPlayer()
    local songs = SongData.Songs
    local currentSongIndex, setCurrentSongIndex = useState(1)
    local isPlaying, setIsPlaying = useState(true)

    local currentSong = songs[currentSongIndex]

    local function onNext()
        setCurrentSongIndex(function(prev)
            return (prev % #songs) + 1
        end)
    end

    local function onTogglePlay()
        setIsPlaying(function(prev)
            return not prev
        end)
    end

    return e("Frame", {
        Size = UDim2.fromOffset(300, 70), -- Ð¢Ñ€Ð¾Ñ…Ð¸ ÑˆÐ¸Ñ€ÑˆÐµ Ð´Ð»Ñ Ð±Ñ–Ð»ÑŒÑˆÐ¾Ð³Ð¾ Ñ‚ÐµÐºÑÑ‚Ñƒ
        Position = UDim2.new(1, -20, 1, -20),
        AnchorPoint = Vector2.new(1, 1),
        BackgroundTransparency = 1,
    }, {
        Title = e("TextLabel", {
            Text = currentSong and currentSong.Title or "No Song",
            Font = Enum.Font.AmaticSC,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 84, -- Ð—Ð½Ð°Ñ‡Ð½Ð¾ Ð·Ð±Ñ–Ð»ÑŒÑˆÐµÐ½Ð¾
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -110, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }),
        
        PlayBtn = e("TextButton", {
            Text = isPlaying and "||" or ">",
            Font = Enum.Font.AmaticSC, -- Ð—Ð¼Ñ–Ð½Ð¸Ð² Ð½Ð° AmaticSC Ð´Ð»Ñ ÑÑ‚Ð¸Ð»ÑŽ
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 72, -- Ð—Ð½Ð°Ñ‡Ð½Ð¾ Ð·Ð±Ñ–Ð»ÑŒÑˆÐµÐ½Ð¾
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(40, 40),
            Position = UDim2.new(1, -85, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            [React.Event.Activated] = onTogglePlay,
        }),

        NextBtn = e("TextButton", {
            Text = ">>",
            Font = Enum.Font.AmaticSC,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 64, -- Ð—Ð½Ð°Ñ‡Ð½Ð¾ Ð·Ð±Ñ–Ð»ÑŒÑˆÐµÐ½Ð¾
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(40, 40),
            Position = UDim2.new(1, -40, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            [React.Event.Activated] = onNext,
        }),

        Audio = currentSong and e("Sound", {
            SoundId = currentSong.AudioId,
            Playing = isPlaying,
            Volume = 0.5,
            [React.Event.Ended] = onNext,
        })
    })
end

return MusicPlayer

