-- GLOBAL RANKING V47.4 | ServerScriptService > GlobalRanking
local Players = game:GetService("Players")
local DSS = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local map = workspace:WaitForChild("SwordGameMap")
while not map:GetAttribute("MapReady") do map:GetAttributeChangedSignal("MapReady"):Wait() end
local stored = map:WaitForChild("StoredSwords")
local bases = map:WaitForChild("Bases")
local prefix = RunService:IsStudio() and "SwordRank_TEST_V1_" or "SwordRank_LIVE_V1_"
local definitions = {{"Cash","TOP CASH",Color3.fromRGB(88,220,145)}, {"Rebirth","TOP REBIRTH",Color3.fromRGB(255,204,91)}, {"Income","TOP MONEY/s",Color3.fromRGB(181,155,255)}}
local old = map:FindFirstChild("GlobalRanking"); if old then old:Destroy() end
local folder = Instance.new("Folder"); folder.Name="GlobalRanking"; folder.Parent=map
local boards, cache, names = {}, {}, {}
local function text(parent, value, pos, size, color, font)
	local t=Instance.new("TextLabel"); t.BackgroundTransparency=1; t.Position=pos; t.Size=size; t.Text=value; t.TextColor3=color; t.Font=font or Enum.Font.GothamBold; t.TextScaled=true; t.Parent=parent; return t
end
local function part(name,size,cf,color)
	local p=Instance.new("Part"); p.Name=name; p.Size=size; p.CFrame=cf; p.Color=color; p.Material=Enum.Material.SmoothPlastic; p.Anchored=true; p.CastShadow=false; p.Parent=folder; return p
end
local function format(n)
	for _,u in ipairs({{1e15,"Q"},{1e12,"T"},{1e9,"B"},{1e6,"M"},{1e3,"K"}}) do if n>=u[1] then return string.format("%.2f%s",n/u[1],u[2]) end end
	return tostring(n)
end
-- Um painel na lateral da fachada, fora da entrada e das bases.
local foundation=map:WaitForChild("Decorations"):WaitForChild("SwordFactory"):WaitForChild("Foundation")
local x=foundation.Position.X-43
local z=foundation.Position.Z+13
local rotation=CFrame.Angles(0,math.pi,0)
local board=part("RankingBoard",Vector3.new(18,13,1),CFrame.new(x,7.5,z)*rotation,Color3.fromRGB(23,34,51))
part("Pedestal",Vector3.new(18,1,3),CFrame.new(x,.5,z)*rotation,Color3.fromRGB(43,63,89))
local HttpService=game:GetService("HttpService")
for _,d in ipairs(definitions) do
	boards[d[1]]={Store=DSS:GetOrderedDataStore(prefix..d[1])}
	board:SetAttribute(d[1].."Data","[]")
	board:SetAttribute(d[1].."Status","Carregando...")
end
local function snapshot(player)
	if not player:GetAttribute("EquipmentReady") then return end
	local stats=player:FindFirstChild("leaderstats"); local cash=stats and stats:FindFirstChild("Cash"); local reb=stats and stats:FindFirstChild("Rebirths")
	if not cash or not reb then return end
	local base
	for _,b in ipairs(bases:GetChildren()) do if b:GetAttribute("OwnerUserId")==player.UserId then base=b; break end end
	if not base then return end
	local income=0
	local mult=math.max(1,player:GetAttribute("IncomeMultiplier") or 1)*(player:GetAttribute("GamepassIncomeMultiplier") or 1)
	for _,s in ipairs(stored:GetChildren()) do if s:GetAttribute("OwnerUserId")==player.UserId and s:GetAttribute("BaseName")==base.Name then income+=math.floor((s:GetAttribute("Income") or 0)*mult) end end
	local values={Rebirth=reb.Value,Income=income}
	if not player:GetAttribute("AdminInfiniteCash") then values.Cash=cash.Value end
	local key=tostring(player.UserId); cache[key]=cache[key] or {}
	for metric,value in pairs(values) do
		value=math.clamp(math.floor(value),0,9000000000000000)
		if cache[key][metric]~=value then
			local ok,err=pcall(function() boards[metric].Store:SetAsync(key,value) end)
			if ok then cache[key][metric]=value else warn("[Ranking]",metric,err) end
		end
	end
end
local function refresh()
	for _,d in ipairs(definitions) do
		local b=boards[d[1]]
		local ok,pages=pcall(function() return b.Store:GetSortedAsync(false,10) end)
		if ok then
			local entries={}
			for _,e in ipairs(pages:GetCurrentPage()) do
				local id=tonumber(e.key)
				if id then
					if not names[id] then local success,n=pcall(function() return Players:GetNameFromUserIdAsync(id) end); if success then names[id]=n end end
					table.insert(entries,{Id=id,Name=names[id] or ("Jogador "..id),Score=(d[1]=="Rebirth" and tostring(e.value) or "$"..format(e.value)..(d[1]=="Income" and "/s" or ""))})
				end
			end
			board:SetAttribute(d[1].."Data",HttpService:JSONEncode(entries))
			board:SetAttribute(d[1].."Status","GLOBAL • Atualizado a cada 60s")
		else board:SetAttribute(d[1].."Status","Ranking temporariamente indisponível"); warn("[Ranking]",pages) end
	end
end
-- Salva antes da limpeza da base sempre que o snapshot ainda estiver disponível.
Players.PlayerRemoving:Connect(function(p) snapshot(p) end)
task.spawn(function()
	while true do
		for _,p in ipairs(Players:GetPlayers()) do snapshot(p) end
		refresh()
		task.wait(60)
	end
end)
print("[GlobalRanking V47.4] Iniciado")
