-- DataSystem V6 | ModuleScript em ServerScriptService
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local storeName = RunService:IsStudio() and "SwordGame_TEST_V1" or "SwordGame_LIVE_V1"
local store = DataStoreService:GetDataStore(storeName)
local token = game.JobId .. ":" .. HttpService:GenerateGUID(false)
local sessions = {}
local M = {}
local function key(player) return "Player_" .. player.UserId end
local function defaults() return {Cash=100, Rebirths=0, Swords={}, Equipment={}, Discovered={}, IndexRewardClaimed=false} end
local function retry(fn)
	for i=1,3 do
		local ok,result=pcall(fn)
		if ok then return true,result end
		warn("[DataSystem V6] Tentativa",i,result)
		if i<3 then task.wait(i) end
	end
	return false,nil
end
local function copy(value)
	if type(value)~="table" then return value end
	local out={}
	for k,v in pairs(value) do out[k]=copy(v) end
	return out
end
local function dayNow() return math.floor(os.time()/86400) end
local function normalizeDaily(data)
	local d=type(data.Daily)=="table" and data.Daily or {}
	d.NextDay=math.clamp(math.floor(tonumber(d.NextDay) or 1),1,7)
	d.LastClaim=math.floor(tonumber(d.LastClaim) or -1)
	data.Daily=d
	local q=type(data.Quests)=="table" and data.Quests or {}
	if q.Day~=dayNow() then q={Day=dayNow(),Items={}} end
	if type(q.Items)~="table" then q.Items={} end
	data.Quests=q
end
local function normalize(data)
	data=type(data)=="table" and data or defaults()
	if type(data.Swords)~="table" then data.Swords={} end
	if type(data.Equipment)~="table" then data.Equipment={} end
	if type(data.Discovered)~="table" then data.Discovered={} end
	if type(data.Cash)~="number" then data.Cash=100 end
	if type(data.Rebirths)~="number" then data.Rebirths=0 end
	data.IndexRewardClaimed=data.IndexRewardClaimed==true
	normalizeDaily(data)
	return data
end
local function snapshot(player,s)
	if not s.Active then return end
	local stats=player:FindFirstChild("leaderstats")
	local cash=stats and stats:FindFirstChild("Cash")
	if s.AdminCashOriginal~=nil then s.Data.Cash=s.AdminCashOriginal
	elseif cash then s.Data.Cash=cash.Value end
	s.Data.Rebirths=player:GetAttribute("Rebirths") or s.Data.Rebirths or 0
