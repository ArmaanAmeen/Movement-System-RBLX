-- Services --
local UIS = game:GetService('UserInputService')
local RunService = game:GetService("RunService")
local DebrisService = game:GetService('Debris')
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

-- Modules --
local stateManager = require(script:WaitForChild('StateManager'))
local vfxHandler = require(script:WaitForChild('VFXHandler'))

-- Character --
local char = script.Parent
local humanoid = char:WaitForChild('Humanoid')
local humanoidRootPart = char:WaitForChild('HumanoidRootPart')
local rootJoint = humanoidRootPart:WaitForChild('RootJoint')
local rootC0 = rootJoint.C0
local head = char:WaitForChild('Head')

-- Camera --
local camera = workspace.CurrentCamera

-- Settings --
local rollCooldown = script.Roll.Cooldown.Value
local rollPower = script.Roll.Power.Value
local rollPower2 = script.Roll.Power2.Value
local slidingCooldown = script.Sliding.Cooldown.Value
local slidingPower = script.Sliding.Power.Value
local slidingLength = script.Sliding.Length.Value
local landingHeight = 6.5
local maxVaultHeight = 4
local climbCooldown = script.Climb.Cooldown.Value
local climbForce = script.Climb.Power.Value
local climbSpeed = script.Climb.Decay.Value
local doubleJumpCooldown = script.DoubleJump.Cooldown.Value
local doubleJumpForce = script.DoubleJump.Power.Value
local doubleJumpSpeed = script.DoubleJump.Decay.Value
local wallRunSpeed = script.WallRun.Speed.Value
local wallRunDownwardSpeed = script.WallRun.DownwardSpeed.Value  
local wallRunDuration = script.WallRun.Duration.Value
local wallRunCooldown = script.WallRun.Cooldown.Value
local wallRunRange = 2
local barSwingDistance = script.BarSwing.Distance.Value
local barSwingPower = script.BarSwing.Power.Value
local barSwingUpPower = script.BarSwing.UpPower.Value
local barSwingCooldown = script.BarSwing.Cooldown.Value
local fallDamageFactor = 100
local maxTiltAngle = 15
local minFOV = 70
local maxFOV = 80 
local maxSpeed = script.MaxSpeed.Value
local momentumGain = 0.005
local slideCancelled = false
local isFKeyDown = false
local climbHorizontalSpeed = 25


-- Animations --
local animation = {
	['W'] = humanoid:LoadAnimation(script.Animations:WaitForChild("ForwardRoll")),
	['A'] = humanoid:LoadAnimation(script.Animations:WaitForChild("LeftRoll")),
	['S'] = humanoid:LoadAnimation(script.Animations:WaitForChild("BackRoll")),
	['D'] = humanoid:LoadAnimation(script.Animations:WaitForChild("RightRoll")),

	['Landed'] = humanoid:LoadAnimation(script.Animations:WaitForChild("Landed")),
	['LightLanded'] = humanoid:LoadAnimation(script.Animations:WaitForChild("LightLanded")),

	['Vault1'] = humanoid:LoadAnimation(script.Animations:WaitForChild("MonkeyVault")),
	['Vault2'] = humanoid:LoadAnimation(script.Animations:WaitForChild("SideVault")),

	['Climb'] = humanoid:LoadAnimation(script.Animations:WaitForChild("Climb")),
	['ClimbUp'] = humanoid:LoadAnimation(script.Animations:WaitForChild("ClimbUp")),
	['ClimbJumpOff'] = humanoid:LoadAnimation(script.Animations:WaitForChild("ClimbJumpOff")),

	['AirDash'] = humanoid:LoadAnimation(script.Animations:WaitForChild("AirDash")), 

	['DoubleJump'] = humanoid:LoadAnimation(script.Animations:WaitForChild("DoubleJump")), 

	['Death'] = humanoid:LoadAnimation(script.Animations:WaitForChild("Death")), 

	['IdleEvent1'] = humanoid:LoadAnimation(script.Animations:WaitForChild("ScratchIdle")), 
	['IdleEvent2'] = humanoid:LoadAnimation(script.Animations:WaitForChild("ShoulderIdle")), 

	['WallRunLeft'] = humanoid:LoadAnimation(script.Animations:WaitForChild("WallRunLeft")), 
	['WallRunRight'] = humanoid:LoadAnimation(script.Animations:WaitForChild("WallRunRight")), 
	['WallHopLeft'] = humanoid:LoadAnimation(script.Animations:WaitForChild("WallHopLeft")), 
	['WallHopRight'] = humanoid:LoadAnimation(script.Animations:WaitForChild("WallHopRight")), 

	['BarSwing'] = humanoid:LoadAnimation(script.Animations:WaitForChild("BarSwing")), 

	['Slide1'] = humanoid:LoadAnimation(script.Animations:WaitForChild("Slide1")), 
	['Slide2'] = humanoid:LoadAnimation(script.Animations:WaitForChild("Slide2")), 
}

-- Sounds --
local sound = {
	['KickUp'] = script.Sounds:WaitForChild("KickUp"),

	['Whoosh1'] = script.Sounds:WaitForChild("Whoosh1"),
	['Whoosh2'] = script.Sounds:WaitForChild("Whoosh2"),

	['Dash'] = script.Sounds:WaitForChild("Dash"),

	['Vault'] = script.Sounds:WaitForChild("Vault"),

	['WallKick'] = script.Sounds:WaitForChild("WallKick"),

	['DeathFade'] = script.Sounds:WaitForChild("DeathFade"),
	['Crackle'] = script.Sounds:WaitForChild("Crackle"),

	['IdleEventSound1'] = script.Sounds:WaitForChild("IdleEventSound1"),
	--['IdleEventSound1_2'] = script.Sounds:WaitForChild("IdleEventSound1_2"),
	['IdleEventSound2'] = script.Sounds:WaitForChild("IdleEventSound2"),
	['IdleEventSound2_2'] = script.Sounds:WaitForChild("IdleEventSound2_2"),

	['WallHop'] = script.Sounds:WaitForChild("WallHop"),
	['WallRun'] = script.Sounds:WaitForChild("WallRun"),

	['Swing'] = script.Sounds:WaitForChild("Swing"),

	['Slide'] = script.Sounds:WaitForChild("Slide"),

	['LightLanding'] = script.Sounds:WaitForChild("LightLanding"),

	['SafeLand'] = script.Sounds:WaitForChild("SafeLanding")
}

-- Data --
local shiftLocked
local direction
local velocityDirection
local fallPosition
local climbViable
local currentTime
local wallRunAnim
local idlePlaying
local barSwingDir
local hopDir = Vector3.new()
local timeMovedAt = tick()
local speedParticles = false
local canSend = true
local disengage = false
local tiltAngle = CFrame.new()
local connections = {}
local keyStates = {
	[Enum.KeyCode.W] = false,
	[Enum.KeyCode.A] = false,
	[Enum.KeyCode.S] = false,
	[Enum.KeyCode.D] = false
}
local movementCooldowns = {
	['Roll'] = false,
	['Climb'] = false,
	['DoubleJump'] = false,
	['WallRun'] = false,
	['BarSwing'] = false,
	['Sliding'] = false,
}

