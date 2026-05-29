--- Put in StarterCharacterScripts
--- Press space twice to double jump
--- Press shift to dive
--- Made by SlowGhost208

local DOUBLE_JUMP_UNLOCK_STAGE = 100
local DIVE_UNLOCK_STAGE = 150

local MAX_JUMPS = 1;
local MAX_DIVES = 0;
local TIME_BETWEEN_JUMPS = 0.1;
local TweenService = game:GetService("TweenService")
local hrp = script.Parent:WaitForChild("HumanoidRootPart");
local head = script.Parent:WaitForChild("Head");
local humanoid = script.Parent:WaitForChild("Humanoid");

local canJump = true;
local jumpCount = 0;

local canDive = true;
local diveCount = 0;
local totalDives = 0;

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local leaderstats = player:WaitForChild("leaderstats")
local maxStageStat = leaderstats:WaitForChild("Max Stage")

local function updateAbilities()
	local maxStage = maxStageStat.Value
	MAX_JUMPS = if maxStage >= DOUBLE_JUMP_UNLOCK_STAGE then 2 else 1
	MAX_DIVES = if maxStage >= DIVE_UNLOCK_STAGE then 1 else 0
end

maxStageStat.Changed:Connect(updateAbilities)
updateAbilities()

local function createParticle(cf, t)
	local Info = TweenInfo.new(t, Enum.EasingStyle.Linear)
	local Goals = {
		Size = Vector3.new(0.1, 4, 4);
		Transparency = 1
	} 
	local part = Instance.new("Part");
	part.Shape = Enum.PartType.Cylinder
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Size = Vector3.new(0.1, 3, 3)
	part.Anchored = true;
	part.CanCollide = false;
	part.Transparency = 0.4;
	local Tween = TweenService:Create(part,Info,Goals)
	part.CFrame = cf;
	part.Orientation = Vector3.new(0, 0, -90)
	part.Parent = game.Workspace;
	game:GetService("Debris"):AddItem(part, t);
	Tween:Play()
end

local function onStateChange(old, new)
	if (new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Swimming or new == Enum.HumanoidStateType.Running or new == Enum.HumanoidStateType.RunningNoPhysics) then	
		canDive = true;
		canJump = true;
		jumpCount = 0;
		diveCount = 0;
	elseif (new == Enum.HumanoidStateType.Freefall or new == Enum.HumanoidStateType.Flying) then
		wait(TIME_BETWEEN_JUMPS)
		canJump = true;
		canDive = true;
	end
end

local function onJumpRequest()
	if (not humanoid or humanoid:GetState() == Enum.HumanoidStateType.Dead) then
		return;
	end
	
	if (canJump and jumpCount < MAX_JUMPS) then
		canJump = false;
		jumpCount = jumpCount + 1;
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping);
		
		if (jumpCount > 1) then
			if (jumpCount % 2 == 0 or humanoid:GetState() == Enum.HumanoidStateType.Flying) then
			end
			local z = hrp.CFrame:vectorToObjectSpace(hrp.Velocity).z;
			createParticle(hrp.CFrame * CFrame.new(0, -1, 0), 1);
		end
	end
end

local function onInput(input, process)
	if (process or not humanoid or humanoid:GetState() == Enum.HumanoidStateType.Dead) then
		return;
	end	
	
	if (input.KeyCode == Enum.KeyCode.LeftShift and humanoid:GetState() == Enum.HumanoidStateType.Freefall and canDive and diveCount < MAX_DIVES) then
		canDive = false;
		diveCount = diveCount + 1;
		totalDives = totalDives + 1;
		
		humanoid:ChangeState(Enum.HumanoidStateType.Flying);
		hrp.Velocity = hrp.CFrame:vectorToWorldSpace(Vector3.new(0, humanoid.JumpPower, -humanoid.WalkSpeed*3));
		hrp.RotVelocity = hrp.CFrame:vectorToWorldSpace(Vector3.new(-math.rad(135), 0, 0));
		createParticle(hrp.CFrame * CFrame.new(0, -1, -3), 1);
		

		local currentDive = totalDives;
		wait(0.5);
		if (currentDive == totalDives) then
			hrp.RotVelocity = hrp.CFrame:vectorToWorldSpace(Vector3.new(0, 0, 0));
		end
	end
end

local function onTouched(touchingPart, humanoidPart)
	if (humanoid:GetState() == Enum.HumanoidStateType.Flying and touchingPart.CanCollide) then
		local ray = Ray.new(humanoidPart.Position, -humanoidPart.Velocity * 10);
		local hit, pos, normal, material = game.Workspace:FindPartOnRayWithWhitelist(ray, {touchingPart});
	
		if (material ~= Enum.Material.Water and material ~= Enum.Material.Air and normal:Dot(Vector3.new(0, 1, 0)) <= 0.5) then
			hrp.Velocity = (normal + Vector3.new(0, 1, 0)) * 30;
		end
		
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall);
	end
end

humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false);
humanoid.Touched:Connect(onTouched);
game:GetService("UserInputService").InputBegan:Connect(onInput);

humanoid.StateChanged:Connect(onStateChange);
game:GetService("UserInputService").JumpRequest:Connect(onJumpRequest);
