-- BrainrotData: the cast, the rarity ladder and the mutation table for Brainrot Vault.
-- Shared by the server (spawning, pricing) and the client (shop rows, labels).

local BrainrotData = {}

-- Rarity ladder, lowest first. Weight is the relative chance that a lane spawn
-- lands on this rarity before a species is picked inside it.
BrainrotData.RarityOrder = { "Common", "Rare", "Epic", "Legendary", "Mythic" }

BrainrotData.Rarities = {
	Common = { weight = 55, color = Color3.fromRGB(205, 205, 205) },
	Rare = { weight = 27, color = Color3.fromRGB(80, 170, 255) },
	Epic = { weight = 12, color = Color3.fromRGB(185, 90, 255) },
	Legendary = { weight = 4.5, color = Color3.fromRGB(255, 190, 40) },
	Mythic = { weight = 1.5, color = Color3.fromRGB(255, 70, 90) },
}

-- Mutations: a second roll on every brainrot. Multiplier applies to the earn rate
-- (and therefore to the price, which is derived from the rate).
BrainrotData.Mutations = {
	Gold = { multiplier = 1.5, chance = 0.08, prefix = "Gold " },
	Diamond = { multiplier = 2.5, chance = 0.03, prefix = "Diamond " },
	Rainbow = { multiplier = 4, chance = 0.01, prefix = "Rainbow " },
}

-- The cast. rate is dollars per second on a pad before mutation and rebirth
-- multipliers. body/head are the model's colours; accessory names the little
-- prop CharacterFactory builds for the species; scale grows the whole model.
BrainrotData.Species = {
	{ id = "captain_cucumber", name = "Captain Cucumber", rarity = "Common", rate = 1, body = Color3.fromRGB(70, 180, 80), head = Color3.fromRGB(90, 200, 95), accessory = "cap", scale = 1.0 },
	{ id = "sir_bananas", name = "Sir Bananas McPeel", rarity = "Common", rate = 2, body = Color3.fromRGB(250, 215, 70), head = Color3.fromRGB(255, 230, 110), accessory = "peel", scale = 1.0 },
	{ id = "disco_potato", name = "Disco Potato", rarity = "Common", rate = 3, body = Color3.fromRGB(180, 140, 95), head = Color3.fromRGB(195, 155, 105), accessory = "disco", scale = 1.05 },
	{ id = "cactus_carlito", name = "Cactus Carlito", rarity = "Rare", rate = 5, body = Color3.fromRGB(45, 150, 70), head = Color3.fromRGB(60, 170, 85), accessory = "sombrero", scale = 1.05 },
	{ id = "pigeon_mafioso", name = "Pigeon Mafioso", rarity = "Rare", rate = 7, body = Color3.fromRGB(140, 145, 160), head = Color3.fromRGB(120, 125, 145), accessory = "fedora", scale = 1.0 },
	{ id = "burger_baron", name = "Burger Baron", rarity = "Rare", rate = 10, body = Color3.fromRGB(220, 160, 80), head = Color3.fromRGB(235, 180, 95), accessory = "stack", scale = 1.15 },
	{ id = "nonna_lasagna", name = "Nonna Lasagna", rarity = "Epic", rate = 18, body = Color3.fromRGB(240, 200, 120), head = Color3.fromRGB(245, 215, 150), accessory = "scarf", scale = 1.1 },
	{ id = "dj_fridge", name = "DJ Fridge", rarity = "Epic", rate = 25, body = Color3.fromRGB(225, 230, 235), head = Color3.fromRGB(235, 240, 245), accessory = "headphones", scale = 1.25 },
	{ id = "melon_musketeer", name = "Melon Musketeer", rarity = "Epic", rate = 35, body = Color3.fromRGB(60, 170, 90), head = Color3.fromRGB(250, 120, 130), accessory = "feather", scale = 1.1 },
	{ id = "spaghetti_yeti", name = "Spaghetti Yeti", rarity = "Legendary", rate = 70, body = Color3.fromRGB(240, 240, 245), head = Color3.fromRGB(250, 250, 255), accessory = "noodles", scale = 1.35 },
	{ id = "toaster_ghost", name = "Toaster Ghost", rarity = "Legendary", rate = 95, body = Color3.fromRGB(235, 238, 245), head = Color3.fromRGB(245, 248, 255), accessory = "toast", scale = 1.2 },
	{ id = "king_kumquat", name = "King Kumquat", rarity = "Legendary", rate = 120, body = Color3.fromRGB(250, 150, 40), head = Color3.fromRGB(255, 170, 60), accessory = "crown", scale = 1.3 },
	{ id = "astro_avocado", name = "Astro Avocado", rarity = "Mythic", rate = 300, body = Color3.fromRGB(50, 130, 60), head = Color3.fromRGB(190, 230, 140), accessory = "helmet", scale = 1.3 },
	{ id = "the_goosefather", name = "The Goosefather", rarity = "Mythic", rate = 500, body = Color3.fromRGB(245, 245, 245), head = Color3.fromRGB(250, 250, 250), accessory = "beak", scale = 1.45 },
}

local speciesById = {}
for _, species in ipairs(BrainrotData.Species) do
	speciesById[species.id] = species
end

function BrainrotData.getById(id)
	return speciesById[id]
end

-- Position on the rarity ladder (1 = Common .. 5 = Mythic); used for carry
-- slowdowns and label sorting.
function BrainrotData.rarityIndex(rarity)
	for index, name in ipairs(BrainrotData.RarityOrder) do
		if name == rarity then
			return index
		end
	end
	return 1
end

-- A brainrot costs 120 seconds of its own base earn rate.
function BrainrotData.priceFor(species)
	return species.rate * 120
end

-- Effective earn rate once a mutation is applied.
function BrainrotData.rateFor(species, mutation)
	local info = mutation and BrainrotData.Mutations[mutation]
	if info then
		return species.rate * info.multiplier
	end
	return species.rate
end

function BrainrotData.displayName(species, mutation)
	local info = mutation and BrainrotData.Mutations[mutation]
	if info then
		return info.prefix .. species.name
	end
	return species.name
end

-- Two-stage roll: pick a rarity by weight, then a species inside it uniformly.
function BrainrotData.rollSpecies(rng)
	local total = 0
	for _, name in ipairs(BrainrotData.RarityOrder) do
		total += BrainrotData.Rarities[name].weight
	end
	local roll = rng:NextNumber() * total
	local chosen = "Common"
	for _, name in ipairs(BrainrotData.RarityOrder) do
		roll -= BrainrotData.Rarities[name].weight
		if roll <= 0 then
			chosen = name
			break
		end
	end
	local pool = {}
	for _, species in ipairs(BrainrotData.Species) do
		if species.rarity == chosen then
			table.insert(pool, species)
		end
	end
	return pool[rng:NextInteger(1, #pool)]
end

-- Returns "Gold" / "Diamond" / "Rainbow", or nil for a plain brainrot.
function BrainrotData.rollMutation(rng)
	local roll = rng:NextNumber()
	local cumulative = 0
	-- Rarest first so the small chances are not swallowed by the bigger ones.
	for _, name in ipairs({ "Rainbow", "Diamond", "Gold" }) do
		cumulative += BrainrotData.Mutations[name].chance
		if roll < cumulative then
			return name
		end
	end
	return nil
end

return BrainrotData
