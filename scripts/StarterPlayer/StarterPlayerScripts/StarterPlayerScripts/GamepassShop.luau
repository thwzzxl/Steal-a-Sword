-- GamepassShop V31 | StarterPlayerScripts (LocalScript)
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
for _,name in ipairs({"GamepassShopV28","GamepassShopV30_4"}) do
	local old=pg:FindFirstChild(name)
	if old then old:Destroy() end
end
local gui = Instance.new("ScreenGui")
gui.Name = "GamepassShopV30_4"; gui.ResetOnSpawn = false; gui.DisplayOrder = 40; gui.Parent = pg
local function make(class, parent, props)
	local o = Instance.new(class)
	for k,v in pairs(props) do o[k] = v end
	o.Parent = parent; return o
end
local function round(o,r) make("UICorner",o,{CornerRadius=UDim.new(0,r)}) end
local function stroke(o,c,t) make("UIStroke",o,{Color=c,Thickness=t,ApplyStrokeMode=Enum.ApplyStrokeMode.Border}) end
local dark=Color3.fromRGB(30,43,64)
local white=Color3.fromRGB(255,255,255)
local function text(parent,content,size,pos,sz,color)
	return make("TextLabel",parent,{Text=content,Size=size,Position=pos,BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextColor3=color or white,TextSize=sz,TextWrapped=true,TextStrokeTransparency=1})
end
local function button(parent,content,size,pos,color)
	local b=make("TextButton",parent,{Text=content,Size=size,Position=pos,BackgroundColor3=color,Font=Enum.Font.GothamBold,TextColor3=white,TextSize=20,TextStrokeTransparency=1,AutoButtonColor=true})
	round(b,12); stroke(b,Color3.fromRGB(90,115,145),1); return b
end

local shade=make("TextButton",gui,{Name="ShopOverlay",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.45,Text="",AutoButtonColor=false,Visible=false})
local panel=make("Frame",shade,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(680,390),BackgroundColor3=Color3.fromRGB(17,26,43)})
round(panel,20); stroke(panel,Color3.fromRGB(62,82,112),1.5)
local scale=make("UIScale",panel,{Scale=1})
local function resize()
	local cam=workspace.CurrentCamera
	if cam then local v=cam.ViewportSize; scale.Scale=math.min(1,(v.X-24)/680,(v.Y-40)/390) end
end
local cameraConnection
local function bindCamera()
	if cameraConnection then cameraConnection:Disconnect() end
	local cam=workspace.CurrentCamera
	if cam then cameraConnection=cam:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
	resize()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera); bindCamera()
