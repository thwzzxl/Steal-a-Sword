--[[
	CelestialAurora (LocalScript)
	Local: StarterPlayer > StarterPlayerScripts

	Cortina de aurora celestial feita de faixas com SurfaceGui + UIGradient.
	Fica atrás da espada Aether (vista a partir do centro do mapa).
]]

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

--------------------------------------------------------------------
-- CONFIGURAÇÃO (ajuste aqui, sem mexer no resto do código)
--------------------------------------------------------------------
local CONFIG = {
	-- Localização da espada: nomes tentados em ordem dentro do Workspace
	SwordNames = { "Aether", "SpiritSword", "AetherSword", "SpiritSwordAether" },
	SearchTimeout = 6, -- segundos procurando a espada antes de usar o fallback
	FallbackSwordPosition = Vector3.new(0, 350, -600),
	MapCenter = Vector3.new(0, 0, 0), -- ponto de onde os jogadores "olham"

	-- Posição e tamanho da cortina
	DistanceBehindSword = 260, -- studs atrás da espada (aumente se cortar ilhas)
	Width = 900,
	Height = 320,
	BaseHeightOffset = -40, -- altura da base em relação à espada
	Bow = 0.6, -- curvatura: bordas avançam em direção ao mapa

	-- Estrutura
	Strips = 80,
	Overlap = 1.4, -- sobreposição das faixas (esconde emendas)

	-- Aparência
	Opacity = 0.85, -- opacidade máxima geral (0 a 1)
	Brightness = 1.6, -- brilho do SurfaceGui (reduza se estiver forte)
	EdgeFade = 0.2, -- fração da largura usada no desvanecer lateral
	ColorSpread = 0.9, -- variação de cor ao longo da cortina

	-- Animação
	Speed = 1, -- multiplicador global (menor = mais lento)
	ColorUpdateRate = 15, -- atualizações de cor por segundo

	-- Aurora antiga: partes com estes trechos no nome ficam invisíveis (só no cliente)
	OldAuroraKeywords = { "aurora" },
}

local PALETTE = {
	Color3.fromRGB(70, 225, 255), -- ciano
	Color3.fromRGB(60, 110, 255), -- azul
	Color3.fromRGB(150, 90, 255), -- roxo
	Color3.fromRGB(60, 110, 255), -- azul (fecha o ciclo)
}

-- Transparência vertical (0 = topo, 1 = base): brilha embaixo, some para cima
local VERTICAL_ALPHA = NumberSequence.new({
	NumberSequenceKeypoint.new(0.00, 1.00),
	NumberSequenceKeypoint.new(0.25, 0.90),
	NumberSequenceKeypoint.new(0.60, 0.72),
	NumberSequenceKeypoint.new(0.85, 0.52),
	NumberSequenceKeypoint.new(0.95, 0.75),
	NumberSequenceKeypoint.new(1.00, 1.00),
})

--------------------------------------------------------------------
-- UTILIDADES
--------------------------------------------------------------------
local function smoothstep(x)
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

local function samplePalette(x)
	local n = #PALETTE
	local scaled = (x % 1) * n
	local index = math.floor(scaled)
	local frac = scaled - index
	local a = PALETTE[index % n + 1]
	local b = PALETTE[(index + 1) % n + 1]
	return a:Lerp(b, frac)
end

local function noise01(x, y, z)
	return math.clamp(0.5 + math.noise(x, y, z) * 0.9, 0, 1)
end

local function getPosition(inst)
	if inst:IsA("Model") then
		return inst:GetPivot().Position
	elseif inst:IsA("BasePart") then
		return inst.Position
	end
	return nil
end

local function findSwordPosition()
	local deadline = os.clock() + CONFIG.SearchTimeout
	repeat
		for _, name in ipairs(CONFIG.SwordNames) do
			local found = Workspace:FindFirstChild(name, true)
			local position = found and getPosition(found)
			if position then
				return position
			end
		end
		task.wait(0.5)
	until os.clock() > deadline
	return CONFIG.FallbackSwordPosition
end

--------------------------------------------------------------------
-- PASTA DA AURORA + LIMPEZA DA AURORA ANTIGA
--------------------------------------------------------------------
local folder = Instance.new("Folder")
folder.Name = "_CelestialAurora"
folder.Parent = Workspace

local function isOldAurora(inst)
	if inst == folder or inst:IsDescendantOf(folder) then
		return false
	end
	local lowered = inst.Name:lower()
	for _, keyword in ipairs(CONFIG.OldAuroraKeywords) do
		if lowered:find(keyword, 1, true) then
			return true
		end
	end
	return false
end

local function hideOldAurora(inst)
	if not isOldAurora(inst) then
		return
	end
	if inst:IsA("BasePart") then
		inst.Transparency = 1
	else
		for _, descendant in ipairs(inst:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.Transparency = 1
			end
		end
	end
end

for _, inst in ipairs(Workspace:GetDescendants()) do
	hideOldAurora(inst)
end
Workspace.DescendantAdded:Connect(hideOldAurora)

--------------------------------------------------------------------
-- GEOMETRIA DA CORTINA
--------------------------------------------------------------------
local swordPosition = findSwordPosition()

local toSword = swordPosition - CONFIG.MapCenter
toSword = Vector3.new(toSword.X, 0, toSword.Z)
local away = toSword.Magnitude > 1 and toSword.Unit or Vector3.new(0, 0, -1)

local UP = Vector3.yAxis
local forward = -away -- em direção ao mapa (lado de quem olha)
local right = away:Cross(UP).Unit
local origin = swordPosition + away * CONFIG.DistanceBehindSword
local baseY = swordPosition.Y + CONFIG.BaseHeightOffset

-- Posição horizontal da cortina (sem altura) para o parâmetro u em [0, 1]
local function curtainPoint(u, t)
	local x = (u - 0.5) * CONFIG.Width
	local z = CONFIG.Bow * CONFIG.Width * (u - 0.5) ^ 2
		+ 55 * math.sin(u * 8.0 + t * 0.35)
		+ 14 * math.sin(u * 17.0 - t * 0.22 + 1.7)
	return origin + right * x + forward * z
end

-----