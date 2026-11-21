-- GamepassSystem V28 | ServerScriptService (Script)
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local VIP = 2088057023
local DOUBLE = 2089898997
local owned = {}
local function apply(player)
	local s = owned[player]
	if not s or player.Parent ~= Players then return end
	player:SetAttribute("HasVIP", s[VIP] == true)
	player:SetAttribute("HasDoubleMoney", s[DOUBLE] == true)
	player:SetAttribute("GamepassIncomeMultiplier", (s[VIP] and 1.25 or 1) * (s[DOUBLE] and 2 or 1))
end
local function setup(player)
	if owned[player] then return end
	owned[player] = {}
	apply(player)
	for _, id in ipairs({VIP, DOUBLE}) do
		task.spawn(function()
			for attempt = 1, 3 do
				local ok, result = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, id)
				local s = owned[player]
				if not s then return end
				if ok then
					if s[id] ~= true then s[id] = result end
					apply(player)
					return
				end
				task.wait(attempt * 2)
			end
			warn("[GamepassSystem] Falha ao consultar passe", id, player.UserId)
		end)
	end
end
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, id, purchased)
	if not purchased or (id ~= VIP and id ~= DOUBLE) then return end
	if not owned[player] then setup(player) end
	if owned[player] then owned[player][id] = true; apply(player) end
end)
Players.PlayerAdded:Connect(setup)
Players.PlayerRemoving:Connect(function(player) owned[player] = nil end)
for _, player in ipairs(Players:GetPlayers()) do setup(player) end
