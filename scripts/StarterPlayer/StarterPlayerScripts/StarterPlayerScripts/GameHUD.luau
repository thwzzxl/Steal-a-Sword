
-- GAME HUD V29 — DAILY REWARDS & QUESTS
-- Roube uma Espada
-- Local: StarterPlayerScripts

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local leaderstats = player:WaitForChild("leaderstats")
local cash = leaderstats:WaitForChild("Cash")

local map = Workspace:WaitForChild("SwordGameMap")
local storedSwords = map:WaitForChild("StoredSwords")

-- CONFIGURACOES

local INCOME = {
	["Comum"] = 2,
	["Incomum"] = 6,
	["Rara"] = 22,
	["Épica"] = 85,
	["Lendária"] = 320,
	["Mítica"] = 2000,
}

local COLORS = {
	["Comum"] = Color3.fromRGB(190, 195, 205),
	["Incomum"] = Color3.fromRGB(80, 215, 120),
	["Rara"] = Color3.fromRGB(65, 155, 255),
	["Épica"] = Color3.fromRGB(175, 85, 255),
	["Lendária"] = Color3.fromRGB(255, 190, 50),
	["Mítica"] = Color3.fromRGB(255,100,30),
	["Secreta"] = Color3.fromRGB(220,80,220),
}

local animationsEnabled = true

-- REMOVER INTERFACE ANTIGA

local oldGui = playerGui:FindFirstChild("SwordGameHUD")

if oldGui then
	oldGui:Destroy()
end

-- CRIAR GUI

local gui = Instance.new("ScreenGui")
gui.Name = "SwordGameHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = playerGui

-- FUNCOES VISUAIS

