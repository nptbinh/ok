--[[

	Universal Aimbot Module by Exunys © CC0 1.0 Universal (2023)

	https://github.com/Exunys

]]

--// Luraph Macros

if LPH_OBFUSCATED == nil then
	LPH_NO_VIRTUALIZE = function(...)
		return ...
	end
end

--// Cache

local game, workspace = game, workspace
local getrawmetatable, pcall, next, tick, getgenv = getrawmetatable, pcall, next, tick, getgenv
local Vector2new, Vector3zero, CFramenew, Color3fromRGB, Color3fromHSV, Drawingnew, TweenInfonew = Vector2.new, Vector3.zero, CFrame.new, Color3.fromRGB, Color3.fromHSV, Drawing and Drawing.new, TweenInfo.new
local mousemoverel, mousemoveabs, tablefind, tableremove, stringlower, stringsub, mathclamp = mousemoverel or (Input and Input.MouseMove), mousemoveabs, table.find, table.remove, string.lower, string.sub, math.clamp
local mouse1press, mouse1release, mouse1click, taskwait = mouse1press, mouse1release, mouse1click, task.wait
local clonefunction, cloneref = clonefunction or LPH_NO_VIRTUALIZE(function(...)
	return ...
end), cloneref or LPH_NO_VIRTUALIZE(function(...)
	return ...
end)

local GameMetatable = getrawmetatable and getrawmetatable(game) or {
	__index = LPH_NO_VIRTUALIZE(function(self, Index)
		return self[Index]
	end),
	__newindex = LPH_NO_VIRTUALIZE(function(self, Index, Value)
		self[Index] = Value
	end)
}

local __index = GameMetatable.__index
local __newindex = GameMetatable.__newindex

local getrenderproperty, setrenderproperty = getrenderproperty or __index, setrenderproperty or __newindex

local _GetService = __index(game, "GetService")
local GetService = function(Service)
	return cloneref(_GetService(game, Service))
end

--// Services

local RunService = GetService("RunService")
local UserInputService = GetService("UserInputService")
local TweenService = GetService("TweenService")
local Players = GetService("Players")

--// Service Methods

local LocalPlayer = __index(Players, "LocalPlayer")
local Camera = __index(workspace, "CurrentCamera")

local FindFirstChild, FindFirstChildOfClass = __index(game, "FindFirstChild"), __index(game, "FindFirstChildOfClass")
local GetDescendants = __index(game, "GetDescendants")
local WorldToViewportPoint = __index(Camera, "WorldToViewportPoint")
local GetPartsObscuringTarget = __index(Camera, "GetPartsObscuringTarget")
local GetMouseLocation = __index(UserInputService, "GetMouseLocation")
local GetPlayers = __index(Players, "GetPlayers")
local GetPlayerFromCharacter = __index(Players, "GetPlayerFromCharacter")
local Mouse = __index(LocalPlayer, "GetMouse")(LocalPlayer)
local CameraViewportSize = __index(Camera, "ViewportSize")

--// Variables

local RequiredDistance, Typing, Running, ServiceConnections, Animation, OriginalSensitivity = 2000, false, false, {}, nil, nil
local Connect, Disconnect = __index(game, "DescendantAdded").Connect

do
	local TemporaryConnection = Connect(__index(game, "DescendantAdded"), function() end)
	Disconnect = TemporaryConnection.Disconnect
	Disconnect(TemporaryConnection)
end

--// Environment

