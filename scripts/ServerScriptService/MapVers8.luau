
-- MAP GENERATOR V27.3
-- ROUBE UMA ESPADA
-- Tema: Sword Factory
-- Local: ServerScriptService

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local CONFIG = {
	MapWidth = 340,
	MapLength = 440,

	BaseWidth = 76,
	BaseDepth = 64,
	BaseDistance = 103,
	BaseSpacing = 94,

	BeltWidth = 26,
	BeltLength = 390,

	StandWidth = 13,
	StandDepth = 6,
	StandX = 27,
	StandFirstZ = -20,
	StandSpacing = 10,
}

-- PALETA DE CORES

local C = {
	Grass = Color3.fromRGB(75, 190, 48),
	Floor = Color3.fromRGB(215, 222, 232),
	Center = Color3.fromRGB(183, 194, 209),

	Wall = Color3.fromRGB(67, 82, 105),
	Trim = Color3.fromRGB(235, 240, 248),
	Dark = Color3.fromRGB(38, 48, 65),

	Metal = Color3.fromRGB(100, 115, 135),
	Glass = Color3.fromRGB(140, 210, 245),

	Gold = Color3.fromRGB(255, 198, 45),
	Red = Color3.fromRGB(230, 48, 55),
	Belt = Color3.fromRGB(215, 53, 60),

	Path = Color3.fromRGB(177, 185, 198),
	Blue = Color3.fromRGB(55, 155, 245),
}

-- LIMPAR MAPA ANTERIOR

local old = Workspace:FindFirstChild("SwordGameMap")

if old then
	old:Destroy()
end

local baseplate = Workspace:FindFirstChild("Baseplate")

if baseplate then
	baseplate:Destroy()
end

-- Remove somente o spawn padrao solto no Workspace.
local defaultSpawn = Workspace:FindFirstChild("SpawnLocation")
if defaultSpawn and defaultSpawn:IsA("SpawnLocation") then
	defaultSpawn:Destroy()
end

local map = Instance.new("Folder")
map.Name = "SwordGameMap"
map.Parent = Workspace

-- FUNCOES DE CONSTRUCAO

local function part(
	name, size, cf, color, material, parent
)
	local p = Instance.new("Part")

	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true

	p.Color = color
	p.Material = material
		or Enum.Material.SmoothPlastic

	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth

	p.Parent = parent

	return p
end

local function decoration(
	name, size, cf, color, material, parent
)
	local p = part(
		name, size, cf, color, material, parent
	)

	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false

	return p
end

local function studs(p)
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Studs
end

-- ILUMINACAO

Lighting.ClockTime = 13
Lighting.Brightness = 1.8
Lighting.ExposureCompensation = -0.1

Lighting.Ambient = Color3.fromRGB(150, 150, 160)
Lighting.OutdoorAmbient =
	Color3.fromRGB(165, 175, 190)

Lighting.GlobalShadows = true
Lighting.ShadowSoftness = 0.35

local atmosphere =
	Lighting:FindFirstChildOfClass("Atmosphere")

if not atmosphere then
	atmosphere = Instance.new("Atmosphere")
	atmosphere.Parent = Lighting
end

atmosphere.Density = 0.12
atmosphere.Haze = 0.15
atmosphere.Glare = 0
atmosphere.Color = Color3.fromRGB(200, 230, 255)

local oldCorrection =
	Lighting:FindFirstChild("SwordColorV7")

if oldCorrection then
	oldCorrection:Destroy()
end

local bloom = Lighting:FindFirstChild("SwordBloom")

if not bloom then
	bloom = Instance.new("BloomEffect")
	bloom.Name = "SwordBloom"
	bloom.Parent = Lighting
end

bloom.Intensity = 0.08
bloom.Size = 10
bloom.Threshold = 2.5

local clouds =
	Workspace.Terrain:FindFirstChild("SwordClouds")

