-- BaseManager V27.6 | ServerScriptService (Script)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local map = Workspace:WaitForChild("SwordGameMap")
while not map:GetAttribute("MapReady") do
	map:GetAttributeChangedSignal("MapReady"):Wait()
end
-- Aguarda a geometria e os grupos de colisao antes de atribuir bases.
while not map:GetAttribute("ProtectionReady") do
	map:GetAttributeChangedSignal("ProtectionReady"):Wait()
end
local basesFolder = map:WaitForChild("Bases")
local assignedBases, occupiedBases, connections = {}, {}, {}

local function createSign(base)
	local old = base:FindFirstChild("OwnerSign")
	if old then old:Destroy() end
	local floor = base:FindFirstChild("Floor")
	if not floor then return end
	local sign = Instance.new("Part")
	sign.Name = "OwnerSign"
	sign.Size = Vector3.new(24,2.2,.5)
	sign.Anchored = true
	sign.CanCollide = false
	sign.CanTouch = false
	sign.CanQuery = false
	sign.Material = Enum.Material.SmoothPlastic
	sign.Color = Color3.fromRGB(35,40,55)
	sign.Transparency = 1
	sign.CFrame = floor.CFrame * CFrame.new(0,15.1,-floor.Size.Z/2-1.8)
	sign.Parent = base
	local gui = Instance.new("SurfaceGui")
	gui.Name = "OwnerGui"
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(720,66)
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Name = "OwnerLabel"
	label.Size = UDim2.fromScale(1,1)
	label.BackgroundTransparency = 1
	label.Text = "BASE DISPONÍVEL"
	label.TextColor3 = Color3.new(1,1,1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
end

local function updateSign(base, player)
	local sign = base:FindFirstChild("OwnerSign")
	local gui = sign and sign:FindFirstChild("OwnerGui")
	local label = gui and gui:FindFirstChild("OwnerLabel")
	if label then label.Text = player and (player.DisplayName .. "'s Base") or "BASE DISPONÍVEL" end
end

local function teleportToBase(player, character)
	local base = assignedBases[player]
	if not base then return end
	local floor = base:FindFirstChild("Floor")
	local root = character:WaitForChild("HumanoidRootPart",10)
	local humanoid = character:WaitForChild("Humanoid",10)
	if not floor or not root or not humanoid or player.Character ~= character or assignedBases[player] ~= base then return end
	local height = floor.Size.Y/2 + humanoid.HipHeight + root.Size.Y/2 + 0.5
	if humanoid.RigType == Enum.HumanoidRigType.R6 then height += 2 end
	local pos = (floor.CFrame * CFrame.new(0,height,-8)).Position
	local facing = floor.CFrame.LookVector
	local target = CFrame.lookAt(pos,pos + Vector3.new(facing.X,0,facing.Z))
	character:PivotTo(target)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	print("[BaseManager V27.6] Spawn:",player.Name,base.Name)
end

local function assignBase(player)
	if assignedBases[player] or player.Parent ~= Players then return end
	local base
	for i=1,8 do
		local candidate = basesFolder:FindFirstChild("Base"..i)
		if candidate and not occupiedBases[candidate] then base = candidate; break end
	end
	if not base then warn("Nenhuma base disponível para "..player.Name); return end
	assignedBases[player] = base
	occupiedBases[base] = player
	base:SetAttribute("OwnerUserId",player.UserId)
	updateSign(base,player)
	local spawn = base:FindFirstChild("Spawn")
	if spawn and spawn:IsA("SpawnLocation") then player.RespawnLocation = spawn end
	connections[player] = player.CharacterAdded:Connect(function(character)
		teleportToBase(player,character)
	end)
	if player.Character then task.spawn(teleportToBase,player,player.Character) end
	print(player.Name.." recebeu "..base.Name)
end

local function releaseBase(player)
	if connections[player] then connections[player]:Disconnect(); connections[player] = nil end
	local base = assignedBases[player]
	if not base then return end
	assignedBases[player] = nil
	player.RespawnLocation = nil
	occupiedBases[base] = nil
	base:SetAttribute("OwnerUserId",nil)
	updateSign(base,nil)
end

for _,base in ipairs(basesFolder:GetChildren()) do
	if base:IsA("Model") then createSign(base) end
end
Players.PlayerAdded:Connect(assignBase)
Players.PlayerRemoving:Connect(releaseBase)
for _,player in ipairs(Players:GetPlayers()) do task.spawn(assignBase,player) end
print("[BaseManager V27.6] Pronto!")
