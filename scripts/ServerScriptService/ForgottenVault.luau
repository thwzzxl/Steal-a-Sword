-- V44.3 | ServerScriptService > ForgottenVault
-- Apenas cenário e acesso. Não altera dados, economia ou mapa existente.
local Players = game:GetService("Players")
local map = workspace:WaitForChild("SwordGameMap")
while not map:GetAttribute("MapReady") do task.wait(.2) end
local old = map:FindFirstChild("ForgottenVault")
if old then old:Destroy() end
local vault = Instance.new("Model")
vault.Name = "ForgottenVault"
vault.Parent = map
local stone = Color3.fromRGB(76,84,99)
local dark = Color3.fromRGB(43,49,62)
local trim = Color3.fromRGB(112,125,143)
local gold = Color3.fromRGB(190,151,78)
local blue = Color3.fromRGB(72,157,207)
local function part(name, size, cf, color, material, solid)
	local p = Instance.new("Part")
	p.Name=name; p.Size=size; p.CFrame=cf; p.Color=color
	p.Material=material or Enum.Material.SmoothPlastic
	p.Anchored=true; p.CanCollide=solid~=false; p.CanTouch=false; p.CastShadow=false
	p.Parent=vault; return p
end
local function label(p, message, face)
	local gui=Instance.new("SurfaceGui"); gui.Face=face or Enum.NormalId.Front
	gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud; gui.PixelsPerStud=35; gui.Parent=p
	local t=Instance.new("TextLabel"); t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1
	t.Text=message; t.TextColor3=Color3.fromRGB(235,240,250); t.Font=Enum.Font.GothamBold; t.TextScaled=true; t.Parent=gui
end
-- Entrada na parede interna, fora da faixa da esteira.
local factory=map:WaitForChild("Decorations"):WaitForChild("SwordFactory")
local foundation=factory:WaitForChild("Foundation")
local entrance=foundation.Position+Vector3.new(17.35,0,-8)
local function entry(n,s,x,y,z,c,m,solid)
	return part(n,s,CFrame.new(entrance+Vector3.new(x,y,z)),c,m,solid)
end
local door=entry("SealedDoor",Vector3.new(.45,9,7),0,4.8,0,dark,Enum.Material.Slate,false)
for _,z in ipairs({-4,4}) do entry("DoorFrame",Vector3.new(.65,10, .8),-.1,5,z,gold,nil,false) end
entry("Lintel",Vector3.new(.65,.8,9),-.1,10,0,gold,nil,false)
entry("DoorInlay",Vector3.new(.12,7,.22),-.28,4.8,0,gold,nil,false)
local sign=entry("EntrySign",Vector3.new(.2,1.5,9),-.35,11,0,dark,nil,false)
label(sign,"FORGOTTEN VAULT",Enum.NormalId.Left)
local gate=Instance.new("ProximityPrompt"); gate.ActionText="Entrar"; gate.ObjectText="Rebirth 10+"; gate.HoldDuration=.5; gate.MaxActivationDistance=7; gate.RequiresLineOfSight=true; gate.Parent=door
-- Sala isolada fora do mapa: o resgate existente teleporta qualquer jogador abaixo de Y=-40.
local origin=Vector3.new(700,0,0)
local function room(n,s,x,y,z,c,m,solid) return part(n,s,CFrame.new(origin+Vector3.new(x,y,z)),c,m,solid) end
-- Piso único, sem plataformas coplanares. Acabamento cartoon em cores sólidas.
local floorColor=Color3.fromRGB(120,133,151)
local wallColor=Color3.fromRGB(88,101,122)
local navy=Color3.fromRGB(46,61,83)
local brass=Color3.fromRGB(170,139,82)
room("Floor",Vector3.new(80,1,64),0,-.5,0,floorColor)
room("Roof",Vector3.new(80,1,64),0,19.5,0,wallColor)
for _,x in ipairs({-40,40}) do room("Wall",Vector3.new(1,19,64),x,9.5,0,wallColor) end
for _,z in ipairs({-32,32}) do room("Wall",Vector3.new(79,19,1),0,9.5,z,wallColor) end
for _,x in ipairs({-30,30}) do
	for _,z in ipairs({-18,0,18}) do
		room("PillarBase",Vector3.new(5,1,5),x,.5,z,navy)
		room("Pillar",Vector3.new(3,16.5,3),x,9.25,z,trim)
		room("PillarCap",Vector3.new(5,1.5,5),x,18.25,z,navy)
		room("PillarBand",Vector3.new(3.2,.35,3.2),x,2,z,brass,nil,false)
	end
