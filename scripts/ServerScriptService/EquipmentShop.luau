-- EquipmentShop V39.4 | ServerScriptService
local TweenService=game:GetService("TweenService")
local Players=game:GetService('Players')
local Workspace=game:GetService('Workspace')
local ServerStorage=game:GetService('ServerStorage')
local Data=require(script.Parent:WaitForChild('DataSystem'))
local recover=script.Parent:WaitForChild('SwordSystem'):WaitForChild('RecoverWithBat')
local template=ServerStorage:WaitForChild('TungTungBatModel',15)
assert(template and template:IsA('Tool'), 'TungTungBatModel precisa ser um Tool no ServerStorage')
assert(template:FindFirstChild('Handle') and template.Handle:IsA('BasePart'), 'Handle ausente')
local map=Workspace:WaitForChild('SwordGameMap')
while not map:GetAttribute('MapReady') do map:GetAttributeChangedSignal('MapReady'):Wait() end
local items={
	{Id='Speed',Name='Speed Coil',Price=2500,Color=Color3.fromRGB(55,160,255),Model='SpeedCoil'},
	{Id='Gravity',Name='Gravity Coil',Price=7500,Color=Color3.fromRGB(175,85,255),Model='GravityCoil'},
	{Id='SuperSpeed',Name='Super Speed Coil',Price=50000,Model='SuperSpeedCoil'},
	{Id='Cloak',Name='Capa da Invisibilidade',Price=75000,Model='InvisibilityCloak'},
	{Id='Grapple',Name='Gancho',Price=150000,Model='GrapplingHook'},
}
local models=ServerStorage:WaitForChild('EquipmentModels')
local bat={Id='Bat',Name='Tung Tung Bat',Color=Color3.fromRGB(155,95,48)}
local cooldown={}
local cloaks={}
local function stopCloak(player)
	local st=cloaks[player]; if not st then return end; cloaks[player]=nil
	for obj,v in pairs(st.values) do if obj.Parent then obj.Transparency=v end end
	if st.h.Parent then st.h.DisplayDistanceType=st.display end
	if st.connection then st.connection:Disconnect() end
end
local function startCloak(player)
	local c=player.Character; local h=c and c:FindFirstChildOfClass('Humanoid'); if not h then return end
	stopCloak(player)
	local st={values={},h=h,display=h.DisplayDistanceType}; cloaks[player]=st
	local function hide(o) if o:IsA('BasePart') or o:IsA('Decal') or o:IsA('Texture') then st.values[o]=o.Transparency; o.Transparency=1 end end
	for _,o in ipairs(c:GetDescendants()) do hide(o) end
	st.connection=c.DescendantAdded:Connect(hide); h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
	task.delay(8,function() if cloaks[player]==st then stopCloak(player) end end)
end
local function imported(item)
	local src=models:FindFirstChild(item.Model) or (item.Id=='Grapple' and models:FindFirstChild('GrappleHook'))
	if not src or not src:IsA('Tool') or not src:FindFirstChild('Handle') or not src.Handle:IsA('BasePart') then return nil end
	local t=src:Clone()
	for _,o in ipairs(t:GetDescendants()) do if o:IsA('LuaSourceContainer') or o:IsA('RemoteEvent') or o:IsA('RemoteFunction') or o:IsA('UnreliableRemoteEvent') then o:Destroy() end end
	for _,o in ipairs(t:GetDescendants()) do if o:IsA('BasePart') then o.Anchored=false; o.CanCollide=false; o.CanTouch=false; o.CanQuery=false; o.Massless=true; if o~=t.Handle then local w=Instance.new('WeldConstraint'); w.Part0=t.Handle; w.Part1=o; w.Parent=o end end end
	return t
end
local function notice(player,msg)
	local pg=player:FindFirstChildOfClass('PlayerGui'); if not pg then return end
	local old=pg:FindFirstChild('EquipmentNotice'); if old then old:Destroy() end
	local gui=Instance.new('ScreenGui'); gui.Name='EquipmentNotice'; gui.ResetOnSpawn=false
	local label=Instance.new('TextLabel'); label.Size=UDim2.new(.65,0,0,45); label.Position=UDim2.new(.175,0,.23,0); label.BackgroundColor3=Color3.fromRGB(35,43,58); label.TextColor3=Color3.new(1,1,1); label.TextSize=18; label.TextWrapped=true; label.Font=Enum.Font.GothamBold; label.Text=msg; label.Parent=gui; gui.Parent=pg
	task.delay(3,function() gui:Destroy() end)
