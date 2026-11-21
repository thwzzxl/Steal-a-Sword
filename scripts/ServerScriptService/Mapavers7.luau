
-- MAP VISUAL V7
-- ROUBE UMA ESPADA
-- Tema: Sword Kingdom
-- Local: ServerScriptService
-- Mantenha o MapGenerator V6 ativo!

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local map = Workspace:WaitForChild("SwordGameMap")
local bases = map:WaitForChild("Bases")
local arena = map:WaitForChild("Arena")

-- PALETA

local C = {
	Grass = Color3.fromRGB(75, 185, 55),
	Stone = Color3.fromRGB(125, 145, 170),
	LightStone = Color3.fromRGB(185, 198, 215),
	DarkStone = Color3.fromRGB(53, 66, 87),
	Trim = Color3.fromRGB(75, 91, 118),

	Gold = Color3.fromRGB(255, 195, 48),
	DarkGold = Color3.fromRGB(181, 118, 25),

	Wood = Color3.fromRGB(153, 96, 52),
	DarkWood = Color3.fromRGB(91, 55, 32),

	Path = Color3.fromRGB(197, 174, 133),
	Red = Color3.fromRGB(185, 42, 55),
	Blue = Color3.fromRGB(55, 120, 215),
}

-- AGUARDAR MAPA COMPLETO

for i = 1, 8 do
	local base = bases:WaitForChild("Base" .. i)
	base:WaitForChild("Floor")

	local stands = base:WaitForChild("SwordStands")

	for side = 1, 2 do
		for slot = 1, 5 do
			stands:WaitForChild(
				"Stand_" .. side .. "_" .. slot
			)
		end
	end

	map:WaitForChild("Path" .. i)
end

-- PASTA DE DECORACAO

local old = map:FindFirstChild("VisualV7")

if old then
	old:Destroy()
end

local decor = Instance.new("Folder")
decor.Name = "VisualV7"
decor.Parent = map

-- CRIAR PECAS DECORATIVAS

local function part(
	name, size, cf, color, material, parent
)
	local p = Instance.new("Part")

	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic

	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false

	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth

	p.CastShadow = true
	p.Parent = parent or decor

	return p
end

local function studs(p)
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Studs
end

-- ILUMINACAO CARTOON

Lighting.ClockTime = 13.5
Lighting.Brightness = 2
Lighting.ExposureCompensation = -0.1

Lighting.Ambient = Color3.fromRGB(145, 145, 155)
Lighting.OutdoorAmbient = Color3.fromRGB(165, 175, 190)

Lighting.GlobalShadows = true
Lighting.ShadowSoftness = 0.3

local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")

if atmosphere then
	atmosphere.Density = 0.15
	atmosphere.Haze = 0.15
	atmosphere.Glare = 0

	atmosphere.Color =
		Color3.fromRGB(205, 230, 255)
end

local bloom = Lighting:FindFirstChild("SwordBloom")

if bloom then
	bloom.Intensity = 0.08
	bloom.Size = 10
	bloom.Threshold = 2.5
end

local correction = Lighting:FindFirstChild("SwordColorV7")

if not correction then
	correction = Instance.new("ColorCorrectionEffect")
	correction.Name = "SwordColorV7"
	correction.Parent = Lighting
end

correction.Saturation = 0.12
correction.Contrast = 0.04
correction.Brightness = 0
correction.TintColor = Color3.fromRGB(255, 250, 240)

-- NUVENS

local clouds = Workspace.Terrain:FindFirstChild("SwordClouds")

if not clouds then
	clouds = Instance.new("Clouds")
	clouds.Name = "SwordClouds"
	clouds.Parent = Workspace.Terrain
end

clouds.Cover = 0.4
clouds.Density = 0.6
clouds.Color = Color3.fromRGB(255, 255, 255)

-- GRAMA CLASSICA

local ground = map:WaitForChild("Ground")

ground.Color = C.Grass
studs(ground)

-- CAMINHOS

for i = 1, 8 do
	local path = map:FindFirstChild("Path" .. i)

	if path then
		path.Color = C.Path
		path.Material = Enum.Material.Cobblestone

		-- Conecta o caminho ate a arena.
		path.Size = Vector3.new(14, 0.25, 140)

		for _, side in ipairs({-1, 1}) do
			part(
				"PathBorder",
				Vector3.new(0.7, 0.15, path.Size.Z),
				path.CFrame * CFrame.new(
					side * 6.65, 0.18, 0
				),
				C.DarkGold,
				Enum.Material.SmoothPlastic
			)
		end
	end
