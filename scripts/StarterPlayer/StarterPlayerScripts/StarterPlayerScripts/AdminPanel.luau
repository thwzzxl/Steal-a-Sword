-- AdminPanel V38 | StarterPlayerScripts
local P=game:GetService('Players'); local player=P.LocalPlayer
if player.UserId~=11715073634 then return end
local RS=game:GetService('ReplicatedStorage')
local control=RS:WaitForChild('AdminControlV38'); local events=RS:WaitForChild('AdminEventRequest'); local money=RS:WaitForChild('AdminMoneyRequest'); local state=RS:WaitForChild('EventSystemState'); local catalog=RS:WaitForChild('SwordIndexCatalog')
local function make(c,p,t) local o=Instance.new(c); for k,v in pairs(t) do o[k]=v end; o.Parent=p; return o end
local dark=Color3.fromRGB(35,44,61); local blue=Color3.fromRGB(49,91,150); local green=Color3.fromRGB(40,125,75)
local gui=make('ScreenGui',player:WaitForChild('PlayerGui'),{Name='AdminEventPanel',ResetOnSpawn=false,DisplayOrder=80})
local function button(p,t,x,y,w,h,c,fn) local b=make('TextButton',p,{Text=t,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundColor3=c,TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=14,BorderSizePixel=0,TextWrapped=true}); make('UICorner',b,{CornerRadius=UDim.new(0,7)}); if fn then b.Activated:Connect(fn) end; return b end
local open=button(gui,'Admin',0,0,86,34,dark); open.AnchorPoint=Vector2.new(1,0); open.Position=UDim2.new(1,-12,0,76)
local panel=make('Frame',gui,{Size=UDim2.fromOffset(440,480),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),BackgroundColor3=Color3.fromRGB(20,27,41),Visible=false}); make('UICorner',panel,{CornerRadius=UDim.new(0,12)})
local scale=make('UIScale',panel,{Scale=1}); local function resize() local s=gui.AbsoluteSize; scale.Scale=math.min(1,math.max(.2,(s.X-16)/440),math.max(.2,(s.Y-16)/480)) end; gui:GetPropertyChangedSignal('AbsoluteSize'):Connect(resize); resize()
local function label(p,t,x,y,w,h) return make('TextLabel',p,{Text=t,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundTransparency=1,TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=14,TextWrapped=true}) end
label(panel,'ADMIN PANEL  •  V45',12,8,370,34); button(panel,'X',392,8,36,34,Color3.fromRGB(165,48,58),function() panel.Visible=false end)
local feedback=label(panel,'Escolha uma acao.',12,430,416,42)
local body=make('Frame',panel,{Position=UDim2.fromOffset(12,94),Size=UDim2.fromOffset(416,330),BackgroundTransparency=1})
local pending=false
local function call(r,...) if pending then return end; pending=true; local ok,success,msg=pcall(r.InvokeServer,r,...); pending=false; feedback.Text=ok and tostring(msg or (success and 'Concluido!' or 'Falhou.')) or 'Falha na conexao.' end
local minutes,scope=5,'Local'; local selected,mut=1,1; local mutations={'Normal','Golden','Diamond','Rainbow','Corrupted','Spiritual'}; local targetId; local tab='Eventos'; local status
local function input(p,y) return make('TextBox',p,{Position=UDim2.fromOffset(0,y),Size=UDim2.fromOffset(416,42),BackgroundColor3=dark,TextColor3=Color3.new(1,1,1),PlaceholderText='Valor em dinheiro',Text='',ClearTextOnFocus=false,Font=Enum.Font.Gotham,TextSize=16}) end
local function pro(op,extra)
	local q=extra or {}; q.Op=op; q.UserId=targetId or player.UserId; call(control,'Pro',q)
