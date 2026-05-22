-- HelpButton.client.luau
-- Toggles raise/lower arm animations when the HelpButton is clicked.
-- Lives in StarterPlayerScripts via Rojo, accesses GUI through PlayerGui.

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- ============================================================================
-- GUI References
-- ============================================================================
local playerGui = player:WaitForChild("PlayerGui", math.huge)
local gameGui = playerGui:WaitForChild("GameGui", math.huge)
local botonesFrame = gameGui:WaitForChild("BotonesIzquierdaFrame", math.huge)
local helpButton = botonesFrame:WaitForChild("HelpButton", math.huge)
local helpButtonText = helpButton:WaitForChild("HelpButtonText", math.huge)

-- ============================================================================
-- Animation Assets
-- ============================================================================
local animLevantarBrazos = Instance.new("Animation")
animLevantarBrazos.AnimationId = "rbxassetid://76711629354070"

local animBrazosLoop = Instance.new("Animation")
animBrazosLoop.AnimationId = "rbxassetid://81576862892743"

local animBajarBrazos = Instance.new("Animation")
animBajarBrazos.AnimationId = "rbxassetid://80968501356802"

-- ============================================================================
-- State
-- ============================================================================
local isHelpActive = false
local isTransitioning = false

-- Animation tracks (recreated on each respawn)
local trackLevantarBrazos = nil
local trackBrazosLoop = nil
local trackBajarBrazos = nil

-- ============================================================================
-- UI Colors
-- ============================================================================
local COLOR_OFF_BG = Color3.fromRGB(52, 0, 1)
local COLOR_ON_BG = Color3.fromRGB(23, 52, 0)
local COLOR_OFF_TEXT = Color3.fromRGB(255, 0, 0)
local COLOR_ON_TEXT = Color3.fromRGB(0, 255, 0)

-- ============================================================================
-- UI Update
-- ============================================================================
local function updateUI()
	if isHelpActive then
		helpButtonText.Text = "HELP ON"
		helpButtonText.TextColor3 = COLOR_ON_TEXT
		helpButton.BackgroundColor3 = COLOR_ON_BG
	else
		helpButtonText.Text = "HELP OFF"
		helpButtonText.TextColor3 = COLOR_OFF_TEXT
		helpButton.BackgroundColor3 = COLOR_OFF_BG
	end
end

-- ============================================================================
-- Animation Setup (called on each spawn)
-- ============================================================================
local function setupAnimations(character)
	local humanoid = character:WaitForChild("Humanoid")
	local animator = humanoid:WaitForChild("Animator")

	trackLevantarBrazos = animator:LoadAnimation(animLevantarBrazos)
	trackLevantarBrazos.Priority = Enum.AnimationPriority.Action4
	trackLevantarBrazos.Looped = false

	trackBrazosLoop = animator:LoadAnimation(animBrazosLoop)
	trackBrazosLoop.Priority = Enum.AnimationPriority.Action4
	trackBrazosLoop.Looped = true

	trackBajarBrazos = animator:LoadAnimation(animBajarBrazos)
	trackBajarBrazos.Priority = Enum.AnimationPriority.Action4
	trackBajarBrazos.Looped = false
end

-- ============================================================================
-- Toggle Logic
-- ============================================================================
local function onHelpButtonClicked()
	if isTransitioning then
		return
	end

	isTransitioning = true

	if not isHelpActive then
		-- OFF → ON: Raise arms
		if trackLevantarBrazos and trackBrazosLoop then
			trackLevantarBrazos:Play()
			trackLevantarBrazos.Stopped:Wait()
			trackBrazosLoop:Play()
		end
		isHelpActive = true
		updateUI()
	else
		-- ON → OFF: Lower arms
		if trackBrazosLoop and trackBajarBrazos then
			trackBrazosLoop:Stop()
			trackBajarBrazos:Play()
			trackBajarBrazos.Stopped:Wait()
		end
		isHelpActive = false
		updateUI()
	end

	isTransitioning = false
end

-- ============================================================================
-- Character Setup (handles initial load + respawns)
-- ============================================================================
local function onCharacterAdded(character)
	-- Stop any playing tracks from previous life
	if trackBrazosLoop and trackBrazosLoop.IsPlaying then
		trackBrazosLoop:Stop(0)
	end

	-- Reset state
	isHelpActive = false
	isTransitioning = false
	updateUI()

	-- Load new animation tracks
	setupAnimations(character)
end

-- Connect to current character (if already loaded) and future respawns
if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

-- ============================================================================
-- Button Connection
-- ============================================================================
helpButton.MouseButton1Click:Connect(onHelpButtonClicked)

-- Set initial UI state
updateUI()
