-- Bases: base assignment, pads, catching and carrying, placing, selling,
-- stealing and vault locks.
--
-- A brainrot model is always in one of three states (its State attribute):
--   "Lane"   walking the lane, prompt says Catch
--   "Carried" riding on a player's head, following them every Heartbeat
--   "Placed" standing on a pad in somebody's vault, earning money
-- Placed models carry a prompt too: the owner triggers it to Sell, anyone
-- else triggers it to Steal! (one prompt serves both; the handler decides).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)
local Config = require(ReplicatedStorage.Shared.Config)

local Bases = {}

local bases = nil
local remotes = nil
local economy = nil

local baseByPlayer = {} -- player -> base record
local carrying = {} -- player -> { model, origin = { kind = "Lane" } | { kind = "Stolen", base, padIndex } }
local occupants = {} -- base record -> { [padIndex] = model }

local function banner(player, text)
	if remotes and remotes.BannerEvent then
		remotes.BannerEvent:FireClient(player, text)
	end
end

function Bases.isLocked(base)
	return os.clock() < (base.lockedUntil or 0)
end

function Bases.usablePads(player)
	local data = economy.getData(player)
	local rebirths = data and data.Rebirths or 0
	return math.min(Config.PadsMax, Config.PadsStart + Config.PadsPerRebirth * rebirths)
end

local function recomputeIncome(player)
	local base = baseByPlayer[player]
	local total = 0
	if base then
		for _, model in pairs(occupants[base]) do
			if model and model.Parent then
				total += model:GetAttribute("Rate") or 0
			end
		end
	end
	economy.setIncome(player, total * economy.incomeMultiplier(player))
end
Bases.recomputeIncome = recomputeIncome

local function setPromptForState(model)
	local prompt = model:FindFirstChild("ActionPrompt", true)
	if not prompt then
		return
	end
	local state = model:GetAttribute("State")
	if state == "Lane" then
		prompt.ActionText = "Catch"
		prompt.ObjectText = model.Name
		prompt.Enabled = true
	elseif state == "Placed" then
		prompt.ActionText = "Steal!"
		prompt.ObjectText = model.Name
		prompt.Enabled = true
	else
		prompt.Enabled = false
	end
end

local function placeOnPad(base, padIndex, model)
	local pad = base.pads[padIndex]
	occupants[base][padIndex] = model
	model:SetAttribute("State", "Placed")
	model:SetAttribute("OwnerUserId", base.owner and base.owner.UserId or 0)
	model:SetAttribute("PadIndex", padIndex)
	model:PivotTo(CFrame.new(pad.Position + Vector3.new(0, 0.25, 0)))
	setPromptForState(model)
	if base.owner then
		recomputeIncome(base.owner)
	end
end

local function freePad(base, padIndex)
	occupants[base][padIndex] = nil
end

function Bases.firstFreePad(player)
	local base = baseByPlayer[player]
	if not base then
		return nil, nil
	end
	local usable = Bases.usablePads(player)
	for padIndex = 1, usable do
		if not occupants[base][padIndex] then
			return base, padIndex
		end
	end
	return base, nil
end

-- Places a freshly bought / staged model straight onto a free pad.
function Bases.placeDirect(player, model)
	local base, padIndex = Bases.firstFreePad(player)
	if not padIndex then
		return false
	end
	placeOnPad(base, padIndex, model)
	return true
end

