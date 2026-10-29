-- VOIDZ HUB · Portal Sandbox
-- BUILD 2026-10-29-1.6.6
-- Place 75108253383447 · Universe 10767619742
-- RightShift shows and hides the hub.

local BUILD = "2026-10-29-1.6.6"
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
	extraCodes = "",
	redeeming = false,
	questAny = false,
	questText = "",
	questKillPlayers = false,
	questKillNpc = false,
	questCollect = false,
	killSelected = false,
	skipTeam = true,
	farmPlayers = true,
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
	if part:IsA("Seat") or part:IsA("VehicleSeat") then
		return false
	end
	local blob = string.lower(part.Name)
	local parent = part.Parent
	if parent then
		blob = blob .. " " .. string.lower(parent.Name)
	end
	if string.find(blob, "seat", 1, true) or string.find(blob, "chair", 1, true) or string.find(blob, "stool", 1, true) or string.find(blob, "iq", 1, true) then
		return false
	end
	if parent then
		for _, child in ipairs(parent:GetChildren()) do
			if child:IsA("Seat") or child:IsA("VehicleSeat") then
				return false
			end
		end
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

local hasPickupSignal

local function scanMaterials()
	local function addPart(index, target)
		local matKey = target.Material.Name
		index[matKey] = index[matKey] or {}
		table.insert(index[matKey], target)
		local model = target:FindFirstAncestorOfClass("Model")
		if model and Players:GetPlayerFromCharacter(model) then
			model = nil
		end
		local label = model and model.Name or target.Name
		if label ~= "" and label ~= "Part" and label ~= "MeshPart" and label ~= "UnionOperation" and label ~= "Model" then
			local nameKey = "name:" .. label
			index[nameKey] = index[nameKey] or {}
			table.insert(index[nameKey], target)
		end
	end
	local looseIndex = {}
	local signalIndex = {}
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
				if hasPickupSignal and hasPickupSignal(target) then
					addPart(signalIndex, target)
				elseif not target.Anchored then
					addPart(looseIndex, target)
				end
			end
		end
	end
	local index = {}
	local function merge(from)
		for key, parts in pairs(from) do
			index[key] = index[key] or {}
			for _, part in ipairs(parts) do
				table.insert(index[key], part)
			end
		end
	end
	merge(signalIndex)
	merge(looseIndex)
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
	local bestSignal, bestLoose = nil, nil
	local signalDist, looseDist = math.huge, math.huge
	for i = #parts, 1, -1 do
		local part = parts[i]
		if not part.Parent or part:FindFirstChild("VOIDZ_Hold") then
			table.remove(parts, i)
		elseif wasTried(part) then
			-- leave it for a later pass
		else
			local dist = (part.Position - origin).Magnitude
			if hasPickupSignal and hasPickupSignal(part) then
				if dist < signalDist then
					signalDist = dist
					bestSignal = part
				end
			elseif not part.Anchored then
				if dist < looseDist then
					looseDist = dist
					bestLoose = part
				end
			end
		end
	end
	return bestSignal or bestLoose
end

local function promptBlocked(blob)
	return string.find(blob, "iq", 1, true)
		or string.find(blob, "sit", 1, true)
		or string.find(blob, "chair", 1, true)
		or string.find(blob, "buy", 1, true)
		or string.find(blob, "shop", 1, true)
		or string.find(blob, "robux", 1, true)
		or string.find(blob, "purchase", 1, true)
end

local function limbList(root)
	local limbs = { root }
	local character = root.Parent
	if character then
		for _, name in ipairs({ "RightFoot", "LeftFoot", "Right Leg", "Left Leg", "Torso", "UpperTorso", "LowerTorso" }) do
			local limb = character:FindFirstChild(name)
			if limb and limb:IsA("BasePart") then
				table.insert(limbs, limb)
			end
		end
	end
	return limbs
end

local function touchTargets(inst)
	local list = {}
	local seen = {}
	local function add(part)
		if part and part:IsA("BasePart") and not seen[part] and #list < 5 then
			seen[part] = true
			table.insert(list, part)
		end
	end
	add(inst)
	local model = inst:FindFirstAncestorOfClass("Model")
	if model and Players:GetPlayerFromCharacter(model) then
		return list
	end
	local host = model or inst.Parent
	if host then
		local count = 0
		for _, child in ipairs(host:GetDescendants()) do
			count = count + 1
			if count > 40 or #list >= 5 then
				break
			end
			if child:IsA("TouchTransmitter") or child:IsA("ClickDetector") or child:IsA("ProximityPrompt") then
				add(child.Parent)
			end
		end
	end
	return list
end

local function sendTouch(root, inst, mode)
	if not root or not inst or not inst:IsA("BasePart") or type(firetouchinterest) ~= "function" then
		return
	end
	pcall(function()
		inst.CanTouch = true
		root.CanTouch = true
	end)
	local limbs = limbList(root)
	local parts = touchTargets(inst)
	for _, limb in ipairs(limbs) do
		pcall(function()
			limb.CanTouch = true
		end)
		for _, piece in ipairs(parts) do
			if piece.Parent then
				pcall(firetouchinterest, limb, piece, mode)
				pcall(firetouchinterest, piece, limb, mode)
			end
		end
	end
end

local function fireCollect(inst, root, beginTouch)
	local hosts = { inst }
	local model = inst:FindFirstAncestorOfClass("Model")
	if model and not Players:GetPlayerFromCharacter(model) then
		table.insert(hosts, model)
	elseif inst.Parent then
		table.insert(hosts, inst.Parent)
	end
	local seen = {}
	for _, host in ipairs(hosts) do
		local count = 0
		for _, item in ipairs(host:GetDescendants()) do
			count = count + 1
			if count > 40 then
				break
			end
			if not seen[item] and (item:IsA("ProximityPrompt") or item:IsA("ClickDetector")) then
				seen[item] = true
				if item:IsA("ProximityPrompt") then
					local blob = string.lower(item.Name .. " " .. item.ActionText .. " " .. item.ObjectText)
					if not promptBlocked(blob) then
						local holdFor = item.HoldDuration or 0
						pcall(function()
							item.MaxActivationDistance = 80
							item.RequiresLineOfSight = false
						end)
						if type(fireproximityprompt) == "function" then
							pcall(fireproximityprompt, item)
							pcall(fireproximityprompt, item, holdFor)
							pcall(fireproximityprompt, item, 1)
						end
						pcall(function()
							item:InputHoldBegin()
							item:InputHoldEnd()
						end)
					end
				elseif type(fireclickdetector) == "function" then
					pcall(fireclickdetector, item)
				end
			end
		end
	end
	if beginTouch then
		sendTouch(root, inst, 0)
	end
	local tool = inst:IsA("Tool") and inst or (inst.Parent and inst.Parent:IsA("Tool") and inst.Parent)
	if tool and root and root.Parent then
		local humanoid = root.Parent:FindFirstChildOfClass("Humanoid")
		if humanoid then
			pcall(function()
				humanoid:EquipTool(tool)
			end)
		end
	end
