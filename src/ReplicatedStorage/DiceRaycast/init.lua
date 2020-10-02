--[[
	@Author: Gavin "Mullets" Rosenthal
	@Desc: 
--]]

--// logic
local Raycast = {}
Raycast.Debug = false

--// services
local Services = setmetatable({}, {__index = function(cache, serviceName)
	cache[serviceName] = game:GetService(serviceName)
	return cache[serviceName]
end})

--// variables
local Manager = require(script:WaitForChild('Manager'))
local IsStudio = Services['RunService']:IsStudio()
local IsServer = Services['RunService']:IsServer()
local IsClient = Services['RunService']:IsClient()

--// functions
local function Draw(origin,direction)
	local ending = origin + direction
	local distance = (origin-ending).magnitude
	local trace = Instance.new("Part")
	trace.Anchored = true
	trace.CanCollide = false
	trace.BrickColor = BrickColor.Random()
	trace.Size = Vector3.new(0.2,0.2,distance)
	trace.CFrame = CFrame.new(origin,ending) * CFrame.new(0,0,-distance/2)
	trace.Parent = workspace
	Manager.garbage(5,trace)
end

function Raycast.FindHumanoidsExcludingPlayers(origin,direction)
	assert(origin ~= nil)
	assert(direction ~= nil)
	origin = typeof(origin) == 'Instance' and origin.Position or origin
	
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.IgnoreWater = true
	
	local proxy = {}
	for index,plr in pairs(Services['Players']:GetPlayers()) do
		if plr.Character then
			table.insert(proxy,plr.Character)
		end
	end
	params.FilterDescendantsInstances = proxy
	
	if Raycast.Debug then
		Draw(origin,direction)
	end
	
	local ray = workspace:Raycast(origin,direction,params)
	if not ray then return end
	local humanoid = ray.Instance.Parent:FindFirstChildWhichIsA('Humanoid') or ray.Instance.Parent.Parent:FindFirstChildWhichIsA('Humanoid')
	if not humanoid then return end
	local model = humanoid.Parent
	if not model then return end
	return model
end

function Raycast.Test(origin,direction)
	if not IsStudio then return end
	assert(origin ~= nil)
	assert(direction ~= nil)
	origin = typeof(origin) == 'Instance' and origin.Position or origin
	
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {game.Players.LocalPlayer.Character}
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.IgnoreWater = true
	
	if Raycast.Debug then
		Draw(origin,direction)
	end
	
	local ray = workspace:Raycast(origin,direction,params)
	return ray.Instance
end

function Raycast.RepeatCast(time,code,...)
	assert(typeof(time) == 'number')
	assert(typeof(code) == 'function')
	
	local opt = {...}
	local rate = 1/60
	local logged = 0
	local clock = os.clock()
	local cache = {}
	local flag = false
	local done = false
	local event; event = Services['RunService'].Heartbeat:Connect(function(delta)
		if os.clock() - clock > time then
			done = true
			event:Disconnect()
			return
		end
		logged = logged + delta
		while logged >= rate do
			logged = logged - rate
			local obj = code(table.unpack(opt))
			if obj then
				if not table.find(cache,obj) then 
					flag = true
					table.insert(cache,obj)
				end
			end
		end
	end)
	
	while not done do Services['RunService'].Heartbeat:Wait() end
	return cache
end

return Raycast