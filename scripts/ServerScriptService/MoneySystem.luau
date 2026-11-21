-- MONEY SYSTEM V30 | Roube uma Espada
local Players=game:GetService("Players")
local Workspace=game:GetService("Workspace")
local states={}
local Data=require(script.Parent:WaitForChild("DataSystem"))
local RS=game:GetService("ReplicatedStorage")
local remote=Instance.new("RemoteFunction")
remote.Name="OfflineFarmV39"
remote.OnServerInvoke=function(player,action)
	if action=="State" then return Data.GetOffline(player) end
	if action=="Claim" then
		local ok=Data.ClaimOffline(player)
		return ok, Data.GetOffline(player)
	end
end
remote.Parent=RS
local Rewards=require(script.Parent:WaitForChild("RewardsSystem"))
local function setupPlayer(player)
	local stats=player:FindFirstChild("leaderstats") or Instance.new("Folder")
	stats.Name="leaderstats"; stats.Parent=player
	if not stats:FindFirstChild("Cash") then
		local cash=Instance.new("IntValue"); cash.Name="Cash"; cash.Value=100; cash.Parent=stats
	end
	local counter=stats:FindFirstChild("Rebirths") or Instance.new("IntValue")
	counter.Name="Rebirths"; counter.Value=player:GetAttribute("Rebirths") or 0; counter.Parent=stats
	if player:GetAttribute("IncomeMultiplier")==nil then player:SetAttribute("IncomeMultiplier",1) end
	player:GetAttributeChangedSignal("Rebirths"):Connect(function() counter.Value=player:GetAttribute("Rebirths") or 0 end)
end
Players.PlayerAdded:Connect(setupPlayer)
for _,p in ipairs(Players:GetPlayers()) do setupPlayer(p) end
local function cashOf(player)
	local stats=player:FindFirstChild("leaderstats")
	return stats and stats:FindFirstChild("Cash")
end
local function formatMoney(n)
	for _,v in ipairs({{1e12,"T"},{1e9,"B"},{1e6,"M"},{1e3,"K"}}) do
		if n>=v[1] then return string.format("%.1f%s",n/v[1],v[2]) end
	end
	return tostring(math.floor(n))
end
local function update(s)
	if not s.Pad.Parent then return end
	s.Label.Text="$"..formatMoney(s.Accumulated)
	s.Pad.Color=s.Accumulated>0 and Color3.fromRGB(57,225,45) or Color3.fromRGB(55,90,65)
end
local function collect(player,s)
	if not s or s.Base:GetAttribute("OwnerUserId")~=player.UserId or s.OwnerId~=player.UserId then return false end
	local cash=cashOf(player)
	if not cash or not cash:IsA("IntValue") then return false end
	local amount=s.Accumulated
	s.Accumulated=0
	cash.Value+=amount
	update(s)
	Rewards.Record(player,"Collect",amount)
	return true,amount
end
-- Canal exclusivamente servidor-servidor; nenhuma RemoteEvent para clientes.
local payout=Instance.new("BindableFunction")
payout.Name="CollectOnSale"
payout.OnInvoke=function(player,base,stand,sword)
	local s=states[stand]
	if not s or s.Base~=base or not sword or sword:GetAttribute("OwnerUserId")~=player.UserId or sword:GetAttribute("BaseName")~=base.Name or sword:GetAttribute("StandName")~=stand.Name then return false end
	return collect(player,s)
end
payout.Parent=script
local map=Workspace:WaitForChild("SwordGameMap")
while not map:GetAttribute("MapReady") do map:GetAttributeChangedSignal("MapReady"):Wait() end
local bases=map:WaitForChild("Bases")
local stored=map:WaitForChild("StoredSwords")
local function removePad(stand)
	local s=states[stand]
	if s then states[stand]=nil; s.Pad:Destroy() end
