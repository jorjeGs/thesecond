-- InviteFriendsButton.client.luau
-- Handles prompting the player to invite friends when the InviteFriendsButton is clicked.
-- Lives in StarterPlayerScripts via Rojo, accesses GUI through PlayerGui.

local Players = game:GetService("Players")
local SocialService = game:GetService("SocialService")
local player = Players.LocalPlayer

-- ============================================================================
-- GUI References & State
-- ============================================================================
local playerGui = player:WaitForChild("PlayerGui", math.huge)
local inviteButton = nil
local clickConnection = nil

-- ============================================================================
-- Invite Logic
-- ============================================================================
local function onInviteButtonClicked()
	local success, err = pcall(function()
		SocialService:PromptGameInvite(player)
	end)
	if not success then
		warn("[InviteFriendsButton] Error al abrir el menú de invitaciones: " .. tostring(err))
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
		local botonesDerechaFrame = gameGui:WaitForChild("BotonesDerechaFrame", 10)
		inviteButton = botonesDerechaFrame:WaitForChild("InviteFriendsButton", 10)
	end)

	if not success or not inviteButton then
		return
	end

	-- Connect the click event
	clickConnection = inviteButton.MouseButton1Click:Connect(onInviteButtonClicked)
end

-- Connect to current character (if already loaded) and future respawns
if player.Character then
	task.spawn(onCharacterAdded, player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)