end
local function save(player,closing)
	local s=sessions[player]
	if not s then return true end
	if closing then
		if s.Closing then return false end
		s.Closing=true
	elseif s.Closing or s.Busy or not s.Active then return false end
	snapshot(player,s)
	while s.Busy do task.wait(.1) end
	s.Busy=true
	s.Data.LastSeen=os.time()
	local data=copy(s.Data)
	local ok,result=retry(function()
		return store:UpdateAsync(key(player),function(old)
			if type(old)~="table" or not old.Lock or old.Lock.Token~=token then return nil end
			if s.Active then old.Data=data end
			if closing then old.Lock=nil else old.Lock={Token=token,Expires=os.time()+180} end
			return old
		end)
	end)
	s.Busy=false
	local success=ok and result~=nil
	if success then
		print("[DataSystem V6] Salvo:",player.Name,"Cash:",data.Cash,"Espadas:",#data.Swords,"Banco:",storeName)
		if closing then sessions[player]=nil end
	else
		warn("[DataSystem V6] Falha ao salvar:",player.Name,"Banco:",storeName)
		if closing then s.Closing=false; s.PendingClose=true end
	end
	return success
end
function M.Open(player)
	if sessions[player] then return sessions[player].Data end
	local ok,record=retry(function()
		return store:UpdateAsync(key(player),function(old)
			old=type(old)=="table" and old or {}
			if old.Lock and old.Lock.Token~=token and (old.Lock.Expires or 0)>os.time() then return nil end
			old.Data=normalize(old.Data)
			local now=os.time()
			local last=tonumber(old.Data.LastSeen) or now
			local elapsed=math.clamp(now-last,0,28800)
			local rate=math.max(0,tonumber(old.Data.OfflineIncome) or 0)
			if elapsed>=60 then
				old.Data.PendingOfflineCash=math.min(9e15,(tonumber(old.Data.PendingOfflineCash) or 0)+math.floor(rate*elapsed*.1))
				old.Data.PendingOfflineSeconds=(tonumber(old.Data.PendingOfflineSeconds) or 0)+elapsed
			end
			old.Data.LastSeen=now
			old.Lock={Token=token,Expires=os.time()+180}
			return old
		end)
	end)
	if not ok or not record or not record.Lock or record.Lock.Token~=token then
		warn("[DataSystem V6] Falha ao abrir:",player.Name,"Banco:",storeName)
		return nil
	end
	sessions[player]={Data=record.Data,Active=false,Busy=false,Closing=false}
	if player.Parent~=Players then M.Close(player); return nil end
	print("[DataSystem V6] Carregado:",player.Name,"Cash:",record.Data.Cash,"Espadas:",#record.Data.Swords,"Banco:",storeName)
	return record.Data
end
function M.Activate(player)
	local s=sessions[player]; if s then s.Active=true end
end
local function active(player)
	local s=sessions[player]
	if s and s.Active and not s.Closing and not s.PendingClose then return s end
end
-- V37: saldo temporario exclusivo do dono, nunca persistido.
local ADMIN_OWNER=11715073634
local ADMIN_BALANCE=999000000000000
function M.ToggleAdminCash(player)
	if player.UserId~=ADMIN_OWNER then return false,"Sem permissao." end
	local s=active(player)
	local stats=player:FindFirstChild("leaderstats")
	local cash=stats and stats:FindFirstChild("Cash")
	if not s or not cash or not cash:IsA("IntValue") then return false,"Aguarde seus dados." end
	if s.AdminCashOriginal~=nil then
		cash.Value=s.AdminCashOriginal
		s.Data.Cash=s.AdminCashOriginal
		s.AdminCashOriginal=nil
		player:SetAttribute("AdminInfiniteCash",false)
		return true,"Saldo original restaurado!"
	end
	s.AdminCashOriginal=cash.Value
	s.Data.Cash=cash.Value
	cash.Value=ADMIN_BALANCE
	player:SetAttribute("AdminInfiniteCash",true)
	return true,"Dinheiro infinito ativado!"
end
task.spawn(function()
	while true do
		task.wait(.1)
		for player,s in pairs(sessions) do
			if s.AdminCashOriginal~=nil and s.Active and not s.Closing and not s.PendingClose and player.Parent==Players then
				local stats=player:FindFirstChild("leaderstats")
				local cash=stats and stats:FindFirstChild("Cash")
				if cash and cash:IsA("IntValue") and cash.Value~=ADMIN_BALANCE then cash.Value=ADMIN_BALANCE end
			end
		end
	end
end)
function M.SetSwords(player,list)
	local s=active(player)
	if s then s.Data.Swords=copy(list) end
end
function M.GetForge(player)
	local s=active(player); return s and copy(s.Data.Forge)
end
function M.SetForge(player,job)
	local s=active(player); if not s then return false end
	s.Data.Forge=copy(job); snapshot(player,s); return true
end
function M.GetEquipment(player)
	local s=active(player); if not s then return nil end
	return copy(s.Data.Equipment)
end
function M.SetEquipment(player,id)
	local s=active(player); if not s then return false end
	s.Data.Equipment[id]=true
	return true
end
-- Chamado somente por scripts do servidor apos aquisicao confirmada.
function M.DiscoverSword(player,id)
	local s=active(player)
	if not s or type(id)~="string" or #id==0 or #id>100 then return false end
	if s.Data.Discovered[id]==true then return false end
	s.Data.Discovered[id]=true
	print("[SwordIndex] Descoberta:",player.Name,id)
	return true
end
function M.GetDiscovered(player)
	local s=active(player); if not s then return nil end
	return copy(s.Data.Discovered)
end
function M.GetIndexRewardClaimed(player)
	local s=active(player); if not s then return nil end
	return s.Data.IndexRewardClaimed
end
-- A entrega da recompensa e a validacao do catalogo serao integradas
-- ao SwordSystem. Nenhum RemoteEvent de resgate e criado aqui.
function M.ClaimIndexReward(player)
	local s=active(player)
	if not s or s.Data.IndexRewardClaimed then return false end
	s.Data.IndexRewardClaimed=true
	return true
end
-- V25.1: API interna; somente scripts do servidor.
function M.GetDaily(player)
	local s=active(player); if not s then return nil end
	normalizeDaily(s.Data)
	return copy(s.Data.Daily)
end
function M.GetQuests(player)
	local s=active(player); if not s then return nil end
	normalizeDaily(s.Data)
	return copy(s.Data.Quests)
end
-- As recompensas serao entregues pelo futuro RewardsSystem.
-- Estas funcoes registram somente progresso; nao concedem premios.
function M.SetDaily(player,nextDay,lastClaim)
	local s=active(player); if not s then return false end
	normalizeDaily(s.Data)
	if type(nextDay)~="number" or nextDay%1~=0 or nextDay<1 or nextDay>7 then return false end
	if lastClaim~=dayNow() or s.Data.Daily.LastClaim>=lastClaim then return false end
	if nextDay~=(s.Data.Daily.NextDay%7)+1 then return false end
	s.Data.Daily={NextDay=nextDay,LastClaim=lastClaim}
	return true
end
function M.SetQuests(player,day,items)
	local s=active(player); if not s or day~=dayNow() or type(items)~="table" then return false end
	normalizeDaily(s.Data)
	s.Data.Quests={Day=day,Items=copy(items)}
	return true
end
-- V39: server-only income snapshot and claim.
function M.SetOfflineIncome(player,rate)
	local s=active(player)
	if s and type(rate)=="number" and rate>=0 and rate<math.huge then s.Data.OfflineIncome=math.min(rate,9e15) end
end
function M.GetOffline(player)
	local s=active(player)
	if not s then return nil end
	return math.max(0,tonumber(s.Data.PendingOfflineCash) or 0), math.max(0,tonumber(s.Data.PendingOfflineSeconds) or 0)
end
function M.ClaimOffline(player)
	local s=active(player)
	if not s or s.Busy or s.AdminCashOriginal~=nil then return false end
	local stats=player:FindFirstChild("leaderstats")
	local cash=stats and stats:FindFirstChild("Cash")
	local amount=math.floor(tonumber(s.Data.PendingOfflineCash) or 0)
	if not cash or not cash:IsA("IntValue") or amount<=0 or cash.Value+amount>9e15 then return false end
	s.Data.PendingOfflineCash=0
	s.Data.PendingOfflineSeconds=0
	cash.Value+=amount
	snapshot(player,s)
	task.spawn(save,player,false)
	return true
end
function M.Close(player) return save(player,true) end
task.spawn(function()
	while true do
		task.wait(5)
		for player,s in pairs(sessions) do
			if s.Active and not s.Closing and not s.PendingClose and player.Parent==Players then snapshot(player,s) end
		end
	end
end)
task.spawn(function()
	while true do
		task.wait(20)
		for player,s in pairs(sessions) do
			if not s.Closing then
				if s.PendingClose then task.spawn(M.Close,player)
				elseif s.Active then task.spawn(save,player,false) end
			end
		end
	end
end)
game:BindToClose(function()
	local start=os.clock()
	while next(sessions) and os.clock()-start<25 do
		for player,s in pairs(sessions) do
			if not s.Closing then task.spawn(M.Close,player) end
		end
		task.wait(1)
	end
	if next(sessions) then warn("[DataSystem V6] Encerramento com sessoes pendentes") end
end)
print("[DataSystem V6] Banco ativo:",storeName)
return M
