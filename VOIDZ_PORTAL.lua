-- VOIDZ HUB · Portal Sandbox
-- BUILD 2026-10-29-1.4.0
-- Place 75108253383447 · Universe 10767619742
-- RightShift shows and hides the hub.

local BUILD = "2026-10-29-1.4.0"
local PLACE_ID = 75108253383447
local UNIVERSE_ID = 10767619742

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	warn("[VOIDZ] LocalPlayer missing")
	return
end

local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
if not PlayerGui then
	PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 15)
end
if not PlayerGui then
	warn("[VOIDZ] PlayerGui missing")
	return
end

local ENV = (type(getgenv) == "function" and getgenv()) or _G
if type(ENV.VOIDZ_PORTAL_STOP) == "function" then
	pcall(ENV.VOIDZ_PORTAL_STOP)
end
local stale = PlayerGui:FindFirstChild("VOIDZ_PORTAL")
if stale then
	stale:Destroy()
end

local C = {
	bg = Color3.fromRGB(14, 14, 16),
	bar = Color3.fromRGB(18, 18, 20),
	side = Color3.fromRGB(16, 16, 18),
	card = Color3.fromRGB(28, 28, 32),
	card2 = Color3.fromRGB(40, 40, 46),
	line = Color3.fromRGB(55, 55, 62),
	text = Color3.fromRGB(245, 245, 247),
	muted = Color3.fromRGB(160, 160, 170),
	accent = Color3.fromRGB(186, 132, 255),
	good = Color3.fromRGB(110, 220, 160),
	warn = Color3.fromRGB(255, 196, 120),
	bad = Color3.fromRGB(255, 120, 130),
}

local KEYS = {
	{ code = Enum.KeyCode.T, name = "T", label = "Portal Gun" },
	{ code = Enum.KeyCode.Q, name = "Q", label = "Knife" },
	{ code = Enum.KeyCode.E, name = "E", label = "Regenerate" },
	{ code = Enum.KeyCode.F, name = "F", label = "Blender" },
	{ code = Enum.KeyCode.R, name = "R", label = "Dimensions" },
	{ code = Enum.KeyCode.X, name = "X", label = "Laser / Mech" },
	{ code = Enum.KeyCode.V, name = "V", label = "Robo Arms" },
}

local state = {
	page = "Home",
	fly = false,
	noclip = false,
	speed = false,
	walkSpeed = 32,
	flySpeed = 80,
	infJump = false,
	clickTp = false,
	antiVoid = false,
	esp = false,
	fullbright = false,
	autoRegen = false,
	autoKill = false,
	autoFarm = false,
	autoQuest = false,
	autoIq = false,
	iqKills = true,
	iqBusy = false,
	iqText = "not found",
	iqSource = "",
	iqLast = nil,
	iqTried = {},
	questAny = false,
	killSelected = false,
	skipTeam = true,
	farmPlayers = true,
	killRange = 500,
	questRange = 400,
	locking = false,
	autoBuild = false,
	autoMat = false,
	material = nil,
	matOpen = false,
	matList = {},
	matIndex = {},
	matScanAt = 0,
	tried = {},
	buildKind = "Pad",
	buildSize = 24,
	buildReach = 16,
	buildOrigin = nil,
	fovOn = false,
	fov = 90,
	selected = nil,
	spectating = nil,
	marks = {},
	scan = {},
	safe = nil,
	speedApplied = false,
	minimized = false,
	query = "",
	alive = true,
}

local logs = {}
local conns = {}
local held = {}
local savedLight = nil
local savedFov = nil
local savedWalk = nil
local collideSaved = {}
local gui
local window
local centerHolder
local playerList
local pageTitle
local statusLabel
local navButtons = {}

local function keepChat()
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
	end)
	pcall(function()
		local textChat = game:GetService("TextChatService")
		if textChat.ChatInputBarConfiguration then
			textChat.ChatInputBarConfiguration.Enabled = true
		end
		if textChat.ChatWindowConfiguration then
			textChat.ChatWindowConfiguration.Enabled = true
		end
	end)
end

local function inPortal()
	return game.PlaceId == PLACE_ID or game.GameId == UNIVERSE_ID
end

local function pushLog(text)
	local stamp = os.date("%H:%M:%S")
	table.insert(logs, 1, stamp .. "  " .. text)
	while #logs > 40 do
		table.remove(logs)
	end
	if statusLabel then
		statusLabel.Text = text
	end
end

local function requireGame()
	if inPortal() then
		return true
	end
	pushLog("Join Portal Sandbox first")
	return false
end

local function characterParts()
	local character = LocalPlayer.Character
	if not character then
		return nil, nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	return character, humanoid, root
end

local function corner(parent, radius)
	local item = Instance.new("UICorner")
	item.CornerRadius = UDim.new(0, radius or 8)
	item.Parent = parent
	return item
end

local function sendKey(code, label)
	if not requireGame() then
		return
	end
	local ok = pcall(function()
		VirtualInputManager:SendKeyEvent(true, code, false, game)
		task.delay(0.06, function()
			pcall(function()
				VirtualInputManager:SendKeyEvent(false, code, false, game)
			end)
		end)
	end)
	if ok then
		pushLog("Sent " .. label)
	else
		pushLog("Could not send " .. label)
	end
end

local function clearFly(root)
	if not root then
		local _, _, found = characterParts()
		root = found
	end
	if not root then
		return
	end
	local gyro = root:FindFirstChild("VOIDZ_FlyBG")
	local velocity = root:FindFirstChild("VOIDZ_FlyBV")
	if gyro then
		gyro:Destroy()
	end
	if velocity then
		velocity:Destroy()
	end
	local humanoid = root.Parent and root.Parent:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.PlatformStand = false
	end
end

local function ensureFly(root)
	local gyro = root:FindFirstChild("VOIDZ_FlyBG")
	if not gyro then
		gyro = Instance.new("BodyGyro")
		gyro.Name = "VOIDZ_FlyBG"
		gyro.MaxTorque = Vector3.new(1, 1, 1) * 400000
		gyro.P = 20000
		gyro.Parent = root
	end
	local velocity = root:FindFirstChild("VOIDZ_FlyBV")
	if not velocity then
		velocity = Instance.new("BodyVelocity")
		velocity.Name = "VOIDZ_FlyBV"
		velocity.MaxForce = Vector3.new(1, 1, 1) * 400000
		velocity.Velocity = Vector3.zero
		velocity.Parent = root
	end
	local humanoid = root.Parent and root.Parent:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.PlatformStand = true
	end
	return gyro, velocity
end

local function flyVector()
	if UserInputService:GetFocusedTextBox() then
		return Vector3.zero
	end
	local camera = workspace.CurrentCamera
	if not camera then
		return Vector3.zero
	end
	local move = Vector3.zero
	local look = camera.CFrame.LookVector
	local right = camera.CFrame.RightVector
	if held[Enum.KeyCode.W] then
		move = move + look
	end
	if held[Enum.KeyCode.S] then
		move = move - look
	end
	if held[Enum.KeyCode.D] then
		move = move + right
	end
	if held[Enum.KeyCode.A] then
		move = move - right
	end
	if held[Enum.KeyCode.Space] then
		move = move + Vector3.yAxis
	end
	if held[Enum.KeyCode.LeftControl] or held[Enum.KeyCode.LeftShift] then
		move = move - Vector3.yAxis
	end
	if move.Magnitude < 0.05 then
		return Vector3.zero
	end
	return move.Unit * state.flySpeed
end

local function setFullbright(on)
	if on and not savedLight then
		savedLight = {
			Brightness = Lighting.Brightness,
			ClockTime = Lighting.ClockTime,
			FogEnd = Lighting.FogEnd,
			GlobalShadows = Lighting.GlobalShadows,
		}
	end
	if on then
		Lighting.Brightness = 2
		Lighting.ClockTime = 14
		Lighting.FogEnd = 100000
		Lighting.GlobalShadows = false
	elseif savedLight then
		Lighting.Brightness = savedLight.Brightness
		Lighting.ClockTime = savedLight.ClockTime
		Lighting.FogEnd = savedLight.FogEnd
		Lighting.GlobalShadows = savedLight.GlobalShadows
		savedLight = nil
	end
end

local function setFov(on)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	if on then
		if not savedFov then
			savedFov = camera.FieldOfView
		end
		camera.FieldOfView = state.fov
	elseif savedFov then
		camera.FieldOfView = savedFov
		savedFov = nil
	end
end

local function clearEsp()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character then
			local highlight = character:FindFirstChild("VOIDZ_HL")
			local tag = character:FindFirstChild("VOIDZ_TAG")
			if highlight then
				highlight:Destroy()
			end
			if tag then
				tag:Destroy()
			end
		end
	end
end

local function applyEsp(player)
	if player == LocalPlayer then
		return
	end
	local character = player.Character
	if not character then
		return
	end
	if not state.esp then
		local highlight = character:FindFirstChild("VOIDZ_HL")
		local tag = character:FindFirstChild("VOIDZ_TAG")
		if highlight then
			highlight:Destroy()
		end
		if tag then
			tag:Destroy()
		end
		return
	end
	if not character:FindFirstChild("VOIDZ_HL") then
		local highlight = Instance.new("Highlight")
		highlight.Name = "VOIDZ_HL"
		highlight.FillColor = C.accent
		highlight.OutlineColor = Color3.new(1, 1, 1)
		highlight.FillTransparency = 0.65
		highlight.OutlineTransparency = 0.2
		highlight.Parent = character
	end
	if not character:FindFirstChild("VOIDZ_TAG") then
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "VOIDZ_TAG"
		billboard.Size = UDim2.fromOffset(160, 24)
		billboard.StudsOffset = Vector3.new(0, 3.4, 0)
		billboard.AlwaysOnTop = true
		billboard.Parent = character
		local text = Instance.new("TextLabel")
		text.Name = "Name"
		text.BackgroundTransparency = 1
		text.Size = UDim2.fromScale(1, 1)
		text.Font = Enum.Font.GothamBold
		text.TextSize = 14
		text.TextColor3 = C.text
		text.TextStrokeTransparency = 0.45
		text.Text = player.DisplayName
		text.Parent = billboard
	end
end

local function refreshEsp()
	for _, player in ipairs(Players:GetPlayers()) do
		applyEsp(player)
	end
end

local function stopSpectate()
	state.spectating = nil
	local _, humanoid = characterParts()
	local camera = workspace.CurrentCamera
	if camera and humanoid then
		camera.CameraSubject = humanoid
	end
end

local function spectate(player)
	if not player or not requireGame() then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local camera = workspace.CurrentCamera
	if humanoid and camera then
		camera.CameraSubject = humanoid
		state.spectating = player
		pushLog("Spectating " .. player.DisplayName)
	else
		pushLog("No character to spectate")
	end