if not clouds then
	clouds = Instance.new("Clouds")
	clouds.Name = "SwordClouds"
	clouds.Parent = Workspace.Terrain
end

clouds.Cover = 0.35
clouds.Density = 0.55
clouds.Color = Color3.new(1, 1, 1)

-- TERRENO PRINCIPAL

local ground = part(
	"Ground",
	Vector3.new(
		CONFIG.MapWidth,
		2,
		CONFIG.MapLength
	),
	CFrame.new(0, -1, 0),
	C.Grass,
	Enum.Material.SmoothPlastic,
	map
)

studs(ground)

-- PASTAS

local arenaFolder = Instance.new("Folder")
arenaFolder.Name = "Arena"
arenaFolder.Parent = map

local basesFolder = Instance.new("Folder")
basesFolder.Name = "Bases"
basesFolder.Parent = map

local decor = Instance.new("Folder")
decor.Name = "Decorations"
decor.Parent = map

-- ESTEIRA CENTRAL
-- ArenaFloor mantido por compatibilidade.

local arenaFloor = part(
	"ArenaFloor",
	Vector3.new(
		44,
		0.5,
		CONFIG.BeltLength
	),
	CFrame.new(0, 0.25, 0),
	C.Dark,
	Enum.Material.SmoothPlastic,
	arenaFolder
)

-- Superficie vermelha da esteira.

local belt = part(
	"ConveyorBelt",
	Vector3.new(
		CONFIG.BeltWidth,
		0.2,
		CONFIG.BeltLength
	),
	CFrame.new(0, 0.6, 0),
	C.Belt,
	Enum.Material.SmoothPlastic,
	arenaFolder
)

belt.TopSurface = Enum.SurfaceType.Smooth

-- Passarelas laterais e bordas.

for _, side in ipairs({-1, 1}) do

	part(
		"ConveyorSidewalk",
		Vector3.new(
			8,
			0.25,
			CONFIG.BeltLength
		),
		CFrame.new(side * 18, 0.625, 0),
		C.Path,
		Enum.Material.SmoothPlastic,
		arenaFolder
	)

	decoration(
		"ConveyorBorder",
		Vector3.new(
			0.8,
			0.3,
			CONFIG.BeltLength
		),
		CFrame.new(side * 13.4, 0.85, 0),
		C.Trim,
		Enum.Material.SmoothPlastic,
		arenaFolder
	)

	decoration(
		"ConveyorYellowLine",
		Vector3.new(
			0.3,
			0.05,
			CONFIG.BeltLength
		),
		CFrame.new(side * 14.1, 0.78, 0),
		C.Gold,
		Enum.Material.SmoothPlastic,
		arenaFolder
	)
end

-- PONTOS DA ESTEIRA
-- O SwordSystem futuro usara estes pontos.

local function marker(name, position)
	local p = decoration(
		name,
		Vector3.new(1, 1, 1),
		CFrame.new(position),
		C.Blue,
		Enum.Material.SmoothPlastic,
		arenaFolder
	)

	p.Transparency = 1

	return p
end

marker(
	"ConveyorStart",
	Vector3.new(0, 1.2, -178)
)

marker(
	"ConveyorEnd",
	Vector3.new(0, 1.2, 178)
)

-- Compatibilidade com referencias antigas.
-- Invisiveis para nao recriar a arena medieval.

marker(
	"CenterPlatform",
	Vector3.new(0, 0.7, 0)
)

marker(
	"SwordPedestal",
	Vector3.new(0, 1.2, -178)
)

-- FUNCAO DE PLACAS

local function signText(p, text, face, color)
	local gui = Instance.new("SurfaceGui")

	gui.Face = face or Enum.NormalId.Front
	gui.SizingMode =
		Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30

	gui.Parent = p

	local label = Instance.new("TextLabel")

	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1

	label.Text = text
	label.TextColor3 = color
		or Color3.new(1, 1, 1)

	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true

	label.TextStrokeColor3 =
		Color3.fromRGB(20, 25, 35)

	label.TextStrokeTransparency = 0.2

	label.Parent = gui

	return label
