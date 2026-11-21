
-- AETHER V2 - THE SPIRIT REALM
-- ROUBE UMA ESPADA
-- Local: ServerScriptService / SpiritSword

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local CONFIG = {
	Position = Vector3.new(0, 115, -420),
	Scale = 5.5,

	FloatHeight = 3,
	FloatSpeed = 0.55,

	RotationSpeed = 0.08,
	FragmentCount = 14,
}

local C = {
	Cyan = Color3.fromRGB(75, 200, 255),
	Ice = Color3.fromRGB(190, 235, 255),
	White = Color3.fromRGB(225, 250, 255),
	Purple = Color3.fromRGB(145, 100, 245),
	Blue = Color3.fromRGB(45, 105, 205),
	Dark = Color3.fromRGB(30, 40, 85),

	Rock = Color3.fromRGB(75, 82, 125),
	RockLight = Color3.fromRGB(110, 125, 165),
	IslandTop = Color3.fromRGB(90, 165, 190),
}

local S = CONFIG.Scale
local rng = Random.new(72)

-- LIMPAR VERSAO ANTERIOR

local old = Workspace:FindFirstChild("AetherSpirit")

if old then
	old:Destroy()
end

local root = Instance.new("Folder")
root.Name = "AetherSpirit"
root.Parent = Workspace

local sword = Instance.new("Model")
sword.Name = "Aether"
sword.ModelStreamingMode =
	Enum.ModelStreamingMode.Persistent
sword.Parent = root

-- FUNCAO DE PECAS

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

	p.Parent = parent or sword

	return p
end

local function sp(
	name, size, offset, color,
	material, transparency, rotation
)
	return part(
		name,
		size * S,
		CFrame.new(offset * S)
			* (rotation or CFrame.new()),
		color,
		material,
		transparency,
		sword
	)
end

-- PIVO

local pivot = sp(
	"SpiritCore",
	Vector3.new(0.2, 0.2, 0.2),
	Vector3.zero,
	C.Cyan,
	Enum.Material.SmoothPlastic,
	1
)

sword.PrimaryPart = pivot

-- GEOMETRIA TRIANGULAR
-- Permite criar uma lamina com formato
-- personalizado, sem depender de MeshParts.

local function triangle(
	name, a, b, c, thickness,
	color, material, transparency, parent
)
	local ab = b - a
	local ac = c - a
	local bc = c - b

	-- Escolher o maior lado.

	if ab.Magnitude > ac.Magnitude
		and ab.Magnitude > bc.Magnitude then

		a, c = c, a

	elseif ac.Magnitude > bc.Magnitude
		and ac.Magnitude > ab.Magnitude then

		a, b = b, a
	end

	ab = b - a
	ac = c - a
	bc = c - b

	local cross = ac:Cross(ab)

	if cross.Magnitude < 0.001 then
		return
	end

	local right = cross.Unit
	local back = bc.Unit
	local up = bc:Cross(right).Unit

	local height = math.abs(ab:Dot(up))

	local length1 = math.abs(ab:Dot(back))
	local length2 = math.abs(ac:Dot(back))

	if length1 > 0.01 then

		part(
			name,
			Vector3.new(
				thickness,
				height,
				length1
			),
			CFrame.fromMatrix(
				(a + b) / 2,
				right,
				up,
				back
			),
			color,
			material,
			transparency,
			parent,
			"WedgePart"
		)
	end

	if length2 > 0.01 then

		part(
			name,
			Vector3.new(
				thickness,
				height,
				length2
			),
			CFrame.fromMatrix(
				(a + c) / 2,
				-right,
				up,
				-back
			),
			color,
			material,
			transparency,
			parent,
			"WedgePart"
		)
	end
end

local function tri(
	name, a, b, c,
	thickness, color, material, transparency
)
	triangle(
		name,
		a * S,
		b * S,
		c * S,
		thickness * S,
		color,
		material,
		transparency,
		sword
	)
end

-- =====================================
-- LAMINA CRISTALINA
-- =====================================

-- Silhueta mais larga na parte superior,
-- afunilando ate a ponta.

local bladePoints = {
	{Y = 3.5, W = 1.3},
	{Y = 1.5, W = 2.1},
	{Y = -3, W = 1.75},
	{Y = -8, W = 1.3},
	{Y = -12, W = 0.65},
	{Y = -15, W = 0},
}

