-- Wave: the tsunami. Every WaveInterval a warning goes out, then a huge
-- translucent wave sweeps the lane from Z = -135 to Z = +135 and washes away
-- every brainrot still outside a vault: lane walkers, and carried ones whose
-- carrier is caught standing in the lane band.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local Wave = {}

local remotes = nil
local bases = nil
local sweeping = false

local LANE_HALF_WIDTH = 14

local function destroyModel(model)
	if bases then
		bases.onModelGone(model)
	end
	model:Destroy()
end

function Wave.triggerNow()
	if sweeping then
		return
	end
	sweeping = true

	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		remotes.BannerEvent:FireClient(player, "TSUNAMI! Get your brainrot home!")
	end

	local wave = Instance.new("Part")
	wave.Name = "TsunamiWave"
	wave.Size = Vector3.new(60, 26, 10)
	wave.Color = Color3.fromRGB(60, 160, 255)
	wave.Transparency = 0.45
	wave.Material = Enum.Material.Glass
	wave.Anchored = true
	wave.CanCollide = false
	wave.Locked = true
	wave.Position = Vector3.new(0, 10, -135)
	wave.Parent = Workspace

	local folder = Workspace:WaitForChild("Brainrots")
	local startTime = os.clock()
	local duration = Config.WaveSweepSeconds
	local conn
	conn = game:GetService("RunService").Heartbeat:Connect(function()
		local alpha = math.clamp((os.clock() - startTime) / duration, 0, 1)
		local z = -135 + alpha * 270
		wave.Position = Vector3.new(0, 10, z)
		for _, model in ipairs(folder:GetChildren()) do
			if model:IsA("Model") then
				local state = model:GetAttribute("State")
				local pos = model:GetPivot().Position
				if pos.Z <= z and pos.Z >= z - 14 then
					if state == "Lane" then
						destroyModel(model)
					elseif state == "Carried" and math.abs(pos.X) < LANE_HALF_WIDTH then
						destroyModel(model)
					end
				end
			end
		end
		if alpha >= 1 then
			conn:Disconnect()
			wave:Destroy()
			sweeping = false
		end
	end)
end

function Wave.init(remotesTable, basesModule)
	remotes = remotesTable
	bases = basesModule
	task.spawn(function()
		while true do
			task.wait(Config.WaveInterval - Config.WaveWarning)
			for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
				remotes.BannerEvent:FireClient(player, "A tsunami is coming in " .. Config.WaveWarning .. "s!")
			end
			task.wait(Config.WaveWarning)
			Wave.triggerNow()
		end
	end)
end

return Wave
