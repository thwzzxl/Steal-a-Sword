-- LocalScript em StarterPlayerScripts
local Players=game:GetService('Players')
local RunService=game:GetService('RunService')
local player=Players.LocalPlayer
local map=workspace:WaitForChild('SwordGameMap')
local stored=map:WaitForChild('StoredSwords')
local tracked={}
local function track(p) if p:IsA('ProximityPrompt') then tracked[p]=true end end
map.DescendantAdded:Connect(track)
map.DescendantRemoving:Connect(function(p) tracked[p]=nil end)
for _,p in ipairs(map:GetDescendants()) do track(p) end
RunService.RenderStepped:Connect(function()
	for p in pairs(tracked) do
		if not p.Parent then tracked[p]=nil
		elseif p.Name=='PlaceMovedSwordPrompt' then
			p.Enabled=p:GetAttribute('MoveOwner')==player.UserId and player:GetAttribute('MovingOwnSword')==true
		else
			local action=p:GetAttribute('SwordAction') or p.ActionText
			local sell=p.Name=='SellPrompt' or action=='Vender espada'
			local steal=action=='Roubar espada'
			local move=p.Name=='MoveSwordPrompt'
			if sell or steal or move then
				local m=p.Parent
				while m and m~=workspace and not (m:IsA('Model') and m.Parent==stored) do m=m.Parent end
				if m and m~=workspace then
					local owner=tonumber(m:GetAttribute('OwnerUserId'))
					local own=owner==player.UserId
					p.Enabled=not player:GetAttribute('MovingOwnSword') and ((own and (sell or move)) or (steal and owner~=nil and not own))
				end
			end
		end
	end
end)
