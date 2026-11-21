
-- SPIRIT REALM V3
-- ROUBE UMA ESPADA
-- Local: ServerScriptService

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local CONFIG = {
	Center = Vector3.new(0, 115, -420),

	IslandFloat = 1.8,
	FloatSpeed = 0.45,

	AuroraEnabled = false,
	WaterfallsEnabled = true,
}

local C = {
	Rock = Color3.fromRGB(52, 65, 105),
	RockLight = Color3.fromRGB(89, 106, 153),
	RockDark = Color3.fromRGB(38, 45, 80),

	Grass = Color3.fromRGB(75, 170, 185),
	GrassLight = Color3.fromRGB(113, 205, 205),

	Cyan = Color3.fromRGB(75, 205, 255),
	Ice = Color3.fromRGB(190, 240, 255),
	Purple = Color3.fromRGB(158, 104, 235),
	Pink = Color3.fromRGB(216, 145, 255),

	Trunk = Color3.fromRGB(70, 65, 115),
}

local rng = Random.new(319)

-- ESPERAR A ESPADA V2 CARREGAR

local spirit = Workspace:WaitForChild(
	"AetherSpirit",
	30
)

if not spirit then
	warn("[SpiritRealmV3] AetherSpirit nao encontrada!")
	return
end

local aether = spirit:WaitForChild("Aether", 15)

if not aether then
	warn("[SpiritRealmV3] Espada nao encontrada!")
	return
end

-- A V2 cria esta pasta com as ilhas antigas.

local oldRealm = spirit:WaitForChild(
	"SpiritRealm",
	15
)

if oldRealm then
	-- Aguarda a construcao da V2 terminar.
	task.wait(1)
	oldRealm:Destroy()
end

local oldV3 = Workspace:FindFirstChild(
	"CelestialRealmV3"
)

if oldV3 then
	oldV3:Destroy()
end

local realm = Instance.new("Model")
realm.Name = "CelestialRealmV3"

realm.ModelStreamingMode =
	Enum.ModelStreamingMode.Persistent

realm.Parent = Workspace

-- FUNCOES DE CONSTRUCAO

local function part(
	name, size, cf, color,
	material, transparency, parent, class
)
	local p = Instance.new(class or "Part")

	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color

	p.Material = material
		or Enum.Material.SmoothPlastic

	p.Transparency = transparency or 0

	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false

	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth

	p.Parent = parent or realm

	return p
end

local function sphere(
	name, size, position, color,
	material, transparency, parent
)
	local p = part(
		name,
		size,
		CFrame.new(position),
		color,
		material,
		transparency,
		parent
	)

	p.Shape = Enum.PartType.Ball

	return p
end

local function line(
	name, a, b, width, color,
	material, transparency, parent
)
	local distance = (b - a).Magnitude

	if distance < 0.01 then
		return
	end

	return part(
		name,
		Vector3.new(width, width, distance),
		CFrame.lookAt((a + b) / 2, b),
		color,
		material,
		transparency,
		parent
	)
end

-- =====================================
-- CRISTAIS FACETADOS
-- =====================================

local function crystal(
	parent, position, height, width, color
)
	local model = Instance.new("Model")
	model.Name = "CelestialCrystal"
	model.Parent = parent

	local rotation = CFrame.Angles(
		0,
		rng:NextNumber(0, math.pi * 2),
		rng:NextNumber(-0.25, 0.25)
	)

	local cf = CFrame.new(position) * rotation

	-- Corpo principal.

	part(
		"CrystalBody",
		Vector3.new(width, height * 0.7, width),
		cf * CFrame.new(0, height * 0.35, 0),
		color,
		Enum.Material.Glass,
		0.12,
		model
	)

	-- Faces laterais.

	for _, side in ipairs({-1, 1}) do

		part(
			"CrystalFacet",
			Vector3.new(
				width * 0.55,
				height * 0.7,
				width * 0.65
			),
			cf * CFrame.new(
				side * width * 0.3,
				height * 0.35,
				0
			) * CFrame.Angles(
				0,
				math.rad(side * 35),
				0
			),
			color:Lerp(C.Ice, 0.25),
			Enum.Material.Glass,
			0.1,
			model
		)
	end

	-- Ponta cristalina.

	part(
		"CrystalTip",
		Vector3.new(
			width * 0.8,
			height * 0.32,
			width * 0.8
		),
		cf * CFrame.new(
			0,
			height * 0.76,
			0
		) * CFrame.Angles(
			math.rad(180),
			math.rad(45),
			0
		),
		C.Ice,
		Enum.Material.Glass,
		0.12,
		model,
		"WedgePart"
	)

	-- Energia interna.

	part(
		"CrystalGlow",
		Vector3.new(
			width * 0.2,
			height * 0.6,
			width * 0.2
		),
		cf * CFrame.new(0, height * 0.35, 0),
		C.Ice,
		Enum.Material.Neon,
		0.35,
		model
	)

	return model
