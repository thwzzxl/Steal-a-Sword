-- EventSystem V27 | ServerScriptService
local RS=game:GetService("ReplicatedStorage")
local Workspace=game:GetService("Workspace")
local DSS=game:GetService("DataStoreService")
local Messaging=game:GetService("MessagingService")
local RunService=game:GetService("RunService")
local OWNER=11715073634
local Data=require(script.Parent:WaitForChild("DataSystem"))
local moneyRemote=Instance.new("RemoteFunction")
moneyRemote.Name="AdminMoneyRequest"
moneyRemote.OnServerInvoke=function(player)
	if player.UserId~=OWNER then return false,"Sem permissao." end
	return Data.ToggleAdminCash(player)
end
moneyRemote.Parent=RS
local state=Instance.new("Folder")
state.Name="EventSystemState"
state:SetAttribute("ActiveEvent","None")
state:SetAttribute("EndsAt",0)
state.Parent=RS
local remote=Instance.new("RemoteFunction")
remote.Name="AdminEventRequest"
remote.Parent=RS
local map = Workspace:WaitForChild("SwordGameMap")
while not map:GetAttribute("MapReady") do map:GetAttributeChangedSignal("MapReady"):Wait() end
local arena = map:WaitForChild("Arena")
local start = arena:WaitForChild("ConveyorStart")
local finish = arena:WaitForChild("ConveyorEnd")
local colors = {Lucky=Color3.fromRGB(120,255,130), Infernal=Color3.fromRGB(255,90,35), Celestial=Color3.fromRGB(140,150,255)}
local function effects(event)
	local folder = Instance.new("Folder")
	folder.Name = "EventEffects"
	folder.Parent = arena
	for i=0,4 do
		local part = Instance.new("Part")
		part.Name = "EventEmitter"
		part.Size = Vector3.new(8,1,8)
		part.Position = start.Position:Lerp(finish.Position,i/4) + Vector3.new(0,1,0)
		part.Transparency = 1; part.Anchored = true; part.CanCollide = false; part.CanTouch = false; part.CanQuery = false
		part.Parent = folder
		local emitter = Instance.new("ParticleEmitter")
		emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		emitter.Color = ColorSequence.new(colors[event], Color3.new(1,1,1))
		emitter.Rate = 5; emitter.Lifetime = NumberRange.new(1,2.5); emitter.Speed = NumberRange.new(1,3)
		emitter.SpreadAngle = Vector2.new(40,40); emitter.LightEmission = .8
		emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,.45),NumberSequenceKeypoint.new(1,0)}); emitter.Parent = part
		local light = Instance.new("PointLight"); light.Color = colors[event]; light.Range = 18; light.Brightness = .7; light.Parent = part
	end
	return folder
end

local store=DSS:GetDataStore("SwordEvents_V27")
local topic="SwordEvents_V27"
local currentFx
local revision=0
local busy=false
local last=0
local function apply(event,ends)
	if currentFx then currentFx:Destroy(); currentFx=nil end
	if not colors[event] or ends<=Workspace:GetServerTimeNow() then event="None"; ends=0 end
	if colors[event] then currentFx=effects(event) end
	state:SetAttribute("EndsAt",ends)
	state:SetAttribute("ActiveEvent",event)
end
local function sync(data)
	if type(data)~="table" or type(data.Revision)~="number" or data.Revision<=revision then return end
	revision=data.Revision
	apply(data.Event,data.EndsAt)
end
local function readGlobal()
	local ok,data=pcall(function() return store:GetAsync("Current") end)
	if ok then sync(data) else warn("[Events] Global sync:",data) end
end
if not RunService:IsStudio() then
	task.spawn(function()
		local ok,err=pcall(function() Messaging:SubscribeAsync(topic,function(message) sync(message.Data) end) end)
		if not ok then warn("[Events] Messaging:",err) end
		while true do readGlobal(); task.wait(30) end
	end)
end
remote.OnServerInvoke=function(player,event,minutes,scope)
	if player.UserId~=OWNER then return false,"Sem permissao." end
	if event~="None" and not colors[event] then return false,"Evento invalido." end
	if not ({[1]=true,[5]=true,[10]=true,[30]=true})[minutes] then return false,"Duracao invalida." end
	if scope~="Local" and scope~="Global" then return false,"Escopo invalido." end
	if busy or os.clock()-last<1 then return false,"Aguarde um instante." end
	last=os.clock(); busy=true
	local ends=event=="None" and 0 or Workspace:GetServerTimeNow()+minutes*60
	if scope=="Global" then
		if RunService:IsStudio() then busy=false; return false,"Global disponivel no jogo publicado. Use Local no Studio." end
		local ok,data=pcall(function()
			return store:UpdateAsync("Current",function(old)
				return {Revision=math.max(revision,type(old)=="table" and (old.Revision or 0) or 0)+1,Event=event,EndsAt=ends}
			end)
		end)
		if not ok then busy=false; return false,"Falha ao salvar evento global. Tente novamente." end
		sync(data)
		local sent=pcall(function() Messaging:PublishAsync(topic,data) end)
		busy=false
		return true,sent and "Evento global atualizado!" or "Salvo; outros servidores sincronizam em ate 30s normalmente."
	end
	apply(event,ends); busy=false; return true,"Evento local atualizado!"
end
while true do
	if state:GetAttribute("ActiveEvent")~="None" and Workspace:GetServerTimeNow()>=state:GetAttribute("EndsAt") then apply("None",0) end
	task.wait(.5)
end