local function corner(object, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = object
end

local function stroke(object, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.Parent = object
end

local function makeFrame(name, size, position, color, parent)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.Position = position
	frame.BackgroundColor3 = color
	frame.BorderSizePixel = 0
	frame.Parent = parent
	return frame
end

local function makeText(name, text, size, position, color, parent)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Text = text
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.TextColor3 = color
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = parent
	return label
end

local function makeButton(name, text, size, position, color, parent)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Text = text
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = color
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamBold
	button.TextScaled = true
	button.BorderSizePixel = 0
	button.Parent = parent

	corner(button, 12)

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 6)
	padding.Parent = button

	return button
end

-- FORMATAR DINHEIRO

local function formatMoney(amount)
	if amount >= 1000000000 then
		return string.format("%.2fB", amount / 1000000000)
	elseif amount >= 1000000 then
		return string.format("%.2fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("%.2fK", amount / 1000)
	end

	return amount % 1 == 0 and tostring(math.floor(amount)) or string.format("%.2f", amount):gsub("0+$", "")
end

-- HUD PRINCIPAL

local hud = makeFrame(
	"MoneyHUD",
	UDim2.fromOffset(245, 108),
	UDim2.new(0, 20, 1, -130),
	Color3.fromRGB(22, 28, 40),
	gui
)

corner(hud, 16)
stroke(hud, Color3.fromRGB(60, 75, 95), 2)

local title = makeText(
	"Title",
	"SEU DINHEIRO",
	UDim2.new(1, -24, 0, 20),
	UDim2.fromOffset(12, 9),
	Color3.fromRGB(175, 185, 205),
	hud
)

title.TextXAlignment = Enum.TextXAlignment.Left

local cashLabel = makeText(
	"Cash",
	"$0",
	UDim2.new(1, -24, 0, 43),
	UDim2.fromOffset(12, 29),
	Color3.fromRGB(80, 255, 125),
	hud
)

cashLabel.TextXAlignment = Enum.TextXAlignment.Left

local incomeLabel = makeText(
	"Income",
	"+$0/s",
	UDim2.new(1, -24, 0, 22),
	UDim2.fromOffset(12, 77),
	Color3.fromRGB(230, 235, 245),
	hud
)

incomeLabel.TextXAlignment = Enum.TextXAlignment.Left

-- BOTOES LATERAIS

local buttons = makeFrame(
	"Buttons",
	UDim2.fromOffset(116, 166),
	UDim2.new(1, -132, 0.5, -83),
	Color3.new(),
	gui
)

buttons.BackgroundTransparency = 1

local inventoryButton = makeButton(
	"Inventory",
	"ESPADAS",
	UDim2.fromOffset(116, 48),
	UDim2.fromOffset(0, 0),
	Color3.fromRGB(112, 75, 210),
	buttons
)

local rebirthButton = makeButton(
	"Rebirth",
	"REBIRTH",
	UDim2.fromOffset(116, 48),
	UDim2.fromOffset(0, 56),
	Color3.fromRGB(220, 150, 35),
	buttons
)

local settingsButton = makeButton(
	"Settings",
	"OPÇÕES",
	UDim2.fromOffset(116, 48),
	UDim2.fromOffset(0, 112),
	Color3.fromRGB(70, 85, 110),
	buttons
)

-- PAINEL DE INVENTARIO

local inventory = makeFrame(
	"InventoryPanel",
	UDim2.new(0.85, 0, 0.65, 0),
	UDim2.fromScale(0.5, 0.5),
	Color3.fromRGB(24, 30, 43),
	gui
)

inventory.AnchorPoint = Vector2.new(0.5, 0.5)
inventory.Visible = false

corner(inventory, 18)
stroke(inventory, Color3.fromRGB(90, 105, 140), 2)

local constraint = Instance.new("UISizeConstraint")
constraint.MaxSize = Vector2.new(650, 520)
constraint.Parent = inventory

makeText(
	"Title",
	"SUAS ESPADAS",
	UDim2.new(1, -70, 0, 34),
	UDim2.fromOffset(15, 12),
	Color3.new(1, 1, 1),
	inventory
)

local closeInventory = makeButton(
	"Close",
	"X",
	UDim2.fromOffset(36, 36),
	UDim2.new(1, -48, 0, 10),
	Color3.fromRGB(205, 60, 70),
	inventory
)

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "SwordList"
scroll.Size = UDim2.new(1, -24, 1, -105)
scroll.Position = UDim2.fromOffset(12, 58)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 5
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new()
scroll.Parent = inventory

local layout = Instance.new("UIGridLayout")
layout.CellSize = UDim2.fromOffset(196, 216)
layout.CellPadding = UDim2.fromOffset(8, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

local totalLabel = makeText(
	"Total",
	"0/10 espadas",
	UDim2.new(1, -24, 0, 30),
	UDim2.new(0, 12, 1, -38),
	Color3.fromRGB(180, 190, 210),
	inventory
)

-- PAINEL DE CONFIGURACOES

local settings = makeFrame(
	"SettingsPanel",
	UDim2.fromOffset(280, 170),
	UDim2.fromScale(0.5, 0.5),
	Color3.fromRGB(24, 30, 43),
	gui
)

settings.AnchorPoint = Vector2.new(0.5, 0.5)
settings.Visible = false

corner(settings, 16)
stroke(settings, Color3.fromRGB(90, 105, 140), 2)

makeText(
	"Title",
	"CONFIGURAÇÕES",
	UDim2.new(1, -20, 0, 30),
	UDim2.fromOffset(10, 12),
	Color3.new(1, 1, 1),
	settings
)

local animationButton = makeButton(
	"Animations",
	"Animações: ON",
	UDim2.new(1, -30, 0, 42),
	UDim2.fromOffset(15, 55),
	Color3.fromRGB(40, 160, 90),
	settings
)

local closeSettings = makeButton(
	"Close",
	"FECHAR",
	UDim2.new(1, -30, 0, 42),
	UDim2.fromOffset(15, 110),
	Color3.fromRGB(75, 85, 110),
	settings
)

-- ATUALIZAR ESPADAS E RENDA

local function getOwnedSwords()
	local swords = {}

	for _, sword in ipairs(storedSwords:GetChildren()) do
		if sword:IsA("Model")
			and sword:GetAttribute("OwnerUserId") == player.UserId then

			table.insert(swords, sword)
		end
	end

	table.sort(swords, function(a, b)
		return (a:GetAttribute("StandName") or "")
			< (b:GetAttribute("StandName") or "")
	end)

	return swords
end

local function capacity()
	local l=math.clamp(player:GetAttribute("Rebirths") or 0,0,10)
	return 10+(l>0 and math.min(l+1,6) or 0)+(l>=6 and l-4 or 0)
end
local menuSale=game:GetService("ReplicatedStorage"):WaitForChild("SellSwordFromMenu")
local inventorySignature = nil
local function refreshInventory()
	local owned = getOwnedSwords()
	local keys = {}
	for _, sword in ipairs(owned) do table.insert(keys, tostring(sword:GetAttribute("StandName"))..":"..sword.Name..":"..tostring(sword:GetAttribute("Mutation"))..":"..tostring(sword:GetAttribute("Income"))) end
	local signature = table.concat(keys,"|")..":"..tostring(player:GetAttribute("IncomeMultiplier"))..":"..tostring(player:GetAttribute("GamepassIncomeMultiplier"))..":"..capacity()..":"..tostring(player:GetAttribute("StoredSwordCount"))
	if signature == inventorySignature then return end
	inventorySignature = signature
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	local swords = getOwnedSwords()
	table.sort(swords, function(a,b)
		local x,y = a:GetAttribute("Income") or 0,b:GetAttribute("Income") or 0
		if x == y then return a.Name < b.Name end
		return x < y
	end)
	local totalIncome = 0

	for index, sword in ipairs(swords) do
		local rarity = sword:GetAttribute("Rarity") or "Comum"
		local income = math.floor((sword:GetAttribute("Income") or INCOME[rarity] or 0) * (player:GetAttribute("IncomeMultiplier") or 1) * (player:GetAttribute("GamepassIncomeMultiplier") or 1))
		local color = COLORS[rarity] or Color3.new(1, 1, 1)

		totalIncome += income

		local item = makeFrame(
			"SwordItem",
			UDim2.new(1, -8, 0, 84),
			UDim2.new(),
			Color3.fromRGB(38, 46, 62),
			scroll
		)

		item.LayoutOrder = index
		corner(item, 10)
		stroke(item, color, 1)

		local name = makeText(
			"SwordName",
			(sword:GetAttribute("Mutation") and sword:GetAttribute("Mutation") ~= "Normal") and (sword:GetAttribute("Mutation") .. " " .. sword.Name) or sword.Name,
			UDim2.new(1, -12, 0, 24),
			UDim2.fromOffset(6, 96),
			color,
			item
		)

		name.TextXAlignment = Enum.TextXAlignment.Center
		name.TextScaled=false; name.TextSize=15

		local rarityLabel=makeText("Rarity",rarity,UDim2.new(1,-12,0,17),UDim2.fromOffset(6,119),color,item)
		rarityLabel.TextScaled=false; rarityLabel.TextSize=12
		local earning=makeText("Earning","+$"..formatMoney(income).."/s",UDim2.new(1,-12,0,20),UDim2.fromOffset(6,136),Color3.fromRGB(85,245,130),item)
		earning.TextScaled=false; earning.TextSize=15
		local sale=makeText("Sale",sword:GetAttribute("SwordId")=="INFINITY" and "Não vendável" or "Venda: $"..formatMoney(math.floor((sword:GetAttribute("Price") or 0)/2)),UDim2.new(1,-12,0,16),UDim2.fromOffset(6,157),Color3.fromRGB(180,195,215),item)
		sale.TextScaled=false; sale.TextSize=11
		if sword:GetAttribute("SwordId") ~= "INFINITY" then
			local sell=makeButton("Sell","Vender",UDim2.new(1,-12,0,32),UDim2.fromOffset(6,178),Color3.fromRGB(170,55,65),item)
			sell.TextScaled=false; sell.TextSize=14
			local confirm=false; local busy=false
			sell.Activated:Connect(function()
				if busy then return end
				if not confirm then
					confirm=true; sell.Text="Confirmar venda?"
					task.delay(5,function() if sell.Parent and not busy then confirm=false; sell.Text="Vender" end end)
					return
				end
				busy=true; sell.Text="Vendendo..."
				local ok,success,msg=pcall(function() return menuSale:InvokeServer(sword) end)
				busy=false; confirm=false
				if sell.Parent then sell.Text=ok and success and "Vendida!" or "Falhou; tente novamente" end
				if ok and success then inventorySignature=nil; refreshInventory() end
			end)
		end

		local guard=makeButton("Store","Guardar",UDim2.new(1,-12,0,28),UDim2.fromOffset(6,212),Color3.fromRGB(65,100,155),item)
		local full=(player:GetAttribute("StoredSwordCount") or 0)>=5
		guard.Text=full and "Inventário cheio" or "Guardar"
		guard.Active=not full; guard.AutoButtonColor=not full
		if full then guard.BackgroundColor3=Color3.fromRGB(65,70,85) end
		guard.Activated:Connect(function()
			if (player:GetAttribute("StoredSwordCount") or 0)>=5 then return end
			local rf=game:GetService("ReplicatedStorage"):FindFirstChild("SwordInventoryV40")
			if rf then local ok,a,b=pcall(function() return rf:InvokeServer("Store",sword) end); if ok and a then inventorySignature=nil; refreshInventory() else guard.Text=tostring(b or "Falhou") end end
		end)
		local view=Instance.new("ViewportFrame")
		view.Size=UDim2.new(1,-12,0,86); view.Position=UDim2.fromOffset(6,6)
		view.BackgroundColor3=Color3.fromRGB(22,32,50); view.BorderSizePixel=0; view.Parent=item; corner(view,10)
		local clone=sword:Clone()
		for _,d in ipairs(clone:GetDescendants()) do
			if d:IsA("BasePart") then d.Anchored=true
			elseif d:IsA("LuaSourceContainer") or d:IsA("BillboardGui") or d:IsA("ProximityPrompt") or d:IsA("ParticleEmitter") or d:IsA("Light") then d:Destroy() end
		end
		clone.Parent=view
		local cf,sz=clone:GetBoundingBox()
		local cam=Instance.new("Camera"); cam.FieldOfView=40
		local dist=math.max(sz.X,sz.Y,sz.Z)*1.55
		cam.CFrame=CFrame.lookAt(cf.Position+Vector3.new(dist*.25,0,dist),cf.Position)
		cam.Parent=view; view.CurrentCamera=cam
		view.Ambient=Color3.fromRGB(180,180,190); view.LightColor=Color3.new(1,1,1)
	end


	totalLabel.Text = #swords .. "/" .. capacity() .. " espadas  •  Renda: +$" .. formatMoney(totalIncome) .. "/s"
	local empty=inventory:FindFirstChild("EmptyInventory")
	if empty then local b=inventory:FindFirstChild("StoredInventory"); empty.Visible=#swords==0 and not (b and b.Visible) end
	incomeLabel.Text = "+$" .. formatMoney(totalIncome) .. "/s"
end

-- ANIMACAO AO COLETAR

local function showMoneyGain(amount)
	if not animationsEnabled then
		return
	end

	local popup = makeText(
		"MoneyGain",
		"+$" .. formatMoney(amount),
		UDim2.fromOffset(200, 40),
		hud.Position + UDim2.fromOffset(0,-hud.Size.Y.Offset-32),
		Color3.fromRGB(85, 255, 130),
		gui
	)

	popup.TextStrokeTransparency = 0.4

	local tween = TweenService:Create(
		popup,
		TweenInfo.new(0.9, Enum.EasingStyle.Quad),
		{
			Position = hud.Position + UDim2.fromOffset(0,-hud.Size.Y.Offset-65),
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		}
	)

	tween:Play()

	tween.Completed:Connect(function()
		popup:Destroy()
	end)
end

local previousCash = cash.Value

local function updateCash()
	local newCash = cash.Value
	local difference = newCash - previousCash

	cashLabel.Text = "$" .. formatMoney(newCash)

	if difference > 0 then
		showMoneyGain(difference)
	end

	previousCash = newCash
end

cash:GetPropertyChangedSignal("Value"):Connect(updateCash)

-- BOTOES

inventoryButton.Activated:Connect(function()
	settings.Visible = false
	inventory.Visible = not inventory.Visible

	if inventory.Visible then
		refreshInventory()
	end
end)

closeInventory.Activated:Connect(function()
	inventory.Visible = false
end)

settingsButton.Activated:Connect(function()
	inventory.Visible = false
	settings.Visible = not settings.Visible
end)

closeSettings.Activated:Connect(function()
	settings.Visible = false
end)

animationButton.Activated:Connect(function()
	animationsEnabled = not animationsEnabled
end)

-- ATUALIZACAO AUTOMATICA

updateCash()
refreshInventory()

task.spawn(function()
	while gui.Parent do
		task.wait(1)
		refreshInventory()
	end
end)

print("[GameHUD V1] Interface iniciada!")


-- GAME HUD V2
-- Atualizacao visual: Roube uma Espada

local FONT = Enum.Font.FredokaOne

-- CONTORNO PRETO NOS TEXTOS

local function textOutline(object, thickness)
	local old = object:FindFirstChild("TextOutline")

	if old then
		old:Destroy()
	end

	local outline = Instance.new("UIStroke")
	outline.Name = "TextOutline"
	outline.Color = Color3.fromRGB(15, 15, 20)
	outline.Thickness = thickness or 2.5
	outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	outline.Parent = object
end

-- NOVO VISUAL DO DINHEIRO

hud.BackgroundTransparency = 1
hud.Size = UDim2.fromOffset(290, 100)
hud.Position = UDim2.new(0, 16, 1, -110)

for _, child in ipairs(hud:GetChildren()) do
	if child:IsA("UIStroke") then
		child:Destroy()
	end
end

title.Visible = false

cashLabel.Position = UDim2.fromOffset(0, 0)
cashLabel.Size = UDim2.fromOffset(290, 57)
cashLabel.Font = FONT
cashLabel.TextColor3 = Color3.fromRGB(105, 255, 25)
cashLabel.TextScaled = false
cashLabel.TextSize = 49

textOutline(cashLabel, 3.5)

incomeLabel.Position = UDim2.fromOffset(2, 57)
incomeLabel.Size = UDim2.fromOffset(285, 30)
incomeLabel.Font = FONT
incomeLabel.TextColor3 = Color3.new(1, 1, 1)
incomeLabel.TextScaled = false
incomeLabel.TextSize = 21

textOutline(incomeLabel, 2.5)

-- BOTOES NO LADO ESQUERDO

buttons.Size = UDim2.fromOffset(184, 188)
buttons.Position = UDim2.new(0, 18, 0.43, -94)

local buttonScale = Instance.new("UIScale")
buttonScale.Parent = buttons

-- ESTILO DOS BOTOES

local function styleGameButton(
	button, name, symbol, color, darkColor, x, y
)
	button.Size = UDim2.fromOffset(76, 76)
	button.Position = UDim2.fromOffset(x * 84 / 98, y * 84 / 98)
	button.BackgroundColor3 = color
	button.Text = ""
	button.AutoButtonColor = false
	button.ClipsDescendants = false

	for _, child in ipairs(button:GetChildren()) do
		if child:IsA("UICorner")
			or child:IsA("UIPadding")
			or child:IsA("UIStroke") then

			child:Destroy()
		end
	end

	corner(button, 9)

	local border = Instance.new("UIStroke")
	border.Color = darkColor
	border.Thickness = 3
	border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	border.Parent = button

	-- Gradiente para dar profundidade

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(
			0, Color3.new(1, 1, 1)
		),
		ColorSequenceKeypoint.new(
			1, Color3.fromRGB(170, 170, 185)
		),
	})
	gradient.Rotation = 90
	gradient.Parent = button

	-- Icone grande

	local ids = {Espadas="98310650334932", Rebirth="124742371751462", ["Índice"]="81627800041890", ["Opções"]="79503839182084", Loja="76897072825574", Daily="73111696227060", Quests="107350862334030"}
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(1, -12, 0, 49)
	icon.Position = UDim2.fromOffset(6, 2)
	icon.BackgroundTransparency = 1
	icon.Image = "rbxassetid://" .. ids[name]
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Parent = button

	-- Nome do botao

	local label = Instance.new("TextLabel")
	label.Name = "ButtonTitle"
	label.Size = UDim2.new(1, -4, 0, 21)
	label.Position = UDim2.new(0, 2, 1, -23)
	label.BackgroundTransparency = 1
	label.Text = name
	label.Font = FONT
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Parent = button

	textOutline(label, 2.2)

	-- Animacao ao passar o mouse

	local scale = Instance.new("UIScale")
	scale.Parent = button

	button.MouseEnter:Connect(function()
		if not animationsEnabled then return end

		TweenService:Create(
			scale,
			TweenInfo.new(0.15),
			{Scale = 1.07}
		):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(
			scale,
			TweenInfo.new(0.15),
			{Scale = 1}
		):Play()
	end)

	button.Activated:Connect(function()
		if not animationsEnabled then return end

		scale.Scale = 0.92

		TweenService:Create(
			scale,
			TweenInfo.new(
				0.25,
				Enum.EasingStyle.Back
			),
			{Scale = 1}
		):Play()
	end)

	return label
end

styleGameButton(
	inventoryButton,
	"Espadas",
	"⚔",
	Color3.fromRGB(163, 75, 230),
	Color3.fromRGB(90, 35, 150),
	0, 0
)

local rebirthTitle = styleGameButton(
	rebirthButton,
	"Rebirth",
	"R",
	Color3.fromRGB(255, 175, 35),
	Color3.fromRGB(180, 100, 15),
	98, 0
)

-- V31.12: engrenagem minimalista na barra superior, sem duplicar o botao.
do
	local GuiService=game:GetService("GuiService")
	local previous=playerGui:FindFirstChild("SwordSettingsTopbar")
	if previous then previous:Destroy() end
	local topGui=Instance.new("ScreenGui")
	topGui.Name="SwordSettingsTopbar"; topGui.ResetOnSpawn=false
	topGui.IgnoreGuiInset=true; topGui.ScreenInsets=Enum.ScreenInsets.None
	topGui.DisplayOrder=2; topGui.Parent=playerGui
	settingsButton.Parent=topGui
	settingsButton.Text=""; settingsButton.AutoButtonColor=false
	settingsButton.BackgroundColor3=Color3.fromRGB(20,23,30)
	settingsButton.BackgroundTransparency=.08; settingsButton.BorderSizePixel=0
	settingsButton.Size=UDim2.fromOffset(40,40)
	for _,child in ipairs(settingsButton:GetChildren()) do child:Destroy() end
	corner(settingsButton,20)
	local icon=Instance.new("ImageLabel")
	icon.Name="Icon"; icon.BackgroundTransparency=1; icon.Image="rbxassetid://79503839182084"
	icon.Size=UDim2.fromOffset(23,23); icon.AnchorPoint=Vector2.new(.5,.5)
	icon.Position=UDim2.fromScale(.5,.5); icon.ScaleType=Enum.ScaleType.Fit; icon.Parent=settingsButton
	-- Use the Roblox-managed free topbar area on mobile, not raw screen coordinates.
	local mobileTop=Instance.new("ScreenGui")
	mobileTop.Name="SwordSettingsMobileTopbar"
	local previousMobile=playerGui:FindFirstChild(mobileTop.Name)
	if previousMobile then previousMobile:Destroy() end
	mobileTop.ResetOnSpawn=false
	mobileTop.ScreenInsets=Enum.ScreenInsets.TopbarSafeInsets
	mobileTop.DisplayOrder=2
	mobileTop.Parent=playerGui
	local function layoutSettingsTopbar()
		local mobile=game:GetService("UserInputService").TouchEnabled or gui.AbsoluteSize.Y<550
		if mobile then
			local h=mobileTop.AbsoluteSize.Y
			local w=mobileTop.AbsoluteSize.X
			local size=math.min(36,math.max(24,h-4))
			settingsButton.Parent=mobileTop
			settingsButton.AnchorPoint=Vector2.new(0,.5)
			settingsButton.Size=UDim2.fromOffset(size,size)
			settingsButton.Position=UDim2.new(0,4,.5,5)
			settingsButton.Visible=w>=size+8 and h>=28
			return
		end
		settingsButton.AnchorPoint=Vector2.new(0,0)
		settingsButton.Visible=true
		local rect=GuiService.TopbarInset
		local height=rect.Max.Y-rect.Min.Y
		local width=rect.Max.X-rect.Min.X
		local size=math.min(mobile and 36 or 40,height-4)
		if width>=size+8 and height>=32 and size>=28 then
			settingsButton.Parent=topGui
			settingsButton.Size=UDim2.fromOffset(size,size)
			settingsButton.Position=UDim2.fromOffset(rect.Min.X+4,rect.Min.Y+(height-size)/2+5)
		else
			-- Fallback na area segura, somente se a barra nativa nao tiver espaco.
			settingsButton.Parent=gui
			settingsButton.Size=UDim2.fromOffset(36,36)
			settingsButton.Position=UDim2.fromOffset(12,8)
		end
	end
	GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(layoutSettingsTopbar)
	mobileTop:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutSettingsTopbar)
	topGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutSettingsTopbar)
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutSettingsTopbar)
	layoutSettingsTopbar()
	settingsButton.MouseEnter:Connect(function() settingsButton.BackgroundColor3=Color3.fromRGB(48,56,70) end)
	settingsButton.MouseLeave:Connect(function() settingsButton.BackgroundColor3=Color3.fromRGB(20,23,30) end)