for i = 1, #bladePoints - 1 do

	local a = bladePoints[i]
	local b = bladePoints[i + 1]

	for _, side in ipairs({-1, 1}) do

		local upperCenter =
			Vector3.new(0, a.Y, 0)

		local lowerCenter =
			Vector3.new(0, b.Y, 0)

		local upperEdge =
			Vector3.new(side * a.W, a.Y, 0)

		local lowerEdge =
			Vector3.new(side * b.W, b.Y, 0)

		local color =
			side == 1 and C.Cyan or C.Blue

		tri(
			"BladeFace",
			upperCenter,
			upperEdge,
			lowerCenter,
			0.85,
			color,
			Enum.Material.Glass,
			0.12
		)

		tri(
			"BladeFace",
			upperEdge,
			lowerEdge,
			lowerCenter,
			0.85,
			color,
			Enum.Material.Glass,
			0.12
		)
	end
end

-- FACETAS BRILHANTES
-- Criam uma nervura no centro da lamina.

for _, side in ipairs({-1, 1}) do

	tri(
		"CrystalRidge",
		Vector3.new(0, 3.5, side * 0.65),
		Vector3.new(1.1, -2, side * 0.45),
		Vector3.new(0, -14, side * 0.65),
		0.13,
		C.Ice,
		Enum.Material.SmoothPlastic,
		0.15
	)

	tri(
		"CrystalRidge",
		Vector3.new(0, 3.5, side * 0.65),
		Vector3.new(-1.1, -2, side * 0.45),
		Vector3.new(0, -14, side * 0.65),
		0.13,
		C.Ice,
		Enum.Material.SmoothPlastic,
		0.15
	)
end

-- LINHAS DE ENERGIA NAS BORDAS

local function energyLine(
	name, a, b, width, color, parent
)
	local length = (b - a).Magnitude

	return part(
		name,
		Vector3.new(width, width, length),
		CFrame.lookAt((a + b) / 2, b),
		color,
		Enum.Material.Neon,
		0.18,
		parent
	)
end

for i = 1, #bladePoints - 1 do

	local a = bladePoints[i]
	local b = bladePoints[i + 1]

	for _, side in ipairs({-1, 1}) do

		energyLine(
			"BladeEnergyEdge",
			Vector3.new(
				side * a.W,
				a.Y,
				0
			) * S,
			Vector3.new(
				side * b.W,
				b.Y,
				0
			) * S,
			0.12 * S,
			C.Purple,
			sword
		)
	end
end

-- NUCLEO ESPIRITUAL

sp(
	"EnergyCore",
	Vector3.new(0.24, 15, 0.24),
	Vector3.new(0, -4.5, 0.8),
	C.White,
	Enum.Material.Neon,
	0.25
)

sp(
	"EnergyCoreBack",
	Vector3.new(0.24, 15, 0.24),
	Vector3.new(0, -4.5, -0.8),
	C.White,
	Enum.Material.Neon,
	0.25
)

-- =====================================
-- GUARDA LENDARIA
-- =====================================

sp(
	"GuardCenter",
	Vector3.new(3.6, 1.4, 1.8),
	Vector3.new(0, 4.2, 0),
	C.Dark,
	Enum.Material.Metal
)

-- Asas curvas feitas de triangulos.

for _, side in ipairs({-1, 1}) do

	local points = {
		Vector3.new(0, 4, 0),
		Vector3.new(side * 2.6, 4.8, 0),
		Vector3.new(side * 5.5, 7.2, 0),
		Vector3.new(side * 4.2, 3.5, 0),
		Vector3.new(side * 2.4, 2.6, 0),
	}

	tri(
		"GuardWing",
		points[1],
		points[2],
		points[4],
		1.2,
		C.Dark,
		Enum.Material.Metal,
		0
	)

	tri(
		"GuardWing",
		points[2],
		points[3],
		points[4],
		1.2,
		C.Blue,
		Enum.Material.Metal,
		0
	)

	tri(
		"GuardWing",
		points[1],
		points[4],
		points[5],
		1.2,
		C.Blue,
		Enum.Material.Metal,
		0
	)

	energyLine(
		"GuardEnergy",
		points[2] * S,
		points[3] * S,
		0.3 * S,
		C.Cyan,
		sword
	)

	energyLine(
		"GuardEnergy",
		points[3] * S,
		points[4] * S,
		0.25 * S,
		C.Purple,
		sword
	)