end

local function teleportTo(cf, label)
	if not requireGame() then
		return
	end
	local _, _, root = characterParts()
	if not root or not cf then
		pushLog("Nothing to teleport to")
		return
	end
	root.CFrame = cf
	pushLog(label or "Teleported")
end

local function teleportToPlayer(player)
	if not player then
		pushLog("Pick a player on the right")
		return
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		pushLog("That player has no character")
		return
	end
	teleportTo(root.CFrame * CFrame.new(0, 0, 4), "Teleported to " .. player.DisplayName)
end

local function selectedPlayer()
	if not state.selected then
		return nil
	end
	return Players:GetPlayerByUserId(state.selected)
end

local function pivotOf(inst)
	if inst:IsA("BasePart") then
		return inst.CFrame
	end
	if inst:IsA("Model") then
		if inst.PrimaryPart then
			return inst.PrimaryPart.CFrame
		end
		local part = inst:FindFirstChildWhichIsA("BasePart", true)
		if part then
			return part.CFrame
		end
	end
	return nil
end

local function scanWorld()
	local found = {}
	local seen = 0
	for _, inst in ipairs(workspace:GetDescendants()) do
		seen = seen + 1
		if seen > 6000 or #found >= 30 then
			break
		end
		local name = string.lower(inst.Name)
		local match = string.find(name, "portal", 1, true)
			or string.find(name, "dimension", 1, true)
			or string.find(name, "blender", 1, true)
		if match and (inst:IsA("BasePart") or inst:IsA("Model")) then
			table.insert(found, inst)
		end
	end
	state.scan = found
	pushLog("Found " .. tostring(#found) .. " portal objects")
	return found
end

local function listTools()
	local items = {}
	local function take(container)
		if not container then
			return
		end
		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("Tool") then
				table.insert(items, child)
			end
		end
	end
	take(LocalPlayer:FindFirstChild("Backpack"))
	take(LocalPlayer.Character)
	return items
end

local function equipTool(tool)
	local _, humanoid = characterParts()
	if humanoid and tool then
		pcall(function()
			humanoid:EquipTool(tool)
		end)
		pushLog("Equipped " .. tool.Name)
	end
end

local function findTool(hints)
	for _, tool in ipairs(listTools()) do
		local name = string.lower(tool.Name)
		for _, hint in ipairs(hints) do
			if string.find(name, hint, 1, true) then
				return tool
			end
		end
	end
	return nil
end

local function restoreCollide()
	for part, was in pairs(collideSaved) do
		if typeof(part) == "Instance" and part.Parent and part:IsA("BasePart") then
			part.CanCollide = was
		end
	end
	table.clear(collideSaved)
end

local function sweepHubObjects()
	local names = {
		VOIDZ_HL = true,
		VOIDZ_TAG = true,
		VOIDZ_FlyBG = true,
		VOIDZ_FlyBV = true,
	}
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character then
			for _, inst in ipairs(character:GetDescendants()) do
				if names[inst.Name] then
					inst:Destroy()
				end
			end
		end
	end
end

local function restoreCharacter()
	local _, humanoid, root = characterParts()
	clearFly(root)
	restoreCollide()
	if humanoid then
		humanoid.PlatformStand = false
		if savedWalk ~= nil then
			humanoid.WalkSpeed = savedWalk
			savedWalk = nil
		end
	end
	state.speedApplied = false
end

local BUILD_FOLDER = "VOIDZ_BUILD"

local function clearBuild()
	state.buildOrigin = nil
	local folder = workspace:FindFirstChild(BUILD_FOLDER)
	if folder then
		folder:Destroy()
	end
end

local function flatLook(root)
	local look = root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 0.05 then
		flat = Vector3.new(0, 0, -1)
	end
	return CFrame.lookAt(root.Position, root.Position + flat.Unit)
end

local function addBlock(folder, cf, size, color)
	if #folder:GetChildren() >= 80 then
		return nil
	end
	local part = Instance.new("Part")
	part.Name = "VOIDZ_Block"
	part.Anchored = true
	part.CanCollide = true
	part.CanQuery = true
	part.CanTouch = true
	part.CastShadow = false
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color or Color3.fromRGB(78, 58, 132)
	part.Size = size
	part.CFrame = cf
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = folder
	return part
end

local function addWedge(folder, cf, size, color)
	if #folder:GetChildren() >= 80 then
		return nil
	end
	local part = Instance.new("WedgePart")
	part.Name = "VOIDZ_Block"
	part.Anchored = true
	part.CanCollide = true
	part.CanQuery = true
	part.CanTouch = true
	part.CastShadow = false
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color or Color3.fromRGB(78, 58, 132)
	part.Size = size
	part.CFrame = cf
	part.Parent = folder
	return part
end

local function placeBuild(kind, root, quiet)
	if not root then
		local _, _, found = characterParts()
		root = found
	end
	if not root then
		if not quiet then
			pushLog("No character to build from")
		end
		return
	end
	clearBuild()
	local folder = Instance.new("Folder")
	folder.Name = BUILD_FOLDER
	folder.Parent = workspace
	local base = flatLook(root)
	local floorColor = Color3.fromRGB(78, 58, 132)
	local wallColor = Color3.fromRGB(36, 28, 58)
	local span = math.clamp(state.buildSize or 24, 12, 48)
	state.buildKind = kind
	state.buildOrigin = root.Position
	state.buildReach = span
	if kind == "Stairs" then
		for step = 0, 9 do
			addBlock(folder, base * CFrame.new(0, -2.5 + step * 1.2, -3 - step * 3), Vector3.new(10, 1, 3.2), floorColor)
		end
		state.buildReach = 34
	elseif kind == "Wall" then
		addBlock(folder, base * CFrame.new(0, 5, -14), Vector3.new(span, 16, 1.5), wallColor)
		state.buildReach = 18
	elseif kind == "Portal bay" then
		local half = span * 0.5
		addBlock(folder, base * CFrame.new(0, -3, 0), Vector3.new(span, 1, span), floorColor)
		addBlock(folder, base * CFrame.new(0, 6, -(half + 2)), Vector3.new(span, 16, 1.5), wallColor)
		addBlock(folder, base * CFrame.new(-half, 4, -4), Vector3.new(1.5, 12, 14), wallColor)
		state.buildReach = half + 4
		if not quiet then
			sendKey(Enum.KeyCode.T, "Portal Gun")
		end
	elseif kind == "Bridge" then
		for step = 0, 9 do
			addBlock(folder, base * CFrame.new(0, -3, -6 - step * 8), Vector3.new(10, 1, 8), floorColor)
		end
		state.buildReach = 88
	elseif kind == "Room" then
		local half = span * 0.5
		addBlock(folder, base * CFrame.new(0, -3, 0), Vector3.new(span, 1, span), floorColor)
		addBlock(folder, base * CFrame.new(0, 5, -half), Vector3.new(span, 12, 1), wallColor)
		addBlock(folder, base * CFrame.new(-half, 5, 0), Vector3.new(1, 12, span), wallColor)
		addBlock(folder, base * CFrame.new(half, 5, 0), Vector3.new(1, 12, span), wallColor)
		addBlock(folder, base * CFrame.new(0, 11, 0), Vector3.new(span, 1, span), floorColor)
		state.buildReach = half
	elseif kind == "Ramp" then
		addWedge(folder, base * CFrame.new(0, 1, -16) * CFrame.Angles(0, math.pi, 0), Vector3.new(14, 8, 28), floorColor)
		state.buildReach = 32
	elseif kind == "Tower" then
		for level = 0, 4 do
			addBlock(folder, base * CFrame.new(0, -3 + level * 8, 0), Vector3.new(16, 1, 16), floorColor)
		end
		for step = 0, 10 do
			addBlock(folder, base * CFrame.new(0, -1 + step * 3.2, -10), Vector3.new(5, 1, 3), floorColor)
		end
		state.buildReach = 16
	else
		addBlock(folder, base * CFrame.new(0, -3, 0), Vector3.new(span, 1, span), floorColor)
		state.buildKind = "Pad"
		state.buildReach = span * 0.5
	end
	if not quiet then
		pushLog("Built " .. state.buildKind .. " (" .. tostring(#folder:GetChildren()) .. " parts)")
	end
end

local function prettyMaterial(id)
	if string.sub(id, 1, 5) == "name:" then
		return "Item: " .. string.sub(id, 6)
	end
	return string.gsub(id, "(%l)(%u)", "%1 %2")
end

local function dropHeld()
	local welds = {}
	local function take(rootInst)
		if not rootInst then
			return
		end
		for _, child in ipairs(rootInst:GetDescendants()) do
			if child.Name == "VOIDZ_Hold" then
				table.insert(welds, child)
			end
		end
	end
	take(LocalPlayer.Character)
	take(workspace)
	for _, weld in ipairs(welds) do
		local part = weld.Part1
		weld:Destroy()
		if part and part:IsA("BasePart") then
			part.CanCollide = true
		end
	end
end

local function materialEligible(part)
	if not part:IsA("BasePart") then
		return false
	end
	if part.Name == "VOIDZ_Block" or part.Name == "HumanoidRootPart" or part.Name == "VOIDZ_Follow" then
		return false
	end
	if part:FindFirstChild("VOIDZ_Hold") then
		return false
	end
	local character = LocalPlayer.Character
	if character and part:IsDescendantOf(character) then
		return false
	end
	local built = workspace:FindFirstChild(BUILD_FOLDER)
	if built and part:IsDescendantOf(built) then
		return false
	end
	local owner = part:FindFirstAncestorOfClass("Model")
	if owner and Players:GetPlayerFromCharacter(owner) then
		return false
	end
	if part.Transparency >= 0.95 then
		return false
	end
	if part.Size.X > 30 or part.Size.Y > 30 or part.Size.Z > 30 then
		return false
	end
	return true
end

local function scanMaterials()
	local index = {}
	local seenModel = {}
	local seen = 0
	for _, inst in ipairs(workspace:GetDescendants()) do
		seen = seen + 1
		if seen > 6000 then
			break
		end
		if inst:IsA("BasePart") and materialEligible(inst) then
			local target = inst
			local model = inst:FindFirstAncestorOfClass("Model")
			if model and not Players:GetPlayerFromCharacter(model) then
				if seenModel[model] then
					target = nil
				else
					seenModel[model] = true
					target = model.PrimaryPart or inst
				end
			end
			if target and materialEligible(target) then
				local matKey = target.Material.Name
				index[matKey] = index[matKey] or {}
				table.insert(index[matKey], target)
				if not target.Anchored then
					local label = model and model.Name or target.Name
					if label ~= "" and label ~= "Part" and label ~= "MeshPart" and label ~= "UnionOperation" and label ~= "Model" then
						local nameKey = "name:" .. label
						index[nameKey] = index[nameKey] or {}
						table.insert(index[nameKey], target)
					end
				end
			end
		end
	end
	local list = {}
	for id, parts in pairs(index) do
		table.insert(list, {
			id = id,
			count = #parts,
			label = prettyMaterial(id) .. "  (" .. tostring(#parts) .. ")",
		})
	end
	table.sort(list, function(a, b)
		if a.count == b.count then
			return a.label < b.label
		end
		return a.count > b.count
	end)
	state.matIndex = index
	state.matList = list
	state.matScanAt = os.clock()
	return #list
end

local function wasTried(part)
	local at = state.tried[part]
	if not at then
		return false
	end
	if os.clock() - at < 6 then
		return true
	end
	state.tried[part] = nil
	return false
end

local function closestMaterial(origin)
	local parts = state.matIndex[state.material]
	if not parts then
		return nil
	end
	local best = nil
	local bestDist = math.huge
	for i = #parts, 1, -1 do
		local part = parts[i]
		if not part.Parent or part:FindFirstChild("VOIDZ_Hold") then
			table.remove(parts, i)
		elseif wasTried(part) then
			-- leave it for a later pass
		else
			local dist = (part.Position - origin).Magnitude
			if dist < bestDist then
				bestDist = dist
				best = part
			end
		end
	end
	return best
end

local function fireCollect(inst, root)
	local prompts = {}
	local function collectFrom(obj)
		if not obj then
			return
		end
		for _, child in ipairs(obj:GetChildren()) do
			if child:IsA("ProximityPrompt") or child:IsA("ClickDetector") then
				table.insert(prompts, child)
			end
		end
	end
	collectFrom(inst)
	collectFrom(inst.Parent)
	for _, item in ipairs(prompts) do
		if item:IsA("ProximityPrompt") then
			pcall(function()
				item.MaxActivationDistance = 100
				item.HoldDuration = 0
			end)
			if type(fireproximityprompt) == "function" then
				pcall(fireproximityprompt, item)
				pcall(fireproximityprompt, item, true)
			end
			pcall(function()
				item:InputHoldBegin()
				item:InputHoldEnd()
			end)
		elseif type(fireclickdetector) == "function" then
			pcall(fireclickdetector, item)
		end
	end
	if root and type(firetouchinterest) == "function" and inst:IsA("BasePart") then
		pcall(firetouchinterest, root, inst, 0)
		task.delay(0.12, function()
			if root.Parent and inst.Parent then
				pcall(firetouchinterest, root, inst, 1)
			end
		end)
	end
	local tool = inst:IsA("Tool") and inst or (inst.Parent and inst.Parent:IsA("Tool") and inst.Parent)
	if tool then
		local _, humanoid = characterParts()
		if humanoid then
			pcall(function()
				humanoid:EquipTool(tool)
			end)
		end
	end
end

local function forcePickup(part, root)
	local stand = part.Position + Vector3.new(0, math.max(3, part.Size.Y * 0.5 + 2), 0)
	root.CFrame = CFrame.lookAt(stand, part.Position)
	pcall(function()
		root.AssemblyLinearVelocity = Vector3.zero
	end)
	fireCollect(part, root)
	state.tried[part] = os.clock()
	task.delay(0.2, function()
		if not state.alive or not part.Parent or not part:IsA("BasePart") then
			return
		end
		if part:FindFirstChild("VOIDZ_Hold") then
			return
		end
		local _, _, current = characterParts()
		if not current then
			return
		end
		pcall(function()
			part.Anchored = false
		end)
		if part.Anchored then
			return
		end
		part.CanCollide = false
		part.CFrame = current.CFrame * CFrame.new(0, 1.5, -2)
		local weld = Instance.new("WeldConstraint")
		weld.Name = "VOIDZ_Hold"
		weld.Part0 = current
		weld.Part1 = part
		weld.Parent = part
	end)
end

local function runMaterials(root)
	if not state.autoMat or not inPortal() then
		return
	end
	local now = os.clock()
	if now < (state.nextMat or 0) then
		return
	end
	state.nextMat = now + 0.7
	if not state.material then
		if now > (state.nextMatNote or 0) then
			state.nextMatNote = now + 4
			pushLog("Open Materials and choose one")
		end
		return
	end
	if now - (state.matScanAt or 0) > 3 then
		scanMaterials()
	end
	local part = closestMaterial(root.Position)
	if not part then
		scanMaterials()
		part = closestMaterial(root.Position)
	end
	if not part then
		if now > (state.nextMatNote or 0) then
			state.nextMatNote = now + 4
			pushLog("No " .. prettyMaterial(state.material) .. " left")
		end
		return
	end
	forcePickup(part, root)
	pushLog("Pickup " .. part.Name .. " · " .. prettyMaterial(state.material))
end

local function revertFeatures()
	state.fly = false
	state.noclip = false
	state.speed = false
	state.infJump = false
	state.clickTp = false
	state.antiVoid = false
	state.esp = false
	state.fullbright = false
	state.autoRegen = false
	state.autoKill = false
	state.autoFarm = false
	state.autoQuest = false
	state.autoIq = false
	state.iqBusy = false
	state.autoBuild = false
	state.autoMat = false
	state.locking = false
	state.fovOn = false
	table.clear(held)
	clearEsp()
	setFullbright(false)
	setFov(false)
	stopSpectate()
	restoreCharacter()
	sweepHubObjects()
	clearBuild()
	dropHeld()
end

local function stopAll()
	revertFeatures()
	pushLog("Stopped features")
end

local function sameTeam(player)
	if not state.skipTeam then
		return false
	end
	if not player.Team or not LocalPlayer.Team then
		return false
	end
	return player.Team == LocalPlayer.Team
end

local function livingRoot(model)
	if not model then
		return nil
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	if model:FindFirstChildOfClass("ForceField") then
		return nil
	end
	return model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
end

local function nearestPlayer(origin)
	if state.killSelected then
		local picked = selectedPlayer()
		if picked and picked ~= LocalPlayer and not sameTeam(picked) then
			local part = livingRoot(picked.Character)
			if part then
				return part, picked.DisplayName
			end
		end
		return nil, nil
	end
	local bestPart = nil
	local bestName = nil
	local bestDist = state.killRange
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and not sameTeam(player) then
			local part = livingRoot(player.Character)
			if part then
				local dist = (part.Position - origin).Magnitude
				if dist < bestDist then
					bestDist = dist
					bestPart = part
					bestName = player.DisplayName
				end
			end
		end
	end
	return bestPart, bestName
end

local npcCache = { time = 0, part = nil, name = nil }

local function nearestNpc(origin)
	local now = os.clock()
	if now - npcCache.time < 0.6 and npcCache.part and npcCache.part.Parent then
		local model = npcCache.part.Parent
		if model and livingRoot(model) then
			return npcCache.part, npcCache.name
		end
	end
	local bestPart = nil
	local bestName = nil
	local bestDist = state.killRange
	local seen = 0
	local function consider(model)
		seen = seen + 1
		if seen > 500 or not model:IsA("Model") or Players:GetPlayerFromCharacter(model) then
			return
		end
		local part = livingRoot(model)
		if not part then
			return
		end
		local dist = (part.Position - origin).Magnitude
		if dist < bestDist then
			bestDist = dist
			bestPart = part
			bestName = model.Name
		end
	end
	for _, inst in ipairs(workspace:GetChildren()) do
		consider(inst)
		if inst:IsA("Folder") or inst:IsA("Model") then
			for _, child in ipairs(inst:GetChildren()) do
				consider(child)
				if child:IsA("Folder") or child:IsA("Model") then
					for _, nested in ipairs(child:GetChildren()) do
						consider(nested)
					end
				end
			end
		end
	end
	npcCache.time = now
	npcCache.part = bestPart
	npcCache.name = bestName
	return bestPart, bestName
end

local function ensureWeapon()
	local character = LocalPlayer.Character
	if character then
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Tool") then
				local name = string.lower(child.Name)
				if string.find(name, "knife", 1, true) or string.find(name, "laser", 1, true) or string.find(name, "mech", 1, true) or string.find(name, "blaster", 1, true) or string.find(name, "robo", 1, true) then
					return
				end
			end
		end
	end
	local tool = findTool({ "knife", "laser", "mech", "blaster", "robo" })
	local _, humanoid = characterParts()
	if tool and humanoid then
		pcall(function()
			humanoid:EquipTool(tool)
		end)
	end
end

local function clickAttack()
	if type(mouse1click) == "function" then
		pcall(mouse1click)
		return
	end
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(960, 540)
	local x = viewport.X * 0.5
	local y = viewport.Y * 0.5
	pcall(function()
		VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
	end)
	task.delay(0.05, function()
		if not state.alive then
			return
		end
		pcall(function()
			VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
		end)
	end)
end

local function strike(root, part)
	local behind = part.Position - part.CFrame.LookVector * 4
	root.CFrame = CFrame.lookAt(behind, part.Position)
	local camera = workspace.CurrentCamera
	if camera then
		camera.CFrame = CFrame.lookAt(camera.CFrame.Position, part.Position)
	end
	ensureWeapon()
	clickAttack()
end

local function promptPosition(prompt)
	local parent = prompt.Parent
	if not parent then
		return nil
	end
	if parent:IsA("BasePart") then
		return parent.Position
	end
	if parent:IsA("Attachment") then
		return parent.WorldPosition
	end
	if parent:IsA("Model") then
		local part = parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart", true)
		if part then
			return part.Position
		end
	end
	return nil
end

local function promptWanted(prompt)
	if state.questAny then
		return true
	end
	local parentName = prompt.Parent and prompt.Parent.Name or ""
	local blob = string.lower(prompt.Name .. " " .. prompt.ActionText .. " " .. prompt.ObjectText .. " " .. parentName)
	return string.find(blob, "quest", 1, true)
		or string.find(blob, "bounty", 1, true)
		or string.find(blob, "reward", 1, true)
		or string.find(blob, "claim", 1, true)
		or string.find(blob, "mission", 1, true)
end

local function firePrompt(prompt)
	if type(fireproximityprompt) == "function" then
		local ok = pcall(fireproximityprompt, prompt)
		if ok then
			return true
		end
	end
	local ok = pcall(function()
		prompt:InputHoldBegin()
		task.delay((prompt.HoldDuration or 0) + 0.05, function()
			pcall(function()
				prompt:InputHoldEnd()
			end)
		end)
	end)
	return ok
end

local function runQuest(root)
	local best = nil
	local bestPos = nil
	local bestDist = state.questRange
	local seen = 0
	for _, inst in ipairs(workspace:GetDescendants()) do
		seen = seen + 1
		if seen > 2500 or bestDist < 12 then
			break
		end
		if inst:IsA("ProximityPrompt") and inst.Enabled and promptWanted(inst) then
			local pos = promptPosition(inst)
			if pos then
				local dist = (pos - root.Position).Magnitude
				if dist < bestDist then
					bestDist = dist
					best = inst
					bestPos = pos
				end
			end
		end
	end
	if not best or not bestPos then
		if os.clock() > (state.nextQuestNote or 0) then
			state.nextQuestNote = os.clock() + 8
			pushLog("No quest prompt nearby")
		end
		return
	end
	root.CFrame = CFrame.new(bestPos + Vector3.new(0, 3, 0))
	if firePrompt(best) then
		local label = best.ObjectText ~= "" and best.ObjectText or best.Name
		if state.lastQuest ~= label then
			state.lastQuest = label
			pushLog("Quest " .. label)
		end
	end
end

local function mentionsIq(text)
	text = string.lower(tostring(text or ""))
	if text == "" then
		return false
	end
	if string.find(text, "intellect", 1, true) or string.find(text, "brain", 1, true) then
		return true
	end
	if string.find(text, "iqxp", 1, true) or string.find(text, "iq_xp", 1, true) or string.find(text, "iq xp", 1, true) then
		return true
	end
	if string.match(text, "^iq$") or string.match(text, "^iq[^%a]") or string.match(text, "[^%a]iq$") or string.match(text, "[^%a]iq[^%a]") or string.match(text, "iq$") then
		return true
	end
	return false
end

local function numberFrom(value)
	if typeof(value) == "number" then
		return value
	end
	local digits = string.match(tostring(value or ""), "[-+]?%d+%.?%d*")
	if not digits then
		return nil
	end
	return tonumber(digits)
end

local function readValueObject(obj, source)
	if not (obj:IsA("IntValue") or obj:IsA("NumberValue") or obj:IsA("StringValue")) then
		return nil
	end
	if not mentionsIq(obj.Name) then
		return nil
	end
	return tostring(obj.Value), numberFrom(obj.Value), source
end

local function scanValueFolder(folder, prefix, depth)
	if not folder or depth > 2 then
		return nil
	end
	for _, child in ipairs(folder:GetChildren()) do
		local text, number, source = readValueObject(child, prefix .. child.Name)
		if text then
			return text, number, source
		end
		if child:IsA("Folder") or child:IsA("Configuration") then
			local nestedText, nestedNumber, nestedSource = scanValueFolder(child, prefix .. child.Name .. ".", depth + 1)
			if nestedText then
				return nestedText, nestedNumber, nestedSource
			end
		end
	end
	return nil
end

local function readIq()
	local stats = LocalPlayer:FindFirstChild("leaderstats")
	if stats then
		local text, number, source = scanValueFolder(stats, "leaderstats.", 1)
		if text then
			return text, number, source
		end
	end
	local ok, attrs = pcall(function()
		return LocalPlayer:GetAttributes()
	end)
	if ok and type(attrs) == "table" then
		for name, value in pairs(attrs) do
			if mentionsIq(name) then
				return tostring(value), numberFrom(value), "attribute." .. tostring(name)
			end
		end
	end
	local text, number, source = scanValueFolder(LocalPlayer, "player.", 0)
	if text then
		return text, number, source
	end
	local seen = 0
	for _, inst in ipairs(PlayerGui:GetDescendants()) do
		seen = seen + 1
		if seen > 800 then
			break
		end
		if gui and inst:IsDescendantOf(gui) then
			continue
		end
		if inst:IsA("TextLabel") or inst:IsA("TextButton") then
			local blob = inst.Name .. " " .. (inst.Parent and inst.Parent.Name or "") .. " " .. inst.Text
			if mentionsIq(blob) then
				local amount = numberFrom(inst.Text)
				if amount then
					return inst.Text, amount, "gui." .. inst.Name
				end
			end
		end
	end
	return nil, nil, nil
end

local function rememberIq(text, number, source)
	state.iqText = text or "not found"
	state.iqSource = source or ""
	if number and state.iqLast ~= nil and number ~= state.iqLast then
		pushLog("IQ " .. tostring(state.iqLast) .. " → " .. tostring(number) .. " (" .. state.iqSource .. ")")
	elseif number and state.iqLast == nil then
		pushLog("IQ " .. tostring(number) .. " (" .. state.iqSource .. ")")
	end
	if number then
		state.iqLast = number
	end
end

local function refreshIq()
	local text, number, source = readIq()
	if text then
		rememberIq(text, number, source)
	else
		state.iqText = "not found"
		state.iqSource = ""
	end
end

local iqWorld = { at = 0, inst = nil, pos = nil, label = nil }

local function iqPoint(inst)
	if inst:IsA("BasePart") then
		return inst.Position
	end
	if inst:IsA("Model") then
		local part = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
		if part then
			return part.Position
		end
	end
	if inst:IsA("ProximityPrompt") then
		return promptPosition(inst)
	end
	if inst:IsA("ClickDetector") then
		local parent = inst.Parent
		if parent and parent:IsA("BasePart") then
			return parent.Position
		end
	end
	if inst:IsA("Attachment") then
		return inst.WorldPosition
	end
	return nil
end

local function ownedByPlayer(inst)
	local model = inst:FindFirstAncestorOfClass("Model")
	return model ~= nil and Players:GetPlayerFromCharacter(model) ~= nil
end

local function findIqWorld(origin)
	local now = os.clock()
	if now - iqWorld.at < 2 and iqWorld.inst and iqWorld.inst.Parent and iqWorld.pos then
		return iqWorld.inst, iqWorld.pos, iqWorld.label
	end
	local best = nil
	local bestPos = nil
	local bestLabel = nil
	local bestDist = 1200
	local seen = 0
	for _, inst in ipairs(workspace:GetDescendants()) do
		seen = seen + 1
		if seen > 2200 then
			break
		end
		if inst:IsDescendantOf(workspace) and not ownedByPlayer(inst) then
			local folder = inst:FindFirstAncestor(BUILD_FOLDER)
			if not folder and (inst:IsA("BasePart") or inst:IsA("Model") or inst:IsA("ProximityPrompt") or inst:IsA("ClickDetector")) then
				local blob = inst.Name
				if inst:IsA("ProximityPrompt") then
					blob = blob .. " " .. inst.ActionText .. " " .. inst.ObjectText
				end
				if mentionsIq(blob) then
					local pos = iqPoint(inst)
					if pos then
						local dist = (pos - origin).Magnitude
						local triedAt = state.iqTried[inst]
						if triedAt and now - triedAt < 5 then
							dist = dist + 400
						end
						if dist < bestDist then
							bestDist = dist
							best = inst
							bestPos = pos
							bestLabel = inst.Name
						end
					end
				end
			end
		end
	end
	iqWorld.at = now
	iqWorld.inst = best
	iqWorld.pos = bestPos
	iqWorld.label = bestLabel
	return best, bestPos, bestLabel
end

local function useIqTarget(inst, root, pos)
	root.CFrame = CFrame.lookAt(pos + Vector3.new(0, 3, 0), pos)
	pcall(function()
		root.AssemblyLinearVelocity = Vector3.zero
	end)
	if inst:IsA("ProximityPrompt") then
		firePrompt(inst)
	elseif inst:IsA("ClickDetector") and type(fireclickdetector) == "function" then
		pcall(fireclickdetector, inst)
	else
		fireCollect(inst, root)
	end
	state.iqTried[inst] = os.clock()
end

local function iqButtonBlob(inst)
	local text = ""
	if inst:IsA("TextButton") then
		text = inst.Text
	end
	return string.lower(inst.Name .. " " .. text .. " " .. (inst.Parent and inst.Parent.Name or ""))
end

local function pressIqButton()
	local seen = 0
	for _, inst in ipairs(PlayerGui:GetDescendants()) do
		seen = seen + 1
		if seen > 800 then
			break
		end
		if gui and inst:IsDescendantOf(gui) then
			continue
		end
		if (inst:IsA("TextButton") or inst:IsA("ImageButton")) and inst.Visible then
			local blob = iqButtonBlob(inst)
			local paid = string.find(blob, "buy", 1, true)
				or string.find(blob, "shop", 1, true)
				or string.find(blob, "robux", 1, true)
				or string.find(blob, "vip", 1, true)
				or string.find(blob, "pass", 1, true)
				or string.find(blob, "purchase", 1, true)
			if mentionsIq(blob) and not paid then
				local pos = inst.AbsolutePosition
				local size = inst.AbsoluteSize
				local x = pos.X + size.X * 0.5
				local y = pos.Y + size.Y * 0.5
				pcall(function()
					VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
				end)
				task.delay(0.05, function()
					if not state.alive then
						return
					end
					pcall(function()
						VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
					end)
				end)
				return inst.Name
			end
		end
	end
	return nil
end

local function runIq(root)
	if not state.autoIq or not inPortal() then
		state.iqBusy = false
		return
	end
	local now = os.clock()
	if now >= (state.nextIqRead or 0) then
		state.nextIqRead = now + 0.6
		refreshIq()
	end
	if now < (state.nextIq or 0) then
		return
	end
	state.nextIq = now + 0.85
	if state.autoMat then
		state.iqBusy = false
		return
	end
	local inst, pos, label = findIqWorld(root.Position)
	if inst and pos then
		state.iqBusy = true
		state.locking = true
		useIqTarget(inst, root, pos)
		if state.lastIqTarget ~= label then
			state.lastIqTarget = label
			pushLog("IQ object " .. tostring(label))
		end
		return
	end
	state.iqBusy = false
	if now >= (state.nextIqClick or 0) then
		state.nextIqClick = now + 3
		local button = pressIqButton()
		if button and state.lastIqButton ~= button then
			state.lastIqButton = button
			pushLog("IQ button " .. button)
		end
	end
	if not state.iqKills and now > (state.nextIqNote or 0) then
		state.nextIqNote = now + 6
		pushLog("IQ " .. state.iqText .. ". No IQ pickup in this server")
	end
end

local function runCombat(root)
	if not inPortal() then
		state.locking = false
		return
	end
	local now = os.clock()
	if state.autoQuest and now >= (state.nextQuest or 0) then
		state.nextQuest = now + 1.15
		runQuest(root)
	end
	if state.iqBusy then
		state.locking = true
		return
	end
	local iqGrind = state.autoIq and state.iqKills
	if not state.autoKill and not state.autoFarm and not iqGrind then
		state.locking = false
		return
	end
	if now < (state.nextHit or 0) then
		return
	end
	local _, humanoid = characterParts()
	if humanoid and humanoid.Health > 0 and humanoid.Health < humanoid.MaxHealth * 0.35 then
		state.locking = false
		return
	end
	state.nextHit = now + 0.32
	local part = nil
	local label = nil
	if state.autoKill or (state.autoFarm and state.farmPlayers) or iqGrind then
		part, label = nearestPlayer(root.Position)
	end
	if not part and state.autoFarm then
		part, label = nearestNpc(root.Position)
	end
	if not part then
		state.locking = false
		if iqGrind and now > (state.nextIqNote or 0) then
			state.nextIqNote = now + 6
			pushLog("IQ " .. state.iqText .. ". No player in range")
		end
		return
	end
	state.locking = true
	if state.lastTarget ~= label then
		state.lastTarget = label
		pushLog("Target " .. tostring(label))
	end
	strike(root, part)
end

local function onHeartbeat()
	if not state.alive then
		return
	end
	local character, humanoid, root = characterParts()
	if not character or not humanoid or not root then
		return
	end
	if state.autoMat then
		state.locking = true
	end
	if state.speed and inPortal() then
		if savedWalk == nil then
			savedWalk = humanoid.WalkSpeed
		end
		humanoid.WalkSpeed = state.walkSpeed
		state.speedApplied = true
	elseif state.speedApplied then
		if savedWalk ~= nil then
			humanoid.WalkSpeed = savedWalk
			savedWalk = nil
		end
		state.speedApplied = false
	end
	if state.noclip and inPortal() then
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				if collideSaved[part] == nil then
					collideSaved[part] = part.CanCollide
				end
				part.CanCollide = false
			end
		end
	end
	if state.fly and inPortal() then
		local gyro, velocity = ensureFly(root)
		local camera = workspace.CurrentCamera
		if gyro and camera then
			gyro.CFrame = camera.CFrame
		end
		if velocity then
			velocity.Velocity = state.locking and Vector3.zero or flyVector()
		end
	else
		if root:FindFirstChild("VOIDZ_FlyBV") then
			clearFly(root)
		end
	end
	if state.antiVoid and inPortal() then
		if root.Position.Y > 8 and humanoid.FloorMaterial ~= Enum.Material.Air then
			state.safe = root.CFrame
		end
		if root.Position.Y < -40 and state.safe then
			root.CFrame = state.safe
		end
	end
	runIq(root)
	if (state.autoRegen or state.autoIq) and inPortal() and humanoid.Health > 0 and humanoid.MaxHealth > 0 then
		if humanoid.Health < humanoid.MaxHealth * 0.45 then
			if (state.lastRegen or 0) + 1.4 < os.clock() then
				state.lastRegen = os.clock()
				pcall(function()
					VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
					task.delay(0.06, function()
						pcall(function()
							VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
						end)
					end)
				end)
				pushLog("Auto regen sent E")
			end
		end
	end
	runCombat(root)
	if state.autoBuild and inPortal() and not state.locking then
		local now = os.clock()
		if now >= (state.nextBuild or 0) then
			state.nextBuild = now + 0.5
			local origin = state.buildOrigin
			local reach = state.buildReach or 16
			if not origin or (root.Position - origin).Magnitude > reach + 8 then
				placeBuild(state.buildKind or "Pad", root, true)
			end
		end
	end
	runMaterials(root)
end

local function bind(signal, fn)
	local conn = signal:Connect(fn)
	table.insert(conns, conn)
	return conn
end

local function wipe(frame)
	for _, child in ipairs(frame:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

local function makeScroll(parent)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Scroll"
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Size = UDim2.new(1, -8, 1, -8)
	scroll.Position = UDim2.fromOffset(4, 4)
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = C.accent
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new()
	scroll.Parent = parent
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroll
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 4)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 6)
	pad.PaddingRight = UDim.new(0, 6)
	pad.Parent = scroll
	return scroll
end

local function note(parent, text, order)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, 0)
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.Font = Enum.Font.Gotham
	label.TextSize = 13
	label.TextColor3 = C.muted
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Text = text
	label.LayoutOrder = order
	label.Parent = parent
	return label
end

local function actionButton(parent, text, order, callback, background)
	local idle = background or C.card
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 34)
	button.BackgroundColor3 = idle
	button.AutoButtonColor = false
	button.Font = Enum.Font.GothamMedium
	button.TextSize = 14
	button.TextColor3 = C.text
	button.Text = text
	button.LayoutOrder = order
	button.Parent = parent
	corner(button, 8)
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = C.card2,
		}):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = idle,
		}):Play()
	end)
	button.MouseButton1Click:Connect(function()
		pcall(callback)
	end)
	return button
