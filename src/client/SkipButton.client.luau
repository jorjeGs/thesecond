-- SkipButton.client.luau
-- Handles prompting the player to purchase the SkipStage Developer Product.
-- Lives in StarterPlayerScripts via Rojo, accesses GUI through PlayerGui.

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local player = Players.LocalPlayer

local SKIP_STAGE_PRODUCT_ID = 3596942758

-- ============================================================================
-- GUI References & State
-- ============================================================================
local playerGui = player:WaitForChild("PlayerGui", math.huge)
local skipButton = nil
local clickConnection = nil

-- ============================================================================
-- Purchase Logic
-- ============================================================================
local function onSkipButtonClicked()
	local success, err = pcall(function()
		MarketplaceService:PromptProductPurchase(player, SKIP_STAGE_PRODUCT_ID)
	end)
	if not success then
		warn("[SkipButton] Error al solicitar la compra de Skip Stage: " .. tostring(err))
	end
end

-- ============================================================================
-- Character Setup (handles initial load + respawns due to ResetOnSpawn)
-- ============================================================================
local function onCharacterAdded(character)
	-- Disconnect old connection if it exists
	if clickConnection then
		clickConnection:Disconnect()
		clickConnection = nil
	end

	-- Find active GUI elements
	local success = pcall(function()
		local gameGui = playerGui:WaitForChild("GameGui", 10)
		if not gameGui then return end
		local botonesIzquierdaFrame = gameGui:WaitForChild("BotonesIzquierdaFrame", 10)
		skipButton = botonesIzquierdaFrame:WaitForChild("SkipButton", 10)
	end)

	if not success or not skipButton then
		warn("[SkipButton] No se pudo encontrar el botón SkipButton en PlayerGui.GameGui.BotonesIzquierdaFrame")
		return
	end

	-- Connect the click event
	clickConnection = skipButton.MouseButton1Click:Connect(onSkipButtonClicked)
end

-- Connect to current character (if already loaded) and future respawns
if player.Character then
	task.spawn(onCharacterAdded, player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)