end

-- =====================================
-- ARVORES ESPIRITUAIS
-- =====================================

local function createTree(
	parent, position, size
)
	local model = Instance.new("Model")
	model.Name = "SpiritTree"
	model.Parent = parent

	local height = size * 2.5

	local trunk = part(
		"Trunk",
		Vector3.new(
			size * 0.3,
			height,
			size * 0.3
		),
		CFrame.new(
			position + Vector3.new(
				0, height / 2, 0
			)
		),
		C.Trunk,
		Enum.Material.SmoothPlastic,
		0,
		model
	)

	-- Galhos inclinados.

	for _, side in ipairs({-1, 1}) do

		local start = position
			+ Vector3.new(0, height * 0.55, 0)

		local finish = position
			+ Vector3.new(
				side * size,
				height * 0.9,
				size * 0.2
			)

		line(
			"Branch",
			start,
			finish,
			size * 0.16,
			C.Trunk,
			nil,
			0,
			model
		)
	end

	-- Copas magicas.

	for i = 1, 5 do

		local angle = i / 5 * math.pi * 2

		local offset = Vector3.new(
			math.cos(angle) * size * 0.7,
			height + rng:NextNumber(-1, 2),
			math.sin(angle) * size * 0.7
		)

		sphere(
			"SpiritLeaves",
			Vector3.new(
				size * 1.8,
				size * 1.4,
				size * 1.8
			),
			position + offset,
			i % 2 == 0 and C.Purple or C.Pink,
			Enum.Material.SmoothPlastic,
			0.05,
			model
		)
	end

	sphere(
		"TreeCrown",
		Vector3.new(
			size * 2,
			size * 1.5,
			size * 2
		),
		position + Vector3.new(
			0, height + size * 0.5, 0
		),
		C.Purple,
		Enum.Material.SmoothPlastic,
		0,
		model
	)

	return model
end

-- =====================================
-- CACHOEIRAS ESPIRITUAIS
-- =====================================

local waterfalls = {}

local function waterfall(
	parent, position, width, height
)
	local model = Instance.new("Model")
	model.Name = "SpiritWaterfall"
	model.Parent = parent

	-- Agua translúcida.

	part(
		"WaterBody",
		Vector3.new(width, height, 2.5),
		CFrame.new(
			position - Vector3.new(
				0, height / 2, 0
			)
		),
		C.Cyan,
		Enum.Material.Glass,
		0.35,
		model
	)

	-- Correntes luminosas em movimento.

	for i = 1, 6 do

		local x = -width / 2
			+ i * width / 7

		local streak = part(
			"FlowingEnergy",
			Vector3.new(
				0.45,
				height * 0.22,
				0.45
			),
			CFrame.new(
				position + Vector3.new(
					x, -height / 2, 1.5
				)
			),
			C.Ice,
			Enum.Material.Neon,
			0.35,
			model
		)

		table.insert(waterfalls, {
			Part = streak,
			Origin = position,
			X = x,
			Height = height,
			Offset = i / 6,
			Speed = rng:NextNumber(0.35, 0.65),
		})
	end

	-- Nevoa na base da cachoeira.

	local mistSource = part(
		"WaterfallMist",
		Vector3.new(width, 2, 4),
		CFrame.new(
			position - Vector3.new(
				0, height, 0
			)
		),
		C.Ice,
		nil,
		1,
		model
	)

	local mist = Instance.new("ParticleEmitter")

	mist.Texture =
		"rbxasset://textures/particles/smoke_main.dds"

	mist.Color = ColorSequence.new(
		C.Ice,
		C.Cyan
	)

	mist.Rate = 8
	mist.Lifetime = NumberRange.new(3, 5)
	mist.Speed = NumberRange.new(1, 4)
	mist.SpreadAngle = Vector2.new(180, 180)

	mist.LightEmission = 0.15
	mist.LightInfluence = 0.5

	mist.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 3),
		NumberSequenceKeypoint.new(1, 14),
	})

	mist.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.25, 0.65),
		NumberSequenceKeypoint.new(1, 1),
	})

	mist.Parent = mistSource

	return model
end

-- =====================================
-- ILHAS CELESTIAIS
-- =====================================

local islands = {}

