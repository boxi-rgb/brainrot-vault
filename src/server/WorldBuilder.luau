-- WorldBuilder: dresses the static plots from default.project.json.
-- For each of the 8 BasePlots it builds the pads, the lock dome, the lock pad
-- and the shop / rebirth boards, and returns one record per base.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local WorldBuilder = {}

-- Must match the Base1..Base8 positions in default.project.json.
local PLOT_POSITIONS = {
	Vector3.new(-58, 0.5, -84),
	Vector3.new(58, 0.5, -84),
	Vector3.new(-58, 0.5, -28),
	Vector3.new(58, 0.5, -28),
	Vector3.new(-58, 0.5, 28),
	Vector3.new(58, 0.5, 28),
	Vector3.new(-58, 0.5, 84),
	Vector3.new(58, 0.5, 84),
}

local OWNER_COLORS = {
	Color3.fromRGB(255, 120, 120),
	Color3.fromRGB(120, 180, 255),
	Color3.fromRGB(130, 230, 140),
	Color3.fromRGB(255, 200, 110),
	Color3.fromRGB(200, 150, 255),
	Color3.fromRGB(255, 150, 210),
	Color3.fromRGB(120, 230, 220),
	Color3.fromRGB(250, 250, 160),
}

local function part(name, size, color, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Anchored = true
	p.Locked = true
	p.Parent = parent
	return p
end

local function board(name, title, color, position, parent)
	local boardPart = part(name, Vector3.new(11, 6, 0.5), Color3.fromRGB(35, 32, 48), parent)
	boardPart.Position = position
	local gui = Instance.new("BillboardGui")
	gui.Name = "BoardGui"
	gui.Size = UDim2.fromOffset(300, 90)
	gui.StudsOffset = Vector3.new(0, 0.5, 0)
	gui.AlwaysOnTop = true
	gui.Parent = boardPart
	local label = Instance.new("TextLabel")
	label.Name = "Title"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(35, 32, 48)
	label.Text = title
	label.TextColor3 = color
	label.TextSize = 34
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
	return boardPart
end

local function laneSign(zPos)
	local world = Workspace:WaitForChild("World")
	local sign = part("LaneSign", Vector3.new(20, 4, 0.5), Color3.fromRGB(40, 35, 60), world)
	sign.Position = Vector3.new(0, 17.5, zPos)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "SignGui"
	gui.Face = Enum.NormalId.Front
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "BRAINROT LANE"
	label.TextColor3 = Color3.fromRGB(255, 230, 120)
	label.TextSize = 60
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
	-- A matching sign facing the other way.
	local back = sign:Clone()
	back.Name = "LaneSignBack"
	back.Position = Vector3.new(0, 17.5, zPos)
	back.CFrame = CFrame.new(back.Position) * CFrame.Angles(0, math.pi, 0)
	back.Parent = world
end

function WorldBuilder.build()
	local world = Workspace:WaitForChild("World")
	local plots = world:WaitForChild("BasePlots")

	laneSign(-115)
	laneSign(115)

	local bases = {}
	for index = 1, Config.BaseCount do
		local plot = plots:WaitForChild("Base" .. index)
		local center = PLOT_POSITIONS[index]
		local color = OWNER_COLORS[index]
		local towardLane = -math.sign(center.X) -- +1 for left plots, -1 for right

		-- Pads: two rows of five flat cylinders on the plot.
		local pads = {}
		for padIndex = 1, Config.PadsMax do
			local col = (padIndex - 1) % 5
			local row = math.floor((padIndex - 1) / 5)
			local pad = part("Pad" .. padIndex, Vector3.new(4.4, 0.5, 4.4), Color3.fromRGB(90, 90, 100), plot)
			pad.Shape = Enum.PartType.Cylinder
			pad.CFrame = CFrame.new(center.X + (col - 2) * 7, 1.25, center.Z + (row == 0 and -8 or 8))
				* CFrame.Angles(0, 0, math.rad(90))
			pad:SetAttribute("PadIndex", padIndex)
			table.insert(pads, pad)
		end

		-- Lock dome: a big translucent sphere over the whole plot, hidden
		-- until the owner locks the vault.
		local dome = part("LockDome", Vector3.new(46, 30, 46), Color3.fromRGB(110, 220, 255), plot)
		dome.Shape = Enum.PartType.Ball
		dome.Position = Vector3.new(center.X, 6, center.Z)
		dome.Transparency = 0.65
		dome.CanCollide = false
		dome.Visible = false

		-- Lock pad on the lane side of the plot.
		local lockPad = part("LockPad", Vector3.new(5, 0.7, 5), Color3.fromRGB(255, 215, 70), plot)
		lockPad.Position = Vector3.new(center.X + towardLane * 17, 1.35, center.Z)

		-- Info boards on the far edge of the plot.
		local shopBoard = board("ShopBoard", "SHOP", Color3.fromRGB(120, 255, 170),
			Vector3.new(center.X - towardLane * 17, 4.5, center.Z - 12), plot)
		local rebirthBoard = board("RebirthBoard", "REBIRTH", Color3.fromRGB(255, 170, 240),
			Vector3.new(center.X - towardLane * 17, 4.5, center.Z + 12), plot)

		table.insert(bases, {
			index = index,
			plot = plot,
			center = center,
			color = color,
			pads = pads,
			doorDome = dome,
			lockPad = lockPad,
			shopBoard = shopBoard,
			rebirthBoard = rebirthBoard,
			spawnCFrame = CFrame.new(center.X + towardLane * 12, 4, center.Z)
				* CFrame.Angles(0, towardLane > 0 and math.rad(-90) or math.rad(90), 0),
			owner = nil,
			lockedUntil = 0,
			lockReadyAt = 0,
		})
	end
	return bases
end

return WorldBuilder