end
local function part(parent,name,size,cf,color,material,anchored)
	local a=Instance.new('Part'); a.Name=name; a.Size=size; a.CFrame=cf; a.Color=color; a.Material=material or Enum.Material.SmoothPlastic; a.Anchored=anchored; a.CanCollide=false; a.CanTouch=false; a.Massless=true; a.Parent=parent; return a
end
local function refreshSpeed(player)
	local h=player.Character and player.Character:FindFirstChildOfClass('Humanoid'); if not h then return end
	h.WalkSpeed=player:GetAttribute('CarryingStolen') and 15 or (player:GetAttribute('SuperSpeedEquipped') and 38 or (player:GetAttribute('SpeedCoilEquipped') and 30 or 20))
end
-- V27.1: bloquear equipamentos no servidor durante o roubo.
local function lockEquipment(player)
	local character=player.Character
	local h=character and character:FindFirstChildOfClass('Humanoid')
	if not player:GetAttribute('CarryingStolen') then refreshSpeed(player); return end
	stopCloak(player)
	player:SetAttribute('SuperSpeedEquipped',false)
	player:SetAttribute('ShieldUntil',0)
	player:SetAttribute('SpeedCoilEquipped',false)
	if character then
		local shield=character:FindFirstChild('EquipmentShield')
		if shield then shield:Destroy() end
		if h then h:UnequipTools() end
	end
	refreshSpeed(player)
end
local function sound(handle,name)
	local s=handle:FindFirstChild(name); if s and s:IsA('Sound') then s:Play() end
end
-- V25.5: server-authoritative cartoon ragdoll (R6/R15).
local ragdolls={}
local immunity=setmetatable({}, {__mode="k"})
local BAT={Cooldown=2, Duration=1, Recovery=1.25, Force=24, Lift=9, Range=10}
local function ragdoll(target, direction)
	local character=target.Character
	local h=character and character:FindFirstChildOfClass('Humanoid')
	local root=character and character:FindFirstChild('HumanoidRootPart')
	if not h or not root or h.Health<=0 or ragdolls[character] or (immunity[character] or 0)>Workspace:GetServerTimeNow() then return false end
	local state={motors={},objects={},collisions={},auto=h.AutoRotate,platform=h.PlatformStand,neck=h.RequiresNeck}
	ragdolls[character]=state
	h.RequiresNeck=false; h.AutoRotate=false; h.PlatformStand=true
	for _,m in ipairs(character:GetDescendants()) do
		if m:IsA('Motor6D') and m.Enabled and m.Part0 and m.Part1 and m.Part0~=root and m.Part1~=root and m.Part0.Parent==character and m.Part1.Parent==character then
			local a=Instance.new('Attachment'); a.CFrame=m.C0; a.Parent=m.Part0
			local b=Instance.new('Attachment'); b.CFrame=m.C1; b.Parent=m.Part1
			local c=Instance.new('BallSocketConstraint'); c.Attachment0=a; c.Attachment1=b; c.LimitsEnabled=true; c.UpperAngle=65; c.TwistLimitsEnabled=true; c.TwistLowerAngle=-45; c.TwistUpperAngle=45; c.Parent=m.Part0
			local n=Instance.new('NoCollisionConstraint'); n.Part0=m.Part0; n.Part1=m.Part1; n.Parent=m.Part0
			table.insert(state.objects,a); table.insert(state.objects,b); table.insert(state.objects,c); table.insert(state.objects,n)
			table.insert(state.motors,m); m.Enabled=false
		end
	end
	for _,p in ipairs(character:GetChildren()) do
		if p:IsA('BasePart') and p~=root then state.collisions[p]=p.CanCollide; p.CanCollide=true end
	end
	pcall(function() root:SetNetworkOwner(nil) end)
	h:ChangeState(Enum.HumanoidStateType.Physics)
	-- Apply the same launch velocity to each ragdoll assembly.
	local launched={}
	for _,p in ipairs(character:GetChildren()) do
		if p:IsA('BasePart') then
			local assembly=p.AssemblyRootPart
			if assembly and not assembly.Anchored and not launched[assembly] then
				launched[assembly]=true
				pcall(function() assembly:SetNetworkOwner(nil) end)
				assembly.AssemblyLinearVelocity=direction*BAT.Force+Vector3.new(0,BAT.Lift,0)
			end
		end
	end
	local function finish()
		if ragdolls[character]~=state then return end
		ragdolls[character]=nil
		immunity[character]=Workspace:GetServerTimeNow()+BAT.Recovery
		for _,m in ipairs(state.motors) do if m.Parent then m.Enabled=true end end
		for _,o in ipairs(state.objects) do o:Destroy() end
		for p,v in pairs(state.collisions) do if p.Parent then p.CanCollide=v end end
		if h.Parent then
			h.RequiresNeck=state.neck; h.AutoRotate=state.auto; h.PlatformStand=state.platform
			if h.Health>0 and root.Parent then
				root.AssemblyLinearVelocity=Vector3.zero; root.AssemblyAngularVelocity=Vector3.zero
				local look=root.CFrame.LookVector; local flat=Vector3.new(look.X,0,look.Z)
				if flat.Magnitude<.01 then flat=Vector3.new(0,0,-1) end
				root.CFrame=CFrame.lookAt(root.Position+Vector3.new(0,1,0),root.Position+Vector3.new(0,1,0)+flat.Unit)
				h:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		end
		for assembly in pairs(launched) do if assembly.Parent then pcall(function() assembly:SetNetworkOwnershipAuto() end) end end
		if target.Character==character then refreshSpeed(target) end
	end
	task.delay(BAT.Duration,finish)
	h.Died:Once(finish)
	return true
