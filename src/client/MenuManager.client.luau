-- MenuManager.client.luau
-- Manages the visibility of the Rebirth and Shop menus in GameGui.
-- Lives in StarterPlayerScripts (Client folder in Rojo), updates connections on CharacterAdded.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- ============================================================================
-- GUI References & State
-- ============================================================================
local playerGui = player:WaitForChild("PlayerGui", math.huge)
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local connections = {}
local statConnections = {}

-- Clean up any existing event connections
local function disconnectAll()
	for _, conn in ipairs(connections) do
		if conn then
			conn:Disconnect()
		end
	end
	table.clear(connections)

	for _, conn in ipairs(statConnections) do
		if conn then
			conn:Disconnect()
		end
	end
	table.clear(statConnections)
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

	local rebirthOpenButton = buttonsFrame:WaitForChild("RebirthButton", 10)
	local shopOpenButton = buttonsFrame:WaitForChild("ShopButton", 10)
	local rebirthCloseButton = rebirthMenu:WaitForChild("CloseButton", 10)
	local shopCloseButton = shopMenu:WaitForChild("CloseButton", 10)

	if not rebirthOpenButton or not shopOpenButton or not rebirthCloseButton or not shopCloseButton then
		warn("[MenuManager] Open/Close buttons not found")
		return
	end

	-- Rebirth Menu internal elements
	local currentRebirthMultiplierText = rebirthMenu:WaitForChild("CurrentRebirthMultiplierText", 10)
	local currentRebirthText = rebirthMenu:WaitForChild("CurrentRebirthText", 10)
	local rebirthTriggerButton = rebirthMenu:WaitForChild("RebirthButton", 10)
	local rebirthButtonText = rebirthTriggerButton and rebirthTriggerButton:WaitForChild("RebirthButtonText", 10)

	if not currentRebirthMultiplierText or not currentRebirthText or not rebirthTriggerButton or not rebirthButtonText then
		warn("[MenuManager] Rebirth menu internal text/buttons not found")
		return
	end

	-- 1. Initialize menus as invisible
	rebirthMenu.Visible = false
	shopMenu.Visible = false

	-- 2. Connect Open Menu Events (with mutual exclusivity)
	local rebirthOpenConn = rebirthOpenButton.MouseButton1Click:Connect(function()
		rebirthMenu.Visible = true
		shopMenu.Visible = false
	end)
	table.insert(connections, rebirthOpenConn)

	local shopOpenConn = shopOpenButton.MouseButton1Click:Connect(function()
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

	-- 4. Rebirth Client Logic & UI Updates
	local leaderstats = player:WaitForChild("leaderstats", 15)
	if leaderstats then
		local rebirthsStat = leaderstats:WaitForChild("Rebirths", 10)
		local coinsStat = leaderstats:WaitForChild("Coins", 10)

		local REBIRTH_COST = 1000

		local function updateRebirthUI()
			local rebirths = rebirthsStat and rebirthsStat.Value or 0
			local coins = coinsStat and coinsStat.Value or 0

			currentRebirthText.Text = "CurrentRebirth: " .. rebirths
			currentRebirthMultiplierText.Text = "Current Rebirth Multiplier: x" .. (1 + (rebirths * 0.5))

			-- Display text colors based on whether player can afford rebirth
			if coins >= REBIRTH_COST then
				rebirthButtonText.TextColor3 = Color3.fromRGB(85, 255, 127) -- Light green
			else
				rebirthButtonText.TextColor3 = Color3.fromRGB(255, 85, 85) -- Light red
			end
			rebirthButtonText.Text = "Rebirth for " .. REBIRTH_COST .. " Coins"
		end

		-- Connect changes
		if rebirthsStat then
			local conn = rebirthsStat.Changed:Connect(updateRebirthUI)
			table.insert(statConnections, conn)
		end
		if coinsStat then
			local conn = coinsStat.Changed:Connect(updateRebirthUI)
			table.insert(statConnections, conn)
		end

		updateRebirthUI()
	end

	-- Connect Rebirth Button click to Fire Server
	local rebirthTriggerConn = rebirthTriggerButton.MouseButton1Click:Connect(function()
		Remotes.RebirthRequest:FireServer()
	end)
	table.insert(connections, rebirthTriggerConn)
end

-- Connect to current character (if already loaded) and future respawns
if player.Character then
	task.spawn(onCharacterAdded, player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)