end

-- ARENA CENTRAL

local arenaFloor = arena:WaitForChild("ArenaFloor")
local center = arena:WaitForChild("CenterPlatform")
local pedestal = arena:WaitForChild("SwordPedestal")

arenaFloor.Color = C.LightStone
arenaFloor.Material = Enum.Material.Cobblestone

center.Color = C.DarkStone
center.Material = Enum.Material.Slate

pedestal.Color = C.Trim
pedestal.Material = Enum.Material.Marble

-- BORDA CIRCULAR DA ARENA

local function cylinder(name, diameter, height, y, color)
	local p = part(
		name,
		Vector3.new(height, diameter, diameter),
		CFrame.new(0, y, 0)
			* CFrame.Angles(0, 0, math.rad(90)),
		color,
		Enum.Material.SmoothPlastic
	)

	p.Shape = Enum.PartType.Cylinder

	return p
end

-- Camadas abaixo da superficie original.

cylinder("ArenaGoldBorder", 153, 0.3, 0.25, C.Gold)
cylinder("ArenaDarkBorder", 155, 0.35, 0.05, C.DarkStone)

-- Detalhes do pedestal central.

part(
	"PedestalGoldTop",
	Vector3.new(8.5, 0.35, 8.5),
	CFrame.new(0, 6.35, 0),
	C.Gold,
	Enum.Material.Metal
)

part(
	"PedestalGoldBottom",
	Vector3.new(9, 0.35, 9),
	CFrame.new(0, 2.4, 0),
	C.DarkGold,
	Enum.Material.Metal
)

-- ESPADAS GIGANTES DECORATIVAS

local function decorativeSword(cf, scale, parent)
	local function sp(name, size, offset, color, material)
		return part(
			name,
			size * scale,
			cf * CFrame.new(offset * scale),
			color,
			material,
			parent
		)
	end

	sp(
		"Handle",
		Vector3.new(0.8, 2.6, 0.8),
		Vector3.new(0, 0, 0),
		C.DarkWood,
		Enum.Material.Wood
	)

	sp(
		"Pommel",
		Vector3.new(1.2, 0.6, 1.2),
		Vector3.new(0, -1.5, 0),
		C.Gold,
		Enum.Material.Metal
	)

	sp(
		"Guard",
		Vector3.new(4.3, 0.65, 1.1),
		Vector3.new(0, 1.5, 0),
		C.Gold,
		Enum.Material.Metal
	)

	sp(
		"Blade",
		Vector3.new(1.3, 6.5, 0.5),
		Vector3.new(0, 5, 0),
		Color3.fromRGB(210, 235, 255),
		Enum.Material.Metal
	)

	sp(
		"BladeCenter",
		Vector3.new(0.35, 6.2, 0.56),
		Vector3.new(0, 5, 0),
		Color3.fromRGB(110, 175, 225),
		Enum.Material.SmoothPlastic
	)

	local tip = Instance.new("WedgePart")
	tip.Name = "BladeTip"
	tip.Size = Vector3.new(1.3, 1.4, 0.5) * scale
	tip.CFrame = cf * CFrame.new(0, 8.9 * scale, 0)
	tip.Color = Color3.fromRGB(210, 235, 255)
	tip.Material = Enum.Material.Metal
	tip.Anchored = true
	tip.CanCollide = false
	tip.CanTouch = false
	tip.CanQuery = false
	tip.Parent = parent
end

-- Espada monumental no centro.

decorativeSword(
	CFrame.new(0, 9, 0)
		* CFrame.Angles(0, math.rad(45), 0),
	2,
	decor
)

-- PILARES DA ARENA

-- Entre os caminhos, fora da area de spawn das espadas.

for i = 1, 8 do
	local angle = math.rad(
		(i - 1) * 45 + 22.5
	)

	local x = math.cos(angle) * 64
	local z = math.sin(angle) * 64

	local cf = CFrame.lookAt(
		Vector3.new(x, 0, z),
		Vector3.zero
	)

	local function ap(name, size, offset, color)
		return part(
			name,
			size,
			cf * CFrame.new(offset),
			color,
			Enum.Material.SmoothPlastic
		)
	end

	ap(
		"PillarBase",
		Vector3.new(7, 1, 7),
		Vector3.new(0, 1.7, 0),
		C.DarkStone
	)

	ap(
		"Pillar",
		Vector3.new(4.5, 9, 4.5),
		Vector3.new(0, 6.7, 0),
		C.Stone
	)

	ap(
		"PillarGoldTrim",
		Vector3.new(5.2, 0.65, 5.2),
		Vector3.new(0, 11.4, 0),
		C.Gold
	)

	ap(
		"PillarTop",
		Vector3.new(6, 1.2, 6),
		Vector3.new(0, 12.2, 0),
		C.DarkStone
	)

	-- Pequeno cristal no topo.

	local gem = ap(
		"PillarGem",
		Vector3.new(2, 2, 2),
		Vector3.new(0, 14, 0),
		Color3.fromRGB(85, 205, 255)
	)

	gem.CFrame *= CFrame.Angles(
		math.rad(45), 0, math.rad(45)
	)

	gem.Material = Enum.Material.Neon
