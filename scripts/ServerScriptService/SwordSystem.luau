
-- SWORD SYSTEM V39.13 - PIEDADE LENDARIA E MITICA
-- Roube uma Espada
-- Local: ServerScriptService
-- Spawn, coleta, armazenamento e roubo

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local CONFIG = {
	SpawnInterval = 5,
	MaxArenaSwords = 12,
	ConveyorSpeed = 8,
	ConveyorHeight = 2,
	CollectDistance = 10,
	StealDistance = 8,
	DepositCheckInterval = 0.2,
}

local RARITIES = {
	{Name = "Comum", Price = 50, Income = 2, Weight = 20, Color = Color3.fromRGB(190, 195, 205)},
	{Name = "Incomum", Price = 350, Income = 6, Weight = 12, Color = Color3.fromRGB(80, 215, 120)},
	{Name = "Rara", Price = 2500, Income = 22, Weight = 4.4625, Color = Color3.fromRGB(65, 155, 255)},
	{Name = "Épica", Price = 15000, Income = 85, Weight = 1.65, Color = Color3.fromRGB(175, 85, 255)},
	{Name = "Lendária", Price = 100000, Income = 320, Weight = 0.308, Color = Color3.fromRGB(255, 190, 50)},
	{Name = "Mítica", Id = "Infernal", Price = 1000000, Income = 2000, Weight = 0.138125, Color = Color3.fromRGB(255, 100, 30)},
	{Name = "Secreta", Id = "Eclipse", Price = 10000000, Income = 10000, Weight = 0.005, Color = Color3.fromRGB(220, 80, 220)},
	{Name = "Secreta", Id = "Aether", Price = 250000000, Income = 100000, Weight = 0.0008, Color = Color3.fromRGB(100, 230, 255)},
	{Name = "Comum", Id = "Wooden Blade", Price = 100, Income = 3, Weight = 13, Color = Color3.fromRGB(170, 120, 70)},
	{Name = "Incomum", Id = "Venom Fang", Price = 750, Income = 10, Weight = 7, Color = Color3.fromRGB(100, 220, 65)},
	{Name = "Rara", Id = "Glacier", Price = 5000, Income = 40, Weight = 2.55, Color = Color3.fromRGB(100, 210, 255)},
	{Name = "Épica", Id = "Shadow Reaper", Price = 35000, Income = 150, Weight = 0.66, Color = Color3.fromRGB(150, 70, 220)},
	{Name = "Lendária", Id = "Sunbreaker", Price = 250000, Income = 650, Weight = 0.126, Color = Color3.fromRGB(255, 170, 40)},
	{Name = "Secreta", Id = "Oblivion", Price = 50000000, Income = 30000, Weight = 0.0015, Color = Color3.fromRGB(170, 100, 255)},
	{Name = "Comum", Id = "Bronze Blade", Price = 150, Income = 4, Weight = 7, Color = Color3.fromRGB(184, 117, 65)},
	{Name = "Comum", Id = "Knight Sword", Price = 250, Income = 5, Weight = 5, Color = Color3.fromRGB(165, 180, 205)},
	{Name = "Incomum", Id = "Crimson Blade", Price = 500, Income = 8, Weight = 6, Color = Color3.fromRGB(205, 65, 75)},
	{Name = "Incomum", Id = "Jade Katana", Price = 1200, Income = 14, Weight = 3, Color = Color3.fromRGB(65, 185, 135)},
	{Name = "Rara", Id = "Thunder Blade", Price = 3500, Income = 30, Weight = 2.55, Color = Color3.fromRGB(245, 210, 65)},
	{Name = "Rara", Id = "Aquamarine", Price = 8500, Income = 55, Weight = 1.275, Color = Color3.fromRGB(65, 205, 225)},
}

table.insert(RARITIES, {Name="Ancestral", Id="Ancient", Price=50000000, Income=50000, Weight=0, Color=Color3.fromRGB(70,170,220)})
local INFINITY = {Name="Exclusiva", Id="INFINITY", Price=0, Income=150000, Weight=0, Color=Color3.fromRGB(255,220,110)}
local rng = Random.new()

local map = Workspace:WaitForChild("SwordGameMap")
while not map:GetAttribute("MapReady") do
	map:GetAttributeChangedSignal("MapReady"):Wait()
end
local basesFolder = map:WaitForChild("Bases")
local arena = map:WaitForChild("Arena")
local beltStart = arena:WaitForChild("ConveyorStart")
local beltEnd = arena:WaitForChild("ConveyorEnd")
local RunService = game:GetService("RunService")
local moving = {}

local function getFolder(name)
	local folder = map:FindFirstChild(name)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = map
	end
	return folder
end

local arenaSwords = getFolder("ArenaSwords")
local carriedSwords = getFolder("CarriedSwords")
local storedSwords = getFolder("StoredSwords")

local DataSystem = require(script.Parent:WaitForChild("DataSystem"))
local Rewards = require(script.Parent:WaitForChild("RewardsSystem"))
local ready = {}
local refreshSave
local carrying = {}
local occupiedStands = {}
local swordOrigins = {}
local carrySpeeds = {}
local clearCarry
local function restoreSpeed(player)
	local state = carrySpeeds[player]
	carrySpeeds[player] = nil
	player:SetAttribute("CarryingStolen", false)
	if state and state.Humanoid.Parent then
		state.Humanoid.WalkSpeed = player:GetAttribute("SpeedCoilEquipped") and 30 or 20
	end
end
local function theftNotice(player, message)
	local pg = player:FindFirstChildOfClass("PlayerGui")
	if not pg then return end
	local old = pg:FindFirstChild("TheftNotice")
	if old then old:Destroy() end
	local gui = Instance.new("ScreenGui")
	gui.Name = "TheftNotice"
	gui.ResetOnSpawn = false
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(.8,0,0,54)
	label.Position = UDim2.fromScale(.1,.28)
	label.BackgroundColor3 = Color3.fromRGB(40,30,45)
	label.TextColor3 = Color3.new(1,1,1)
	label.TextWrapped = true
	label.TextSize = 18
	label.Font = Enum.Font.GothamBold
	label.Text = message
	label.Parent = gui
	gui.Parent = pg
	task.delay(5,function() gui:Destroy() end)
end

-- RARIDADE

-- Garantia: no maximo quatro spawns seguidos sem espada comum.
local spawnsWithoutCommon = 0
local MAX_WITHOUT_COMMON = 4

local eventStorage = game:GetService("ReplicatedStorage")
local boosted = {Rara=true, ["Épica"]=true, ["Lendária"]=true}
local lastEvent = "None"
local eventMisses = 0
local eventLimits = {Lucky=12, Infernal=75, Celestial=300}
local function qualifies(rarity,event)
	if event == "Lucky" then return boosted[rarity.Name] == true end
	if event == "Infernal" then return rarity.Id == "Infernal" end
	if event == "Celestial" then return rarity.Name == "Secreta" end
	return false
end
-- V39.6: contadores por servidor, somente spawns naturais.
local pity = {Legendary=0, Mythic=0}
local pityLimits = {Legendary=65, Mythic=200}
local pityRows = {}
local function updatePityDisplay()
	for key,row in pairs(pityRows) do
		local count=math.min(pity[key],pityLimits[key])
		row.Label.Text=row.Title.."   "..count.." / "..pityLimits[key]
		row.Fill.Size=UDim2.fromScale(count/pityLimits[key],1)
	end
	map:SetAttribute("MythicPity",pity.Mythic)
	map:SetAttribute("LegendaryPity",pity.Legendary)
	map:SetAttribute("SecretPity",nil)
end
local function buildPityDisplay()
	local factory=map:FindFirstChild("SwordFactory",true)
	local sign=factory and factory:FindFirstChild("TerminalSign")
	if not sign or not sign:IsA("BasePart") then warn("[Pity] TerminalSign nao encontrado"); return end
	for _,obj in ipairs(sign:GetDescendants()) do
		if obj:IsA("SurfaceGui") or obj:IsA("BillboardGui") then obj.Enabled=false end
	end
	local old=factory:FindFirstChild("PityDisplay")
	if old then old:Destroy() end
	local panel=Instance.new("Part")
	panel.Name="PityDisplay"; panel.Size=Vector3.new(sign.Size.X,sign.Size.Y,.18)
	panel.CFrame=sign.CFrame*CFrame.new(0,0,sign.Size.Z/2+.1)
	panel.Anchored=true; panel.CanCollide=false; panel.CanTouch=false; panel.CanQuery=false
	panel.Color=Color3.fromRGB(24,24,28); panel.Material=Enum.Material.SmoothPlastic
	panel.Parent=factory
	local gui=Instance.new("SurfaceGui")
	gui.Name="PitySurface"; gui.Face=Enum.NormalId.Back; gui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize=Vector2.new(1020,math.max(160,math.floor(1020*sign.Size.Y/sign.Size.X))); gui.LightInfluence=0; gui.MaxDistance=150; gui.Parent=panel
	for i,entry in ipairs({{"Legendary","LENDÁRIA GARANTIDA",Color3.new(1,1,1)},{"Mythic","MÍTICA GARANTIDA",Color3.new(1,1,1)}}) do
		local frame=Instance.new("Frame"); frame.BackgroundColor3=Color3.fromRGB(24,24,28)
		frame.BorderSizePixel=0; frame.Position=UDim2.fromScale(0,(i-1)*.5); frame.Size=UDim2.fromScale(1,.5); frame.Parent=gui
		local label=Instance.new("TextLabel"); label.BackgroundTransparency=1; label.Position=UDim2.fromScale(.08,.04); label.Size=UDim2.fromScale(.84,.60)
		label.Font=Enum.Font.GothamBold; label.TextScaled=true; label.TextColor3=entry[3]; label.Parent=frame
		local bar=Instance.new("Frame"); bar.BorderSizePixel=0; bar.BackgroundColor3=Color3.fromRGB(55,55,60); bar.Position=UDim2.fromScale(.18,.72); bar.Size=UDim2.fromScale(.64,.13); bar.ClipsDescendants=true; bar.Parent=frame
		local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(1,0); corner.Parent=bar
		local fill=Instance.new("Frame"); fill.BorderSizePixel=0; fill.BackgroundColor3=entry[3]; fill.Size=UDim2.fromScale(0,1); fill.Parent=bar
		local fc=corner:Clone(); fc.Parent=fill
		pityRows[entry[1]]={Label=label,Fill=fill,Title=entry[2]}
	end
end
buildPityDisplay()
updatePityDisplay()
local function recordPity(rarity)
	pity.Mythic=rarity.Name=="Mítica" and 0 or math.min(pityLimits.Mythic,pity.Mythic+1)
	pity.Legendary=rarity.Name=="Lendária" and 0 or math.min(pityLimits.Legendary,pity.Legendary+1)
	updatePityDisplay()
end
local function chooseRarity()
	local state = eventStorage:FindFirstChild("EventSystemState")
	local event = state and state:GetAttribute("ActiveEvent") or "None"
	if event ~= lastEvent then lastEvent=event; eventMisses=0 end
	local limit=eventLimits[event]
	local forcePity = pity.Mythic >= pityLimits.Mythic-1 and "Mítica" or (pity.Legendary >= pityLimits.Legendary-1 and "Lendária" or nil)
	local forceEvent=not forcePity and limit and eventMisses >= limit-1
	local forceCommon=not forcePity and not forceEvent and spawnsWithoutCommon >= MAX_WITHOUT_COMMON
	local function weight(rarity)
		if forcePity and rarity.Name ~= forcePity then return 0 end
		if forceEvent and not qualifies(rarity,event) then return 0 end
		if forceCommon and rarity.Name ~= "Comum" then return 0 end
		local factor=1
		if event=="Lucky" and boosted[rarity.Name] then factor=2
		elseif event=="Infernal" and rarity.Id=="Infernal" then factor=8
		elseif event=="Celestial" and rarity.Name=="Secreta" then factor=12 end
		return rarity.Weight*factor
	end
	local total=0
	for _,r in ipairs(RARITIES) do total+=weight(r) end
	local roll=rng:NextNumber(0,total)
	local selected=RARITIES[1]
	for _,r in ipairs(RARITIES) do
		local w=weight(r)
		if w>0 then selected=r; roll-=w; if roll<=0 then break end end
	end
	if limit then
		if qualifies(selected,event) then eventMisses=0 else eventMisses+=1 end
	end
	return selected,forceCommon
end

local function rarityFromName(name, id)
	if id == INFINITY.Id then return INFINITY end
	for _, rarity in ipairs(RARITIES) do
		if (id and rarity.Id == id) or (not id and not rarity.Id and rarity.Name == name) then
			return rarity
		end
	end
	return RARITIES[1]
end

-- PECAS

