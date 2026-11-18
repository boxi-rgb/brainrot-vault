-- Spawner: keeps the lane populated. Brainrots appear at the spawn gate
-- (Z = -108) and walk to +Z; anything reaching Z > 112 is removed.
-- One Heartbeat connection moves every Lane-state model in the folder.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)
local Config = require(ReplicatedStorage.Shared.Config)
local CharacterFactory = require(script.Parent.CharacterFactory)

local Spawner = {}

local rng = Random.new()
local folder = nil
local spawnsSinceEpic = 0 -- pity counter: the lane never goes too long without a big catch
local PITY_LIMIT = 14

local function laneCount()
	local count = 0
	for _, model in ipairs(folder:GetChildren()) do
		if model:IsA("Model") and model:GetAttribute("State") == "Lane" then
			count += 1
		end
	end
	return count
end

function Spawner.spawnOne()
	local species = BrainrotData.rollSpecies(rng)
	-- Pity rule: after PITY_LIMIT ordinary spawns, keep re-rolling until an
	-- Epic-or-better shows up, so a long Common streak cannot starve the lane.
	if spawnsSinceEpic >= PITY_LIMIT then
		local attempts = 0
		while BrainrotData.rarityIndex(species.rarity) < 3 and attempts < 40 do
			species = BrainrotData.rollSpecies(rng)
			attempts += 1
		end
	end
	if BrainrotData.rarityIndex(species.rarity) >= 3 then
		spawnsSinceEpic = 0
	else
		spawnsSinceEpic += 1
	end
	local mutation = BrainrotData.rollMutation(rng)
	local model = CharacterFactory.build(species, mutation)
	model:PivotTo(CFrame.new(rng:NextNumber(-6, 6), 0, -108))
	model.Parent = folder
	return model
end

-- Deterministic spawn for the reviewer's tour: a named species at a given Z.
function Spawner.spawnSpecific(speciesId, mutationName, zPos)
	local species = BrainrotData.getById(speciesId)
	if not species then
		return nil
	end
	local model = CharacterFactory.build(species, mutationName)
	model:PivotTo(CFrame.new(0, 0, zPos or -40))
	model.Parent = folder
	return model
end

function Spawner.init()
	folder = Workspace:WaitForChild("Brainrots")

	RunService.Heartbeat:Connect(function(dt)
		if not folder then
			return
		end
		for _, model in ipairs(folder:GetChildren()) do
			if model:IsA("Model") and model:GetAttribute("State") == "Lane" then
				local pivot = model:GetPivot()
				if pivot.Position.Z > 112 then
					model:Destroy()
				else
					model:PivotTo(pivot + Vector3.new(0, 0, Config.LaneWalkSpeed * dt))
				end
			end
		end
	end)

	task.spawn(function()
		while true do
			task.wait(Config.LaneSpawnInterval)
			if folder and laneCount() < Config.LaneMaxBrainrots then
				Spawner.spawnOne()
			end
		end
	end)
end

return Spawner