end

local function pinMaterial(root, part)
	local humanoid = root.Parent and root.Parent:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Sit then
		humanoid.Sit = false
	end
	local character = root.Parent
	if character and not state.noclip then
		for _, limb in ipairs(character:GetDescendants()) do
			if limb:IsA("BasePart") then
				if collideSaved[limb] == nil then
					collideSaved[limb] = limb.CanCollide
				end
				limb.CanCollide = false
			end
		end
	end
	local lift = math.clamp(part.Size.Y * 0.5 + 1.5, 1.5, 4)
	root.CFrame = CFrame.new(part.Position + Vector3.new(0, lift, 0))
	pcall(function()
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end)
	state.locking = true
end

local function stayOnMaterial(root, part)
	pinMaterial(root, part)
	local now = os.clock()
	if now < (state.nextTouch or 0) then
		return
	end
	state.nextTouch = now + 0.35
	fireCollect(part, root, true)
	state.touchOpen = true
	local capturedRoot = root
	local captured = part
	task.delay(0.16, function()
		if not state.alive or state.matFocus ~= captured or not captured.Parent or not capturedRoot.Parent then
			return
		end
		sendTouch(capturedRoot, captured, 1)
	end)
end

local function releaseMaterialTouch(root, part)
	if state.touchOpen and root and part and part.Parent and part:IsA("BasePart") then
		sendTouch(root, part, 1)
	end
	state.touchOpen = false
end

local function clearMaterialFocus(root)
	local part = state.matFocus
	state.matFocus = nil
	state.matUntil = 0
	releaseMaterialTouch(root, part)
	if not state.noclip and not state.iqBusy then
		restoreCollide()
	end
end

local function materialHoldActive()
	local part = state.matFocus
	return part ~= nil and part.Parent ~= nil and part:IsDescendantOf(workspace) and os.clock() < (state.matUntil or 0)
end

local function forcePickup(part, root)
	state.matFocus = part
	state.matUntil = os.clock() + 1.2
	state.nextTouch = 0
	state.touchOpen = false
	state.tried[part] = os.clock()
	stayOnMaterial(root, part)
end

local releaseKillCamera

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
	do
		local _, _, root = characterParts()
		if root and state.matFocus then
			releaseMaterialTouch(root, state.matFocus)
		end
	end
	state.matFocus = nil
	state.matUntil = 0
	state.touchOpen = false
	state.locking = false
	state.killPart = nil
	state.aimPoint = nil
	state.iqBusy = false
	state.fovOn = false
	if releaseKillCamera then
		releaseKillCamera()
	end
	local camera = workspace.CurrentCamera
	if camera and state.savedCamType ~= nil then
		camera.CameraType = state.savedCamType
		state.savedCamType = nil
	end
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
	return model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
end

local function nearestPlayer(origin)
	local picked = selectedPlayer()
	if state.killSelected or picked then
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
	local bestDist = math.huge
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
	local bestDist = math.huge
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
	local function walk(folder, depth)
		if depth > 5 or seen > 800 then
			return
		end
		for _, child in ipairs(folder:GetChildren()) do
			consider(child)
			if seen > 800 then
				return
			end
			if (child:IsA("Folder") or child:IsA("Model")) and child.Name ~= BUILD_FOLDER then
				walk(child, depth + 1)
			end
		end
	end
	walk(workspace, 0)
	npcCache.time = now
	npcCache.part = bestPart
	npcCache.name = bestName
	return bestPart, bestName
end

local GUN_HINTS = { "blaster", "laser", "mech", "pistol", "gun", "portal" }

local function isGun(tool)
	local name = string.lower(tool.Name)
	for _, hint in ipairs(GUN_HINTS) do
		if string.find(name, hint, 1, true) then
			return true
		end
	end
	return false
end

local function pointerOverHub()
	if not window or not window.Visible then
		return false
	end
	local pos = UserInputService:GetMouseLocation()
	local origin = window.AbsolutePosition
	local size = window.AbsoluteSize
	return pos.X >= origin.X and pos.X <= origin.X + size.X and pos.Y >= origin.Y and pos.Y <= origin.Y + size.Y
end

local function ensureWeapon()
	local character = LocalPlayer.Character
	local _, humanoid = characterParts()
	if character then
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Tool") and isGun(child) then
				return child
			end
		end
	end
	local tool = findTool(GUN_HINTS)
	if tool and humanoid then
		pcall(function()
			humanoid:UnequipTools()
			humanoid:EquipTool(tool)
		end)
		if state.lastGun ~= tool.Name then
			state.lastGun = tool.Name
			pushLog("Gun " .. tool.Name)
		end
		return tool
	end
	if os.clock() > (state.nextGunKey or 0) and not UserInputService:GetFocusedTextBox() then
		state.nextGunKey = os.clock() + 1.2
		pcall(function()
			VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.X, false, game)
			task.delay(0.06, function()
				if not state.alive then
					return
				end
				pcall(function()
					VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.X, false, game)
				end)
			end)
		end)
		pushLog("Pulling mech blaster")
	end
	return nil
end

local function clickAttack()
	local tool = ensureWeapon()
	if tool then
		pcall(function()
			tool:Activate()
		end)
	end
	if (not window or not window.Visible) and type(mouse1click) == "function" then
		pcall(mouse1click)
	end
end

local function holdKillCamera()
	if state.savedMinZoom == nil then
		state.savedMinZoom = LocalPlayer.CameraMinZoomDistance
		state.savedMaxZoom = LocalPlayer.CameraMaxZoomDistance
	end
	if LocalPlayer.CameraMaxZoomDistance < 20 then
		LocalPlayer.CameraMaxZoomDistance = 80
	end
	if LocalPlayer.CameraMinZoomDistance < 8 then
		LocalPlayer.CameraMinZoomDistance = 8
	end
	if LocalPlayer.CameraMode == Enum.CameraMode.LockFirstPerson then
		LocalPlayer.CameraMode = Enum.CameraMode.Classic
	end
