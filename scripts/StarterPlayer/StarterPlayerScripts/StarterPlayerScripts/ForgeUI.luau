-- LocalScript: StarterPlayerScripts
local RS=game:GetService("ReplicatedStorage")
local player=game:GetService("Players").LocalPlayer
local rf=RS:WaitForChild("SwordInventoryV40")
local open=RS:WaitForChild("OpenSpiritualForge")
local gui=Instance.new("ScreenGui"); gui.Name="ForgeUI"; gui.ResetOnSpawn=false; gui.DisplayOrder=20; gui.Parent=player:WaitForChild("PlayerGui")
local panel=Instance.new("Frame"); panel.Size=UDim2.fromScale(.88,.82); panel.Position=UDim2.fromScale(.5,.5); panel.AnchorPoint=Vector2.new(.5,.5); panel.BackgroundColor3=Color3.fromRGB(22,29,42); panel.Visible=false; panel.Parent=gui
local limit=Instance.new("UISizeConstraint"); limit.MaxSize=Vector2.new(580,540); limit.Parent=panel
local function round(o) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,12); c.Parent=o end
round(panel)
local function text(parent,name,txt,pos,size,button)
	local o=Instance.new(button and "TextButton" or "TextLabel"); o.Name=name; o.Text=txt; o.Position=pos; o.Size=size; o.Font=Enum.Font.GothamMedium; o.TextColor3=Color3.fromRGB(235,230,250); o.TextScaled=true; o.BackgroundColor3=Color3.fromRGB(36,48,66); o.BackgroundTransparency=button and 0 or 1; o.BorderSizePixel=0; o.Parent=parent; if button then round(o) end; return o
end
text(panel,"Title","FORJA ESPIRITUAL",UDim2.fromScale(.04,.02),UDim2.fromScale(.82,.08))
local close=text(panel,"Close","X",UDim2.fromScale(.88,.02),UDim2.fromScale(.09,.08),true)
local info=text(panel,"Info","Escolha 3 espadas da sua base",UDim2.fromScale(.04,.12),UDim2.fromScale(.92,.08))
local list=Instance.new("ScrollingFrame"); list.Size=UDim2.fromScale(.92,.46); list.Position=UDim2.fromScale(.04,.22); list.BackgroundTransparency=1; list.BorderSizePixel=0; list.ScrollBarThickness=5; list.AutomaticCanvasSize=Enum.AutomaticSize.Y; list.CanvasSize=UDim2.new(); list.Parent=panel
local layout=Instance.new("UIGridLayout"); layout.CellSize=UDim2.new(.333,-8,0,112); layout.CellPadding=UDim2.fromOffset(6,6); layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.Parent=list
local catalog=RS:WaitForChild("SwordIndexCatalog")
local function preview(parent,item)
	local template=typeof(item.Uid)=="Instance" and item.Uid or nil
	if not template then for _,m in ipairs(catalog:GetChildren()) do if m:GetAttribute("IndexId")== (item.Id or item.Rarity) then template=m; break end end end
	if not template then return end
	local v=Instance.new("ViewportFrame"); v.Size=UDim2.new(1,-8,0,78); v.Position=UDim2.fromOffset(4,4); v.BackgroundTransparency=1; v.Active=false; v.Parent=parent
	v.Ambient=Color3.fromRGB(180,180,190); v.LightColor=Color3.new(1,1,1); v.LightDirection=Vector3.new(-1,-1,-1)
	local m=template:Clone(); for _,o in ipairs(m:GetDescendants()) do if o:IsA("BasePart") then o.Anchored=true elseif o:IsA("Script") or o:IsA("LocalScript") or o:IsA("BillboardGui") or o:IsA("ParticleEmitter") or o:IsA("ProximityPrompt") then o:Destroy() end end
	m.Parent=v; local cf,size=m:GetBoundingBox(); local d=math.max(size.X,size.Y,size.Z)*1.9
	local cam=Instance.new("Camera"); cam.FieldOfView=38; cam.CFrame=CFrame.lookAt(cf.Position+Vector3.new(d*.23,0,d),cf.Position); cam.Parent=v; v.CurrentCamera=cam
