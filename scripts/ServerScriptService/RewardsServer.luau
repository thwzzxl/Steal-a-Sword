-- RewardsServer V25.2 | Script | ServerScriptService
local RS=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")
local R=require(script.Parent:WaitForChild("RewardsSystem"))
local remote=Instance.new("RemoteFunction")
remote.Name="DailyQuestsRequest"
local last={}
remote.OnServerInvoke=function(player,action,id)
	local now=os.clock()
	if last[player] and now-last[player]<.35 then return false,"Aguarde um instante." end
	last[player]=now
	if action=="State" then return true,R.State(player) end
	if action=="Daily" then return R.ClaimDaily(player) end
	if action=="Quest" then return R.ClaimQuest(player,id) end
	return false,"Ação inválida."
end
Players.PlayerRemoving:Connect(function(p) last[p]=nil end)
remote.Parent=RS
