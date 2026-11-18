-- Config: every tuning number for Brainrot Vault in one place.

return {
	-- The lane
	LaneSpawnInterval = 4, -- seconds between lane spawns
	LaneMaxBrainrots = 8, -- most brainrots walking the lane at once
	LaneWalkSpeed = 6, -- studs per second down the lane

	-- Bases and pads
	BaseCount = 8,
	PadsStart = 6, -- pads a fresh player can use
	PadsMax = 10, -- pads once fully rebirthed
	PadsPerRebirth = 2, -- extra usable pads per rebirth

	-- Vault lock
	LockSeconds = 30, -- how long a lock holds
	LockCooldown = 45, -- seconds before the vault can be locked again

	-- The tsunami
	WaveInterval = 120, -- seconds between waves
	WaveWarning = 10, -- seconds of warning before a wave hits
	WaveSweepSeconds = 6, -- how long the wave takes to cross the map

	-- Rebirth
	RebirthBaseCost = 25000, -- cost of the first rebirth
	RebirthCostGrowth = 3, -- each rebirth costs this many times the last
	RebirthIncomeBonus = 0.5, -- +50% income per rebirth, multiplicative stack

	-- Money
	SellRefund = 0.4, -- fraction of price paid back when a placed brainrot is sold
	ShopPriceSeconds = 120, -- shop price = rate * this many seconds
	StartingMoney = 50,
}