getgenv().ExunysDeveloperAimbot = {
	DeveloperSettings = {
		UpdateMode = "RenderStepped",
		TeamCheckOption = "TeamColor",
		RainbowSpeed = 1,
		DisableWarnings = false
	},

	Settings = {
		Enabled = true,
		TeamCheck = true,
		AliveCheck = true,
		WallCheck = true,
		OffsetToMoveDirection = false,
		OffsetIncrement = 15,
		Sensitivity = 0.2,
		Sensitivity2 = 1,
		LockMode = 1,
		LockPart = "Head",
		TriggerKey = Enum.UserInputType.MouseButton2,
		Toggle = false
	},

	Triggerbot = {
		Enabled = false,
		TeamCheck = true,
		AliveCheck = true,
		AimLockedCheck = false,
		Delay = 0
	},

	ClosestPlayerTracer = {
		Enabled = true,
		Position = 3,
		Transparency = 0.5,
		Thickness = 1,
		RainbowColor = false,
		Color = Color3fromRGB(150, 150, 255)
	},

	FOVSettings = {
		Enabled = true,
		Visible = true,
		Radius = 25,
		NumSides = 60,
		Thickness = 1,
		Transparency = 1,
		Filled = false,
		RainbowColor = false,
		RainbowOutlineColor = false,
		Color = Color3fromRGB(255, 255, 255),
		OutlineColor = Color3fromRGB(0, 0, 0),
		LockedColor = Color3fromRGB(255, 150, 150)
	},

	-- [MỚI] Cấu hình viền phát sáng
	EnemyHighlight = {
		Enabled = true,

		-- true = highlight TẤT CẢ (kể cả đồng đội); false = chỉ người khác team
		HighlightAll = false,

		TeamCheck = true,
		AliveCheck = true,
		WallCheck = true,

		FillTransparency = 1,
		OutlineTransparency = 0,
		DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
		Smoothing = 0.35,

		-- === Màu cho KẺ ĐỊCH ===
		OccludedColor = Color3fromRGB(255, 255, 255), -- bị che - TRẮNG
		VisibleColor = Color3fromRGB(255, 0, 0),      -- nhìn thấy - ĐỎ

		-- === [MỚI] Màu cho ĐỒNG ĐỘI (khi HighlightAll bật) ===
		TeammateOccludedColor = Color3fromRGB(0, 150, 255), -- bị che - XANH DƯƠNG
		TeammateVisibleColor = Color3fromRGB(0, 255, 0),    -- nhìn thấy - XANH LÁ
	},

	Blacklisted = {},
	FOVCircleOutline = Drawingnew("Circle"),
	FOVCircle = Drawingnew("Circle"),
	Tracer = Drawingnew("Line")
}

local Environment, _warn = getgenv().ExunysDeveloperAimbot, clonefunction(warn); warn = function(...)
	return not Environment.DeveloperSettings.DisableWarnings and _warn(...)
end

repeat
	taskwait(0)
until Environment and Environment.FOVCircle and Environment.FOVCircleOutline

setrenderproperty(Environment.FOVCircle, "Visible", false)
setrenderproperty(Environment.FOVCircleOutline, "Visible", false)

--// Core Functions