end

-- NOVO BOTAO: INDICE

local indexButton = Instance.new("TextButton")
indexButton.Name = "Index"
indexButton.Parent = buttons

styleGameButton(
	indexButton,
	"Índice",
	"▤",
	Color3.fromRGB(55, 155, 245),
	Color3.fromRGB(25, 85, 165),
	0, 98
)

-- PAINEL DO INDICE

local indexPanel = makeFrame(
	"IndexPanel",
	UDim2.new(0.85, 0, 0.72, 0),
	UDim2.fromScale(0.5, 0.5),
	Color3.fromRGB(30, 40, 60),
	gui
)

indexPanel.AnchorPoint = Vector2.new(0.5, 0.5)
indexPanel.Visible = false
indexPanel.ZIndex = 5

corner(indexPanel, 16)
stroke(indexPanel, Color3.fromRGB(70, 155, 240), 4)

local indexConstraint = Instance.new("UISizeConstraint")
indexConstraint.MaxSize = Vector2.new(480, 460)
indexConstraint.Parent = indexPanel

local indexTitle = makeText(
	"Title",
	"ÍNDICE DE ESPADAS",
	UDim2.new(1, -65, 0, 42),
	UDim2.fromOffset(12, 10),
	Color3.new(1, 1, 1),
	indexPanel
)

indexTitle.Font = FONT
indexTitle.ZIndex = 6
textOutline(indexTitle, 2)

local closeIndex = makeButton(
	"Close",
	"X",
	UDim2.fromOffset(38, 38),
	UDim2.new(1, -48, 0, 10),
	Color3.fromRGB(230, 65, 65),
	indexPanel
)

closeIndex.ZIndex = 6

local indexScroll = Instance.new("ScrollingFrame")
indexScroll.Size = UDim2.new(1, -24, 1, -70)
indexScroll.Position = UDim2.fromOffset(12, 60)
indexScroll.BackgroundTransparency = 1
indexScroll.BorderSizePixel = 0
indexScroll.ScrollBarThickness = 5
indexScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
indexScroll.CanvasSize = UDim2.new()
indexScroll.ZIndex = 6
indexScroll.Parent = indexPanel

local indexLayout = Instance.new("UIListLayout")
indexLayout.Padding = UDim.new(0, 9)
indexLayout.Parent = indexScroll

-- V13: catalogo e progresso replicados pelo servidor
local indexProgress = makeText("ProgressText", "Carregando coleção...", UDim2.new(1,-24,0,24), UDim2.fromOffset(12,55), Color3.new(1,1,1), indexPanel)
indexProgress.ZIndex=7
local indexBar=makeFrame("IndexBar",UDim2.new(1,-24,0,9),UDim2.fromOffset(12,82),Color3.fromRGB(55,68,90),indexPanel)
indexBar.ZIndex=7; corner(indexBar,5); indexBar.ClipsDescendants=true
local indexFill=makeFrame("Fill",UDim2.fromScale(0,1),UDim2.new(),Color3.fromRGB(80,225,140),indexBar)
indexFill.ZIndex=8; corner(indexFill,5)
indexConstraint.MaxSize=Vector2.new(650,560)
indexScroll.Position=UDim2.fromOffset(12,139)
indexScroll.Size=UDim2.new(1,-24,1,-189)
indexLayout:Destroy()
local indexGrid=Instance.new("UIGridLayout")
indexGrid.CellSize=UDim2.new(1/4,-7,0,164)
indexGrid.CellPadding=UDim2.fromOffset(6,8)
indexGrid.SortOrder=Enum.SortOrder.LayoutOrder
indexGrid.Parent=indexScroll
local reward=makeButton("Reward","INFINITY • Complete a coleção",UDim2.new(1,-24,0,34),UDim2.new(0,12,1,-40),Color3.fromRGB(110,85,45),indexPanel)
reward.ZIndex=7
local indexRS=game:GetService("ReplicatedStorage")
local indexCards={}
local selected="Normal"
local variants={Normal={1,Color3.fromRGB(150,160,180)},Golden={1.5,Color3.fromRGB(255,195,45)},Diamond={2,Color3.fromRGB(75,220,255)},Rainbow={3,Color3.fromRGB(220,100,255)},Corrupted={5,Color3.fromRGB(135,35,190)}}
local tabs={}
for i,name in ipairs({"Normal","Golden","Diamond","Rainbow","Corrupted"}) do
	local tab=makeButton(name,name,UDim2.new(.2,-8,0,28),UDim2.new((i-1)*.2,12-(i-1)*4,0,101),Color3.fromRGB(55,68,90),indexPanel)
	tab.ZIndex=8; tab.TextSize=12; tabs[name]=tab
	tab.Activated:Connect(function()
		selected=name
		for _,entry in pairs(indexCards) do entry.card:Destroy() end
		table.clear(indexCards)
		indexScroll.CanvasPosition=Vector2.zero
	end)
end
reward.Activated:Connect(function()
	local folder=player:FindFirstChild("SwordIndex")
	local remote=indexRS:FindFirstChild("ClaimInfinity")
	if folder and remote and folder:GetAttribute("Count_"..selected)==folder:GetAttribute("Total") and not folder:GetAttribute("Claimed_"..selected) then remote:FireServer(selected) end
end)
local function makePreview(template, parent, unlocked)
	local viewport=Instance.new("ViewportFrame")
	viewport.Size=UDim2.new(1,-8,0,110); viewport.Position=UDim2.fromOffset(4,5)
	viewport.BackgroundTransparency=1; viewport.ZIndex=8; viewport.Parent=parent
	viewport.Ambient=Color3.fromRGB(170,170,180); viewport.LightColor=Color3.new(1,1,1)
	viewport.LightDirection=Vector3.new(-1,-1,-1)
	local model=template:Clone()
	for _,part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored=true
			if unlocked and selected~="Normal" then part.Color=part.Color:Lerp(variants[selected][2],.8) end
			if not unlocked then part.Color=Color3.fromRGB(42,49,65); part.Material=Enum.Material.SmoothPlastic; if part:IsA("MeshPart") then part.TextureID="" end end
		elseif part:IsA("Script") or part:IsA("LocalScript") or part:IsA("BillboardGui") or part:IsA("ParticleEmitter") or part:IsA("Light") or (not unlocked and (part:IsA("SurfaceAppearance") or part:IsA("Decal") or part:IsA("Texture"))) then part:Destroy() end
	end
	model.Parent=viewport
	local cf,size=model:GetBoundingBox()
	local camera=Instance.new("Camera"); camera.FieldOfView=38
	local distance=math.max(size.X,size.Y,size.Z)*1.75
	camera.CFrame=CFrame.lookAt(cf.Position+Vector3.new(distance*.23,0,distance),cf.Position)
	camera.Parent=viewport; viewport.CurrentCamera=camera
	return viewport
end
-- Ordem visual por renda base (mesma progressao dos precos).
-- Nao depende do nome traduzido nem altera o IndexOrder do servidor.
local function swordVisualOrder(template, order)
	local income = template:GetAttribute("Income")
	if typeof(income) == "number" and income > 0 then return math.floor(income) end
	return 1000000 + order
end
local function refreshIndex()
	local folder=player:FindFirstChild("SwordIndex")
	local catalogFolder=indexRS:FindFirstChild("SwordIndexCatalog")
	if not folder or not folder:GetAttribute("Ready") or not catalogFolder then return end
	local count=folder:GetAttribute("Count_"..selected) or 0
	local total=folder:GetAttribute("Total") or 14
	local claimed=folder:GetAttribute("Claimed_"..selected)
	for name,tab in pairs(tabs) do tab.BackgroundColor3=name==selected and variants[name][2] or Color3.fromRGB(39,55,75); tab.TextColor3=name==selected and Color3.fromRGB(17,27,44) or Color3.fromRGB(220,230,245) end
	local rewardIncome = formatMoney(150000 * variants[selected][1])
	reward.Text=claimed and ("INFINITY • Resgatada • $"..rewardIncome.."/s") or (count==total and ("RESGATAR INFINITY • $"..rewardIncome.."/s") or ("INFINITY • $"..rewardIncome.."/s • Complete a coleção"))
	reward.BackgroundColor3=count==total and not claimed and Color3.fromRGB(180,125,30) or Color3.fromRGB(110,85,45)
	indexProgress.Text=selected.." • "..count.." / "..total.." espadas descobertas"
	indexFill.Size=UDim2.fromScale(math.clamp(count/math.max(total,1),0,1),1)
	for _,template in ipairs(catalogFolder:GetChildren()) do
		local order=template:GetAttribute("IndexOrder")
		if template:IsA("Model") and order then
			local unlocked=folder:GetAttribute(selected.."_"..order)==true
			local old=indexCards[order]
			if old then old.card.LayoutOrder=swordVisualOrder(template, order) end
			if not old or old.unlocked~=unlocked then
				if old then old.card:Destroy() end
				local color=unlocked and (template:GetAttribute("IndexColor") or Color3.new(1,1,1)) or Color3.fromRGB(100,112,135)
				local card=makeFrame("Sword_"..order,UDim2.new(),UDim2.new(),Color3.fromRGB(42,54,75),indexScroll)
				card.LayoutOrder=swordVisualOrder(template, order); card.ZIndex=7; corner(card,10); stroke(card,color,1.5)
				makePreview(template,card,unlocked)
				if not unlocked then local q=makeText("Locked","🔒",UDim2.fromOffset(24,24),UDim2.fromOffset(8,8),Color3.new(1,1,1),card); q.ZIndex=9; q.Font=FONT; q.TextScaled=false; q.TextSize=16 end
				local name=makeText("Name",unlocked and template.Name or "???",UDim2.new(1,-8,0,22),UDim2.fromOffset(4,116),color,card)
				name.ZIndex=8; name.Font=FONT; name.TextScaled=false; name.TextSize=15; name.TextTruncate=Enum.TextTruncate.AtEnd
				local info=makeText("Info",unlocked and (tostring(template:GetAttribute("Rarity")).." • $"..formatMoney((template:GetAttribute("Income") or 0)*variants[selected][1]).."/s") or "Não descoberta",UDim2.new(1,-8,0,22),UDim2.fromOffset(4,138),Color3.fromRGB(220,225,235),card)
				info.ZIndex=8; info.TextScaled=false; info.TextSize=11; info.TextTruncate=Enum.TextTruncate.AtEnd
				indexCards[order]={card=card,unlocked=unlocked}
			end
		end
	end
end
task.spawn(function()
	while gui.Parent do
		if indexPanel.Visible then refreshIndex() end
		task.wait(.3)
	end
end)

indexButton.Activated:Connect(function()
	inventory.Visible = false
	settings.Visible = false
	indexPanel.Visible = not indexPanel.Visible
	if indexPanel.Visible then refreshIndex() end
end)

closeIndex.Activated:Connect(function()
	indexPanel.Visible = false
end)

inventoryButton.Activated:Connect(function()
	indexPanel.Visible = false
end)

settingsButton.Activated:Connect(function()
	indexPanel.Visible = false
end)

-- OBJETIVO NO TOPO DA TELA

local objective = makeText(
	"Objective",
	"Encontre uma espada na arena!",
	UDim2.new(0.8, 0, 0, 48),
	UDim2.new(0.1, 0, 0, 45),
	Color3.new(1, 1, 1),
	gui
)

objective.Font = FONT
objective.TextScaled = true
textOutline(objective, 3)

local objectiveLimit = Instance.new("UITextSizeConstraint")
objectiveLimit.MaxTextSize = 32
objectiveLimit.MinTextSize = 14
objectiveLimit.Parent = objective