local function createIsland(
	name, position, radius, treeCount
)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = realm

	local pivot = part(
		"IslandPivot",
		Vector3.new(1, 1, 1),
		CFrame.new(position),
		C.Rock,
		nil,
		1,
		model
	)

	model.PrimaryPart = pivot

	-- Base rochosa em camadas.

	sphere(
		"UpperRock",
		Vector3.new(
			radius * 2,
			radius * 0.65,
			radius * 1.8
		),
		position - Vector3.new(0, 4, 0),
		C.RockLight,
		Enum.Material.Slate,
		0,
		model
	)

	sphere(
		"MiddleRock",
		Vector3.new(
			radius * 1.55,
			radius * 0.85,
			radius * 1.35
		),
		position - Vector3.new(
			0, radius * 0.42, 0
		),
		C.Rock,
		Enum.Material.Slate,
		0,
		model
	)

	sphere(
		"LowerRock",
		Vector3.new(
			radius * 0.95,
			radius * 1.1,
			radius * 0.8
		),
		position - Vector3.new(
			0, radius * 0.85, 0
		),
		C.RockDark,
		Enum.Material.Slate,
		0,
		model
	)

	-- Pontas rochosas irregulares.

	for i = 1, 7 do

		local angle = i / 7 * math.pi * 2

		local offset = Vector3.new(
			math.cos(angle) * radius * 0.45,
			-radius * 0.65,
			math.sin(angle) * radius * 0.45
		)

		part(
			"RockShard",
			Vector3.new(
				radius * 0.55,
				radius * rng:NextNumber(0.8, 1.4),
				radius * 0.55
			),
			CFrame.new(position + offset)
				* CFrame.Angles(
					math.rad(180),
					angle,
					rng:NextNumber(-0.4, 0.4)
				),
			i % 2 == 0 and C.Rock
				or C.RockLight,
			Enum.Material.Slate,
			0,
			model,
			"WedgePart"
		)
	end

	-- Superficie azulada.

	sphere(
		"SpiritGrass",
		Vector3.new(
			radius * 1.95,
			5,
			radius * 1.75
		),
		position,
		C.Grass,
		Enum.Material.SmoothPlastic,
		0,
		model
	)

	sphere(
		"GrassHighlight",
		Vector3.new(
			radius * 1.55,
			2.5,
			radius * 1.4
		),
		position + Vector3.new(0, 1.5, 0),
		C.GrassLight,
		Enum.Material.SmoothPlastic,
		0,
		model
	)

	-- Cristais grandes.

	for i = 1, 4 do

		local angle = i / 4 * math.pi * 2

		local offset = Vector3.new(
			math.cos(angle) * radius * 0.48,
			2.5,
			math.sin(angle) * radius * 0.48
		)

		crystal(
			model,
			position + offset,
			rng:NextNumber(9, 17),
			rng:NextNumber(3, 5),
			i % 2 == 0 and C.Purple
				or C.Cyan
		)
	end

	-- Vegetacao espiritual.

	for i = 1, treeCount do

		local angle = i / treeCount
			* math.pi * 2 + 0.6

		local offset = Vector3.new(
			math.cos(angle) * radius * 0.32,
			2.5,
			math.sin(angle) * radius * 0.32
		)

		createTree(
			model,
			position + offset,
			rng:NextNumber(3, 5)
		)
	end

	-- Pequenas pedras luminosas.

	for i = 1, 8 do

		local angle = rng:NextNumber(
			0, math.pi * 2
		)

		local r = rng:NextNumber(
			radius * 0.2,
			radius * 0.7
		)

		sphere(
			"SpiritStone",
			Vector3.new(2, 1.5, 2),
			position + Vector3.new(
				math.cos(angle) * r,
				2.7,
				math.sin(angle) * r
			),
			C.Cyan,
			Enum.Material.Neon,
			0.4,
			model
		)
	end

	table.insert(islands, {
		Model = model,
		Position = position,
		Phase = rng:NextNumber(
			0, math.pi * 2
		),
	})

	return model
end

-- =====================================
-- POSICOES DAS ILHAS
-- =====================================

local center = CONFIG.Center

local leftPosition =
	center + Vector3.new(-105, -30, -30)

local rightPosition =
	center + Vector3.new(112, -15, -55)

local lowerPosition =
	center + Vector3.new(10, -85, -65)

local farLeftPosition =
	center + Vector3.new(-185, 15, -110)

local farRightPosition =
	center + Vector3.new(190, -40, -95)

local left = createIsland(
	"CelestialIslandLeft",
	leftPosition,
	27,
	3
)

local right = createIsland(
	"CelestialIslandRight",
	rightPosition,
	32,
	3
)

local lower = createIsland(
	"CelestialIslandLower",
	lowerPosition,
	25,
	2
)

createIsland(
	"CelestialIslandFarLeft",
	farLeftPosition,
	19,
	2
)

createIsland(
	"CelestialIslandFarRight",
	farRightPosition,
	21,
	2
)

-- =====================================
-- CACHOEIRAS DAS ILHAS
-- =====================================