local FixUsername = LPH_NO_VIRTUALIZE(function(String)
	for _, Value in next, GetPlayers(Players) do
		local Name = __index(Value, "Name")
		if stringsub(stringlower(Name), 1, #String) == stringlower(String) then
			return Name
		end
	end
end)

local GetRainbowColor = LPH_NO_VIRTUALIZE(function()
	local RainbowSpeed = Environment.DeveloperSettings.RainbowSpeed
	return Color3fromHSV(tick() % RainbowSpeed / RainbowSpeed, 1, 1)
end)

local ConvertVector = LPH_NO_VIRTUALIZE(function(Vector)
	return Vector2new(Vector.X, Vector.Y)
end)

local CancelLock = LPH_NO_VIRTUALIZE(function()
	Environment.Locked = nil
	setrenderproperty(Environment.FOVCircle, "Color", Environment.FOVSettings.Color)
	__newindex(UserInputService, "MouseDeltaSensitivity", OriginalSensitivity)
	if Animation then
		Animation:Cancel()
	end
	setrenderproperty(Environment.Tracer, "Visible", Environment.ClosestPlayerTracer.Enabled)
end)

local GetClosestPlayer = LPH_NO_VIRTUALIZE(function(Aux)
	local Settings = Environment.Settings
	local LockPart = Settings.LockPart

	if not Environment.Locked or Aux then
		RequiredDistance = Environment.FOVSettings.Enabled and Environment.FOVSettings.Radius or 2000
		Required3DDistance = 10000

		for _, Value in next, GetPlayers(Players) do
			local Character = __index(Value, "Character")
			local Humanoid = Character and FindFirstChildOfClass(Character, "Humanoid")

			if Value ~= LocalPlayer and not tablefind(Environment.Blacklisted, __index(Value, "Name")) and Character and FindFirstChild(Character, LockPart) and Humanoid then
				local PartPosition, TeamCheckOption = __index(Character[LockPart], "Position"), Environment.DeveloperSettings.TeamCheckOption

				if Settings.TeamCheck and __index(Value, TeamCheckOption) == __index(LocalPlayer, TeamCheckOption) then
					continue
				end

				if Settings.AliveCheck and __index(Humanoid, "Health") <= 0 then
					continue
				end

				if Settings.WallCheck then
					local BlacklistTable = GetDescendants(__index(LocalPlayer, "Character"))
					for _, _Value in next, GetDescendants(Character) do
						BlacklistTable[#BlacklistTable + 1] = _Value
					end
					if #GetPartsObscuringTarget(Camera, {PartPosition}, BlacklistTable) > 0 then
						continue
					end
				end

				local Vector, OnScreen, Distance = WorldToViewportPoint(Camera, PartPosition)
				Vector = ConvertVector(Vector)
				Distance = (GetMouseLocation(UserInputService) - Vector).Magnitude
				local _3DDistance = (__index(Camera, "CFrame").Position - PartPosition).Magnitude

				if Distance < RequiredDistance and _3DDistance < Required3DDistance and OnScreen then
					RequiredDistance, Required3DDistance = Distance, _3DDistance
					if not Aux then
						Environment.Locked = Value
					elseif not Running and not Environment.Locked then
						return Value
					end
				end
			end
		end
	elseif (GetMouseLocation(UserInputService) - ConvertVector(WorldToViewportPoint(Camera, __index(__index(__index(Environment.Locked, "Character"), LockPart), "Position")))).Magnitude > RequiredDistance then
		CancelLock()
	end
end)

local Load = function()
	OriginalSensitivity = __index(UserInputService, "MouseDeltaSensitivity")

	local Settings, Triggerbot, Tracer, FOVCircle, FOVCircleOutline, TracerSettings, FOVSettings, Offset = Environment.Settings, Environment.Triggerbot, Environment.Tracer, Environment.FOVCircle, Environment.FOVCircleOutline, Environment.ClosestPlayerTracer, Environment.FOVSettings
	local OffsetToMoveDirection, LockPart = Settings.OffsetToMoveDirection, Settings.LockPart

	local DeveloperSettings = Environment.DeveloperSettings
	local UpdateMode = DeveloperSettings.UpdateMode
	local TeamCheckOption = DeveloperSettings.TeamCheckOption

	if mouse1press and mouse1release then
		ServiceConnections.Triggerbot = Connect(__index(RunService, UpdateMode), LPH_NO_VIRTUALIZE(function()
			if Triggerbot.Enabled and Mouse.Target then
				local Character = Mouse.Target.Parent
				local Humanoid = FindFirstChildOfClass(Character, "Humanoid")
				local Player = GetPlayerFromCharacter(Players, Character)

				if Character and Humanoid and Player then
					if Triggerbot.TeamCheck and __index(Player, TeamCheckOption) == __index(LocalPlayer, TeamCheckOption) then
						return
					end
					if Triggerbot.AliveCheck and __index(Humanoid, "Health") <= 0 then
						return
					end
					if Triggerbot.AimLockedCheck and not Environment.Locked then
						return
					end
					if Triggerbot.Delay ~= 0 then
						taskwait(Triggerbot.Delay)
					end
					mouse1press(); __index(RunService, UpdateMode):Wait(); mouse1release(); mouse1click(); __index(RunService, UpdateMode):Wait()
				end
			end
		end))
	end

	ServiceConnections.UpdateTracer = Connect(__index(RunService, UpdateMode), LPH_NO_VIRTUALIZE(function()
		local ClosestPlayer = TracerSettings.Enabled and Settings.Enabled and GetClosestPlayer(true)

		if ClosestPlayer then
			setrenderproperty(Tracer, "Visible", true)
			for Index, Value in next, TracerSettings do
				if Index == "Color" then
					continue
				end
				if pcall(getrenderproperty, Tracer, Index) then
					setrenderproperty(Tracer, Index, Value)
				end
			end
			setrenderproperty(Tracer, "Color", TracerSettings.RainbowColor and GetRainbowColor() or TracerSettings.Color)

			if TracerSettings.Position == 1 then
				setrenderproperty(Tracer, "From", Vector2new(CameraViewportSize.X / 2, CameraViewportSize.Y))
			elseif TracerSettings.Position == 2 then
				setrenderproperty(Tracer, "From", CameraViewportSize / 2)
			elseif TracerSettings.Position == 3 then
				setrenderproperty(Tracer, "From", GetMouseLocation(UserInputService))
			else
				TracerSettings.Position = 3
			end
			setrenderproperty(Tracer, "To", ConvertVector(WorldToViewportPoint(Camera, __index(__index(ClosestPlayer, "Character")[Settings.LockPart], "Position"))))
		else
			setrenderproperty(Tracer, "Visible", false)
		end
	end))

	ServiceConnections.RenderSteppedConnection = Connect(__index(RunService, UpdateMode), LPH_NO_VIRTUALIZE(function()
		if FOVSettings.Enabled and Settings.Enabled then
			for Index, Value in next, FOVSettings do
				if Index == "Color" then
					continue
				end
				if pcall(getrenderproperty, FOVCircle, Index) then
					setrenderproperty(FOVCircle, Index, Value)
					setrenderproperty(FOVCircleOutline, Index, Value)
				end
			end
			setrenderproperty(FOVCircle, "Color", (Environment.Locked and FOVSettings.LockedColor) or FOVSettings.RainbowColor and GetRainbowColor() or FOVSettings.Color)
			setrenderproperty(FOVCircleOutline, "Color", FOVSettings.RainbowOutlineColor and GetRainbowColor() or FOVSettings.OutlineColor)
			setrenderproperty(FOVCircleOutline, "Thickness", FOVSettings.Thickness + 1)
			setrenderproperty(FOVCircle, "Position", GetMouseLocation(UserInputService))
			setrenderproperty(FOVCircleOutline, "Position", GetMouseLocation(UserInputService))
		else
			setrenderproperty(FOVCircle, "Visible", false)
			setrenderproperty(FOVCircleOutline, "Visible", false)
		end

		if Running and Settings.Enabled then
			GetClosestPlayer()
			Offset = OffsetToMoveDirection and __index(FindFirstChildOfClass(__index(Environment.Locked, "Character"), "Humanoid"), "MoveDirection") * (mathclamp(Settings.OffsetIncrement, 1, 30) / 10) or Vector3zero

			if Environment.Locked then
				local LockedPosition_Vector3 = __index(__index(Environment.Locked, "Character")[LockPart], "Position")
				local LockedPosition = WorldToViewportPoint(Camera, LockedPosition_Vector3 + Offset)

				if Settings.LockMode == 2 then
					mousemoverel((LockedPosition.X - GetMouseLocation(UserInputService).X) / Settings.Sensitivity2, (LockedPosition.Y - GetMouseLocation(UserInputService).Y) / Settings.Sensitivity2)
				elseif Settings.LockMode == 3 and mousemoveabs then
					mousemoveabs(LockedPosition.X, LockedPosition.Y)
				else
					if Settings.Sensitivity > 0 then
						Animation = TweenService:Create(Camera, TweenInfonew(Settings.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = CFramenew(Camera.CFrame.Position, LockedPosition_Vector3 + Offset)})
						Animation:Play()
					else
						__newindex(Camera, "CFrame", CFramenew(Camera.CFrame.Position, LockedPosition_Vector3 + Offset))
					end
					__newindex(UserInputService, "MouseDeltaSensitivity", 0)
				end

				setrenderproperty(FOVCircle, "Color", FOVSettings.LockedColor)
				setrenderproperty(Tracer, "Visible", false)
			end
		end
	end))

	ServiceConnections.InputBeganConnection = Connect(__index(UserInputService, "InputBegan"), LPH_NO_VIRTUALIZE(function(Input)
		if Typing then return end
		local TriggerKey, Toggle = Settings.TriggerKey, Settings.Toggle
		if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode == TriggerKey or Input.UserInputType == TriggerKey then
			if Toggle then
				Running = not Running
				if not Running then CancelLock() end
			else
				Running = true
			end
		end
	end))

	ServiceConnections.InputEndedConnection = Connect(__index(UserInputService, "InputEnded"), LPH_NO_VIRTUALIZE(function(Input)
		if Typing then return end
		local TriggerKey = Settings.TriggerKey
		if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode == TriggerKey or Input.UserInputType == TriggerKey then
			Running = false; CancelLock()
		end
	end))
end

--// Typing Check

ServiceConnections.TypingStartedConnection = Connect(__index(UserInputService, "TextBoxFocused"), function()
	Typing = true
end)

ServiceConnections.TypingEndedConnection = Connect(__index(UserInputService, "TextBoxFocusReleased"), function()
	Typing = false
end)

--// Interactive User Methods

repeat
	taskwait(0)
until Environment and Load

Environment.Exit = LPH_NO_VIRTUALIZE(function(self)
	assert(self, "EXUNYS_AIMBOT-V3.Exit: Missing parameter #1 \"self\" <table>.")
	for Index, _ in next, ServiceConnections do
		pcall(Disconnect, ServiceConnections[Index])
	end
	Load = nil; ConvertVector = nil; CancelLock = nil; GetClosestPlayer = nil; GetRainbowColor = nil; FixUsername = nil
	self.FOVCircle:Remove()
	self.FOVCircleOutline:Remove()
	self.Tracer:Remove()
	getgenv().ExunysDeveloperAimbot = nil; pcall(collectgarbage, "step", 200)
end)

Environment.Restart = LPH_NO_VIRTUALIZE(function()
	for Index, _ in next, ServiceConnections do
		pcall(Disconnect, ServiceConnections[Index])
	end
	Load()
end)

Environment.Blacklist = LPH_NO_VIRTUALIZE(function(self, Username)
	assert(self, "EXUNYS_AIMBOT-V3.Blacklist: Missing parameter #1 \"self\" <table>.")
	assert(Username, "EXUNYS_AIMBOT-V3.Blacklist: Missing parameter #2 \"Username\" <string>.")
	Username = FixUsername(Username)
	assert(self, "EXUNYS_AIMBOT-V3.Blacklist: User "..Username.." couldn't be found.")
	self.Blacklisted[#self.Blacklisted + 1] = Username
end)

Environment.Whitelist = LPH_NO_VIRTUALIZE(function(self, Username)
	assert(self, "EXUNYS_AIMBOT-V3.Whitelist: Missing parameter #1 \"self\" <table>.")
	assert(Username, "EXUNYS_AIMBOT-V3.Whitelist: Missing parameter #2 \"Username\" <string>.")
	Username = FixUsername(Username)
	assert(Username, "EXUNYS_AIMBOT-V3.Whitelist: User "..Username.." couldn't be found.")
	local Index = tablefind(self.Blacklisted, Username)
	assert(Index, "EXUNYS_AIMBOT-V3.Whitelist: User "..Username.." is not blacklisted.")
	tableremove(self.Blacklisted, Index)
end)

Environment.GetClosestPlayer = LPH_NO_VIRTUALIZE(function()
	return GetClosestPlayer(true)
end)

Environment.Load = Load
setmetatable(Environment, {__call = Load})

--// ============================================================================== //--
--// TEAM OUTLINE HIGHLIGHT
--// ============================================================================== //--

local Instancenew = Instance.new

local TeamOutlineHighlights, TeamOutlineConnections, TeamOutlineServiceConnections = {}, {}, {}
local TeamOutlineRaycastParams = RaycastParams.new()
local WorkspaceRaycast = __index(workspace, "Raycast")

TeamOutlineRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
TeamOutlineRaycastParams.IgnoreWater = true

-- [HELPER] Trả về true nếu Player là đồng đội của LocalPlayer (cùng Team khác nil)
local IsTeammate = LPH_NO_VIRTUALIZE(function(Player)
	local LocalTeam, PlayerTeam = __index(LocalPlayer, "Team"), __index(Player, "Team")
	return LocalTeam ~= nil and LocalTeam == PlayerTeam
end)

-- Trả về true nếu "Player" cần được highlight.
local IsTeamOutlineEnemy = LPH_NO_VIRTUALIZE(function(Player)
	if Player == LocalPlayer then
		return false
	end

	local EnemyHighlight = Environment.EnemyHighlight

	-- HighlightAll = true => highlight TẤT CẢ người chơi khác (kể cả đồng đội)
	if EnemyHighlight.HighlightAll then
		return true
	end

	if not EnemyHighlight.TeamCheck then
		return true
	end

	return not IsTeammate(Player)
end)

local GetTeamOutlinePart = LPH_NO_VIRTUALIZE(function(Character)
	return FindFirstChild(Character, "HumanoidRootPart") or FindFirstChild(Character, "Head")
end)

local IsTeamOutlineVisible = LPH_NO_VIRTUALIZE(function(Character, Part)
	if not Environment.EnemyHighlight.WallCheck then
		return true
	end

	local CurrentCamera = __index(workspace, "CurrentCamera")
	if not CurrentCamera then
		return false
	end

	local Origin = __index(CurrentCamera, "CFrame").Position
	local Direction = __index(Part, "Position") - Origin
	if Direction.Magnitude <= 0.001 then
		return true
	end

	local Blacklist = { Character }
	local LocalCharacter = __index(LocalPlayer, "Character")
	if LocalCharacter then
		Blacklist[#Blacklist + 1] = LocalCharacter
	end

	TeamOutlineRaycastParams.FilterDescendantsInstances = Blacklist
	return WorkspaceRaycast(workspace, Origin, Direction, TeamOutlineRaycastParams) == nil
end)

local CreateTeamOutline = LPH_NO_VIRTUALIZE(function(Player, Character)
	local EnemyHighlight = Environment.EnemyHighlight
	local Highlight = TeamOutlineHighlights[Player]

	if Highlight and __index(Highlight, "Parent") ~= Character then
		Highlight:Destroy()
		Highlight = nil
	end

	if not Highlight then
		Highlight = Instancenew("Highlight")
		Highlight.Name = "ExunysTeamOutline"
		Highlight.Parent = Character
		Highlight.OutlineColor = EnemyHighlight.OccludedColor
		TeamOutlineHighlights[Player] = Highlight
	end

	Highlight.DepthMode = EnemyHighlight.DepthMode
	Highlight.FillTransparency = EnemyHighlight.FillTransparency
	Highlight.OutlineTransparency = EnemyHighlight.OutlineTransparency

	return Highlight
end)

local RemoveTeamOutline = LPH_NO_VIRTUALIZE(function(Player)
	local Highlight = TeamOutlineHighlights[Player]
	if Highlight then
		TeamOutlineHighlights[Player] = nil
		pcall(Highlight.Destroy, Highlight)
	end
end)

local ClearTeamOutlines = LPH_NO_VIRTUALIZE(function()
	for Player, Highlight in next, TeamOutlineHighlights do
		TeamOutlineHighlights[Player] = nil
		pcall(Highlight.Destroy, Highlight)
	end
end)

-- Cập nhật Highlight + màu viền theo trạng thái nhìn thấy + loại (địch/đồng đội)
local RefreshTeamOutline = LPH_NO_VIRTUALIZE(function(Player)
	local EnemyHighlight = Environment.EnemyHighlight

	if not EnemyHighlight.Enabled or not IsTeamOutlineEnemy(Player) then
		RemoveTeamOutline(Player)
		return
	end

	local Character = __index(Player, "Character")
	local Humanoid = Character and FindFirstChildOfClass(Character, "Humanoid")
	local Part = Character and GetTeamOutlinePart(Character)

	if not Character or not Humanoid or not Part or (EnemyHighlight.AliveCheck and __index(Humanoid, "Health") <= 0) then
		RemoveTeamOutline(Player)
		return
	end

	local Highlight = CreateTeamOutline(Player, Character)

	-- [FIX] Chọn bảng màu theo loại: đồng đội (khi HighlightAll bật) hay địch
	local VisibleColor, OccludedColor

	if EnemyHighlight.HighlightAll and IsTeammate(Player) then
		-- Đồng đội: xanh lá (thấy) / xanh dương (bị che)
		VisibleColor = EnemyHighlight.TeammateVisibleColor
		OccludedColor = EnemyHighlight.TeammateOccludedColor
	else
		-- Địch: đỏ (thấy) / trắng (bị che)
		VisibleColor = EnemyHighlight.VisibleColor
		OccludedColor = EnemyHighlight.OccludedColor
	end

	local TargetColor = IsTeamOutlineVisible(Character, Part) and VisibleColor or OccludedColor

	if EnemyHighlight.Smoothing > 0 then
		Highlight.OutlineColor = Highlight.OutlineColor:Lerp(TargetColor, EnemyHighlight.Smoothing)
	else
		Highlight.OutlineColor = TargetColor
	end
end)

local UpdateTeamOutlines = LPH_NO_VIRTUALIZE(function()
	if not Environment.EnemyHighlight.Enabled then
		if next(TeamOutlineHighlights) ~= nil then
			ClearTeamOutlines()
		end
		return
	end

	for _, Player in next, GetPlayers(Players) do
		RefreshTeamOutline(Player)
	end

	for Player, _ in next, TeamOutlineHighlights do
		if __index(Player, "Parent") == nil then
			RemoveTeamOutline(Player)
		end
	end
end)

local DisconnectTeamOutlinePlayer = LPH_NO_VIRTUALIZE(function(Player)
	local Connections = TeamOutlineConnections[Player]
	if Connections then
		for Index, _ in next, Connections do
			pcall(Disconnect, Connections[Index])
		end
		TeamOutlineConnections[Player] = nil
	end
	RemoveTeamOutline(Player)
end)

local ConnectTeamOutlinePlayer = LPH_NO_VIRTUALIZE(function(Player)
	if Player == LocalPlayer or TeamOutlineConnections[Player] then
		return
	end

	TeamOutlineConnections[Player] = {
		CharacterAdded = Connect(__index(Player, "CharacterAdded"), LPH_NO_VIRTUALIZE(function()
			RefreshTeamOutline(Player)
		end)),
		CharacterRemoving = Connect(__index(Player, "CharacterRemoving"), LPH_NO_VIRTUALIZE(function()
			RemoveTeamOutline(Player)
		end))
	}

	RefreshTeamOutline(Player)
end)

local DestroyTeamOutlines = LPH_NO_VIRTUALIZE(function()
	for Player, _ in next, TeamOutlineConnections do
		DisconnectTeamOutlinePlayer(Player)
	end
	for Index, _ in next, TeamOutlineServiceConnections do
		pcall(Disconnect, TeamOutlineServiceConnections[Index])
		TeamOutlineServiceConnections[Index] = nil
	end
	ClearTeamOutlines()
end)

TeamOutlineServiceConnections.PlayerAdded = Connect(__index(Players, "PlayerAdded"), LPH_NO_VIRTUALIZE(function(Player)
	ConnectTeamOutlinePlayer(Player)
end))

TeamOutlineServiceConnections.PlayerRemoving = Connect(__index(Players, "PlayerRemoving"), LPH_NO_VIRTUALIZE(function(Player)
	DisconnectTeamOutlinePlayer(Player)
end))

TeamOutlineServiceConnections.Update = Connect(__index(RunService, Environment.DeveloperSettings.UpdateMode), LPH_NO_VIRTUALIZE(function()
	UpdateTeamOutlines()
end))

for _, Player in next, GetPlayers(Players) do
	ConnectTeamOutlinePlayer(Player)
end

Environment.ClearTeamOutlines = ClearTeamOutlines

local OriginalExit = Environment.Exit
Environment.Exit = LPH_NO_VIRTUALIZE(function(self, ...)
	DestroyTeamOutlines()
	return OriginalExit(self, ...)
end)

--// ================= GUI ================= //--

task.spawn(function()
	local CoreGui = cloneref(game:GetService("CoreGui"))
	local UIS = cloneref(game:GetService("UserInputService"))

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "ExunysSimpleAimbotGUI"
	ScreenGui.ResetOnSpawn = false

	if gethui then
		ScreenGui.Parent = gethui()
	elseif syn and syn.protect_gui then
		syn.protect_gui(ScreenGui)
		ScreenGui.Parent = CoreGui
	else
		local s = pcall(function() ScreenGui.Parent = CoreGui end)
		if not s then
			ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
		end
	end

	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Size = UDim2.new(0, 240, 0, 360)
	MainFrame.Position = UDim2.new(0, 50, 0, 50)
	MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	MainFrame.BorderSizePixel = 0
	MainFrame.Active = true
	MainFrame.Parent = ScreenGui

	local MainCorner = Instance.new("UICorner")
	MainCorner.CornerRadius = UDim.new(0, 8)
	MainCorner.Parent = MainFrame

	local Dragging, DragInput, DragStart, StartPos
	MainFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			Dragging = true
			DragStart = input.Position
			StartPos = MainFrame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					Dragging = false
				end
			end)
		end
	end)
	MainFrame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			DragInput = input
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if input == DragInput and Dragging then
			local Delta = input.Position - DragStart
			MainFrame.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)
		end
	end)

	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, 0, 0, 32)
	Title.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
	Title.BorderSizePixel = 0
	Title.Text = "  Aimbot Settings [Insert]"
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.TextSize = 13
	Title.Font = Enum.Font.SourceSansBold
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Parent = MainFrame

	local TitleCorner = Instance.new("UICorner")
	TitleCorner.CornerRadius = UDim.new(0, 8)
	TitleCorner.Parent = Title

	local List = Instance.new("Frame")
	List.Size = UDim2.new(1, -16, 1, -42)
	List.Position = UDim2.new(0, 8, 0, 38)
	List.BackgroundTransparency = 1
	List.Parent = MainFrame

	local Layout = Instance.new("UIListLayout")
	Layout.Padding = UDim.new(0, 5)
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Parent = List

	local function CreateToggle(name, defaultVal, callback)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 28)
		btn.BackgroundColor3 = defaultVal and Color3.fromRGB(45, 120, 60) or Color3.fromRGB(60, 60, 65)
		btn.Text = name .. ": " .. (defaultVal and "ON" or "OFF")
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Font = Enum.Font.SourceSansSemibold
		btn.TextSize = 13
		btn.BorderSizePixel = 0
		btn.Parent = List

		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 5)
		c.Parent = btn

		local state = defaultVal
		btn.MouseButton1Click:Connect(function()
			state = not state
			btn.BackgroundColor3 = state and Color3.fromRGB(45, 120, 60) or Color3.fromRGB(60, 60, 65)
			btn.Text = name .. ": " .. (state and "ON" or "OFF")
			callback(state)
		end)
	end

	local function CreateInput(name, defaultVal, callback)
		local f = Instance.new("Frame")
		f.Size = UDim2.new(1, 0, 0, 28)
		f.BackgroundTransparency = 1
		f.Parent = List

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(0.65, 0, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = "  " .. name
		lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
		lbl.Font = Enum.Font.SourceSans
		lbl.TextSize = 13
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Parent = f

		local box = Instance.new("TextBox")
		box.Size = UDim2.new(0.35, 0, 1, 0)
		box.Position = UDim2.new(0.65, 0, 0, 0)
		box.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
		box.Text = tostring(defaultVal)
		box.TextColor3 = Color3.fromRGB(255, 255, 255)
		box.Font = Enum.Font.SourceSansBold
		box.TextSize = 13
		box.BorderSizePixel = 0
		box.Parent = f

		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 5)
		c.Parent = box

		box.FocusLost:Connect(function()
			local num = tonumber(box.Text)
			if num then
				callback(num)
			else
				box.Text = tostring(defaultVal)
			end
		end)
	end

	CreateToggle("Aimbot", Environment.Settings.Enabled, function(val)
		Environment.Settings.Enabled = val
	end)

	CreateToggle("Team Check", Environment.Settings.TeamCheck, function(val)
		Environment.Settings.TeamCheck = val
	end)

	CreateToggle("Wall Check", Environment.Settings.WallCheck, function(val)
		Environment.Settings.WallCheck = val
	end)

	CreateToggle("Team Outline", Environment.EnemyHighlight.Enabled, function(val)
		Environment.EnemyHighlight.Enabled = val
		if not val then
			Environment.ClearTeamOutlines()
		end
	end)

	-- ON = highlight TẤT CẢ (đồng đội = xanh, địch = đỏ); OFF = chỉ địch
	CreateToggle("Highlight Teammates", Environment.EnemyHighlight.HighlightAll, function(val)
		Environment.EnemyHighlight.HighlightAll = val
	end)

	CreateToggle("FOV Circle", Environment.FOVSettings.Visible, function(val)
		Environment.FOVSettings.Visible = val
	end)

	CreateInput("FOV Radius", Environment.FOVSettings.Radius, function(num)
		Environment.FOVSettings.Radius = num
	end)

	CreateInput("Sensitivity", Environment.Settings.Sensitivity, function(num)
		Environment.Settings.Sensitivity = num
	end)

	local parts = {"Head", "UpperTorso", "HumanoidRootPart"}
	local currentPartIdx = 1
	for idx, p in ipairs(parts) do
		if p == Environment.Settings.LockPart then
			currentPartIdx = idx
			break
		end
	end

	local partBtn = Instance.new("TextButton")
	partBtn.Size = UDim2.new(1, 0, 0, 28)
	partBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
	partBtn.Text = "Target Part: " .. Environment.Settings.LockPart
	partBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	partBtn.Font = Enum.Font.SourceSansSemibold
	partBtn.TextSize = 13
	partBtn.BorderSizePixel = 0
	partBtn.Parent = List

	local partCorner = Instance.new("UICorner")
	partCorner.CornerRadius = UDim.new(0, 5)
	partCorner.Parent = partBtn

	partBtn.MouseButton1Click:Connect(function()
		currentPartIdx = (currentPartIdx % #parts) + 1
		local nextPart = parts[currentPartIdx]
		Environment.Settings.LockPart = nextPart
		partBtn.Text = "Target Part: " .. nextPart
	end)

	UIS.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Insert then
			MainFrame.Visible = not MainFrame.Visible
		end
	end)
end)

return Environment