local function rockDebris(origin,amount,color,material,collide)
	for i = 1, amount do 
		local Part = Instance.new("Part")
		Part.Anchored = false
		Part.Name = "DebrisPart"
		Part.Shape = "Block"
		Part.Size = Vector3.new(0.5,0.5,0.5)
		Part.Material = material
		Part.CanCollide = collide
		Part.CFrame = origin.CFrame * CFrame.new(0, -5, 0)
		Part.BrickColor = BrickColor.new(color)

		local DENSITY = 25
		local FRICTION = 1
		local ELASTICITY = 0
		local FRICTION_WEIGHT = 1
		local ELASTICITY_WEIGHT = 25
		local physProperties = PhysicalProperties.new(DENSITY, FRICTION, ELASTICITY, FRICTION_WEIGHT, ELASTICITY_WEIGHT)
		Part.CustomPhysicalProperties = physProperties

		Part.Velocity = Vector3.new(math.random(-33,33),math.random(-5,25),math.random(-33,33))
		Part.CFrame = Part.CFrame * CFrame.Angles(math.rad(math.random(30, 90)), math.rad(math.random(30, 90)), math.rad(math.random(30, 90)))

		Part.Parent = workspace

		game.PhysicsService:SetPartCollisionGroup(Part,"Debris")

		DebrisService:AddItem(Part, math.random(5,7))
	end
end

local function lerp(A: number, B: number, T: number): number
	return A + (B - A) * T
end

local function checkRollKey(key)
	if key == Enum.KeyCode.W then
		direction = 'W'
		velocityDirection = camera.CFrame.LookVector

	elseif key == Enum.KeyCode.A then
		direction = 'A'
		velocityDirection = -camera.CFrame.RightVector

	elseif key == Enum.KeyCode.S then
		direction = 'S'
		velocityDirection = -camera.CFrame.LookVector

	elseif key == Enum.KeyCode.D then
		direction = 'D'
		velocityDirection = camera.CFrame.RightVector

	end
end


local function movementRoll(dashDirection)
	stateManager.SetState('Rolling', true)

	sound['Dash']:Play()

	vfxHandler.SendVFX('BodyTrail', 'All', char, {0.5, 'BodyTrail1'})

	task.spawn(function()
		vfxHandler.SendVFX('FOV', 'Single', char, {0.3, 80})
		task.wait(0.3)
		vfxHandler.SendVFX('FOV', 'Single', char, {0.3, 70})
	end)

	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(100000, 0, 100000)
	bv.Parent = humanoidRootPart

	-- **Create BodyGyro to rotate character towards camera direction**
	local bg = Instance.new("BodyGyro")
	bg.MaxTorque = Vector3.new(0, math.huge, 0)
	bg.P = 100000
	bg.D = 1000
	bg.Parent = humanoidRootPart

	local dashStrength = rollPower -- Adjust as needed
	local dashDuration = 0.35
	local rate = 0.01

	local minimumDashStrength = dashStrength * 0.15

	local amountOfIterations = dashDuration / rate

	local removalOfStrengthPerIteration = dashStrength / amountOfIterations

	local animDirection = ''

	-- **Determine the animation direction based on dashDirection**
	if dashDirection == 'Front' then
		animDirection = 'W'
	elseif dashDirection == 'Back' then
		animDirection = 'S'
	elseif dashDirection == 'Left' then
		animDirection = 'A'
	elseif dashDirection == 'Right' then
		animDirection = 'D'
	else
		animDirection = 'W'
	end

	-- **Play animation and adjust speed**
	local anim = animation[animDirection]
	local animLength = anim.Length
	local requiredSpeed = animLength / dashDuration

	anim:Play()
	anim:AdjustSpeed(requiredSpeed)

	for i = 0, dashDuration, rate do
		-- **Update character orientation to face the camera direction**
		local cameraCFrame = workspace.CurrentCamera.CFrame
		local cameraDirection = Vector3.new(cameraCFrame.LookVector.X, 0, cameraCFrame.LookVector.Z).Unit
		bg.CFrame = CFrame.new(humanoidRootPart.Position, humanoidRootPart.Position + cameraDirection)

		-- **Determine velocityDirection based on the updated character orientation**
		local velocityDirection = Vector3.new()
		if dashDirection == 'Front' then
			velocityDirection = humanoidRootPart.CFrame.LookVector
		elseif dashDirection == 'Back' then
			velocityDirection = -humanoidRootPart.CFrame.LookVector
		elseif dashDirection == 'Left' then
			velocityDirection = -humanoidRootPart.CFrame.RightVector
		elseif dashDirection == 'Right' then
			velocityDirection = humanoidRootPart.CFrame.RightVector
		else
			velocityDirection = humanoidRootPart.CFrame.LookVector
		end

		bv.Velocity = velocityDirection * dashStrength

		if dashStrength > minimumDashStrength then
			dashStrength -= removalOfStrengthPerIteration
			if dashStrength < minimumDashStrength then
				dashStrength = minimumDashStrength
			end
		end

		task.wait(rate)
	end

	bv:Destroy()
	bg:Destroy()

	-- **Stop the animation when the dash ends**
	anim:Stop()

	stateManager.SetState('Rolling', false)
end


local function movementSlide()
	stateManager.SetState('Sliding', true)
	slideCancelled = false  -- Reset the flag at the start of the slide

	sound['Slide']:Play()

	local randomNum = math.random(2)
	local anim = animation['Slide'..randomNum]
	task.spawn(function()
		anim:Play()    
		animation['Slide'..randomNum]:AdjustSpeed(1.5)
		task.wait(animation['Slide1'].Length*0.49)
		animation['Slide'..randomNum]:AdjustSpeed(0)
	end)

	local prevVolume = humanoidRootPart:FindFirstChild('Running').Volume 
	humanoidRootPart:FindFirstChild('Running').Volume = 0

	vfxHandler.SendVFX('BodyTrail', 'All', char, {1, 'BodyTrail1'})
	vfxHandler.SendVFX('FOV', 'Single', char, {0.1, 80})

	local bodyVel = Instance.new("BodyVelocity", humanoidRootPart)
	bodyVel.MaxForce = Vector3.new(1, 0, 1) * 25000
	bodyVel.Velocity = char.HumanoidRootPart.CFrame.lookVector * slidingPower

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {char}
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	local partBelow = workspace:Raycast(humanoidRootPart.Position, humanoidRootPart.CFrame.UpVector * -5, params)
	if partBelow then
		vfxHandler.SendVFX('Slide', 'All', char, {'Torso', partBelow.Instance.Color, true})
	else    
		vfxHandler.SendVFX('Slide', 'All', char, {'Torso', nil, true})
	end

	for i=1, slidingLength do
		if slideCancelled then
			break  -- Exit the loop if slide is cancelled
		end

		local params = RaycastParams.new()
		params.FilterDescendantsInstances = {char}
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.IgnoreWater = true
		local partBelow = workspace:Raycast(humanoidRootPart.Position, humanoidRootPart.CFrame.UpVector * -5, params)
		if partBelow then
			vfxHandler.SendVFX('Slide', 'All', char, {'Torso', partBelow.Instance.Color, true})
		else    
			vfxHandler.SendVFX('Slide', 'All', char, {'Torso', nil, true})
		end

		bodyVel.Velocity *= 0.8        
		task.wait(0.1)
	end

	humanoidRootPart:FindFirstChild('Running').Volume = prevVolume

	vfxHandler.SendVFX('Slide', 'All', char, {'Torso', nil, false})

	vfxHandler.SendVFX('FOV', 'Single', char, {1, 70})
	animation['Slide'..randomNum]:Stop(0.3)
	bodyVel:Destroy()
	stateManager.SetState('Sliding', false)
	slideCancelled = false  -- Reset the flag after sliding ends