end

-- FACTORY EXPANSION V8.4
-- Os pontos ConveyorStart e ConveyorEnd permanecem inalterados.
local function terminal(name, side, accent, title)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = decor
	local frontZ = side * 170
	local function build(n, size, x, y, depth, color, material, decorative)
		local cf = CFrame.new(x, y, frontZ + side * depth)
		local make = decorative and decoration or part
		return make(n, size, cf, color, material, model)
	end
	-- Tunel de 48 studs: da fachada ate o muro externo.
	build("Foundation", Vector3.new(56, 0.4, 48), 0, 0.2, 24, C.Dark)
	-- Completa a esteira existente (que termina em +/-195).
	build("BeltExtension", Vector3.new(26, 0.2, 23), 0, 0.6, 36.5, C.Belt)
	for _, x in ipairs({-23, 23}) do
		build("SideShell", Vector3.new(10, 24, 43), x, 12, 24.5, C.Wall)
		build("SideTrim", Vector3.new(10.4, 0.5, 43), x, 24.25, 24.5, C.Trim)
		build("FrontColumn", Vector3.new(10.5, 24, 3), x, 12, 1.5, C.Dark)
	end
	build("TunnelRoof", Vector3.new(56, 2, 48), 0, 25, 24, C.Dark)
	build("RoofTrim", Vector3.new(57, 0.6, 48), 0, 26.3, 24, C.Trim, nil, true)
	build("RearWall", Vector3.new(56, 24, 2), 0, 12, 47, C.Dark)
	-- A abertura central permanece livre: 36 studs de largura.
	build("FrontHeader", Vector3.new(35.5, 5, 3), 0, 21.5, 1.5, C.Wall)
	for _, x in ipairs({-23,23}) do
		build("FacadeAccent",Vector3.new(1.2,17,.3),x,10,0,accent,nil,true)
	end
	local sign = build("TerminalSign", Vector3.new(34, 4.5, 0.5), 0, 21.5, -0.4, accent, nil, true)
	local face = side == -1 and Enum.NormalId.Back or Enum.NormalId.Front
	signText(sign, title, face)
	-- Luz interna discreta, sem detalhes neon na fachada.
	local lamp = build("InteriorLamp", Vector3.new(8, 0.3, 3), 0, 23.8, 13, C.Trim, nil, true)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(235, 240, 255)
	light.Brightness = 0.7
	light.Range = 25
	light.Shadows = false
	light.Parent = lamp
end

terminal("SwordFactory", -1, C.Blue, "SWORD FACTORY")
terminal("ConveyorExit", 1, C.Red, "RECOLHIMENTO")

-- CRIAR BASES MODERNAS