end
local function batHit(player,character,tool,handle)
	if player:GetAttribute('CarryingStolen') or player.Character~=character or tool.Parent~=character or ragdolls[character] then return false end
	local root=character:FindFirstChild('HumanoidRootPart'); local h=character:FindFirstChildOfClass('Humanoid')
	if not root or not h or h.Health<=0 then return false end
	local now=Workspace:GetServerTimeNow()
	local best,dist
	local ray=RaycastParams.new(); ray.FilterType=Enum.RaycastFilterType.Exclude; ray.RespectCanCollide=true
	for _,target in ipairs(Players:GetPlayers()) do
		local model=target.Character
		local tr=model and model:FindFirstChild('HumanoidRootPart'); local th=model and model:FindFirstChildOfClass('Humanoid')
		if target~=player and tr and th and th.Health>0 and not ragdolls[model] and (immunity[model] or 0)<=now and (target:GetAttribute('ShieldUntil') or 0)<=now then
			local delta=tr.Position-root.Position; local pos=root.CFrame:PointToObjectSpace(tr.Position)
			if math.abs(pos.X)<=6 and math.abs(pos.Y)<=5 and pos.Z<=2 and delta.Magnitude<=BAT.Range then
				ray.FilterDescendantsInstances={character,model}
				local visible=false
				for _,offset in ipairs({Vector3.zero,Vector3.new(0,2,0),Vector3.new(0,-1,0)}) do
					local aim=tr.Position+offset-root.Position
					if not Workspace:Raycast(root.Position,aim,ray) then visible=true; break end
				end
				if visible and (not dist or delta.Magnitude<dist) then best=target; dist=delta.Magnitude end
			end
		end
	end
	if not best then return false end
	local tr=best.Character:FindFirstChild('HumanoidRootPart')
	local delta=tr.Position-root.Position; local flat=Vector3.new(delta.X,0,delta.Z)
	local direction=flat.Magnitude>.01 and flat.Unit or root.CFrame.LookVector
	-- Recover before physics changes the target position; the server validates the sword.
	local ok,recovered=pcall(function() return recover:Invoke(player,best) end)
	if not ok then warn('[EquipmentShop] RecoverWithBat:',recovered) end
	if ok and recovered then notice(player,'TUNG TUNG! Espada recuperada!') end
	if ragdoll(best,direction) then sound(handle,'Hit') end
	return true
end