end


local function movementAirDash()
	stateManager.SetState('AirDashing', true)  -- Changed from 'Rolling' to 'AirDashing'

	sound['Dash']:Play()

	animation['AirDash']:Play()
	animation['AirDash']:AdjustSpeed(1.5)

	task.spawn(function()
		vfxHandler.SendVFX('FOV', 'Single', char, {0.1, 75})
		task.wait(0.1)
		vfxHandler.SendVFX('FOV', 'Single', char, {0.1, 70})
	end)

	vfxHandler.SendVFX('AirDash', 'All', char)
	vfxHandler.SendVFX('BodyTrail', 'All', char, {1.5, 'BodyTrail1'})

	local bodyVel = Instance.new("BodyVelocity", humanoidRootPart)
	bodyVel.MaxForce = Vector3.new(1, 1, 1) * 25000	

	velocityDirection = humanoidRootPart.CFrame.LookVector

	for i=rollPower2, 0, -.15 do
		bodyVel.Velocity = velocityDirection * i * 4
		task.wait(0.01)
		if i < 17 then
			i = 0
			bodyVel:Destroy()
			animation['AirDash']:Stop(0.3)
		end
	end

	bodyVel:Destroy()
	stateManager.SetState('AirDashing', false)  -- Changed from 'Rolling' to 'AirDashing'
end


local function movementDoubleJump()

	stateManager.SetState('DoubleJumping', true)

	vfxHandler.SendVFX('DoubleJump', 'All', char)
	vfxHandler.SendVFX('BodyTrail', 'All', char, {1.5, 'BodyTrail1'})

	task.spawn(function()
		vfxHandler.SendVFX('FOV', 'Single', char, {0.25, 75})
		task.wait(0.25)
		vfxHandler.SendVFX('FOV', 'Single', char, {0.1, 70})
	end)

	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

	local bodyVel = Instance.new("BodyVelocity", humanoidRootPart)
	bodyVel.MaxForce = Vector3.new(0, 1, 0) * 15000
	bodyVel.Velocity = Vector3.new(0, 1, 0)

	local currentTime = 0
	local currentVel = doubleJumpForce

	animation['DoubleJump']:Play()
	animation['DoubleJump']:AdjustSpeed(2)
	sound['Whoosh2']:Play()

	connections[game.Players.LocalPlayer] = RunService.Heartbeat:Connect(function(delta: number)

		currentTime += delta * doubleJumpSpeed

		local timePosition = math.clamp(1 - currentTime, 0, 1)
		local percentage = lerp(0, 1, timePosition)

		currentVel = doubleJumpForce * percentage
		bodyVel.Velocity = Vector3.yAxis * currentVel

	end)

	animation['DoubleJump'].Stopped:Connect(function()
		bodyVel:Destroy()
		connections[game.Players.LocalPlayer]:Disconnect()

		stateManager.SetState('DoubleJumping', false)
	end)

end

local function spawnVaultPart()
	local lookVector = humanoidRootPart.CFrame.LookVector
	local upVector = humanoidRootPart.CFrame.UpVector
	local spawnDistance = 8
	local stepSize = 0.5  
	local minDistance = 2 

	local function isSpaceAvailable(position)
		local rayOrigin = humanoidRootPart.Position
		local rayDirection = position - rayOrigin
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {humanoidRootPart.Parent}
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

		return not raycastResult
	end

	local spawnPosition = humanoidRootPart.Position + lookVector * spawnDistance + upVector * 3

	while not isSpaceAvailable(spawnPosition) and spawnDistance > minDistance do
		spawnDistance -= stepSize
		spawnPosition = humanoidRootPart.Position + lookVector * spawnDistance + upVector * 3
	end

	if spawnDistance <= minDistance then
		return nil
	end

	local part = Instance.new("Part", workspace)
	part.Size = Vector3.new(1, 1, 1)
	part.CFrame = CFrame.new(spawnPosition, spawnPosition + lookVector)
	part.Transparency = 1
	part.Position = spawnPosition
	part.Anchored = true
	part.Parent = workspace
	part.CanCollide = false

	part.BrickColor = BrickColor.new("Bright Gold")
	part.Material = Enum.Material.SmoothPlastic

	DebrisService:AddItem(part, 0.5)

	return part.CFrame
end

local function movementVault(result)

	if humanoid.FloorMaterial == Enum.Material.Air then return end

	stateManager.SetState('Vaulting', true)

	vfxHandler.SendVFX('BodyTrail', 'All', char, {0.5, 'BodyTrail1'})

	local randomNum = math.random(2)
	local anim = animation['Vault'..randomNum]
	anim:Play()	
	anim:AdjustSpeed(2)

	sound['Vault']:Play()
	sound['Vault'].TimePosition = 0

	local partPos = spawnVaultPart()
	local tweenInfo = TweenInfo.new(
		0.25, 
		Enum.EasingStyle.Quad, 
		Enum.EasingDirection.Out 
	)

	local tweenGoal = {CFrame = partPos }
	local tween = TweenService:Create(humanoidRootPart, tweenInfo, tweenGoal)

	humanoidRootPart.Anchored = true
	tween:Play()

	tween.Completed:Wait()

	stateManager.SetState('Vaulting', false)
	humanoidRootPart.Anchored = false
end

local function movementVaultCheck()
	task.wait(0.1)
	if stateManager.GetStates('Swinging') == true or stateManager.GetStates('Sliding') == true or stateManager.GetStates('Rolling') == true or stateManager.GetStates('Climbing') == true or stateManager.GetStates('Vaulting') == true or stateManager.GetStates('DoubleJumping') == true or stateManager.GetStates('Stunned') == true or stateManager.GetStates('WallRunning') == true or stateManager.GetStates('WallHopping') == true then return end
	if keyStates[Enum.KeyCode.W] == true and humanoid.MoveDirection.Magnitude > 0  then
		local raycastRange = 2.5
		local ray = Ray.new(humanoidRootPart.CFrame.p, humanoidRootPart.CFrame.LookVector * raycastRange)
		local result = workspace:FindPartOnRay(ray, char)

		if result and result:IsA('BasePart') then
			if result.Parent:FindFirstChild('Humanoid') then return end
			if result.Size.Y < 4.1 then
				if (head.Position.Y - result.Position.Y) >= 2 then
					if canSend then
						canSend = false
						movementVault(result)
						task.wait(0.1)
						canSend = true
					end
				end
			end
		end
	end
end

local function vaultRayCheck(part, distance)
	local vaultRay = workspace:Raycast(part.Position,part.CFrame.LookVector * distance)
	if not vaultRay then
		return true
	else
		return false
	end
end

