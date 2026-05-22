-- HelpButton.client.luau
-- Toggles raise/lower arm animations when the HelpButton is clicked.
-- Lives in StarterPlayerScripts via Rojo, accesses GUI through PlayerGui.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- RemoteEvent para solicitar toggle de plataforma al servidor (se obtiene con timeout)
local toggleEvent: RemoteEvent? = nil

task.spawn(function()
	toggleEvent = ReplicatedStorage:WaitForChild("TogglePlataformaEvent", 30)
	if not toggleEvent then
		warn("[HelpButton] No se encontró TogglePlataformaEvent después de 30s")
	end
end)

-- ============================================================================
-- GUI References
-- ============================================================================
local playerGui = player:WaitForChild("PlayerGui", math.huge)
local helpButton = nil
local helpButtonText = nil
local clickConnection = nil

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
	if not helpButton or not helpButtonText then
		return
	end
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
		-- OFF → ON: Raise arms + show platform
		if trackLevantarBrazos and trackBrazosLoop then
			trackLevantarBrazos:Play()
			trackLevantarBrazos.Stopped:Wait()
			trackBrazosLoop:Play()
		end
		isHelpActive = true
		updateUI()
		if toggleEvent then
			toggleEvent:FireServer(true)
		end
	else
		-- ON → OFF: Hide platform FIRST, then lower arms
		if toggleEvent then
			toggleEvent:FireServer(false)
		end
		isHelpActive = false
		updateUI()
		if trackBrazosLoop and trackBajarBrazos then
			trackBrazosLoop:Stop()
			trackBajarBrazos:Play()
			trackBajarBrazos.Stopped:Wait()
		end
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
	if trackLevantarBrazos and trackLevantarBrazos.IsPlaying then
		trackLevantarBrazos:Stop(0)
	end
	if trackBajarBrazos and trackBajarBrazos.IsPlaying then
		trackBajarBrazos:Stop(0)
	end

	-- Nullificar tracks viejos ANTES de setupAnimations
	-- Esto evita que clicks durante el yield usen tracks del Animator destruido
	trackLevantarBrazos = nil
	trackBrazosLoop = nil
	trackBajarBrazos = nil

	-- Reset state
	isHelpActive = false
	isTransitioning = false

	-- Actualizar referencias de UI (por si ResetOnSpawn destruyó la anterior)
	if clickConnection then
		clickConnection:Disconnect()
		clickConnection = nil
	end

	local success = pcall(function()
		local gameGui = playerGui:WaitForChild("GameGui", 10)
		if not gameGui then return end
		local botonesFrame = gameGui:WaitForChild("BotonesIzquierdaFrame", 10)
		helpButton = botonesFrame:WaitForChild("HelpButton", 10)
		helpButtonText = helpButton:WaitForChild("HelpButtonText", 10)
	end)

	if not success or not helpButton then
		return
	end

	clickConnection = helpButton.MouseButton1Click:Connect(onHelpButtonClicked)
	updateUI()

	-- Load new animation tracks (puede hacer yield en WaitForChild)
	setupAnimations(character)
end

-- Connect to current character (if already loaded) and future respawns
if player.Character then
	task.spawn(onCharacterAdded, player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)