end
-- Passarela com juntas reais, sem faces sobrepostas.
for i=0,5 do
	room("AisleTile",Vector3.new(10,.12,5.8),0,.06,24-i*6,i%2==0 and navy or dark,nil,false)
end
for _,x in ipairs({-5.3,5.3}) do room("AisleEdge",Vector3.new(.25,.14,36),x,.07,9,brass,nil,false) end
-- Uma única plataforma circular, com degrau separado.
local dais=room("CircularDais",Vector3.new(1,24,24),0,.5,-12,navy)
dais.Shape=Enum.PartType.Cylinder; dais.CFrame=CFrame.new(origin+Vector3.new(0,.5,-12))*CFrame.Angles(0,0,math.pi/2)
room("ChestBase",Vector3.new(13,4.5,7),0,3.25,-12,navy)
room("ChestLid",Vector3.new(13.6,1.5,7.6),0,6.25,-12,trim)
for _,x in ipairs({-5,5}) do
	room("ChestBand",Vector3.new(.7,4.5,.16),x,3.25,-8.42,brass,nil,false)
	room("LidBand",Vector3.new(.7,1.5,.16),x,6.25,-8.12,brass,nil,false)
end
room("Lock",Vector3.new(1.8,1.8,.45),0,4.7,-8.15,brass,nil,false)
local plaque=room("VaultSign",Vector3.new(16,2,.3),0,9,-12,navy,nil,false)
label(plaque,"COFRE ANCESTRAL",Enum.NormalId.Back)
for _,x in ipairs({-39,39}) do
	for _,y in ipairs({1,17.5}) do room("WallTrim",Vector3.new(.5,.5,62),x,y,0,brass,nil,false) end
end
for _,z in ipairs({-31,31}) do
	for _,y in ipairs({1,17.5}) do room("WallTrim",Vector3.new(77,.5,.5),0,y,z,brass,nil,false) end
end
-- Luz local sem sombras; não altera Lighting do mapa principal.
for _,x in ipairs({-20,20}) do
	for _,z in ipairs({-18,0,18}) do
		room("LanternBase",Vector3.new(2.4,.5,2.4),x,3,z,navy,nil,false)
		local lamp=room("Lantern",Vector3.new(1.5,2,1.5),x,4.25,z,Color3.fromRGB(170,211,235),Enum.Material.SmoothPlastic,false)
		local light=Instance.new("PointLight"); light.Color=Color3.fromRGB(215,231,255); light.Brightness=.35; light.Range=16; light.Shadows=false; light.Parent=lamp
		room("LanternCap",Vector3.new(2.4,.4,2.4),x,5.45,z,brass,nil,false)
		room("LanternPedestal",Vector3.new(1.8,2.75,1.8),x,1.375,z,trim)
	end
end
-- Saída integrada à parede traseira, com moldura e placa.
local exit=room("ReturnPortal",Vector3.new(8,9,.5),0,4.5,30.8,navy,nil,false)
for _,x in ipairs({-4.6,4.6}) do room("ExitFrame",Vector3.new(1,10,1),x,5,30.5,brass,nil,false) end
room("ExitLintel",Vector3.new(10,1,1),0,10,30.5,brass,nil,false)
room("ExitSeam",Vector3.new(.15,8,.12),0,4.5,30.48,brass,nil,false)
local exitSign=room("ExitSign",Vector3.new(10,1.5,.3),0,11.5,30.4,navy,nil,false)
label(exitSign,"VOLTAR A FABRICA",Enum.NormalId.Front)
local back=Instance.new("ProximityPrompt"); back.ActionText="Voltar"; back.ObjectText="Sword Factory"; back.HoldDuration=.3; back.MaxActivationDistance=10; back.RequiresLineOfSight=false; back.Parent=exit
local function allowed(player)
	if (tonumber(player:GetAttribute("Rebirths")) or 0)<10 or player:GetAttribute("CarryingStolen") then return false end
	local folder=map:FindFirstChild("CarriedSwords")
	if folder then for _,s in ipairs(folder:GetChildren()) do if s:GetAttribute("CarrierUserId")==player.UserId then return false end end end
	return true