local function movementClimbJumpOff()
	task.wait(.2)

	stateManager.SetState('Climbing', true)

	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

	local bodyVel = Instance.new("BodyVelocity", humanoidRootPart)
	bodyVel.Name = 'ClimbingDisengage'
	bodyVel.MaxForce = Vector3.new(1, 1, 1) * 15000
	bodyVel.Velocity = Vector3.new(1, 1, 1)

	local currentTime = 0
	local currentVel = doubleJumpForce

	animation['ClimbJumpOff']:Play()
	animation['ClimbJumpOff']:AdjustSpeed(2.5)
	sound['WallKick']:Play()

	task.spawn(function()
		vfxHandler.SendVFX('FOV', 'Single', char, {0.1, 75})
		task.wait(0.1)
		vfxHandler.SendVFX('FOV', 'Single', char, {0.1, 70})
	end)

	vfxHandler.SendVFX('BodyTrail', 'All', char, {1, 'BodyTrail1'})

	local jumpOffDir = humanoidRootPart.CFrame.LookVector

	connections[game.Players.LocalPlayer] = RunService.Heartbeat:Connect(function(delta: number)

		currentTime += delta * doubleJumpSpeed

		local timePosition = math.clamp(1 - currentTime, 0, 1)
		local percentage = lerp(0, 1, timePosition)

		currentVel = doubleJumpForce * percentage 
		bodyVel.Velocity = Vector3.yAxis * currentVel - jumpOffDir * 15

	end)

	animation['ClimbJumpOff'].Stopped:Connect(function()
		bodyVel:Destroy()
		connections[game.Players.LocalPlayer]:Disconnect()

		stateManager.SetState('Climbing', false)

	end)
end

local function movementClimb()
	-- Removed the check for humanoid.FloorMaterial

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {workspace.Live}
	params.FilterType = Enum.RaycastFilterType.Exclude

	local firstResult = workspace:Raycast(char.PrimaryPart.CFrame.Position, char.PrimaryPart.CFrame.LookVector * 2, params)

	-- 1) If there was no hit, return false immediately.
	if not firstResult then 
		return false 
	end

	-- 2) Check if the part is a BasePart or MeshPart **and** has the 'climbable' Attribute == true
	local hitPart = firstResult.Instance
	if (hitPart:IsA("BasePart") or hitPart:IsA("MeshPart")) and hitPart:GetAttribute("climbable") == true then
		-- Good: This is a valid climbable surface
	else
		-- Not valid climbable, so return false
		return false
	end

	humanoid.AutoRotate = false
	humanoid.WalkSpeed = 0

	stateManager.SetState('Climbing', true)

	local bodyVel = Instance.new("BodyVelocity", humanoidRootPart)
	bodyVel.Name = 'ClimbingVelocity'
	bodyVel.MaxForce = Vector3.new(1, 1, 1) * 15000  -- Updated MaxForce to include horizontal movement
	bodyVel.Velocity = Vector3.new(0, 1, 0)

	local alignOrientation = Instance.new("AlignOrientation", char.PrimaryPart)
	alignOrientation.Name = 'ClimbingAlign'
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrientation.Attachment0 = char:FindFirstChild("RootAttachment", true)
	alignOrientation.Responsiveness = 100
	alignOrientation.CFrame = CFrame.lookAt(humanoidRootPart.Position, humanoidRootPart.Position + firstResult.Normal)

	animation['Climb']:Play()

	local currentTime = 0
	local currentVel = climbForce
	connections[game.Players.LocalPlayer] = RunService.Heartbeat:Connect(function(delta: number)

		humanoid:ChangeState(Enum.HumanoidStateType.Climbing)

		animation['Climb'].KeyframeReached:Connect(function(keyframeName)
			currentTime = 0
			sound['KickUp']:Play()
		end)
		currentTime += delta * climbSpeed

		local timePosition = math.clamp(1 - currentTime, 0, 1)
		local percentage = lerp(0, 1, timePosition)

		currentVel = climbForce * percentage

		-- Calculate horizontal movement based on 'A' and 'D' key states
		local horizontalMovement = Vector3.new(0, 0, 0)
		if keyStates[Enum.KeyCode.A] then
			horizontalMovement = horizontalMovement - humanoidRootPart.CFrame.RightVector
		end
		if keyStates[Enum.KeyCode.D] then
			horizontalMovement = horizontalMovement + humanoidRootPart.CFrame.RightVector
		end
		if horizontalMovement.Magnitude > 0 then
			horizontalMovement = horizontalMovement.Unit * climbHorizontalSpeed
		end

		-- Update the body velocity to include horizontal movement
		bodyVel.Velocity = Vector3.yAxis * currentVel + horizontalMovement

		local ray = char.PrimaryPart.CFrame.Position - Vector3.new(0, 2, 0)
		local result = workspace:Raycast(ray, char.PrimaryPart.CFrame.LookVector * 2, params)
		if result then
			if not result.Instance then return end
			alignOrientation.CFrame = CFrame.lookAlong(char.PrimaryPart.CFrame.Position, -result.Normal)
		else
			animation['Climb']:Stop()
		end

		if disengage == true then
			animation['Climb']:Stop()
			movementClimbJumpOff()
			disengage = false
		end
	end)

	animation['Climb'].Stopped:Connect(function()
		bodyVel:Destroy()
		connections[game.Players.LocalPlayer]:Disconnect()

		local function climbVaultProcedure()
			animation['ClimbUp']:Play()
			animation['ClimbUp']:AdjustSpeed(2)

			vfxHandler.SendVFX('BodyTrail', 'All', char, {0.5, 'BodyTrail1'})

			sound['Whoosh1']:Play()
			sound['Whoosh1'].TimePosition = 0.2

			task.spawn(function()
				vfxHandler.SendVFX('FOV', 'Single', char, {0.25, 75})
				task.wait(0.25)
				vfxHandler.SendVFX('FOV', 'Single', char, {0.1, 70})
			end)
		end

		if vaultRayCheck(humanoidRootPart, 5) and not humanoidRootPart:FindFirstChild('ClimbingDisengage') and not disengage then
			climbVaultProcedure()

			local vaultBodyVel = Instance.new("BodyVelocity", humanoidRootPart)
			vaultBodyVel.Name = 'ClimbVaultVelocity'
			vaultBodyVel.MaxForce = Vector3.new(1, 1, 1) * 15000
			vaultBodyVel.Velocity = humanoidRootPart.CFrame.LookVector * 15 + Vector3.new(0, 5, 0)
			game.Debris:AddItem(vaultBodyVel, 0.15)

		elseif vaultRayCheck(head, 5) and not humanoidRootPart:FindFirstChild('ClimbingDisengage') and not disengage then
			climbVaultProcedure()

			local vaultBodyVel = Instance.new("BodyVelocity", humanoidRootPart)
			vaultBodyVel.Name = 'ClimbVaultVelocity'
			vaultBodyVel.MaxForce = Vector3.new(1, 1, 1) * 15000
			vaultBodyVel.Velocity = humanoidRootPart.CFrame.LookVector * 15 + Vector3.new(0, 20, 0)
			game.Debris:AddItem(vaultBodyVel, 0.15)
		end

		humanoid.AutoRotate = true
		alignOrientation:Destroy()
		humanoid.WalkSpeed = game.StarterPlayer.CharacterWalkSpeed

		task.wait(0.01)
		stateManager.SetState('Climbing', false)
	end)
end