end

local function toggleRow(parent, title, order, isOn, callback)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 36)
	row.BackgroundColor3 = C.card
	row.LayoutOrder = order
	row.Parent = parent
	corner(row, 8)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(12, 0)
	label.Size = UDim2.new(1, -70, 1, 0)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = C.text
	label.Text = title
	label.Parent = row
	local pill = Instance.new("TextButton")
	pill.Size = UDim2.fromOffset(42, 22)
	pill.Position = UDim2.new(1, -52, 0.5, -11)
	pill.BackgroundColor3 = isOn and C.accent or Color3.fromRGB(58, 58, 66)
	pill.Text = ""
	pill.AutoButtonColor = false
	pill.Parent = row
	corner(pill, 11)
	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(16, 16)
	knob.Position = isOn and UDim2.new(1, -19, 0.5, -8) or UDim2.fromOffset(3, 3)
	knob.BackgroundColor3 = Color3.new(1, 1, 1)
	knob.Parent = pill
	corner(knob, 8)
	pill.MouseButton1Click:Connect(function()
		pcall(callback)
	end)
	return row
end

local function stepRow(parent, title, order, valueText, onLess, onMore)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 36)
	row.BackgroundColor3 = C.card
	row.LayoutOrder = order
	row.Parent = parent
	corner(row, 8)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(12, 0)
	label.Size = UDim2.new(1, -130, 1, 0)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = C.text
	label.Text = title .. "  " .. valueText
	label.Parent = row
	local function step(text, x, callback)
		local button = Instance.new("TextButton")
		button.Size = UDim2.fromOffset(28, 24)
		button.Position = UDim2.new(1, x, 0.5, -12)
		button.BackgroundColor3 = C.card2
		button.Font = Enum.Font.GothamBold
		button.TextSize = 16
		button.TextColor3 = C.text
		button.Text = text
		button.AutoButtonColor = false
		button.Parent = row
		corner(button, 6)
		button.MouseButton1Click:Connect(function()
			pcall(callback)
		end)
	end
	step("-", -68, onLess)
	step("+", -34, onMore)
	return row