local carriedSwords = map:WaitForChild("CarriedSwords")

local function updateObjective()
	for _, sword in ipairs(carriedSwords:GetChildren()) do
		if sword:GetAttribute("CarrierUserId") == player.UserId then
			objective.Text = "Leve a espada até sua base!"
			objective.TextColor3 = Color3.fromRGB(255, 225, 75)
			return
		end
	end

	local owned = getOwnedSwords()

	if #owned == 0 then
		objective.Text = "Encontre uma espada na arena!"
	elseif cash.Value == 0 then
		objective.Text = "Colete o dinheiro da sua espada!"
	elseif #owned >= capacity() then
		objective.Text = "Base cheia! Venda uma espada (F)."
	else
		objective.Text = "Colecione espadas mais raras!"
	end

	objective.TextColor3 = Color3.new(1, 1, 1)
end

-- ADAPTAR A TELAS MENORES

local function updateScreenSize()
	local w,h=gui.AbsoluteSize.X,gui.AbsoluteSize.Y
	local small=game:GetService("UserInputService").TouchEnabled or w<700 or h<550
	local scale=small and math.clamp(math.min(w/650,h/340),.68,.92) or math.min(1,h/580)
	buttonScale.Scale=small and (math.min(scale,math.max(.58,(h-100)/180))*.85) or scale
	local margin=small and 12 or 14
	local moneyHeight=small and 82 or 104
	hud.AnchorPoint=Vector2.new(0,1)
	hud.Position=UDim2.new(0,margin,1,-margin)
	hud.Size=UDim2.fromOffset(small and 170 or 265,moneyHeight)
	buttons.AnchorPoint=Vector2.new(0,.5)
	buttons.Position=UDim2.new(0,margin,small and .38 or .5,0)
	-- Money labels are sized by layoutMoney below.
	objective.Size=UDim2.new(.72,0,0,30)
	objectiveLimit.MaxTextSize=small and 16 or 25
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateScreenSize)

-- ATUALIZACAO DA V2

task.spawn(function()
	while gui.Parent do
		local totalIncome = 0

		for _, sword in ipairs(getOwnedSwords()) do
			local rarity = sword:GetAttribute("Rarity")
			totalIncome += math.floor((sword:GetAttribute("Income") or INCOME[rarity] or 0) * (player:GetAttribute("IncomeMultiplier") or 1) * (player:GetAttribute("GamepassIncomeMultiplier") or 1))
		end

		incomeLabel.Text =
			"+$" .. formatMoney(totalIncome) .. "/s"

		-- Compatibilidade com o botao Rebirth da V1

		rebirthTitle.Text = "Rebirth"

		rebirthButton.TextTransparency = 1

		updateObjective()

		task.wait(0.25)
	end
end)

updateScreenSize()
updateObjective()

print("[GameHUD V2] Novo visual iniciado!")

-- GAME HUD V3: REBIRTH
local remote = game:GetService("ReplicatedStorage"):WaitForChild("RequestRebirth")
local requirements = {{5000,{"Espada de Ferro","Wooden Blade"},1.5},{15000,{"Bronze Blade","Knight Sword"},2},{40000,{"Esmeralda","Crimson Blade"},2.5},{100000,{"Venom Fang","Jade Katana"},3},{250000,{"Frostbite","Thunder Blade"},4},{600000,{"Glacier"},4.5},{1500000,{"Aquamarine"},5},{4000000,{"Voidblade","Aquamarine"},5.5},{10000000,{"Shadow Reaper"},6},{25000000,{"Solaris","Shadow Reaper"},7},{75000000,{"Sunbreaker"},8},{200000000,{"Infernal","Sunbreaker"},9},{750000000,{"Eclipse"},10},{2500000000,{"Oblivion","Eclipse"},12},{10000000000,{"Aether"},15,true}}
local panel = makeFrame("RebirthPanel",UDim2.new(.88,0,.72,0),UDim2.fromScale(.5,.5),Color3.fromRGB(25,30,48),gui)
panel.AnchorPoint=Vector2.new(.5,.5); panel.Visible=false; panel.ZIndex=10
corner(panel,16); stroke(panel,Color3.fromRGB(155,95,240),3)
local limit=Instance.new("UISizeConstraint"); limit.MaxSize=Vector2.new(660,470); limit.Parent=panel
local function line(name,text,y,height,color)
	local l=makeText(name,text,UDim2.new(1,-30,height,0),UDim2.new(0,15,y,0),color,panel)
	l.ZIndex=11; l.Font=FONT; l.TextWrapped=true; return l