end

-- CRISTAL CENTRAL

local gem = sp(
	"SoulGem",
	Vector3.new(2.3, 2.3, 2.3),
	Vector3.new(0, 4.3, 0),
	C.Cyan,
	Enum.Material.Neon,
	0.18,
	CFrame.Angles(
		math.rad(45),
		0,
		math.rad(45)
	)
)

-- EMPUNHADURA

local handle = sp(
	"Handle",
	Vector3.new(1.3, 5.2, 1.3),
	Vector3.new(0, 7.5, 0),
	C.Dark,
	Enum.Material.Metal
)

for i = 1, 7 do

	sp(
		"HandleBand",
		Vector3.new(1.5, 0.22, 1.5),
		Vector3.new(
			0,
			5.1 + i * 0.65,
			0
		),
		i % 2 == 0 and C.Purple or C.Blue,
		Enum.Material.Metal
	)
end

sp(
	"Pommel",
	Vector3.new(1.8, 1.8, 1.8),
	Vector3.new(0, 10.7, 0),
	C.Purple,
	Enum.Material.Glass,
	0.1,
	CFrame.Angles(
		math.rad(45),
		0,
		math.rad(45)
	)
)

-- =====================================
-- PARTICULAS ESPIRITUAIS
-- =====================================

local emitter = Instance.new("ParticleEmitter")

emitter.Name = "SoulParticles"

emitter.Texture =
	"rbxasset://textures/particles/sparkles_main.dds"

emitter.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, C.Cyan),
	ColorSequenceKeypoint.new(0.5, C.White),
	ColorSequenceKeypoint.new(1, C.Purple),
})

emitter.Rate = 22
emitter.Lifetime = NumberRange.new(3, 6)
emitter.Speed = NumberRange.new(3, 9)
emitter.SpreadAngle = Vector2.new(180, 180)

emitter.LightEmission = 0.6
emitter.LightInfluence = 0

emitter.Size = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.5),
	NumberSequenceKeypoint.new(0.4, 1.4),
	NumberSequenceKeypoint.new(1, 0),
})

emitter.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.3),
	NumberSequenceKeypoint.new(0.6, 0.5),
	NumberSequenceKeypoint.new(1, 1),
})

emitter.Acceleration = Vector3.new(0, 2, 0)
emitter.Parent = gem

-- =====================================
-- ANEIS ESPIRITUAIS
-- =====================================

local rings = {}

local function createRing(
	radius, height, color, tilt, speed
)
	local model = Instance.new("Model")
	model.Name = "SpiritRing"

	model.ModelStreamingMode =
		Enum.ModelStreamingMode.Persistent

	model.Parent = root

	local ringPivot = part(
		"RingPivot",
		Vector3.new(1, 1, 1),
		CFrame.new(),
		color,
		nil,
		1,
		model
	)

	model.PrimaryPart = ringPivot

	local segments = 40

	for i = 1, segments do

		local a1 = (i - 1)
			/ segments * math.pi * 2

		local a2 = i
			/ segments * math.pi * 2

		local p1 = Vector3.new(
			math.cos(a1) * radius,
			0,
			math.sin(a1) * radius
		)

		local p2 = Vector3.new(
			math.cos(a2) * radius,
			0,
			math.sin(a2) * radius
		)

		energyLine(
			"RingSegment",
			p1,
			p2,
			0.38,
			color,
			model
		)
	end

	-- Simbolos luminosos no anel.

	local symbols = {
		"◇", "✦", "△", "✧",
		"○", "◇", "✦", "△",
	}

	for i = 1, 8 do

		local angle =
			i / 8 * math.pi * 2

		local position = Vector3.new(
			math.cos(angle) * radius,
			0,
			math.sin(angle) * radius
		)

		local rune = part(
			"SpiritRune",
			Vector3.new(2, 2, 2),
			CFrame.new(position)
				* CFrame.Angles(
					math.rad(45),
					angle,
					math.rad(45)
				),
			color,
			Enum.Material.Neon,
			0.2,
			model
		)

		local gui = Instance.new("BillboardGui")

		gui.Size = UDim2.fromOffset(28, 28)
		gui.StudsOffset = Vector3.new(0, 2, 0)
		gui.AlwaysOnTop = false
		gui.MaxDistance = 850
		gui.Parent = rune

		local label = Instance.new("TextLabel")

		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = symbols[i]
		label.TextScaled = true
		label.TextColor3 = color
		label.Font = Enum.Font.GothamBold
		label.Parent = gui
	end

	table.insert(rings, {
		Model = model,
		Height = height,
		Tilt = tilt,
		Speed = speed,
	})
