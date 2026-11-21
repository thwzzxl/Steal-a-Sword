
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local map = Workspace:WaitForChild("SwordGameMap")

-- PALETA DE CORES
local COLORS = {
	Grass = Color3.fromRGB(91, 195, 83),
	Arena = Color3.fromRGB(155, 158, 165),
	Center = Color3.fromRGB(85, 90, 105),
	Pedestal = Color3.fromRGB(65, 70, 85),
	BaseFloor = Color3.fromRGB(218, 223, 232),
	Wall = Color3.fromRGB(245, 247, 250),
	Stand = Color3.fromRGB(95, 100, 115),
	Trim = Color3.fromRGB(255, 205, 70),
	Path = Color3.fromRGB(220, 205, 175)
}

local function stylePart(part)
	if not part:IsA("BasePart") then
		return
	end

	-- Remove aparência realista
	part.Material = Enum.Material.SmoothPlastic
	part.MaterialVariant = ""
	part.Reflectance = 0
	part.CastShadow = true

	if part.Name == "Ground" then
		part.Color = COLORS.Grass

	elseif part.Name == "ArenaFloor" then
		part.Color = COLORS.Arena

	elseif part.Name == "CenterPlatform" then
		part.Color = COLORS.Center

	elseif part.Name == "SwordPedestal" then
		part.Color = COLORS.Pedestal

	elseif part.Name == "Floor" then
		part.Color = COLORS.BaseFloor

	elseif part.Name == "BackWall"
		or part.Name == "SideWall" then
		part.Color = COLORS.Wall

	elseif part.Name:match("^Stand_%d+_%d+$") then
		part.Color = COLORS.Stand

	elseif part.Name == "StandTrim" then
		part.Color = COLORS.Trim
		part.Material = Enum.Material.Neon

	elseif part.Name:match("^Path%d+$") then
		part.Color = COLORS.Path

	elseif part.Name == "LockButton" then
		part.Color = Color3.fromRGB(255, 70, 70)
		part.Material = Enum.Material.Neon
	end
end

-- APLICA VISUAL EM TODO O MAPA
for _, object in ipairs(map:GetDescendants()) do
	stylePart(object)
end


-- ILUMINAÇÃO SUAVE
Lighting.ClockTime = 14
Lighting.Brightness = 1.5
Lighting.GlobalShadows = true

Lighting.Ambient = Color3.fromRGB(125, 125, 125)
Lighting.OutdoorAmbient = Color3.fromRGB(145, 145, 145)

Lighting.ExposureCompensation = -0.2
Lighting.EnvironmentDiffuseScale = 0.5
Lighting.EnvironmentSpecularScale = 0.3

-- ATMOSFERA LIMPA
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")

if atmosphere then
	atmosphere.Density = 0.05
	atmosphere.Haze = 0
	atmosphere.Glare = 0
end

-- CORREÇÃO DE CORES
local colorCorrection = Lighting:FindFirstChild("SwordGameColors")

if not colorCorrection then
	colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Name = "SwordGameColors"
	colorCorrection.Parent = Lighting
end

colorCorrection.Brightness = 0
colorCorrection.Contrast = 0.02
colorCorrection.Saturation = 0.05
colorCorrection.TintColor = Color3.fromRGB(255, 255, 255)

print("Iluminação V3.1 aplicada com sucesso!")
