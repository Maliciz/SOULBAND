local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local CharacterCreator = require(script.Parent.CharacterCreator)

return {
    summary = "Character Creation Menu",
    story = function(props)
        return React.createElement(CharacterCreator, {
            onFinish = function(name, gender, hairId, color)
                print("Finished Creation!", name, gender, hairId, color)
            end,
            onPreviewChange = function(gender, hairId, color)
                print("Previewing:", gender, hairId, color)
            end,
        })
    end,
}
