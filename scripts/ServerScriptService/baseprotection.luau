-- BASE PROTECTION V27.4 | ServerScriptService
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local Workspace = game:GetService("Workspace")
local map = Workspace:WaitForChild("SwordGameMap")
while not map:GetAttribute("MapReady") do map:GetAttributeChangedSignal("MapReady"):Wait() end
local bases = map:WaitForChild("Bases")
local states, connections = {}, {}
local function register(name)
	if not PhysicsService:IsCollisionGroupRegistered(name) then PhysicsService:RegisterCollisionGroup(name) end
end
local function ownerGroup(base) return "SwordOwner_"..base.Name end
local function laserGroup(base) return "SwordLaser_"..base.Name end
for i=1,8 do register("SwordOwner_Base"..i); register("SwordLaser_Base"..i) end
for i=1,8 do
	local g="SwordLaser_Base"..i
	PhysicsService:CollisionGroupSetCollidable(g,"Default",true)
	for j=1,8 do PhysicsService:CollisionGroupSetCollidable(g,"SwordOwner_Base"..j,i~=j) end
end
local function updateCharacter(player)
	if connections[player] then connections[player]:Disconnect(); connections[player]=nil end
	local char=player.Character
	if not char then return end
	local group="Default"
	for base in pairs(states) do if base:GetAttribute("OwnerUserId")==player.UserId then group=ownerGroup(base); break end end
	local function apply(p) if p:IsA("BasePart") then p.CollisionGroup=group end end
	for _,p in ipairs(char:GetDescendants()) do apply(p) end
	connections[player]=char.DescendantAdded:Connect(apply)
end
local function part(parent,name,size,cf,color,material)
	local p=Instance.new("Part"); p.Name=name; p.Size=size; p.CFrame=cf; p.Anchored=true
	p.Color=color; p.Material=material or Enum.Material.SmoothPlastic; p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth; p.Parent=parent
	return p
end
local function setProtection(s,on)
	s.active=on; s.base:SetAttribute("ProtectionActive",on)
	s.prompt.Enabled=not on
	for _,p in ipairs(s.barriers) do p.CanCollide=on end
	for _,p in ipairs(s.lasers) do p.Transparency=on and .18 or 1 end
	s.button.Color=on and Color3.fromRGB(155,35,45) or Color3.fromRGB(235,45,55)
end
local function rebuild(s)
	if s.geometry then s.geometry:Destroy() end
	local folder=Instance.new("Folder"); folder.Name="ProtectionGeometry"; folder.Parent=s.base; s.geometry=folder
	s.barriers={}; s.lasers={}
	local f=s.floor; local w,d=f.Size.X,f.Size.Z
	local level=s.base:GetAttribute("BaseLevel") or 0
	local h=level>=6 and 52 or (level>=1 and 35 or 18)
	local cf=f.CFrame*CFrame.new(0,f.Size.Y/2,0)
	local function barrier(size,x,y,z)
		local p=part(folder,"ProtectionBarrier",size,cf*CFrame.new(x,y,z),Color3.new(1,1,1)); p.Transparency=1; p.CanTouch=false; p.CanQuery=false; p.CastShadow=false; p.CollisionGroup=laserGroup(s.base); p.CanCollide=s.active; table.insert(s.barriers,p)
	end
	-- Perimetro completo, inclusive frestas laterais e cobertura.
	barrier(Vector3.new(w+2,h,.8),0,h/2,-d/2)
	barrier(Vector3.new(w+2,h,.8),0,h/2,d/2)
	for _,side in ipairs({-1,1}) do barrier(Vector3.new(.8,h,d+2),side*w/2,h/2,0) end
	barrier(Vector3.new(w+2,.8,d+2),0,h,0)
	-- Lasers visuais na entrada; segundo andar tem fachada fechada.
	for i=1,9 do
		local p=part(folder,"ProtectionLaser",Vector3.new(w-3,.22,.22),cf*CFrame.new(0,i*13/10,-d/2+1.5),Color3.fromRGB(235,40,50),Enum.Material.Neon)
		p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.CastShadow=false; p.Transparency=s.active and .18 or 1; table.insert(s.lasers,p)
	end
end
local function reset(s)
	s.token+=1; s.label.Text=""; setProtection(s,false)
end
-- A protecao inicial comeca imediatamente; o relogio espera os dados.
local function startProtection(s,player,initial)
	if s.active or s.base:GetAttribute("OwnerUserId")~=player.UserId then return end
	s.token+=1
	local token=s.token
	setProtection(s,true)
	s.label.Text=initial and "Carregando..." or ""
	local function valid()
		return s.base.Parent and s.token==token and player.Parent==Players and s.base:GetAttribute("OwnerUserId")==player.UserId
	end
	task.spawn(function()
		if initial then
			while valid() and player:GetAttribute("EquipmentReady")~=true do task.wait(.1) end
		end
		if not valid() then return end
		local level=math.clamp(math.floor(tonumber(player:GetAttribute("Rebirths")) or 0),0,10)
		local finish=os.clock()+30+15*level
		while valid() and os.clock()<finish do
			s.label.Text=math.ceil(finish-os.clock()).."s"
			task.wait(.1)
		end
		if not valid() then return end
		setProtection(s,false)
		s.label.Text=""
	end)