end

createRing(32, 15, C.Cyan, 22, 0.25)
createRing(42, -17, C.Purple, -28, -0.2)
createRing(26, -55, C.Ice, 35, 0.32)

-- =====================================
-- CRISTAIS ESPIRITUAIS
-- =====================================

local function crystal(
	parent, position, size, color
)
	local model = Instance.new("Model")
	model.Name = "SpiritCrystal"
	model.Parent = parent

	local core = part(
		"CrystalCore",
		Vector3.new(
			size,
			size * 1.8,
			size
		),
		CFrame.new(position)
			* CFrame.Angles(
				0,
				math.rad(45),
				math.rad(15)
			),
		color,
		Enum.Material.Glass,
		0.12,
		model
	)

	model.PrimaryPart = core

	local glow = part(
		"CrystalEnergy",
		Vector3.new(
			size * 0.3,
			size * 1.4,
			size * 0.3
		),
		core.CFrame,
		C.Ice,
		Enum.Material.Neon,
		0.35,
		model
	)

	return model
end

-- =====================================
-- DIMENSAO ESPIRITUAL
-- ILHAS FLUTUANTES
-- =====================================

local realm = Instance.new("Model")
realm.Name = "SpiritRealm"

realm.ModelStreamingMode =
	Enum.ModelStreamingMode.Persistent

realm.Parent = root

local function island(position, radius)

	local model = Instance.new("Model")
	model.Name = "FloatingIsland"
	model.Parent = realm

	-- Topo da ilha.

	local top = part(
		"IslandSurface",
		Vector3.new(
			radius * 2,
			4,
			radius * 2
		),
		CFrame.new(position),
		C.IslandTop,
		Enum.Material.Slate,
		0,
		model
	)

	top.Shape = Enum.PartType.Ball

	-- Rochas inferiores.

	for i = 1, 9 do

		local angle =
			i / 9 * math.pi * 2

		local rockRadius =
			radius * rng:NextNumber(0.35, 0.75)

		local rockPosition =
			position + Vector3.new(
				math.cos(angle) * rockRadius,
				-rng:NextNumber(4, 10),
				math.sin(angle) * rockRadius
			)

		local rockSize =
			rng:NextNumber(
				radius * 0.6,
				radius * 1.1
			)

		part(
			"IslandRock",
			Vector3.new(
				rockSize,
				radius * 1.2,
				rockSize
			),
			CFrame.new(rockPosition)
				* CFrame.Angles(
					rng:NextNumber(-0.5, 0.5),
					angle,
					rng:NextNumber(-0.5, 0.5)
				),
			i % 2 == 0 and C.Rock
				or C.RockLight,
			Enum.Material.Slate,
			0,
			model,
			"WedgePart"
		)
	end

	-- Ponta inferior da ilha.

	part(
		"IslandBottom",
		Vector3.new(
			radius,
			radius * 1.7,
			radius
		),
		CFrame.new(
			position - Vector3.new(
				0, radius * 0.65, 0
			)
		) * CFrame.Angles(
			math.rad(180),
			math.rad(45),
			0
		),
		C.Rock,
		Enum.Material.Slate,
		0,
		model,
		"WedgePart"
	)

	-- Cristais crescendo na superficie.

	for i = 1, 5 do

		local angle =
			i / 5 * math.pi * 2

		local offset = Vector3.new(
			math.cos(angle) * radius * 0.45,
			5,
			math.sin(angle) * radius * 0.45
		)

		crystal(
			model,
			position + offset,
			rng:NextNumber(3, 6),
			i % 2 == 0 and C.Purple
				or C.Cyan
		)
	end

	return model
end

local center = CONFIG.Position

-- Todas as ilhas ficam fora do mapa.

island(
	center + Vector3.new(-95, -48, -35),
	24
)

island(
	center + Vector3.new(100, -30, -55),
	29
)

