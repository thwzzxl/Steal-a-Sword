-- EVENT GUI V17.4 | LocalScript em StarterPlayerScripts
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local state = RS:WaitForChild("EventSystemState")
local map = Workspace:WaitForChild("SwordGameMap")
local ground = map:WaitForChild("Ground", 15)
local old = pg:FindFirstChild("EventGUI")
if old then old:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "EventGUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 15
gui.Parent = pg
local timer = Instance.new("TextLabel")
timer.Name = "EventTimer"
timer.AnchorPoint = Vector2.new(.5, 0)
timer.Position = UDim2.new(.5, 0, 0, 4)
timer.BackgroundColor3 = Color3.fromRGB(35,40,50)
timer.BackgroundTransparency = .08
timer.BorderSizePixel = 0
timer.Font = Enum.Font.GothamBold
timer.TextColor3 = Color3.new(1,1,1)
timer.TextScaled = false
timer.TextWrapped = false
timer.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 7)
corner.Parent = timer
local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0,8)
padding.PaddingRight = UDim.new(0,8)
padding.Parent = timer
local textLimit = Instance.new("UITextSizeConstraint")
textLimit.MinTextSize = 9
textLimit.Parent = timer
local function resize()
	local size = gui.AbsoluteSize
	local compact = UIS.TouchEnabled or size.Y < 500 or size.X < 700
	timer.Size = UDim2.fromOffset(math.max(100, math.min(compact and 220 or 320, size.X * .48)), compact and 24 or 32)
	timer.TextSize = compact and 13 or 16
	textLimit.MaxTextSize = 18
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
resize()
local info = {
	Lucky={Name="LUCKY HOUR",Mult="2x",Color=Color3.fromRGB(38,120,65),Tint=Color3.fromRGB(210,255,220)},
	Infernal={Name="INFERNAL",Mult="8x",Color=Color3.fromRGB(150,48,28),Tint=Color3.fromRGB(255,185,150)},
	Celestial={Name="CELESTIAL",Mult="12x",Color=Color3.fromRGB(65,55,150),Tint=Color3.fromRGB(190,195,255)}
}
local oldTint = Lighting:FindFirstChild("SwordEventTint")
if oldTint then oldTint:Destroy() end
local correction = Instance.new("ColorCorrectionEffect")
correction.Name = "SwordEventTint"
correction.Enabled = false
correction.Parent = Lighting
local previous = nil
local startedUntil = 0
while gui.Parent do
	local event = state:GetAttribute("ActiveEvent") or "None"
	local data = info[event]
	local remaining = math.max(0, math.ceil((state:GetAttribute("EndsAt") or 0) - Workspace:GetServerTimeNow()))
	local clock = string.format("%02d:%02d", math.floor(remaining/60), remaining%60)
	if event ~= previous then
		startedUntil = previous ~= nil and data and os.clock()+3 or 0
		previous = event
	end
	if data then
		timer.Text = data.Name .. " | " .. data.Mult .. " | " .. clock
		if os.clock() < startedUntil then timer.Text = data.Name .. " ATIVO! | " .. data.Mult end
	else
		timer.Text = "Próximo evento: " .. clock
	end
	timer.BackgroundColor3 = data and data.Color or Color3.fromRGB(35,40,50)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local onIsland = false
	if ground and ground:IsA("BasePart") and root then
		local pos = ground.CFrame:PointToObjectSpace(root.Position)
		onIsland = math.abs(pos.X) <= ground.Size.X/2 and math.abs(pos.Z) <= ground.Size.Z/2 and pos.Y >= -10 and pos.Y <= 60
	end
	correction.Enabled = data ~= nil and onIsland
	if data then
		correction.TintColor = data.Tint
		correction.Contrast = .08
		correction.Saturation = .1
	end
	task.wait(.25)
end
correction:Destroy()