end

local function renderPlayers()
	if not playerList then
		return
	end
	wipe(playerList)
	local query = string.lower(state.query or "")
	local people = Players:GetPlayers()
	table.sort(people, function(a, b)
		if a == LocalPlayer then
			return true
		end
		if b == LocalPlayer then
			return false
		end
		return a.DisplayName:lower() < b.DisplayName:lower()
	end)
	local shown = 0
	for _, player in ipairs(people) do
		local blob = string.lower(player.DisplayName .. " " .. player.Name .. " " .. tostring(player.UserId))
		if query == "" or string.find(blob, query, 1, true) then
			shown = shown + 1
			local card = Instance.new("TextButton")
			card.Size = UDim2.new(1, 0, 0, 64)
			card.BackgroundColor3 = (state.selected == player.UserId) and C.card2 or C.card
			card.AutoButtonColor = false
			card.Text = ""
			card.LayoutOrder = shown
			card.Parent = playerList
			corner(card, 8)
			if state.selected == player.UserId then
				local bar = Instance.new("Frame")
				bar.Size = UDim2.new(0, 3, 1, -12)
				bar.Position = UDim2.fromOffset(0, 6)
				bar.BackgroundColor3 = C.accent
				bar.BorderSizePixel = 0
				bar.Parent = card
				corner(bar, 2)
			end
			local avatar = Instance.new("ImageLabel")
			avatar.Size = UDim2.fromOffset(40, 40)
			avatar.Position = UDim2.fromOffset(10, 12)
			avatar.BackgroundColor3 = C.card2
			avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(player.UserId) .. "&w=150&h=150"
			avatar.Parent = card
			corner(avatar, 20)
			local name = Instance.new("TextLabel")
			name.BackgroundTransparency = 1
			name.Position = UDim2.fromOffset(58, 8)
			name.Size = UDim2.new(1, -112, 0, 18)
			name.Font = Enum.Font.GothamBold
			name.TextSize = 14
			name.TextXAlignment = Enum.TextXAlignment.Left
			name.TextColor3 = C.text
			name.Text = player.DisplayName
			name.Parent = card
			local handle = Instance.new("TextLabel")
			handle.BackgroundTransparency = 1
			handle.Position = UDim2.fromOffset(58, 26)
			handle.Size = UDim2.new(1, -112, 0, 14)
			handle.Font = Enum.Font.Gotham
			handle.TextSize = 12
			handle.TextXAlignment = Enum.TextXAlignment.Left
			handle.TextColor3 = C.muted
			handle.Text = "@" .. player.Name
			handle.Parent = card
			local userId = Instance.new("TextLabel")
			userId.BackgroundTransparency = 1
			userId.Position = UDim2.fromOffset(58, 42)
			userId.Size = UDim2.new(1, -112, 0, 14)
			userId.Font = Enum.Font.Gotham
			userId.TextSize = 11
			userId.TextXAlignment = Enum.TextXAlignment.Left
			userId.TextColor3 = C.muted
			userId.Text = tostring(player.UserId)
			userId.Parent = card
			local role = Instance.new("TextLabel")
			role.BackgroundTransparency = 1
			role.AnchorPoint = Vector2.new(1, 0.5)
			role.Position = UDim2.new(1, -10, 0.5, 0)
			role.Size = UDim2.fromOffset(70, 18)
			role.Font = Enum.Font.GothamMedium
			role.TextSize = 12
			role.TextXAlignment = Enum.TextXAlignment.Right
			role.TextColor3 = (player == LocalPlayer) and C.accent or C.good
			role.Text = (player == LocalPlayer) and "You" or "Player"
			role.Parent = card
			card.MouseButton1Click:Connect(function()
				state.selected = player.UserId
				pushLog("Selected " .. player.DisplayName)
				renderPlayers()
				if state.page == "Players" or state.page == "Home" then
					renderPage()
				end
			end)
		end
	end
	if shown == 0 then
		note(playerList, "No players match that search.", 1)
	end