local function createBase(index, side, row)

	local x = side * CONFIG.BaseDistance

	local z = (
		row - 2.5
	) * CONFIG.BaseSpacing

	local position = Vector3.new(x, 0, z)

	-- Todas as bases olham para a esteira.

	local baseCF = CFrame.lookAt(
		position,
		Vector3.new(0, 0, z)
	)

	local base = Instance.new("Model")
	base.Name = "Base" .. index
	base.Parent = basesFolder

	local function bp(
		name, size, offset, color, material
	)
		return part(
			name,
			size,
			baseCF * CFrame.new(offset),
			color,
			material,
			base
		)
	end

	local function bd(
		name, size, offset, color, material
	)
		return decoration(
			name,
			size,
			baseCF * CFrame.new(offset),
			color,
			material,
			base
		)
	end

	-- PISO

	local floor = bp(
		"Floor",
		Vector3.new(
			CONFIG.BaseWidth,
			1,
			CONFIG.BaseDepth
		),
		Vector3.new(0, 0.5, 0),
		C.Floor
	)

	studs(floor)

	local corridor = bd(
		"CenterWalkway",
		Vector3.new(21, 0.06, 52),
		Vector3.new(0, 1.035, 0),
		C.Center
	)

	-- PAREDE TRASEIRA

	local backWall = bp(
		"BackWall",
		Vector3.new(76, 13, 2),
		Vector3.new(0, 7, 32),
		C.Wall
	)

	backWall.Material = Enum.Material.SmoothPlastic

	-- Faixas brancas.

	bd(
		"BackTopTrim",
		Vector3.new(76, 1, 2.5),
		Vector3.new(0, 13.5, 32),
		C.Trim
	)

	bd(
		"BackBottomTrim",
		Vector3.new(76, 0.8, 2.5),
		Vector3.new(0, 1.5, 32),
		C.Trim
	)

	-- V26.2: laterais sem faces coplanares; vidro continuo e montantes unicos.
	for _, side in ipairs({-1,1}) do
		local x=side*38
		bp("SideWall",Vector3.new(2,3,61),Vector3.new(x,2.5,.5),C.Wall)
		bp("SideWallTop",Vector3.new(2,5.5,61),Vector3.new(x,13.75,.5),C.Wall)
		local pane=bp("Window",Vector3.new(.6,7,61),Vector3.new(x,7.5,.5),C.Glass,Enum.Material.Glass)
		pane.Transparency=.5; pane.Reflectance=0; pane.CanCollide=true
		for _,z in ipairs({-29,-15,0,15,30}) do
			bp("WindowFrame",Vector3.new(2.3,7,1.2),Vector3.new(x,7.5,z),C.Trim)
		end
		bd("WallTopTrim",Vector3.new(2.4,.5,61),Vector3.new(x,13.2,.5),C.Trim)
		bd("WallBottomTrim",Vector3.new(2.4,.5,61),Vector3.new(x,1.3,.5),C.Trim)
		bp("EntranceColumn",Vector3.new(4,12.75,3),Vector3.new(side*36,7.375,-31.5),C.Wall)
	end
	bp("EntranceHeader",Vector3.new(76,2.75,3),Vector3.new(0,15.125,-31.5),C.Wall)
	bd("EntranceHeaderTrim",Vector3.new(76,.4,3.4),Vector3.new(0,16.5,-31.5),C.Trim)

	-- Teto fechado V17: altura uniforme e corredor livre.
	bp("RoofFront", Vector3.new(78, 1, 10), Vector3.new(0, 17, -27), C.Dark)
	bp("RoofBack", Vector3.new(78, 1, 10), Vector3.new(0, 17, 27), C.Dark)
	bp("RoofCenter", Vector3.new(78, 1, 44), Vector3.new(0, 17, 0), C.Dark)
	-- Fecha a faixa entre as paredes existentes e o teto.
	for _, side in ipairs({-1, 1}) do
		bd("RoofEdge", Vector3.new(2.5, 0.5, 64), Vector3.new(side * 38, 17.75, 0), C.Trim)
	end
	bp("RoofRearFill", Vector3.new(76, 3, 2), Vector3.new(0, 15, 32), C.Wall)
	for _, z in ipairs({-16, 0, 16}) do
		local lamp = bd("InteriorLamp", Vector3.new(12, 0.3, 2), Vector3.new(0, 16.2, z), C.Trim, Enum.Material.Neon)
		local light = Instance.new("SurfaceLight")
		light.Face = Enum.NormalId.Bottom
		light.Angle = 120
		light.Range = 28
		light.Brightness = 1.2
		light.Color = Color3.fromRGB(235, 240, 255)
		light.Parent = lamp
	end
	-- Metadados para a futura integracao dos upgrades.
	base:SetAttribute("BaseLevel", 0)
	base:SetAttribute("StandCapacity", 10)

	-- EXPOSITORES
	-- Mesmos nomes e attachments da V6.

	local standsFolder = Instance.new("Folder")
	standsFolder.Name = "SwordStands"
	standsFolder.Parent = base

	for sideIndex = 1, 2 do

		local s = sideIndex == 1 and -1 or 1

		for slot = 1, 5 do

			local sx = s * CONFIG.StandX

			local sz = CONFIG.StandFirstZ
				+ (slot - 1) * CONFIG.StandSpacing

			local standCF = baseCF
				* CFrame.new(sx, 1.25, sz)

			local stand = part(
				"Stand_" .. sideIndex .. "_" .. slot,
				Vector3.new(
					CONFIG.StandWidth,
					0.5,
					CONFIG.StandDepth
				),
				standCF,
				C.Dark,
				Enum.Material.SmoothPlastic,
				standsFolder
			)

			-- Plataforma compacta com cantos chanfrados visualmente.
			stand.Transparency = 1
			local function display(name, size, offset, color)
				return decoration(name, size, standCF * CFrame.new(offset), color, Enum.Material.SmoothPlastic, stand)
			end
			display("DisplayBase", Vector3.new(10, .45, 4.8), Vector3.new(0, 0, 0), C.Dark)
			display("DisplayGold", Vector3.new(9.6, .15, 4.4), Vector3.new(0, .30, 0), C.Gold)
			display("DisplayTop", Vector3.new(9.1, .18, 3.9), Vector3.new(0, .45, 0), C.Wall)
			display("DisplayPedestal", Vector3.new(3.4, .65, 3.4), Vector3.new(0, .83, 0), C.Dark)
			display("DisplayCap", Vector3.new(3, .16, 3), Vector3.new(0, 1.23, 0), C.Metal)

			local attachment = Instance.new("Attachment")

			attachment.Name = "SwordPoint"
			attachment.Position = Vector3.new(0, 3, 0)
			attachment.Parent = stand
		end
	end

	-- BOTAO DE PROTECAO ORIGINAL

	local lockButton = bp(
		"LockButton",
		Vector3.new(7, 0.5, 7),
		Vector3.new(0, 1.3, -25),
		C.Red,
		Enum.Material.Neon
	)

	lockButton.Transparency = 1
	lockButton.CanCollide = false

	-- SPAWN ORIGINAL

	local spawn = Instance.new("SpawnLocation")

	spawn.Name = "Spawn"
	spawn.Size = Vector3.new(7, 1, 7)

	spawn.CFrame = baseCF
		* CFrame.new(0, 1.6, 0)

	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Transparency = 1
	spawn.CanCollide = false

	spawn.Parent = base

	-- CAMINHO ENTRE BASE E ESTEIRA

	local path = part(
		"Path" .. index,
		Vector3.new(50, 0.3, 24),
		CFrame.new(side * 47, 0.15, z),
		C.Path,
		Enum.Material.SmoothPlastic,
		map
	)

	path.TopSurface = Enum.SurfaceType.Smooth
	for offset=-20,20,10 do
		decoration("PathJoint",Vector3.new(.08,.025,23),CFrame.new(side*47+offset,.315,z),Color3.fromRGB(145,155,170),nil,decor)
	end

	-- Moldura do caminho.

	for _, edge in ipairs({-1, 1}) do

		decoration(
			"PathBorder",
			Vector3.new(50, 0.12, 0.7),
			CFrame.new(
				side * 47,
				0.35,
				z + edge * 11.8
			),
			C.Trim,
			nil,
			decor
		)
	end


	-- V19: acabamento Sword Vault, sem alterar colisoes ou slots.
	local graphite = C.Wall
	local brass = C.Gold
	local tile = C.Floor
	local function finish(name,size,x,y,z,color,material)
		return bd(name,size,Vector3.new(x,y,z),color,material)
	end
	floor.TopSurface = Enum.SurfaceType.Smooth
	floor.Color = tile
	corridor.Color = C.Center
	for _,p in ipairs(base:GetChildren()) do
		if p:IsA("BasePart") then
			if p.Name == "BackWall" or p.Name == "SideWall" or p.Name == "SideWallTop" or p.Name == "EntranceColumn" or p.Name == "EntranceHeader" or p.Name == "RoofSideFill" or p.Name == "RoofRearFill" then
				p.Color = graphite
			elseif p.Name:find("Trim") or p.Name == "RoofEdge" then
				p.Color = C.Trim
			elseif p.Name == "Window" then
				p.Color = C.Glass
				p.Transparency = .5
			end
		end
	end
	-- Juntas finas de ladrilho, fora do corredor central.
	for _,side in ipairs({-1,1}) do
		for x=12,36,8 do
			finish("TileJoint",Vector3.new(.08,.025,62),side*x,1.015,0,Color3.fromRGB(155,165,180))
		end
		for z=-28,28,8 do
			finish("TileJoint",Vector3.new(26,.025,.08),side*24,1.015,z,Color3.fromRGB(155,165,180))
		end
		finish("AisleGold",Vector3.new(.28,.04,52),side*10.3,1.075,0,brass)
		finish("FacadePillar",Vector3.new(2.2,13, .5),side*35,7.5,-33,graphite)
		finish("FacadeAccent",Vector3.new(.5,11,.15),side*35,7.5,-33.3,brass)

	end
	-- V25.4: fundo antigo da placa removido; entrada livre.

	return base
