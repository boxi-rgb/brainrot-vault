-- CharacterFactory: builds a brainrot Model out of plain Parts.
-- Body is the PrimaryPart; Head sits on top with the name BillboardGui.
-- Every species gets its signature accessory from a small builder below.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)

local CharacterFactory = {}

local GOLD = Color3.fromRGB(255, 200, 40)
local DIAMOND = Color3.fromRGB(150, 225, 255)

local function basePart(name, size, color, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.CanCollide = false
	part.Massless = true
	part.Anchored = false
	if shape then
		part.Shape = shape
	end
	return part
end

-- Adds a part to the model, positioned relative to the model origin and
-- welded to the anchor so the model moves as one piece.
local function attach(model, anchor, part, offset)
	part.CFrame = offset
	part.Parent = model
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = anchor
	weld.Part1 = part
	weld.Parent = part
	return part
end

-- Accessory builders. Each receives the model, its Body/Head and the scale,
-- and bolts one small prop on. Coordinates are in model space (origin at the
-- ground under the Body, +Z is the way the brainrot faces and walks).
local accessories = {}

function accessories.cap(model, body, head, s)
	attach(model, head, basePart("CapBrim", Vector3.new(1.5, 0.15, 0.9) * s, Color3.fromRGB(40, 90, 200)), CFrame.new(0, 3.35 * s, 0.55 * s))
	attach(model, head, basePart("CapTop", Vector3.new(1.4, 0.5, 1.4) * s, Color3.fromRGB(40, 90, 200), Enum.PartType.Ball), CFrame.new(0, 3.55 * s, 0))
end

function accessories.peel(model, body, head, s)
	for i = 1, 3 do
		local angle = (i - 2) * 0.7
		local peel = basePart("Peel" .. i, Vector3.new(0.35, 1.1, 0.7) * s, Color3.fromRGB(240, 200, 50))
		attach(model, body, peel, CFrame.new(math.sin(angle) * 0.8 * s, 0.7 * s, -math.cos(angle) * 0.6 * s) * CFrame.Angles(0.5, angle, 0))
	end
end

function accessories.disco(model, body, head, s)
	local ball = basePart("DiscoBall", Vector3.new(1.1, 1.1, 1.1) * s, Color3.fromRGB(200, 200, 220), Enum.PartType.Ball)
	ball.Material = Enum.Material.Metal
	attach(model, head, ball, CFrame.new(0, 4.6 * s, 0))
end

function accessories.sombrero(model, body, head, s)
	local brim = basePart("SombreroBrim", Vector3.new(2.6, 0.18, 2.6) * s, Color3.fromRGB(230, 190, 90), Enum.PartType.Cylinder)
	attach(model, head, brim, CFrame.new(0, 3.6 * s, 0))
	local top = basePart("SombreroTop", Vector3.new(1.2, 0.7, 1.2) * s, Color3.fromRGB(210, 160, 60), Enum.PartType.Cylinder)
	attach(model, head, top, CFrame.new(0, 3.95 * s, 0))
end

function accessories.fedora(model, body, head, s)
	local brim = basePart("FedoraBrim", Vector3.new(1.9, 0.14, 1.9) * s, Color3.fromRGB(35, 35, 40), Enum.PartType.Cylinder)
	attach(model, head, brim, CFrame.new(0, 3.55 * s, 0))
	local top = basePart("FedoraTop", Vector3.new(1.15, 0.6, 1.15) * s, Color3.fromRGB(45, 45, 52), Enum.PartType.Cylinder)
	attach(model, head, top, CFrame.new(0, 3.85 * s, 0))
end

function accessories.stack(model, body, head, s)
	-- A burger worn as a hat: bun, lettuce, patty, bun.
	attach(model, head, basePart("BunBottom", Vector3.new(1.5, 0.3, 1.5) * s, Color3.fromRGB(235, 185, 105), Enum.PartType.Cylinder), CFrame.new(0, 3.5 * s, 0))
	attach(model, head, basePart("Lettuce", Vector3.new(1.65, 0.16, 1.65) * s, Color3.fromRGB(110, 200, 90), Enum.PartType.Cylinder), CFrame.new(0, 3.72 * s, 0))
	attach(model, head, basePart("Patty", Vector3.new(1.45, 0.28, 1.45) * s, Color3.fromRGB(120, 75, 45), Enum.PartType.Cylinder), CFrame.new(0, 3.92 * s, 0))
	attach(model, head, basePart("BunTop", Vector3.new(1.5, 0.45, 1.5) * s, Color3.fromRGB(240, 195, 115), Enum.PartType.Ball), CFrame.new(0, 4.2 * s, 0))
end

function accessories.scarf(model, body, head, s)
	local scarf = basePart("Scarf", Vector3.new(1.7, 0.45, 1.7) * s, Color3.fromRGB(200, 50, 60), Enum.PartType.Cylinder)
	attach(model, head, scarf, CFrame.new(0, 2.75 * s, 0))
	attach(model, body, basePart("ScarfTail", Vector3.new(0.5, 1.0, 0.18) * s, Color3.fromRGB(200, 50, 60)), CFrame.new(0.5 * s, 2.1 * s, -0.8 * s))
end

function accessories.headphones(model, body, head, s)
	attach(model, head, basePart("CupL", Vector3.new(0.35, 0.8, 0.8) * s, Color3.fromRGB(30, 30, 35), Enum.PartType.Cylinder), CFrame.new(-0.85 * s, 3.1 * s, 0) * CFrame.Angles(0, 0, math.rad(90)))
	attach(model, head, basePart("CupR", Vector3.new(0.35, 0.8, 0.8) * s, Color3.fromRGB(30, 30, 35), Enum.PartType.Cylinder), CFrame.new(0.85 * s, 3.1 * s, 0) * CFrame.Angles(0, 0, math.rad(90)))
	attach(model, head, basePart("Band", Vector3.new(1.8, 0.22, 0.3) * s, Color3.fromRGB(30, 30, 35)), CFrame.new(0, 3.85 * s, 0))
end

function accessories.feather(model, body, head, s)
	local feather = basePart("Feather", Vector3.new(0.28, 1.5, 0.6) * s, Color3.fromRGB(255, 90, 140))
	attach(model, head, feather, CFrame.new(0.45 * s, 4.1 * s, -0.2 * s) * CFrame.Angles(math.rad(-18), 0, math.rad(-14)))
	attach(model, head, basePart("Beret", Vector3.new(1.5, 0.3, 1.5) * s, Color3.fromRGB(60, 60, 130), Enum.PartType.Cylinder), CFrame.new(0, 3.6 * s, 0))
end

function accessories.noodles(model, body, head, s)
	for i = 1, 4 do
		local x = (i - 2.5) * 0.35
		local strand = basePart("Noodle" .. i, Vector3.new(0.22, 1.3, 0.22) * s, Color3.fromRGB(250, 220, 130), Enum.PartType.Cylinder)
		attach(model, head, strand, CFrame.new(x * s, 3.0 * s, 0.55 * s) * CFrame.Angles(math.rad(12), 0, 0))
	end
	attach(model, head, basePart("Bowl", Vector3.new(1.7, 0.5, 1.7) * s, Color3.fromRGB(200, 60, 60), Enum.PartType.Cylinder), CFrame.new(0, 3.75 * s, 0))
end

function accessories.toast(model, body, head, s)
	local toast = basePart("Toast", Vector3.new(1.3, 1.3, 0.25) * s, Color3.fromRGB(225, 170, 100))
	attach(model, head, toast, CFrame.new(0.9 * s, 3.6 * s, 0.3 * s) * CFrame.Angles(0, 0, math.rad(-20)))
end

function accessories.crown(model, body, head, s)
	local crown = basePart("Crown", Vector3.new(1.4, 0.6, 1.4) * s, GOLD, Enum.PartType.Cylinder)
	crown.Material = Enum.Material.Metal
	attach(model, head, crown, CFrame.new(0, 3.85 * s, 0))
	for i = 1, 4 do
		local angle = i * math.pi / 2
		local spike = basePart("CrownSpike" .. i, Vector3.new(0.3, 0.55, 0.3) * s, GOLD)
		spike.Material = Enum.Material.Metal
		attach(model, head, spike, CFrame.new(math.sin(angle) * 0.55 * s, 4.25 * s, math.cos(angle) * 0.55 * s))
	end
end

function accessories.helmet(model, body, head, s)
	local helmet = basePart("Helmet", Vector3.new(1.9, 1.9, 1.9) * s, Color3.fromRGB(200, 230, 255), Enum.PartType.Ball)
	helmet.Transparency = 0.45
	helmet.Material = Enum.Material.Glass
	attach(model, head, helmet, CFrame.new(0, 3.1 * s, 0))
end

function accessories.beak(model, body, head, s)
	local beak = basePart("Beak", Vector3.new(0.7, 0.45, 1.1) * s, Color3.fromRGB(250, 160, 30))
	attach(model, head, beak, CFrame.new(0, 2.95 * s, 0.95 * s))
	attach(model, head, basePart("SuitTie", Vector3.new(0.35, 1.0, 0.15) * s, Color3.fromRGB(30, 30, 35)), CFrame.new(0, 1.9 * s, 0.75 * s))
end

local function buildLabel(head, species, mutation)
	local rarity = BrainrotData.Rarities[species.rarity]
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(220, 64)
	gui.StudsOffset = Vector3.new(0, 1.6, 0)
	gui.AlwaysOnTop = true
	gui.Parent = head

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.55, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = BrainrotData.displayName(species, mutation)
	nameLabel.TextColor3 = rarity.color
	nameLabel.TextSize = 22
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextStrokeTransparency = 0.4
	nameLabel.Parent = gui

	local infoLabel = Instance.new("TextLabel")
	infoLabel.Name = "InfoLabel"
	infoLabel.Position = UDim2.new(0, 0, 0.55, 0)
	infoLabel.Size = UDim2.new(1, 0, 0.45, 0)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Text = string.format("%s · $%g/s", species.rarity:upper(), BrainrotData.rateFor(species, mutation))
	infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	infoLabel.TextSize = 18
	infoLabel.Font = Enum.Font.GothamBold
	infoLabel.TextStrokeTransparency = 0.4
	infoLabel.Parent = gui
end

function CharacterFactory.build(species, mutation)
	local s = species.scale
	local model = Instance.new("Model")
	model.Name = BrainrotData.displayName(species, mutation)

	local bodyColor = species.body
	local headColor = species.head
	if mutation == "Gold" then
		bodyColor = GOLD
		headColor = GOLD
	elseif mutation == "Diamond" then
		bodyColor = DIAMOND
		headColor = DIAMOND
	end

	local body = basePart("Body", Vector3.new(2, 2.4, 1.4) * s, bodyColor)
	body.CFrame = CFrame.new(0, 1.5 * s, 0)
	body.Parent = model
	model.PrimaryPart = body

	local head = basePart("Head", Vector3.new(1.5, 1.5, 1.5) * s, headColor, Enum.PartType.Ball)
	head.CFrame = CFrame.new(0, 3.1 * s, 0)
	head.Parent = model
	local headWeld = Instance.new("WeldConstraint")
	headWeld.Part0 = body
	headWeld.Part1 = head
	headWeld.Parent = head

	-- Two eyes on the face (+Z side).
	for _, side in ipairs({ -1, 1 }) do
		local eye = basePart("Eye", Vector3.new(0.28, 0.38, 0.12) * s, Color3.fromRGB(20, 20, 25), Enum.PartType.Ball)
		attach(model, head, eye, CFrame.new(side * 0.35 * s, 3.25 * s, 0.68 * s))
	end

	local builder = accessories[species.accessory]
	if builder then
		builder(model, body, head, s)
	end

	if mutation == "Gold" then
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "Eye" then
				part.Material = Enum.Material.Metal
			end
		end
	elseif mutation == "Diamond" then
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "Eye" then
				part.Transparency = math.max(part.Transparency, 0.2)
				part.Material = Enum.Material.Glass
			end
		end
	end

	-- Rare catches should read from across the map: Legendary and Mythic
	-- brainrots, and anything mutated, glow in their rarity colour.
	local rarityIdx = BrainrotData.rarityIndex(species.rarity)
	if rarityIdx >= 4 or mutation then
		local glow = Instance.new("PointLight")
		glow.Name = "RarityGlow"
		glow.Color = BrainrotData.Rarities[species.rarity].color
		glow.Brightness = mutation and 2.5 or 1.8
		glow.Range = 10 + rarityIdx * 2
		glow.Parent = body
		local sparkles = Instance.new("Sparkles")
		sparkles.Name = "RaritySparkles"
		sparkles.SparkleColor = BrainrotData.Rarities[species.rarity].color
		sparkles.Parent = body
	end

	buildLabel(head, species, mutation)

	model:SetAttribute("SpeciesId", species.id)
	model:SetAttribute("Mutation", mutation or "")
	model:SetAttribute("Rate", BrainrotData.rateFor(species, mutation))
	model:SetAttribute("Price", BrainrotData.priceFor(species) * (BrainrotData.rateFor(species, mutation) / species.rate))
	model:SetAttribute("State", "Lane")

	if mutation == "Rainbow" then
		task.spawn(function()
			local hue = math.random()
			while model.Parent do
				hue = (hue + 0.01) % 1
				local color = Color3.fromHSV(hue, 0.65, 1)
				body.Color = color
				head.Color = color
				task.wait(0.08)
			end
		end)
	end

	return model
end

return CharacterFactory