local function wallRun(rayInput, direction, wallRunParams)
	local wallDirection = rayInput.Normal:Cross(Vector3.new(0, direction, 0))
	local wallNormal = rayInput.Normal

	local bodyVel = Instance.new("BodyVelocity")
	bodyVel.Name = 'WallRunVelocity'
	bodyVel.Velocity = wallDirection * wallRunSpeed
	bodyVel.MaxForce = Vector3.new(1, 1, 1) * 14000
	bodyVel.Parent = humanoidRootPart

	local directionValue = Instance.new('IntValue')
	directionValue.Name = 'Direction'
	directionValue.Parent = bodyVel
	directionValue.Value = direction

	local alignOrientation = Instance.new("AlignOrientation", char.PrimaryPart)
	alignOrientation.Name = 'WallRunAlign'
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrientation.Attachment0 = char:FindFirstChild("RootAttachment", true)
	alignOrientation.Responsiveness = 100
	alignOrientation.CFrame = CFrame.lookAt(humanoidRootPart.Position, humanoidRootPart.Position + wallNormal)

	local function updateOrientation(wallNormal)
		local lookDirection
		if direction == 1 then 
			lookDirection = wallNormal:Cross(Vector3.new(0, 1, 0))
		else
			lookDirection = wallNormal:Cross(Vector3.new(0, -1, 0))
		end
		alignOrientation.CFrame = CFrame.lookAt(humanoidRootPart.Position, humanoidRootPart.Position + lookDirection, Vector3.new(0, 1, 0))
	end

	local function destroyVel()
		sound['WallRun']:Stop()

		if humanoidRootPart:FindFirstChild('WallRunVelocity') then
			humanoidRootPart:FindFirstChild('WallRunVelocity'):Destroy()
		end
		if humanoidRootPart:FindFirstChild('WallRunAlign') then
			humanoidRootPart:FindFirstChild('WallRunAlign'):Destroy()
		end
	end

	updateOrientation(wallNormal)

	DebrisService:AddItem(bodyVel, wallRunDuration)
	DebrisService:AddItem(alignOrientation, wallRunDuration)

	stateManager.SetState('WallRunning', true)

	humanoid:ChangeState(Enum.HumanoidStateType.Climbing)

	humanoid.AutoRotate = false

	local wallRunAnim
	if direction == -1 then
		wallRunAnim = 'WallRunLeft'
		vfxHandler.SendVFX('WallRun', 'All', char, {'Left Arm', true})
	elseif direction == 1 then
		wallRunAnim = 'WallRunRight'
		vfxHandler.SendVFX('WallRun', 'All', char, {'Right Arm', true})
	end

	animation[wallRunAnim]:Play()
	animation[wallRunAnim]:AdjustSpeed(1.3)

	sound['WallRun']:Play()

	bodyVel.Destroying:Connect(function()
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)

		movementCooldowns['WallRun'] = true

		if direction == -1 then
			vfxHandler.SendVFX('WallRun', 'All', char, {'Left Arm', false})
		elseif direction == 1 then
			vfxHandler.SendVFX('WallRun', 'All', char, {'Right Arm', false})
		end

		destroyVel()
		stateManager.SetState('WallRunning', false)
		humanoid.AutoRotate = true
		animation[wallRunAnim]:Stop()
		if connections[game.Players.LocalPlayer] then
			connections[game.Players.LocalPlayer]:Disconnect()
			connections[game.Players.LocalPlayer] = nil
		end
	end)

	local currentVel = wallRunSpeed
	local currentTime = 0

	connections[game.Players.LocalPlayer] = RunService.Heartbeat:Connect(function(delta)
		currentTime = currentTime + delta
		local timePosition = math.clamp(1 - (currentTime / wallRunDuration), 0, 1)
		local percentage = lerp(0, 1, timePosition)
		if percentage < 0.55 then
			destroyVel()
		end
		currentVel = wallRunSpeed * percentage

		if humanoid.FloorMaterial ~= Enum.Material.Air then 
			destroyVel()			
		end

		local forwardRay = workspace:Raycast(humanoidRootPart.Position, humanoidRootPart.CFrame.LookVector * wallRunRange, wallRunParams)
		if forwardRay then 
			local forwardWallNormal = forwardRay.Normal
			local angleDifference = math.deg(math.acos(wallNormal:Dot(forwardWallNormal)))
			if angleDifference > 50 then
				destroyVel()
			else
				wallDirection = forwardWallNormal:Cross(Vector3.new(0, direction, 0))
				bodyVel.Velocity = wallDirection * currentVel + Vector3.new(0, -wallRunDownwardSpeed, 0)
				updateOrientation(forwardWallNormal)
			end
		end

		if direction == -1 then
			local leftRayCheck = workspace:Raycast(humanoidRootPart.Position, humanoidRootPart.CFrame.RightVector * -wallRunRange, wallRunParams)
			if not leftRayCheck then
				destroyVel()
			end
		elseif direction == 1 then
			local rightRayCheck = workspace:Raycast(humanoidRootPart.Position, humanoidRootPart.CFrame.RightVector * wallRunRange, wallRunParams)
			if not rightRayCheck then
				destroyVel()
			end
		else
			warn('Missing direction...')
		end

		bodyVel.Velocity = wallDirection * currentVel + Vector3.new(0, -wallRunDownwardSpeed, 0)
	end)
end

local function wallRunJumpOff(direction)

	stateManager.SetState('WallHopping', true)

	repeat wait() until not humanoidRootPart:FindFirstChild('WallRunVelocity')

	movementCooldowns['WallRun'] = false

	local bodyVel = Instance.new("BodyVelocity", humanoidRootPart)
	bodyVel.Name = 'WallRunDisengage'
	bodyVel.MaxForce = Vector3.new(1, 1, 1) * 15000
	bodyVel.Velocity = Vector3.new(1, 1, 1)

	local currentTime = 0
	local currentVel = doubleJumpForce

	if direction == -1 then
		animation['WallHopLeft']:Play()
		animation['WallHopLeft']:AdjustSpeed(2)
		hopDir = humanoidRootPart.CFrame.RightVector

	elseif direction == 1 then
		animation['WallHopRight']:Play()
		animation['WallHopRight']:AdjustSpeed(2)

		hopDir = -humanoidRootPart.CFrame.RightVector

	end	
	sound['WallHop']:Play()

	task.spawn(function()
		vfxHandler.SendVFX('FOV', 'Single', char, {0.1, 75})
		task.wait(0.1)
		vfxHandler.SendVFX('FOV', 'Single', char, {0.1, 70})
	end)

	vfxHandler.SendVFX('BodyTrail', 'All', char, {1, 'BodyTrail1'})

	bodyVel.Velocity = hopDir * 25 + Vector3.new(0, 20, 0) + (humanoidRootPart.CFrame.LookVector * 30)

	animation['WallHopLeft'].Stopped:Connect(function()
		bodyVel:Destroy()
		stateManager.SetState('WallHopping', false)
	end)
	animation['WallHopRight'].Stopped:Connect(function()
		bodyVel:Destroy()
		stateManager.SetState('WallHopping', false)
	end)
end