end
local function createPad(base,stand)
	if not stand:IsA("BasePart") or not stand.Name:match("^Stand_%d+_%d+$") or states[stand] then return end
	local floor=base:FindFirstChild("Floor")
	if not floor then return end
	local pos=floor.CFrame:PointToObjectSpace(stand.Position)
	local direction=pos.X>0 and -1 or 1
	local upper=pos.Y>10
	-- Nos slots internos superiores, o coletor fica ao lado em Z para nao cair na abertura da escada.
	local x=pos.X+direction*9.5
	local z=pos.Z
	if upper then x=pos.X+direction*5.5 end
	local pad=Instance.new("Part")
	pad.Name="MoneyPad_"..stand.Name; pad.Size=Vector3.new(4.5,.25,3.5)
	pad.Anchored=true; pad.CanCollide=false; pad.CanTouch=true; pad.CastShadow=false
	pad.Material=Enum.Material.SmoothPlastic
	pad.CFrame=floor.CFrame*CFrame.new(x,(pos.Y>30 and 34 or (upper and 17 or floor.Size.Y/2))+.175,z)
	local old=base:FindFirstChild(pad.Name); if old then old:Destroy() end
	pad.Parent=base
	-- Texto flutuante acima do coletor, acompanhando a camera.
	local gui=Instance.new("BillboardGui")
	gui.Name="MoneyDisplay"
	gui.Adornee=pad
	gui.Size=UDim2.fromScale(4.8,2.2)
	gui.StudsOffsetWorldSpace=Vector3.new(0,2.3,0)
	gui.AlwaysOnTop=false
	gui.MaxDistance=35
	gui.LightInfluence=0
	gui.Parent=pad
	local function makeLabel(name,text,color,y,height)
		local label=Instance.new("TextLabel")
		label.Name=name
		label.Size=UDim2.fromScale(1,height)
		label.Position=UDim2.fromScale(0,y)
		label.BackgroundTransparency=1
		label.Text=text
		label.TextColor3=color
		label.TextScaled=true
		label.Font=Enum.Font.FredokaOne
		label.TextStrokeColor3=Color3.new(0,0,0)
		label.TextStrokeTransparency=0
		label.Parent=gui
		local stroke=Instance.new("UIStroke")
		stroke.Color=Color3.new(0,0,0)
		stroke.Thickness=2
		stroke.Parent=label
		return label
	end
	makeLabel("CollectTitle","Coletar",Color3.new(1,1,1),0,.46)
	local label=makeLabel("Amount","$0",Color3.fromRGB(139,255,55),.46,.54)
	local s={Base=base,Stand=stand,Pad=pad,Label=label,Accumulated=0,OwnerId=base:GetAttribute("OwnerUserId")}
	states[stand]=s
	pad.Touched:Connect(function(hit)
		local character=hit:FindFirstAncestorOfClass("Model")
		local player=character and Players:GetPlayerFromCharacter(character)
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		if player and humanoid and humanoid.Health>0 and states[stand]==s then collect(player,s) end
	end)
	update(s)
end
local function setupBase(base)
	local folder=base:WaitForChild("SwordStands")
	folder.ChildAdded:Connect(function(stand) createPad(base,stand) end)
	folder.ChildRemoved:Connect(removePad)
	for _,stand in ipairs(folder:GetChildren()) do createPad(base,stand) end
	local function reset()
		for _,s in pairs(states) do if s.Base==base then s.OwnerId=base:GetAttribute("OwnerUserId"); s.Accumulated=0; update(s) end end
	end
	base:GetAttributeChangedSignal("OwnerUserId"):Connect(reset)
	base:GetAttributeChangedSignal("RebirthReset"):Connect(reset)
end
for _,base in ipairs(bases:GetChildren()) do if base:IsA("Model") then setupBase(base) end end
local fallback={Comum=5,Incomum=15,Rara=50,["Épica"]=150,["Lendária"]=500,["Mítica"]=3000}
while true do
	task.wait(1)
	local rates={}
	for _,sword in ipairs(stored:GetChildren()) do
		if not sword:IsA("Model") then continue end
		local id=sword:GetAttribute("OwnerUserId")
		local bn=sword:GetAttribute("BaseName"); local sn=sword:GetAttribute("StandName")
		if not id or not bn or not sn then continue end
		local base=bases:FindFirstChild(bn)
		local folder=base and base:FindFirstChild("SwordStands")
		local stand=folder and folder:FindFirstChild(sn)
		local s=stand and states[stand]
		local owner=Players:GetPlayerByUserId(id)
		if not s or not owner or s.OwnerId~=id or base:GetAttribute("OwnerUserId")~=id then continue end
		local income=sword:GetAttribute("Income")
		if typeof(income)~="number" or income<0 then income=fallback[sword:GetAttribute("Rarity")] or 0 end
		local mult=owner:GetAttribute("IncomeMultiplier")
		if typeof(mult)~="number" or mult<1 then mult=1 end
		local passMult=owner:GetAttribute("GamepassIncomeMultiplier") or 1
		local earned=math.floor(income*mult*passMult)
		rates[owner]=(rates[owner] or 0)+earned
		s.Accumulated+=earned
		update(s)
	end
	for _,player in ipairs(Players:GetPlayers()) do Data.SetOfflineIncome(player,rates[player] or 0) end
end
