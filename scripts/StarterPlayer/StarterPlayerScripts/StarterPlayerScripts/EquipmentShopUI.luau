-- EquipmentShopUI V36 | StarterPlayerScripts (LocalScript)
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Lighting=game:GetService('Lighting')
local StarterGui=game:GetService('StarterGui')
local UIS=game:GetService('UserInputService')
local player=Players.LocalPlayer
local net=RS:WaitForChild('EquipmentShopV20')
local request=net:WaitForChild('Request')
local previews=net:WaitForChild('Previews')
local pg=player:WaitForChild('PlayerGui')
local gui=Instance.new('ScreenGui'); gui.Name='EquipmentShopUI'; gui.ResetOnSpawn=false; gui.DisplayOrder=30; gui.Enabled=false; gui.Parent=pg
local function make(class,parent,props)
	local o=Instance.new(class); for k,v in pairs(props) do o[k]=v end; o.Parent=parent; return o
end
local function round(o,r) make('UICorner',o,{CornerRadius=UDim.new(0,r)}) end
local function stroke(o,c,t) make('UIStroke',o,{Color=c,Thickness=t,ApplyStrokeMode=Enum.ApplyStrokeMode.Border}) end
local function frame(p,n,s,pos,c,r)
	local f=make('Frame',p,{Name=n,Size=s,Position=pos,BackgroundColor3=c,BorderSizePixel=0}); if r then round(f,r) end; return f
end
local white=Color3.fromRGB(245,248,255)
local muted=Color3.fromRGB(190,205,224)
local green=Color3.fromRGB(48,113,53)
local function text(p,n,v,s,pos,c,ts,button)
	return make(button and 'TextButton' or 'TextLabel',p,{Name=n,Text=v,Size=s,Position=pos,TextColor3=c,Font=Enum.Font.FredokaOne,TextSize=ts,TextWrapped=true,TextStrokeColor3=Color3.new(),TextStrokeTransparency=.15,BackgroundTransparency=1,BorderSizePixel=0})
end
local shade=frame(gui,'Shade',UDim2.fromScale(1,1),UDim2.new(),Color3.new()); shade.BackgroundTransparency=.45; shade.Active=true
local panel=frame(shade,'Shop',UDim2.fromOffset(680,460),UDim2.fromScale(.5,.5),Color3.fromRGB(38,48,53),5); panel.AnchorPoint=Vector2.new(.5,.5); stroke(panel,Color3.fromRGB(69,100,137),2)
local scale=make('UIScale',panel,{Scale=1})
local header=frame(panel,'Header',UDim2.new(1,0,0,72),UDim2.new(),Color3.fromRGB(75,104,119),4)
local title=text(header,'Title','LOJA',UDim2.new(1,-76,0,36),UDim2.fromOffset(18,7),white,26); title.TextXAlignment=Enum.TextXAlignment.Left
local subtitle=text(header,'Subtitle','Compre ferramentas para proteger sua base!',UDim2.new(1,-76,0,24),UDim2.fromOffset(18,41),muted,16); subtitle.TextXAlignment=Enum.TextXAlignment.Left
local close=text(header,'Close','X',UDim2.fromOffset(42,42),UDim2.new(1,-54,0,14),white,25,true); close.BackgroundTransparency=0; close.BackgroundColor3=Color3.fromRGB(201,55,65); round(close,3)
local list=make('ScrollingFrame',panel,{Name='EquipmentList',Position=UDim2.fromOffset(14,84),Size=UDim2.new(1,-28,1,-132),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=7,ScrollBarImageColor3=Color3.fromRGB(91,153,210),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y,ClipsDescendants=true})
make('UIPadding',list,{PaddingTop=UDim.new(0,3),PaddingBottom=UDim.new(0,5),PaddingLeft=UDim.new(0,3),PaddingRight=UDim.new(0,10)})
make('UIListLayout',list,{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder})
local status=text(panel,'Status','Compre ferramentas para proteger sua base!',UDim2.new(1,-28,0,36),UDim2.new(0,14,1,-42),muted,16)
local items={{'Speed','Speed Coil','$2.500','Aumenta sua velocidade enquanto equipado.',Color3.fromRGB(55,160,255)},{'Gravity','Gravity Coil','$7.500','Pulos mais altos enquanto equipado.',Color3.fromRGB(175,85,255)},{'SuperSpeed','Super Speed Coil','$50.000','Velocidade 38 enquanto equipado.',Color3.fromRGB(255,191,51)},{'Cloak','Capa da Invisibilidade','$75.000','Invisível por 8 segundos. Recarga: 30s.',Color3.fromRGB(150,80,220)},{'Grapple','Gancho','$150.000','Puxa até o ponto escolhido. Recarga: 8s.',Color3.fromRGB(150,150,150)}}
local buttons,prices,owned={}, {}, {}; local busy=false; local loaded=false
local function refresh()
	for _,item in ipairs(items) do
		local id=item[1]; local b=buttons[id]; local has=owned[id]==true
		b.Text=not loaded and 'AGUARDE' or (has and 'EQUIPAR' or item[3])
		b.BackgroundColor3=not loaded and Color3.fromRGB(76,88,105) or (has and Color3.fromRGB(43,122,190) or green)
		b.Active=loaded and not busy; b.AutoButtonColor=b.Active
		prices[id].Text=has and 'ADQUIRIDO' or 'COMPRAR'
	end