local function swingBar(bar)

	stateManager.SetState('Swinging', true)

	local tweenInfo = TweenInfo.new(
		0.15, 
		Enum.EasingStyle.Linear, 
		Enum.EasingDirection.Out
	)
	local tween = TweenService:Create(humanoidRootPart, tweenInfo, {CFrame = bar.CFrame * CFrame.new(0, -2, 0)})

	animation['BarSwing']:Play()
	animation['BarSwing']:AdjustSpeed(1.5)
	task.spawn(function()
		task.wait(animation['BarSwing'].Length*0.49)
		animation['BarSwing']:AdjustSpeed(0)
		task.wait(0.1)
		animation['BarSwing']:AdjustSpeed(1.5)
	end)

	humanoidRootPart.Anchored = true
	tween:Play()
	tween.Completed:Wait()

	humanoidRootPart.Anchored = false

	sound['Swing']:Play()

	vfxHandler.SendVFX('BodyTrail', 'All', char, {1.5, 'BodyTrail1'})

	local bodyVel2 = Instance.new("BodyVelocity", humanoidRootPart)
	bodyVel2.Name = 'BarSwingVel'
	bodyVel2.MaxForce = Vector3.new(0, 1, 0) * 14000
	bodyVel2.Velocity = Vector3.new(0, barSwingUpPower, 0)
	DebrisService:AddItem(bodyVel2, 0.1)

	bodyVel2.Destroying:Connect(function()
		local bodyVel1 = Instance.new("BodyVelocity", humanoidRootPart)
		bodyVel1.Name = 'BarSwingVel'
		bodyVel1.MaxForce = Vector3.new(1, 0, 1) * 14000
		local forceDir = (camera.CFrame.LookVector * barSwingPower)
		bodyVel1.Velocity = forceDir.Unit * 100
		DebrisService:AddItem(bodyVel1, 0.1)
	end)

	task.wait(0.1)
	stateManager.SetState('Swinging', false)

end

local function swingBarCheck()
	local swingingObjects = game.Workspace.SwingingBars

	for _, bar in pairs(swingingObjects:GetChildren()) do
		local distance = (bar.Position - humanoidRootPart.Position).Magnitude
		if distance < barSwingDistance then return bar end
	end
end

local function idleEvent()
	local chanceToPlay = math.random(1, 5) 
	timeMovedAt = tick()

	if chanceToPlay == 1 then
		local randomNum = math.random(1, 2) 
		idlePlaying = animation['IdleEvent'.. randomNum]
		animation['IdleEvent'.. randomNum]:Play()
		animation['IdleEvent'.. randomNum].KeyframeReached:Connect(function(kfName)
			if kfName == 'scratch1'then
				sound['IdleEventSound'..randomNum]:Play(.2)
			elseif kfName == 'scratch2' then
				if sound['IdleEventSound'..randomNum..'_2'] then
					sound['IdleEventSound'..randomNum..'_2']:Play(.2)
				end
			end
		end)

		animation['IdleEvent'.. randomNum].Stopped:Connect(function()
			timeMovedAt = tick()
		end)

	end
end

local function idleEventCheck()
	if humanoid.MoveDirection.Magnitude > 0 then
		timeMovedAt = tick()
	end

	if timeMovedAt and tick() - timeMovedAt > 10 then
		idleEvent()
	end
end

