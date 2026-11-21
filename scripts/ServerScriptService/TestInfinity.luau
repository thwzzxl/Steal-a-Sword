
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Funciona SOMENTE no Roblox Studio
if not RunService:IsStudio() then
	return
end

local DataSystem = require(
	game.ServerScriptService:WaitForChild("DataSystem")
)

local catalog = ReplicatedStorage:WaitForChild("SwordIndexCatalog")

local function testPlayer(player)
	local index = player:WaitForChild("SwordIndex", 60)

	if not index then
		warn("[TEST INFINITY] Index não encontrado!")
		return
	end

	while not index:GetAttribute("Ready") do
		task.wait(0.2)
	end

	local count = 0

	for _, sword in ipairs(catalog:GetChildren()) do
		local id = sword:GetAttribute("IndexId")
		local order = sword:GetAttribute("IndexOrder")

		if id and order then
			DataSystem.DiscoverSword(player, id)

			index:SetAttribute("Sword_" .. order, true)

			count += 1
		end
	end

	index:SetAttribute("Count", count)

	print("[TEST INFINITY] Coleção liberada:", count)
end

Players.PlayerAdded:Connect(testPlayer)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(testPlayer, player)
end
