-- MenuManager.client.luau
-- Manages the visibility of the Rebirth and Shop menus in GameGui.
-- Lives in StarterPlayerScripts (Client folder in Rojo), updates connections on CharacterAdded.

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- ============================================================================
-- GUI References & State
-- ============================================================================
local playerGui = player:WaitForChild("PlayerGui", math.huge)

local connections = {}

-- Clean up any existing event connections
local function disconnectAll()
	for _, conn in ipairs(connections) do
		if conn then
			conn:Disconnect()
		end
	end
	table.clear(connections)
end

-- ============================================================================
-- Character Setup (handles initial load + respawns)
-- ============================================================================
local function onCharacterAdded(character)
	disconnectAll()

	local gameGui = playerGui:WaitForChild("GameGui", 10)
	if not gameGui then
		warn("[MenuManager] GameGui not found in PlayerGui")
		return
	end

	local botonesIzquierdaFrame = gameGui:WaitForChild("BotonesIzquierdaFrame", 10)
	local center = gameGui:WaitForChild("Center", 10)

	if not botonesIzquierdaFrame or not center then
		warn("[MenuManager] BotonesIzquierdaFrame or Center not found in GameGui")
		return
	end

	local buttonsFrame = botonesIzquierdaFrame:WaitForChild("ButtonsFrame", 10)
	local rebirthMenu = center:WaitForChild("RebirthMenu", 10)
	local shopMenu = center:WaitForChild("ShopMenu", 10)

	if not buttonsFrame or not rebirthMenu or not shopMenu then
		warn("[MenuManager] Required buttons or menus not found")
		return
	end

	local rebirthButton = buttonsFrame:WaitForChild("RebirthButton", 10)
	local shopButton = buttonsFrame:WaitForChild("ShopButton", 10)
	local rebirthCloseButton = rebirthMenu:WaitForChild("CloseButton", 10)
	local shopCloseButton = shopMenu:WaitForChild("CloseButton", 10)

	if not rebirthButton or not shopButton or not rebirthCloseButton or not shopCloseButton then
		warn("[MenuManager] Rebirth/Shop buttons or their CloseButtons not found")
		return
	end

	-- 1. Initialize menus as invisible
	rebirthMenu.Visible = false
	shopMenu.Visible = false

	-- 2. Connect Open Menu Events (with mutual exclusivity)
	local rebirthOpenConn = rebirthButton.MouseButton1Click:Connect(function()
		rebirthMenu.Visible = true
		shopMenu.Visible = false
	end)
	table.insert(connections, rebirthOpenConn)

	local shopOpenConn = shopButton.MouseButton1Click:Connect(function()
		shopMenu.Visible = true
		rebirthMenu.Visible = false
	end)
	table.insert(connections, shopOpenConn)

	-- 3. Connect Close Menu Events
	local rebirthCloseConn = rebirthCloseButton.MouseButton1Click:Connect(function()
		rebirthMenu.Visible = false
	end)
	table.insert(connections, rebirthCloseConn)

	local shopCloseConn = shopCloseButton.MouseButton1Click:Connect(function()
		shopMenu.Visible = false
	end)
	table.insert(connections, shopCloseConn)
end

-- Connect to current character (if already loaded) and future respawns
if player.Character then
	task.spawn(onCharacterAdded, player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)