end

-- MELHORAR AS BASES

local function styleBase(base, index)
	local floor = base:WaitForChild("Floor")
	local cf = floor.CFrame

	floor.Color = C.LightStone
	studs(floor)

	local walkway = base:FindFirstChild("CenterWalkway")

	if walkway then
		walkway.Color = Color3.fromRGB(165, 180, 200)
		walkway.Material = Enum.Material.Cobblestone
	end

	-- PAREDES E ACABAMENTOS

	for _, p in ipairs(base:GetChildren()) do
		if p:IsA("BasePart") then

			if p.Name == "BackWall"
				or p.Name == "SideWall" then

				p.Color = C.Stone
				p.Material = Enum.Material.Brick

			elseif p.Name == "WallTopTrim"
				or p.Name == "BackTopTrim"
				or p.Name == "WallBottomTrim" then

				p.Color = C.DarkStone
				p.Material = Enum.Material.SmoothPlastic
			end
		end
	end

	-- DECORACOES LOCAIS DA BASE

	local folder = Instance.new("Folder")
	folder.Name = base.Name .. "_Decor"
	folder.Parent = decor

	local function bp(name, size, offset, color, material)
		return part(
			name,
			size,
			cf * CFrame.new(offset),
			color,
			material,
			folder
		)
	end

	-- PILARES NA ENTRADA E NO FUNDO

	for _, side in ipairs({-1, 1}) do
		for _, z in ipairs({-30, 0, 30}) do

			bp(
				"WallPillar",
				Vector3.new(3.5, 10, 3.5),
				Vector3.new(side * 36, 5, z),
				C.DarkStone,
				Enum.Material.Brick
			)

			bp(
				"PillarFoot",
				Vector3.new(4.5, 0.7, 4.5),
				Vector3.new(side * 36, 0.85, z),
				C.Trim
			)

			bp(
				"PillarGold",
				Vector3.new(4.3, 0.6, 4.3),
				Vector3.new(side * 36, 10.2, z),
				C.Gold
			)

			bp(
				"PillarCap",
				Vector3.new(4.8, 0.8, 4.8),
				Vector3.new(side * 36, 10.9, z),
				C.DarkStone
			)
		end
	end

	-- FAIXAS DOURADAS NAS PAREDES

	for _, side in ipairs({-1, 1}) do
		bp(
			"WallGoldLine",
			Vector3.new(0.2, 0.4, 62),
			Vector3.new(side * 36.9, 7.7, 0),
			C.Gold,
			Enum.Material.Metal
		)
	end

	-- BANDEIRAS MEDIEVAIS

	local bannerColor = index % 2 == 0
		and C.Blue or C.Red

	for _, x in ipairs({-23, 23}) do
		bp(
			"Banner",
			Vector3.new(7, 8, 0.2),
			Vector3.new(x, 7, 30.85),
			bannerColor,
			Enum.Material.Fabric
		)

		bp(
			"BannerGoldTop",
			Vector3.new(8, 0.5, 0.6),
			Vector3.new(x, 11.2, 30.6),
			C.Gold,
			Enum.Material.Metal
		)

		bp(
			"BannerGoldBottom",
			Vector3.new(7, 0.5, 0.3),
			Vector3.new(x, 3.2, 30.7),
			C.Gold,
			Enum.Material.Metal
		)

		local emblem = bp(
			"BannerEmblem",
			Vector3.new(2.5, 2.5, 0.25),
			Vector3.new(x, 7.5, 30.6),
			C.Gold
		)

		emblem.CFrame *= CFrame.Angles(
			0, 0, math.rad(45)
		)
	end

	-- EXPOSITORES

	local stands = base:WaitForChild("SwordStands")

	for _, p in ipairs(stands:GetChildren()) do
		if p:IsA("BasePart") then

			if p.Name:match("^Stand_%d+_%d+$") then
				p.Color = C.DarkStone
				studs(p)

				-- Base decorativa sob o expositor.

				part(
					"StandFoundation",
					Vector3.new(
						p.Size.X + 0.6,
						0.22,
						p.Size.Z + 0.6
					),
					p.CFrame * CFrame.new(0, -0.35, 0),
					C.Trim,
					Enum.Material.SmoothPlastic,
					folder
				)

				-- Detalhe dourado nos cantos.

				for _, sx in ipairs({-1, 1}) do
					for _, sz in ipairs({-1, 1}) do
						part(
							"StandCorner",
							Vector3.new(0.65, 0.4, 0.65),
							p.CFrame * CFrame.new(
								sx * (p.Size.X / 2 - 0.4),
								0.38,
								sz * (p.Size.Z / 2 - 0.4)
							),
							C.Gold,
							Enum.Material.Metal,
							folder
						)
					end
				end

			elseif p.Name:match("^Trim") then
				p.Color = C.Gold
				p.Material = Enum.Material.Metal

			elseif p.Name == "SwordDisplaySupport" then
				p.Color = C.DarkGold
				p.Material = Enum.Material.Metal
			end
		end
	end

	-- PLACA DO DONO

	local function styleSign(sign)
		if not sign:IsA("BasePart") then
			return
		end

		sign.Color = C.Wood
		sign.Material = Enum.Material.WoodPlanks

		for _, child in ipairs(sign:GetDescendants()) do
			if child:IsA("TextLabel") then
				child.Font = Enum.Font.FredokaOne
				child.TextColor3 = Color3.new(1, 1, 1)
				child.TextStrokeColor3 = C.DarkWood
				child.TextStrokeTransparency = 0.15
			end
		end

		local oldFrame = sign:FindFirstChild("GoldFrameV7")

		if oldFrame then
			oldFrame:Destroy()
		end

		local frame = Instance.new("Folder")
		frame.Name = "GoldFrameV7"
		frame.Parent = sign

		local w = sign.Size.X
		local h = sign.Size.Y
		local d = sign.Size.Z

		for _, side in ipairs({-1, 1}) do
			part(
				"Horizontal",
				Vector3.new(w + 0.5, 0.4, d + 0.3),
				sign.CFrame * CFrame.new(
					0, side * h / 2, 0
				),
				C.Gold,
				Enum.Material.Metal,
				frame
			)

			part(
				"Vertical",
				Vector3.new(0.4, h, d + 0.3),
				sign.CFrame * CFrame.new(
					side * w / 2, 0, 0
				),
				C.Gold,
				Enum.Material.Metal,
				frame
			)
		end
	end

	local sign = base:FindFirstChild("OwnerSign")

	if sign then
		styleSign(sign)
	end

	-- Funciona tambem se o sistema de bases
	-- criar ou substituir a placa depois.

	base.ChildAdded:Connect(function(child)
		if child.Name == "OwnerSign" then
			task.defer(function()
				if child.Parent then
					styleSign(child)
				end
			end)
		end
	end)

	print("[MapVisualV7] " .. base.Name .. " atualizada!")