local function makePart(name, size, cf, color, material, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CastShadow = false
	p.Parent = parent
	return p
end

-- MODELO DA ESPADA

local SwordModels = require(script.Parent:WaitForChild("SwordModels"))
local function createSword(rarity)
	if rarity.Id == "Ancient" then
		local m= SwordModels.Create({Name="Secreta",Id="Aether",Price=rarity.Price,Income=rarity.Income,Color=rarity.Color})
		m.Name="Ancient"; m:SetAttribute("SwordId","Ancient"); m:SetAttribute("Rarity","Ancestral")
		for _,p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then p.Color=p.Material==Enum.Material.Neon and Color3.fromRGB(85,190,235) or Color3.fromRGB(40,65,105) end end
		return m
	end
	if rarity.Id ~= INFINITY.Id then return SwordModels.Create(rarity) end
	local model=Instance.new("Model")
	model.Name="INFINITY"
	model:SetAttribute("Rarity",rarity.Name)
	model:SetAttribute("SwordId",rarity.Id)
	model:SetAttribute("Price",0)
	model:SetAttribute("Income",rarity.Income)
	local gold=Color3.fromRGB(255,200,65)
	local white=Color3.fromRGB(245,250,255)
	local blue=Color3.fromRGB(105,225,255)
	local function piece(name,size,cf,color,material)
		return makePart(name,size,cf,color,material,model)
	end
	local handle=piece("Handle",Vector3.new(.45,1.8,.45),CFrame.new(0,0,0),gold,Enum.Material.Metal)
	model.PrimaryPart=handle
	local function detail(name,size,cf,color,material)
		local part=piece(name,size,cf,color,material)
		local weld=Instance.new("WeldConstraint"); weld.Part0=handle; weld.Part1=part; weld.Parent=part
		return part
	end
	detail("Blade",Vector3.new(1.15,4.8,.32),CFrame.new(0,3.5,0),white,Enum.Material.Metal)
	detail("Tip",Vector3.new(.8,.8,.32),CFrame.new(0,6,0)*CFrame.Angles(0,0,math.rad(45)),white,Enum.Material.Metal)
	detail("Core",Vector3.new(.22,4.5,.38),CFrame.new(0,3.5,0),blue,Enum.Material.Neon)
	detail("Guard",Vector3.new(2.7,.35,.65),CFrame.new(0,1,0),gold,Enum.Material.Metal)
	for _,side in ipairs({-1,1}) do
		detail("Wing",Vector3.new(.35,1.35,.55),CFrame.new(side*1.25,1.45,0)*CFrame.Angles(0,0,math.rad(-side*35)),gold,Enum.Material.Metal)
	end
	detail("Gem",Vector3.new(.65,.65,.7),CFrame.new(0,1,0)*CFrame.Angles(0,0,math.rad(45)),blue,Enum.Material.Neon)
	detail("Pommel",Vector3.new(.7,.45,.7),CFrame.new(0,-1,0),gold,Enum.Material.Metal)
	return model
end

-- V16: mutacoes (somente sorteadas na esteira).
local MUTATIONS = {
	{Name="Normal", Chance=94, Mult=1},
	{Name="Golden", Chance=4, Mult=1.5, Color=Color3.fromRGB(255,195,45)},
	{Name="Diamond", Chance=1.5, Mult=2, Color=Color3.fromRGB(75,220,255)},
	{Name="Rainbow", Chance=0.45, Mult=3, Color=Color3.fromRGB(220,100,255)},
	{Name="Corrupted", Chance=0.05, Mult=5, Color=Color3.fromRGB(135,35,190)},
	{Name="Spiritual", Chance=0, Mult=6, Color=Color3.fromRGB(205,175,255)},
}
local function rollMutation()
	local roll=rng:NextNumber(0,100)
	local sum=0
	for _,m in ipairs(MUTATIONS) do
		sum+=m.Chance
		if roll<sum then return m.Name end
	end
	return "Normal"
end
-- V23.1: efeitos decorativos, sem alterar fisica ou economia.
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local function sparkles(parent, color, rate, size)
	local e=Instance.new("ParticleEmitter")
	e.Name="PolishSparkles"
	e.Texture="rbxasset://textures/particles/sparkles_main.dds"
	e.Color=ColorSequence.new(color)
	e.Rate=rate; e.Lifetime=NumberRange.new(.45,.85)
	e.Speed=NumberRange.new(1,3); e.SpreadAngle=Vector2.new(180,180)
	e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,size),NumberSequenceKeypoint.new(1,0)})
	e.LightEmission=.65; e.Parent=parent
	return e
end
local function burst(position,color,count)
	local p=Instance.new("Part")
	p.Name="PolishBurst"; p.Size=Vector3.new(.2,.2,.2); p.Position=position
	p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false
	p.Transparency=1; p.Parent=Workspace
	local e=sparkles(p,color,0,.45); e:Emit(count)
	Debris:AddItem(p,2)
end
local function celebration(position,color)
	burst(position+Vector3.new(0,2,0),color,32)
	local ring=Instance.new("Part")
	ring.Name="PolishPulse"; ring.Shape=Enum.PartType.Cylinder
	ring.Size=Vector3.new(.12,2,2); ring.CFrame=CFrame.new(position)*CFrame.Angles(0,0,math.pi/2)
	ring.Color=color; ring.Material=Enum.Material.Neon; ring.Transparency=.55
	ring.Anchored=true; ring.CanCollide=false; ring.CanTouch=false; ring.CanQuery=false
	ring.Parent=Workspace
	TweenService:Create(ring,TweenInfo.new(.65,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.new(.12,12,12),Transparency=1}):Play()
	Debris:AddItem(ring,1)
end
local function applyMutation(model, rarity, name)
	local mutation=MUTATIONS[1]
	for _,m in ipairs(MUTATIONS) do if m.Name==name then mutation=m; break end end
	model:SetAttribute("Mutation",mutation.Name)
	model:SetAttribute("Price",rarity.Price)
	model:SetAttribute("Income",math.floor(rarity.Income*mutation.Mult))
	if not mutation.Color then
		local rates={ ["Lendária"]=3, ["Mítica"]=5, Secreta=7, Exclusiva=5 }
		local rate=rates[rarity.Name]
		if rate and model.PrimaryPart then sparkles(model.PrimaryPart,rarity.Color,rate,.28) end
		return model
	end
	for _,part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part~=model.PrimaryPart then
			part.Color=part.Color:Lerp(mutation.Color,0.8)
			if mutation.Name=="Diamond" or mutation.Name=="Corrupted" then part.Material=Enum.Material.Neon end
		end
	end
	local light=Instance.new("PointLight")
	light.Color=mutation.Color; light.Brightness=0.65; light.Range=9; light.Parent=model.PrimaryPart
	local particles=Instance.new("ParticleEmitter")
	particles.Name="MutationParticles"
	particles.Texture="rbxasset://textures/particles/sparkles_main.dds"
	particles.Color=ColorSequence.new(mutation.Color)
	if mutation.Name=="Rainbow" then
		particles.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,70,70)),ColorSequenceKeypoint.new(.33,Color3.fromRGB(80,255,120)),ColorSequenceKeypoint.new(.66,Color3.fromRGB(70,140,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,80,220))})
	end
	particles.Rate=6; particles.Lifetime=NumberRange.new(.5,1); particles.Speed=NumberRange.new(.5,2)
	particles.Size=NumberSequence.new(.25); particles.LightEmission=.8; particles.Parent=model.PrimaryPart
	return model
end
local function displayName(model)
	local m=model:GetAttribute("Mutation")
	return m and m~="Normal" and (m.." "..model.Name) or model.Name
end

-- V13: catalogo compartilhado e descoberta validada no servidor.
local indexFolder = Instance.new("Folder")
indexFolder.Name = "SwordIndexCatalog"
local function indexId(rarity)
	return rarity.Id or rarity.Name
end
for i, rarity in ipairs(RARITIES) do
	local preview = createSword(rarity)
	preview:SetAttribute("IndexId", indexId(rarity))
	preview:SetAttribute("IndexOrder", i)
	preview:SetAttribute("IndexColor", rarity.Color)
	preview.Parent = indexFolder