end

local function markNav()
	for name, button in pairs(navButtons) do
		TweenService:Create(button, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = (name == state.page) and C.card2 or C.side,
		}):Play()
	end
end

local function animatePage()
	if not centerHolder then
		return
	end
	centerHolder.Position = UDim2.fromOffset(18, 10)
	TweenService:Create(centerHolder, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = UDim2.fromOffset(4, 4),
	}):Play()
end

function renderPage()
	if not centerHolder then
		return
	end
	wipe(centerHolder)
	pageTitle.Text = state.page
	markNav()
	local order = 0
	local function nextOrder()
		order = order + 1
		return order
	end

	if state.page == "Home" then
		local where = inPortal() and "Portal Sandbox is loaded." or "This place is not Portal Sandbox. Join the game, then execute again."
		note(centerHolder, where .. " PlaceId " .. tostring(game.PlaceId) .. ". Build " .. BUILD .. ".", nextOrder())
		note(centerHolder, "RightShift hides the hub. Materials collects map parts. Farm reads your IQ and uses an IQ pickup when the game has one.", nextOrder())
		for _, line in ipairs(logs) do
			local row = Instance.new("TextLabel")
			row.BackgroundColor3 = C.card
			row.Size = UDim2.new(1, 0, 0, 28)
			row.Font = Enum.Font.Gotham
			row.TextSize = 13
			row.TextColor3 = C.text
			row.TextXAlignment = Enum.TextXAlignment.Left
			row.Text = "  " .. line
			row.LayoutOrder = nextOrder()
			row.Parent = centerHolder
			corner(row, 6)
		end
		if #logs == 0 then
			note(centerHolder, "No activity yet.", nextOrder())
		end
		return
	end

	if state.page == "Move" then
		note(centerHolder, "Fly uses WASD. Space rises. LeftControl or LeftShift drops. Speed and fly only run inside Portal Sandbox.", nextOrder())
		toggleRow(centerHolder, "Fly", nextOrder(), state.fly, function()
			if not state.fly and not requireGame() then
				return
			end
			state.fly = not state.fly
			if not state.fly then
				clearFly()
			end
			pushLog(state.fly and "Fly on" or "Fly off")
			renderPage()
		end)
		stepRow(centerHolder, "Fly speed", nextOrder(), tostring(state.flySpeed), function()
			state.flySpeed = math.max(20, state.flySpeed - 20)
			renderPage()
		end, function()
			state.flySpeed = math.min(200, state.flySpeed + 20)
			renderPage()
		end)
		toggleRow(centerHolder, "Noclip", nextOrder(), state.noclip, function()
			if not state.noclip and not requireGame() then
				return
			end
			state.noclip = not state.noclip
			if not state.noclip then
				restoreCollide()
			end
			pushLog(state.noclip and "Noclip on" or "Noclip off")
			renderPage()
		end)
		toggleRow(centerHolder, "Walk speed", nextOrder(), state.speed, function()
			if not state.speed and not requireGame() then
				return
			end
			state.speed = not state.speed
			pushLog(state.speed and "Speed on" or "Speed off")
			renderPage()
		end)
		stepRow(centerHolder, "Walk speed", nextOrder(), tostring(state.walkSpeed), function()
			state.walkSpeed = math.max(16, state.walkSpeed - 8)
			renderPage()
		end, function()
			state.walkSpeed = math.min(120, state.walkSpeed + 8)
			renderPage()
		end)
		toggleRow(centerHolder, "Infinite jump", nextOrder(), state.infJump, function()
			if not state.infJump and not requireGame() then
				return
			end
			state.infJump = not state.infJump
			pushLog(state.infJump and "Infinite jump on" or "Infinite jump off")
			renderPage()
		end)
		toggleRow(centerHolder, "Click teleport", nextOrder(), state.clickTp, function()
			if not state.clickTp and not requireGame() then
				return
			end
			state.clickTp = not state.clickTp
			pushLog(state.clickTp and "Click teleport on" or "Click teleport off")
			renderPage()
		end)
		toggleRow(centerHolder, "Anti void", nextOrder(), state.antiVoid, function()
			if not state.antiVoid and not requireGame() then
				return
			end
			state.antiVoid = not state.antiVoid
			pushLog(state.antiVoid and "Anti void on" or "Anti void off")
			renderPage()
		end)
		actionButton(centerHolder, "Stop movement", nextOrder(), function()
			state.fly = false
			state.noclip = false
			state.speed = false
			state.infJump = false
			state.clickTp = false
			state.antiVoid = false
			clearFly()
			restoreCharacter()
			pushLog("Movement stopped")
			renderPage()
		end)
		return
	end

	if state.page == "PvP" then
		note(centerHolder, "Auto kill teleports behind a living player, aims, equips a knife, laser, or mech if you already have one, and clicks. Kills pay money in this game. It uses your weapons. It does not invent a damage remote.", nextOrder())
		toggleRow(centerHolder, "Auto kill", nextOrder(), state.autoKill, function()
			if not state.autoKill and not requireGame() then
				return
			end
			state.autoKill = not state.autoKill
			pushLog(state.autoKill and "Auto kill on" or "Auto kill off")
			renderPage()
		end)
		toggleRow(centerHolder, "Selected player only", nextOrder(), state.killSelected, function()
			state.killSelected = not state.killSelected
			pushLog(state.killSelected and "Kill target is the selected player" or "Kill target is the nearest player")
			renderPage()
		end)
		toggleRow(centerHolder, "Skip teammates", nextOrder(), state.skipTeam, function()
			state.skipTeam = not state.skipTeam
			renderPage()
		end)
		stepRow(centerHolder, "Search range", nextOrder(), tostring(state.killRange), function()
			state.killRange = math.max(40, state.killRange - 50)
			renderPage()
		end, function()
			state.killRange = math.min(2000, state.killRange + 50)
			renderPage()
		end)
		return
	end

	if state.page == "Materials" then
		if os.clock() - (state.matScanAt or 0) > 2 then
			scanMaterials()
		end
		local chosen = state.material and prettyMaterial(state.material) or "None"
		local left = 0
		if state.material and state.matIndex[state.material] then
			left = #state.matIndex[state.material]
		end
		note(centerHolder, "Scan finds loose parts by material and by item name. Auto collect teleports you onto the closest one, fires its prompt or touch, pulls it to you, then moves to the next closest.", nextOrder())
		note(centerHolder, "Selected: " .. chosen .. "  ·  " .. tostring(left) .. " left. Found " .. tostring(#state.matList) .. " types.", nextOrder())
		actionButton(centerHolder, "Scan materials", nextOrder(), function()
			if not requireGame() then
				return
			end
			local count = scanMaterials()
			pushLog("Scan found " .. tostring(count) .. " material types")
			renderPage()
		end)
		actionButton(centerHolder, state.matOpen and "Close list" or ("Material: " .. chosen), nextOrder(), function()
			state.matOpen = not state.matOpen
			if state.matOpen then
				scanMaterials()
			end
			renderPage()
		end)
		if state.matOpen then
			if #state.matList == 0 then
				note(centerHolder, "No loose parts found. Walk into the map and press Scan materials.", nextOrder())
			end
			for _, item in ipairs(state.matList) do
				actionButton(centerHolder, item.label, nextOrder(), function()
					state.material = item.id
					state.matOpen = false
					pushLog("Selected " .. prettyMaterial(item.id))
					renderPage()
				end)
			end
		end
		toggleRow(centerHolder, "Auto collect", nextOrder(), state.autoMat, function()
			if not state.autoMat and not requireGame() then
				return
			end
			if not state.autoMat and not state.material then
				pushLog("Choose a material first")
				return
			end
			state.autoMat = not state.autoMat
			if state.autoMat then
				state.locking = true
				scanMaterials()
			end
			pushLog(state.autoMat and ("Collecting " .. prettyMaterial(state.material)) or "Auto collect off")
			renderPage()
		end)
		actionButton(centerHolder, "Drop held parts", nextOrder(), function()
			dropHeld()
			pushLog("Dropped held parts")
		end)
		return
	end

	if state.page == "Farm" then
		local iqLine = "IQ: " .. tostring(state.iqText)
		if state.iqSource ~= "" then
			iqLine = iqLine .. "  ·  " .. state.iqSource
		end
		note(centerHolder, iqLine, nextOrder())
		note(centerHolder, "VIP lists 2x IQ XP next to 2x kill money. Public pages never say which action grants IQ, and this hub does not call a guessed remote. Auto IQ reads leaderstats, attributes, and the HUD. If the map has an IQ prompt or pickup, it teleports there and uses it. Grind nearest player is the kill loop, because kills are the only payout the game describes.", nextOrder())
		toggleRow(centerHolder, "Auto IQ", nextOrder(), state.autoIq, function()
			if not state.autoIq and not requireGame() then
				return
			end
			state.autoIq = not state.autoIq
			if state.autoIq then
				refreshIq()
			else
				state.iqBusy = false
			end
			pushLog(state.autoIq and ("Auto IQ on · " .. state.iqText) or "Auto IQ off")
			renderPage()
		end)
		toggleRow(centerHolder, "Grind nearest player", nextOrder(), state.iqKills, function()
			state.iqKills = not state.iqKills
			pushLog(state.iqKills and "IQ farm also grinds the nearest player" or "IQ farm only uses IQ objects")
			renderPage()
		end)
		actionButton(centerHolder, "Refresh IQ", nextOrder(), function()
			refreshIq()
			if state.iqSource ~= "" then
				pushLog("IQ " .. state.iqText .. " (" .. state.iqSource .. ")")
			else
				pushLog("No IQ stat on the player or HUD")
			end
			renderPage()
		end)
		note(centerHolder, "Auto farm hunts NPC humanoids, then players if that option is on. Auto quest teleports to a nearby prompt named quest, bounty, reward, claim, or mission and fires it. Bounties were announced as upcoming, so a prompt has to exist in the server.", nextOrder())
		toggleRow(centerHolder, "Auto farm", nextOrder(), state.autoFarm, function()
			if not state.autoFarm and not requireGame() then
				return
			end
			state.autoFarm = not state.autoFarm
			pushLog(state.autoFarm and "Auto farm on" or "Auto farm off")
			renderPage()
		end)
		toggleRow(centerHolder, "Farm players too", nextOrder(), state.farmPlayers, function()
			state.farmPlayers = not state.farmPlayers
			renderPage()
		end)
		toggleRow(centerHolder, "Auto quest", nextOrder(), state.autoQuest, function()
			if not state.autoQuest and not requireGame() then
				return
			end
			state.autoQuest = not state.autoQuest
			pushLog(state.autoQuest and "Auto quest on" or "Auto quest off")
			renderPage()
		end)
		toggleRow(centerHolder, "Any nearby prompt", nextOrder(), state.questAny, function()
			state.questAny = not state.questAny
			pushLog(state.questAny and "Quest loop accepts any prompt" or "Quest loop uses quest words only")
			renderPage()
		end)
		stepRow(centerHolder, "Quest range", nextOrder(), tostring(state.questRange), function()
			state.questRange = math.max(30, state.questRange - 50)
			renderPage()
		end, function()
			state.questRange = math.min(2000, state.questRange + 50)
			renderPage()
		end)
		return
	end

	if state.page == "Build" then
		note(centerHolder, "Builds a structure at your feet. Portal bay is a floor plus a wall, then selects the portal gun so you can place a portal on that wall. Auto rebuild moves the same structure when you walk past it. Unload removes the parts.", nextOrder())
		local function buildNow(kind)
			if not requireGame() then
				return
			end
			local _, _, root = characterParts()
			placeBuild(kind, root, false)
		end
		actionButton(centerHolder, "Pad", nextOrder(), function()
			buildNow("Pad")
		end)
		actionButton(centerHolder, "Stairs", nextOrder(), function()
			buildNow("Stairs")
		end)
		actionButton(centerHolder, "Wall", nextOrder(), function()
			buildNow("Wall")
		end)
		actionButton(centerHolder, "Portal bay", nextOrder(), function()
			buildNow("Portal bay")
		end)
		actionButton(centerHolder, "Bridge", nextOrder(), function()
			buildNow("Bridge")
		end)
		actionButton(centerHolder, "Room", nextOrder(), function()
			buildNow("Room")
		end)
		actionButton(centerHolder, "Ramp", nextOrder(), function()
			buildNow("Ramp")
		end)
		actionButton(centerHolder, "Tower", nextOrder(), function()
			buildNow("Tower")
		end)
		stepRow(centerHolder, "Size", nextOrder(), tostring(state.buildSize), function()
			state.buildSize = math.max(12, state.buildSize - 4)
			renderPage()
		end, function()
			state.buildSize = math.min(48, state.buildSize + 4)
			renderPage()
		end)
		toggleRow(centerHolder, "Auto rebuild", nextOrder(), state.autoBuild, function()
			if not state.autoBuild and not requireGame() then
				return
			end
			state.autoBuild = not state.autoBuild
			if state.autoBuild then
				local _, _, root = characterParts()
				placeBuild(state.buildKind or "Pad", root, false)
			end
			pushLog(state.autoBuild and "Auto rebuild on" or "Auto rebuild off")
			renderPage()
		end)
		actionButton(centerHolder, "Clear build", nextOrder(), function()
			clearBuild()
			state.autoBuild = false
			pushLog("Build cleared")
			renderPage()
		end)
		return
	end

	if state.page == "Portals" then
		note(centerHolder, "These buttons send the same keys the game already uses. Press F before you walk into a portal for Blender Dimension. F after you enter does not follow that order.", nextOrder())
		for _, item in ipairs(KEYS) do
			actionButton(centerHolder, item.name .. "   " .. item.label, nextOrder(), function()
				sendKey(item.code, item.label)
			end)
		end
		toggleRow(centerHolder, "Auto regenerate", nextOrder(), state.autoRegen, function()
			if not state.autoRegen and not requireGame() then
				return
			end
			state.autoRegen = not state.autoRegen
			pushLog(state.autoRegen and "Auto regen on" or "Auto regen off")
			renderPage()
		end)
		actionButton(centerHolder, "Save mark here", nextOrder(), function()
			if not requireGame() then
				return
			end
			local _, _, root = characterParts()
			if not root then
				pushLog("No character")
				return
			end
			if #state.marks >= 6 then
				table.remove(state.marks, 1)
			end
			table.insert(state.marks, { name = "Mark " .. tostring(#state.marks + 1), cf = root.CFrame })
			pushLog("Saved mark " .. tostring(#state.marks))
			renderPage()
		end)
		for index, mark in ipairs(state.marks) do
			actionButton(centerHolder, "Go to " .. mark.name, nextOrder(), function()
				teleportTo(mark.cf + Vector3.new(0, 3, 0), "Returned to " .. mark.name)
			end)
		end
		actionButton(centerHolder, "Scan portal objects", nextOrder(), function()
			if not requireGame() then
				return
			end
			scanWorld()
			renderPage()
		end)
		for _, inst in ipairs(state.scan) do
			if inst and inst.Parent then
				actionButton(centerHolder, "TP  " .. inst.Name, nextOrder(), function()
					local cf = pivotOf(inst)
					if cf then
						teleportTo(cf + Vector3.new(0, 4, 0), "Teleported to " .. inst.Name)
					else
						pushLog("No part on " .. inst.Name)
					end
				end)
			end
		end
		return
	end

	if state.page == "Tools" then
		note(centerHolder, "Tools already in your backpack can be equipped from here. The hub does not create gear the game did not give you.", nextOrder())
		actionButton(centerHolder, "Refresh tools", nextOrder(), function()
			renderPage()
		end)
		local hints = {
			{ "Portal gun", { "portal" } },
			{ "Knife", { "knife" } },
			{ "Laser or mech", { "laser", "mech", "blaster" } },
			{ "Robo arms", { "robo", "arm" } },
		}
		for _, item in ipairs(hints) do
			actionButton(centerHolder, "Equip " .. item[1], nextOrder(), function()
				if not requireGame() then
					return
				end
				local tool = findTool(item[2])
				if tool then
					equipTool(tool)
				else
					pushLog(item[1] .. " is not in your backpack")
				end
			end)
		end
		local tools = listTools()
		if #tools == 0 then
			note(centerHolder, "No tools in your backpack or hands.", nextOrder())
		end
		for _, tool in ipairs(tools) do
			actionButton(centerHolder, tool.Name, nextOrder(), function()
				equipTool(tool)
			end)
		end
		return
	end

	if state.page == "Visuals" then
		note(centerHolder, "Highlights and names are drawn on your client. Other players do not see them.", nextOrder())
		toggleRow(centerHolder, "Player ESP", nextOrder(), state.esp, function()
			if not state.esp and not requireGame() then
				return
			end
			state.esp = not state.esp
			refreshEsp()
			pushLog(state.esp and "ESP on" or "ESP off")
			renderPage()
		end)
		toggleRow(centerHolder, "Fullbright", nextOrder(), state.fullbright, function()
			if not state.fullbright and not requireGame() then
				return
			end
			state.fullbright = not state.fullbright
			setFullbright(state.fullbright)
			pushLog(state.fullbright and "Fullbright on" or "Fullbright off")
			renderPage()
		end)
		toggleRow(centerHolder, "Field of view", nextOrder(), state.fovOn, function()
			if not state.fovOn and not requireGame() then
				return
			end
			state.fovOn = not state.fovOn
			setFov(state.fovOn)
			pushLog(state.fovOn and "FOV on" or "FOV off")
			renderPage()
		end)
		stepRow(centerHolder, "FOV", nextOrder(), tostring(state.fov), function()
			state.fov = math.max(40, state.fov - 5)
			if state.fovOn then
				setFov(true)
			end
			renderPage()
		end, function()
			state.fov = math.min(120, state.fov + 5)
			if state.fovOn then
				setFov(true)
			end
			renderPage()
		end)
		return
	end

	if state.page == "Players" then
		local picked = selectedPlayer()
		if picked then
			note(centerHolder, picked.DisplayName .. "  @" .. picked.Name .. "  " .. tostring(picked.UserId), nextOrder())
		else
			note(centerHolder, "Select a player on the right.", nextOrder())
		end
		actionButton(centerHolder, "Teleport to player", nextOrder(), function()
			teleportToPlayer(selectedPlayer())
		end)
		actionButton(centerHolder, "Spectate", nextOrder(), function()
			spectate(selectedPlayer())
		end)
		actionButton(centerHolder, "Stop spectate", nextOrder(), function()
			stopSpectate()
			pushLog("Spectate off")
		end)
		actionButton(centerHolder, "Copy username", nextOrder(), function()
			local player = selectedPlayer()
			if not player then
				pushLog("Pick a player on the right")
				return
			end
			local ok = false
			if type(setclipboard) == "function" then
				ok = pcall(setclipboard, player.Name)
			end
			pushLog(ok and ("Copied " .. player.Name) or player.Name)
		end)
		return
	end

	if state.page == "Settings" then
		note(centerHolder, "Unload script turns off fly, noclip, speed, jump, teleport, auto regenerate, combat, auto rebuild, and auto collect. It drops held parts, removes built parts and ESP, restores lighting and field of view, and deletes this window.", nextOrder())
		note(centerHolder, "Build " .. BUILD .. ". RightShift hides the hub. The chat bar stays available.", nextOrder())
		actionButton(centerHolder, "Unload script", nextOrder(), function()
			if type(ENV.VOIDZ_PORTAL_STOP) == "function" then
				ENV.VOIDZ_PORTAL_STOP()
			end
		end, Color3.fromRGB(92, 32, 42))
		actionButton(centerHolder, "Stop features, keep window", nextOrder(), function()
			stopAll()
			renderPage()
		end)
	end
	animatePage()
end

local function shutdown()
	if not state.alive then
		return
	end
	state.alive = false
	for _, conn in ipairs(conns) do
		pcall(function()
			conn:Disconnect()
		end)
	end
	table.clear(conns)
	pcall(revertFeatures)
	keepChat()
	if gui then
		gui:Destroy()
		gui = nil
	end
	local leftover = PlayerGui:FindFirstChild("VOIDZ_PORTAL")
	if leftover then
		leftover:Destroy()
	end
	if ENV.VOIDZ_PORTAL_STOP == shutdown then
		ENV.VOIDZ_PORTAL_STOP = nil
	end
	ENV.VOIDZ_PORTAL_BUILD = nil
end

ENV.VOIDZ_PORTAL_STOP = shutdown
ENV.VOIDZ_PORTAL_BUILD = BUILD

gui = Instance.new("ScreenGui")
gui.Name = "VOIDZ_PORTAL"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 40
gui.Parent = PlayerGui

window = Instance.new("Frame")
window.Name = "Window"
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.fromScale(0.5, 0.5)
window.Size = UDim2.fromOffset(760, 440)
window.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
window.BorderSizePixel = 0
window.Active = true
window.ClipsDescendants = true
window.Parent = gui
corner(window, 12)
local wash = Instance.new("UIGradient")
wash.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(54, 28, 92)),
	ColorSequenceKeypoint.new(0.42, Color3.fromRGB(14, 12, 20)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(36, 22, 68)),
})
wash.Rotation = 28
wash.Parent = window
local windowStroke = Instance.new("UIStroke")
windowStroke.Color = C.accent
windowStroke.Thickness = 1.4
windowStroke.Transparency = 0.25
windowStroke.Parent = window
task.spawn(function()
	while state.alive and wash.Parent do
		local wave = os.clock()
		wash.Rotation = 20 + math.sin(wave * 0.35) * 16
		wash.Offset = Vector2.new(math.sin(wave * 0.22) * 0.18, math.cos(wave * 0.18) * 0.06)
		windowStroke.Color = C.line:Lerp(C.accent, 0.35 + math.sin(wave * 1.4) * 0.35)
		RunService.Heartbeat:Wait()
	end
end)

local top = Instance.new("Frame")
top.Name = "Top"
top.Size = UDim2.new(1, 0, 0, 52)
top.BackgroundColor3 = C.bar
top.BackgroundTransparency = 0.22
top.BorderSizePixel = 0
top.Active = true
top.Parent = window
corner(top, 12)
local topFill = Instance.new("Frame")
topFill.Size = UDim2.new(1, 0, 0, 16)
topFill.Position = UDim2.new(0, 0, 1, -16)
topFill.BackgroundColor3 = C.bar
topFill.BackgroundTransparency = 0.22
topFill.BorderSizePixel = 0
topFill.Parent = top
local sheen = Instance.new("Frame")
sheen.Size = UDim2.new(0.28, 0, 1, 0)
sheen.Position = UDim2.new(-0.4, 0, 0, 0)
sheen.BackgroundColor3 = Color3.new(1, 1, 1)
sheen.BackgroundTransparency = 0.86
sheen.BorderSizePixel = 0
sheen.ZIndex = 3
sheen.Parent = top
local sheenGrad = Instance.new("UIGradient")
sheenGrad.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.5, 0.15),
	NumberSequenceKeypoint.new(1, 1),
})
sheenGrad.Parent = sheen
local function loopSheen()
	if not state.alive or not sheen.Parent then
		return
	end
	sheen.Position = UDim2.new(-0.45, 0, 0, 0)
	local glide = TweenService:Create(sheen, TweenInfo.new(2.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
		Position = UDim2.new(1.15, 0, 0, 0),
	})
	glide.Completed:Connect(function()
		task.delay(1.1, loopSheen)
	end)
	glide:Play()
end
task.defer(loopSheen)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(18, 8)
title.Size = UDim2.fromOffset(220, 22)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = C.text
title.Text = "VOIDZ HUB"
title.Parent = top

pageTitle = Instance.new("TextLabel")
pageTitle.BackgroundTransparency = 1
pageTitle.Position = UDim2.fromOffset(18, 28)
pageTitle.Size = UDim2.fromOffset(220, 16)
pageTitle.Font = Enum.Font.Gotham
pageTitle.TextSize = 12
pageTitle.TextXAlignment = Enum.TextXAlignment.Left
pageTitle.TextColor3 = C.muted
pageTitle.Text = "Home"
pageTitle.Parent = top

local search = Instance.new("TextBox")
search.Size = UDim2.fromOffset(220, 28)
search.Position = UDim2.new(1, -310, 0.5, -14)
search.BackgroundColor3 = C.card
search.PlaceholderText = "Search players"
search.PlaceholderColor3 = C.muted
search.Text = ""
search.ClearTextOnFocus = false
search.Font = Enum.Font.Gotham
search.TextSize = 13
search.TextColor3 = C.text
search.TextXAlignment = Enum.TextXAlignment.Left
search.Parent = top
corner(search, 8)
local searchPad = Instance.new("UIPadding")
searchPad.PaddingLeft = UDim.new(0, 10)
searchPad.Parent = search

local function iconButton(text, x, callback)
	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(28, 28)
	button.Position = UDim2.new(1, x, 0.5, -14)
	button.BackgroundColor3 = C.card
	button.Font = Enum.Font.GothamBold
	button.TextSize = 16
	button.TextColor3 = C.text
	button.Text = text
	button.AutoButtonColor = false
	button.Parent = top
	corner(button, 8)
	button.MouseButton1Click:Connect(callback)
	return button
end

iconButton("-", -78, function()
	state.minimized = not state.minimized
	local goal = state.minimized and UDim2.fromOffset(880, 52) or UDim2.fromOffset(880, 520)
	TweenService:Create(window, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = goal,
	}):Play()
end)
iconButton("x", -42, function()
	shutdown()
end)