end
local white=Color3.new(1,1,1)
local heading=line("Title","REBIRTH",.03,.12,white)
local bonus=line("Bonus","",.13,.10,Color3.fromRGB(195,145,255))
local money=line("Money","",.24,.08,white)
local bar=makeFrame("Progress",UDim2.new(.85,0,.035,0),UDim2.fromScale(.075,.33),Color3.fromRGB(65,70,95),panel); bar.ZIndex=11; corner(bar,6); bar.ClipsDescendants=true
local fill=makeFrame("Fill",UDim2.fromScale(0,1),UDim2.new(),Color3.fromRGB(100,220,130),bar); fill.ZIndex=12; corner(fill,6)
local requiredCards={}
local function updateRequiredCards(req,owned,claimed)
	local names={}
	if req then
		for _,name in ipairs(req[2]) do table.insert(names,name) end
		if req[4] then table.insert(names,"INFINITY") end
	end
	for i,card in ipairs(requiredCards) do
		local name=names[i]
		card.Frame.Visible=name~=nil
		if name then
			card.Frame.Size=UDim2.new(1/#names,-6,1,0)
			card.Frame.Position=UDim2.new((i-1)/#names,3,0,0)
			local ok=(name=="INFINITY" and claimed) or (name~="INFINITY" and owned[name])
			card.NameLabel.Text=name=="INFINITY" and "INFINITY (Índice)" or name
			card.Status.Text=ok and "1/1 • Obtida" or "0/1 • Falta"
			card.Status.TextColor3=ok and Color3.fromRGB(105,240,145) or Color3.fromRGB(245,145,145)
			if card.PreviewName~=name then
				if card.View then card.View:Destroy(); card.View=nil end
				local catalog=indexRS:FindFirstChild("SwordIndexCatalog")
				local template=name=="INFINITY" and indexRS:FindFirstChild("RebirthInfinityPreview") or (catalog and catalog:FindFirstChild(name))
				if template and template:IsA("Model") then
					local v=Instance.new("ViewportFrame"); v.BackgroundTransparency=1; v.Ambient=Color3.fromRGB(180,180,190); v.LightColor=Color3.new(1,1,1); v.Parent=card.Frame
					v.Size=UDim2.fromOffset(76,64); v.Position=UDim2.fromOffset(4,2); v.ZIndex=15
					-- Rebirth previews always use the original model, independent of index tab.
					local original=template:Clone()
					for _,p in ipairs(original:GetDescendants()) do if p:IsA("BasePart") then p.Anchored=true elseif p:IsA("Script") or p:IsA("LocalScript") or p:IsA("BillboardGui") or p:IsA("ParticleEmitter") or p:IsA("Light") then p:Destroy() end end
					original.Parent=v
					local cf,size=original:GetBoundingBox(); local d=math.max(size.X,size.Y,size.Z)*1.9
					local cam=Instance.new("Camera"); cam.FieldOfView=40; cam.CFrame=CFrame.lookAt(cf.Position+Vector3.new(d*.2,0,d),cf.Position); cam.Parent=v; v.CurrentCamera=cam
					card.View=v; card.PreviewName=name
				end
			end
		end
	end
end
local upgrade=line("Upgrade","",.64,.08,Color3.fromRGB(110,230,155))
local protection=line("Protection","",.70,.055,Color3.fromRGB(110,200,255))
local warning=line("Warning","Você perderá o dinheiro e as espadas da base e inventário. Voltará com $100.",.765,.07,Color3.fromRGB(230,190,150))
local action=makeButton("Confirm","RENASCER",UDim2.new(.8,0,.12,0),UDim2.fromScale(.1,.85),Color3.fromRGB(125,65,220),panel); action.ZIndex=11
local close=makeButton("Close","X",UDim2.fromOffset(32,32),UDim2.new(1,-40,0,8),Color3.fromRGB(200,65,75),panel); close.ZIndex=12
local ready=false
local function refreshRebirth()
	local level=player:GetAttribute("Rebirths") or 0
	local req=requirements[level+1]
	heading.Text=req and ("REBIRTH "..(level+1)) or "REBIRTH MÁXIMO"

	local n=math.min(level+1,10)
	upgrade.Text=req and ((10+(n>0 and math.min(n+1,6) or 0)+(n>=6 and n-4 or 0)).." expositores • "..(n>=6 and "3 andares" or (n>=1 and "2 andares" or "1 andar"))) or "Base máxima"
	protection.Text=req and ("Proteção: "..(30+15*math.min(level,10)).."s → "..(30+15*n).."s") or "Proteção máxima: 180s"
	ready=false
	if not req then bonus.Text="Nível máximo!"; money.Text=""; updateRequiredCards(nil,{},false); fill.Size=UDim2.fromScale(1,1); action.Text="CONCLUÍDO"; return end
	bonus.Text=tostring(player:GetAttribute("IncomeMultiplier") or 1).."x → "..req[3].."x"
	money.Text="$"..formatMoney(cash.Value).." / $"..formatMoney(req[1])
	fill.Size=UDim2.fromScale(math.clamp(cash.Value/req[1],0,1),1)
	local owned={}
	for _,sword in ipairs(getOwnedSwords()) do owned[sword.Name]=true end
	local found=true; local claimed=false
	for _,name in ipairs(req[2]) do
		if not owned[name] then found=false end
	end
	if req[4] then
		local idx=player:FindFirstChild("SwordIndex")
		claimed=idx and idx:GetAttribute("RewardClaimed")==true
		if not claimed then found=false end
	end
	updateRequiredCards(req,owned,claimed)
	ready=found and cash.Value>=req[1]
	action.Text=ready and "RENASCER" or "FALTAM REQUISITOS"
	action.BackgroundColor3=ready and Color3.fromRGB(190,137,35) or Color3.fromRGB(75,80,100)
end
rebirthButton.Activated:Connect(function() inventory.Visible=false; settings.Visible=false; indexPanel.Visible=false; panel.Visible=not panel.Visible; refreshRebirth() end)
close.Activated:Connect(function() panel.Visible=false end)
for _,button in ipairs({inventoryButton,settingsButton,indexButton}) do button.Activated:Connect(function() panel.Visible=false end) end
local confirmUntil=0
action.Activated:Connect(function()
	if not ready then return end
	if os.clock()>confirmUntil then confirmUntil=os.clock()+4; return end
	confirmUntil=0; remote:FireServer()
end)
task.spawn(function()
	while gui.Parent do
		if panel.Visible then refreshRebirth(); if ready and os.clock()<confirmUntil then action.Text="CONFIRMAR RENASCIMENTO" end else confirmUntil=0 end
		task.wait(.2)
	end
end)

-- V17.3: menus responsivos
local function resizeMenus()
	local w,h=gui.AbsoluteSize.X,gui.AbsoluteSize.Y
	if w<=0 or h<=0 then return end
	local small=game:GetService("UserInputService").TouchEnabled or w<700
	for _,e in ipairs({{inventory,650,520},{indexPanel,650,560},{settings,520,300},{panel,660,470}}) do
		local f,bw,bh=e[1],e[2],e[3]
		local scale=f:FindFirstChild("ResponsiveScale") or Instance.new("UIScale")
		scale.Name="ResponsiveScale"; scale.Parent=f
		f.Size=UDim2.fromOffset(bw,bh)
		scale.Scale=math.min(1,w*(small and .88 or .95)/bw,h*(small and .86 or .95)/bh)
	end
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeMenus)
resizeMenus()

-- V20: acabamento visual compartilhado
local function gradient(obj, top, bottom)
	local g=Instance.new("UIGradient"); g.Color=ColorSequence.new(top,bottom); g.Rotation=90; g.Parent=obj
end
local function polishPanel(p, accent)
	p.BackgroundColor3=Color3.fromRGB(35,48,72)
	gradient(p,Color3.new(1,1,1),Color3.fromRGB(150,165,195))
	for _,v in ipairs(p:GetChildren()) do
		if v:IsA("UIStroke") then v.Color=accent; v.Thickness=3 end
	end
	local header=p:FindFirstChild("Title")
	if header then header.Font=FONT; textOutline(header,2) end
	local shadow=makeFrame("HeaderAccent",UDim2.new(1,-32,0,4),UDim2.fromOffset(16,49),accent,p)
	shadow.ZIndex= p.ZIndex+1; corner(shadow,2)
end
polishPanel(inventory,Color3.fromRGB(165,110,245))
polishPanel(indexPanel,Color3.fromRGB(85,185,255))
polishPanel(settings,Color3.fromRGB(145,170,205))
polishPanel(panel,Color3.fromRGB(255,185,65))
-- O painel de rebirth usa layout proporcional; evita sobrepor o subtitulo.
panel.HeaderAccent:Destroy()
for _,p in ipairs({inventory,indexPanel,settings,panel}) do
	p:GetPropertyChangedSignal("Visible"):Connect(function()
		if p.Visible and animationsEnabled then
			p.Position=UDim2.fromScale(.5,.53)
			TweenService:Create(p,TweenInfo.new(.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=UDim2.fromScale(.5,.5)}):Play()
		else p.Position=UDim2.fromScale(.5,.5) end
	end)
end
print("[GameHUD V20] Interface remodelada!")

-- V25.3: Daily Rewards & Quests
-- Escopo separado para evitar excesso de variaveis locais no HUD.
do
	local rs=game:GetService("ReplicatedStorage")
	local top=makeFrame("DailyQuestButtons",UDim2.fromOffset(174,56),UDim2.new(1,-12,0,8),Color3.new(),playerGui:WaitForChild("SwordSettingsTopbar"))
	top.AnchorPoint=Vector2.new(1,0); top.BackgroundTransparency=1
	local dailyButton=Instance.new("TextButton"); dailyButton.Name="Daily"; dailyButton.Parent=top
	local questsButton=Instance.new("TextButton"); questsButton.Name="Quests"; questsButton.Parent=top
	styleGameButton(dailyButton,"Daily","$",Color3.fromRGB(55,190,110),Color3.fromRGB(25,105,65),0,0)
	styleGameButton(questsButton,"Quests","✓",Color3.fromRGB(235,125,55),Color3.fromRGB(145,65,25),98,0)
	for _,button in ipairs({dailyButton,questsButton}) do
		button.Size=UDim2.fromOffset(76,56)
		button.Icon.Size=UDim2.new(1,-12,0,32)
		button.ButtonTitle.Size=UDim2.new(1,-4,0,20)
		button.ButtonTitle.Position=UDim2.new(0,2,1,-22)
	end
	buttons.Size=UDim2.fromOffset(160,160)
	local topScale=Instance.new("UIScale"); topScale.Parent=top
	local GuiService=game:GetService("GuiService")
	local function layoutTop()
		local w,h=gui.AbsoluteSize.X,gui.AbsoluteSize.Y
		local mobile=game:GetService("UserInputService").TouchEnabled or h<550
		if mobile then
			top.Parent=gui
			topScale.Scale=.82
			top.Position=UDim2.new(1,-12,0,8)
			objective.Position=UDim2.new(.5,0,0,64)
			return
		end
		top.Parent=playerGui:WaitForChild("SwordSettingsTopbar")
		topScale.Scale=math.clamp(math.min(w/650,h/340),.75,1)
		local rect=GuiService.TopbarInset
		local centerY=(rect.Min.Y+rect.Max.Y)/2+5
		local inset=GuiService:GetGuiInset()
		local right=math.min(top.Parent.AbsoluteSize.X-12,rect.Max.X-4)
		local fits=right-174*topScale.Scale>=rect.Min.X+52 and rect.Max.Y-rect.Min.Y>=32
		top.Position=UDim2.fromOffset(fits and right or right, fits and math.max(0,centerY-28*topScale.Scale) or inset.Y+8)
		objective.AnchorPoint=Vector2.new(.5,0)
		objective.Position=UDim2.new(.5,0,0,72)
		objective.Size=UDim2.new(.72,0,0,30)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutTop)
	GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(layoutTop)
	playerGui:WaitForChild("SwordSettingsTopbar"):GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutTop); layoutTop()
	updateScreenSize()
	local p=makeFrame("DailyQuestsPanel",UDim2.fromOffset(660,470),UDim2.fromScale(.5,.5),Color3.fromRGB(24,36,53),gui)
	p.AnchorPoint=Vector2.new(.5,.5); p.Visible=false; p.ZIndex=20; p.ClipsDescendants=true; corner(p,16); stroke(p,Color3.fromRGB(65,83,108),2)
	local scale=Instance.new("UIScale"); scale.Parent=p
	local function fit() local w,h=gui.AbsoluteSize.X,gui.AbsoluteSize.Y; if w>0 and h>0 then scale.Scale=math.min(1,w*.94/660,h*.94/470) end end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit); fit()
	local function label(parent,name,txt,x,y,w,h,color)
		local l=makeText(name,txt,UDim2.fromOffset(w,h),UDim2.fromOffset(x,y),color or Color3.new(1,1,1),parent); l.ZIndex=22; l.TextWrapped=true; l.TextScaled=false; l.TextSize=16; l.Font=Enum.Font.GothamBold; l.TextStrokeTransparency=1; return l
	end
	local function btn(parent,name,txt,x,y,w,h,color)
		local b=makeButton(name,txt,UDim2.fromOffset(w,h),UDim2.fromOffset(x,y),color,parent); b.ZIndex=23; b.TextScaled=false; b.TextSize=14; b.Font=Enum.Font.GothamBold; return b
	end
	local header=makeFrame("RewardsHeader",UDim2.fromOffset(660,58),UDim2.new(),Color3.fromRGB(49,79,111),p); header.ZIndex=21; corner(header,12)
	local title=label(header,"Title","RECOMPENSAS DIÁRIAS",18,5,560,48); title.TextSize=25; title.TextXAlignment=Enum.TextXAlignment.Left
	local exit=btn(header,"Close","X",610,10,38,38,Color3.fromRGB(199,62,71)); exit.TextSize=21
	local timer=label(p,"Timer","Carregando...",18,65,624,25,Color3.fromRGB(180,205,235)); timer.TextSize=14
	local status=label(p,"Status","",18,430,624,30,Color3.fromRGB(255,210,110)); status.TextSize=13
	local daily=Instance.new("ScrollingFrame"); daily.Name="DailyCards"; daily.Size=UDim2.fromOffset(624,330); daily.Position=UDim2.fromOffset(18,96); daily.BackgroundTransparency=1; daily.BorderSizePixel=0; daily.ScrollBarThickness=5; daily.CanvasSize=UDim2.fromOffset(0,330); daily.ZIndex=21; daily.Parent=p
	local quest=makeFrame("QuestCards",UDim2.fromOffset(516,310),UDim2.fromOffset(72,96),Color3.new(),p); quest.BackgroundTransparency=1; quest.ZIndex=21
	local cards={}; local rows={}; local mode="Daily"; local state; local busy=false; local messageUntil=0
	local green=Color3.fromRGB(45,170,100); local gray=Color3.fromRGB(75,90,115)
	local function request(action,id)
		local r=rs:FindFirstChild("DailyQuestsRequest")
		if not r or not r:IsA("RemoteFunction") then return false,"Servidor de recompensas indisponível." end
		local ok,a,b=pcall(function() return r:InvokeServer(action,id) end)
		if not ok then return false,"Falha de conexão." end
		return a,b
	end
	local function claim(action,id)
		if busy then return end; busy=true
		task.spawn(function()
			local ok,msg=request(action,id); status.Text=tostring(msg or "Tente novamente."); messageUntil=os.clock()+5
			task.wait(.4); local good,data=request("State"); if good and type(data)=="table" then state=data end
			busy=false
		end)
	end
	for i=1,7 do
		local x=((i-1)%3)*210; local y=math.floor((i-1)/3)*108; local w=204; local h=100
		if i==7 then x=0; y=216; w=624; h=108 end
		local c=makeFrame("Day"..i,UDim2.fromOffset(w,h),UDim2.fromOffset(x,y),Color3.fromRGB(39,65,85),daily); c.ZIndex=21; corner(c,8)
		local edge=Instance.new("UIStroke"); edge.Color=Color3.fromRGB(15,30,44); edge.Thickness=3; edge.Parent=c
		local heading=label(c,"Day",i==7 and "DIA 7 - PRÊMIO ESPECIAL" or "DIA "..i,8,3,w-16,22,Color3.fromRGB(255,255,255)); heading.TextSize=16; heading.Font=Enum.Font.FredokaOne; heading.TextStrokeTransparency=.35
		local rewardText=label(c,"Reward","",58,25,w-66,38,Color3.fromRGB(105,240,145)); rewardText.TextSize=25; rewardText.Font=Enum.Font.FredokaOne; rewardText.TextStrokeTransparency=.35
		local icon=Instance.new("ImageLabel"); icon.BackgroundTransparency=1; icon.Image=i==7 and "rbxassetid://98310650334932" or "rbxassetid://85968636395107"; icon.Size=UDim2.fromOffset(48,48); icon.Position=UDim2.fromOffset(8,22); icon.ZIndex=23; icon.ScaleType=Enum.ScaleType.Fit; icon.Parent=c
		if i~=7 then
			icon.Visible=false
			local cashIcon=label(c,"CashIcon","$",8,22,48,42,Color3.fromRGB(105,240,145)); cashIcon.Font=Enum.Font.FredokaOne; cashIcon.TextSize=34; cashIcon.TextStrokeTransparency=.25
		end
		if i==7 then
			icon.Size=UDim2.fromOffset(94,94); icon.Position=UDim2.fromOffset(12,7)
			heading.Position=UDim2.fromOffset(116,10); heading.Size=UDim2.fromOffset(300,25); heading.TextXAlignment=Enum.TextXAlignment.Left; heading.TextColor3=Color3.fromRGB(255,216,96)
			rewardText.Position=UDim2.fromOffset(116,39); rewardText.Size=UDim2.fromOffset(300,48); rewardText.TextXAlignment=Enum.TextXAlignment.Left; rewardText.TextColor3=Color3.fromRGB(255,224,120); rewardText.TextSize=23
		end
		local b=btn(c,"Claim","",i==7 and 430 or 8,i==7 and 34 or 66,i==7 and 182 or w-16,i==7 and 42 or 27,gray)
		b.Font=Enum.Font.FredokaOne; b.TextSize=15; b.TextStrokeTransparency=.4
		b.Activated:Connect(function() if state and state.CanClaim and state.Daily.NextDay==i then claim("Daily") end end)
		cards[i]={Reward=rewardText,Button=b,Edge=edge,Card=c}
	end
	quest.Position=UDim2.fromOffset(18,96); quest.Size=UDim2.fromOffset(624,324)
	local questIcons={"98310650334932","107350862334030","85968636395107"}
	local questColors={Color3.fromRGB(174,115,255),Color3.fromRGB(255,174,72),Color3.fromRGB(85,230,145)}
	for i=1,3 do
		local accent=questColors[i]
		local c=makeFrame("Quest"..i,UDim2.fromOffset(624,100),UDim2.fromOffset(0,(i-1)*108),Color3.fromRGB(39,65,85),quest); c.ZIndex=21; corner(c,10)
		local edge=Instance.new("UIStroke"); edge.Color=accent; edge.Thickness=2; edge.Parent=c
		local icon=Instance.new("ImageLabel"); icon.BackgroundTransparency=1; icon.Image="rbxassetid://"..questIcons[i]; icon.Size=UDim2.fromOffset(56,56); icon.Position=UDim2.fromOffset(12,22); icon.ZIndex=23; icon.ScaleType=Enum.ScaleType.Fit; icon.Parent=c
		local name=label(c,"Title","",82,8,350,28); name.TextXAlignment=Enum.TextXAlignment.Left; name.TextSize=20
		local info=label(c,"Progress","",82,38,350,22,Color3.fromRGB(190,215,240)); info.TextXAlignment=Enum.TextXAlignment.Left
		local bar=makeFrame("Bar",UDim2.fromOffset(350,14),UDim2.fromOffset(82,72),Color3.fromRGB(19,34,49),c); bar.ZIndex=22; corner(bar,7); bar.ClipsDescendants=true
		local fill=makeFrame("Fill",UDim2.fromScale(0,1),UDim2.new(),accent,bar); fill.ZIndex=23; corner(fill,7)
		local reward=label(c,"Reward","",444,8,168,28,Color3.fromRGB(105,240,145)); reward.TextSize=21
		local b=btn(c,"Claim","",444,42,168,44,gray)
		b.Activated:Connect(function() local q=state and state.Quests[i]; if q and not q.Claimed and q.Progress>=q.Target then claim("Quest",q.Id) end end)
		rows[i]={Name=name,Info=info,Fill=fill,Button=b,Reward=reward,Card=c,Icon=icon,Bar=bar,Edge=edge,Accent=accent}
	end
	local function render()
		if not state then timer.Text="Carregando recompensas..."; return end
		local seconds=math.max(0,state.ResetAt-os.time()); timer.Text=string.format("Renova em %02d:%02d:%02d UTC",math.floor(seconds/3600),math.floor(seconds/60)%60,seconds%60)
		for i,c in ipairs(cards) do
			c.Reward.Text=i==7 and "Espada Rara ou superior" or "$"..formatMoney(state.DailyCash[i] or 0)
			local available=state.CanClaim and state.Daily.NextDay==i
			c.Button.Text=available and "RESGATAR" or (i<state.Daily.NextDay and "RESGATADO" or (i==state.Daily.NextDay and "AMANHÃ" or "BLOQUEADO")); c.Button.BackgroundColor3=available and green or gray
			c.Edge.Color=available and Color3.fromRGB(80,225,140) or (i==7 and Color3.fromRGB(210,166,65) or Color3.fromRGB(15,30,44))
			c.Card.BackgroundColor3=i==7 and Color3.fromRGB(92,66,24) or (available and Color3.fromRGB(29,103,66) or Color3.fromRGB(39,65,85))
			c.Button.BackgroundColor3=available and Color3.fromRGB(32,175,75) or (i<state.Daily.NextDay and Color3.fromRGB(36,110,78) or gray)
		end
		for i,r in ipairs(rows) do local q=state.Quests[i]; if q then
				r.Name.Text=q.Title; r.Info.Text=formatMoney(q.Progress).." / "..formatMoney(q.Target); r.Reward.Text="$"..formatMoney(q.Reward)
				r.Fill.Size=UDim2.fromScale(math.clamp(q.Progress/math.max(1,q.Target),0,1),1)
				local available=not q.Claimed and q.Progress>=q.Target; r.Button.Text=q.Claimed and "RESGATADO" or (available and "RESGATAR" or "EM PROGRESSO"); r.Button.BackgroundColor3=available and green or (q.Claimed and Color3.fromRGB(36,110,78) or gray); r.Card.BackgroundColor3=available and Color3.fromRGB(29,85,65) or Color3.fromRGB(39,65,85); r.Edge.Color=available and green or r.Accent; r.Button.Active=available; r.Button.AutoButtonColor=available
			end end
		if os.clock()>messageUntil then status.Text="" end
	end
	local function fitRewards()
		local w,h=gui.AbsoluteSize.X,gui.AbsoluteSize.Y
		if w<=0 or h<=0 then return end
		local compact=game:GetService("UserInputService").TouchEnabled or h<550
		local bh=compact and 350 or 470
		if mode=="Quest" then bh=compact and 350 or 470 end
		for i,r in ipairs(rows) do
			local rh=compact and 66 or 100
			r.Card.Size=UDim2.fromOffset(624,rh); r.Card.Position=UDim2.fromOffset(0,(i-1)*(rh+6))
			r.Icon.Size=UDim2.fromOffset(compact and 42 or 56,compact and 42 or 56); r.Icon.Position=UDim2.fromOffset(12,compact and 12 or 22)
			r.Name.Position=UDim2.fromOffset(82,compact and 2 or 8); r.Name.Size=UDim2.fromOffset(350,compact and 22 or 28)
			r.Info.Position=UDim2.fromOffset(82,compact and 24 or 38); r.Info.Size=UDim2.fromOffset(350,20)
			r.Bar.Position=UDim2.fromOffset(82,compact and 48 or 72); r.Bar.Size=UDim2.fromOffset(350,compact and 10 or 14)
			r.Reward.Position=UDim2.fromOffset(444,compact and 2 or 8); r.Reward.Size=UDim2.fromOffset(168,compact and 22 or 28)
			r.Button.Position=UDim2.fromOffset(444,compact and 26 or 42); r.Button.Size=UDim2.fromOffset(168,compact and 34 or 44)
		end
		quest.Size=UDim2.fromOffset(624,compact and 210 or 324)
		p.Size=UDim2.fromOffset(660,bh)
		scale.Scale=math.min(1,w*.96/660,h*.96/bh)
		daily.Size=UDim2.fromOffset(624,bh-136)
		daily.CanvasSize=UDim2.fromOffset(0,compact and 210 or 330)
		daily.ScrollingDirection=Enum.ScrollingDirection.Y
		daily.ScrollBarThickness=compact and 6 or 5
		status.Position=UDim2.fromOffset(18,bh-36)
		for i,c in ipairs(cards) do
			local card=c.Card
			local heading=card:FindFirstChild("Day")
			local icon=card:FindFirstChildOfClass("ImageLabel")
			local cashIcon=card:FindFirstChild("CashIcon")
			if compact then
				card.Position=UDim2.fromOffset(i==7 and 0 or ((i-1)%3)*210,i==7 and 140 or math.floor((i-1)/3)*70)
				card.Size=UDim2.fromOffset(i==7 and 618 or 202,66)
				heading.Position=UDim2.fromOffset(i==7 and 66 or 6,2)
				heading.Size=UDim2.fromOffset(i==7 and 340 or 190,18)
				c.Reward.Position=UDim2.fromOffset(i==7 and 66 or 38,20)
				c.Reward.Size=UDim2.fromOffset(i==7 and 340 or 158,23)
				c.Reward.TextSize=i==7 and 20 or 22
				c.Button.Position=UDim2.fromOffset(i==7 and 430 or 6,i==7 and 14 or 43)
				c.Button.Size=UDim2.fromOffset(i==7 and 180 or 190,i==7 and 38 or 20)
				if cashIcon then cashIcon.Position=UDim2.fromOffset(5,18); cashIcon.Size=UDim2.fromOffset(30,25); cashIcon.TextSize=25 end
				if i==7 and icon then icon.Position=UDim2.fromOffset(6,5); icon.Size=UDim2.fromOffset(55,55) end
			else
				card.Position=UDim2.fromOffset(i==7 and 0 or ((i-1)%3)*210,i==7 and 216 or math.floor((i-1)/3)*108)
				card.Size=UDim2.fromOffset(i==7 and 624 or 204,i==7 and 108 or 100)
				heading.Position=UDim2.fromOffset(i==7 and 116 or 8,i==7 and 10 or 3)
				heading.Size=UDim2.fromOffset(i==7 and 300 or 188,i==7 and 25 or 22)
				c.Reward.Position=UDim2.fromOffset(i==7 and 116 or 58,i==7 and 39 or 25)
				c.Reward.Size=UDim2.fromOffset(i==7 and 300 or 138,i==7 and 48 or 38)
				c.Reward.TextSize=i==7 and 23 or 25
				c.Button.Position=UDim2.fromOffset(i==7 and 430 or 8,i==7 and 34 or 66)
				c.Button.Size=UDim2.fromOffset(i==7 and 182 or 188,i==7 and 42 or 27)
				if cashIcon then cashIcon.Position=UDim2.fromOffset(8,22); cashIcon.Size=UDim2.fromOffset(48,42); cashIcon.TextSize=34 end
				if i==7 and icon then icon.Position=UDim2.fromOffset(12,7); icon.Size=UDim2.fromOffset(94,94) end
			end
		end
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitRewards)
	fitRewards()
	local function open(which)
		local same=p.Visible and mode==which; mode=which; p.Visible=not same; fitRewards()
		inventory.Visible=false; settings.Visible=false; indexPanel.Visible=false; panel.Visible=false
		daily.Visible=which=="Daily"; quest.Visible=which=="Quest"; title.Text=which=="Daily" and "RECOMPENSAS DIÁRIAS" or "MISSÕES DIÁRIAS"; render()
	end
	dailyButton.Activated:Connect(function() open("Daily") end); questsButton.Activated:Connect(function() open("Quest") end)
	exit.Activated:Connect(function() p.Visible=false end)
	for _,b in ipairs({inventoryButton,settingsButton,indexButton,rebirthButton}) do b.Activated:Connect(function() p.Visible=false end) end
	task.spawn(function()
		while gui.Parent do
			if p.Visible and not busy then
				busy=true; local ok,data=request("State"); if ok and type(data)=="table" then state=data elseif not state then status.Text=type(data)=="string" and data or "Aguardando dados..."; messageUntil=os.clock()+3 end; busy=false; render()
			end
			task.wait(1)
		end
	end)