end
local status=text(panel,"Status","",UDim2.fromScale(.04,.70),UDim2.fromScale(.92,.09)); status.TextWrapped=true
local action=text(panel,"Action","Iniciar fusão",UDim2.fromScale(.12,.82),UDim2.fromScale(.76,.13),true)
local fees={Comum=500,Incomum=2500,Rara=15000,["Épica"]=100000,["Lendária"]=500000,["Mítica"]=5000000,Secreta=50000000}
local chosen={}; local rows={}; local ends=0; local offset=0; local busy=false; local generation=0
local function call(a,b) local ok,x,y=pcall(function() return rf:InvokeServer(a,b) end); if not ok then return false,"Conexão indisponível." end; return x,y end
local function count() local n=0; local tier; for _,v in pairs(chosen) do n+=1; tier=v.Rarity end; return n,tier end
local function update()
	local n,tier=count(); local remaining=math.max(0,ends-os.time()-offset)
	if ends>0 then
		info.Text=remaining>0 and string.format("Fusão em andamento • %02d:%02d",math.floor(remaining/60),remaining%60) or "Sua espada está pronta!"
		action.Text=remaining>0 and "Aguardando..." or "Resgatar espada"; action.Active=remaining==0 and not busy
	else
		info.Text=n.."/3 selecionadas • "..(tier or "Mesma raridade")
		action.Text=n==3 and ("Fundir • $"..tostring(fees[tier])) or "Selecione 3 espadas"; action.Active=n==3 and not busy
	end
	action.AutoButtonColor=action.Active
end
local function refresh()
	generation+=1; local g=generation; chosen={}
	local ok,job=call("ForgeStatus"); if g~=generation or not panel.Visible then return end
	if not ok then status.Text=tostring(job); return end
	ends=job.EndsAt; offset=job.Now-os.time()
	for _,o in ipairs(list:GetChildren()) do if o:IsA("TextButton") then o:Destroy() end end
	if ends==0 then
		local success,items=call("ForgeList"); if g~=generation or not panel.Visible then return end
		if not success then status.Text=tostring(items); return end
		for _,item in ipairs(items) do
			local b=text(list,"Sword","",UDim2.new(),UDim2.new(),true)
			preview(b,item)
			local name=text(b,"Name",item.Name,UDim2.new(0,4,0,82),UDim2.new(1,-8,0,24)); name.TextScaled=false; name.TextSize=12; name.TextTruncate=Enum.TextTruncate.AtEnd
			local stroke=Instance.new("UIStroke"); stroke.Color=Color3.fromRGB(58,72,92); stroke.Thickness=1; stroke.Parent=b
			if item.Favorite or item.Id=="INFINITY" then name.Text="Protegida: "..item.Name; b.Active=false; b.AutoButtonColor=false else
				b.Activated:Connect(function()
					if busy then return end
					if chosen[item.Uid] then chosen[item.Uid]=nil; b.BackgroundColor3=Color3.fromRGB(36,48,66); stroke.Color=Color3.fromRGB(58,72,92) else
						local n,tier=count(); if n>=3 or (tier and tier~=item.Rarity) then status.Text="Escolha três da mesma raridade."; return end
						chosen[item.Uid]=item; b.BackgroundColor3=Color3.fromRGB(70,94,145); stroke.Color=Color3.fromRGB(155,190,255)
					end
					status.Text="65% mesma raridade • 35% evolução • 5% Spiritual (inclusos)"; update()
				end)
			end
		end
	end
	update()
end
close.Activated:Connect(function() panel.Visible=false; generation+=1 end)
open.OnClientEvent:Connect(function() panel.Visible=true; status.Text="15 minutos por fusão • Espadas da base"; refresh() end)
action.Activated:Connect(function()
	if busy or not action.Active then return end
	busy=true; update(); local ok,msg
	if ends>0 then ok,msg=call("ForgeClaim") else local ids={}; for id in pairs(chosen) do table.insert(ids,id) end; ok,msg=call("ForgeStart",ids) end
	busy=false; status.Text=tostring(msg); if ok or ends==0 then refresh() else update() end
end)
task.spawn(function() while gui.Parent do if panel.Visible then update() end; task.wait(1) end end)