end
indexFolder.Parent = eventStorage
local infinityPreview = createSword(INFINITY)
infinityPreview.Name = "RebirthInfinityPreview"
infinityPreview.Parent = eventStorage
local function syncIndex(player)
	local discovered = DataSystem.GetDiscovered(player)
	if not discovered then return end
	local folder = player:FindFirstChild("SwordIndex")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "SwordIndex"
		folder.Parent = player
	end
	for _, mutation in ipairs(MUTATIONS) do
		local name=mutation.Name
		local count=0
		for i,rarity in ipairs(RARITIES) do
			local id=indexId(rarity)
			local key=name=="Normal" and id or name..":"..id
			local value=discovered[key]==true
			folder:SetAttribute(name.."_"..i,value)
			if name=="Normal" then folder:SetAttribute("Sword_"..i,value) end
			if value then count+=1 end
		end
		folder:SetAttribute("Count_"..name,count)
		folder:SetAttribute("Claimed_"..name,name=="Normal" and DataSystem.GetIndexRewardClaimed(player)==true or discovered["Reward:"..name]==true)
		if name=="Normal" then folder:SetAttribute("Count",count) end
	end
	folder:SetAttribute("Total",#RARITIES)
	folder:SetAttribute("RewardClaimed",DataSystem.GetIndexRewardClaimed(player)==true)
	folder:SetAttribute("Ready", true)
end
local function discoverModel(player, model)
	local rarity = rarityFromName(model:GetAttribute("Rarity"), model:GetAttribute("SwordId"))
	if rarity.Id ~= INFINITY.Id then
		local mutation=model:GetAttribute("Mutation") or "Normal"
		DataSystem.DiscoverSword(player, mutation=="Normal" and indexId(rarity) or mutation..":"..indexId(rarity))
	end
	syncIndex(player)
end

local function formatSwordMoney(value)
	local n = tonumber(value) or 0
	for _, unit in ipairs({{1e12,"T"},{1e9,"B"},{1e6,"M"},{1e3,"K"}}) do
		if math.abs(n) >= unit[1] then
			local text = string.format("%.2f", n / unit[1]):gsub("0+$", ""):gsub("%.$", "")
			return text .. unit[2]
		end
	end
	return tostring(math.floor(n))
end

local function addSwordLabel(model)
	local old = model.PrimaryPart:FindFirstChild("SwordLabel")
	if old then old:Destroy() end
	local rarity = rarityFromName(model:GetAttribute("Rarity"), model:GetAttribute("SwordId"))
	local gui = Instance.new("BillboardGui")
	gui.Name = "SwordLabel"
	gui.Size = UDim2.new(9,0,3.8,0)
	-- V23.2: posiciona o texto acima da ponta, usando a altura real do modelo.
	local handle = model.PrimaryPart
	local top = 0
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			local relative = handle.CFrame:ToObjectSpace(part.CFrame)
			local half = part.Size * .5
			local extent = math.abs(relative.RightVector.Y)*half.X
				+ math.abs(relative.UpVector.Y)*half.Y
				+ math.abs(relative.LookVector.Y)*half.Z
			top = math.max(top, relative.Position.Y + extent)
		end
	end
	-- A metade do painel mede 1.9 studs; deixa mais .6 de folga.
	gui.StudsOffsetWorldSpace = Vector3.new(0, top + 2.5, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 40
	gui.Parent = model.PrimaryPart
	local mutation = model:GetAttribute("Mutation") or "Normal"
	local function line(name,text,y,h,color,maxSize)
		local label = Instance.new("TextLabel")
		label.Name=name; label.Text=text
		label.Size=UDim2.fromScale(1,h); label.Position=UDim2.fromScale(0,y)
		label.BackgroundTransparency=1; label.TextColor3=color
		label.Font=Enum.Font.FredokaOne; label.TextScaled=true
		label.TextStrokeColor3=Color3.fromRGB(18,23,34); label.TextStrokeTransparency=.35
		label.Parent=gui
		local limit=Instance.new("UITextSizeConstraint"); limit.MaxTextSize=maxSize; limit.MinTextSize=1; limit.Parent=label
	end
	local colors={Golden=Color3.fromRGB(255,207,64),Diamond=Color3.fromRGB(100,230,255),Rainbow=Color3.fromRGB(235,130,255),Corrupted=Color3.fromRGB(190,95,255)}
	if mutation~="Normal" then line("Mutation",string.upper(mutation),0,.2,colors[mutation] or rarity.Color,18) end
	line("SwordName",model.Name,.2,.34,Color3.new(1,1,1),26)
	line("Rarity",rarity.Name,.54,.21,rarity.Color,17)
	local income="+$"..formatSwordMoney(model:GetAttribute("Income") or 0).."/s"
	local deliveryPrice = model:GetAttribute("DeliveryPrice")
	if type(deliveryPrice)=="number" then
		income="$"..formatSwordMoney(deliveryPrice).."  |  "..income
	elseif model.Parent==arenaSwords then
		income="$"..formatSwordMoney(model:GetAttribute("Price") or rarity.Price).."  |  "..income
	end
	line("Income",income,.75,.25,Color3.fromRGB(115,255,145),19)
end

-- BASES

local function getPlayerBase(player)
	for _, base in ipairs(basesFolder:GetChildren()) do
		if base:IsA("Model")
			and base:GetAttribute("OwnerUserId") == player.UserId then
			return base
		end
	end
	return nil
end

-- V17: geometria de evolucao, antes de restaurar espadas.
local function evolveBase(base, level)
	level = math.clamp(math.floor(level), 0, 10)
	if base:GetAttribute("EvolutionBuilt") == level and base:GetAttribute("StairLayoutVersion") == 46 then return end
	local floor = base:FindFirstChild("Floor")
	local stands = base:FindFirstChild("SwordStands")
	if not floor or not stands then return end
	local cf = floor.CFrame * CFrame.new(0,-0.5,0)
	local old = base:FindFirstChild("Evolution")
	if old then old:Destroy() end
	for _, p in ipairs(stands:GetChildren()) do
		if p:GetAttribute("EvolutionStand") then
			occupiedStands[p] = nil
			p:Destroy()
		end
	end
	local group = Instance.new("Folder")
	group.Name = "Evolution"; group.Parent = base
	local dark = Color3.fromRGB(38,48,65)
	local gold = Color3.fromRGB(255,198,45)
	local wall = Color3.fromRGB(67,82,105)
	local trim = Color3.fromRGB(235,240,248)
	local pale = Color3.fromRGB(215,222,232)
	local metal = Color3.fromRGB(100,115,135)
	local glass = Color3.fromRGB(140,210,245)
	local function build(name,size,x,y,z,color,parent)
		local p = makePart(name,size,cf*CFrame.new(x,y,z),color,Enum.Material.SmoothPlastic,parent or group)
		p.CanCollide = true; p.CanTouch = true; p.CastShadow = true
		return p
	end
	local function detail(name,size,x,y,z,color,parent)
		local p=build(name,size,x,y,z,color,parent)
		p.CanCollide=false; p.CanTouch=false; p.CanQuery=false
		return p
	end
	local function stand(name,x,y,z)
		local p=build(name,Vector3.new(8,.5,6),x,y,z,dark,stands)
		p.Transparency=1
		p:SetAttribute("EvolutionStand",true)
		local a=Instance.new("Attachment"); a.Name="SwordPoint"; a.Position=Vector3.new(0,3,0); a.Parent=p
		detail("DisplayBase",Vector3.new(8,.45,4.8),x,y,z,dark,p)
		detail("DisplayGold",Vector3.new(7.6,.15,4.4),x,y+.30,z,gold,p)
		detail("DisplayTop",Vector3.new(7.1,.18,3.9),x,y+.45,z,wall,p)
		detail("DisplayPedestal",Vector3.new(3.4,.65,3.4),x,y+.83,z,dark,p)
		detail("DisplayCap",Vector3.new(3,.16,3),x,y+1.23,z,metal,p)
	end
	local roof=base:FindFirstChild("RoofCenter")
	for _,p in ipairs(base:GetChildren()) do
		if p.Name=="InteriorLamp" and p:IsA("BasePart") and cf:PointToObjectSpace(p.Position).Z>=0 then
			p.Transparency=level>=1 and 1 or 0
			for _,l in ipairs(p:GetChildren()) do if l:IsA("SurfaceLight") then l.Enabled=level<1 end end
		end
	end
	if roof then roof.Transparency=level>=1 and 1 or 0; roof.CanCollide=level<1; roof.CanQuery=level<1 end
	if level>=1 then
		for _,side in ipairs({-1,1}) do
			build("UpperFloorSide",Vector3.new(34,1,44),side*22,17,0,pale)
			-- Painel continuo de vidro com colisao, sem frestas.
			build("UpperSill",Vector3.new(2,4,62),side*38,19.5,0,wall)
			build("UpperHeader",Vector3.new(2,4,62),side*38,31.5,0,wall)
			local pane=build("UpperWindow",Vector3.new(1,8,62),side*38,25.5,0,glass)
			pane.Material=Enum.Material.Glass; pane.Transparency=.45
			for z=-30,30,15 do
				build("UpperFrame",Vector3.new(2.2,8,1.2),side*38,25.5,z,trim)
			end
			detail("UpperTrim",Vector3.new(2.5,.5,62),side*38,29.5,0,trim)
		end
		build("UpperFloorFront",Vector3.new(10,1,22),0,17,-11,pale)
		-- Acabamento sobre as faixas fixas do teto, sem bloquear a escada.
		for _,z in ipairs({-27,27}) do detail("LandingFinish",Vector3.new(76,.06,10),0,17.54,z,pale) end
		for i=1,22 do
			local h=16.5*i/22
			build("Step",Vector3.new(8,h,1),0,1+h/2,i-.5,dark)
			detail("StepTread",Vector3.new(8,.08,1),0,1+h+.04,i-.5,pale)
		end
		for _,side in ipairs({-1,1}) do
			build("StairRail",Vector3.new(.5,3,22),side*5,19,11,wall)
			detail("RailCap",Vector3.new(.7,.2,22),side*5,20.6,11,trim)
		end
		if level<6 then build("StairOpeningGuard",Vector3.new(10,3,.5),0,19,0,wall) end
		build("UpperBack",Vector3.new(78,16,2),0,25.5,32,wall)
		-- Fachada frontal envidracada, com colisao continua.
		build("UpperFrontSill",Vector3.new(78,4,2),0,19.5,-32,wall)
		build("UpperFrontHeader",Vector3.new(78,4,2),0,31.5,-32,wall)
		local frontGlass=build("UpperFrontWindow",Vector3.new(78,8,1),0,25.5,-32,glass)
		frontGlass.Material=Enum.Material.Glass; frontGlass.Transparency=.45
		for _,x in ipairs({-37,-25,-12.5,0,12.5,25,37}) do
			build("UpperFrontFrame",Vector3.new(1.2,8,2.2),x,25.5,-32,trim)
		end
		detail("UpperFrontTrim",Vector3.new(78,.5,2.5),0,29.5,-32,trim)
		if level<6 then
			build("UpperRoof",Vector3.new(78,1,66),0,34,0,dark)
		else
			-- Terceiro andar: abertura central para escada, piso continuo nas laterais.
			for _,side in ipairs({-1,1}) do
				build("ThirdFloorSide",Vector3.new(34,1,64),side*22,34,0,pale)
				build("ThirdSill",Vector3.new(2,4,62),side*38,36.5,0,wall)
				build("ThirdHeader",Vector3.new(2,4,62),side*38,48.5,0,wall)
				local pane=build("ThirdWindow",Vector3.new(1,8,62),side*38,42.5,0,glass)
				pane.Material=Enum.Material.Glass; pane.Transparency=.45
				for z=-30,30,15 do build("ThirdFrame",Vector3.new(2.2,8,1.2),side*38,42.5,z,trim) end
				build("ThirdRail",Vector3.new(.5,3,42),side*5,36,-3,wall)
			end
			-- V46: escada independente, entrada na frente e desembarque atras.
			build("ThirdFloorRear",Vector3.new(10,1,14),0,34,25,pale)
			build("ThirdLanding",Vector3.new(10,1,8),0,34,-28,pale)
			-- 28 degraus: subida de 17 studs em 42 studs de percurso.
			for i=1,28 do
				local h=17*i/28
				local z=-24+(i-.5)*1.5
				build("ThirdStep",Vector3.new(9,.65,1.5),0,17.5+h-.325,z,dark)
				detail("ThirdTread",Vector3.new(9,.08,1.5),0,17.5+h+.04,z,pale)
				for _,side in ipairs({-1,1}) do
					build("ThirdStairRail",Vector3.new(.25,2.5,1.5),side*4.65,17.5+h+1.25,z,wall)
				end
			end
			-- Protege a abertura da escada inferior sem bloquear a nova subida.
			build("StairOpeningGuard",Vector3.new(10,3,.5),0,19,0,wall)
			build("ThirdBack",Vector3.new(78,16,2),0,42.5,32,wall)
			build("ThirdFrontSill",Vector3.new(78,4,2),0,36.5,-32,wall)
			build("ThirdFrontHeader",Vector3.new(78,4,2),0,48.5,-32,wall)
			local pane=build("ThirdFrontWindow",Vector3.new(78,8,1),0,42.5,-32,glass)
			pane.Material=Enum.Material.Glass; pane.Transparency=.45
			for _,x in ipairs({-37,-25,-12.5,0,12.5,25,37}) do build("ThirdFrontFrame",Vector3.new(1.2,8,2.2),x,42.5,-32,trim) end
			build("ThirdRoof",Vector3.new(78,1,66),0,51,0,dark)
			for _,z in ipairs({-16,16}) do
				local lamp=detail("ThirdLamp",Vector3.new(12,.3,2),0,50.2,z,trim)
				local light=Instance.new("SurfaceLight"); light.Face=Enum.NormalId.Bottom; light.Range=28; light.Brightness=.9; light.Angle=120; light.Parent=lamp
			end
			local slots={{-27,-20},{27,-20},{-27,-10},{27,-10},{-27,0},{27,0},{-27,10},{27,10},{-27,20},{27,20}}
			for n=1,(level-4) do local pos=slots[n]; stand("Stand_5_"..n,pos[1],34.75,pos[2]) end
		end
		for _,z in ipairs({-16,16}) do
			local lamp=detail("UpperLamp",Vector3.new(12,.3,2),(level>=6 and 20 or 0),33.2,z,trim)
			local light=Instance.new("SurfaceLight"); light.Face=Enum.NormalId.Bottom; light.Range=28; light.Brightness=.9; light.Angle=120; light.Parent=lamp
		end
		-- Preserve os nomes antigos para restaurar saves sem perder espadas.
		local positions = {{-27,-18},{27,-18},{-27,0},{27,0},
			{-27,18},{27,18}}
		local count=math.min(level+1,6)
		for n=1,count do
			local pos=positions[n]
			local name=n<=4 and ("Stand_3_"..n) or ("Stand_4_"..(n-4))
			stand(name,pos[1],17.75,pos[2])
		end

	end
	base:SetAttribute("BaseLevel",level)
	base:SetAttribute("StandCapacity",10+(level>0 and math.min(level+1,6) or 0)+(level>=6 and level-4 or 0))
	base:SetAttribute("EvolutionBuilt",level)
	base:SetAttribute("StairLayoutVersion",46)
end

local function getStands(base)
	local folder = base:FindFirstChild("SwordStands")
	if not folder then return {} end

	local stands = {}

	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("BasePart")
			and child.Name:match("^Stand_%d+_%d+$") then
			table.insert(stands, child)
		end
	end

	table.sort(stands, function(a, b)
		return a.Name < b.Name
	end)

	return stands
end

local function findFreeStand(base)
	for _, stand in ipairs(getStands(base)) do
		if not occupiedStands[stand] then
			return stand
		end
	end
	return nil
end

local function isInsideBase(player, base)
	local character = player.Character
	if not character then return false end

	local root = character:FindFirstChild("HumanoidRootPart")
	local floor = base:FindFirstChild("Floor")

	if not root or not floor then return false end

	local pos = floor.CFrame:PointToObjectSpace(root.Position)

	return math.abs(pos.X) <= floor.Size.X / 2
		and math.abs(pos.Z) <= floor.Size.Z / 2
		and pos.Y >= 0
		and pos.Y <= ((base:GetAttribute("BaseLevel") or 0) >= 6 and 51 or ((base:GetAttribute("BaseLevel") or 0) >= 1 and 34 or 16))
end

local function isAlive(player)
	local character = player.Character
	if not character then return false end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")

	return humanoid ~= nil
		and root ~= nil
		and humanoid.Health > 0
end

local function isNearSword(player, model, distance)
	if not isAlive(player) then return false end
	if not model.PrimaryPart then return false end

	local root = player.Character.HumanoidRootPart

	return (root.Position - model.PrimaryPart.Position).Magnitude
		<= distance + 2
end

-- PREPARAR TRANSPORTE

local function setSwordAnchored(model, anchored)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = anchored
			descendant.CanCollide = false
			descendant.Massless = true

			if anchored then
				descendant.AssemblyLinearVelocity = Vector3.zero
				descendant.AssemblyAngularVelocity = Vector3.zero
			end
		end
	end
end

local function removePrompt(model)
	local handle = model.PrimaryPart
	if not handle then return end

	for _, name in ipairs({"SwordPrompt", "SellPrompt", "MoveSwordPrompt"}) do
		local prompt = handle:FindFirstChild(name)
		if prompt then prompt:Destroy() end
	end
end

local function removeCarryWeld(model)
	local handle = model.PrimaryPart
	if not handle then return end

	local weld = handle:FindFirstChild("CarryWeld")
	if weld then
		weld:Destroy()
	end
end

local function startCarrying(player, model, stolen)
	if carrying[player] then return false end
	if not isAlive(player) then return false end

	local root = player.Character.HumanoidRootPart
	local handle = model.PrimaryPart
	if not handle then return false end

	carrying[player] = model

	removePrompt(model)
	removeCarryWeld(model)

	model.Parent = carriedSwords
	addSwordLabel(model)

	-- Primeiro posiciona o modelo; depois desancora e solda.
	model:PivotTo(
		root.CFrame
			* CFrame.new(0, 1.5, 2.2)
			* CFrame.Angles(0, 0, math.rad(-25))
	)

	setSwordAnchored(model, false)

	local carryWeld = Instance.new("WeldConstraint")
	carryWeld.Name = "CarryWeld"
	carryWeld.Part0 = root
	carryWeld.Part1 = handle
	carryWeld.Parent = handle

	model:SetAttribute("CarrierUserId", player.UserId)
	model:SetAttribute("IsStolen", stolen)

	return true
end

-- DECLARACOES PARA PROMPTS
local collectSword
local stealSword

local function createPrompt(model, action, callback, distance)
	removePrompt(model)

	local handle = model.PrimaryPart
	if not handle then return end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SwordPrompt"
	prompt:SetAttribute("SwordAction", action)
	prompt.ActionText = action
	prompt.ObjectText = displayName(model)
	if action == "Comprar espada" then
		prompt.ObjectText = displayName(model) .. " - $" .. formatSwordMoney(model:GetAttribute("Price"))
	end
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = distance
	prompt.RequiresLineOfSight = true
	prompt.Parent = handle

	prompt.Triggered:Connect(function(player)
		callback(player, model)
	end)
end

-- V18: venda validada no servidor, confirmacao em duas interacoes.
local pendingSales = {}
local selling = {}
local function sellOwned(player, model, base, stand)
	if not ready[player] or carrying[player] or selling[model] then return false, "Venda indisponivel." end
	if model.Parent ~= storedSwords or occupiedStands[stand] ~= model or model:GetAttribute("SwordId") == INFINITY.Id then return false, "Espada indisponivel." end
	if base:GetAttribute("OwnerUserId") ~= player.UserId or model:GetAttribute("OwnerUserId") ~= player.UserId then return false, "Sem permissao." end
	local stats=player:FindFirstChild("leaderstats"); local cash=stats and stats:FindFirstChild("Cash")
	if not cash or not cash:IsA("IntValue") then return false, "Saldo indisponivel." end
	local payout=script.Parent:FindFirstChild("MoneySystem"); payout=payout and payout:FindFirstChild("CollectOnSale")
	if not payout or not payout:IsA("BindableFunction") then return false, "Coletor indisponivel." end
	selling[model]=true
	local refund=math.floor((model:GetAttribute("Price") or 0)/2)
	local ok,paid=pcall(function() return payout:Invoke(player,base,stand,model) end)
	if not ok or not paid then selling[model]=nil; return false,"Falha ao coletar." end
	if model.Parent~=storedSwords or occupiedStands[stand]~=model or model:GetAttribute("OwnerUserId")~=player.UserId then selling[model]=nil; return false,"Espada indisponivel." end
	pendingSales[player]=nil; occupiedStands[stand]=nil; model:Destroy(); selling[model]=nil
	cash.Value += refund; refreshSave(player)
	return true,"Espada vendida!"
end
local menuSale=Instance.new("RemoteFunction")
menuSale.Name="SellSwordFromMenu"
menuSale.OnServerInvoke=function(player,model)
	if typeof(model)~="Instance" or not model:IsA("Model") or model.Parent~=storedSwords then return false,"Espada indisponivel." end
	local base=getPlayerBase(player); local stands=base and base:FindFirstChild("SwordStands")
	local name=model:GetAttribute("StandName"); local stand=stands and type(name)=="string" and stands:FindFirstChild(name)
	if not stand then return false,"Expositor indisponivel." end
	return sellOwned(player,model,base,stand)
end
menuSale.Parent=game:GetService("ReplicatedStorage")
local function createSellPrompt(model, base, stand)
	if model:GetAttribute("SwordId") == INFINITY.Id then return end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SellPrompt"
	prompt:SetAttribute("SwordAction", "Vender espada")
	prompt.ActionText = "Vender espada"
	local refund = math.floor((model:GetAttribute("Price") or 0) / 2)
	prompt.ObjectText = displayName(model) .. " - $" .. formatSwordMoney(refund)
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonY
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = CONFIG.StealDistance
	prompt.RequiresLineOfSight = true
	prompt.UIOffset = Vector2.new(0, 65)
	prompt.Parent = model.PrimaryPart
	local serial = 0
	prompt.Triggered:Connect(function(player)
		if not ready[player] or carrying[player] then return end
		if model.Parent ~= storedSwords or occupiedStands[stand] ~= model then return end
		if base:GetAttribute("OwnerUserId") ~= player.UserId or model:GetAttribute("OwnerUserId") ~= player.UserId then return end
		if not isInsideBase(player, base) or not isNearSword(player, model, CONFIG.StealDistance) then return end
		local stats = player:FindFirstChild("leaderstats")
		local cash = stats and stats:FindFirstChild("Cash")
		if not cash or not cash:IsA("IntValue") then return end
		local pending = pendingSales[player]
		if not pending or pending.Model ~= model or os.clock() > pending.Expires then
			pendingSales[player] = {Model=model, Expires=os.clock()+5}
			serial += 1
			local token = serial
			prompt.ActionText = "Confirmar venda"
			task.delay(5, function()
				if prompt.Parent and serial == token then prompt.ActionText = "Vender espada" end
				if pendingSales[player] and pendingSales[player].Model == model and os.clock() >= pendingSales[player].Expires then pendingSales[player] = nil end
			end)
			return
		end
		sellOwned(player, model, base, stand)
	end)
end
Players.PlayerRemoving:Connect(function(player) pendingSales[player] = nil end)

-- GUARDAR NO EXPOSITOR

local beginMove
local function placeOnStand(model, base, stand)
	removeCarryWeld(model)
	setSwordAnchored(model, true)

	local point = stand:FindFirstChild("SwordPoint")
	local targetCF

	if point and point:IsA("Attachment") then
		targetCF = point.WorldCFrame
	else
		targetCF = stand.CFrame * CFrame.new(0, 3, 0)
	end

	model.Parent = storedSwords
	addSwordLabel(model)
	-- V21.7: face larga (+Z do modelo) voltada para o corredor.
	local floor = base:FindFirstChild("Floor")
	if floor and floor:IsA("BasePart") then
		local localPos = floor.CFrame:PointToObjectSpace(targetCF.Position)
		local side = localPos.X >= 0 and 1 or -1
		local outward = floor.CFrame.RightVector * side
		-- LookVector aponta para -Z; +Z da lamina aponta para dentro.
		targetCF = CFrame.lookAt(targetCF.Position, targetCF.Position + outward, Vector3.yAxis)
	end
	model:PivotTo(targetCF)

	occupiedStands[stand] = model

	model:SetAttribute("OwnerUserId", base:GetAttribute("OwnerUserId"))
	model:SetAttribute("BaseName", base.Name)
	model:SetAttribute("StandName", stand.Name)
	model:SetAttribute("CarrierUserId", nil)
	model:SetAttribute("IsStolen", false)

	createPrompt(
		model,
		"Roubar espada",
		function(player, sword)
			stealSword(player, sword)
		end,
		CONFIG.StealDistance
	)
	createSellPrompt(model, base, stand)
	local prompt=Instance.new("ProximityPrompt")
	prompt.Name="MoveSwordPrompt"; prompt.ActionText="Mover espada"; prompt.ObjectText=displayName(model)
	prompt.KeyboardKeyCode=Enum.KeyCode.R; prompt.GamepadKeyCode=Enum.KeyCode.ButtonX
	prompt.HoldDuration=.3; prompt.MaxActivationDistance=CONFIG.StealDistance; prompt.RequiresLineOfSight=false
	prompt.UIOffset=Vector2.new(0,130); prompt.Parent=model.PrimaryPart
	prompt.Triggered:Connect(function(player) if beginMove then beginMove(player,model,base,stand) end end)
end

-- V38.6: reorganizacao com reserva do expositor original.
local movePrompts={}
local function clearMovePrompts(player)
	for _,p in ipairs(movePrompts[player] or {}) do p:Destroy() end
	movePrompts[player]=nil
	player:SetAttribute("MovingOwnSword",false)
end
local function collectMove(player,base,stand,model)
	local ms=script.Parent:FindFirstChild("MoneySystem")
	local payout=ms and ms:FindFirstChild("CollectOnSale")
	if not payout then return false end
	local ok,result=pcall(function() return payout:Invoke(player,base,stand,model) end)
	return ok and result==true
end
beginMove=function(player,model,base,stand)
	if not ready[player] or carrying[player] or selling[model] or not isAlive(player) then return end
	if getPlayerBase(player)~=base or base:GetAttribute("OwnerUserId")~=player.UserId or model:GetAttribute("OwnerUserId")~=player.UserId then return end
	if model.Parent~=storedSwords or occupiedStands[stand]~=model or not isInsideBase(player,base) or not isNearSword(player,model,CONFIG.StealDistance) then return end
	selling[model]=true
	local paid=collectMove(player,base,stand,model)
	selling[model]=nil
	if not paid or not ready[player] or carrying[player] or model.Parent~=storedSwords or occupiedStands[stand]~=model then return end
	swordOrigins[model]={Base=base,Stand=stand,OwnerUserId=player.UserId,MovingOwn=true}
	if not startCarrying(player,model,false) then swordOrigins[model]=nil; return end
	player:SetAttribute("MovingOwnSword",true)
	movePrompts[player]={}
	for _,target in ipairs(getStands(base)) do
		local p=Instance.new("ProximityPrompt"); p.Name="PlaceMovedSwordPrompt"; p.ActionText="Colocar / trocar espada"; p.ObjectText=target.Name
		p.KeyboardKeyCode=Enum.KeyCode.E; p.HoldDuration=.3; p.MaxActivationDistance=8; p.RequiresLineOfSight=false
		p:SetAttribute("MoveOwner",player.UserId); p.Parent=target; table.insert(movePrompts[player],p)
		p.Triggered:Connect(function(who)
			if who~=player or carrying[player]~=model or not ready[player] or not isAlive(player) or not isInsideBase(player,base) or getPlayerBase(player)~=base then return end
			local root=player.Character:FindFirstChild("HumanoidRootPart")
			if not root or not target.Parent or (root.Position-target.Position).Magnitude>10 then return end
			local origin=swordOrigins[model]; if not origin or not origin.MovingOwn or occupiedStands[stand]~=model then return end
			local other=occupiedStands[target]
			if other and other~=model then
				if other.Parent~=storedSwords or other:GetAttribute("OwnerUserId")~=player.UserId or selling[other] then return end
				selling[other]=true; local ok=collectMove(player,base,target,other); selling[other]=nil
				if not ok or carrying[player]~=model or occupiedStands[target]~=other or other.Parent~=storedSwords then return end
			end
			carrying[player]=nil; swordOrigins[model]=nil; occupiedStands[stand]=nil
			clearMovePrompts(player)
			if other and other~=model then placeOnStand(other,base,stand) end
			placeOnStand(model,base,target); refreshSave(player)
		end)
	end
	refreshSave(player)
end

-- PEGAR ESPADA DA ARENA

-- V38.3: disputas com preco fixo sem reembolso ao comprador anterior.
local deliveries = {}
local deliveryFolder = getFolder("DeliveringSwords")
local function cashOf(player)
	local stats=player:FindFirstChild("leaderstats")
	return stats and stats:FindFirstChild("Cash")
end
local function cancelDelivery(model, refund)
	local d=deliveries[model]; if not d then return end
	deliveries[model]=nil
	if occupiedStands[d.Stand]==model then occupiedStands[d.Stand]=nil end
	if refund then local cash=cashOf(d.Player); if cash then cash.Value+=d.Price end end
	model:Destroy()
end
local function routeDelivery(model, base)
	local cf=base.Floor.CFrame*CFrame.new(0,-.5,0)
	return {cf:PointToWorldSpace(Vector3.new(0,4.25,-35))}
end
local function purchaseNotice(player, message)
	local pg=player:FindFirstChildOfClass("PlayerGui")
	if not pg then return end
	local old=pg:FindFirstChild("PurchaseNotice")
	if old then old:Destroy() end
	local gui=Instance.new("ScreenGui"); gui.Name="PurchaseNotice"; gui.ResetOnSpawn=false; gui.DisplayOrder=50; gui.Parent=pg
	local label=Instance.new("TextLabel"); label.AnchorPoint=Vector2.new(.5,0); label.Position=UDim2.fromScale(.5,.24); label.Size=UDim2.new(.85,0,0,44); label.BackgroundColor3=Color3.fromRGB(40,48,65); label.TextColor3=Color3.new(1,1,1); label.Font=Enum.Font.FredokaOne; label.TextSize=19; label.TextWrapped=true; label.Text=message; label.Parent=gui
	local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,10); corner.Parent=label
	local limit=Instance.new("UISizeConstraint"); limit.MaxSize=Vector2.new(420,44); limit.Parent=label
	task.delay(3,function() gui:Destroy() end)
end
collectSword = function(player, model)
	if not ready[player] or not isAlive(player) or carrying[player] then return end
	local old=deliveries[model]
	if model.Parent~=arenaSwords and not old then return end
	if old and old.Player==player then return end
	if not isNearSword(player,model,CONFIG.CollectDistance) then return end
	local base=getPlayerBase(player); if not base then return end
	local stand=findFreeStand(base); if not stand then purchaseNotice(player,"Sua base está cheia! Libere um expositor."); return end
	local cash=cashOf(player); if not cash or not cash:IsA("IntValue") then return end
	local price=old and old.Price or (model:GetAttribute("Price") or 0)
	if price>9000000000000000 or cash.Value<price then return end
	cash.Value-=price
	if old then
		-- O comprador anterior perde o valor pago ao perder a disputa.
		if occupiedStands[old.Stand]==model then occupiedStands[old.Stand]=nil end
	end
	occupiedStands[stand]=model
	moving[model]=nil
	model.Parent=deliveryFolder
	setSwordAnchored(model,true)
	local points=routeDelivery(model,base)
	deliveries[model]={Player=player,Base=base,Stand=stand,Price=price,Points=points,Index=1}
	model:SetAttribute("DeliveryBuyer",player.UserId)
	model:SetAttribute("DeliveryPrice",price)
	addSwordLabel(model)
	createPrompt(model,"Disputar compra",collectSword,CONFIG.CollectDistance)
	local prompt=model.PrimaryPart:FindFirstChild("SwordPrompt")
	if prompt then prompt.ObjectText=displayName(model).." - $"..formatSwordMoney(price) end
	burst(model.PrimaryPart.Position,Color3.fromRGB(100,255,155),12)
end
RunService.Heartbeat:Connect(function(dt)
	for model,d in pairs(deliveries) do
		if not model.Parent or d.Base:GetAttribute("OwnerUserId")~=d.Player.UserId or not d.Stand.Parent or not ready[d.Player] then
			cancelDelivery(model,true)
		else
			local target=d.Points[d.Index]
			if not target then
				if occupiedStands[d.Stand]~=model then
					local free=findFreeStand(d.Base)
					if not free then purchaseNotice(d.Player,"Sua base está cheia! Compra reembolsada."); cancelDelivery(model,true); continue end
					d.Stand=free; occupiedStands[free]=model
				end
				deliveries[model]=nil
				model:SetAttribute("DeliveryBuyer",nil); model:SetAttribute("DeliveryPrice",nil)
				placeOnStand(model,d.Base,d.Stand)
				discoverModel(d.Player,model); refreshSave(d.Player)
				Rewards.Record(d.Player,"Buy",1)
				celebration(d.Stand.Position+Vector3.new(0,.5,0),rarityFromName(model:GetAttribute("Rarity"),model:GetAttribute("SwordId")).Color)
			else
				local pivot=model:GetPivot(); local delta=target-pivot.Position
				local distance=delta.Magnitude; local step=math.min(dt*14,distance)
				if distance<=step+.001 then
					model:PivotTo(CFrame.new(target)*pivot.Rotation)
					d.Index+=1
				else
					model:PivotTo(CFrame.new(pivot.Position+delta.Unit*step)*pivot.Rotation)
				end
			end
		end
	end
end)

-- ROUBAR ESPADA DE OUTRA BASE

stealSword = function(player, model)
	if not ready[player] then return end
	if model.Parent ~= storedSwords or selling[model] then return end
	if carrying[player] then return end

	local playerBase = getPlayerBase(player)
	if not playerBase then return end

	-- Precisa ter onde guardar.
	if not findFreeStand(playerBase) then
		return
	end

	local originalBaseName = model:GetAttribute("BaseName")
	local originalStandName = model:GetAttribute("StandName")

	if not originalBaseName or not originalStandName then
		return
	end

	local originalBase = basesFolder:FindFirstChild(originalBaseName)
	if not originalBase then return end

	local originalOwner = originalBase:GetAttribute("OwnerUserId")

	if not originalOwner then return end
	if originalOwner == player.UserId then return end
	local victim = Players:GetPlayerByUserId(originalOwner)
	if not victim or not ready[victim] then return end

	-- Os lasers bloqueiam a entrada; quem ja esta dentro pode roubar.

	-- Precisa realmente estar dentro da base.
	if not isInsideBase(player, originalBase) then
		return
	end

	if not isNearSword(player, model, CONFIG.StealDistance) then
		return
	end

	local standsFolder = originalBase:FindFirstChild("SwordStands")
	if not standsFolder then return end

	local originalStand = standsFolder:FindFirstChild(originalStandName)
	if not originalStand then return end

	if occupiedStands[originalStand] ~= model then
		return
	end

	-- Reserva o expositor ate o roubo terminar.

	swordOrigins[model] = {
		Base = originalBase,
		Stand = originalStand,
		OwnerUserId = originalOwner,
	}

	local success = startCarrying(player, model, true)

	if not success then
		occupiedStands[originalStand] = model
		swordOrigins[model] = nil
		return
	end

	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local speed = player:GetAttribute("SpeedCoilEquipped") and 30 or 20
		local applied = 15
		carrySpeeds[player] = {Humanoid=humanoid, Original=speed, Applied=applied}
		humanoid.WalkSpeed = applied
		player:SetAttribute("CarryingStolen", true)
	end
	theftNotice(victim, player.Name .. " esta roubando sua espada " .. model.Name .. "!")
	theftNotice(player, "Leve " .. model.Name .. " para sua base!")
	-- V39.2: recuperacao manual removida; apenas RecoverWithBat.

	print(
		"[SwordSystem V18]",
		player.Name,
		"roubou",
		model.Name,
		"de",
		originalBase.Name
	)
end

-- DEVOLVER ESPADA ROUBADA

local function returnStolenSword(model)
	local origin = swordOrigins[model]
	swordOrigins[model] = nil

	if not origin then
		model:Destroy()
		return
	end

	local base = origin.Base
	local stand = origin.Stand

	if not base.Parent
		or base:GetAttribute("OwnerUserId") ~= origin.OwnerUserId then
		model:Destroy()
		return
	end

	-- Se o expositor original foi ocupado, tenta outro.
	if not stand.Parent or (occupiedStands[stand] and occupiedStands[stand] ~= model) then
		stand = findFreeStand(base)
	end

	if not stand then
		model:Destroy()
		return
	end

	placeOnStand(model, base, stand)

	local owner = Players:GetPlayerByUserId(origin.OwnerUserId)
	if owner and refreshSave then refreshSave(owner) end
	print("[SwordSystem V18] Espada roubada devolvida.")
end

-- MORTE OU SAIDA

clearCarry = function(player)
	local model = carrying[player]
	carrying[player] = nil
	restoreSpeed(player)

	if not model or not model.Parent then
		return
	end

	removeCarryWeld(model)

	if model:GetAttribute("IsStolen") or (swordOrigins[model] and swordOrigins[model].MovingOwn) then
		clearMovePrompts(player)
		returnStolenSword(model)
	else
		model:Destroy()
	end
end

-- DEPOSITAR ESPADA NA BASE

local function depositSword(player)
	if player:GetAttribute("MovingOwnSword") then return end
	if not ready[player] then return end
	local model = carrying[player]
	if not model or not model.Parent then
		carrying[player] = nil
		restoreSpeed(player)
		return
	end

	if not isAlive(player) then return end

	local base = getPlayerBase(player)
	if not base then return end

	if not isInsideBase(player, base) then
		return
	end

	local stand = findFreeStand(base)
	if not stand then return end

	local origin = swordOrigins[model]
	carrying[player] = nil
	restoreSpeed(player)
	swordOrigins[model] = nil
	if origin and occupiedStands[origin.Stand] == model then
		occupiedStands[origin.Stand] = nil
	end

	placeOnStand(model, base, stand)
	celebration(stand.Position+Vector3.new(0,.5,0),rarityFromName(model:GetAttribute("Rarity"),model:GetAttribute("SwordId")).Color)
	discoverModel(player, model)
	refreshSave(player)
	if origin then
		Rewards.Record(player,"Steal",1)
		local victim = Players:GetPlayerByUserId(origin.OwnerUserId)
		if victim then refreshSave(victim); theftNotice(victim, "Sua espada foi roubada!") end
		theftNotice(player, "Roubo concluido: " .. model.Name .. "!")
	end

	print(
		"[SwordSystem V18]",
		player.Name,
		"guardou",
		model.Name,
		"em",
		base.Name
	)
end

-- GERAR ESPADA NA ARENA

local function announceSecret(model)
	local name=displayName(model)
	local accent=Color3.fromRGB(184,139,255)
	for _,player in ipairs(Players:GetPlayers()) do
		local pg=player:FindFirstChildOfClass("PlayerGui")
		if not pg then continue end
		local old=pg:FindFirstChild("SecretAnnouncement")
		if old then old:Destroy() end
		local gui=Instance.new("ScreenGui")
		gui.Name="SecretAnnouncement"; gui.ResetOnSpawn=false; gui.DisplayOrder=35; gui.Parent=pg
		local card=Instance.new("CanvasGroup")
		card.AnchorPoint=Vector2.new(.5,0); card.Position=UDim2.new(.5,0,0,48)
		card.Size=UDim2.new(.86,0,0,88); card.BackgroundColor3=Color3.fromRGB(24,29,42)
		card.GroupTransparency=1; card.Parent=gui
		local limit=Instance.new("UISizeConstraint"); limit.MaxSize=Vector2.new(390,88); limit.Parent=card
		local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,12); corner.Parent=card
		local stroke=Instance.new("UIStroke"); stroke.Color=accent; stroke.Transparency=.65; stroke.Thickness=1; stroke.Parent=card
		local tile=Instance.new("Frame"); tile.BackgroundColor3=Color3.fromRGB(57,43,79); tile.Size=UDim2.fromOffset(48,48); tile.Position=UDim2.fromOffset(12,17); tile.Parent=card
		local tc=Instance.new("UICorner"); tc.CornerRadius=UDim.new(0,10); tc.Parent=tile
		local diamond=Instance.new("Frame"); diamond.AnchorPoint=Vector2.new(.5,.5); diamond.Position=UDim2.fromScale(.5,.5); diamond.Size=UDim2.fromOffset(17,17); diamond.Rotation=45; diamond.BackgroundColor3=accent; diamond.BorderSizePixel=0; diamond.Parent=tile
		local dc=Instance.new("UICorner"); dc.CornerRadius=UDim.new(0,3); dc.Parent=diamond
		local function line(text,y,h,size,color,font)
			local l=Instance.new("TextLabel"); l.BackgroundTransparency=1; l.Position=UDim2.fromOffset(72,y); l.Size=UDim2.new(1,-84,0,h); l.Text=text; l.TextColor3=color; l.Font=font; l.TextScaled=true; l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=card
			local c=Instance.new("UITextSizeConstraint"); c.MinTextSize=9; c.MaxTextSize=size; c.Parent=l
		end
		line("ESPADA SECRETA",10,15,12,accent,Enum.Font.GothamBold)
		line(name.." apareceu!",27,25,21,Color3.new(1,1,1),Enum.Font.GothamBold)
		line("Disponível na esteira",53,17,13,Color3.fromRGB(181,185,202),Enum.Font.Gotham)
		local track=Instance.new("Frame"); track.Position=UDim2.new(0,12,1,-9); track.Size=UDim2.new(1,-24,0,3); track.BackgroundColor3=Color3.fromRGB(53,48,70); track.BorderSizePixel=0; track.Parent=card
		local bar=Instance.new("Frame"); bar.Size=UDim2.fromScale(1,1); bar.BackgroundColor3=accent; bar.BorderSizePixel=0; bar.Parent=track
		TweenService:Create(card,TweenInfo.new(.2),{GroupTransparency=0}):Play()
		TweenService:Create(bar,TweenInfo.new(5,Enum.EasingStyle.Linear),{Size=UDim2.fromScale(0,1)}):Play()
		task.delay(5,function()
			if not gui.Parent then return end
			TweenService:Create(card,TweenInfo.new(.25),{GroupTransparency=1}):Play()
			task.delay(.3,function() if gui.Parent then gui:Destroy() end end)
		end)
	end