end
local function activate(s,player)
	if s.base:GetAttribute("OwnerUserId")~=player.UserId or s.active then return end
	local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health<=0 or (root.Position-s.button.Position).Magnitude>14 then return end
	startProtection(s,player,false)
end
local function ownerChanged(s)
	reset(s)
	local id=s.base:GetAttribute("OwnerUserId")
	local owner=type(id)=="number" and Players:GetPlayerByUserId(id)
	if owner then startProtection(s,owner,true) end
	for _,p in ipairs(Players:GetPlayers()) do updateCharacter(p) end
end
local function setup(base)
	if states[base] or not base:IsA("Model") or not base.Name:match("^Base%d+$") then return end
	local floor=base:WaitForChild("Floor",10); if not floor then return end
	for _,p in ipairs(base:GetChildren()) do if p.Name=="ProtectionGeometry" or p.Name=="ProtectionLaser" or p.Name=="ProtectionBarrier" or p.Name=="ProtectionPedestal" or p.Name=="ProtectionButton" then p:Destroy() end end
	local pedestal=Instance.new("Model"); pedestal.Name="ProtectionPedestal"; pedestal.Parent=base
	local cf=floor.CFrame*CFrame.new(-29,floor.Size.Y/2,-27)
	local function piece(name,size,y,color,material) return part(pedestal,name,size,cf*CFrame.new(0,y,0),color,material) end
	piece("Base",Vector3.new(4.5,.5,4.5),.25,Color3.fromRGB(35,40,52),Enum.Material.Metal)
	piece("Column",Vector3.new(2.7,2,2.7),1.5,Color3.fromRGB(75,83,103),Enum.Material.Metal)
	piece("Top",Vector3.new(3.7,.35,3.7),2.65,Color3.fromRGB(35,39,50),Enum.Material.Metal)
	local trim=piece("RedAccent",Vector3.new(3.3,.12,3.3),2.87,Color3.fromRGB(180,35,45),Enum.Material.Neon); trim.CanCollide=false
	local button=piece("ProtectionButton",Vector3.new(2.4,.4,2.4),3.15,Color3.fromRGB(235,45,55),Enum.Material.Neon); button.CanCollide=false
	local prompt=Instance.new("ProximityPrompt"); prompt.Name="CloseBasePrompt"; prompt.ActionText="Fechar base"; prompt.ObjectText="Protecao"; prompt.KeyboardKeyCode=Enum.KeyCode.E; prompt.GamepadKeyCode=Enum.KeyCode.ButtonX; prompt.HoldDuration=.5; prompt.MaxActivationDistance=12; prompt.RequiresLineOfSight=false; prompt.Parent=button
	local gui=Instance.new("BillboardGui"); gui.Name="ProtectionGui"; gui.Size=UDim2.fromOffset(80,26); gui.StudsOffset=Vector3.new(0,1.25,0); gui.AlwaysOnTop=true; gui.Parent=button
	local label=Instance.new("TextLabel"); label.Name="Status"; label.Size=UDim2.fromScale(1,1); label.BackgroundTransparency=1; label.Text=""; label.TextSize=14; label.Font=Enum.Font.GothamBold; label.TextColor3=Color3.new(1,1,1); label.TextStrokeTransparency=.35; label.Parent=gui
	local s={base=base,floor=floor,button=button,label=label,prompt=prompt,active=false,token=0,barriers={},lasers={}}
	states[base]=s; rebuild(s); setProtection(s,false)
	prompt.Triggered:Connect(function(player) activate(s,player) end)
	base:GetAttributeChangedSignal("BaseLevel"):Connect(function() rebuild(s) end)
	base:GetAttributeChangedSignal("RebirthReset"):Connect(function() reset(s) end)
	base:GetAttributeChangedSignal("OwnerUserId"):Connect(function() ownerChanged(s) end)
	base.Destroying:Connect(function() s.token+=1; states[base]=nil end)
	ownerChanged(s)
end
for _,base in ipairs(bases:GetChildren()) do setup(base) end
map:SetAttribute("ProtectionReady",true)
bases.ChildAdded:Connect(setup)
local function setupPlayer(p)
	p.CharacterAdded:Connect(function(char) char:WaitForChild("HumanoidRootPart"); if p.Character==char then updateCharacter(p) end end)
	if p.Character then updateCharacter(p) end
end
Players.PlayerAdded:Connect(setupPlayer)
for _,p in ipairs(Players:GetPlayers()) do setupPlayer(p) end
Players.PlayerRemoving:Connect(function(p) if connections[p] then connections[p]:Disconnect(); connections[p]=nil end end)
print("[BaseProtection V27.4] Protecao evolutiva inicializada!")
