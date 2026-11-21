-- LuckyHourGUI V1 | LocalScript em StarterPlayerScripts
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local state = RS:WaitForChild("LuckyHourState")
local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
local gui = Instance.new("ScreenGui")
gui.Name = "LuckyHourGUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 15
gui.Parent = pg
local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(.5,0)
label.Position = UDim2.new(.5,0,0,8)
label.Size = UDim2.new(.85,0,0,38)
label.BackgroundColor3 = Color3.fromRGB(30,42,38)
label.TextColor3 = Color3.fromRGB(210,255,220)
label.Font = Enum.Font.GothamBold
label.TextSize = 15
label.Parent = gui
local limit = Instance.new("UISizeConstraint")
limit.MaxSize = Vector2.new(340,38)
limit.Parent = label
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0,10)
corner.Parent = label
local banner = Instance.new("TextLabel")
banner.AnchorPoint = Vector2.new(.5,0)
banner.Position = UDim2.new(.5,0,.22,0)
banner.Size = UDim2.new(.85,0,0,55)
banner.BackgroundColor3 = Color3.fromRGB(32,110,65)
banner.TextColor3 = Color3.new(1,1,1)
banner.Text = "LUCKY HOUR! Sorte 2x na esteira!"
banner.TextWrapped = true
banner.Font = Enum.Font.GothamBold
banner.TextSize = 19
banner.Visible = false
banner.Parent = gui
local bc = Instance.new("UICorner"); bc.Parent = banner
local previous = false
while gui.Parent do
	local active = state:GetAttribute("Active") == true
	local remaining = math.max(0,math.ceil((state:GetAttribute("EndsAt") or 0)-Workspace:GetServerTimeNow()))
	local clock = string.format("%02d:%02d",math.floor(remaining/60),remaining%60)
	label.Text = active and ("LUCKY HOUR  |  2x  |  "..clock) or ("Proximo Lucky Hour: "..clock)
	label.BackgroundColor3 = active and Color3.fromRGB(32,110,65) or Color3.fromRGB(30,42,38)
	if active and not previous then
		banner.Visible = true
		task.delay(5,function() if banner.Parent then banner.Visible=false end end)
	end
	previous = active
	task.wait(.25)
end
