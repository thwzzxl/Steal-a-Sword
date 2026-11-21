-- LocalScript inside the Tool
local Tool = script.Parent
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")

-- Swing animation
local anim = Instance.new("Animation")
anim.AnimationId = "rbxassetid://95826977890108"  -- Basic right-hand swing animation
local track = humanoid:LoadAnimation(anim)

-- Configure animation settings
track.Priority = Enum.AnimationPriority.Action
track.Looped = false

local remote = Tool:WaitForChild("HitEvent")
local canSwing = true
local cooldown = 2

Tool.Activated:Connect(function()
	if not canSwing then return end
	canSwing = false

	-- play swing animation
	track:Stop() -- Stop any existing animation
	track:Play(0.1, 1, 1.5) -- Fade in time, weight, speed

	-- tell server we swung
	remote:FireServer()

	-- cooldown
	task.delay(cooldown, function()
		canSwing = true
	end)
end)