end

releaseKillCamera = function()
	local wasKillCam = state.savedMinZoom ~= nil or state.savedMaxZoom ~= nil
	if state.savedMinZoom ~= nil then
		LocalPlayer.CameraMinZoomDistance = state.savedMinZoom
		state.savedMinZoom = nil
	end
	if state.savedMaxZoom ~= nil then
		LocalPlayer.CameraMaxZoomDistance = state.savedMaxZoom
		state.savedMaxZoom = nil
	end
	if wasKillCam and LocalPlayer.CameraMode == Enum.CameraMode.LockFirstPerson then
		LocalPlayer.CameraMode = Enum.CameraMode.Classic
	end
end

local function placeBehind(root, part, aimCamera)
	local look = part.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 0.2 then
		flat = Vector3.new(0, 0, -1)
	else
		flat = flat.Unit
	end
	local pos = part.Position - flat * 5 + Vector3.new(0, 1.5, 0)
	local model = part.Parent
	local torso = model and (model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso") or model:FindFirstChild("Head"))
	local aim = (torso and torso:IsA("BasePart") and torso.Position) or (part.Position + Vector3.new(0, 1.2, 0))
	state.aimPoint = aim
	root.CFrame = CFrame.lookAt(pos, aim)
	pcall(function()
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end)
	if aimCamera then
		local camera = workspace.CurrentCamera
		if camera then
			local back = aim - pos
			if back.Magnitude < 0.05 then
				back = flat
			else
				back = back.Unit
			end
			local eye = pos - back * 12 + Vector3.new(0, 3, 0)
			camera.CFrame = CFrame.lookAt(eye, aim)
			holdKillCamera()
			local character = root.Parent
			if character then
				for _, inst in ipairs(character:GetDescendants()) do
					if inst:IsA("BasePart") or inst:IsA("Decal") then
						inst.LocalTransparencyModifier = 0
					end
				end
			end
		end
	end
end

local function strike(root, part)
	placeBehind(root, part, true)
end

local aimMouse = LocalPlayer:GetMouse()
if aimMouse and type(hookmetamethod) == "function" then
	local oldIndex
	local hooked = pcall(function()
		oldIndex = hookmetamethod(game, "__index", function(self, key)
			if state.aimPoint and self == aimMouse then
				if type(checkcaller) == "function" then
					local callerOk, ours = pcall(checkcaller)
					if callerOk and ours then
						return oldIndex(self, key)
					end
				end
				if key == "Hit" then
					return CFrame.new(state.aimPoint)
				elseif key == "Target" then
					return state.killPart
				elseif key == "UnitRay" then
					local camera = workspace.CurrentCamera
					local origin = camera and camera.CFrame.Position or state.aimPoint
					local delta = state.aimPoint - origin
					if delta.Magnitude < 0.05 then
						delta = Vector3.new(0, 0, -1)
					end
					return Ray.new(origin, delta.Unit)
				elseif key == "X" or key == "Y" then
					local camera = workspace.CurrentCamera
					if camera then
						local screen = camera:WorldToViewportPoint(state.aimPoint)
						if key == "X" then
							return screen.X
						end
						return screen.Y
					end
				end
			end
			return oldIndex(self, key)
		end)
	end)
	if not hooked then
		oldIndex = nil
	end
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

local function scanQuestText()
	local bestNamed = ""
	local bestLoose = ""
	local seen = 0
	local function consider(inst)
		if gui and inst:IsDescendantOf(gui) then
			return
		end
		if not (inst:IsA("TextLabel") or inst:IsA("TextButton")) or not inst.Visible then
			return
		end
		local nameBlob = string.lower(inst.Name)
		local parent = inst.Parent
		for _ = 1, 6 do
			if not parent then
				break
			end
			nameBlob = nameBlob .. " " .. string.lower(parent.Name)
			parent = parent.Parent
		end
		local text = inst.Text or ""
		if #text < 3 or #text > 140 then
			return
		end
		local lower = string.lower(text)
		local named = string.find(nameBlob, "quest", 1, true)
			or string.find(nameBlob, "mission", 1, true)
			or string.find(nameBlob, "objective", 1, true)
			or string.find(nameBlob, "bounty", 1, true)
			or string.find(nameBlob, "task", 1, true)
		local objective = string.find(lower, "kill", 1, true)
			or string.find(lower, "eliminat", 1, true)
			or string.find(lower, "defeat", 1, true)
			or string.find(lower, "collect", 1, true)
			or string.find(lower, "scrap", 1, true)
			or string.find(lower, "gather", 1, true)
		local targeted = string.find(lower, "player", 1, true)
			or string.find(lower, "pvp", 1, true)
			or string.find(lower, "creature", 1, true)
			or string.find(lower, "npc", 1, true)
			or string.find(lower, "monster", 1, true)
			or string.find(lower, "scrap", 1, true)
			or string.find(lower, "material", 1, true)
			or string.find(lower, "bot", 1, true)
		if named and #text > #bestNamed then
			bestNamed = text
		elseif objective and targeted and #text >= 8 and (bestLoose == "" or #text < #bestLoose) then
			bestLoose = text
		end
	end
	for _, inst in ipairs(PlayerGui:GetDescendants()) do
		seen = seen + 1
		if seen > 1600 then
			break
		end
		consider(inst)
	end
	if bestNamed ~= "" then
		return bestNamed
	end
	return bestLoose
end

local function classifyQuest(text)
	state.questText = text or ""
	state.questKillPlayers = false
	state.questKillNpc = false
	state.questCollect = false
	local lower = string.lower(state.questText)
	if lower == "" then
		return
	end
	local creatures = string.find(lower, "npc", 1, true)
		or string.find(lower, "creature", 1, true)
		or string.find(lower, "monster", 1, true)
		or string.find(lower, "bot", 1, true)
	local people = string.find(lower, "player", 1, true) or string.find(lower, "pvp", 1, true)
	local killing = string.find(lower, "kill", 1, true)
		or string.find(lower, "eliminat", 1, true)
		or string.find(lower, "defeat", 1, true)
		or string.find(lower, "shoot", 1, true)
	if creatures then
		state.questKillNpc = true
	end
	if people or (killing and not creatures) then
		state.questKillPlayers = true
	end
	if string.find(lower, "collect", 1, true)
		or string.find(lower, "scrap", 1, true)
		or string.find(lower, "pickup", 1, true)
		or string.find(lower, "gather", 1, true)
		or string.find(lower, "material", 1, true) then
		state.questCollect = true
	end
end

local function runQuest(root)
	classifyQuest(scanQuestText())
	if state.questText ~= "" and state.lastQuest ~= state.questText then
		state.lastQuest = state.questText
		pushLog("Quest " .. state.questText)
	end
	if state.questKillPlayers or state.questKillNpc or state.questCollect then
		return
	end
	local best = nil
	local bestPos = nil
	local bestDist = math.huge
	local seen = 0
	for _, inst in ipairs(workspace:GetDescendants()) do
		seen = seen + 1
		if seen > 5000 then
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
		if state.questText == "" and os.clock() > (state.nextQuestNote or 0) then
			state.nextQuestNote = os.clock() + 8
			pushLog("No quest text or prompt")
		end
		return
	end
	root.CFrame = CFrame.new(bestPos + Vector3.new(0, 3, 0))
	pcall(function()
		root.AssemblyLinearVelocity = Vector3.zero
	end)
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
	if now - iqWorld.at < 2 then
		if not iqWorld.inst or (iqWorld.inst.Parent and iqWorld.pos) then
			return iqWorld.inst, iqWorld.pos, iqWorld.label
		end
	end
	local best = nil
	local bestPos = nil
	local bestLabel = nil
	local bestDist = math.huge
	local seen = 0
	for _, inst in ipairs(workspace:GetDescendants()) do
		seen = seen + 1
		if seen > 6000 then
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

local function closestClaim(origin)
	local best = nil
	local bestPos = nil
	local bestDist = math.huge
	local seen = 0
	for _, inst in ipairs(workspace:GetDescendants()) do
		seen = seen + 1
		if seen > 6000 then
			break
		end
		if inst:IsA("ProximityPrompt") and inst.Enabled then
			local blob = string.lower(inst.Name .. " " .. inst.ActionText .. " " .. inst.ObjectText)
			if string.find(blob, "claim", 1, true) or string.find(blob, "collect", 1, true) or string.find(blob, "pickup", 1, true) then
				local pos = promptPosition(inst)
				if pos then
					local dist = (pos - origin).Magnitude
					if dist < bestDist then
						bestDist = dist
						best = inst
						bestPos = pos
					end
				end
			end
		end
	end
	return best, bestPos
end

local scrapCache = { at = 0, inst = nil, pos = nil, label = nil }

local function hasWord(blob, word)
	return string.match(blob, "^" .. word .. "$")
		or string.match(blob, "^" .. word .. "[^%a]")
		or string.match(blob, "[^%a]" .. word .. "$")
		or string.match(blob, "[^%a]" .. word .. "[^%a]")
end

local function isScrapName(blob)
	return hasWord(blob, "scrap")
		or hasWord(blob, "metal")
		or hasWord(blob, "iron")
		or hasWord(blob, "steel")
		or hasWord(blob, "junk")
end

local function closestScrap(origin)
	local now = os.clock()
	if now - scrapCache.at < 1.5 then
		if not scrapCache.inst or (scrapCache.inst.Parent and scrapCache.pos) then
			return scrapCache.inst, scrapCache.pos, scrapCache.label
		end
	end
	local best = nil
	local bestPos = nil
	local bestLabel = nil
	local bestDist = math.huge
	local seen = 0
	for _, inst in ipairs(workspace:GetDescendants()) do
		seen = seen + 1
		if seen > 6000 then
			break
		end
		if not ownedByPlayer(inst) and not inst:FindFirstAncestor(BUILD_FOLDER) then
			local pos = nil
			local label = nil
			if inst:IsA("ProximityPrompt") and inst.Enabled then
				local blob = string.lower(inst.Name .. " " .. inst.ActionText .. " " .. inst.ObjectText)
				if isScrapName(blob) then
					pos = promptPosition(inst)
					label = inst.ObjectText ~= "" and inst.ObjectText or inst.Name
				end
			elseif inst:IsA("BasePart") or inst:IsA("Model") or inst:IsA("ClickDetector") then
				local blob = string.lower(inst.Name)
				if inst:IsA("ClickDetector") and inst.Parent then
					blob = blob .. " " .. string.lower(inst.Parent.Name)
				end
				if isScrapName(blob) then
					pos = iqPoint(inst)
					label = inst.Name
					if inst:IsA("BasePart") then
						local size = inst.Size
						if size.X > 30 or size.Y > 30 or size.Z > 30 then
							pos = nil
						end
					end
				end
			end
			if pos then
				local dist = (pos - origin).Magnitude
				if dist < bestDist then
					bestDist = dist
					best = inst
					bestPos = pos
					bestLabel = label
				end
			end
		end
	end
	scrapCache.at = now
	scrapCache.inst = best
	scrapCache.pos = bestPos
	scrapCache.label = bestLabel
	return best, bestPos, bestLabel
end

local function partMentionsIq(part)
	if mentionsIq(part.Name) then
		return true
	end
	local model = part:FindFirstAncestorOfClass("Model")
	if model and mentionsIq(model.Name) then
		return true
	end
	for _, child in ipairs(part:GetChildren()) do
		if child:IsA("ProximityPrompt") or child:IsA("TextLabel") then
			local blob = child.Name
			if child:IsA("ProximityPrompt") then
				blob = blob .. " " .. child.ActionText .. " " .. child.ObjectText
			elseif child:IsA("TextLabel") then
				blob = blob .. " " .. child.Text
			end
			if mentionsIq(blob) then
				return true
			end
		end
	end
	return false
end

local function pickupBlob(inst)
	local blob = string.lower(inst.Name)
	if inst:IsA("ProximityPrompt") then
		blob = blob .. " " .. string.lower((inst.ActionText or "") .. " " .. (inst.ObjectText or ""))
	end
	return blob
end

local function blobIsPickup(blob)
	if blob == "" or promptBlocked(blob) or mentionsIq(blob) then
		return false
	end
	if isScrapName(blob) then
		return true
	end
	return string.find(blob, "pick", 1, true)
		or string.find(blob, "collect", 1, true)
		or string.find(blob, "grab", 1, true)
		or string.find(blob, "loot", 1, true)
		or hasWord(blob, "take")
end

hasPickupSignal = function(part)
	if not part or not part.Parent then
		return false
	end
	local function interesting(node, deep)
		if blobIsPickup(string.lower(node.Name)) then
			return true
		end
		local list = deep and node:GetDescendants() or node:GetChildren()
		local seen = 0
		for _, child in ipairs(list) do
			seen = seen + 1
			if seen > 40 then
				break
			end
			if child:IsA("ProximityPrompt") and blobIsPickup(pickupBlob(child)) then
				return true
			end
			if child:IsA("ClickDetector") then
				local hostName = child.Parent and child.Parent.Name or child.Name
				if blobIsPickup(string.lower(hostName .. " " .. child.Name)) then
					return true
				end
			end
			if child:IsA("TouchTransmitter") and child.Parent and child.Parent:IsA("BasePart") then
				local host = child.Parent
				local blob = string.lower(host.Name .. " " .. node.Name)
				if (not host.Anchored or blobIsPickup(blob)) and materialEligible(host) then
					return true
				end
			end
		end
		return false
	end
	if interesting(part, false) then
		return true
	end
	local model = part:FindFirstAncestorOfClass("Model")
	if model and not Players:GetPlayerFromCharacter(model) and interesting(model, true) then
		return true
	end
	if part.Parent and not part.Parent:IsA("Model") and interesting(part.Parent, false) then
		return true
	end
	return false
end

local function closestGround(origin)
	local bestSignal, bestLoose = nil, nil
	local signalDist, looseDist = math.huge, math.huge
	local seen = {}
	for _, parts in pairs(state.matIndex) do
		for _, part in ipairs(parts) do
			if not seen[part] and part.Parent and not wasTried(part) and materialEligible(part) and not partMentionsIq(part) then
				seen[part] = true
				local dist = (part.Position - origin).Magnitude
				if hasPickupSignal(part) then
					if dist < signalDist then
						signalDist = dist
						bestSignal = part
					end
				elseif not part.Anchored then
					if dist < looseDist then
						looseDist = dist
						bestLoose = part
					end
				end
			end
		end
	end
	return bestSignal or bestLoose
end

local function nextGroundPart(origin)
	if state.material and state.matIndex[state.material] then
		for _ = 1, 8 do
			local part = closestMaterial(origin)
			if not part then
				return nil
			end
			if not partMentionsIq(part) then
				return part
			end
			state.tried[part] = os.clock()
		end
		return nil
	end
	return closestGround(origin)
end

local function runMaterials(root)
	local scraping = state.autoMat or (state.autoQuest and state.questCollect)
	if not scraping or not inPortal() then
		if state.matFocus then
			clearMaterialFocus(root)
		end
		return
	end
	if state.autoIq and not state.autoMat then
		if state.matFocus then
			clearMaterialFocus(root)
		end
		return
	end
	local _, humanoid = characterParts()
	if humanoid and humanoid.Sit then
		humanoid.Sit = false
	end
	state.iqBusy = false
	if state.autoKill or (state.autoQuest and (state.questKillPlayers or state.questKillNpc)) then
		if state.matFocus then
			clearMaterialFocus(root)
		end
		return
	end
	local now = os.clock()
	if state.matFocus then
		if not state.matFocus.Parent or not state.matFocus:IsDescendantOf(workspace) then
			local label = state.matLabel or "material"
			clearMaterialFocus(root)
			pushLog("Collected " .. tostring(label))
			state.nextMat = 0
		elseif now < (state.matUntil or 0) then
			stayOnMaterial(root, state.matFocus)
			return
		else
			clearMaterialFocus(root)
		end
	end
	if now < (state.nextMat or 0) then
		return
	end
	state.nextMat = now + 0.15
	if now - (state.matScanAt or 0) > 2 then
		scanMaterials()
	end
	local part = nextGroundPart(root.Position)
	if not part then
		state.locking = false
		if now > (state.nextMatNote or 0) then
			state.nextMatNote = now + 6
			if state.material then
				pushLog("No more " .. prettyMaterial(state.material) .. " on the ground")
			else
				pushLog("No ground material")
			end
		end
		return
	end
	local label = part.Parent and part.Parent:IsA("Model") and part.Parent.Name or part.Name
	if state.material then
		label = prettyMaterial(state.material) .. " " .. label
	end
	state.matLabel = label
	if state.lastMat ~= part then
		state.lastMat = part
		pushLog("Picking up " .. tostring(label))
	end
	forcePickup(part, root)
end

local iqSeat = { at = 0, seat = nil, names = "" }

local function seatMentionsIq(seat)
	if mentionsIq(seat.Name) then
		return true
	end
	local parent = seat.Parent
	if parent and (mentionsIq(parent.Name) or (parent.Parent and mentionsIq(parent.Parent.Name))) then
		return true
	end
	local function blobMentions(inst)
		local blob = inst.Name
		if inst:IsA("ProximityPrompt") then
			blob = blob .. " " .. inst.ActionText .. " " .. inst.ObjectText
		elseif inst:IsA("TextLabel") or inst:IsA("TextButton") then
			blob = blob .. " " .. (inst.Text or "")
		end
		return mentionsIq(blob)
	end
	for _, inst in ipairs(seat:GetDescendants()) do
		if blobMentions(inst) then
			return true
		end
	end
	if parent then
		for _, inst in ipairs(parent:GetChildren()) do
			if blobMentions(inst) then
				return true
			end
		end
	end
	local ok, attrs = pcall(function()
		return seat:GetAttributes()
	end)
	if ok and type(attrs) == "table" then
		for key, value in pairs(attrs) do
			if mentionsIq(tostring(key) .. " " .. tostring(value)) then
				return true
			end
		end
	end
	return false
end

local function findIqSeat()
	local now = os.clock()
	if now - iqSeat.at < 2 and iqSeat.seat and iqSeat.seat.Parent then
		return iqSeat.seat
	end
	local _, _, root = characterParts()
	local origin = root and root.Position or Vector3.zero
	local best = nil
	local bestDist = math.huge
	local signPos = nil
	local signDist = math.huge
	local names = {}
	local seen = 0
	for _, inst in ipairs(workspace:GetDescendants()) do
		seen = seen + 1
		if seen > 6000 then
			break
		end
		if (inst:IsA("Seat") or inst:IsA("VehicleSeat")) and not ownedByPlayer(inst) then
			if #names < 6 then
				table.insert(names, inst.Name)
			end
			if seatMentionsIq(inst) then
				local dist = (inst.Position - origin).Magnitude
				if dist < bestDist then
					bestDist = dist
					best = inst
				end
			end
		elseif not signPos or signDist > 0 then
			local blob = nil
			if inst:IsA("TextLabel") or inst:IsA("TextButton") then
				blob = inst.Text
			elseif inst:IsA("ProximityPrompt") then
				blob = inst.Name .. " " .. inst.ActionText .. " " .. inst.ObjectText
			end
			if blob and mentionsIq(blob) then
				local pos = iqPoint(inst)
				if not pos then
					local part = inst:FindFirstAncestorWhichIsA("BasePart")
					local board = inst:FindFirstAncestorWhichIsA("BillboardGui") or inst:FindFirstAncestorWhichIsA("SurfaceGui")
					if board and board.Adornee and board.Adornee:IsA("BasePart") then
						pos = board.Adornee.Position
					elseif part then
						pos = part.Position
					end
				end
				if pos then
					local dist = (pos - origin).Magnitude
					if dist < signDist then
						signDist = dist
						signPos = pos
					end
				end
			end
		end
	end
	if not best and signPos then
		local nearDist = 45
		for _, inst in ipairs(workspace:GetDescendants()) do
			if (inst:IsA("Seat") or inst:IsA("VehicleSeat")) and not ownedByPlayer(inst) then
				local dist = (inst.Position - signPos).Magnitude
				if dist < nearDist then
					nearDist = dist
					best = inst
				end
			end
		end
	end
	iqSeat.at = now
	iqSeat.seat = best
	iqSeat.names = table.concat(names, ", ")
	return best
end

local function fireSeatPrompt(seat)
	for _, inst in ipairs(seat:GetDescendants()) do
		if inst:IsA("ProximityPrompt") and inst.Enabled then
			firePrompt(inst)
		end
	end
	local parent = seat.Parent
	if not parent then
		return
	end
	for _, inst in ipairs(parent:GetChildren()) do
		if inst:IsA("ProximityPrompt") and inst.Enabled then
			local blob = inst.Name .. " " .. inst.ActionText .. " " .. inst.ObjectText
			if mentionsIq(blob) or string.find(string.lower(blob), "sit", 1, true) then
				firePrompt(inst)
			end
		end
	end
end

local function runIq(root)
	if state.autoMat or not state.autoIq or not inPortal() then
		if state.autoMat or not state.autoIq then
			state.iqBusy = false
		end
		return
	end
	local now = os.clock()
	if now >= (state.nextIqRead or 0) then
		state.nextIqRead = now + 0.6
		refreshIq()
	end
	local _, humanoid = characterParts()
	if not humanoid then
		state.iqBusy = false
		return
	end
	local seat = findIqSeat()
	if not seat then
		state.iqBusy = false
		state.locking = false
		if now > (state.nextIqNote or 0) then
			state.nextIqNote = now + 6
			local names = iqSeat.names
			if names and names ~= "" then
				pushLog("No IQ chair. Seats: " .. names)
			else
				pushLog("No IQ chair")
			end
		end
		return
	end
	if seat.Occupant and seat.Occupant ~= humanoid then
		state.iqBusy = false
		state.locking = false
		if now > (state.nextIqNote or 0) then
			state.nextIqNote = now + 6
			pushLog("IQ chair is taken")
		end
		return
	end
	state.locking = true
	state.iqBusy = true
	state.killPart = nil
	state.aimPoint = nil
	if humanoid.SeatPart == seat then
		pcall(function()
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end)
		return
	end
	if humanoid.SeatPart and humanoid.SeatPart ~= seat then
		humanoid.Sit = false
	end
	pcall(function()
		seat.Disabled = false
	end)
	local tried = state.iqTried[seat]
	if not tried or now - tried > 2 then
		state.iqTried[seat] = now
		fireSeatPrompt(seat)
		if state.lastIqTarget ~= seat.Name then
			state.lastIqTarget = seat.Name
			pushLog("IQ chair " .. seat.Name)
		end
	end
	root.CFrame = seat.CFrame * CFrame.new(0, 3, 0)
	pcall(function()
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end)
	pcall(function()
		seat:Sit(humanoid)
	end)
end

local function runCombat(root)
	if not inPortal() then
		state.locking = false
		state.killPart = nil
		state.aimPoint = nil
		return
	end
	if state.iqBusy then
		state.locking = true
		state.killPart = nil
		state.aimPoint = nil
		return
	end
	local now = os.clock()
	if state.autoQuest and now >= (state.nextQuest or 0) then
		state.nextQuest = now + 1.15
		runQuest(root)
	end
	local killPlayers = state.autoKill or (state.autoQuest and state.questKillPlayers)
	local killNpcs = state.autoQuest and state.questKillNpc
	if killPlayers or killNpcs then
		local part, label = nil, nil
		if killPlayers then
			part, label = nearestPlayer(root.Position)
		end
		if not part and killNpcs then
			part, label = nearestNpc(root.Position)
		end
		if not part then
			state.locking = false
			state.killPart = nil
			state.aimPoint = nil
			local picked = selectedPlayer()
			if (state.killSelected or picked) and now > (state.nextKillNote or 0) then
				state.nextKillNote = now + 4
				pushLog(picked and (picked.DisplayName .. " is down") or "Pick a player on the right")
			end
			return
		end
		state.locking = true
		state.killPart = part
		placeBehind(root, part, true)
		if state.lastTarget ~= label then
			state.lastTarget = label
			pushLog("Target " .. tostring(label))
		end
		return
	end
	state.killPart = nil
	state.aimPoint = nil
	if not state.autoFarm then
		if not materialHoldActive() then
			state.locking = false
		end
		return
	end
	if now < (state.nextHit or 0) then
		return
	end
	local _, humanoid = characterParts()
	if humanoid and humanoid.Health > 0 and humanoid.Health < humanoid.MaxHealth * 0.35 then
		if not materialHoldActive() then
			state.locking = false
		end
		return
	end
	state.nextHit = now + 0.32
	local part, label = nil, nil
	if state.farmPlayers then
		part, label = nearestPlayer(root.Position)
	end
	if not part then
		part, label = nearestNpc(root.Position)
	end
	if not part then
		if not materialHoldActive() then
			state.locking = false
		end
		state.killPart = nil
		state.aimPoint = nil
		return
	end
	state.locking = true
	state.killPart = part
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
	if state.iqBusy and next(collideSaved) then
		restoreCollide()
	end
	if state.noclip and inPortal() and not state.iqBusy then
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				if collideSaved[part] == nil then
					collideSaved[part] = part.CanCollide
				end
				part.CanCollide = false
			end
		end
	end
	if materialHoldActive() then
		state.locking = true
	end
	if state.fly and inPortal() and not state.iqBusy and not state.killPart and not materialHoldActive() then
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
	local function feature(name, fn)
		local ok, err = pcall(fn)
		if not ok and os.clock() > (state.nextErr or 0) then
			state.nextErr = os.clock() + 5
			pushLog(name .. " failed")
			warn("[VOIDZ] " .. name .. " " .. tostring(err))
		end
	end
	feature("IQ", function()
		runIq(root)
	end)
	feature("Scrap", function()
		runMaterials(root)
	end)
	local scrapOn = state.autoMat or (state.autoQuest and state.questCollect)
	if (state.autoRegen or scrapOn) and not state.iqBusy and inPortal() and humanoid.Health > 0 and humanoid.MaxHealth > 0 then
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
	feature("Combat", function()
		runCombat(root)
	end)
	local cameraNow = workspace.CurrentCamera
	if cameraNow and state.savedCamType ~= nil and not state.killPart then
		cameraNow.CameraType = state.savedCamType
		state.savedCamType = nil
	end
	if state.killPart then
		if state.savedRotate == nil then
			state.savedRotate = humanoid.AutoRotate
		end
		humanoid.AutoRotate = false
	else
		if state.savedRotate ~= nil then
			humanoid.AutoRotate = state.savedRotate
			state.savedRotate = nil
		end
		releaseKillCamera()
	end
	if state.autoBuild and inPortal() and not state.locking and not state.iqBusy then
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
	if materialHoldActive() then
		state.locking = true
	end
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

local function looksLikeCode(text)
	if type(text) ~= "string" then
		return false
	end
	text = string.gsub(text, "^%s+", "")
	text = string.gsub(text, "%s+$", "")
	if #text < 3 or #text > 24 then
		return false
	end
	if not string.match(text, "^[%w_%-]+$") then
		return false
	end
	local lower = string.lower(text)
	local banned = {
		gear = true,
		codes = true,
		code = true,
		shop = true,
		claim = true,
		redeem = true,
		vip = true,
		gun = true,
		guns = true,
		vehicles = true,
		gamepasses = true,
		custom = true,
		portal = true,
		close = true,
		enter = true,
		submit = true,
		text = true,
		button = true,
		frame = true,
	}
	return banned[lower] ~= true
end

local function clickGui(button)
	if type(firesignal) == "function" then
		pcall(firesignal, button.MouseButton1Click)
		pcall(firesignal, button.Activated)
	end
	local size = button.AbsoluteSize
	if size.X < 2 or size.Y < 2 then
		return
	end
	local pos = button.AbsolutePosition
	local x = pos.X + size.X * 0.5
	local y = pos.Y + size.Y * 0.5
	pcall(function()
		VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
	end)
	task.wait(0.05)
	pcall(function()
		VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
	end)
end

local function guiBlob(inst)
	local text = ""
	if inst:IsA("TextButton") or inst:IsA("TextLabel") or inst:IsA("TextBox") then
		text = inst.Text
	end
	local placeholder = ""
	if inst:IsA("TextBox") then
		placeholder = inst.PlaceholderText
	end
	return string.lower(inst.Name .. " " .. text .. " " .. placeholder .. " " .. (inst.Parent and inst.Parent.Name or ""))
end

local function paidBlob(blob)
	return string.find(blob, "robux", 1, true)
		or string.find(blob, "buy", 1, true)
		or string.find(blob, "purchase", 1, true)
		or string.find(blob, "gamepass", 1, true)
		or string.find(blob, "vip", 1, true)
end

local function nearCode(inst)
	local current = inst
	for _ = 1, 5 do
		if not current then
			return false
		end
		if string.find(string.lower(current.Name), "code", 1, true) then
			return true
		end
		current = current.Parent
	end
	return false
end

local function redeemAll()
	if state.redeeming then
		pushLog("Already redeeming")
		return
	end
	if not requireGame() then
		return
	end
	state.redeeming = true
	task.spawn(function()
		local found = {}
		local function add(text)
			if not looksLikeCode(text) then
				return
			end
			local key = string.lower(text)
			if not found[key] then
				found[key] = text
			end
		end
		for piece in string.gmatch(state.extraCodes or "", "[^,%s]+") do
			add(piece)
		end
		pcall(function()
			local replicated = game:GetService("ReplicatedStorage")
			local function harvest(inst, depth)
				if depth > 2 then
					return
				end
				if inst:IsA("StringValue") then
					add(inst.Value)
					if string.find(string.lower(inst.Parent and inst.Parent.Name or ""), "code", 1, true) then
						add(inst.Name)
					end
				end
				if string.find(string.lower(inst.Name), "code", 1, true) then
					for _, child in ipairs(inst:GetChildren()) do
						harvest(child, depth + 1)
					end
				end
			end
			for _, child in ipairs(replicated:GetChildren()) do
				harvest(child, 0)
			end
		end)
		local seen = 0
		local codesTab = nil
		local codeBox = nil
		local redeemButton = nil
		local claims = {}
		for _, inst in ipairs(PlayerGui:GetDescendants()) do
			seen = seen + 1
			if seen > 1200 then
				break
			end
			if gui and inst:IsDescendantOf(gui) then
				continue
			end
			local blob = guiBlob(inst)
			if paidBlob(blob) then
				continue
			end
			if (inst:IsA("TextButton") or inst:IsA("ImageButton")) and inst.Visible and nearCode(inst) then
				if not codesTab and string.find(blob, "codes", 1, true) and not string.find(blob, "barcode", 1, true) then
					codesTab = inst
				end
				if string.find(blob, "redeem", 1, true) or string.find(blob, "claim", 1, true) or string.find(blob, "submit", 1, true) then
					if not redeemButton and string.find(blob, "redeem", 1, true) then
						redeemButton = inst
					else
						table.insert(claims, inst)
					end
				end
			elseif inst:IsA("TextBox") and nearCode(inst) then
				codeBox = inst
			elseif inst:IsA("TextLabel") and nearCode(inst) then
				add(inst.Text)
			end
		end
		if codesTab then
			clickGui(codesTab)
			pushLog("Opened Codes tab")
			task.wait(0.35)
		end
		local list = {}
		for _, text in pairs(found) do
			table.insert(list, text)
		end
		table.sort(list)
		local used = 0
		if codeBox and #list > 0 then
			for _, text in ipairs(list) do
				if not state.alive then
					break
				end
				codeBox.Text = text
				pcall(function()
					codeBox:CaptureFocus()
					codeBox:ReleaseFocus(true)
				end)
				if redeemButton then
					clickGui(redeemButton)
				end
				used = used + 1
				pushLog("Redeem " .. text)
				task.wait(0.55)
			end
		end
		local clicked = 0
		for _, button in ipairs(claims) do
			if not state.alive or clicked >= 12 then
				break
			end
			if button.Parent then
				clickGui(button)
				clicked = clicked + 1
				task.wait(0.45)
			end
		end
		state.redeeming = false
		if used == 0 and clicked == 0 then
			pushLog("No code string on screen. Paste codes, then redeem again")
		else
			pushLog("Redeem pass done · " .. tostring(used) .. " typed · " .. tostring(clicked) .. " claim buttons")
		end
	end)
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
		note(centerHolder, "RightShift hides the hub. Materials auto collect picks up parts on the ground. Auto IQ sits in the IQ chair. Auto kill stays behind a player from anywhere.", nextOrder())
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
		note(centerHolder, "Auto kill stays on the target and fires after the camera is aimed, so the shot hits. The camera stays in third person. If you select a player, it only hunts that player and waits when they die. It does not switch to someone else.", nextOrder())
		toggleRow(centerHolder, "Auto kill", nextOrder(), state.autoKill, function()
			if not state.autoKill and not requireGame() then
				return
			end
			state.autoKill = not state.autoKill
			if not state.autoKill then
				state.killPart = nil
				state.aimPoint = nil
				state.locking = false
				releaseKillCamera()
				local camera = workspace.CurrentCamera
				if camera and state.savedCamType ~= nil then
					camera.CameraType = state.savedCamType
					state.savedCamType = nil
				end
			end
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
		note(centerHolder, "Auto collect stands on the closest scrap, fires the pickup, and stays until the game takes it. Then it goes to the next one. It skips chairs. Choose a material to grab only that type.", nextOrder())
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
			state.autoMat = not state.autoMat
			if state.autoMat then
				scanMaterials()
			else
				local _, _, root = characterParts()
				clearMaterialFocus(root)
				state.locking = false
			end
			pushLog(state.autoMat and "Auto collect on" or "Auto collect off")
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
		note(centerHolder, "Auto IQ puts you in the chair that gives IQ and stays there. It does not pick up scrap or shoot. The number above is the IQ stat if the game shows one.", nextOrder())
		toggleRow(centerHolder, "Auto IQ", nextOrder(), state.autoIq, function()
			if not state.autoIq and not requireGame() then
				return
			end
			state.autoIq = not state.autoIq
			if state.autoIq then
				refreshIq()
			else
				state.iqBusy = false
				state.locking = false
			end
			pushLog(state.autoIq and ("Auto IQ on · " .. state.iqText) or "Auto IQ off")
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
		note(centerHolder, "Auto quest reads the quest text on screen and does it from anywhere. Kill players keeps you behind a player. Creatures keeps you behind one. Collect or scrap picks up ground materials. Anything else teleports to the closest quest prompt.", nextOrder())
		toggleRow(centerHolder, "Auto farm", nextOrder(), state.autoFarm, function()
			if not state.autoFarm and not requireGame() then
				return
			end
			state.autoFarm = not state.autoFarm
			if not state.autoFarm and not state.autoKill then
				state.killPart = nil
				state.aimPoint = nil
				state.locking = false
			end
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
		return
	end

	if state.page == "Codes" then
		note(centerHolder, "The shop in the Oct 28 guide has a Codes tab. That video never shows a code string, and a comment on it says the codes were not shown. Redeem all opens that tab, types any codes you paste, and presses claim buttons that are not Robux purchases. It does not call a guessed remote.", nextOrder())
		local box = Instance.new("TextBox")
		box.Size = UDim2.new(1, 0, 0, 34)
		box.BackgroundColor3 = C.card
		box.BorderSizePixel = 0
		box.ClearTextOnFocus = false
		box.Font = Enum.Font.Gotham
		box.PlaceholderColor3 = C.muted
		box.PlaceholderText = "Paste codes, separated by spaces"
		box.Text = state.extraCodes or ""
		box.TextColor3 = C.text
		box.TextSize = 14
		box.TextXAlignment = Enum.TextXAlignment.Left
		box.LayoutOrder = nextOrder()
		box.Parent = centerHolder
		corner(box, 6)
		local inset = Instance.new("UIPadding")
		inset.PaddingLeft = UDim.new(0, 8)
		inset.Parent = box
		box.FocusLost:Connect(function()
			state.extraCodes = box.Text
		end)
		actionButton(centerHolder, "Redeem all", nextOrder(), function()
			state.extraCodes = box.Text
			redeemAll()
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
	pcall(function()
		RunService:UnbindFromRenderStep("VOIDZ_PORTAL_STICK")
		RunService:UnbindFromRenderStep("VOIDZ_PORTAL_MAT")
	end)
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

local pages = { "Home", "Move", "Materials", "PvP", "Farm", "Codes", "Build", "Portals", "Tools", "Visuals", "Players", "Settings" }
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
	if not state.infJump or not inPortal() or state.iqBusy then
		return
	end
	local _, humanoid = characterParts()
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)
bind(RunService.Heartbeat, onHeartbeat)
pcall(function()
	RunService:UnbindFromRenderStep("VOIDZ_PORTAL_STICK")
	RunService:UnbindFromRenderStep("VOIDZ_PORTAL_MAT")
end)
RunService:BindToRenderStep("VOIDZ_PORTAL_MAT", Enum.RenderPriority.Last.Value, function()
	if not state.alive or state.killPart or not materialHoldActive() then
		return
	end
	local _, _, matRoot = characterParts()
	if matRoot and state.matFocus then
		pinMaterial(matRoot, state.matFocus)
	end
end)
RunService:BindToRenderStep("VOIDZ_PORTAL_STICK", Enum.RenderPriority.Camera.Value + 5, function()
	if not state.alive or not state.killPart or not state.killPart.Parent then
		return
	end
	local ok, err = pcall(function()
		local _, stickHumanoid, stickRoot = characterParts()
		if not stickRoot then
			return
		end
		if stickHumanoid then
			stickHumanoid.AutoRotate = false
			stickHumanoid.PlatformStand = false
		end
		placeBehind(stickRoot, state.killPart, true)
		if os.clock() >= (state.nextHit or 0) then
			state.nextHit = os.clock() + 0.1
			clickAttack()
		end
	end)
	if not ok and os.clock() > (state.nextErr or 0) then
		state.nextErr = os.clock() + 5
		pushLog("Kill aim failed")
		warn("[VOIDZ] kill " .. tostring(err))
	end
end)
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
