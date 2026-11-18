-- Brainrot Vault HUD.
-- Top centre: money and income. Top right: rebirths and multiplier.
-- Bottom centre: Shop / Lock Vault / Rebirth buttons. Centre-top banner for
-- tsunami warnings and theft notices. The top-left corner stays empty on
-- purpose: Roblox's own menu buttons sit there.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateUpdate = remotes:WaitForChild("StateUpdate")
local shopOffers = remotes:WaitForChild("ShopOffers")
local buyRequest = remotes:WaitForChild("BuyRequest")
local lockRequest = remotes:WaitForChild("LockRequest")
local rebirthRequest = remotes:WaitForChild("RebirthRequest")
local bannerEvent = remotes:WaitForChild("BannerEvent")

local BOLD = Enum.Font.GothamBold
local DARK = Color3.fromRGB(28, 26, 40)
local WHITE = Color3.fromRGB(255, 255, 255)

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHud"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function label(name, parent, size, position, anchor, text, textSize, color)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Size = size
	l.Position = position
	l.AnchorPoint = anchor or Vector2.new(0.5, 0)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextSize = textSize
	l.Font = BOLD
	l.TextColor3 = color or WHITE
	l.TextStrokeTransparency = 0.35
	l.Parent = parent
	return l
end

local function panel(name, parent, size, position, anchor)
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = size
	f.Position = position
	f.AnchorPoint = anchor or Vector2.new(0.5, 0)
	f.BackgroundColor3 = DARK
	f.BackgroundTransparency = 0.25
	f.BorderSizePixel = 0
	f.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = f
	return f
end

-- Money block, top centre.
local moneyPanel = panel("MoneyPanel", gui, UDim2.fromOffset(340, 86), UDim2.new(0.5, 0, 0, 14))
local moneyLabel = label("Money", moneyPanel, UDim2.new(1, 0, 0.6, 0), UDim2.new(0.5, 0, 0, 2), nil, "$50", 36, Color3.fromRGB(140, 255, 150))
local incomeLabel = label("Income", moneyPanel, UDim2.new(1, 0, 0.4, 0), UDim2.new(0.5, 0, 0.6, 0), nil, "$0/s", 22, WHITE)

-- Rebirth block, top right.
local rebirthPanel = panel("RebirthPanel", gui, UDim2.fromOffset(230, 86), UDim2.new(1, -14, 0, 14), Vector2.new(1, 0))
local rebirthLabel = label("Rebirths", rebirthPanel, UDim2.new(1, 0, 0.55, 0), UDim2.new(0.5, 0, 0, 2), nil, "Rebirths: 0", 24, Color3.fromRGB(255, 170, 240))
local multLabel = label("Multiplier", rebirthPanel, UDim2.new(1, 0, 0.45, 0), UDim2.new(0.5, 0, 0.55, 0), nil, "Income x1.00", 20, WHITE)

-- Banner, centre-top: tsunami warnings, theft notices, purchase results.
local banner = label("Banner", gui, UDim2.new(0.8, 0, 0, 56), UDim2.new(0.5, 0, 0, 118), nil, "", 30, Color3.fromRGB(255, 220, 90))
banner.Visible = false
local bannerToken = 0
local function showBanner(text)
	bannerToken += 1
	local token = bannerToken
	banner.Text = text
	banner.Visible = true
	task.delay(4, function()
		if bannerToken == token then
			banner.Visible = false
		end
	end)
end
bannerEvent.OnClientEvent:Connect(showBanner)

-- Carrying indicator, just under the banner.
local carryingLabel = label("Carrying", gui, UDim2.new(0.8, 0, 0, 34), UDim2.new(0.5, 0, 0, 176), nil, "", 22, Color3.fromRGB(150, 225, 255))
carryingLabel.Visible = false

-- Button row, bottom centre.
local buttonRow = Instance.new("Frame")
buttonRow.Name = "Buttons"
buttonRow.Size = UDim2.fromOffset(520, 64)
buttonRow.Position = UDim2.new(0.5, 0, 1, -20)
buttonRow.AnchorPoint = Vector2.new(0.5, 1)
buttonRow.BackgroundTransparency = 1
buttonRow.Parent = gui
local rowLayout = Instance.new("UIListLayout")
rowLayout.FillDirection = Enum.FillDirection.Horizontal
rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
rowLayout.Padding = UDim.new(0, 12)
rowLayout.Parent = buttonRow

local function button(name, text, color)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Size = UDim2.fromOffset(164, 64)
	b.BackgroundColor3 = color
	b.BorderSizePixel = 0
	b.Text = text
	b.TextSize = 22
	b.Font = BOLD
	b.TextColor3 = WHITE
	b.Parent = buttonRow
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = b
	return b