end

for i = 1, 8 do
	local base = bases:WaitForChild("Base" .. i)
	styleBase(base, i)
end

-- ARVORES CARTOON

local function createTree(x, z, scale)
	local cf = CFrame.new(x, 0, z)

	part(
		"TreeTrunk",
		Vector3.new(2.5, 9, 2.5) * scale,
		cf * CFrame.new(0, 4.5 * scale, 0),
		C.Wood,
		Enum.Material.Wood
	)

	local leaves = part(
		"TreeLeaves",
		Vector3.new(10, 10, 10) * scale,
		cf * CFrame.new(0, 11 * scale, 0),
		Color3.fromRGB(48, 155, 65),
		Enum.Material.SmoothPlastic
	)

	leaves.Shape = Enum.PartType.Ball

	local top = part(
		"TreeTop",
		Vector3.new(7, 7, 7) * scale,
		cf * CFrame.new(0, 15 * scale, 0),
		Color3.fromRGB(80, 195, 75),
		Enum.Material.SmoothPlastic
	)

	top.Shape = Enum.PartType.Ball
end

-- Arvores nas bordas, longe das bases.

for i = 1, 16 do
	local angle = math.rad(
		(i - 1) * 22.5 + 11.25
	)

	createTree(
		math.cos(angle) * 282,
		math.sin(angle) * 282,
		1
	)
end

print("[MapVisualV7] SWORD KINGDOM CONCLUIDO!")