end
local function render()
	body:ClearAllChildren(); status=nil
	if tab=='Eventos' then
		status=label(body,'',0,0,416,30)
		for i,e in ipairs({{'Lucky','Lucky Hour 2x'},{'Infernal','Infernal 8x'},{'Celestial','Celestial 12x'}}) do button(body,e[2],0,35+(i-1)*45,416,39,blue,function() call(events,e[1],minutes,scope) end) end
		local d; d=button(body,'Duracao: '..minutes..' min',0,175,202,40,dark,function() local v={1,5,10,30}; local n=table.find(v,minutes) or 1; minutes=v[n%4+1]; d.Text='Duracao: '..minutes..' min' end)
		local sc; sc=button(body,'Servidor: '..scope,214,175,202,40,dark,function() scope=scope=='Local' and 'Global' or 'Local'; sc.Text='Servidor: '..scope end)
		button(body,'Encerrar evento',0,225,416,44,Color3.fromRGB(145,45,60),function() call(events,'None',minutes,scope) end)
	elseif tab=='Espadas' then
		local list=catalog:GetChildren(); table.sort(list,function(a,b) return (a:GetAttribute('IndexOrder') or 0)<(b:GetAttribute('IndexOrder') or 0) end)
		if #list==0 then label(body,'Catalogo indisponivel.',0,0,416,40); return end
		selected=math.clamp(selected,1,#list)
		local name=label(body,'',48,0,320,40); local view=make('ViewportFrame',body,{Position=UDim2.fromOffset(148,46),Size=UDim2.fromOffset(120,120),BackgroundColor3=dark,Ambient=Color3.fromRGB(200,200,210),LightColor=Color3.new(1,1,1)})
		local function preview() view:ClearAllChildren(); local source=list[selected]; name.Text=source.Name..' ('..selected..'/'..#list..')'; local model=source:Clone(); model.Parent=view; local cf,size=model:GetBoundingBox(); local d=math.max(size.X,size.Y,size.Z)*2; local cam=make('Camera',view,{CFrame=CFrame.lookAt(cf.Position+Vector3.new(d*.3,d*.1,d),cf.Position),FieldOfView=40}); view.CurrentCamera=cam end
		button(body,'<',0,0,42,40,dark,function() selected=(selected-2)%#list+1; preview() end); button(body,'>',374,0,42,40,dark,function() selected=selected%#list+1; preview() end); preview()
		local mb; mb=button(body,'Mutacao: '..mutations[mut],0,175,416,40,dark,function() mut=mut%#mutations+1; mb.Text='Mutacao: '..mutations[mut] end)
		button(body,'Spawnar na esteira',0,225,416,44,green,function() call(control,'Spawn',list[selected]:GetAttribute('IndexId'),mutations[mut]) end)
		button(body,'Adicionar a minha base',0,278,416,44,blue,function() call(control,'Grant',list[selected]:GetAttribute('IndexId'),mutations[mut]) end)
	elseif tab=='PRO' then
		local list=P:GetPlayers(); local n=table.find(list,P:GetPlayerByUserId(targetId or player.UserId)) or 1
		local who=label(body,'',48,0,320,36); local function update() local t=list[n]; targetId=t.UserId; who.Text=t.Name end; update()
		button(body,'<',0,0,42,36,dark,function() n=(n-2)%#list+1; update() end); button(body,'>',374,0,42,36,dark,function() n=n%#list+1; update() end)
		local value=input(body,42); value.PlaceholderText='Rebirth (0-15) ou saldo';
		button(body,'Definir Rebirth',0,90,202,38,blue,function() pro('Rebirth',{Value=tonumber(value.Text)}) end)
		button(body,'Definir saldo',214,90,202,38,blue,function() pro('Cash',{Value=tonumber(value.Text)}) end)
		local swords=catalog:GetChildren(); table.sort(swords,function(a,b) return (a:GetAttribute('IndexOrder') or 0)<(b:GetAttribute('IndexOrder') or 0) end)
		local i=1; local m=1; local dest=1; local destinations={'Base','Inventory','Belt'}
		local sb; sb=button(body,'Espada: '..(swords[i] and swords[i].Name or '-'),0,134,416,36,dark,function() if #swords>0 then i=i%#swords+1; sb.Text='Espada: '..swords[i].Name end end)
		local mb; mb=button(body,mutations[m],0,176,202,36,dark,function() m=m%#mutations+1; mb.Text=mutations[m] end)
		local db; db=button(body,destinations[dest],214,176,202,36,dark,function() dest=dest%3+1; db.Text=destinations[dest] end)
		button(body,'Dar espada',0,218,202,36,green,function() if swords[i] then pro('Sword',{Id=swords[i]:GetAttribute('IndexId'),Mutation=mutations[m],Dest=destinations[dest]}) end end)
		button(body,'Finalizar fusao',214,218,202,36,blue,function() pro('ForgeFinish') end)
		button(body,'Inspecionar',0,260,132,36,dark,function() pro('Inspect') end)
		button(body,'Curar',142,260,132,36,dark,function() pro('Heal') end)
		button(body,'Respawn',284,260,132,36,dark,function() pro('Respawn') end)
	elseif tab=='Economia' then
		local b=button(body,'',0,0,416,44,green,function() call(money) end); local function update() b.Text='Dinheiro infinito: '..(player:GetAttribute('AdminInfiniteCash') and 'ON' or 'OFF') end; update(); task.spawn(function() while b.Parent do update(); task.wait(.25) end end)
		local amount=input(body,60); button(body,'Adicionar dinheiro',0,115,416,44,blue,function() call(control,'Add',tonumber(amount.Text)) end); button(body,'Definir saldo',0,170,416,44,dark,function() call(control,'Set',tonumber(amount.Text)) end)
	else
		local list=P:GetPlayers(); local n=1; local who=label(body,'',48,0,320,40); local function update() local t=list[n]; targetId=t and t.UserId; who.Text=t and t.Name or 'Sem jogadores' end; update()
		button(body,'<',0,0,42,40,dark,function() n=(n-2)%#list+1; update() end); button(body,'>',374,0,42,40,dark,function() n=n%#list+1; update() end)
		local amount=input(body,50); button(body,'Dar dinheiro',0,102,416,40,green,function() call(control,'Give',targetId,tonumber(amount.Text)) end)
		button(body,'Teleportar ate jogador',0,150,416,40,blue,function() call(control,'Goto',targetId) end); button(body,'Trazer jogador',0,198,416,40,blue,function() call(control,'Bring',targetId) end)
		local confirm; button(body,'Expulsar (2 cliques)',0,246,416,40,Color3.fromRGB(145,45,60),function() if confirm==targetId then call(control,'Kick',targetId); confirm=nil else confirm=targetId; feedback.Text='Clique novamente para confirmar.' end end)
	end
end
for i,t in ipairs({'Eventos','Espadas','Economia','Jogadores','PRO'}) do button(panel,t,12+(i-1)*84,48,80,36,dark,function() tab=t; render() end) end
open.Activated:Connect(function() panel.Visible=not panel.Visible; if panel.Visible then render() end end)
while gui.Parent do if status and status.Parent then local e=state:GetAttribute('ActiveEvent') or 'None'; local t=math.max(0,math.ceil((state:GetAttribute('EndsAt') or 0)-workspace:GetServerTimeNow())); status.Text=e=='None' and 'Nenhum evento ativo' or string.format('%s | %02d:%02d',e,math.floor(t/60),t%60) end; task.wait(.25) end