local function inputBegan(input, gameProcessed)

	if gameProcessed then return end

	if UIS.MouseBehavior == Enum.MouseBehavior.LockCenter then
		shiftLocked = true
	else
		shiftLocked = false
	end

	if input.KeyCode == Enum.KeyCode.W or
		input.KeyCode == Enum.KeyCode.A or
		input.KeyCode == Enum.KeyCode.S or
		input.KeyCode == Enum.KeyCode.D then

		if humanoid:GetState() == Enum.HumanoidStateType.Dead then return end

		if keyStates[input.KeyCode] ~= true then
			keyStates[input.KeyCode] = true
		end
	end

	if input.KeyCode == Enum.KeyCode.C then
		if stateManager.GetStates('Swinging') == true or stateManager.GetStates('Sliding') == true or stateManager.GetStates('Rolling') == true or stateManager.GetStates('Climbing') == true or stateManager.GetStates('Vaulting') == true or stateManager.GetStates('DoubleJumping') == true or stateManager.GetStates('Stunned') == true or stateManager.GetStates('WallRunning') == true or stateManager.GetStates('WallHopping') == true then return end
		if movementCooldowns['Sliding'] ~= false then return end
		if humanoid.FloorMaterial == Enum.Material.Air then return end

		task.spawn(function()
			movementCooldowns['Sliding'] = true
			movementSlide()
			task.wait(slidingCooldown)
			movementCooldowns['Sliding'] = false
		end)
	end

	if input.KeyCode == Enum.KeyCode.LeftControl then
		if stateManager.GetStates('Swinging') == true or stateManager.GetStates('Sliding') == true or stateManager.GetStates('Rolling') == true or stateManager.GetStates('Climbing') == true or stateManager.GetStates('Vaulting') == true or stateManager.GetStates('DoubleJumping') == true or stateManager.GetStates('Stunned') == true or stateManager.GetStates('WallRunning') == true or stateManager.GetStates('WallHopping') == true then return end

		if movementCooldowns['WallRun'] ~= false then return end

		local wallRunParams = RaycastParams.new()
		wallRunParams.FilterDescendantsInstances = {char}
		wallRunParams.FilterType = Enum.RaycastFilterType.Exclude

		local function leftWallRun(rayInput)
			wallRun(rayInput, -1, wallRunParams)
		end

		local function rightWallRun(rayInput)
			wallRun(rayInput, 1, wallRunParams)
		end

		--local forwardRay = workspace:Raycast(humanoidRootPart.Position, humanoidRootPart.CFrame.LookVector * 5, wallRunParams)
		local leftRayCheck = workspace:Raycast(humanoidRootPart.Position, humanoidRootPart.CFrame.RightVector * -wallRunRange, wallRunParams)
		local rightRayCheck = workspace:Raycast(humanoidRootPart.Position, humanoidRootPart.CFrame.RightVector * wallRunRange, wallRunParams)

		if leftRayCheck or rightRayCheck then
			if leftRayCheck and rightRayCheck then
				local leftDistance = (leftRayCheck.Position - humanoidRootPart.Position).Magnitude
				local rightDistance = (rightRayCheck.Position - humanoidRootPart.Position).Magnitude

				if leftDistance < rightDistance then
					leftWallRun(leftRayCheck)
				else
					rightWallRun(rightRayCheck)
				end
			elseif leftRayCheck then
				leftWallRun(leftRayCheck)
			elseif rightRayCheck then
				rightWallRun(rightRayCheck)
			end
		end
	end

	if input.KeyCode == Enum.KeyCode.Q then
		if stateManager.GetStates('Swinging') == true or stateManager.GetStates('Sliding') == true or
			stateManager.GetStates('Rolling') == true or stateManager.GetStates('Climbing') == true or
			stateManager.GetStates('Vaulting') == true or stateManager.GetStates('DoubleJumping') == true or
			stateManager.GetStates('WallRunning') == true or stateManager.GetStates('WallHopping') == true or
			stateManager.GetStates('Stunned') == true then return end

		if movementCooldowns['Roll'] == false then
			-- If in air and W is pressed, perform air dash
			if humanoid.FloorMaterial == Enum.Material.Air and UIS:IsKeyDown(Enum.KeyCode.W) then
				task.spawn(function()
					movementCooldowns['Roll'] = true
					movementAirDash()
					task.wait(rollCooldown)
					movementCooldowns['Roll'] = false
				end)
				return
			end

			-- Determine dashDirection based on movement keys
			local dashDirection = nil
			if UIS:IsKeyDown(Enum.KeyCode.W) then
				dashDirection = "Front"
			elseif UIS:IsKeyDown(Enum.KeyCode.A) then
				dashDirection = "Left"
			elseif UIS:IsKeyDown(Enum.KeyCode.S) then
				dashDirection = "Back"
			elseif UIS:IsKeyDown(Enum.KeyCode.D) then
				dashDirection = "Right"
			end

			if dashDirection then
				task.spawn(function()
					movementCooldowns['Roll'] = true
					movementRoll(dashDirection)
					task.wait(rollCooldown)
					movementCooldowns['Roll'] = false
				end)
			else
				-- If no movement keys pressed, default to 'Back' direction
				task.spawn(function()
					movementCooldowns['Roll'] = true
					movementRoll("Back")
					task.wait(rollCooldown)
					movementCooldowns['Roll'] = false
				end)
			end
		end
	end

	if input.KeyCode == Enum.KeyCode.X and not gameProcessed then
		isFKeyDown = true
		-- Start a loop that keeps trying to climb while X is held.
		task.spawn(function()
			while isFKeyDown do
				-- Only attempt climb if not climbing and no other states conflict
				if not stateManager.GetStates('Climbing')
					and stateManager.GetStates('Swinging') == false
					and stateManager.GetStates('Sliding') == false
					and stateManager.GetStates('Rolling') == false
					and stateManager.GetStates('Vaulting') == false
					and stateManager.GetStates('DoubleJumping') == false
					and stateManager.GetStates('Stunned') == false
					and stateManager.GetStates('WallRunning') == false
					and stateManager.GetStates('WallHopping') == false
				then
					-- Attempt to climb. If movementClimb() returns false, that’s okay:
					-- we won't break; we let the loop keep going so it can try again.
					movementClimb()
				end

				-- Small wait so we don’t spam calls every frame
				task.wait(0.01)
			end
		end)
	end

	-- Double Jump remains on Space key
	if input.KeyCode == Enum.KeyCode.Space and not gameProcessed then

		-- **Disable Space Key During Climbing**
		if stateManager.GetStates('Climbing') == true then
			return  -- Ignore the Space key if climbing
		end

		if stateManager.GetStates('Sliding') == true then
			slideCancelled = true
			return  -- Exit the function after cancelling the slide
		end

		-- Handle WallRunning Disengage
		if stateManager.GetStates('WallRunning') == true and humanoidRootPart:FindFirstChild('WallRunVelocity') then
			local dir = humanoidRootPart:FindFirstChild('WallRunVelocity'):FindFirstChild('Direction').Value
			humanoidRootPart:FindFirstChild('WallRunVelocity'):Destroy()
			wallRunJumpOff(dir)
			return
		end

		-- Check for Other Conflicting States
		if stateManager.GetStates('Swinging') == true or
			stateManager.GetStates('Rolling') == true or
			stateManager.GetStates('Vaulting') == true or
			stateManager.GetStates('DoubleJumping') == true or
			stateManager.GetStates('Stunned') == true or
			stateManager.GetStates('WallHopping') == true then
			return
		end

		-- Handle Double Jump
		if humanoid.FloorMaterial == Enum.Material.Air then
			if movementCooldowns['DoubleJump'] == false then
				movementCooldowns['DoubleJump'] = true
				movementDoubleJump()
				task.wait(doubleJumpCooldown)
				movementCooldowns['DoubleJump'] = false
			end
		else
			-- **Regular Jump**
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end

	-- Other input handling code...

	if input.KeyCode == Enum.KeyCode.E then
		if stateManager.GetStates('Swinging') == true or
			stateManager.GetStates('Sliding') == true or
			stateManager.GetStates('Rolling') == true or
			stateManager.GetStates('Climbing') == true or
			stateManager.GetStates('Vaulting') == true or
			stateManager.GetStates('DoubleJumping') == true or
			stateManager.GetStates('WallRunning') == true or
			stateManager.GetStates('WallHopping') == true or
			stateManager.GetStates('Stunned') == true then
			return
		end

		if movementCooldowns['BarSwing'] == false then

			local barTarget = swingBarCheck()

			if barTarget then
				local dotResult = camera.CFrame.LookVector:Dot(barTarget.CFrame.LookVector)
				if dotResult < 0.5 and dotResult > 0 then return end
				if dotResult < 0 and dotResult > -0.5 then return end
				if dotResult == 0 then return end
				movementCooldowns['BarSwing'] = true
				swingBar(barTarget)
				task.wait(barSwingCooldown)
				movementCooldowns['BarSwing'] = false
			end			
		end
	end
end