end

-- V29: acabamento e integração com a loja
do
	local shopButton=Instance.new("TextButton"); shopButton.Name="Shop"; shopButton.Parent=buttons
	styleGameButton(shopButton,"Loja","$",Color3.fromRGB(48,190,100),Color3.fromRGB(15,85,45),98,98)

	shopButton.Activated:Connect(function()
		for _,p in ipairs({inventory,settings,indexPanel,panel,gui:FindFirstChild("DailyQuestsPanel")}) do p.Visible=false end
		local shopGui=playerGui:WaitForChild("GamepassShopV30_4",5)
		local overlay=shopGui and shopGui:WaitForChild("ShopOverlay",5)
		if overlay then overlay.Visible=not overlay.Visible else warn("[GameHUD] GamepassShop V30.4 nao encontrado") end
	end)
	hud.BackgroundTransparency=1
	for _,c in ipairs(hud:GetChildren()) do if c:IsA("UIStroke") then c:Destroy() end end
	cashLabel.Position=UDim2.fromOffset(10,2)
	cashLabel.TextColor3=Color3.fromRGB(118,255,79)
	local boost=makeText("Boost","",UDim2.new(1,-20,0,19),UDim2.new(0,10,1,-23),Color3.fromRGB(255,215,100),hud)
	boost.TextXAlignment=Enum.TextXAlignment.Left; boost.Font=FONT; textOutline(boost,1.5)
	local function refreshBoost()
		boost.Text="Multiplicador: "..string.format("%.2f",(player:GetAttribute("IncomeMultiplier") or 1)*(player:GetAttribute("GamepassIncomeMultiplier") or 1)):gsub("0+$",""):gsub("%.$","").."x"
	end
	player:GetAttributeChangedSignal("IncomeMultiplier"):Connect(refreshBoost)
	player:GetAttributeChangedSignal("GamepassIncomeMultiplier"):Connect(refreshBoost); refreshBoost()
	for _,p in ipairs({inventory,settings,indexPanel,panel,gui:FindFirstChild("DailyQuestsPanel")}) do
		p.BackgroundColor3=Color3.fromRGB(28,40,58)
		for _,c in ipairs(p:GetChildren()) do if c:IsA("UIGradient") then c:Destroy() end end
		p:GetPropertyChangedSignal("Visible"):Connect(function()
			if p.Visible then local e=playerGui:FindFirstChild("CloseGamepassShop"); if e then e:Fire() end end
		end)
	end
end
print("[GameHUD V29.2] Icones personalizados carregados!")

-- V30.2: contador compacto, sem painel escuro
do
	local boost=hud:WaitForChild("Boost")
	local function layoutMoney()
		local small=game:GetService("UserInputService").TouchEnabled or gui.AbsoluteSize.X<700 or gui.AbsoluteSize.Y<550
		cashLabel.Position=UDim2.fromOffset(3,0)
		cashLabel.Size=UDim2.new(1,-6,0,small and 34 or 44)
		cashLabel.TextSize=small and 27 or 40
		incomeLabel.Position=UDim2.fromOffset(3,small and 36 or 48)
		incomeLabel.Size=UDim2.new(1,-6,0,small and 20 or 24)
		incomeLabel.TextSize=small and 15 or 20
		boost.Position=UDim2.fromOffset(3,small and 60 or 78)
		boost.Size=UDim2.new(1,-6,0,small and 18 or 22)
		boost.TextScaled=false; boost.TextSize=small and 14 or 17
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutMoney)
	layoutMoney()