local body = Instance.new("Frame")
body.Name = "Body"
body.Position = UDim2.fromOffset(0, 52)
body.Size = UDim2.new(1, 0, 1, -52)
body.BackgroundTransparency = 1
body.Parent = window

local side = Instance.new("Frame")
side.Size = UDim2.new(0, 168, 1, 0)
side.BackgroundColor3 = C.side
side.BackgroundTransparency = 0.3
side.BorderSizePixel = 0
side.Parent = body

local sideList = Instance.new("ScrollingFrame")
sideList.BackgroundTransparency = 1
sideList.BorderSizePixel = 0
sideList.Position = UDim2.fromOffset(8, 8)
sideList.Size = UDim2.new(1, -12, 1, -16)
sideList.ScrollBarThickness = 3
sideList.ScrollBarImageColor3 = C.accent
sideList.AutomaticCanvasSize = Enum.AutomaticSize.Y
sideList.CanvasSize = UDim2.new()
sideList.Parent = side
local sideLayout = Instance.new("UIListLayout")
sideLayout.Padding = UDim.new(0, 4)
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
sideLayout.Parent = sideList

local pages = { "Home", "Move", "Materials", "PvP", "Farm", "Build", "Portals", "Tools", "Visuals", "Players", "Settings" }
for index, name in ipairs(pages) do
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 30)
	button.BackgroundColor3 = C.side
	button.AutoButtonColor = false
	button.Font = Enum.Font.GothamMedium
	button.TextSize = 13
	button.TextColor3 = C.text
	button.TextXAlignment = Enum.TextXAlignment.Left
	button.Text = "   " .. name
	button.LayoutOrder = index
	button.Parent = sideList
	corner(button, 8)
	navButtons[name] = button
	button.MouseEnter:Connect(function()
		if state.page ~= name then
			TweenService:Create(button, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundColor3 = C.card,
			}):Play()
		end
	end)
	button.MouseLeave:Connect(function()
		if state.page ~= name then
			TweenService:Create(button, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundColor3 = C.side,
			}):Play()
		end
	end)
	button.MouseButton1Click:Connect(function()
		state.page = name
		renderPage()
	end)
