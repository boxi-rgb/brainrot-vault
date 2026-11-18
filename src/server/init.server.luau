-- Brainrot Vault server bootstrap.
-- Creates the remotes and the Brainrots folder, builds the world dressing,
-- starts every system, and wires player join / leave.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)
local CharacterFactory = require(script.CharacterFactory)
local WorldBuilder = require(script.WorldBuilder)
local Economy = require(script.Economy)
local Bases = require(script.Bases)
local Spawner = require(script.Spawner)
local Shop = require(script.Shop)
local Wave = require(script.Wave)
local Tour = require(script.Tour)

-- Remotes (created here so the client can WaitForChild them under one folder).
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
for _, name in ipairs({ "StateUpdate", "ShopOffers", "BuyRequest", "LockRequest", "RebirthRequest", "BannerEvent" }) do
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = remotes
end
remotes.Parent = ReplicatedStorage

-- Every brainrot model lives in this folder, whatever state it is in.
local brainrots = Instance.new("Folder")
brainrots.Name = "Brainrots"
brainrots.Parent = Workspace

local bases = WorldBuilder.build()

Economy.init(remotes)
Bases.init(bases, remotes, Economy)
Spawner.init()
Shop.init(remotes, Economy, Bases)
Wave.init(remotes, Bases)
Tour.init({
	Economy = Economy,
	Spawner = Spawner,
	Bases = Bases,
	Wave = Wave,
	CharacterFactory = CharacterFactory,
	BrainrotData = BrainrotData,
})

local function onPlayerAdded(player)
	Economy.createData(player)
	local base = Bases.assignBase(player)
	player.CharacterAdded:Connect(function(character)
		local root = character:WaitForChild("HumanoidRootPart")
		if base then
			task.wait(0.1)
			root.CFrame = base.spawnCFrame
		end
	end)
	if player.Character then
		local root = player.Character:FindFirstChild("HumanoidRootPart")
		if root and base then
			root.CFrame = base.spawnCFrame
		end
	end
	Economy.pushState(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	Bases.releaseBase(player)
	Economy.removeData(player)
end)

-- HUD buttons that are not owned by a single system.
remotes.LockRequest.OnServerEvent:Connect(function(player)
	Bases.tryLock(player)
end)

remotes.RebirthRequest.OnServerEvent:Connect(function(player)
	local data = Economy.getData(player)
	if not data then
		return
	end
	local cost = Economy.rebirthCost(player)
	if Economy.trySpend(player, cost) then
		data.Rebirths += 1
		Bases.recomputeIncome(player)
		remotes.BannerEvent:FireClient(player, "REBIRTH! Income x" .. string.format("%.2f", Economy.incomeMultiplier(player)))
		Economy.pushState(player)
	else
		remotes.BannerEvent:FireClient(player, "Rebirth costs $" .. cost)
	end
end)

print("Brainrot Vault server started")