text(panel,"Loja",UDim2.fromOffset(160,55),UDim2.fromOffset(16,5),34)
text(panel,"Passes de jogo",UDim2.fromOffset(350,55),UDim2.fromOffset(165,5),26)
local close=button(panel,"X",UDim2.fromOffset(46,42),UDim2.fromOffset(618,12),Color3.fromRGB(55,70,94))
local status=text(panel,"Benefícios permanentes • Os multiplicadores acumulam!",UDim2.fromOffset(640,40),UDim2.fromOffset(20,337),16)
local passes={
	{id=2088057023,attr="HasVIP",name="VIP",desc="+25% de dinheiro\nTag VIP exclusiva",fallback="👑",color=Color3.fromRGB(255,210,55)},
	{id=2089898997,attr="HasDoubleMoney",name="2x Dinheiro",desc="Dobre a renda das espadas!",fallback="2X",color=Color3.fromRGB(100,255,120)}
}
for i,p in ipairs(passes) do
	local card=make("Frame",panel,{Size=UDim2.fromOffset(312,258),Position=UDim2.fromOffset(18+(i-1)*332,72),BackgroundColor3=dark})
	round(card,16); stroke(card,p.color,1.5)
	text(card,p.name,UDim2.fromOffset(292,42),UDim2.fromOffset(10,5),27,p.color)
	local fallback=text(card,p.fallback,UDim2.fromOffset(100,100),UDim2.fromOffset(12,56),48,p.color)
	local img=make("ImageLabel",card,{Size=UDim2.fromOffset(100,100),Position=UDim2.fromOffset(12,56),BackgroundTransparency=1,ScaleType=Enum.ScaleType.Fit,Visible=false})
	text(card,p.desc,UDim2.fromOffset(178,110),UDim2.fromOffset(120,50),19)
	local buy=button(card,"Carregando...",UDim2.fromOffset(282,52),UDim2.fromOffset(15,188),Color3.fromRGB(35,145,85))
	local info, busy
	local hover=make("UIScale",buy,{Scale=1})
	buy.MouseEnter:Connect(function() if buy.Active then TweenService:Create(hover,TweenInfo.new(.15),{Scale=1.025}):Play() end end)
	buy.MouseLeave:Connect(function() TweenService:Create(hover,TweenInfo.new(.15),{Scale=1}):Play() end)
	local function refresh()
		local owned=player:GetAttribute(p.attr)==true
		buy.Text=owned and "ADQUIRIDO" or (busy and "Aguarde..." or (info and info.IsForSale and info.PriceInRobux and (tostring(info.PriceInRobux).." ROBUX") or "Indisponível"))
		buy.Active=not owned and not busy and info~=nil and info.IsForSale==true and info.PriceInRobux~=nil
		buy.AutoButtonColor=buy.Active
		buy.BackgroundColor3=owned and Color3.fromRGB(83,100,104) or Color3.fromRGB(35,145,85)
	end
	player:GetAttributeChangedSignal(p.attr):Connect(refresh)
	task.spawn(function()
		local ok,result=pcall(MarketplaceService.GetProductInfo,MarketplaceService,p.id,Enum.InfoType.GamePass)
		if ok then info=result; if result.IconImageAssetId and result.IconImageAssetId>0 then img.Image="rbxassetid://"..result.IconImageAssetId; img.Visible=true; fallback.Visible=false end end
		refresh()
	end)
	buy.Activated:Connect(function()
		if not buy.Active or busy or player:GetAttribute(p.attr) then return end
		busy=true; refresh()
		local ok=pcall(MarketplaceService.PromptGamePassPurchase,MarketplaceService,player,p.id)
		if not ok then busy=false; refresh(); status.Text="Não foi possível abrir a compra. Tente novamente." end
	end)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(who,id,purchased)
		if who~=player or id~=p.id then return end
		busy=false; refresh()
		status.Text=purchased and "Compra concluída! Ativando benefício..." or "Benefícios permanentes • Os multiplicadores acumulam!"
	end)
end
local toggle=pg:FindFirstChild("ToggleGamepassShop") or Instance.new("BindableEvent")
toggle.Name="ToggleGamepassShop"; toggle.Parent=pg
local dismiss=pg:FindFirstChild("CloseGamepassShop") or Instance.new("BindableEvent")
dismiss.Name="CloseGamepassShop"; dismiss.Parent=pg
toggle.Event:Connect(function() shade.Visible=not shade.Visible end)
dismiss.Event:Connect(function() shade.Visible=false end)
close.Activated:Connect(function() shade.Visible=false end)

-- O GameHUD V30.4 controla ShopOverlay.Visible diretamente.
local blur=Instance.new("BlurEffect")
blur.Name="SwordShopBlurV31"; blur.Size=0; blur.Parent=Lighting
local animation, blurTween
shade:GetPropertyChangedSignal("Visible"):Connect(function()
	if animation then animation:Cancel() end
	if blurTween then blurTween:Cancel() end
	if shade.Visible then
		panel.Position=UDim2.fromScale(.5,.53)
		animation=TweenService:Create(panel,TweenInfo.new(.22,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Position=UDim2.fromScale(.5,.5)})
		animation:Play()
	end
	blurTween=TweenService:Create(blur,TweenInfo.new(.2),{Size=shade.Visible and 12 or 0})
	blurTween:Play()
end)
gui.Destroying:Connect(function() blur:Destroy() end)
print("[GamepassShop V31] Loja pronta!")