end

local center = Instance.new("Frame")
center.Position = UDim2.fromOffset(168, 0)
center.Size = UDim2.new(1, -400, 1, 0)
center.BackgroundTransparency = 1
center.Parent = body

statusLabel = Instance.new("TextLabel")
statusLabel.BackgroundTransparency = 1
statusLabel.Position = UDim2.new(0, 12, 1, -22)
statusLabel.Size = UDim2.new(1, -20, 0, 16)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextColor3 = C.muted
statusLabel.Text = "Ready"
statusLabel.Parent = center

centerHolder = makeScroll(center)
centerHolder.Size = UDim2.new(1, -8, 1, -28)

local right = Instance.new("Frame")
right.AnchorPoint = Vector2.new(1, 0)
right.Position = UDim2.new(1, 0, 0, 0)
right.Size = UDim2.new(0, 232, 1, 0)
right.BackgroundColor3 = C.side
right.BackgroundTransparency = 0.3
right.BorderSizePixel = 0
right.Parent = body

local rightTitle = Instance.new("TextLabel")
rightTitle.BackgroundTransparency = 1
rightTitle.Position = UDim2.fromOffset(12, 8)
rightTitle.Size = UDim2.new(1, -20, 0, 18)
rightTitle.Font = Enum.Font.GothamBold
rightTitle.TextSize = 13
rightTitle.TextXAlignment = Enum.TextXAlignment.Left
rightTitle.TextColor3 = C.muted
rightTitle.Text = "PLAYERS"
rightTitle.Parent = right