end
print("[GameHUD V30.2] Contador compacto carregado!")


print("[GameHUD V30.4] Loja integrada!")

-- V31.1: identidade visual dos menus, sem alterar a logica.
do
	local palette=Color3.fromRGB(17,27,44)
	local cardColor=Color3.fromRGB(33,47,68)
	local borderColor=Color3.fromRGB(65,83,108)
	local menus={inventory,panel,indexPanel,settings,gui:FindFirstChild("DailyQuestsPanel")}
	local function modernize(o)
		if o:IsA("TextLabel") or o:IsA("TextButton") then
			o.Font=Enum.Font.GothamBold
			o.TextStrokeTransparency=1
			local outline=o:FindFirstChild("TextOutline")
			if outline then outline:Destroy() end
			if o:IsA("TextButton") then
				o.AutoButtonColor=true
				local c=o:FindFirstChildOfClass("UICorner")
				if c then c.CornerRadius=UDim.new(0,9) end
			end
		elseif o:IsA("Frame") then
			if o.Name=="SwordItem" or o.Name:match("^Sword_%d+$") or o.Name:match("^Day%d+$") or o.Name:match("^Quest%d+$") then
				o.BackgroundColor3=cardColor
				local c=o:FindFirstChildOfClass("UICorner")
				if c then c.CornerRadius=UDim.new(0,12) end
			end
		end
	end
	for _,p in ipairs(menus) do
		p.BackgroundColor3=palette
		local c=p:FindFirstChildOfClass("UICorner")
		if c then c.CornerRadius=UDim.new(0,18) end
		for _,d in ipairs(p:GetChildren()) do
			if d:IsA("UIStroke") then d.Color=borderColor; d.Thickness=1.5 end
			if d.Name=="HeaderAccent" then d:Destroy() end
		end
		for _,d in ipairs(p:GetDescendants()) do modernize(d) end
		p.DescendantAdded:Connect(function(d) task.defer(function() if d.Parent then modernize(d) end end) end)
	end
	-- Mantem a grade, requisitos, botoes e remotes existentes.
	local lighting=game:GetService("Lighting")
	local blur=Instance.new("BlurEffect")
	blur.Name="HUDMenuBlurV31"; blur.Size=0; blur.Parent=lighting
	local activeTween
	local function refreshBlur()
		local visible=false
		for _,p in ipairs(menus) do if p.Visible then visible=true; break end end
		if activeTween then activeTween:Cancel() end
		activeTween=TweenService:Create(blur,TweenInfo.new(.18),{Size=visible and 9 or 0})
		activeTween:Play()
	end
	for _,p in ipairs(menus) do p:GetPropertyChangedSignal("Visible"):Connect(refreshBlur) end
	gui.Destroying:Connect(function() blur:Destroy() end)
end
print("[GameHUD V31.1] Menus modernizados!")

-- V31.3: Rebirth, layout cartoon responsivo
do
	local C=Color3.fromRGB
	local function place(o,parent,x,y,w,h)
		o.Parent=parent; o.Position=UDim2.fromOffset(x,y); o.Size=UDim2.fromOffset(w,h)
	end
	local function frame(name,parent,x,y,w,h,color,z)
		local f=makeFrame(name,UDim2.fromOffset(w,h),UDim2.fromOffset(x,y),color,parent)
		f.ZIndex=z or 11; corner(f,10); return f
	end
	local function label(parent,name,content,x,y,w,h,size,color)
		local l=makeText(name,content,UDim2.fromOffset(w,h),UDim2.fromOffset(x,y),color,parent)
		l.ZIndex=14; l.TextScaled=false; l.TextSize=size; l.Font=Enum.Font.GothamBold; l.TextWrapped=true; return l
	end
	local function style(l,parent,x,y,w,h,size,color)
		place(l,parent,x,y,w,h); l.ZIndex=14; l.TextScaled=false; l.TextSize=size; l.TextColor3=color; l.Font=Enum.Font.GothamBold; l.TextWrapped=true; l.TextStrokeTransparency=1
	end
	local white=C(255,255,255); local muted=C(190,207,228); local gold=C(255,211,87)
	panel.BackgroundColor3=C(24,36,53); panel.ClipsDescendants=true
	for _,v in ipairs(panel:GetChildren()) do if v:IsA("UIGradient") then v:Destroy() end end
	local header=frame("RebirthHeader",panel,0,0,660,58,C(49,79,111),11)
	style(heading,header,18,5,560,48,29,white); heading.TextXAlignment=Enum.TextXAlignment.Left
	place(close,header,610,10,38,38); close.ZIndex=15; close.BackgroundColor3=C(199,62,71); close.TextScaled=false; close.TextSize=23
	style(warning,panel,20,65,620,34,13,C(255,190,100))
	label(panel,"RewardsTitle","VOCÊ VAI DESBLOQUEAR",20,102,620,26,19,gold)
	local a=frame("IncomeReward",panel,20,135,200,104,C(42,65,86),11)
	local b=frame("BaseReward",panel,230,135,200,104,C(42,65,86),11)
	local c=frame("ProtectionReward",panel,440,135,200,104,C(42,65,86),11)
	for _,f in ipairs({a,b,c}) do stroke(f,C(76,108,139),2) end
	label(a,"Icon","$",0,4,200,33,29,C(105,240,145))
	label(a,"Caption","MULTIPLICADOR",0,39,200,20,13,muted)
	style(bonus,a,5,61,190,37,23,C(105,240,145))
	label(b,"Icon","▦",0,4,200,33,29,C(116,195,255))
	label(b,"Caption","EXPANSÃO DA BASE",0,39,200,20,13,muted)
	style(upgrade,b,5,61,190,37,15,white)
	label(c,"Icon","⏱",0,4,200,33,27,gold)
	label(c,"Caption","PROTEÇÃO",0,39,200,20,13,muted)
	style(protection,c,5,61,190,37,15,gold)
	label(panel,"RequirementsTitle","REQUISITOS",20,246,620,26,19,gold)
	local req=frame("RequirementsArea",panel,20,278,620,126,C(16,26,42),11)
	place(bar,req,12,10,596,30); bar.ZIndex=12; bar.BackgroundColor3=C(48,61,79); fill.ZIndex=13; fill.BackgroundColor3=C(49,190,103)
	style(money,req,12,10,596,30,17,white); money.ZIndex=14
	local holder=frame("RequiredSwordCards",req,12,48,596,68,C(16,26,42),12)
	for i=1,2 do
		local f=frame("SwordCard"..i,holder,0,0,290,68,C(35,50,70),13)
		local name=label(f,"SwordName","",82,8,200,25,15,white)
		name.Size=UDim2.new(1,-88,0,25); name.TextXAlignment=Enum.TextXAlignment.Left
		local status=label(f,"Status","",82,35,200,22,13,muted)
		status.Size=UDim2.new(1,-88,0,22); status.TextXAlignment=Enum.TextXAlignment.Left
		requiredCards[i]={Frame=f,NameLabel=name,Status=status}; f.Visible=false
	end
	place(action,panel,150,416,360,42); action.ZIndex=14; action.TextScaled=false; action.TextSize=19; action.Font=Enum.Font.GothamBold
	resizeMenus()
end
print("[GameHUD V31.3] Rebirth redesenhado!")

-- V31.4: indice, identidade visual do Rebirth
do
	local C=Color3.fromRGB
	indexPanel.BackgroundColor3=C(24,36,53); indexPanel.ClipsDescendants=true
	for _,v in ipairs(indexPanel:GetChildren()) do if v:IsA("UIGradient") then v:Destroy() end end
	local header=makeFrame("IndexHeader",UDim2.fromOffset(650,58),UDim2.new(),C(49,79,111),indexPanel)
	header.ZIndex=10; corner(header,12)
	indexTitle.Parent=header; indexTitle.Position=UDim2.fromOffset(18,5); indexTitle.Size=UDim2.fromOffset(570,48); indexTitle.ZIndex=11; indexTitle.TextScaled=false; indexTitle.TextSize=25; indexTitle.TextXAlignment=Enum.TextXAlignment.Left
	closeIndex.Parent=header; closeIndex.Position=UDim2.fromOffset(600,10); closeIndex.Size=UDim2.fromOffset(38,38); closeIndex.ZIndex=12; closeIndex.BackgroundColor3=C(199,62,71); closeIndex.TextScaled=false; closeIndex.TextSize=21
	indexProgress.Position=UDim2.fromOffset(18,66); indexProgress.Size=UDim2.fromOffset(614,22); indexProgress.TextScaled=false; indexProgress.TextSize=15; indexProgress.TextXAlignment=Enum.TextXAlignment.Left; indexProgress.TextColor3=C(190,207,228)
	indexBar.Position=UDim2.fromOffset(18,94); indexBar.Size=UDim2.fromOffset(614,9); indexFill.BackgroundColor3=C(80,225,140)
	for i,n in ipairs({"Normal","Golden","Diamond","Rainbow","Corrupted"}) do
		local t=tabs[n]; t.Position=UDim2.fromOffset(18+(i-1)*124,114); t.Size=UDim2.fromOffset(118,32); t.TextScaled=false; t.TextSize=13
	end
	indexScroll.Position=UDim2.fromOffset(18,158); indexScroll.Size=UDim2.fromOffset(614,338); indexScroll.ScrollBarThickness=4; indexScroll.ScrollBarImageColor3=C(116,195,255)
	indexGrid.CellPadding=UDim2.fromOffset(8,8); indexGrid.CellSize=UDim2.new(.25,-8,0,164)
	reward.Position=UDim2.fromOffset(18,508); reward.Size=UDim2.fromOffset(614,40); reward.TextScaled=false; reward.TextSize=15
	resizeMenus()
end
print("[GameHUD V31.6] Indice ordenado!")

-- V31.7: inventario de espadas
do
	local C=Color3.fromRGB
	inventory.BackgroundColor3=C(24,36,53); inventory.ClipsDescendants=true
	for _,v in ipairs(inventory:GetChildren()) do if v:IsA("UIGradient") then v:Destroy() end end
	local title=inventory:FindFirstChild("Title")
	local header=makeFrame("InventoryHeader",UDim2.fromOffset(650,58),UDim2.new(),C(49,79,111),inventory)
	corner(header,12); header.ZIndex=10
	title.Parent=header; title.Position=UDim2.fromOffset(18,5); title.Size=UDim2.fromOffset(560,48); title.TextScaled=false; title.TextSize=25; title.TextXAlignment=Enum.TextXAlignment.Left; title.ZIndex=11
	closeInventory.Parent=header; closeInventory.Position=UDim2.fromOffset(600,10); closeInventory.Size=UDim2.fromOffset(38,38); closeInventory.BackgroundColor3=C(199,62,71); closeInventory.TextScaled=false; closeInventory.TextSize=21; closeInventory.ZIndex=12
	totalLabel.Position=UDim2.fromOffset(18,68); totalLabel.Size=UDim2.fromOffset(614,30); totalLabel.TextScaled=false; totalLabel.TextSize=16; totalLabel.TextXAlignment=Enum.TextXAlignment.Left
	scroll.Position=UDim2.fromOffset(18,108); scroll.Size=UDim2.fromOffset(614,394); scroll.ScrollBarThickness=4; scroll.ScrollBarImageColor3=C(116,195,255); scroll.ClipsDescendants=true
	local empty=makeText("EmptyInventory","Sua coleção está vazia!\nCompre uma espada na arena para começar.",UDim2.fromOffset(614,100),UDim2.fromOffset(18,200),C(190,207,228),inventory)
	empty.TextScaled=false; empty.TextSize=19; empty.TextWrapped=true; empty.Visible=false
	inventorySignature=nil; refreshInventory(); resizeMenus()
end
print("[GameHUD V31.7] Inventario redesenhado!")