local function grant(player,item)
	local backpack=player:FindFirstChildOfClass('Backpack'); if not backpack then return end
	if backpack:FindFirstChild(item.Name) or (player.Character and player.Character:FindFirstChild(item.Name)) then return end
	local tool,handle
	if item.Id=='Bat' then
		tool=template:Clone()
		-- Nunca executar codigo importado da Toolbox.
		for _,obj in ipairs(tool:GetDescendants()) do
			if obj:IsA('LuaSourceContainer') or obj:IsA('RemoteEvent') or obj:IsA('RemoteFunction') or obj:IsA('UnreliableRemoteEvent') then obj:Destroy() end
		end
		handle=tool:FindFirstChild('Handle')
		-- Usar somente o Handle visual e os recursos de audio/animacao.
		for _,obj in ipairs(tool:GetChildren()) do
			if obj~=handle then obj:Destroy() end
		end
		for _,obj in ipairs(handle:GetDescendants()) do
			if obj:IsA('BasePart') then obj:Destroy() end
		end
		handle.Anchored=false; handle.CanCollide=false; handle.CanTouch=false; handle.Massless=true
	elseif item.Model then
		tool=imported(item); if not tool then warn('Modelo ausente:',item.Model); return end; handle=tool.Handle
	else
		tool=Instance.new('Tool')
		handle=part(tool,'Handle',Vector3.new(.5,2,.5),CFrame.new(),item.Color,nil,false)
		local function detail(name,size,cf,color,mat)
			local a=part(tool,name,size,cf,color,mat,false); local w=Instance.new('WeldConstraint'); w.Part0=handle; w.Part1=a; w.Parent=a; return a
		end
		if item.Id=='Shield' then
			detail('Shield',Vector3.new(2.5,3,.25),CFrame.new(0,.6,.4),item.Color,Enum.Material.Neon)
		else
			for i=0,19 do local angle=i*math.pi/3; detail('Coil',Vector3.new(.35,.35,.35),CFrame.new(math.cos(angle)*.55,-.9+i*.1,math.sin(angle)*.55),item.Color,Enum.Material.Neon) end
		end
	end
	tool:SetAttribute('EquipmentId',item.Id); tool.Name=item.Name; tool.CanBeDropped=false; tool.RequiresHandle=true; tool.Enabled=true; tool.ManualActivationOnly=false
	local oldJump,oldHeight,gravityHumanoid
	local baseGrip=tool.Grip
	local swingTweens={}
	local swingOriginals={}
	local swingToken=0
	local trail
	if item.Id=='Bat' then
		local a=Instance.new('Attachment'); a.Position=Vector3.new(0,-handle.Size.Y*.45,0); a.Parent=handle
		local b=Instance.new('Attachment'); b.Position=Vector3.new(0,handle.Size.Y*.45,0); b.Parent=handle
		trail=Instance.new('Trail'); trail.Attachment0=a; trail.Attachment1=b; trail.Lifetime=.14; trail.Enabled=false
		trail.Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(255,210,75)); trail.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.15),NumberSequenceKeypoint.new(1,1)}); trail.Parent=handle
	end
	local function resetSwing()
		swingToken+=1
		for _,t in ipairs(swingTweens) do t:Cancel() end
		for joint,cf in pairs(swingOriginals) do if joint.Parent then joint.C0=cf end end
		table.clear(swingTweens); table.clear(swingOriginals)
		tool.Grip=baseGrip
		if trail then trail.Enabled=false end
	end
	local function swing()
		resetSwing()
		local token=swingToken
		local character=player.Character
		local shoulder
		for _,j in ipairs(character:GetDescendants()) do
			if j:IsA('Motor6D') and (j.Name=='RightShoulder' or j.Name=='Right Shoulder') then shoulder=j; break end
		end
		if shoulder then swingOriginals[shoulder]=shoulder.C0 end
		local function pose(angle,gripAngle,duration)
			for _,t in ipairs(swingTweens) do t:Cancel() end
			table.clear(swingTweens)
			local info=TweenInfo.new(duration,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
			if shoulder and shoulder.Parent then
				local t=TweenService:Create(shoulder,info,{C0=swingOriginals[shoulder]*CFrame.Angles(math.rad(angle),0,math.rad(-12))}); table.insert(swingTweens,t); t:Play()
			end
			local t=TweenService:Create(tool,info,{Grip=baseGrip*CFrame.Angles(math.rad(gripAngle),0,0)}); table.insert(swingTweens,t); t:Play()
		end
		pose(-55,35,.16)
		task.delay(.16,function()
			if token~=swingToken or tool.Parent~=character then return end
			if trail then trail.Enabled=true end
			pose(75,-65,.12)
		end)
		task.delay(.31,function()
			if token~=swingToken or tool.Parent~=character then return end
			if trail then trail.Enabled=false end
			pose(0,0,.22)
		end)
		task.delay(.56,function() if token==swingToken then resetSwing() end end)
	end
	tool.Equipped:Connect(function()
		if player:GetAttribute('CarryingStolen') then lockEquipment(player); return end
		local h=player.Character and player.Character:FindFirstChildOfClass('Humanoid'); if not h then return end
		if item.Id=='Speed' then player:SetAttribute('SpeedCoilEquipped',true); refreshSpeed(player)
		elseif item.Id=='SuperSpeed' then player:SetAttribute('SuperSpeedEquipped',true); refreshSpeed(player)
		elseif item.Id=='Gravity' then gravityHumanoid=h; oldJump=h.JumpPower; oldHeight=h.JumpHeight; if h.UseJumpPower then h.JumpPower=75 else h.JumpHeight=14 end

		end
	end)
	tool.Unequipped:Connect(function()
		if item.Id=='Bat' then
			resetSwing()
		elseif item.Id=='Speed' then player:SetAttribute('SpeedCoilEquipped',false); refreshSpeed(player)
		elseif item.Id=='SuperSpeed' then player:SetAttribute('SuperSpeedEquipped',false); refreshSpeed(player)
		elseif item.Id=='Cloak' then stopCloak(player)
		elseif item.Id=='Gravity' and gravityHumanoid and gravityHumanoid.Parent then gravityHumanoid.JumpPower=oldJump; gravityHumanoid.JumpHeight=oldHeight; gravityHumanoid=nil
		end
	end)
	tool.Activated:Connect(function()
		if player:GetAttribute('CarryingStolen') then lockEquipment(player); return end
		if tool.Parent~=player.Character then return end
		if item.Id~='Bat' and not player:GetAttribute('EquipmentReady') then return end
		local root=player.Character:FindFirstChild('HumanoidRootPart'); local h=player.Character:FindFirstChildOfClass('Humanoid'); if not root or not h or h.Health<=0 then return end
		local now=Workspace:GetServerTimeNow(); cooldown[player]=cooldown[player] or {}; local cd=cooldown[player]
		if item.Id=='Bat' then
			if ragdolls[player.Character] or now<(cd.Bat or 0) then return end; cd.Bat=now+BAT.Cooldown
			print('[EquipmentShop] Bat ativado:',player.Name)
			swing()
			sound(handle,'Slash')
			local character=player.Character
			task.spawn(function()
				for i=1,12 do
					if player.Character~=character or tool.Parent~=character or player:GetAttribute('CarryingStolen') then break end
					if batHit(player,character,tool,handle) then break end
					if i<12 then task.wait(.04) end
				end
			end)
		elseif item.Id=='Cloak' then
			if now<(cd.Cloak or 0) then return end; cd.Cloak=now+30; startCloak(player); notice(player,'Invisibilidade: 8 segundos!')
		elseif item.Id=='Shield' then
			if now<(cd.Shield or 0) then return end; cd.Shield=now+30; player:SetAttribute('ShieldUntil',now+5)
			local bubble=Instance.new('Highlight'); bubble.Name='EquipmentShield'; bubble.FillColor=item.Color; bubble.FillTransparency=.65; bubble.OutlineColor=item.Color; bubble.Parent=player.Character
			task.delay(5,function() bubble:Destroy() end); notice(player,'Escudo ativo por 5 segundos!')
		end
	end)
	tool.Parent=backpack
end
local function restore(player)
	-- Bastao gratuito, independente de compra ou dados antigos.
	grant(player,bat)
	if not player:GetAttribute('EquipmentReady') then return end
	local owned=Data.GetEquipment(player); if not owned then return end
	for _,item in ipairs(items) do if owned[item.Id] then grant(player,item) end end
end
local function setup(player)
	player:GetAttributeChangedSignal('CarryingStolen'):Connect(function() lockEquipment(player) end)
	local function watchCharacter(character)
		character.ChildAdded:Connect(function(child)
			if child:IsA('Tool') and player:GetAttribute('CarryingStolen') then
				lockEquipment(player)
			end
		end)
		lockEquipment(player)
	end
	player.CharacterAdded:Connect(watchCharacter)
	if player.Character then watchCharacter(player.Character) end
	player:GetAttributeChangedSignal('EquipmentReady'):Connect(function() restore(player) end)
	player.CharacterAdded:Connect(function(character)
		stopCloak(player); player:SetAttribute('SuperSpeedEquipped',false); player:SetAttribute('SpeedCoilEquipped',false); player:SetAttribute('ShieldUntil',0)
		character:WaitForChild('Humanoid'); refreshSpeed(player)
		task.defer(function() player:WaitForChild('Backpack',10); restore(player) end)
	end)
	task.defer(function() player:WaitForChild('Backpack',10); restore(player) end)
end
Players.PlayerAdded:Connect(setup); for _,player in ipairs(Players:GetPlayers()) do setup(player) end
Players.PlayerRemoving:Connect(function(player) cooldown[player]=nil; stopCloak(player) end)

local RS=game:GetService('ReplicatedStorage')
local net=Instance.new('Folder'); net.Name='EquipmentShopV20'; net.Parent=RS
local open=Instance.new('RemoteEvent'); open.Name='Open'; open.Parent=net
local request=Instance.new('RemoteFunction'); request.Name='Request'; request.Parent=net
local grapple=Instance.new('RemoteEvent'); grapple.Name='Grapple'; grapple.Parent=net
local RunService=game:GetService('RunService')
grapple.OnServerEvent:Connect(function(player,target)
	if typeof(target)~='Vector3' or target.X~=target.X or target.Y~=target.Y or target.Z~=target.Z then return end
	local c=player.Character; local root=c and c:FindFirstChild('HumanoidRootPart'); local h=c and c:FindFirstChildOfClass('Humanoid'); local tool=c and c:FindFirstChildOfClass('Tool')
	if not root or not h or h.Health<=0 or not tool or tool:GetAttribute('EquipmentId')~='Grapple' or not player:GetAttribute('EquipmentReady') or player:GetAttribute('CarryingStolen') or ragdolls[c] then return end
	local delta=target-root.Position; if delta.Magnitude<5 or delta.Magnitude>120 then return end
	local now=Workspace:GetServerTimeNow(); cooldown[player]=cooldown[player] or {}; local cd=cooldown[player]; if now<(cd.Grapple or 0) then return end
	local ray=RaycastParams.new(); ray.FilterType=Enum.RaycastFilterType.Exclude; ray.FilterDescendantsInstances={c}; ray.RespectCanCollide=true; ray.CollisionGroup=root.CollisionGroup
	local hit=Workspace:Raycast(root.Position,delta.Unit*math.min(120,delta.Magnitude+3),ray); if not hit then return end
	cd.Grapple=now+8
	local goal=hit.Position; local a=Instance.new('Attachment',root); local marker=Instance.new('Part'); marker.Size=Vector3.new(.1,.1,.1); marker.Transparency=1; marker.Anchored=true; marker.CanCollide=false; marker.CanQuery=false; marker.CanTouch=false; marker.Position=goal; marker.Parent=Workspace
	local b=Instance.new('Attachment',marker); local beam=Instance.new('Beam',root); beam.Attachment0=a; beam.Attachment1=b; beam.Width0=.08; beam.Width1=.08; beam.Color=ColorSequence.new(Color3.fromRGB(210,210,210))
	local elapsed=0; local conn; conn=RunService.Heartbeat:Connect(function(dt)
		elapsed+=dt; local d=goal-root.Position
		if elapsed>1.5 or d.Magnitude<5 or player.Character~=c or not root.Parent or h.Health<=0 or tool.Parent~=c or player:GetAttribute('CarryingStolen') or ragdolls[c] or Workspace:Raycast(root.Position,d.Unit*math.min(5,d.Magnitude),ray) then
			conn:Disconnect(); beam:Destroy(); a:Destroy(); marker:Destroy(); if root.Parent then root.AssemblyLinearVelocity=Vector3.zero end; return end
		root.AssemblyLinearVelocity=d.Unit*65
	end)
end)
local previews=Instance.new('Folder'); previews.Name='Previews'; previews.Parent=net
local shop=Instance.new('Model'); shop.Name='EquipmentShop'; shop.Parent=map
local ground=map:WaitForChild('Ground')
local foundation=map:WaitForChild('Decorations'):WaitForChild('SwordFactory'):WaitForChild('Foundation')
local cf=CFrame.new(46,ground.Position.Y+ground.Size.Y/2+.5,0)*CFrame.Angles(0,math.rad(-90),0)
-- V34.2: barraca aberta, estilo classico.
local wood=Color3.fromRGB(156,105,65)
local trim=Color3.fromRGB(193,145,92)
local stone=Color3.fromRGB(170,174,184)
local blue=Color3.fromRGB(48,155,218)
local white=Color3.fromRGB(245,245,238)
local function build(name,size,x,y,z,color,solid,rotation)
	local p=part(shop,name,size,cf*CFrame.new(x,y,z)*(rotation or CFrame.new()),color,nil,true)
	p.CanCollide=solid==true; p.CanQuery=solid==true; return p
end
local floor=build('ShopFloor',Vector3.new(17,1,10),0,0,0,stone,true)
floor.TopSurface=Enum.SurfaceType.Studs
for _,x in ipairs({-6.5,6.5}) do
	for _,z in ipairs({-3,3}) do
		build('Post',Vector3.new(.65,7.6,.65),x,4.3,z,wood,true)
	end
end
for i=1,8 do
	local x=(i-4.5)*1.9
	local c=i%2==0 and white or blue
	build('Awning',Vector3.new(1.92,.3,8.4),x,8.35,0,c,false,CFrame.Angles(math.rad(8),0,0))
	build('Valance',Vector3.new(1.92,.65,.3),x,7.65,4.15,c,false)
end
local counter=build('Counter',Vector3.new(12,2.5,1.6),0,1.75,3.25,wood,true)
build('CounterTop',Vector3.new(12.8,.3,2.1),0,3.15,3.25,trim,true)
for _,x in ipairs({-6,6}) do
	build('SideRail',Vector3.new(.3,.5,5.5),x,2.1,0,wood,true)
end
local sign=build('ShopSign',Vector3.new(1,1,1),0,11.4,0,wood,false)
sign.Transparency=1; sign.CanTouch=false
local sg=Instance.new('BillboardGui'); sg.Size=UDim2.fromOffset(180,49); sg.MaxDistance=100; sg.AlwaysOnTop=false; sg.Parent=sign
local title=Instance.new('TextLabel'); title.Size=UDim2.fromScale(1,1); title.BackgroundTransparency=1; title.Text='Loja'; title.TextColor3=Color3.fromRGB(55,230,55); title.TextStrokeColor3=Color3.new(0,0,0); title.TextStrokeTransparency=0; title.TextScaled=true; title.Font=Enum.Font.FredokaOne; title.Parent=sg
-- NPC R15 real, criado no ServerStorage.
local merchantTemplate=ServerStorage:FindFirstChild('EquipmentMerchant')
local merchant
if merchantTemplate and merchantTemplate:IsA('Model') and merchantTemplate:FindFirstChildOfClass('Humanoid') and merchantTemplate:FindFirstChild('HumanoidRootPart') then
	merchant=merchantTemplate:Clone(); merchant.Name='Comerciante'; merchant.Parent=shop
	local humanoid=merchant:FindFirstChildOfClass('Humanoid')
	humanoid.DisplayName='Comerciante'; humanoid.HealthDisplayType=Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.WalkSpeed=0; humanoid.AutoRotate=false
	-- Aparencia classica, sem depender de roupas externas.
	local skin=Color3.fromRGB(245,195,130)
	local shirt=Color3.fromRGB(238,240,245)
	local apron=Color3.fromRGB(35,105,190)
	local pants=Color3.fromRGB(48,57,76)
	local colors=merchant:FindFirstChildOfClass('BodyColors') or Instance.new('BodyColors',merchant)
	colors.HeadColor3=skin; colors.LeftArmColor3=skin; colors.RightArmColor3=skin
	colors.TorsoColor3=apron; colors.LeftLegColor3=pants; colors.RightLegColor3=pants
	for _,p in ipairs(merchant:GetChildren()) do
		if p:IsA('BasePart') and p.Name~='HumanoidRootPart' then
			p.Color=skin; p.Material=Enum.Material.SmoothPlastic
			if p.Name=='UpperTorso' or p.Name=='LowerTorso' then p.Color=apron
			elseif p.Name:find('UpperArm') then p.Color=shirt
			elseif p.Name:find('Leg') or p.Name:find('Foot') then p.Color=pants end
		end
	end
	local head=merchant:FindFirstChild('Head')
	if head then
		local face=head:FindFirstChild('face') or Instance.new('Decal',head)
		face.Name='face'; face.Face=Enum.NormalId.Front; face.Texture='rbxasset://textures/face.png'
		local function hatPart(name,size,offset,color)
			local p=Instance.new('Part'); p.Name=name; p.Size=size; p.Shape=Enum.PartType.Cylinder
			p.Color=color; p.Material=Enum.Material.SmoothPlastic; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.Massless=true
			p.CFrame=head.CFrame*CFrame.new(0,head.Size.Y/2+offset,0)*CFrame.Angles(0,0,math.pi/2)
			p.Parent=merchant
			local weld=Instance.new('WeldConstraint'); weld.Part0=head; weld.Part1=p; weld.Parent=p
		end
		hatPart('HatBrim',Vector3.new(.12,2.1,2.1),.06,Color3.fromRGB(211,166,77))
		hatPart('HatCrown',Vector3.new(.55,1.3,1.3),.35,Color3.fromRGB(211,166,77))
		hatPart('HatBand',Vector3.new(.15,1.33,1.33),.16,apron)
	end
	-- Detalhes do avental, presos ao torso do R15.
	local torso=merchant:FindFirstChild('UpperTorso')
	if torso then
		local function detail(name,size,offset,color)
			local p=Instance.new('Part'); p.Name=name; p.Size=size; p.Color=color
			p.Material=Enum.Material.SmoothPlastic; p.CanCollide=false; p.Massless=true
			p.CFrame=torso.CFrame*CFrame.new(offset); p.Parent=merchant
			local w=Instance.new('WeldConstraint'); w.Part0=torso; w.Part1=p; w.Parent=p
		end
		local z=-torso.Size.Z/2-.025
		detail('ApronPocket',Vector3.new(.65,.38,.06),Vector3.new(0,-.22,z),Color3.fromRGB(22,73,145))
		for _,x in ipairs({-.36,.36}) do
			detail('ApronStrap',Vector3.new(.16,.52,.05),Vector3.new(x,.25,z),Color3.fromRGB(20,65,130))
			detail('GoldButton',Vector3.new(.13,.13,.07),Vector3.new(x,.04,z-.035),Color3.fromRGB(245,190,55))
		end
	end
	merchant:ScaleTo(1.15)
	humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.Viewer
	humanoid.NameDisplayDistance=30
	for _,p in ipairs(merchant:GetDescendants()) do
		if p:IsA('BasePart') then p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false end
	end
	local root=merchant.HumanoidRootPart; root.Anchored=true
	merchant:PivotTo(cf*CFrame.new(0,0,1)*CFrame.Angles(0,math.pi,0))
	local bounds,size=merchant:GetBoundingBox()
	local bottom=bounds.Position.Y-size.Y/2
	merchant:PivotTo(merchant:GetPivot()+Vector3.new(0,cf.Position.Y+1.15-bottom,0))
	-- NPC estatico: remove scripts de animacao e interrompe tracks existentes.
	for _,obj in ipairs(merchant:GetDescendants()) do
		if obj:IsA('BaseScript') then obj:Destroy() end
	end
	local animator=humanoid:FindFirstChildOfClass('Animator')
	if animator then
		for _,track in ipairs(animator:GetPlayingAnimationTracks()) do track:Stop(0) end
	end
	humanoid.JumpPower=0; humanoid.JumpHeight=0
	humanoid.AutoRotate=false

else
	warn('[EquipmentShop] EquipmentMerchant R15 ausente; usando interacao no balcao.')
end
local all=items
for i,item in ipairs(all) do
	local model=Instance.new('Model'); model.Name=item.Id; model.Parent=previews
	if item.Model then
		local t=imported(item); if t then for _,o in ipairs(t:GetChildren()) do o.Parent=model end; t:Destroy(); for _,o in ipairs(model:GetDescendants()) do if o:IsA('BasePart') then o.Anchored=true end end end
	elseif item.Id=='Bat' then
		local h=template.Handle:Clone(); for _,o in ipairs(h:GetDescendants()) do if o:IsA('LuaSourceContainer') or o:IsA('BasePart') or o:IsA('Sound') or o:IsA('RemoteEvent') or o:IsA('RemoteFunction') then o:Destroy() end end
		h.Anchored=true; h.CFrame=CFrame.new(); h.Parent=model
	else
		part(model,'Handle',Vector3.new(.5,2,.5),CFrame.new(),item.Color,nil,true)
		if item.Id=='Shield' then part(model,'Shield',Vector3.new(2.5,3,.25),CFrame.new(0,.6,.4),item.Color,Enum.Material.SmoothPlastic,true)
		else for j=0,19 do local a=j*math.pi/3; part(model,'Coil',Vector3.new(.35,.35,.35),CFrame.new(math.cos(a)*.55,-.9+j*.1,math.sin(a)*.55),item.Color,Enum.Material.SmoothPlastic,true) end end
	end
end
local prompt=Instance.new('ProximityPrompt'); prompt.ActionText='Abrir loja'; prompt.ObjectText='Equipamentos'; prompt.HoldDuration=.2; prompt.MaxActivationDistance=12; prompt.RequiresLineOfSight=false; prompt.Parent=(merchant and merchant:FindFirstChild('Head')) or counter
local function near(player)
	local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart'); local h=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
	return root and h and h.Health>0 and (root.Position-counter.Position).Magnitude<=16
end
prompt.Triggered:Connect(function(player) if near(player) then open:FireClient(player) end end)
local function state(player)
	local owned=Data.GetEquipment(player) or {}; local result={Bat=true}
	for _,item in ipairs(items) do result[item.Id]=owned[item.Id]==true end
	return result
end
request.OnServerInvoke=function(player,action,id)
	if not near(player) or not player:GetAttribute('EquipmentReady') then return false,'Aproxime-se da loja e aguarde seus dados.' end
	if action=='State' then return true,state(player) end
	if player:GetAttribute('CarryingStolen') then return false,'Termine o roubo antes de usar equipamentos!' end
	local item; for _,v in ipairs(all) do if v.Id==id then item=v end end
	if not item or (action~='Buy' and action~='Equip') then return false,'Solicitação inválida.' end
	if item.Model then local t=imported(item); if not t then return false,'Modelo indisponível.' end; t:Destroy() end
	local owned=state(player)
	if not owned[id] then
		if action~='Buy' then return false,'Compre primeiro.' end
		local stats=player:FindFirstChild('leaderstats'); local cash=stats and stats:FindFirstChild('Cash')
		if not cash or cash.Value<item.Price then return false,'Dinheiro insuficiente!' end
		if not Data.SetEquipment(player,id) then return false,'Não foi possível comprar.' end
		cash.Value-=item.Price
	end
	grant(player,item)
	if action=='Equip' then
		local backpack=player:FindFirstChildOfClass('Backpack'); local tool=backpack and backpack:FindFirstChild(item.Name); local h=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
		if tool and h then h:EquipTool(tool) end
	end
	return true,state(player)
end
print('[EquipmentShop V34.2] Barraca pronta!')