if CONFIG.WaterfallsEnabled then

	waterfall(
		realm,
		leftPosition + Vector3.new(
			-8, 1, 24
		),
		9,
		65
	)

	waterfall(
		realm,
		rightPosition + Vector3.new(
			10, 1, 28
		),
		12,
		80
	)

	waterfall(
		realm,
		lowerPosition + Vector3.new(
			4, 1, 22
		),
		8,
		48
	)
end

-- =====================================
-- NUVENS CELESTIAIS
-- =====================================

local clouds = Instance.new("Model")
clouds.Name = "CelestialClouds"
clouds.Parent = realm

local function cloud(position, size)

	for i = 1, 5 do

		local offset = Vector3.new(
			(i - 3) * size * 0.4,
			rng:NextNumber(-2, 2),
			rng:NextNumber(-4, 4)
		)

		sphere(
			"CloudPuff",
			Vector3.new(
				size,
				size * 0.32,
				size * 0.6
			),
			position + offset,
			C.Ice,
			Enum.Material.SmoothPlastic,
			0.65,
			clouds
		)
	end
end

cloud(
	center + Vector3.new(-105, -72, -12),
	38
)

cloud(
	center + Vector3.new(115, -75, -30),
	48
)

cloud(
	center + Vector3.new(0, -105, -25),
	55
)

cloud(
	center + Vector3.new(-170, -35, -90),
	36
)

cloud(
	center + Vector3.new(175, -60, -80),
	42
)

-- =====================================
-- AURORA CELESTIAL
-- =====================================

local aurora = Instance.new("Model")
aurora.Name = "CelestialAurora"
aurora.Parent = realm

if CONFIG.AuroraEnabled then

	local auroraCenter =
		center + Vector3.new(0, 65, -160)

	for band = 1, 3 do

		local color = band == 1 and C.Cyan
			or band == 2 and C.Purple
			or C.Pink

		local previous = nil

		for i = 0, 40 do

			local x = -220 + i * 11

			local y = math.sin(
				i * 0.2 + band
			) * 20 + band * 12

			local z = math.cos(
				i * 0.12
			) * 25

			local position = auroraCenter
				+ Vector3.new(x, y, z)

			if previous then

				line(
					"AuroraRibbon",
					previous,
					position,
					4 + band,
					color,
					Enum.Material.Neon,
					0.65,
					aurora
				)

				line(
					"AuroraSoftGlow",
					previous + Vector3.new(0, 4, 0),
					position + Vector3.new(0, 4, 0),
					10 + band,
					color,
					Enum.Material.Neon,
					0.88,
					aurora
				)
			end

			previous = position
		end
	end
end

-- =====================================
-- ESTRELAS ESPIRITUAIS
-- =====================================

local stars = Instance.new("Folder")
stars.Name = "CelestialStars"
stars.Parent = realm

for i = 1, 45 do

	local position = center
		+ Vector3.new(
			rng:NextNumber(-230, 230),
			rng:NextNumber(-25, 150),
			rng:NextNumber(-180, -30)
		)

	local size = rng:NextNumber(0.4, 1.4)

	sphere(
		"SpiritStar",
		Vector3.new(size, size, size),
		position,
		i % 2 == 0 and C.Ice or C.Purple,
		Enum.Material.Neon,
		0.2,
		stars
	)
end

-- =====================================
-- ANIMACAO DO CENARIO
-- =====================================

local elapsed = 0
local accumulator = 0

local connection

connection = RunService.Heartbeat:Connect(
	function(dt)

		if not realm.Parent then
			connection:Disconnect()
			return
		end

		elapsed += dt
		accumulator += dt

		-- Atualizacao limitada a 10 FPS
		-- para reduzir o custo das decoracoes.

		if accumulator < 0.1 then
			return
		end

		accumulator = 0

		-- Ilhas flutuando suavemente.

		for _, island in ipairs(islands) do

			local y = math.sin(
				elapsed * CONFIG.FloatSpeed
					+ island.Phase
			) * CONFIG.IslandFloat

			island.Model:PivotTo(
				CFrame.new(
					island.Position
						+ Vector3.new(0, y, 0)
				)
			)
		end

		-- Energia descendo nas cachoeiras.

		for _, water in ipairs(waterfalls) do

			local progress = (
				elapsed * water.Speed
					+ water.Offset
			) % 1

			local y = -progress * water.Height

			water.Part.CFrame = CFrame.new(
				water.Origin + Vector3.new(
					water.X, y, 1.5
				)
			)

			water.Part.Transparency =
				0.35 + progress * 0.5
		end
	end
)

print("[SpiritRealmV3] Dimensao celestial criada!")
print("[SpiritRealmV3] Aether preservada!")
