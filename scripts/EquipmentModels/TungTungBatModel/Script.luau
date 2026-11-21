-- ...existing code...
-- Script inside the Tool
local Tool = script.Parent
local remote = Tool:WaitForChild("HitEvent")

local DAMAGE_FORCE = 60  -- Reduced back to original value
local RAGDOLL_TIME = 2
local HIT_DISTANCE = 13 -- studs forward from player

-- Ragdoll function
local function ragdoll(char, attackerRoot)
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if not (hum and root) then return end

	-- Fully disable movement and set up for ragdoll
	hum.JumpPower = 0
	hum.WalkSpeed = 0  -- Prevent walking while ragdolled
	hum.AutoRotate = false

	-- Force ragdoll state while keeping animations
	if game:GetService("Players"):GetPlayerFromCharacter(char) then
		-- For players, use FallingDown which allows animations
		hum:ChangeState(Enum.HumanoidStateType.FallingDown)
		task.wait() -- Wait one frame
		hum:ChangeState(Enum.HumanoidStateType.FallingDown)
	else
		-- For NPCs, single state change is enough
		hum:ChangeState(Enum.HumanoidStateType.FallingDown)
	end

	-- Only disable movement states, keep animation states
	hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Running, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)

	-- Ensure proper network ownership for physics
	local function setNetworkOwnership(char)
		if game:GetService("RunService"):IsServer() then
			-- Give server control of all physics parts immediately
			for _, part in pairs(char:GetDescendants()) do
				if part:IsA("BasePart") then
					part:SetNetworkOwner(nil)  -- Server takes control
				end
			end

			-- Set custom physical properties for better physics behavior
			local properties = PhysicalProperties.new(1, 0.3, 0.5, 1, 1)  -- Mass, Friction, Elasticity, FrictionWeight, ElasticityWeight
			for _, part in pairs(char:GetDescendants()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					part.CustomPhysicalProperties = properties
				end
			end
		end
	end

	-- Set network ownership immediately and after a small delay to ensure it takes effect
	setNetworkOwnership(char)
	task.delay(0.1, function() 
		setNetworkOwnership(char)
	end)

	-- Collect and disable Motor6D joints
	local disabledMotors = {}
	for _, desc in ipairs(char:GetDescendants()) do
		if desc:IsA("Motor6D") and desc.Part1 and desc.Name ~= "Root" then
			desc.Enabled = false
			table.insert(disabledMotors, desc)
		end
	end

	-- Save health to prevent accidental death
	local originalHealth = hum.Health

	-- Detect rig type
	local isR15 = char:FindFirstChild("UpperTorso") and char:FindFirstChild("LeftUpperArm")
	local ragdollConstraints = Instance.new("Folder")
	ragdollConstraints.Name = "RagdollConstraints"
	ragdollConstraints.Parent = char

	local ragdollApplied = false
	local parts = nil
	local r6parts = nil
	if isR15 then
		-- R15 logic
		local function addRagdollJoint(part0, part1, typeName, attName)
			local att0 = part0:FindFirstChild(attName.."RigAttachment")
			local att1 = part1:FindFirstChild(attName.."RigAttachment")
			if att0 and att1 then
				local constraint
				if typeName == "BallSocket" then
					constraint = Instance.new("BallSocketConstraint")
					constraint.LimitsEnabled = true
					constraint.TwistLimitsEnabled = true

					-- Different limits based on joint type
					if attName == "Neck" then
						-- Keep head more restricted
						constraint.UpperAngle = 45
						constraint.TwistLowerAngle = -45
						constraint.TwistUpperAngle = 45
					elseif attName == "Waist" then
						-- Moderate torso flexibility
						constraint.UpperAngle = 90
						constraint.TwistLowerAngle = -90
						constraint.TwistUpperAngle = 90
					else
						-- Full flexibility for limbs
						constraint.UpperAngle = 135
						constraint.TwistLowerAngle = -135
						constraint.TwistUpperAngle = 135
					end

				elseif typeName == "Hinge" then
					constraint = Instance.new("HingeConstraint")
					constraint.LimitsEnabled = true
					-- Knees and elbows have different ranges
					if attName:find("Knee") then
						constraint.LowerAngle = 0  -- knees don't bend backwards
						constraint.UpperAngle = 135
					else  -- elbows
						constraint.LowerAngle = -45
						constraint.UpperAngle = 145
					end
				end

				-- Add NoCollision constraint between connected parts
				local noCollision = Instance.new("NoCollisionConstraint")
				noCollision.Part0 = part0
				noCollision.Part1 = part1
				noCollision.Parent = ragdollConstraints
				constraint.Attachment0 = att0
				constraint.Attachment1 = att1
				constraint.Parent = ragdollConstraints
			end
		end
		parts = {
			LowerTorso = char:FindFirstChild("LowerTorso"),
			UpperTorso = char:FindFirstChild("UpperTorso"),
			Head = char:FindFirstChild("Head"),
			LeftUpperArm = char:FindFirstChild("LeftUpperArm"),
			LeftLowerArm = char:FindFirstChild("LeftLowerArm"),
			LeftHand = char:FindFirstChild("LeftHand"),
			RightUpperArm = char:FindFirstChild("RightUpperArm"),
			RightLowerArm = char:FindFirstChild("RightLowerArm"),
			RightHand = char:FindFirstChild("RightHand"),
			LeftUpperLeg = char:FindFirstChild("LeftUpperLeg"),
			LeftLowerLeg = char:FindFirstChild("LeftLowerLeg"),
			LeftFoot = char:FindFirstChild("LeftFoot"),
			RightUpperLeg = char:FindFirstChild("RightUpperLeg"),
			RightLowerLeg = char:FindFirstChild("RightLowerLeg"),
			RightFoot = char:FindFirstChild("RightFoot"),
		}
		addRagdollJoint(parts.LowerTorso, parts.UpperTorso, "BallSocket", "Waist")
		addRagdollJoint(parts.UpperTorso, parts.Head, "BallSocket", "Neck")
		addRagdollJoint(parts.UpperTorso, parts.LeftUpperArm, "BallSocket", "LeftShoulder")
		addRagdollJoint(parts.LeftUpperArm, parts.LeftLowerArm, "Hinge", "LeftElbow")
		addRagdollJoint(parts.LeftLowerArm, parts.LeftHand, "BallSocket", "LeftWrist")
		addRagdollJoint(parts.UpperTorso, parts.RightUpperArm, "BallSocket", "RightShoulder")
		addRagdollJoint(parts.RightUpperArm, parts.RightLowerArm, "Hinge", "RightElbow")
		addRagdollJoint(parts.RightLowerArm, parts.RightHand, "BallSocket", "RightWrist")
		addRagdollJoint(parts.LowerTorso, parts.LeftUpperLeg, "BallSocket", "LeftHip")
		addRagdollJoint(parts.LeftUpperLeg, parts.LeftLowerLeg, "Hinge", "LeftKnee")
		addRagdollJoint(parts.LeftLowerLeg, parts.LeftFoot, "BallSocket", "LeftAnkle")
		addRagdollJoint(parts.LowerTorso, parts.RightUpperLeg, "BallSocket", "RightHip")
		addRagdollJoint(parts.RightUpperLeg, parts.RightLowerLeg, "Hinge", "RightKnee")
		addRagdollJoint(parts.RightLowerLeg, parts.RightFoot, "BallSocket", "RightAnkle")
		-- Set up collisions and physical properties for limbs
		for _, part in pairs(parts) do
			if part and part.Name ~= "HumanoidRootPart" then
				part.CanCollide = true
				part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)  -- Better physics response

				-- Prevent collision with own HumanoidRootPart
				if root then
					local noCollision = Instance.new("NoCollisionConstraint")
					noCollision.Part0 = part
					noCollision.Part1 = root
					noCollision.Parent = ragdollConstraints
				end

				-- Prevent collision between touching limbs to reduce glitching
				for _, otherPart in pairs(parts) do
					if otherPart and otherPart ~= part and otherPart.Name ~= "HumanoidRootPart" then
						local touching = (otherPart.Position - part.Position).Magnitude < (part.Size.Magnitude + otherPart.Size.Magnitude) * 0.5
						if touching then
							local noCollision = Instance.new("NoCollisionConstraint")
							noCollision.Part0 = part
							noCollision.Part1 = otherPart
							noCollision.Parent = ragdollConstraints
						end
					end
				end
			end
		end
		ragdollApplied = true
	else
		-- R6 logic
		r6parts = {
			Head = char:FindFirstChild("Head"),
			Torso = char:FindFirstChild("Torso"),
			LeftArm = char:FindFirstChild("Left Arm"),
			RightArm = char:FindFirstChild("Right Arm"),
			LeftLeg = char:FindFirstChild("Left Leg"),
			RightLeg = char:FindFirstChild("Right Leg"),
		}
		local function makeAttachment(part, name, position)
			local att = Instance.new("Attachment")
			att.Name = name
			att.Position = position or Vector3.new()
			att.Parent = part
			return att
		end
		-- Create attachments for R6
		local attTorsoTop = makeAttachment(r6parts.Torso, "TorsoTop", Vector3.new(0, r6parts.Torso.Size.Y/2, 0))
		local attHeadBottom = makeAttachment(r6parts.Head, "HeadBottom", Vector3.new(0, -r6parts.Head.Size.Y/2, 0))
		local attTorsoLeft = makeAttachment(r6parts.Torso, "TorsoLeft", Vector3.new(-r6parts.Torso.Size.X/2, 0, 0))
		local attLeftArm = makeAttachment(r6parts.LeftArm, "LeftArm", Vector3.new(r6parts.LeftArm.Size.X/2, 0, 0))
		local attTorsoRight = makeAttachment(r6parts.Torso, "TorsoRight", Vector3.new(r6parts.Torso.Size.X/2, 0, 0))
		local attRightArm = makeAttachment(r6parts.RightArm, "RightArm", Vector3.new(-r6parts.RightArm.Size.X/2, 0, 0))
		local attTorsoBottom = makeAttachment(r6parts.Torso, "TorsoBottom", Vector3.new(0, -r6parts.Torso.Size.Y/2, 0))
		local attLeftLeg = makeAttachment(r6parts.LeftLeg, "LeftLeg", Vector3.new(0, r6parts.LeftLeg.Size.Y/2, 0))
		local attRightLeg = makeAttachment(r6parts.RightLeg, "RightLeg", Vector3.new(0, r6parts.RightLeg.Size.Y/2, 0))
		-- Head-Torso
		local c1 = Instance.new("BallSocketConstraint")
		c1.Attachment0 = attTorsoTop
		c1.Attachment1 = attHeadBottom
		c1.Parent = ragdollConstraints
		-- Left Arm-Torso
		local c2 = Instance.new("BallSocketConstraint")
		c2.Attachment0 = attTorsoLeft
		c2.Attachment1 = attLeftArm
		c2.Parent = ragdollConstraints
		-- Right Arm-Torso
		local c3 = Instance.new("BallSocketConstraint")
		c3.Attachment0 = attTorsoRight
		c3.Attachment1 = attRightArm
		c3.Parent = ragdollConstraints
		-- Left Leg-Torso
		local c4 = Instance.new("BallSocketConstraint")
		c4.Attachment0 = attTorsoBottom
		c4.Attachment1 = attLeftLeg
		c4.Parent = ragdollConstraints
		-- Right Leg-Torso
		local c5 = Instance.new("BallSocketConstraint")
		c5.Attachment0 = attTorsoBottom
		c5.Attachment1 = attRightLeg
		c5.Parent = ragdollConstraints
		-- Enable collisions on limbs, but not with HumanoidRootPart
		for _, part in pairs(r6parts) do
			if part and part.Name ~= "HumanoidRootPart" then
				part.CanCollide = true
				-- Prevent collision with HumanoidRootPart
				if root then
					local noCollision = Instance.new("NoCollisionConstraint")
					noCollision.Part0 = part
					noCollision.Part1 = root
					noCollision.Parent = ragdollConstraints
				end
			end
		end
		ragdollApplied = true
	end

	-- Apply knockback force with better consistency
	if attackerRoot then
		-- Calculate direction and force
		local dir = (root.Position - attackerRoot.Position).Unit
		dir = Vector3.new(dir.X, 0.7, dir.Z).Unit  -- More upward force

		-- Calculate base impulse with reduced multiplier
		local baseImpulse = DAMAGE_FORCE * root.AssemblyMass

		-- Function to apply force to a part
		local function applyForce(part, multiplier)
			if part then
				-- Initial impulse
				part:ApplyImpulse(dir * baseImpulse * multiplier)

				-- Schedule a delayed second push for more consistent force
				task.delay(0.1, function()
					if part and part.Parent then
						part:ApplyImpulse(dir * baseImpulse * multiplier * 0.25)
					end
				end)
			end
		end

		-- Apply forces to multiple parts for more consistent physics
		applyForce(root, 1)  -- Full force to root

		-- Apply to torso
		local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
		applyForce(torso, 0.8)  -- 80% force to torso

		-- For R15, also push lower torso
		local lowerTorso = char:FindFirstChild("LowerTorso")
		if lowerTorso then
			applyForce(lowerTorso, 0.6)  -- 60% force to lower torso
		end

		-- play Hit sound from attacker's tool handle (server-side)
		if Tool and Tool:FindFirstChild("Handle") then
			local hitSound = Tool.Handle:FindFirstChild("Hit")
			if hitSound and hitSound:IsA("Sound") then
				hitSound:Play() -- server-side, all clients will hear
			end
		end
	end

	-- always force FallingDown state
	hum:ChangeState(Enum.HumanoidStateType.FallingDown)

	-- If no ragdoll joints were applied (custom rig), just stop here
	if not ragdollApplied then return end

	-- recover after ragdoll time
	task.delay(RAGDOLL_TIME, function()
		if hum and hum.Parent then
			-- Re-enable Motor6Ds
			for _, motor in ipairs(disabledMotors) do
				motor.Enabled = true
			end
			-- cleanup ragdoll constraints
			local folder = char:FindFirstChild("RagdollConstraints")
			if folder then
				folder:Destroy()
			end
			-- restore humanoid and collisions
			if isR15 and parts then
				for _, part in pairs(parts) do
					if part and part.Name ~= "HumanoidRootPart" then
						part.CanCollide = false
					end
				end
			elseif r6parts then
				for _, part in pairs(r6parts) do
					if part and part.Name ~= "HumanoidRootPart" then
						part.CanCollide = false
					end
				end
			end
			-- Re-enable all movement
			hum.JumpPower = 50
			hum.WalkSpeed = 16  -- Default walk speed
			hum.AutoRotate = true

			-- Re-enable all movement states
			hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
			hum:SetStateEnabled(Enum.HumanoidStateType.Running, true)
			hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
			hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)

			-- restore health if lost during ragdoll
			if hum.Health < originalHealth then
				hum.Health = originalHealth
			end
			-- force GettingUp state to avoid floor glitch
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end)
end

-- Hit detection using raycast (accurate forward check)
local function tryHit(attacker)
	local char = attacker.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	-- Only use range and touching for hit detection

	-- Touch detection for more accurate hits (vertical and close)
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj:IsA("Model") then
			local victimHum = obj:FindFirstChildOfClass("Humanoid")
			local victimRoot = obj:FindFirstChild("HumanoidRootPart")
			-- Prevent affecting the player holding the tool
			if victimHum and victimRoot and obj ~= char and not obj:IsDescendantOf(char) then
				-- Check distance between roots
				local dist = (root.Position - victimRoot.Position).Magnitude
				if dist <= HIT_DISTANCE then
					-- If within range, trigger ragdoll even if not physically touching
					return obj
				end
			end
		end
	end
end

-- RemoteEvent handler
remote.OnServerEvent:Connect(function(player)
	local victim = tryHit(player)
	if victim then
		local attackerRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		ragdoll(victim, attackerRoot)
	end
end)
