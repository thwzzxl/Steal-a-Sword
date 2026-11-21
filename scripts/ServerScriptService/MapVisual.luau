-- MapVisual V43.1 | ServerScriptService > Script
-- Visual only. No geometry, collision, data or gameplay changes.
local Lighting = game:GetService("Lighting")
local map = workspace:WaitForChild("SwordGameMap")
while not map:GetAttribute("MapReady") do map:GetAttributeChangedSignal("MapReady"):Wait() end
local bases = map:WaitForChild("Bases")
local arena = map:WaitForChild("Arena")
local decor = map:WaitForChild("Decorations")
local rgb = Color3.fromRGB
local function finish(p, color, material)
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
end
local function baseVisual(p)
	if not p:IsA("BasePart") then return end
	local n = p.Name
	-- Only architecture: keep sword, player, laser and stand effects intact.
	if n:find("Roof") or n:find("Floor") or n == "ThirdLanding" or n == "LandingFinish" then
		p.CastShadow = false
		if n:find("Roof") and not n:find("Fill") and not n:find("Edge") then
			finish(p,rgb(49,65,86),Enum.Material.SmoothPlastic)
		elseif n:find("Floor") or n == "ThirdLanding" or n == "LandingFinish" then
			finish(p,rgb(211,221,231),Enum.Material.SmoothPlastic)
		end
	elseif n:find("Window") and p.Material == Enum.Material.Glass then
		p.CastShadow = false
		p.Color = rgb(164,215,240)
	elseif n == "CenterWalkway" then
		finish(p,rgb(174,190,207),Enum.Material.Concrete)
	elseif n == "BackWall" or n == "SideWall" or n == "SideWallTop" or n == "EntranceColumn" or n == "EntranceHeader" or n:match("^Upper.*Header$") or n:match("^Third.*Header$") or n == "UpperBack" or n == "ThirdBack" or n:match("^Upper.*Sill$") or n:match("^Third.*Sill$") then
		finish(p,rgb(75,94,117),Enum.Material.SmoothPlastic)
		p.CastShadow = false
	elseif n == "TileJoint" then
		p.Color = rgb(181,195,209)
	end
end
bases.DescendantAdded:Connect(function(p) task.defer(function() if p:IsDescendantOf(bases) then baseVisual(p) end end) end)
for _,p in ipairs(bases:GetDescendants()) do baseVisual(p) end
local ground = map:FindFirstChild("Ground")
if ground and ground:IsA("BasePart") then finish(ground,rgb(104,174,83),Enum.Material.Grass) end
for _,p in ipairs(map:GetChildren()) do
	if p:IsA("BasePart") and p.Name:match("^Path%d+$") then finish(p,rgb(191,198,207),Enum.Material.Concrete) end
end
for _,p in ipairs(arena:GetDescendants()) do
	if p:IsA("BasePart") then
		if p.Name == "ConveyorBelt" then finish(p,rgb(182,47,61),Enum.Material.SmoothPlastic)
		elseif p.Name == "ConveyorSidewalk" then finish(p,rgb(184,197,210),Enum.Material.Concrete)
		elseif p.Name == "ConveyorBorder" then finish(p,rgb(218,228,239),Enum.Material.Metal)
		elseif p.Name == "ConveyorYellowLine" then p.Color = rgb(240,195,75) end
	end
end
for _,p in ipairs(decor:GetDescendants()) do
	if p:IsA("BasePart") then
		if p.Name == "PathJoint" then p.Color = rgb(161,173,186)
		elseif p.Name == "PathBorder" then p.Color = rgb(218,226,233)
		elseif p.Name == "TunnelRoof" or p.Name == "RoofTrim" then p.CastShadow = false end
	end
end
-- V43.1: daylight without dynamic shadows; preserve gameplay effects.
local function applyLighting()
	Lighting.ClockTime = 12.5
	Lighting.Brightness = 1.65
	Lighting.ExposureCompensation = -0.05
	Lighting.Ambient = rgb(175,183,195)
	Lighting.OutdoorAmbient = rgb(175,183,195)
	Lighting.GlobalShadows = false
end
applyLighting()
-- Prevent another lighting script from restoring sun shadows.
Lighting:GetPropertyChangedSignal("GlobalShadows"):Connect(function()
	if Lighting.GlobalShadows then Lighting.GlobalShadows = false end
end)
local function optimize(p)
	if not p:IsA("Light") then return end
	local parent = p.Parent
	if not parent then return end
	-- Only known architectural lights, not swords, forge or event effects.
	if parent.Name == "InteriorLamp" or parent.Name == "LampLens" then
		p.Shadows = false
		-- Daylight already illuminates the entire map; keep the lamp meshes.
		p.Enabled = false
	end
end
map.DescendantAdded:Connect(function(p)
	if p:IsA("Light") then task.defer(function()
			if p:IsDescendantOf(map) then optimize(p) end
		end) end
end)
for _,p in ipairs(map:GetDescendants()) do optimize(p) end
print("[MapVisual V43.1] Sombras desativadas; luzes decorativas otimizadas.")