-- V31.8: dicas temporarias, sem sobrepor os menus
do
	local lastText = objective.Text
	local expiresAt = os.clock() + 8
	local outline = objective:FindFirstChild("TextOutline")
	local function menuOpen()
		for _, menu in ipairs({inventory, settings, indexPanel, panel}) do
			if menu.Visible then return true end
		end
		local daily = gui:FindFirstChild("DailyQuestsPanel")
		if daily and daily.Visible then return true end
		local shop = playerGui:FindFirstChild("GamepassShopV30_4")
		local overlay = shop and shop:FindFirstChild("ShopOverlay")
		return shop and shop.Enabled and overlay and overlay.Visible or false
	end
	local connection
	connection = game:GetService("RunService").RenderStepped:Connect(function()
		if objective.Text ~= lastText then
			lastText = objective.Text
			expiresAt = os.clock() + 8
		end
		local remaining = expiresAt - os.clock()
		local show = remaining > 0 and not menuOpen()
		objective.Visible = show
		if show then
			local alpha = math.clamp(1 - remaining / .5, 0, 1)
			objective.TextTransparency = alpha
			if outline then outline.Transparency = alpha end
		end
	end)
	gui.Destroying:Connect(function() connection:Disconnect() end)
end
print("[GameHUD V31.8] Dicas temporarias ativadas!")


-- V31.10: Opcoes redesenhadas, mantendo a configuracao original.
do
	local C=Color3.fromRGB
	settings.BackgroundColor3=C(24,36,53)
	settings.ClipsDescendants=true
	local header=makeFrame("SettingsHeader",UDim2.fromOffset(520,58),UDim2.new(),C(49,79,111),settings)
	corner(header,12)
	local title=settings:FindFirstChild("Title")
	title.Parent=header; title.Position=UDim2.fromOffset(18,5); title.Size=UDim2.fromOffset(440,48)
	title.Text="OPÇÕES"; title.TextScaled=false; title.TextSize=25; title.TextXAlignment=Enum.TextXAlignment.Left
	closeSettings.Parent=header; closeSettings.Position=UDim2.fromOffset(470,10); closeSettings.Size=UDim2.fromOffset(38,38)
	closeSettings.Text="X"; closeSettings.TextScaled=false; closeSettings.TextSize=21; closeSettings.BackgroundColor3=C(199,62,71)
	local function label(parent,name,content,x,y,w,h,size,color)
		local l=makeText(name,content,UDim2.fromOffset(w,h),UDim2.fromOffset(x,y),color,parent)
		l.TextScaled=false; l.TextSize=size; l.TextXAlignment=Enum.TextXAlignment.Left; l.TextWrapped=true; return l
	end
	label(settings,"Section","EXPERIÊNCIA DE JOGO",18,73,484,25,13,C(158,181,208))
	local card=makeFrame("AnimationCard",UDim2.fromOffset(484,100),UDim2.fromOffset(18,108),C(33,47,68),settings)
	corner(card,12); stroke(card,C(65,83,108),1)
	local icon=makeFrame("Icon",UDim2.fromOffset(46,46),UDim2.fromOffset(14,27),C(49,79,111),card); corner(icon,10)
	local glyph=Instance.new("ImageLabel"); glyph.Name="Glyph"; glyph.BackgroundTransparency=1; glyph.Size=UDim2.fromOffset(30,30); glyph.Position=UDim2.fromOffset(8,8); glyph.Image="rbxassetid://79503839182084"; glyph.ScaleType=Enum.ScaleType.Fit; glyph.Parent=icon
	label(card,"Name","Animações da HUD",72,16,285,25,18,C(255,255,255))
	label(card,"Description","Efeitos dos menus e ganhos de dinheiro.",72,43,275,42,13,C(166,185,208))
	animationButton.Parent=card; animationButton.Position=UDim2.fromOffset(388,24); animationButton.Size=UDim2.fromOffset(80,34)
	animationButton.Text=""; animationButton.AutoButtonColor=false; animationButton.TextScaled=false
	for _,v in ipairs(animationButton:GetChildren()) do if v:IsA("UIStroke") or v:IsA("UIPadding") then v:Destroy() end end
	animationButton.ClipsDescendants=true
	local c=animationButton:FindFirstChildOfClass("UICorner"); if c then c.CornerRadius=UDim.new(1,0) end
	local knob=makeFrame("Knob",UDim2.fromOffset(26,26),UDim2.fromOffset(50,4),C(255,255,255),animationButton); corner(knob,13)
	local state=label(card,"State","",388,61,80,22,12,C(166,185,208)); state.TextXAlignment=Enum.TextXAlignment.Center
	local function refresh()
		animationButton.BackgroundColor3=animationsEnabled and C(44,167,102) or C(75,88,110)
		knob.Position=UDim2.fromOffset(animationsEnabled and 50 or 4,4)
		state.Text=animationsEnabled and "Ativado" or "Desativado"
	end
	animationButton.Activated:Connect(function() task.defer(refresh) end)
	refresh()
	label(settings,"Info","As configurações valem para esta sessão de jogo.",18,225,484,48,13,C(158,181,208))
	resizeMenus()
end
print("[GameHUD V31.13] HUD lateral e recompensas alinhadas!")

print("[GameHUD V32] Mobile e Daily responsivos!")

-- V32.1: evita sobreposicoes de HUD e mochila em menus mobile.
do
	local starter=game:GetService("StarterGui")
	local menus={inventory,settings,indexPanel,panel,gui:FindFirstChild("DailyQuestsPanel")}
	local previousBackpack=nil
	local function sync()
		local mobile=game:GetService("UserInputService").TouchEnabled or gui.AbsoluteSize.Y<550
		local opened=false
		for _,m in ipairs(menus) do if m.Visible then opened=true; break end end
		local hide=mobile and opened
		buttons.Visible=not hide; hud.Visible=not hide
		if hide and previousBackpack==nil then
			local ok,value=pcall(function() return starter:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack) end)
			if ok then previousBackpack=value; pcall(function() starter:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false) end) end
		elseif not hide and previousBackpack~=nil then
			local value=previousBackpack; previousBackpack=nil
			pcall(function() starter:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,value) end)
		end
	end
	for _,m in ipairs(menus) do m:GetPropertyChangedSignal("Visible"):Connect(sync) end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(sync)
	gui.Destroying:Connect(function() if previousBackpack~=nil then pcall(function() starter:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,previousBackpack) end) end end)
	sync()
end
print("[GameHUD V32.1] Mobile fix aplicado!")

-- V40: abas do inventario
do
	local rf=game:GetService("ReplicatedStorage"):WaitForChild("SwordInventoryV40")
	local baseTab=makeButton("BaseTab","Base",UDim2.fromOffset(140,30),UDim2.fromOffset(18,70),Color3.fromRGB(65,100,155),inventory)
	local bagTab=makeButton("BagTab","Inventário",UDim2.fromOffset(140,30),UDim2.fromOffset(166,70),Color3.fromRGB(65,100,155),inventory)
	local bag=Instance.new("ScrollingFrame"); bag.Name="StoredInventory"; bag.Position=UDim2.fromOffset(18,108); bag.Size=UDim2.fromOffset(614,394); bag.BackgroundTransparency=1; bag.ScrollBarThickness=5; bag.AutomaticCanvasSize=Enum.AutomaticSize.Y; bag.CanvasSize=UDim2.new(); bag.Visible=false; bag.Parent=inventory
	local list=Instance.new("UIListLayout"); list.Padding=UDim.new(0,8); list.Parent=bag
	local status=makeText("BagStatus","",UDim2.fromOffset(290,30),UDim2.fromOffset(320,70),Color3.new(1,1,1),inventory); status.TextScaled=false; status.TextSize=13
	local C=Color3.fromRGB
	inventory.BackgroundColor3=C(20,27,40)
	local header=inventory:FindFirstChild("InventoryHeader")
	if header then header.BackgroundColor3=C(37,51,75) end
	local track=makeFrame("CapacityTrack",UDim2.fromOffset(290,5),UDim2.fromOffset(320,100),C(48,60,80),inventory); corner(track,3)
	local fill=makeFrame("Fill",UDim2.fromScale(0,1),UDim2.new(),C(125,166,245),track); corner(fill,3)
	track.Visible=false
	totalLabel.Position=UDim2.fromOffset(18,490); totalLabel.Size=UDim2.fromOffset(614,24)
	scroll.Size=UDim2.fromOffset(614,378)
	local function styleTabs(isBag)
		baseTab.BackgroundColor3=isBag and C(42,53,72) or C(75,106,160)
		bagTab.BackgroundColor3=isBag and C(75,106,160) or C(42,53,72)
		track.Visible=isBag
		local empty=inventory:FindFirstChild("EmptyInventory"); if empty and isBag then empty.Visible=false end
	end
	styleTabs(false)
	local function refreshBag()
		local ok,success,items=pcall(function() return rf:InvokeServer("List") end)
		if not ok or not success then status.Text="Aguarde seus dados"; return end
		for _,v in ipairs(bag:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
		table.sort(items,function(a,b) if a.Favorite~=b.Favorite then return a.Favorite end return tostring(a.Name)<tostring(b.Name) end)
		status.Text=#items.." / 5 guardadas"..(#items>5 and " (excedentes)" or "")
		fill.Size=UDim2.fromScale(math.min(#items/5,1),1)
		for _,item in ipairs(items) do
			local card=makeFrame("Item",UDim2.new(1,-10,0,112),UDim2.new(),Color3.fromRGB(31,43,62),bag); corner(card,12); stroke(card, COLORS[item.Rarity] or C(80,95,120),1)
			local title=makeText("Name",tostring(item.Name).." | "..tostring(item.Mutation or "Normal"),UDim2.new(1,-100,0,28),UDim2.fromOffset(88,6),COLORS[item.Rarity] or Color3.new(1,1,1),card); title.TextScaled=false; title.TextSize=16; title.TextXAlignment=Enum.TextXAlignment.Left
			local catalog=game:GetService("ReplicatedStorage"):FindFirstChild("SwordIndexCatalog")
			local template=catalog and catalog:FindFirstChild(item.Id or item.Name)
			if template and template:IsA("Model") then
				local view=Instance.new("ViewportFrame"); view.Size=UDim2.fromOffset(72,92); view.Position=UDim2.fromOffset(8,10); view.BackgroundColor3=C(20,29,44); view.Parent=card; corner(view,8)
				local model=template:Clone(); for _,d in ipairs(model:GetDescendants()) do if d:IsA("BasePart") then d.Anchored=true elseif d:IsA("LuaSourceContainer") or d:IsA("BillboardGui") or d:IsA("ProximityPrompt") or d:IsA("ParticleEmitter") then d:Destroy() end end
				model.Parent=view; local cf,sz=model:GetBoundingBox(); local cam=Instance.new("Camera"); local dist=math.max(sz.X,sz.Y,sz.Z)*1.8; cam.CFrame=CFrame.lookAt(cf.Position+Vector3.new(dist*.2,0,dist),cf.Position); cam.Parent=view; view.CurrentCamera=cam
			end
			local info=makeText("Info",tostring(item.Rarity).."  •  Guardada",UDim2.new(1,-100,0,20),UDim2.fromOffset(88,35),C(174,190,213),card); info.TextScaled=false; info.TextSize=13; info.TextXAlignment=Enum.TextXAlignment.Left
			for i,entry in ipairs({{"Equip","Colocar na base"},{"Sell","Vender $"..formatMoney(math.floor(item.Price/2))},{"Favorite",item.Favorite and "Desfavoritar" or "Favoritar"}}) do
				local btn=makeButton(entry[1],entry[2],UDim2.fromOffset(164,34),UDim2.fromOffset(88+(i-1)*170,68),entry[1]=="Equip" and C(42,113,86) or entry[1]=="Sell" and C(132,55,67) or C(65,85,120),card); btn.TextScaled=false; btn.TextSize=13
				local confirm=false
				btn.Activated:Connect(function()
					if entry[1]=="Sell" and not confirm then confirm=true; btn.Text="Confirmar?"; return end
					local ok,a,b=pcall(function() return rf:InvokeServer(entry[1],item.Uid) end)
					if ok and a then inventorySignature=nil; refreshInventory(); refreshBag() else status.Text=tostring(b or "Falhou") end
				end)
			end
		end
	end
	baseTab.Activated:Connect(function() bag.Visible=false; scroll.Visible=true; totalLabel.Visible=true; styleTabs(false); status.Text=""; inventorySignature=nil; refreshInventory() end)
	bagTab.Activated:Connect(function() bag.Visible=true; scroll.Visible=false; totalLabel.Visible=false; styleTabs(true); refreshBag() end)
	inventory:GetPropertyChangedSignal("Visible"):Connect(function() if inventory.Visible and bag.Visible then refreshBag() end end)
	layout.CellSize=UDim2.fromOffset(196,248)
end