local function resetWalkSpeed(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16
	end
end

local function startCarry(player, model, origin)
	local species = BrainrotData.getById(model:GetAttribute("SpeciesId"))
	local rarityIdx = species and BrainrotData.rarityIndex(species.rarity) or 1
	model:SetAttribute("State", "Carried")
	model:SetAttribute("CarrierUserId", player.UserId)
	carrying[player] = { model = model, origin = origin }
	setPromptForState(model)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Heavier rarities slow the carrier down: Mythic halves your pace.
		humanoid.WalkSpeed = math.max(8, 16 - (rarityIdx - 1) * 2)
	end
	economy.pushState(player)
end

-- Returns whatever the player is carrying to where it came from: stolen
-- goods go back to the victim's pad, lane catches go back to the lane.
local function returnCarried(player)
	local entry = carrying[player]
	if not entry then
		return
	end
	carrying[player] = nil
	resetWalkSpeed(player)
	local model = entry.model
	if not (model and model.Parent) then
		return
	end
	model:SetAttribute("CarrierUserId", 0)
	if entry.origin.kind == "Stolen" then
		local base = entry.origin.base
		if base.owner and not occupants[base][entry.origin.padIndex] then
			placeOnPad(base, entry.origin.padIndex, model)
		else
			model:Destroy()
		end
	else
		model:SetAttribute("State", "Lane")
		model:SetAttribute("OwnerUserId", 0)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local z = root and math.clamp(root.Position.Z, -100, 100) or 0
		model:PivotTo(CFrame.new(0, 0, z))
		setPromptForState(model)
	end
	economy.pushState(player)
end

-- Called by Wave when a model is washed away while carried or placed.
function Bases.onModelGone(model)
	for player, entry in pairs(carrying) do
		if entry.model == model then
			carrying[player] = nil
			resetWalkSpeed(player)
			economy.pushState(player)
		end
	end
	for _, base in ipairs(bases) do
		for padIndex, occupant in pairs(occupants[base]) do
			if occupant == model then
				occupants[base][padIndex] = nil
				if base.owner then
					recomputeIncome(base.owner)
				end
			end
		end
	end
end

local function sellPlaced(player, model)
	local price = model:GetAttribute("Price") or 0
	local base = baseByPlayer[player]
	local padIndex = model:GetAttribute("PadIndex")
	if base and padIndex then
		freePad(base, padIndex)
	end
	model:Destroy()
	economy.addMoney(player, math.floor(price * Config.SellRefund))
	recomputeIncome(player)
end

local function stealPlaced(player, model)
	local ownerUserId = model:GetAttribute("OwnerUserId")
	local victim = ownerUserId and Players:GetPlayerByUserId(ownerUserId)
	local victimBase = victim and baseByPlayer[victim]
	if not victimBase then
		return
	end
	if Bases.isLocked(victimBase) then
		banner(player, "That vault is LOCKED!")
		return
	end
	local padIndex = model:GetAttribute("PadIndex")
	freePad(victimBase, padIndex)
	recomputeIncome(victim)
	banner(victim, "Your " .. model.Name .. " was STOLEN!")
	startCarry(player, model, { kind = "Stolen", base = victimBase, padIndex = padIndex })
end

local function onPrompt(player, model)
	if not model or not model.Parent then
		return
	end
	local state = model:GetAttribute("State")
	if state == "Lane" then
		if carrying[player] then
			banner(player, "Already carrying one!")
			return
		end
		startCarry(player, model, { kind = "Lane" })
	elseif state == "Placed" then
		if model:GetAttribute("OwnerUserId") == player.UserId then
			sellPlaced(player, model)
		elseif not carrying[player] then
			stealPlaced(player, model)
		else
			banner(player, "Already carrying one!")
		end
	end
end

local function attachPrompt(model)
	if not model:IsA("Model") then
		return
	end
	local body = model:WaitForChild("Body", 5)
	if not body then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ActionPrompt"
	prompt.ActionText = "Catch"
	prompt.ObjectText = model.Name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = body
	prompt.Triggered:Connect(function(player)
		onPrompt(player, model)
	end)
	setPromptForState(model)
end

function Bases.tryLock(player)
	local base = baseByPlayer[player]
	if not base then
		return
	end
	local now = os.clock()
	if now < base.lockReadyAt then
		banner(player, string.format("Lock recharging: %ds", math.ceil(base.lockReadyAt - now)))
		return
	end
	base.lockedUntil = now + Config.LockSeconds
	base.lockReadyAt = now + Config.LockSeconds + Config.LockCooldown
	base.doorDome.Transparency = 0.65
	banner(player, "Vault locked for " .. Config.LockSeconds .. "s!")
	task.delay(Config.LockSeconds, function()
		base.doorDome.Transparency = 1
	end)
end

function Bases.assignBase(player)
	for _, base in ipairs(bases) do
		if not base.owner then
			base.owner = player
			baseByPlayer[player] = base
			for _, pad in ipairs(base.pads) do
				pad.Color = base.color
			end
			base.doorDome.Color = base.color
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "LockPrompt"
			prompt.ActionText = "Lock Vault"
			prompt.ObjectText = "Vault " .. base.index
			prompt.HoldDuration = 0
			prompt.MaxActivationDistance = 10
			prompt.RequiresLineOfSight = false
			prompt.Parent = base.lockPad
			prompt.Triggered:Connect(function(triggeringPlayer)
				if triggeringPlayer == player then
					Bases.tryLock(player)
				end
			end)
			recomputeIncome(player)
			return base
		end
	end
	return nil
end

function Bases.getBase(player)
	return baseByPlayer[player]
end

function Bases.releaseBase(player)
	returnCarried(player)
	local base = baseByPlayer[player]
	if not base then
		return
	end
	for padIndex, model in pairs(occupants[base]) do
		if model and model.Parent then
			model:Destroy()
		end
		occupants[base][padIndex] = nil
	end
	local prompt = base.lockPad:FindFirstChild("LockPrompt")
	if prompt then
		prompt:Destroy()
	end
	base.doorDome.Transparency = 1
	base.lockedUntil = 0
	base.lockReadyAt = 0
	base.owner = nil
	baseByPlayer[player] = nil
	for _, pad in ipairs(base.pads) do
		pad.Color = Color3.fromRGB(90, 90, 100)
	end
end

function Bases.init(basesList, remotesTable, economyModule)
	bases = basesList
	remotes = remotesTable
	economy = economyModule
	for _, base in ipairs(bases) do
		occupants[base] = {}
	end

	economy.setCarryingProvider(function(player)
		local entry = carrying[player]
		if entry and entry.model and entry.model.Parent then
			return entry.model.Name
		end
		return nil
	end)

	-- Every brainrot model, however it spawned, gets its action prompt here.
	local folder = Workspace:WaitForChild("Brainrots")
	for _, child in ipairs(folder:GetChildren()) do
		task.spawn(attachPrompt, child)
	end
	folder.ChildAdded:Connect(function(child)
		task.spawn(attachPrompt, child)
	end)

	-- Carried brainrots ride above the carrier's head; touching one of your
	-- own free pads places the catch automatically.
	RunService.Heartbeat:Connect(function()
		for player, entry in pairs(carrying) do
			local model = entry.model
			local character = player.Character
			local head = character and character:FindFirstChild("Head")
			if not (model and model.Parent and head) then
				continue
			end
			model:PivotTo(CFrame.new(head.Position + Vector3.new(0, 2.4, 0)))
			local base = baseByPlayer[player]
			local root = character:FindFirstChild("HumanoidRootPart")
			if base and root then
				local usable = Bases.usablePads(player)
				for padIndex = 1, usable do
					if not occupants[base][padIndex] then
						local pad = base.pads[padIndex]
						if (root.Position - pad.Position).Magnitude < 6 then
							carrying[player] = nil
							resetWalkSpeed(player)
							model:SetAttribute("CarrierUserId", 0)
							placeOnPad(base, padIndex, model)
							economy.pushState(player)
							break
						end
					end
				end
			end
		end
	end)

	-- Death drops the catch: stolen goods go home, lane catches rejoin the lane.
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			local humanoid = character:WaitForChild("Humanoid")
			humanoid.Died:Connect(function()
				returnCarried(player)
			end)
		end)
	end)
end

return Bases