playerList = Instance.new("ScrollingFrame")
playerList.BackgroundTransparency = 1
playerList.BorderSizePixel = 0
playerList.Position = UDim2.fromOffset(8, 32)
playerList.Size = UDim2.new(1, -16, 1, -40)
playerList.ScrollBarThickness = 4
playerList.ScrollBarImageColor3 = C.accent
playerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerList.CanvasSize = UDim2.new()
playerList.Parent = right
local playerLayout = Instance.new("UIListLayout")
playerLayout.Padding = UDim.new(0, 6)
playerLayout.SortOrder = Enum.SortOrder.LayoutOrder
playerLayout.Parent = playerList

search:GetPropertyChangedSignal("Text"):Connect(function()
	state.query = search.Text
	renderPlayers()
end)

local dragging = false
local dragStart
local startPos
top.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = window.Position
	end
end)
bind(UserInputService.InputEnded, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)
bind(UserInputService.InputChanged, function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement and startPos and dragStart then
		local delta = input.Position - dragStart
		window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

bind(UserInputService.InputBegan, function(input, processed)
	if input.KeyCode == Enum.KeyCode.RightShift and not processed then
		window.Visible = not window.Visible
		keepChat()
		return
	end
	if input.UserInputType == Enum.UserInputType.Keyboard then
		held[input.KeyCode] = true
	end
	if state.clickTp and inPortal() and not processed and input.UserInputType == Enum.UserInputType.MouseButton1 then
		local _, _, root = characterParts()
		local mouse = LocalPlayer:GetMouse()
		if root and mouse and mouse.Hit then
			root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
			pushLog("Click teleport")
		end
	end
end)
bind(UserInputService.InputEnded, function(input)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		held[input.KeyCode] = nil
	end
end)
bind(UserInputService.JumpRequest, function()
	if not state.infJump or not inPortal() then
		return
	end
	local _, humanoid = characterParts()
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)
bind(RunService.Heartbeat, onHeartbeat)
bind(Players.PlayerAdded, function(player)
	pushLog(player.DisplayName .. " joined")
	renderPlayers()
	bind(player.CharacterAdded, function()
		task.defer(function()
			if state.alive then
				applyEsp(player)
			end
		end)
	end)
end)
bind(Players.PlayerRemoving, function(player)
	pushLog(player.DisplayName .. " left")
	if state.selected == player.UserId then
		state.selected = nil
	end
	if state.spectating == player then
		stopSpectate()
	end
	renderPlayers()
end)
bind(LocalPlayer.CharacterAdded, function()
	task.defer(function()
		if not state.alive then
			return
		end
		if state.spectating then
			spectate(state.spectating)
		end
		refreshEsp()
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	bind(player.CharacterAdded, function()
		task.defer(function()
			if state.alive then
				applyEsp(player)
			end
		end)
	end)
end

keepChat()
TweenService:Create(window, TweenInfo.new(0.42, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
	Size = UDim2.fromOffset(880, 520),
}):Play()
renderPlayers()
renderPage()
if inPortal() then
	pushLog("VOIDZ HUB ready in Portal Sandbox")
else
	pushLog("Wrong place. Join Portal Sandbox, then execute")
end
renderPage()

-- hi im voidz
