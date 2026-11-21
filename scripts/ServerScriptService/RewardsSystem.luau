-- RewardsSystem V25.2 | ModuleScript | ServerScriptService
local Data = require(script.Parent:WaitForChild("DataSystem"))
local R = {}
local dailyCash = {500,1500,5000,10000,25000,50000}
local definitions = {
	{Id="Buy",Target=5,Reward=2500,Title="Compre 5 espadas"},
	{Id="Steal",Target=2,Reward=7500,Title="Roube 2 espadas"},
	{Id="Collect",Target=10000,Reward=5000,Title="Colete $10.000"},
}
local function day() return math.floor(os.time()/86400) end
local function cash(player)
	local stats=player:FindFirstChild("leaderstats")
	return stats and stats:FindFirstChild("Cash")
end
local function quests(player)
	local q=Data.GetQuests(player)
	if not q then return nil end
	if #q.Items==0 then
		for _,d in ipairs(definitions) do
			table.insert(q.Items,{Id=d.Id,Title=d.Title,Target=d.Target,Reward=d.Reward,Progress=0,Claimed=false})
		end
		if not Data.SetQuests(player,q.Day,q.Items) then return nil end
	end
	return q
end
function R.Record(player,id,amount)
	if type(amount)~="number" or amount<=0 then return end
	local q=quests(player); if not q then return end
	for _,item in ipairs(q.Items) do
		if item.Id==id and not item.Claimed then
			item.Progress=math.min(item.Target,item.Progress+math.floor(amount))
			Data.SetQuests(player,q.Day,q.Items)
			return
		end
	end
end
function R.State(player)
	local d=Data.GetDaily(player); local q=quests(player)
	if not d or not q then return nil end
	return {Daily=d,Quests=q.Items,CanClaim=d.LastClaim<day(),ResetAt=(day()+1)*86400,DailyCash=dailyCash}
end
function R.ClaimDaily(player)
	local d=Data.GetDaily(player); local c=cash(player)
	if not d or not c then return false,"Dados indisponíveis." end
	local today=day()
	if d.LastClaim>=today then return false,"Já resgatado hoje." end
	if d.NextDay==7 then
		if not R.GrantSword then return false,"Sistema de espadas indisponível." end
		-- Callback servidor, sem espera: valida vaga, cria espada e confirma resgate.
		return R.GrantSword(player,today)
	end
	if not Data.SetDaily(player,d.NextDay+1,today) then return false,"Tente novamente." end
	c.Value+=dailyCash[d.NextDay]
	return true,"Recompensa recebida!"
end
function R.ClaimQuest(player,id)
	if type(id)~="string" then return false,"Missão inválida." end
	local q=quests(player); local c=cash(player)
	if not q or not c then return false,"Dados indisponíveis." end
	for _,item in ipairs(q.Items) do
		if item.Id==id then
			if item.Claimed or item.Progress<item.Target then return false,"Missão indisponível." end
			item.Claimed=true
			if not Data.SetQuests(player,q.Day,q.Items) then return false,"Tente novamente." end
			c.Value+=item.Reward
			return true,"Recompensa recebida!"
		end
	end
	return false,"Missão inválida."
end
return R