end
for i,item in ipairs(items) do
	local id=item[1]
	local card=frame(list,id,UDim2.new(1,-4,0,120),UDim2.new(),Color3.fromRGB(34,44,49),3); card.LayoutOrder=i; stroke(card,Color3.fromRGB(12,17,20),2)
	local tile=frame(card,'PreviewTile',UDim2.fromOffset(112,112),UDim2.fromOffset(4,4),Color3.fromRGB(34,44,49),3)
	local view=make('ViewportFrame',tile,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Ambient=Color3.fromRGB(200,200,210),LightColor=white,LightDirection=Vector3.new(-1,-1,-1)})
	local source=previews:WaitForChild(id,5)
	if source and source:FindFirstChildWhichIsA("BasePart",true) then
		local model=source:Clone(); model.Parent=view
		local cf,size=model:GetBoundingBox(); local d=math.max(size.X,size.Y,size.Z)*2.5
		local cam=make('Camera',view,{FieldOfView=40,CFrame=CFrame.lookAt(cf.Position+Vector3.new(d*.35,d*.15,d),cf.Position)}); view.CurrentCamera=cam
	end
	local name=text(card,'Name',item[2],UDim2.new(1,-300,0,34),UDim2.fromOffset(124,12),white,24); name.TextXAlignment=Enum.TextXAlignment.Left
	local desc=text(card,'Description',item[4],UDim2.new(1,-300,0,64),UDim2.fromOffset(124,48),muted,17); desc.TextXAlignment=Enum.TextXAlignment.Left; desc.TextYAlignment=Enum.TextYAlignment.Top
	prices[id]=text(card,'Price',item[3],UDim2.fromOffset(154,34),UDim2.new(1,-166,0,12),white,16)
	local b=text(card,'Action','COMPRAR',UDim2.fromOffset(154,44),UDim2.new(1,-166,0,61),white,19,true); b.BackgroundTransparency=0; round(b,3); stroke(b,Color3.fromRGB(16,75,36),2); buttons[id]=b
	b.Activated:Connect(function()
		if busy or not loaded then return end
		busy=true; refresh(); local equip=owned[id]==true
		local ok,success,result=pcall(function() return request:InvokeServer(equip and 'Equip' or 'Buy',id) end)
		busy=false
		if ok and success and type(result)=='table' then owned=result; status.Text=equip and 'Equipamento equipado!' or 'Compra concluída!'; if equip then gui.Enabled=false end
		else status.Text=ok and tostring(result or 'Não foi possível concluir.') or 'Erro de conexão. Tente novamente.' end
		refresh()
	end)
end
local function resize()
	local s=shade.AbsoluteSize; if s.X<1 or s.Y<1 then return end
	-- Keep text and touch targets readable; shorten the scroll area on low screens.
	local k=math.min(1,(s.X-20)/680,math.max(.72,(s.Y-16)/460))
	scale.Scale=k; panel.Size=UDim2.fromOffset(680,math.min(460,(s.Y-16)/k))
end
shade:GetPropertyChangedSignal('AbsoluteSize'):Connect(resize)
local blur=make('BlurEffect',Lighting,{Name='EquipmentShopBlur',Size=0,Enabled=false})
local backpackWasEnabled=nil
local function visibility()
	blur.Enabled=gui.Enabled; blur.Size=gui.Enabled and 12 or 0
	if gui.Enabled then
		local ok,value=pcall(function() return StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack) end)
		if ok then backpackWasEnabled=value; pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false) end) end
	elseif backpackWasEnabled~=nil then
		local value=backpackWasEnabled; backpackWasEnabled=nil; pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,value) end)
	end
end
gui:GetPropertyChangedSignal('Enabled'):Connect(visibility)
close.Activated:Connect(function() gui.Enabled=false end)
net:WaitForChild('Open').OnClientEvent:Connect(function()
	if busy then return end
	busy=true; loaded=false; gui.Enabled=true; resize(); list.CanvasPosition=Vector2.zero; status.Text='Carregando...'; refresh()
	local ok,success,result=pcall(function() return request:InvokeServer('State') end); busy=false
	if ok and success and type(result)=='table' then owned=result; loaded=true; status.Text='Compre ferramentas para proteger sua base!' else status.Text=ok and tostring(result or 'Não foi possível carregar.') or 'Erro de conexão.' end
	refresh()
end)
refresh()

-- Mira do gancho: servidor valida alcance, colisões e equipamento.
local grapple=net:WaitForChild('Grapple')
local mouse=player:GetMouse()
local watched=setmetatable({}, {__mode='k'})
local function watchTool(t)
	if not t:IsA('Tool') or t:GetAttribute('EquipmentId')~='Grapple' or watched[t] then return end
	watched[t]=true; t.Activated:Connect(function() if t.Parent==player.Character then grapple:FireServer(mouse.Hit.Position) end end)
end
local function watchCharacter(c) for _,t in ipairs(c:GetChildren()) do watchTool(t) end; c.ChildAdded:Connect(watchTool) end
player.CharacterAdded:Connect(watchCharacter); if player.Character then watchCharacter(player.Character) end