local function inputEnded(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.W or
		input.KeyCode == Enum.KeyCode.A or
		input.KeyCode == Enum.KeyCode.S or
		input.KeyCode == Enum.KeyCode.D then
		if keyStates[input.KeyCode] ~= false then
			keyStates[input.KeyCode] = false
		end
	elseif input.KeyCode == Enum.KeyCode.X and not gameProcessed then
		isFKeyDown = false
	end
end

local function calculateFOV(walkSpeed)
	walkSpeed = math.clamp(walkSpeed, 0, maxSpeed)
	local normalizedSpeed = walkSpeed / maxSpeed
	local fov = minFOV + (maxFOV - minFOV) * (normalizedSpeed ^ 3)
	return fov
end


UIS.InputBegan:Connect(inputBegan)
UIS.InputEnded:Connect(inputEnded)
RunService.RenderStepped:Connect(movementVaultCheck)
RunService.RenderStepped:Connect(idleEventCheck)
RunService.RenderStepped:Connect(function(delta)

	if speedParticles == true then
		vfxHandler.SendVFX('MomentumSpeed', 'Single', char, true)
	else
		vfxHandler.SendVFX('MomentumSpeed', 'Single', char, false)
	end

	local moveDir = humanoidRootPart.CFrame:VectorToObjectSpace(humanoid.MoveDirection)

	if moveDir.Magnitude == 0 then
		humanoid.WalkSpeed = game.StarterPlayer.CharacterWalkSpeed
		humanoidRootPart:FindFirstChild('Running').PlaybackSpeed = game.Players.LocalPlayer.PlayerScripts.RbxCharacterSounds.RunPitch.Value
		speedParticles = false

	else
		if humanoid.WalkSpeed < maxSpeed and keyStates[Enum.KeyCode.W] == true and keyStates[Enum.KeyCode.S] == false and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
			if stateManager.GetStates('Swinging') == true or stateManager.GetStates('Sliding') == true or stateManager.GetStates('Rolling') == true or stateManager.GetStates('Climbing') == true or stateManager.GetStates('Vaulting') == true or stateManager.GetStates('DoubleJumping') == true or stateManager.GetStates('WallRunning') == true or stateManager.GetStates('WallHopping') == true or stateManager.GetStates('Stunned') == true then return end
			humanoid.WalkSpeed += momentumGain
		end

		if humanoid.WalkSpeed >= maxSpeed*0.95 then
			humanoidRootPart:FindFirstChild('Running').PlaybackSpeed = game.Players.LocalPlayer.PlayerScripts.RbxCharacterSounds.RunPitch.Value*1.15
			speedParticles = true
		else
			speedParticles = false
			humanoidRootPart:FindFirstChild('Running').PlaybackSpeed = game.Players.LocalPlayer.PlayerScripts.RbxCharacterSounds.RunPitch.Value
		end
	end

	if humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
		tiltAngle = tiltAngle:Lerp(CFrame.Angles(math.rad(-moveDir.Z) * maxTiltAngle, math.rad(-moveDir.X) * maxTiltAngle, 0), 0.35 ^ (1 / (delta * 60)))
		rootJoint.C0 = rootC0 * tiltAngle
	else
		tiltAngle = tiltAngle:Lerp(CFrame.Angles(0,0,0), 0.1)
		rootJoint.C0 = rootC0 * tiltAngle
	end


	if keyStates[Enum.KeyCode.W] == true then
		if stateManager.CheckAllStates() == true then return end
		vfxHandler.SendVFX('FOV', 'Single', char, {0.1, calculateFOV(humanoid.WalkSpeed)})
	else
		if stateManager.CheckAllStates() == true then return end
		vfxHandler.SendVFX('FOV', 'Single', char, {0.3, 70})
	end

	if moveDir.Magnitude > 0 then
		if idlePlaying and idlePlaying.IsPlaying == true then
			idlePlaying:Stop() 
		end
	end
end)
humanoid.StateChanged:Connect(function(oldstate, state)
	if state == Enum.HumanoidStateType.Dead then
		if oldstate == Enum.HumanoidStateType.Landed then

			local raycastParams = RaycastParams.new()
			raycastParams.FilterDescendantsInstances = {humanoidRootPart.Parent}
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude

			local ray = workspace:Raycast(humanoidRootPart.Position, Vector3.new(0, -100, 0), raycastParams)
			if ray then 
				local floorHeight = ray.Position.Y + 3
				local currentCFrame = humanoidRootPart.CFrame
				local newPos = CFrame.new(currentCFrame.Position.X, floorHeight, currentCFrame.Position.Z) * CFrame.Angles(currentCFrame:ToOrientation())				
				local tweenInfo = TweenInfo.new(
					0.25, 
					Enum.EasingStyle.Quad, 
					Enum.EasingDirection.Out 
				)
				local heightTween = TweenService:Create(humanoidRootPart, tweenInfo, {CFrame = newPos})
				heightTween:Play()
			end
		end

		humanoidRootPart.Anchored = true
		-- Removed the death animation and stun logic:
		-- animation['Death']:Play()	
		-- stateManager.SetState('Stunned', true)

		-- VFX for death:
		task.spawn(function()
			vfxHandler.SendVFX('DeathFade', 'All', char)
			sound['DeathFade']:Play()
			sound['Crackle']:Play()
			task.wait(animation['Death'].Length)  -- You can adjust this based on your preferred timing.
			humanoidRootPart.Anchored = false
			vfxHandler.SendVFX('None', 'Respawn', char, game.Players.LocalPlayer)
		end)

		-- Optional: Remove any animation speed adjustments if not needed.
		-- task.spawn(function()
		--     task.wait(animation['Death'].Length * 0.99)
		--     animation['Death']:AdjustSpeed(0)
		-- end)
	end



	if state == Enum.HumanoidStateType.Freefall then
		fallPosition = humanoidRootPart.Position.y
	end

	if oldstate == Enum.HumanoidStateType.Freefall and state == Enum.HumanoidStateType.Landed then

		if movementCooldowns['WallRun'] == true then
			task.spawn(function()
				task.wait(wallRunCooldown)
				movementCooldowns['WallRun'] = false
			end)
		end

		if movementCooldowns['Climb'] == true then
			task.spawn(function()
				task.wait(climbCooldown)
				movementCooldowns['Climb'] = false
			end)
		end

		local heightDropped = fallPosition - humanoidRootPart.Position.y
		if heightDropped > landingHeight then

			local params = RaycastParams.new()
			params.FilterDescendantsInstances = {char}
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.IgnoreWater = true
			local partBelow = workspace:Raycast(humanoidRootPart.Position, humanoidRootPart.CFrame.UpVector * -10, params)

			if partBelow and partBelow.Instance.Name == "SafeLanding" then
				humanoid.WalkSpeed = game.StarterPlayer.CharacterWalkSpeed*0
				humanoid.JumpPower = game.StarterPlayer.CharacterJumpPower*0

				animation['LightLanded']:Play()
				animation['LightLanded']:AdjustSpeed(1)
				sound['SafeLand']:Play()

				task.spawn(function()
					stateManager.SetState('Rolling', true)
					vfxHandler.SendVFX('FOV', 'Single', char, {animation['LightLanded'].Length, 65})
					task.wait(animation['LightLanded'].Length)
					vfxHandler.SendVFX('FOV', 'Single', char, {0.1, 70})
					stateManager.SetState('Rolling', false)
				end)

				local bodyVelocity = Instance.new("BodyVelocity")
				bodyVelocity.Velocity = char.HumanoidRootPart.CFrame.lookVector * 25
				bodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
				bodyVelocity.Parent = humanoidRootPart

				task.wait(animation['LightLanded'].Length*1.2)

				humanoid.WalkSpeed = game.StarterPlayer.CharacterWalkSpeed
				humanoid.JumpPower = game.StarterPlayer.CharacterJumpPower

				bodyVelocity:Destroy()				
				return
			end

			animation['Landed']:Play()	
			animation['Landed']:AdjustSpeed(1.15)	
			vfxHandler.SendVFX('Fall', 'All', char)

			if humanoidRootPart:FindFirstChild('Landing').Playing ~= true then
				humanoidRootPart:FindFirstChild('Landing'):Play()
			end 

			if heightDropped > 17 then

				rockDebris(humanoidRootPart,math.random(3,5),partBelow.Instance.Color,partBelow.Material,true)

				humanoid:TakeDamage(heightDropped/fallDamageFactor)				
				task.spawn(function()
					vfxHandler.SendVFX('FOV', 'Single', char, {0.1, 65})
					task.wait(0.1)
					vfxHandler.SendVFX('FOV', 'Single', char, {0.1, 70})
				end)
			end

			stateManager.SetState('Stunned', true)
			humanoid.WalkSpeed = game.StarterPlayer.CharacterWalkSpeed/3
			humanoid.JumpPower = game.StarterPlayer.CharacterJumpPower*0
			animation['Landed'].Stopped:Connect(function()
				stateManager.SetState('Stunned', false)
				humanoid.WalkSpeed = game.StarterPlayer.CharacterWalkSpeed
				humanoid.JumpPower = game.StarterPlayer.CharacterJumpPower
			end)
		else
			humanoidRootPart:FindFirstChild('Landing'):Stop()
			if heightDropped > landingHeight/2 then
				sound['LightLanding']:Play()
			end
		end
	end
end)
humanoid:GetPropertyChangedSignal('Jump'):Connect(function()
	timeMovedAt = tick()
end) 
humanoid:GetPropertyChangedSignal('Health'):Connect(function()
	vfxHandler.SendVFX('BodyColour', 'All', char, {0.25, Color3.fromRGB(255, 102, 102)})
end)