end

local function spawnSword(forcedRarity, forcedMutation)
	if #arenaSwords:GetChildren() >= CONFIG.MaxArenaSwords then
		return
	end

	local rarity, guaranteed
	if forcedRarity then rarity=forcedRarity else rarity,guaranteed=chooseRarity() end
	local model = applyMutation(createSword(rarity), rarity, forcedMutation or rollMutation())

	model.Parent = arenaSwords
	if not forcedRarity then
		recordPity(rarity)
		if rarity.Name == "Comum" then
			spawnsWithoutCommon = 0
			if guaranteed then
				print("[SwordSystem V18] Espada comum garantida!")
			end
		else
			spawnsWithoutCommon += 1
		end
	end
	if rarity.Name == "Secreta" then announceSecret(model) end

	local offset = Vector3.new(0, CONFIG.ConveyorHeight, 0)
	local startPosition = beltStart.Position + offset
	local endPosition = beltEnd.Position + offset
	model:PivotTo(CFrame.new(startPosition))
	moving[model] = {Start = startPosition, Finish = endPosition, Distance = 0}

	addSwordLabel(model)

	createPrompt(
		model,
		"Comprar espada",
		collectSword,
		CONFIG.CollectDistance
	)
	return true
end

-- MOVIMENTO DA ESTEIRA
local accumulator = 0
RunService.Heartbeat:Connect(function(dt)
	accumulator += dt
	if accumulator < 1/30 then return end
	local step = accumulator
	accumulator = 0
	for _,folder in ipairs({arenaSwords,carriedSwords,storedSwords,deliveryFolder}) do
		for _,model in ipairs(folder:GetChildren()) do
			if model:GetAttribute("Mutation")=="Rainbow" then
				local color=Color3.fromHSV((os.clock()*.25)%1,.85,1)
				for _,part in ipairs(model:GetDescendants()) do
					if part:IsA("BasePart") and part~=model.PrimaryPart then part.Color=color end
				end
			end
		end
	end
	for model, data in pairs(moving) do
		if model.Parent ~= arenaSwords then
			moving[model] = nil
		else
			local length = (data.Finish - data.Start).Magnitude
			data.Distance += CONFIG.ConveyorSpeed * step
			if data.Distance >= length then
				moving[model] = nil
				model:Destroy()
			else
				local position = data.Start:Lerp(data.Finish, data.Distance / length)
				model:PivotTo(CFrame.new(position))
			end
		end
	end
end)