end

-- QUATRO BASES DE CADA LADO

for row = 1, 4 do
	createBase(row, -1, row)
	createBase(row + 4, 1, row)
end

-- DECORACAO MODERNA DO MAPA

local function createTree(x, z)

	local trunk = part(
		"TreeTrunk",
		Vector3.new(2, 7, 2),
		CFrame.new(x, 3.5, z),
		Color3.fromRGB(120, 78, 42),
		Enum.Material.SmoothPlastic,
		decor
	)

	local leaves = part(
		"TreeLeaves",
		Vector3.new(9, 9, 9),
		CFrame.new(x, 9, z),
		Color3.fromRGB(42, 155, 52),
		Enum.Material.SmoothPlastic,
		decor
	)

	leaves.Shape = Enum.PartType.Ball

	local top = part(
		"TreeTop",
		Vector3.new(6, 6, 6),
		CFrame.new(x, 13, z),
		Color3.fromRGB(76, 205, 64),
		Enum.Material.SmoothPlastic,
		decor
	)

	top.Shape = Enum.PartType.Ball
end

-- Arvores nas laterais externas.

for _, side in ipairs({-1, 1}) do

	for z = -175, 175, 70 do
		createTree(side * 153, z)
	end
end

-- V21: postes e paisagismo
for _,side in ipairs({-1,1}) do
	-- V21.2: duas fileiras espelhadas, espacamento de 64 studs.
	-- Sem poste no centro: entrada da loja livre nos dois lados.
	for _,lampZ in ipairs({-160,-96,-32,32,96,160}) do
		local x=side*26
		local function d(n,size,px,y,pz,c) return decoration(n,size,CFrame.new(px,y,pz),c,nil,decor) end
		d("LampFoot",Vector3.new(2.4,.45,2.4),x,.225,lampZ,C.Floor)
		d("LightPole",Vector3.new(.65,7.6,.65),x,4.05,lampZ,C.Dark)
		d("LampCollar",Vector3.new(.85,.6,.85),x,1.1,lampZ,C.Trim)
		d("LightArm",Vector3.new(3.4,.45,.65),x-side*1.4,7.8,lampZ,C.Dark)
		d("LampHousing",Vector3.new(2.6,.5,1.4),x-side*2.5,7.65,lampZ,C.Trim)
		local lamp=d("LampLens",Vector3.new(2.2,.12,1.1),x-side*2.5,7.34,lampZ,Color3.fromRGB(245,248,255))
		local light=Instance.new("PointLight"); light.Brightness=.65; light.Range=15; light.Color=Color3.fromRGB(245,248,255); light.Shadows=false; light.Parent=lamp
	end
	-- Canteiros junto ao limite externo, longe dos caminhos e da loja.
	for z=-141,141,94 do
		local x=side*158
		decoration("Planter",Vector3.new(5,.6,12),CFrame.new(x,.3,z),C.Trim,nil,decor)
		decoration("Soil",Vector3.new(4.5,.12,11.5),CFrame.new(x,.66,z),Color3.fromRGB(103,77,55),nil,decor)
		for dz=-4,4,4 do
			local bush=decoration("Bush",Vector3.new(3,2.5,3),CFrame.new(x,1.8,z+dz),Color3.fromRGB(53,151,79),nil,decor); bush.Shape=Enum.PartType.Ball
		end
	end
	-- Juntas discretas nas passarelas, sem colisao.
	for z=-160,160,16 do
		decoration("WalkwayJoint",Vector3.new(7.5,.025,.09),CFrame.new(side*18,.765,z),Color3.fromRGB(145,155,170),nil,arenaFolder)
	end
