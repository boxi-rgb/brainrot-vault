-- Shop: three rotating offers per player, rolled from BrainrotData with the
-- same rarity weights as the lane. Buying places the brainrot straight onto
-- a free pad; with no free pad the purchase is refunded and explained.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)
local Config = require(ReplicatedStorage.Shared.Config)
local CharacterFactory = require(script.Parent.CharacterFactory)

local Shop = {}

local rng = Random.new()
local offersByPlayer = {}
local remotes = nil
local economy = nil
local bases = nil

local function rollOffers(player)
	local offers = {}
	for slot = 1, 3 do
		local species = BrainrotData.rollSpecies(rng)
		local mutation = BrainrotData.rollMutation(rng)
		local rate = BrainrotData.rateFor(species, mutation)
		offers[slot] = {
			speciesId = species.id,
			mutation = mutation or "",
			name = BrainrotData.displayName(species, mutation),
			rarity = species.rarity,
			rate = rate,
			price = math.floor(rate * Config.ShopPriceSeconds),
		}
	end
	offersByPlayer[player] = offers
	remotes.ShopOffers:FireClient(player, offers)
	return offers
end

function Shop.init(remotesTable, economyModule, basesModule)
	remotes = remotesTable
	economy = economyModule
	bases = basesModule

	Players.PlayerAdded:Connect(function(player)
		rollOffers(player)
		task.spawn(function()
			while player.Parent do
				task.wait(45)
				rollOffers(player)
			end
		end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		offersByPlayer[player] = nil
	end)

	remotes.BuyRequest.OnServerEvent:Connect(function(player, slot)
		local offers = offersByPlayer[player]
		local offer = offers and offers[tonumber(slot)]
		if not offer then
			return
		end
		local _, padIndex = bases.firstFreePad(player)
		if not padIndex then
			remotes.BannerEvent:FireClient(player, "No free pads! Sell something or Rebirth.")
			return
		end
		if not economy.trySpend(player, offer.price) then
			remotes.BannerEvent:FireClient(player, "Not enough money for " .. offer.name)
			return
		end
		local species = BrainrotData.getById(offer.speciesId)
		local mutation = offer.mutation ~= "" and offer.mutation or nil
		local model = CharacterFactory.build(species, mutation)
		model.Parent = Workspace:WaitForChild("Brainrots")
		if not bases.placeDirect(player, model) then
			model:Destroy()
			economy.addMoney(player, offer.price) -- full refund
			remotes.BannerEvent:FireClient(player, "No free pads! Purchase refunded.")
			return
		end
		remotes.BannerEvent:FireClient(player, "Bought " .. offer.name .. "!")
	end)
end

return Shop