-- LIMPAR ESPADAS QUANDO UMA BASE FICA SEM DONO
-- Nesta versao nao existe salvamento permanente.

local function watchBase(base)
	local previousOwner = base:GetAttribute("OwnerUserId")

	base:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
		local newOwner = base:GetAttribute("OwnerUserId")

		if previousOwner and previousOwner ~= newOwner then
			for model, origin in pairs(swordOrigins) do
				if origin.Base == base and origin.OwnerUserId == previousOwner then
					for carrier, held in pairs(carrying) do
						if held == model then carrying[carrier] = nil; restoreSpeed(carrier); clearMovePrompts(carrier) end
					end
					if occupiedStands[origin.Stand] == model then occupiedStands[origin.Stand] = nil end
					swordOrigins[model] = nil
					model:Destroy()
				end
			end
			for _, model in ipairs(storedSwords:GetChildren()) do
				if model:GetAttribute("BaseName") == base.Name
					and model:GetAttribute("OwnerUserId") == previousOwner then

					local standsFolder = base:FindFirstChild("SwordStands")
					local standName = model:GetAttribute("StandName")

					if standsFolder and standName then
						local stand = standsFolder:FindFirstChild(standName)

						if stand and occupiedStands[stand] == model then
							occupiedStands[stand] = nil
						end
					end

					swordOrigins[model] = nil
					model:Destroy()
				end
			end
		end

		if not newOwner then evolveBase(base,0) end
		previousOwner = newOwner
	end)
