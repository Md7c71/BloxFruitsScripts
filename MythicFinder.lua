-- Mythic Fruits Server Finder for Blox Fruits
-- By: yourname

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local mythicFruits = {
    "Dragon",
    "Leopard",
    "Mammoth",
    "Dough",
    "Venom",
    "Shadow",
    "Control",
    "Spirit",
    "Kitsune",
    "T-Rex",
    "Gravity",
    "Gas",
    "Yeti",
    "East Dragon",
    "West Dragon",
}

-- إنشاء واجهة المستخدم
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = player.PlayerGui
ScreenGui.Name = "MythicFinderUI"

local Frame = Instance.new("Frame")
Frame.Parent = ScreenGui
Frame.Size = UDim2.new(0, 350, 0, 250)
Frame.Position = UDim2.new(0.5, -175, 0.5, -125)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel")
Title.Parent = Frame
Title.Text = "Mythic Fruits Finder"
Title.Size = UDim2.new(1, 0, 0, 40)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18

local SearchButton = Instance.new("TextButton")
SearchButton.Parent = Frame
SearchButton.Text = "Search Server"
SearchButton.Size = UDim2.new(0.8, 0, 0, 50)
SearchButton.Position = UDim2.new(0.1, 0, 0.3, 0)
SearchButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
SearchButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchButton.Font = Enum.Font.GothamBold
SearchButton.TextSize = 16

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Parent = Frame
StatusLabel.Text = "Ready to search"
StatusLabel.Size = UDim2.new(1, 0, 0, 40)
StatusLabel.Position = UDim2.new(0, 0, 0.7, 0)
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 14

local CloseButton = Instance.new("TextButton")
CloseButton.Parent = Frame
CloseButton.Text = "X"
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -30, 0, 0)
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.GothamBold

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

local function findServerWithMythicFruit()
    StatusLabel.Text = "Searching for servers..."
    
    local placeId = game.PlaceId
    local jobIds = TeleportService:GetGameInstances(placeId)
    
    if not jobIds or #jobIds == 0 then
        StatusLabel.Text = "No available servers"
        return nil
    end
    
    for _, jobId in ipairs(jobIds) do
        local success, serverData = pcall(function()
            return HttpService:JSONDecode(HttpService:GetAsync(
                "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?limit=100&cursor="..(jobId.cursor or "")
            ))
        end)
        
        if success and serverData.data then
            for _, server in ipairs(serverData.data) do
                if server.playing and server.playing > 0 then
                    local serverInfo = TeleportService:GetServerInfo(server.id)
                    if serverInfo and serverInfo.Players then
                        for _, plr in ipairs(serverInfo.Players) do
                            if plr.Character then
                                for _, fruitName in ipairs(mythicFruits) do
                                    if string.find(plr.Character.Name, fruitName) or 
                                       (plr.Backpack and plr.Backpack:FindFirstChild(fruitName)) then
                                        StatusLabel.Text = "Found server with "..fruitName
                                        return server.id
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    StatusLabel.Text = "No mythic fruits found"
    return nil
end

local function teleportToMythicServer()
    local mythicServer = findServerWithMythicFruit()
    
    if mythicServer then
        StatusLabel.Text = "Teleporting..."
        TeleportService:TeleportToPlaceInstance(game.PlaceId, mythicServer, player)
    else
        StatusLabel.Text = "Joining random server"
        TeleportService:TeleportToPlaceInstance(game.PlaceId, jobIds[math.random(1, #jobIds)].id, player)
    end
end

SearchButton.MouseButton1Click:Connect(teleportToMythicServer)

return {
    Init = teleportToMythicServer
}