end

local shopButton = button("ShopButton", "SHOP", Color3.fromRGB(45, 150, 80))
local lockButton = button("LockButton", "LOCK VAULT", Color3.fromRGB(50, 110, 190))
local rebirthButton = button("RebirthButton", "REBIRTH", Color3.fromRGB(170, 70, 160))

lockButton.MouseButton1Click:Connect(function()
	lockRequest:FireServer()
end)
rebirthButton.MouseButton1Click:Connect(function()
	rebirthRequest:FireServer()
end)

-- Shop panel, centre: three offer rows with Buy buttons.
local shopPanel = panel("ShopPanel", gui, UDim2.fromOffset(560, 330), UDim2.new(0.5, 0, 0.5, 0), Vector2.new(0.5, 0.5))
shopPanel.Visible = false
label("ShopTitle", shopPanel, UDim2.new(1, 0, 0, 48), UDim2.new(0.5, 0, 0, 6), nil, "BRAINROT SHOP", 28, Color3.fromRGB(140, 255, 170))

local offerRows = {}
for slot = 1, 3 do
	local row = panel("Offer" .. slot, shopPanel, UDim2.new(1, -24, 0, 68), UDim2.new(0.5, 0, 0, 58 + (slot - 1) * 78))
	row.BackgroundTransparency = 0.1
	local info = label("Info", row, UDim2.new(1, -140, 1, 0), UDim2.new(0, 12, 0.5, 0), Vector2.new(0, 0.5), "...", 20, WHITE)
	info.TextXAlignment = Enum.TextXAlignment.Left
	local buy = Instance.new("TextButton")
	buy.Name = "Buy"
	buy.Size = UDim2.fromOffset(120, 48)
	buy.Position = UDim2.new(1, -10, 0.5, 0)
	buy.AnchorPoint = Vector2.new(1, 0.5)
	buy.BackgroundColor3 = Color3.fromRGB(45, 150, 80)
	buy.BorderSizePixel = 0
	buy.Text = "BUY"
	buy.TextSize = 22
	buy.Font = BOLD
	buy.TextColor3 = WHITE
	buy.Parent = row
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = buy
	buy.MouseButton1Click:Connect(function()
		buyRequest:FireServer(slot)
	end)
	offerRows[slot] = { info = info, buy = buy }
end

local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.Size = UDim2.fromOffset(140, 44)
closeButton.Position = UDim2.new(0.5, 0, 1, -12)
closeButton.AnchorPoint = Vector2.new(0.5, 1)
closeButton.BackgroundColor3 = Color3.fromRGB(150, 60, 60)
closeButton.BorderSizePixel = 0
closeButton.Text = "CLOSE"
closeButton.TextSize = 20
closeButton.Font = BOLD
closeButton.TextColor3 = WHITE
closeButton.Parent = shopPanel
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 10)
closeCorner.Parent = closeButton
closeButton.MouseButton1Click:Connect(function()
	shopPanel.Visible = false
end)
shopButton.MouseButton1Click:Connect(function()
	shopPanel.Visible = not shopPanel.Visible
end)

local RARITY_COLORS = {
	Common = Color3.fromRGB(205, 205, 205),
	Rare = Color3.fromRGB(80, 170, 255),
	Epic = Color3.fromRGB(185, 90, 255),
	Legendary = Color3.fromRGB(255, 190, 40),
	Mythic = Color3.fromRGB(255, 70, 90),
}

shopOffers.OnClientEvent:Connect(function(offers)
	for slot, row in ipairs(offerRows) do
		local offer = offers[slot]
		if offer then
			row.info.Text = string.format("%s\n%s · $%g/s", offer.name, offer.rarity:upper(), offer.rate)
			row.info.TextColor3 = RARITY_COLORS[offer.rarity] or WHITE
			row.buy.Text = "$" .. offer.price
		end
	end
end)

stateUpdate.OnClientEvent:Connect(function(state)
	moneyLabel.Text = "$" .. tostring(state.money)
	incomeLabel.Text = string.format("$%g/s", state.income)
	rebirthLabel.Text = "Rebirths: " .. tostring(state.rebirths)
	multLabel.Text = string.format("Income x%.2f", state.multiplier)
	rebirthButton.Text = "REBIRTH $" .. tostring(state.rebirthCost)
	if state.carrying then
		carryingLabel.Text = "Carrying: " .. state.carrying .. " — get it to a pad!"
		carryingLabel.Visible = true
	else
		carryingLabel.Visible = false
	end
end)
