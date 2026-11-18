-- Tour: staging helpers the reviewer's TOUR.json calls between screenshots.
-- stagePlay makes the game look lived-in; stageWave fires the tsunami.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Tour = {}

local economy = nil
local spawner = nil
local bases = nil
local wave = nil
local characterFactory = nil
local brainrotData = nil

function Tour.init(deps)
	economy = deps.Economy
	spawner = deps.Spawner
	bases = deps.Bases
	wave = deps.Wave
	characterFactory = deps.CharacterFactory
	brainrotData = deps.BrainrotData
end

local function firstPlayer()
	local players = Players:GetPlayers()
	return players[1]
end

function Tour.stagePlay()
	local player = firstPlayer()
	if not player then
		return
	end
	-- A grand to spend, a Legendary strolling past the spawn gate, and a
	-- Rare already earning on the player's first pad.
	economy.addMoney(player, 1000)
	spawner.spawnSpecific("king_kumquat", nil, -30)
	local species = brainrotData.getById("pigeon_mafioso")
	if species then
		local model = characterFactory.build(species, nil)
		model.Parent = Workspace:WaitForChild("Brainrots")
		bases.placeDirect(player, model)
	end
end

function Tour.stageWave()
	wave.triggerNow()
end

return Tour