end

-- MUROS EXTERNOS V37.3
local wallHeight = 25
local barrierTop = 100
local barrierHeight = barrierTop - wallHeight
local function barrier(name, size, cf)
	local p = part(name, size, cf, C.Wall, nil, decor)
	p.Transparency = 1
	p.CanCollide = true
	p.CanTouch = false
	p.CanQuery = true
	p.CastShadow = false
	return p
end
for _, side in ipairs({-1, 1}) do
	local x = side * (CONFIG.MapWidth/2 - 2)
	local z = side * (CONFIG.MapLength/2 - 2)
	part("BoundaryWall", Vector3.new(3, wallHeight, CONFIG.MapLength), CFrame.new(x, wallHeight/2, 0), C.Wall, nil, decor)
	decoration("BoundaryTrim", Vector3.new(3.5, .8, CONFIG.MapLength), CFrame.new(x, wallHeight+.3, 0), C.Trim, nil, decor)
	part("BoundaryEnd", Vector3.new(CONFIG.MapWidth, wallHeight, 3), CFrame.new(0, wallHeight/2, z), C.Wall, nil, decor)
	decoration("BoundaryEndTrim", Vector3.new(CONFIG.MapWidth, .8, 3.5), CFrame.new(0, wallHeight+.3, z), C.Trim, nil, decor)
	barrier("BoundaryBarrierSide", Vector3.new(3, barrierHeight, CONFIG.MapLength), CFrame.new(x, wallHeight+barrierHeight/2, 0))
	barrier("BoundaryBarrierEnd", Vector3.new(CONFIG.MapWidth, barrierHeight, 3), CFrame.new(0, wallHeight+barrierHeight/2, z))
end

-- Resgate abaixo do mapa; nao limita a altura das ilhas.
local Players = game:GetService("Players")
task.spawn(function()
	while map.Parent do
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root and humanoid and humanoid.Health > 0 and root.Position.Y < -40 then
				-- Nao transportar uma espada roubada diretamente para a base.
				local target = CFrame.new(0, 5, 0)
				if not player:GetAttribute("CarryingStolen") then
					for _, base in ipairs(basesFolder:GetChildren()) do
						if base:GetAttribute("OwnerUserId") == player.UserId then
							local floor = base:FindFirstChild("Floor")
							if floor then target = floor.CFrame * CFrame.new(0, 4, -8) end
							break
						end
					end
				end
				character:PivotTo(target)
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
			end
		end
		task.wait(.1)
	end
end)

-- MAPA PRONTO

map:SetAttribute("MapVersion", 8)
map:SetAttribute("MapRevision", "37.3")
map:SetAttribute("MapReady", true)

print("[MapGenerator V19] Sword Factory criada!")
print("[MapGenerator V19] 8 bases e 80 expositores!")
print("[MapGenerator V19] Esteira pronta para SwordSystem!")