end
local function teleport(player, source, target, check)
	local char=player.Character; local root=char and char:FindFirstChild("HumanoidRootPart"); local hum=char and char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health<=0 or (root.Position-source.Position).Magnitude>13 then return end
	if check and not allowed(player) then return end
	char:PivotTo(target); root.AssemblyLinearVelocity=Vector3.zero; root.AssemblyAngularVelocity=Vector3.zero
end
local arrival=CFrame.lookAt(origin+Vector3.new(0,4,23),origin+Vector3.new(0,4,0))
local returnCF=CFrame.new(entrance+Vector3.new(-3,4,0))
gate.Triggered:Connect(function(p) teleport(p,door,arrival,true) end)
back.Triggered:Connect(function(p) teleport(p,exit,returnCF,false) end)
-- Verificação leve para impedir acesso por teleporte não autorizado.
task.spawn(function()
	while vault.Parent do
		for _,p in ipairs(Players:GetPlayers()) do
			local c=p.Character; local r=c and c:FindFirstChild("HumanoidRootPart")
			if r and math.abs(r.Position.X-origin.X)<42 and math.abs(r.Position.Z-origin.Z)<34 and r.Position.Y>-5 and r.Position.Y<21 and not allowed(p) then
				c:PivotTo(returnCF); r.AssemblyLinearVelocity=Vector3.zero; r.AssemblyAngularVelocity=Vector3.zero
			end
		end
		task.wait(1)
	end
end)
print("[ForgottenVault V44.3] Area e acesso criados!")

-- V44.4: interactive chest
local chest=vault:WaitForChild("ChestBase")
local prompt=Instance.new("ProximityPrompt"); prompt.ActionText="Abrir cofre"; prompt.ObjectText="$500K"; prompt.HoldDuration=.7; prompt.MaxActivationDistance=12; prompt.RequiresLineOfSight=false; prompt.Parent=chest
local gui=Instance.new("BillboardGui"); gui.Size=UDim2.fromOffset(260,65); gui.StudsOffset=Vector3.new(0,8,0); gui.AlwaysOnTop=true; gui.MaxDistance=65; gui.Parent=chest
local status=Instance.new("TextLabel"); status.Size=UDim2.fromScale(1,1); status.BackgroundTransparency=1; status.TextColor3=Color3.fromRGB(240,220,170); status.TextStrokeTransparency=.4; status.Font=Enum.Font.GothamBold; status.TextScaled=true; status.Parent=gui
local nextOpen=0; local busy=false; local messageUntil=0
prompt.Triggered:Connect(function(player)
	if busy or not allowed(player) or os.time()<nextOpen then return end
	local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position-chest.Position).Magnitude>14 then return end
	local sword=script.Parent:FindFirstChild("SwordSystem"); local grant=sword and sword:FindFirstChild("VaultClaim")
	if not grant then status.Text="Sistema indisponivel"; messageUntil=os.time()+4; return end
	busy=true
	local ok,success,msg,ends=pcall(function() return grant:Invoke(player) end)
	busy=false
	if ok and success then nextOpen=ends; status.Text=player.DisplayName..": "..msg; messageUntil=os.time()+5
	else status.Text=ok and tostring(msg) or "Erro ao abrir"; messageUntil=os.time()+4 end
end)
task.spawn(function()
	while vault.Parent do
		local left=math.max(0,nextOpen-os.time()); prompt.Enabled=left==0 and not busy
		if os.time()>=messageUntil then status.Text=left>0 and string.format("Proximo cofre: %02d:%02d",math.floor(left/60),left%60) or "COFRE DISPONIVEL" end
		task.wait(1)
	end
end)
