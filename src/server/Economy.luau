-- Economy: the single owner of per-player money data.
-- Money, Rebirths and IncomePerSec live here and nowhere else; other modules
-- ask through getData / addMoney / trySpend / setIncome. A 1-second tick pays
-- out IncomePerSec and pushes a StateUpdate to the player's HUD.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Economy = {}

local dataByPlayer = {}
local stateUpdate = nil
local carryingProvider = nil -- set by Bases: (player) -> brainrot name or nil

function Economy.init(remotes)
	stateUpdate = remotes.StateUpdate
	task.spawn(function()
		while true do
			task.wait(1)
			for player, data in pairs(dataByPlayer) do
				if data.IncomePerSec > 0 then
					data.Money += data.IncomePerSec
				end
				Economy.pushState(player)
			end
		end
	end)
end

function Economy.setCarryingProvider(fn)
	carryingProvider = fn
end

function Economy.createData(player)
	local data = {
		Money = Config.StartingMoney,
		Rebirths = 0,
		IncomePerSec = 0,
	}
	dataByPlayer[player] = data
	return data
end

function Economy.removeData(player)
	dataByPlayer[player] = nil
end

function Economy.getData(player)
	return dataByPlayer[player]
end

function Economy.addMoney(player, amount)
	local data = dataByPlayer[player]
	if data then
		data.Money += amount
		Economy.pushState(player)
	end
end

function Economy.trySpend(player, amount)
	local data = dataByPlayer[player]
	if not data or data.Money < amount then
		return false
	end
	data.Money -= amount
	Economy.pushState(player)
	return true
end

function Economy.setIncome(player, incomePerSec)
	local data = dataByPlayer[player]
	if data then
		data.IncomePerSec = incomePerSec
		Economy.pushState(player)
	end
end

-- Cost of the player's next rebirth: base cost, growing geometrically.
function Economy.rebirthCost(player)
	local data = dataByPlayer[player]
	local rebirths = data and data.Rebirths or 0
	return math.floor(Config.RebirthBaseCost * (Config.RebirthCostGrowth ^ rebirths))
end

-- Income multiplier from rebirths, shown in the HUD.
function Economy.incomeMultiplier(player)
	local data = dataByPlayer[player]
	local rebirths = data and data.Rebirths or 0
	return (1 + Config.RebirthIncomeBonus) ^ rebirths
end

function Economy.pushState(player)
	local data = dataByPlayer[player]
	if not data or not stateUpdate then
		return
	end
	local carrying = nil
	if carryingProvider then
		carrying = carryingProvider(player)
	end
	stateUpdate:FireClient(player, {
		money = math.floor(data.Money),
		income = data.IncomePerSec,
		rebirths = data.Rebirths,
		multiplier = Economy.incomeMultiplier(player),
		rebirthCost = Economy.rebirthCost(player),
		carrying = carrying,
	})
end

-- Keep data tidy if a player slips out without init.server noticing.
Players.PlayerRemoving:Connect(function(player)
	dataByPlayer[player] = nil
end)

return Economy