end

for _, base in ipairs(basesFolder:GetChildren()) do
	if base:IsA("Model") then
		watchBase(base)
	end
end

-- JOGADORES

local function setupPlayer(player)
	local function onCharacter(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.WalkSpeed = player:GetAttribute("CarryingStolen") and 15 or (player:GetAttribute("SpeedCoilEquipped") and 30 or 20)

		humanoid.Died:Connect(function()
			clearCarry(player)
		end)
	end

	player.CharacterAdded:Connect(onCharacter)

	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end

Players.PlayerAdded:Connect(setupPlayer)

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

Players.PlayerRemoving:Connect(function(player)
	if player:GetAttribute("MovingOwnSword") then clearCarry(player) end
	clearMovePrompts(player)
	for model,d in pairs(deliveries) do if d.Player==player then cancelDelivery(model,true) end end
	ready[player] = nil
	player:SetAttribute("EquipmentReady", false)
	for model, origin in pairs(swordOrigins) do
		if origin.OwnerUserId == player.UserId then
			for carrier, held in pairs(carrying) do
				if held == model then carrying[carrier] = nil; restoreSpeed(carrier); theftNotice(carrier, "Roubo cancelado: dono saiu.") end
			end
			if occupiedStands[origin.Stand] == model then occupiedStands[origin.Stand] = nil end
			swordOrigins[model] = nil
			model:Destroy()
		end
	end
	clearCarry(player)
	DataSystem.Close(player)
end)

-- DEPOSITO AUTOMATICO

task.spawn(function()
	while true do
		task.wait(CONFIG.DepositCheckInterval)

		for player, model in pairs(carrying) do
			if model and model.Parent then
				if not isAlive(player) then
					clearCarry(player)
				else
					depositSword(player)
				end
			else
				carrying[player] = nil
				restoreSpeed(player)
			end
		end
	end
end)

-- SPAWN PERIODICO

task.spawn(function()
	task.wait(3)

	while true do
		spawnSword()
		task.wait(CONFIG.SpawnInterval)
	end
end)

print("[SwordSystem V18] Spawn, coleta e roubo iniciados!")
-- REBIRTH V1 (server-authoritative)
local REBIRTHS = {
	{Cash=5000, Swords={"Espada de Ferro","Wooden Blade"}, Multiplier=1.5},
	{Cash=15000, Swords={"Bronze Blade","Knight Sword"}, Multiplier=2},
	{Cash=40000, Swords={"Esmeralda","Crimson Blade"}, Multiplier=2.5},
	{Cash=100000, Swords={"Venom Fang","Jade Katana"}, Multiplier=3},
	{Cash=250000, Swords={"Frostbite","Thunder Blade"}, Multiplier=4},
	{Cash=600000, Swords={"Glacier"}, Multiplier=4.5},
	{Cash=1500000, Swords={"Aquamarine"}, Multiplier=5},
	{Cash=4000000, Swords={"Voidblade","Aquamarine"}, Multiplier=5.5},
	{Cash=10000000, Swords={"Shadow Reaper"}, Multiplier=6},
	{Cash=25000000, Swords={"Solaris","Shadow Reaper"}, Multiplier=7},
	{Cash=75000000, Swords={"Sunbreaker"}, Multiplier=8},
	{Cash=200000000, Swords={"Infernal","Sunbreaker"}, Multiplier=9},
	{Cash=750000000, Swords={"Eclipse"}, Multiplier=10},
	{Cash=2500000000, Swords={"Oblivion","Eclipse"}, Multiplier=12},
	{Cash=10000000000, Swords={"Aether"}, Multiplier=15, IndexReward=true},
}
local function initRebirth(player)
	if player:GetAttribute("Rebirths") == nil then player:SetAttribute("Rebirths",0) end
	if player:GetAttribute("IncomeMultiplier") == nil then player:SetAttribute("IncomeMultiplier",1) end
	task.spawn(function()
		local stats=player:WaitForChild("leaderstats",30)
		if not stats then return end
		local counter=stats:FindFirstChild("Rebirths") or Instance.new("IntValue")
		counter.Name="Rebirths"; counter.Value=player:GetAttribute("Rebirths") or 0; counter.Parent=stats
	end)
end
Players.PlayerAdded:Connect(initRebirth)
for _,player in ipairs(Players:GetPlayers()) do initRebirth(player) end
local function notify(player,message)
	local pg=player:FindFirstChildOfClass("PlayerGui")
	if not pg then return end
	local old=pg:FindFirstChild("RebirthNotice")
	if old then old:Destroy() end
	local gui=Instance.new("ScreenGui"); gui.Name="RebirthNotice"; gui.ResetOnSpawn=false; gui.Parent=pg
	local label=Instance.new("TextLabel"); label.Size=UDim2.new(.8,0,0,48); label.Position=UDim2.fromScale(.1,.18); label.BackgroundColor3=Color3.fromRGB(30,35,50); label.TextColor3=Color3.new(1,1,1); label.TextScaled=false; label.TextSize=18; label.TextWrapped=true; label.Font=Enum.Font.GothamBold; label.Text=message; label.Parent=gui
	task.delay(5,function() gui:Destroy() end)
end
local inventoryByPlayer={}
local function tryRebirth(player,base)
	if not ready[player] then return end
	if not base or getPlayerBase(player)~=base or not isAlive(player) then return end
	local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local level=player:GetAttribute("Rebirths") or 0
	local req=REBIRTHS[level+1]
	if not req then notify(player,"Rebirth máximo atingido!"); return end
	local stats=player:FindFirstChild("leaderstats")
	local cash=stats and stats:FindFirstChild("Cash")
	if not cash then return end
	if DataSystem.GetForge(player) then notify(player,"Resgate a fusão antes de renascer."); return end
	if carrying[player] then notify(player,"Guarde a espada antes de renascer."); return end
	for _,d in pairs(deliveries) do if d.Player==player then notify(player,"Espere suas compras chegarem à base."); return end end
	-- Prevent a pending stolen sword from returning after the reset.
	for model,origin in pairs(swordOrigins) do
		if origin.OwnerUserId==player.UserId and model.Parent then notify(player,"Espere a disputa pela sua espada terminar."); return end
	end
	local owned={}; local found={}
	for _,model in ipairs(storedSwords:GetChildren()) do
		if model:GetAttribute("OwnerUserId")==player.UserId and model:GetAttribute("BaseName")==base.Name then
			table.insert(owned,model)
			found[model.Name]=true
		end
	end
	local missing={}
	for _,name in ipairs(req.Swords) do if not found[name] then table.insert(missing,name) end end
	if req.IndexReward and not DataSystem.GetIndexRewardClaimed(player) then table.insert(missing,"INFINITY (resgate do índice)") end
	if cash.Value<req.Cash or #missing>0 then notify(player,"Rebirth "..(level+1)..": $"..formatSwordMoney(req.Cash)..(#missing>0 and (" | Falta: "..table.concat(missing,", ")) or "")); return end
	for _,model in ipairs(owned) do
		for stand,occupant in pairs(occupiedStands) do if occupant==model then occupiedStands[stand]=nil end end
		swordOrigins[model]=nil; model:Destroy()
	end
	inventoryByPlayer[player]={}
	base:SetAttribute("RebirthReset",(base:GetAttribute("RebirthReset") or 0)+1)
	cash.Value=100
	player:SetAttribute("Rebirths",level+1)
	evolveBase(base,level+1)
	local counter=stats:FindFirstChild("Rebirths")
	if counter then counter.Value=level+1 end
	player:SetAttribute("IncomeMultiplier",req.Multiplier)
	refreshSave(player)
	celebration(root.Position-Vector3.new(0,2.5,0),Color3.fromRGB(180,110,255))
	notify(player,"Rebirth "..(level+1).." concluído! Ganhos: "..req.Multiplier.."x")
end
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remote = Instance.new("RemoteEvent")
remote.Name = "RequestRebirth"
remote.Parent = ReplicatedStorage
local lastRequest = {}
remote.OnServerEvent:Connect(function(player)
	local now = os.clock()
	if now - (lastRequest[player] or -10) < 2 then return end
	lastRequest[player] = now
	tryRebirth(player, getPlayerBase(player))
end)
Players.PlayerRemoving:Connect(function(player) lastRequest[player] = nil end)


-- V7: persistencia integrada aos expositores reais
refreshSave = function(player)
	if not ready[player] then return end
	local list = {}
	for _, model in ipairs(storedSwords:GetChildren()) do
		if model:GetAttribute("OwnerUserId") == player.UserId then
			table.insert(list, {Rarity=model:GetAttribute("Rarity"), Id=model:GetAttribute("SwordId"), Mutation=model:GetAttribute("Mutation") or "Normal", Stand=model:GetAttribute("StandName")})
		end
	end
	for model, origin in pairs(swordOrigins) do
		if origin.OwnerUserId == player.UserId and model.Parent then
			table.insert(list, {Rarity=model:GetAttribute("Rarity"), Id=model:GetAttribute("SwordId"), Mutation=model:GetAttribute("Mutation") or "Normal", Stand=origin.Stand.Name})
		end
	end
	for _,item in ipairs(inventoryByPlayer[player] or {}) do table.insert(list,item) end
	DataSystem.SetSwords(player,list)
	player:SetAttribute("StoredSwordCount", #(inventoryByPlayer[player] or {}))
end

local function loadProgress(player)
	local data = DataSystem.Open(player)
	if not data then
		if player.Parent == Players then player:Kick("Nao foi possivel carregar seu progresso. Entre novamente.") end
		return
	end
	local stats = player:WaitForChild("leaderstats",30)
	local cash = stats and stats:WaitForChild("Cash",30)
	local base
	for i=1,300 do
		if player.Parent ~= Players then DataSystem.Close(player); return end
		base=getPlayerBase(player)
		if base then break end
		task.wait(.1)
	end
	if not cash or not base then DataSystem.Close(player); player:Kick("Base ou dinheiro indisponivel. Tente novamente."); return end
	if player.Parent ~= Players then DataSystem.Close(player); return end
	local level=math.clamp(math.floor(tonumber(data.Rebirths) or 0),0,#REBIRTHS)
	cash.Value=math.max(0,math.floor(tonumber(data.Cash) or 100))
	player:SetAttribute("Rebirths",level)
	evolveBase(base,level)
	player:SetAttribute("IncomeMultiplier",level>0 and REBIRTHS[level].Multiplier or 1)
	local counter=stats:FindFirstChild("Rebirths")
	if counter then counter.Value=level end
	local bag={}; inventoryByPlayer[player]=bag
	local function storeItem(item)
		local entry=table.clone(item); entry.Stored=true; entry.Stand=nil
		entry.Uid=entry.Uid or game:GetService("HttpService"):GenerateGUID(false)
		table.insert(bag,entry)
	end
	for _, item in ipairs(data.Swords or {}) do
		local rarity = item.Id == INFINITY.Id and INFINITY or nil
		for _,r in ipairs(RARITIES) do if r.Name==item.Rarity and r.Id==item.Id then rarity=r; break end end
		local stand=not item.Stored and base.SwordStands:FindFirstChild(item.Stand or "")
		if not item.Stored and (not stand or not stand:IsA("BasePart") or occupiedStands[stand]) then stand=findFreeStand(base) end
		if rarity and stand and not item.Stored then placeOnStand(applyMutation(createSword(rarity),rarity,item.Mutation),base,stand) else storeItem(item) end
	end
	DataSystem.Activate(player)
	-- Migra espadas antigas, inclusive se nao houver expositor livre.
	for _, item in ipairs(data.Swords or {}) do
		for _, rarity in ipairs(RARITIES) do
			if rarity.Name == item.Rarity and rarity.Id == item.Id then
				local mutation=item.Mutation or "Normal"
				DataSystem.DiscoverSword(player, mutation=="Normal" and indexId(rarity) or mutation..":"..indexId(rarity))
				break
			end
		end
	end
	syncIndex(player)
	ready[player]=true
	player:SetAttribute("EquipmentReady", true)
	refreshSave(player)
	print("[SwordSystem V18] Progresso carregado:",player.Name)
end
-- V40: inventory requests, validated exclusively on server.
do
	local rs=game:GetService("ReplicatedStorage")
	local rf=Instance.new("RemoteFunction"); rf.Name="SwordInventoryV40"; rf.Parent=rs
	local busy={}
	local function rarityOf(item)
		if item.Id==INFINITY.Id then return INFINITY end
		for _,r in ipairs(RARITIES) do if r.Name==item.Rarity and r.Id==item.Id then return r end end
	end

	local tiers={"Comum","Incomum","Rara","Épica","Lendária","Mítica","Secreta"}
	local fees={500,2500,15000,100000,500000,5000000,50000000}
	local forge=Instance.new("Model"); forge.Name="SpiritualForge"; forge.Parent=map
	local center=Vector3.new(-52,0,194)
	local function piece(n,size,offset,color,mat)
		return makePart(n,size,CFrame.new(center+offset),color,mat,forge)
	end
	local stone=Color3.fromRGB(103,105,115)
	local dark=Color3.fromRGB(68,70,80)
	local wood=Color3.fromRGB(126,83,55)
	local smooth=Enum.Material.SmoothPlastic
	local function block(n,x,y,z,sx,sy,sz,c,collide)
		local q=piece(n,Vector3.new(sx,sy,sz),Vector3.new(x,y,z),c,smooth)
		q.CanCollide=collide==true; q.CastShadow=true; return q
	end
	block("Platform",0,.35,0,24,.7,18,Color3.fromRGB(130,132,141),true)
	for x=-9,9,6 do for z=-6,6,6 do
			block("Paving",x,.76,z,5.8,.12,5.8,Color3.fromRGB(145+(x+9)%17,145,151),false)
		end end
	-- Open hearth: two piers, back wall, lintel and chimney.
	block("Hearth",0,1.2,4,9,1,6,dark,true)
	block("LeftPier",-3.5,3.6,4,2,4,5,stone,true)
	block("RightPier",3.5,3.6,4,2,4,5,stone,true)
	block("Back",0,3.6,6.3,5,4,.8,dark,true)
	block("Lintel",0,6,4,9,1.3,5.4,stone,true)
	block("ChimneyShoulder",0,7,4,6,1,4.4,stone,true)
	block("Chimney",0,9.2,4,3.8,4,3.5,stone,true)
	block("ChimneyCap",0,11.3,4,4.5,.6,4.1,dark,true)
	for i=1,5 do
		local q=block("Coal",(i-3)*.75,1.95,3.6+(i%2)*.7,1,.65,1,Color3.fromRGB(213,103+ i*13,52),false)
		q.CFrame*=CFrame.Angles(0,i*.7,.2)
	end
	local flame=block("Ember",0,2.25,3.9,2,.4,1.5,Color3.fromRGB(255,158,67),false)
	flame.Transparency=1
	local fire=Instance.new("Fire"); fire.Size=3; fire.Heat=4; fire.Color=Color3.fromRGB(255,157,68); fire.SecondaryColor=Color3.fromRGB(255,214,125); fire.Parent=flame
	-- Anvil on a timber pedestal, facing the entrance.
	block("TimberBase",0,1.2,-3,5,1,4,wood,true)
	block("AnvilFoot",0,1.95,-3,3.4,.5,2.5,dark,true)
	block("AnvilWaist",0,2.55,-3,2,1,1.8,stone,true)
	local altar=block("Anvil",0,3.35,-3,4.8,.65,2.4,dark,true)
	local horn=Instance.new("WedgePart"); horn.Name="AnvilHorn"; horn.Size=Vector3.new(2.3,.65,2.4); horn.CFrame=altar.CFrame*CFrame.new(3.5,0,0)*CFrame.Angles(0,math.rad(90),0); horn.Anchored=true; horn.Color=dark; horn.Material=smooth; horn.Parent=forge
	local handle=block("HammerHandle",-.4,3.85,-3,2.2,.22,.25,wood,false); handle.CFrame*=CFrame.Angles(0,.5,0)
	local head=block("HammerHead",.5,3.85,-3.45,.7,.55,1.1,stone,false); head.CFrame*=CFrame.Angles(0,.5,0)
	for i=1,3 do block("Firewood",-8,1.1+(i-1)*.65,4,3,.6,.7,wood,false) end
	local prompt=Instance.new("ProximityPrompt"); prompt.ActionText="Abrir forja"; prompt.ObjectText="Forja Espiritual"; prompt.MaxActivationDistance=12; prompt.RequiresLineOfSight=false; prompt.Parent=altar
	local open=Instance.new("RemoteEvent"); open.Name="OpenSpiritualForge"; open.Parent=rs
	prompt.Triggered:Connect(function(p) open:FireClient(p) end)
	local function near(p)
		local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		return root and (root.Position-altar.Position).Magnitude<=16 and isAlive(p)
	end
	local function request(player,action,arg)
		if not ready[player] then return false,"Aguarde seus dados." end
		local bag=inventoryByPlayer[player]; if not bag then return false,"Inventario indisponivel." end

		local function forgeStand(model)
			local base=getPlayerBase(player)
			if not base or base:GetAttribute("OwnerUserId")~=player.UserId then return nil end
			if typeof(model)~="Instance" or not model:IsA("Model") or model.Parent~=storedSwords or model:GetAttribute("OwnerUserId")~=player.UserId or model:GetAttribute("BaseName")~=base.Name or selling[model] or swordOrigins[model] then return nil end
			local stand=base.SwordStands:FindFirstChild(model:GetAttribute("StandName") or "")
			if not stand or occupiedStands[stand]~=model then return nil end
			return stand,base
		end
		if action=="ForgeList" then
			local out={}
			for _,model in ipairs(storedSwords:GetChildren()) do
				if forgeStand(model) then
					local item={Uid=model,Name=model.Name,Rarity=model:GetAttribute("Rarity"),Id=model:GetAttribute("SwordId"),Mutation=model:GetAttribute("Mutation") or "Normal"}
					if rarityOf(item) and item.Id~=INFINITY.Id then table.insert(out,item) end
				end
			end
			return true,out
		end
		if action=="ForgeStatus" then
			local job=DataSystem.GetForge(player)
			return true,{EndsAt=job and job.EndsAt or 0,Now=os.time()}
		end
		if action=="ForgeStart" or action=="ForgeClaim" then
			if not near(player) or carrying[player] then return false,"Aproxime-se da forja sem carregar espadas." end
			local job=DataSystem.GetForge(player)
			if action=="ForgeClaim" then
				if not job or os.time()<job.EndsAt then return false,"Fusão ainda não está pronta." end
				if #bag>=5 then return false,"Libere um espaço no inventário." end
				local item=job.Result; local r=rarityOf(item)
				if not r then return false,"Resultado indisponível." end
				table.insert(bag,item); DataSystem.SetForge(player,nil); refreshSave(player)
				DataSystem.DiscoverSword(player,item.Mutation=="Normal" and indexId(r) or item.Mutation..":"..indexId(r)); syncIndex(player)
				local model=createSword(r); local name=model.Name; model:Destroy()
				return true,item.Mutation.." "..name.." resgatada!"
			end
			if job then return false,"Já existe uma fusão." end
			if type(arg)~="table" or #arg~=3 then return false,"Selecione três espadas." end
			local chosen={}; local seen={}; local tier
			for i=1,3 do
				local model=arg[i]; local stand,base=forgeStand(model)
				if not stand or seen[model] then return false,"Espada indisponível na base." end
				seen[model]=true
				local item={Id=model:GetAttribute("SwordId"),Rarity=model:GetAttribute("Rarity")}
				if item.Id==INFINITY.Id or not rarityOf(item) then return false,"Espada protegida ou indisponível." end
				local t=table.find(tiers,item.Rarity); if not t or (tier and tier~=t) then return false,"Use três espadas da mesma raridade." end
				tier=t; chosen[i]={Model=model,Stand=stand,Base=base}
			end
			local stats=player:FindFirstChild("leaderstats"); local cash=stats and stats:FindFirstChild("Cash")
			if not cash or cash.Value<fees[tier] or player:GetAttribute("AdminInfiniteCash") then return false,"Saldo insuficiente ou modo admin ativo." end
			local roll=rng:NextNumber(0,100); local target=math.min(7,tier+(roll>=65 and 1 or 0)); local pool={}
			for _,r in ipairs(RARITIES) do if r.Name==tiers[target] then table.insert(pool,r) end end
			local r=pool[rng:NextInteger(1,#pool)]
			local result={Rarity=r.Name,Id=r.Id,Mutation=roll>=95 and "Spiritual" or "Normal",Stored=true,Uid=game:GetService("HttpService"):GenerateGUID(false)}
			-- Reserve all three before collecting accrued income (BindableFunction may yield).
			for _,v in ipairs(chosen) do selling[v.Model]=true end
			local function unlock() for _,v in ipairs(chosen) do selling[v.Model]=nil end end
			for _,v in ipairs(chosen) do
				if not collectMove(player,v.Base,v.Stand,v.Model) then unlock(); return false,"Não foi possível coletar a renda." end
			end
			if not ready[player] or carrying[player] or not near(player) or DataSystem.GetForge(player) or cash.Value<fees[tier] then unlock(); return false,"Fusão cancelada. Tente novamente." end
			for _,v in ipairs(chosen) do
				if v.Model.Parent~=storedSwords or occupiedStands[v.Stand]~=v.Model or v.Model:GetAttribute("OwnerUserId")~=player.UserId or getPlayerBase(player)~=v.Base then unlock(); return false,"Uma espada não está mais disponível." end
			end
			for _,v in ipairs(chosen) do occupiedStands[v.Stand]=nil; v.Model:Destroy() end
			unlock()
			cash.Value-=fees[tier]; DataSystem.SetForge(player,{EndsAt=os.time()+900,Result=result}); refreshSave(player)
			return true,"Fusão iniciada!"
		end
		if action=="List" then
			local out={}
			for _,item in ipairs(bag) do
				local r=rarityOf(item); local name=r and (r.Id or r.Name) or item.Id or item.Rarity
				local preview=r and applyMutation(createSword(r),r,item.Mutation)
				table.insert(out,{Uid=item.Uid,Name=preview and preview.Name or name,Rarity=item.Rarity,Mutation=item.Mutation,Favorite=item.Favorite==true,Price=preview and preview:GetAttribute("Price") or 0,Id=item.Id})
				if preview then preview:Destroy() end
			end
			return true,out
		end
		if carrying[player] or not isAlive(player) then return false,"Guarde a espada que esta carregando." end
		local base=getPlayerBase(player); if not base or base:GetAttribute("OwnerUserId")~=player.UserId then return false,"Base indisponivel." end
		if action=="Store" then
			if #bag>=5 then return false,"Inventário cheio (5/5)." end
			local model=arg
			if typeof(model)~="Instance" or not model:IsA("Model") or model.Parent~=storedSwords or model:GetAttribute("OwnerUserId")~=player.UserId or selling[model] then return false,"Espada indisponivel." end
			local stand=base.SwordStands:FindFirstChild(model:GetAttribute("StandName") or "")
			if not stand or occupiedStands[stand]~=model then return false,"Expositor indisponivel." end
			selling[model]=true
			local paid=collectMove(player,base,stand,model)
			selling[model]=nil
			if not paid or not ready[player] or model.Parent~=storedSwords or occupiedStands[stand]~=model then return false,"Nao foi possivel guardar." end
			table.insert(bag,{Rarity=model:GetAttribute("Rarity"),Id=model:GetAttribute("SwordId"),Mutation=model:GetAttribute("Mutation") or "Normal",Stored=true,Uid=game:GetService("HttpService"):GenerateGUID(false)})
			occupiedStands[stand]=nil; model:Destroy(); refreshSave(player); return true,"Guardada!"
		end
		if type(arg)~="string" then return false,"Espada invalida." end
		local idx,item
		for i,v in ipairs(bag) do if v.Uid==arg then idx=i; item=v; break end end
		if not item then return false,"Espada indisponivel." end
		if action=="Favorite" then item.Favorite=not item.Favorite; refreshSave(player); return true end
		local r=rarityOf(item); if not r then return false,"Espada antiga preservada; modelo indisponivel." end
		if action=="Equip" then
			local stand=findFreeStand(base); if not stand then return false,"Base cheia!" end
			local model=applyMutation(createSword(r),r,item.Mutation)
			placeOnStand(model,base,stand); table.remove(bag,idx); refreshSave(player); return true,"Equipada!"
		elseif action=="Sell" then
			if item.Id==INFINITY.Id or item.Favorite then return false,"Espada protegida." end
			local stats=player:FindFirstChild("leaderstats"); local cash=stats and stats:FindFirstChild("Cash")
			if not cash then return false,"Saldo indisponivel." end
			local model=applyMutation(createSword(r),r,item.Mutation); local price=math.floor((model:GetAttribute("Price") or 0)/2); model:Destroy()
			if cash.Value+price>9e15 then return false,"Limite de saldo." end
			table.remove(bag,idx); cash.Value+=price; refreshSave(player); return true,"Vendida!"
		end
		return false,"Acao invalida."
	end
	rf.OnServerInvoke=function(player,action,arg)
		if busy[player] then return false,"Aguarde." end
		busy[player]=true; local ok,a,b=pcall(request,player,action,arg); busy[player]=nil
		if not ok then warn("[Inventory V40]",a); return false,"Erro interno." end
		return a,b
	end
	Players.PlayerRemoving:Connect(function(player) inventoryByPlayer[player]=nil; busy[player]=nil end)
end
local claimRemote=Instance.new("RemoteEvent")
claimRemote.Name="ClaimInfinity"
claimRemote.Parent=eventStorage
claimRemote.OnServerEvent:Connect(function(player, name)
	name=name or "Normal"
	local mutation
	for _,m in ipairs(MUTATIONS) do if m.Name==name then mutation=m; break end end
	if not mutation or name=="Spiritual" then return end
	if not ready[player] or not isAlive(player) or carrying[player] then return end
	if name=="Normal" and DataSystem.GetIndexRewardClaimed(player) ~= false then return end
	local discovered=DataSystem.GetDiscovered(player)
	if not discovered or discovered["Reward:"..name] then return end
	for _,rarity in ipairs(RARITIES) do
		if discovered[name=="Normal" and indexId(rarity) or name..":"..indexId(rarity)] ~= true then return end
	end
	local base=getPlayerBase(player)
	local stand=base and findFreeStand(base)
	if not stand then notify(player,"Libere um expositor para receber INFINITY!"); return end
	local model=applyMutation(createSword(INFINITY),INFINITY,name)
	local claimed
	if name=="Normal" then claimed=DataSystem.ClaimIndexReward(player) else claimed=DataSystem.DiscoverSword(player,"Reward:"..name) end
	if not claimed then model:Destroy(); return end
	placeOnStand(model,base,stand)
	refreshSave(player)
	syncIndex(player)
	notify(player,displayName(model).." desbloqueada! +$"..formatSwordMoney(model:GetAttribute("Income")).."/s")
end)
Players.PlayerAdded:Connect(function(player) task.spawn(loadProgress,player) end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(loadProgress,player) end

-- V12: interface exclusivamente no servidor para recuperar espada com o bastao.
local recover = Instance.new("BindableFunction")
recover.Name = "RecoverWithBat"
recover.OnInvoke = function(attacker, thief)
	-- V39.1: qualquer jogador que acerte o ladrao pode recuperar a espada.
	-- O BindableFunction e chamado apenas pelo EquipmentShop apos um golpe validado.
	if attacker == thief or not ready[thief] or not isAlive(attacker) or not isAlive(thief) then return false end
	local model = carrying[thief]
	local origin = model and swordOrigins[model]
	if not origin or origin.MovingOwn or model.Parent ~= carriedSwords or model:GetAttribute("IsStolen") ~= true then return false end
	local owner = Players:GetPlayerByUserId(origin.OwnerUserId)
	if not owner or not ready[owner] or not origin.Base.Parent or origin.Base:GetAttribute("OwnerUserId") ~= origin.OwnerUserId then return false end
	if (attacker.Character.HumanoidRootPart.Position-thief.Character.HumanoidRootPart.Position).Magnitude > 10 then return false end
	if (thief:GetAttribute("ShieldUntil") or 0) > Workspace:GetServerTimeNow() then return false end
	clearCarry(thief)
	if model.Parent ~= storedSwords then return false end
	theftNotice(owner, "TUNG TUNG! Sua espada foi recuperada!")
	theftNotice(thief, "A espada roubada voltou para a base!")
	return true
end
recover.Parent = script

-- V25.2: prêmio do dia 7, somente com expositor livre.
Rewards.GrantSword=function(player,today)
	if not ready[player] then return false,"Dados indisponíveis." end
	local base=getPlayerBase(player)
	local stand=base and findFreeStand(base)
	if not stand then return false,"Libere um expositor para receber sua espada!" end
	local pool={}
	for _,r in ipairs(RARITIES) do
		if r.Name=="Rara" or r.Name=="Épica" or r.Name=="Lendária" or r.Name=="Mítica" or r.Name=="Secreta" then table.insert(pool,r) end
	end
	-- Sorteio ponderado pelas chances originais, sem multiplicadores de evento.
	local total=0
	for _,r in ipairs(pool) do total+=r.Weight end
	local roll=rng:NextNumber(0,total)
	local rarity=pool[#pool]
	for _,r in ipairs(pool) do roll-=r.Weight; if roll<=0 then rarity=r; break end end
	local model=applyMutation(createSword(rarity),rarity,"Normal")
	if not DataSystem.SetDaily(player,1,today) then model:Destroy(); return false,"Tente novamente." end
	placeOnStand(model,base,stand)
	discoverModel(player,model); refreshSave(player)
	return true,"Espada recebida: "..displayName(model)
end

-- V38: admin, validacao exclusivamente no servidor.
local adminRemote=Instance.new("RemoteFunction")
adminRemote.Name="AdminControlV38"
local lastAdmin=0
adminRemote.OnServerInvoke=function(player,action,id,mutation)
	if player.UserId~=11715073634 then return false,"Sem permissao." end
	if os.clock()-lastAdmin<.5 then return false,"Aguarde um instante." end
	lastAdmin=os.clock()
	if action=="Spawn" or action=="Grant" then
		local rarity
		for _,r in ipairs(RARITIES) do if indexId(r)==id then rarity=r; break end end
		local valid=false
		for _,m in ipairs(MUTATIONS) do if m.Name==mutation then valid=true end end
		if not rarity or not valid then return false,"Espada ou mutacao invalida." end
		if action=="Spawn" then
			if not spawnSword(rarity,mutation) then return false,"Esteira cheia. Aguarde." end
			return true,"Espada na esteira!"
		end
		if not ready[player] then return false,"Dados indisponiveis." end
		local base=getPlayerBase(player); local stand=base and findFreeStand(base)
		if not stand then return false,"Base cheia ou indisponivel." end
		local model=applyMutation(createSword(rarity),rarity,mutation)
		placeOnStand(model,base,stand); discoverModel(player,model); refreshSave(player)
		return true,"Espada adicionada!"
	end
	if action=="Pro" then
		local q=id
		if type(q)~="table" or type(q.UserId)~="number" then return false,"Jogador invalido." end
		local t=Players:GetPlayerByUserId(q.UserId)
		if not t or not ready[t] then return false,"Jogador ou dados indisponiveis." end
		local base=getPlayerBase(t); local bag=inventoryByPlayer[t]; local cash=cashOf(t)
		local op=q.Op
		if op=="Inspect" then
			local count=0; for _,m in ipairs(storedSwords:GetChildren()) do if m:GetAttribute("OwnerUserId")==t.UserId then count+=1 end end
			local job=DataSystem.GetForge(t)
			return true,string.format("%s | $%s | R%d | %sx | Base %d | Inventario %d/5 | Forja %s",t.Name,tostring(cash and cash.Value or 0),t:GetAttribute("Rebirths") or 0,tostring(t:GetAttribute("IncomeMultiplier") or 1),count,#(bag or {}),job and tostring(math.max(0,job.EndsAt-os.time())).."s" or "livre")
		elseif op=="Rebirth" then
			local n=q.Value
			if type(n)~="number" or n~=n or n%1~=0 or n<0 or n>#REBIRTHS then return false,"Rebirth: 0 a 15." end
			-- V45.1: admin altera nivel sem resetar a fusao ou as espadas.
			if not base then return false,"Base ainda indisponivel. Aguarde o carregamento." end
			if carrying[t] then return false,"Guarde ou devolva a espada carregada antes de alterar o rebirth." end
			for model in pairs(selling) do
				if model:GetAttribute("OwnerUserId")==t.UserId then return false,"Aguarde a operacao de espada em andamento." end
			end
			for _,d in pairs(deliveries) do if d.Player==t then return false,"Aguarde entregas." end end
			for _,o in pairs(swordOrigins) do if o.OwnerUserId==t.UserId then return false,"Aguarde disputa ou movimento." end end
			local old=t:GetAttribute("Rebirths") or 0
			if math.min(old,10)~=math.min(n,10) then
				for stand,m in pairs(occupiedStands) do if m and m:GetAttribute("OwnerUserId")==t.UserId and stand:GetAttribute("EvolutionStand") then return false,"Retire as espadas dos andares superiores antes de mudar o nivel." end end
				evolveBase(base,n)
			end
			t:SetAttribute("Rebirths",n); t:SetAttribute("IncomeMultiplier",n>0 and REBIRTHS[n].Multiplier or 1)
			local stats=t:FindFirstChild("leaderstats"); local counter=stats and stats:FindFirstChild("Rebirths"); if counter then counter.Value=n end
			refreshSave(t); return true,"Rebirth definido: "..n
		elseif op=="Sword" then
			local r; for _,v in ipairs(RARITIES) do if indexId(v)==q.Id then r=v; break end end
			if q.Id==INFINITY.Id then r=INFINITY end
			local valid=false; for _,m in ipairs(MUTATIONS) do if m.Name==q.Mutation then valid=true end end
			if not r or not valid then return false,"Espada ou mutacao invalida." end
			if q.Dest=="Belt" then if r==INFINITY then return false,"INFINITY exclusiva do indice." end; return spawnSword(r,q.Mutation) and true or false,"Solicitacao de spawn concluida (verifique a esteira)." end
			if r==INFINITY then return false,"INFINITY permanece exclusiva do indice." end
			if q.Dest=="Inventory" then
				if not bag or #bag>=5 then return false,"Inventario cheio." end
				table.insert(bag,{Rarity=r.Name,Id=r.Id,Mutation=q.Mutation,Stored=true,Uid=game:GetService("HttpService"):GenerateGUID(false)})
				DataSystem.DiscoverSword(t,q.Mutation=="Normal" and indexId(r) or q.Mutation..":"..indexId(r)); syncIndex(t); refreshSave(t); return true,"Espada guardada!"
			elseif q.Dest=="Base" then
				local stand=base and findFreeStand(base); if not stand then return false,"Base cheia." end
				local m=applyMutation(createSword(r),r,q.Mutation); placeOnStand(m,base,stand); discoverModel(t,m); refreshSave(t); return true,"Espada adicionada!"
			end
		elseif op=="Cash" then
			local n=q.Value; if type(n)~="number" or n~=n or n%1~=0 or n<0 or n>9e15 or not cash or t:GetAttribute("AdminInfiniteCash") then return false,"Saldo invalido ou modo infinito ativo." end
			cash.Value=n; return true,"Saldo definido!"
		elseif op=="ForgeFinish" then
			local job=DataSystem.GetForge(t); if not job then return false,"Sem fusao." end
			job.EndsAt=os.time(); if not DataSystem.SetForge(t,job) then return false,"Falha ao atualizar." end; return true,"Fusao pronta para resgate!"
		elseif op=="Heal" then
			local h=t.Character and t.Character:FindFirstChildOfClass("Humanoid"); if not h or h.Health<=0 then return false,"Personagem indisponivel." end; h.Health=h.MaxHealth; return true,"Curado!"
		elseif op=="Respawn" then
			if carrying[t] then return false,"Guarde a espada primeiro." end; t:LoadCharacter(); return true,"Respawn concluido."
		end
		return false,"Acao invalida."
	end
	local target=player
	if action=="Give" or action=="Goto" or action=="Bring" or action=="Kick" then
		if type(id)~="number" then return false,"Jogador invalido." end
		target=Players:GetPlayerByUserId(id)
		if not target then return false,"Jogador saiu." end
	end
	if action=="Add" or action=="Set" or action=="Give" then
		local amount=action=="Give" and mutation or id
		if type(amount)~="number" or amount~=amount or amount<0 or amount>1e12 or amount%1~=0 then return false,"Valor invalido (0 a 1 trilhao)." end
		if not ready[target] or target:GetAttribute("AdminInfiniteCash") then return false,"Dados indisponiveis ou dinheiro infinito ativo." end
		local cash=cashOf(target); if not cash or not cash:IsA("IntValue") then return false,"Saldo indisponivel." end
		cash.Value=action=="Set" and amount or math.min(9e15,cash.Value+amount)
		return true,"Saldo atualizado!"
	elseif action=="Goto" or action=="Bring" then
		if not isAlive(player) or not isAlive(target) or carrying[player] or carrying[target] then return false,"Personagem indisponivel ou carregando espada." end
		local mover=action=="Goto" and player or target
		local dest=action=="Goto" and target or player
		mover.Character:PivotTo(dest.Character.HumanoidRootPart.CFrame*CFrame.new(0,0,5))
		return true,"Teleporte concluido!"
	elseif action=="Kick" then
		if target==player then return false,"Nao pode expulsar a si mesmo." end
		target:Kick("Removido pelo administrador."); return true,"Jogador removido."
	end
	return false,"Acao invalida."
end
adminRemote.Parent=eventStorage

-- V44.4: server-only vault reward, one shared cooldown per server.
do
	local nextOpen=0
	local grant=Instance.new("BindableFunction")
	grant.Name="VaultClaim"; grant.Parent=script
	grant.OnInvoke=function(player)
		if not ready[player] or not isAlive(player) or carrying[player] or (player:GetAttribute("Rebirths") or 0)<10 then return false,"Acesso indisponivel." end
		if os.time()<nextOpen then return false,"Cofre em recarga." end
		local cash=cashOf(player); local base=getPlayerBase(player); local stand=base and findFreeStand(base)
		if not cash or not stand then return false,"Libere um expositor na base." end
		if cash.Value<500000 or player:GetAttribute("AdminInfiniteCash") then return false,"Precisa de $500K (sem dinheiro infinito)." end
		local roll=rng:NextNumber(0,100)
		local tier=roll<45 and nil or (roll<70 and "Épica" or roll<88 and "Lendária" or roll<97 and "Mítica" or "Ancestral")
		local model
		if roll>=45 then
			local pool={}; for _,r in ipairs(RARITIES) do if r.Name==tier then table.insert(pool,r) end end
			local r=pool[rng:NextInteger(1,#pool)]; model=applyMutation(createSword(r),r,rollMutation())
		end
		nextOpen=os.time()+1800
		cash.Value-=500000
		if model then placeOnStand(model,base,stand); discoverModel(player,model); refreshSave(player); notify(player,"Cofre: "..displayName(model)); return true,displayName(model),nextOpen end
		cash.Value=math.min(9e15,cash.Value+1000000); notify(player,"Cofre: $1M!"); return true,"$1M",nextOpen
	end
end