island(
	center + Vector3.new(-150, -12, -85),
	17
)

island(
	center + Vector3.new(155, -70, -20),
	20
)

island(
	center + Vector3.new(15, -95, -65),
	32
)

-- =====================================
-- NEVOA ESPIRITUAL
-- =====================================

local mistSource = part(
	"SpiritMistSource",
	Vector3.new(140, 5, 70),
	CFrame.new(
		center + Vector3.new(0, -65, 0)
	),
	C.Cyan,
	nil,
	1,
	realm
)

local mist = Instance.new("ParticleEmitter")

mist.Name = "SpiritMist"

mist.Texture =
	"rbxasset://textures/particles/smoke_main.dds"

mist.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, C.Cyan),
	ColorSequenceKeypoint.new(1, C.Purple),
})

mist.Rate = 12
mist.Lifetime = NumberRange.new(8, 12)
mist.Speed = NumberRange.new(1, 3)

mist.SpreadAngle = Vector2.new(180, 180)

mist.LightEmission = 0.25
mist.LightInfluence = 0.4

mist.Size = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 12),
	NumberSequenceKeypoint.new(0.5, 25),
	NumberSequenceKeypoint.new(1, 35),
})

mist.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.25, 0.83),
	NumberSequenceKeypoint.new(0.75, 0.88),
	NumberSequenceKeypoint.new(1, 1),
})

mist.Rotation = NumberRange.new(0, 360)
mist.RotSpeed = NumberRange.new(-8, 8)

mist.Parent = mistSource

-- =====================================
-- FRAGMENTOS ORBITAIS
-- =====================================

local fragments = {}

for i = 1, CONFIG.FragmentCount do

	local model = crystal(
		root,
		Vector3.zero,
		rng:NextNumber(1.2, 2.5),
		i % 2 == 0 and C.Purple or C.Cyan
	)

	model.ModelStreamingMode =
		Enum.ModelStreamingMode.Persistent

	table.insert(fragments, {
		Model = model,

		Angle = i
			/ CONFIG.FragmentCount
			* math.pi * 2,

		Radius = rng:NextNumber(25, 53),
		Height = rng:NextNumber(-60, 60),
		Speed = rng:NextNumber(0.1, 0.3),
	})
end

-- =====================================
-- ANIMACAO
-- =====================================

local elapsed = 0
local accumulator = 0

local function update(dt)

	elapsed += dt

	local float = math.sin(
		elapsed * CONFIG.FloatSpeed
	) * CONFIG.FloatHeight

	local position =
		CONFIG.Position + Vector3.new(
			0, float, 0
		)

	-- Rotacao suave, sem girar demais.

	local rotation =
		math.sin(
			elapsed * CONFIG.RotationSpeed
		) * 0.45

	sword:PivotTo(
		CFrame.new(position)
			* CFrame.Angles(
				0,
				rotation,
				math.rad(-7)
			)
	)

	-- Aneis com movimentos independentes.

	for _, ring in ipairs(rings) do

		ring.Model:PivotTo(
			CFrame.new(
				position + Vector3.new(
					0, ring.Height, 0
				)
			)
				* CFrame.Angles(
					0,
					elapsed * ring.Speed,
					math.rad(ring.Tilt)
				)
		)
	end

	-- Cristais orbitando.

	for _, data in ipairs(fragments) do

		local angle =
			data.Angle + elapsed * data.Speed

		local offset = Vector3.new(
			math.cos(angle) * data.Radius,

			data.Height + math.sin(
				elapsed + data.Angle
			) * 4,

			math.sin(angle) * data.Radius
		)

		data.Model:PivotTo(
			CFrame.new(position + offset)
				* CFrame.Angles(
					elapsed * 0.2,
					angle,
					elapsed * 0.15
				)
		)
	end
end

-- Posicionar tudo imediatamente.

update(0)

-- Atualizacao limitada para desempenho.

local connection

connection = RunService.Heartbeat:Connect(
	function(dt)

		if not root.Parent then
			connection:Disconnect()
			return
		end

		accumulator += dt

		if accumulator >= 1 / 15 then

			update(accumulator)
			accumulator = 0
		end
	end
)

print("[AETHER V2] Spirit Realm criado!")
print("[AETHER V2] Espada e ilhas prontas!")
