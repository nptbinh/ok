--[[

	Universal Aimbot Module by Exunys © CC0 1.0 Universal (2023)

	https://github.com/Exunys

]]

-- Luraph macro: 'LPH_NO_VIRTUALIZE' không gán được nếu LPH_OBFUSCATED đã set, nên phải check nil trước.
if LPH_OBFUSCATED == nil then
	LPH_NO_VIRTUALIZE = function(...)
		return ...
	end
end

-- Cache global để tránh bị hook bởi anti-cheat của executor khác
local game, workspace = game, workspace
local getrawmetatable, pcall, next, tick, getgenv = getrawmetatable, pcall, next, tick, getgenv
local Vector2new, Vector3zero, Vector3new, CFramenew, Color3fromRGB, Color3fromHSV, Drawingnew, TweenInfonew = Vector2.new, Vector3.zero, Vector3.new, CFrame.new, Color3.fromRGB, Color3.fromHSV, Drawing and Drawing.new, TweenInfo.new
local mousemoverel, mousemoveabs, tablefind, tableremove, stringlower, stringsub, mathclamp, mathfloor = mousemoverel or (Input and Input.MouseMove), mousemoveabs, table.find, table.remove, string.lower, string.sub, math.clamp, math.floor
local mouse1press, mouse1release, mouse1click, taskwait = mouse1press, mouse1release, mouse1click, task.wait
local clonefunction, cloneref = clonefunction or function(...) return ... end, cloneref or function(...) return ... end

local GameMetatable = getrawmetatable and getrawmetatable(game) or {
	__index = function(self, Index)
		return self[Index]
	end,
	__newindex = function(self, Index, Value)
		self[Index] = Value
	end
}

local __index = GameMetatable.__index
local __newindex = GameMetatable.__newindex

local getrenderproperty, setrenderproperty = getrenderproperty or __index, setrenderproperty or __newindex

local _GetService = __index(game, "GetService")
local GetService = function(Service)
	return cloneref(_GetService(game, Service))
end

local RunService = GetService("RunService")
local UserInputService = GetService("UserInputService")
local TweenService = GetService("TweenService")
local Players = GetService("Players")

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

local RequiredDistance, Typing, Running, ServiceConnections, Animation, OriginalSensitivity = 2000, false, false, {}, nil, nil
local Connect, Disconnect = __index(game, "DescendantAdded").Connect

do
	local TemporaryConnection = Connect(__index(game, "DescendantAdded"), function() end)
	Disconnect = TemporaryConnection.Disconnect
	Disconnect(TemporaryConnection)
end

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

		-- Đón đầu: bật/tắt và độ lớn (1-30, scale/10 studs)
		OffsetToMoveDirection = false,
		OffsetIncrement = 15,

		-- Sensitivity chỉ áp dụng cho LockMode = 1 (CFrame tween). 0 = snap tức thời.
		Sensitivity = 0.2,
		-- Sensitivity2 chia delta chuột cho LockMode = 2 (mousemoverel).
		Sensitivity2 = 1,

		-- 1 = tween Camera.CFrame; 2 = mousemoverel; 3 = mousemoveabs
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
		-- 1 = từ đáy màn hình; 2 = từ tâm màn hình; 3 = từ vị trí chuột
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

	EnemyHighlight = {
		Enabled = true,

		-- true = highlight TẤT CẢ người chơi khác (kể cả đồng đội); false = chỉ người khác team
		HighlightAll = false,

		TeamCheck = true,
		AliveCheck = true,
		WallCheck = true,

		FillTransparency = 1,
		OutlineTransparency = 0,
		DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
		Smoothing = 0.35,

		-- Màu kẻ địch: bị che / nhìn thấy
		OccludedColor = Color3fromRGB(255, 255, 255),
		VisibleColor = Color3fromRGB(255, 0, 0),

		-- Màu đồng đội (chỉ dùng khi HighlightAll bật): bị che / nhìn thấy
		TeammateOccludedColor = Color3fromRGB(0, 150, 255),
		TeammateVisibleColor = Color3fromRGB(0, 255, 0),

		-- Kích thước chữ NameTag (tên + HP) hiển thị trên đầu mục tiêu
		NameTagSize = 14,
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

local FixUsername = function(String)
	for _, Value in next, GetPlayers(Players) do
		local Name = __index(Value, "Name")
		if stringsub(stringlower(Name), 1, #String) == stringlower(String) then
			return Name
		end
	end
end

local GetRainbowColor = function()
	local RainbowSpeed = Environment.DeveloperSettings.RainbowSpeed
	return Color3fromHSV(tick() % RainbowSpeed / RainbowSpeed, 1, 1)
end

local ConvertVector = function(Vector)
	return Vector2new(Vector.X, Vector.Y)
end

-- Resolve LockPart với fallback R6 ↔ R15:
--   "UpperTorso" không có (R6) → dùng "Torso"
--   "Torso" không có (R15)      → dùng "UpperTorso"
--   "Head" / "HumanoidRootPart" → luôn tồn tại
local GetLockPartInstance = function(Character, WantedPart)
	if not Character then return nil end
	local Part = FindFirstChild(Character, WantedPart)
	if Part then return Part end
	if WantedPart == "UpperTorso" then
		return FindFirstChild(Character, "Torso")
	elseif WantedPart == "Torso" then
		return FindFirstChild(Character, "UpperTorso")
	end
	return nil
end

local CancelLock = function()
	Environment.Locked = nil
	setrenderproperty(Environment.FOVCircle, "Color", Environment.FOVSettings.Color)
	__newindex(UserInputService, "MouseDeltaSensitivity", OriginalSensitivity)
	if Animation then
		Animation:Cancel()
	end
	setrenderproperty(Environment.Tracer, "Visible", Environment.ClosestPlayerTracer.Enabled)
end

local GetClosestPlayer = function(Aux)
	local Settings = Environment.Settings
	local LockPart = Settings.LockPart

	if not Environment.Locked or Aux then
		RequiredDistance = Environment.FOVSettings.Enabled and Environment.FOVSettings.Radius or 2000
		Required3DDistance = 10000

		for _, Value in next, GetPlayers(Players) do
			local Character = __index(Value, "Character")
			local Humanoid = Character and FindFirstChildOfClass(Character, "Humanoid")
			local TargetPart = Character and GetLockPartInstance(Character, LockPart)

			if Value ~= LocalPlayer and not tablefind(Environment.Blacklisted, __index(Value, "Name")) and Character and TargetPart and Humanoid then
				local PartPosition, TeamCheckOption = __index(TargetPart, "Position"), Environment.DeveloperSettings.TeamCheckOption

				if Settings.TeamCheck and __index(Value, TeamCheckOption) == __index(LocalPlayer, TeamCheckOption) then
					continue
				end

				if Settings.AliveCheck and __index(Humanoid, "Health") <= 0 then
					continue
				end

				-- WallCheck: raycast từ Camera tới LockPart, blacklist nhân vật của mình + mục tiêu
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
	else
		-- Kiểm tra mục tiêu đang lock: nếu part biến mất hoặc ra khỏi FOV → hủy lock
		local LockedCharacter = __index(Environment.Locked, "Character")
		local LockedPart = GetLockPartInstance(LockedCharacter, LockPart)

		if not LockedPart then
			CancelLock()
		elseif (GetMouseLocation(UserInputService) - ConvertVector(WorldToViewportPoint(Camera, __index(LockedPart, "Position")))).Magnitude > RequiredDistance then
			CancelLock()
		end
	end
end

local Load = function()
	OriginalSensitivity = __index(UserInputService, "MouseDeltaSensitivity")

	local Settings, Triggerbot, Tracer, FOVCircle, FOVCircleOutline, TracerSettings, FOVSettings, Offset = Environment.Settings, Environment.Triggerbot, Environment.Tracer, Environment.FOVCircle, Environment.FOVCircleOutline, Environment.ClosestPlayerTracer, Environment.FOVSettings

	local DeveloperSettings = Environment.DeveloperSettings
	local UpdateMode = DeveloperSettings.UpdateMode
	local TeamCheckOption = DeveloperSettings.TeamCheckOption

	-- Tracer chỉ cần ~20Hz, không cần 60fps như aim lock. Giảm tải GetClosestPlayer(true) mỗi frame.
	local TRACER_INTERVAL = 0.05
	local LastTracerUpdate = 0

	if mouse1press and mouse1release then
		ServiceConnections.Triggerbot = Connect(__index(RunService, UpdateMode), function()
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
		end)
	end

	ServiceConnections.UpdateTracer = Connect(__index(RunService, UpdateMode), function()
		local Now = tick()
		if Now - LastTracerUpdate < TRACER_INTERVAL then return end
		LastTracerUpdate = Now

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

			local TracerTarget = GetLockPartInstance(__index(ClosestPlayer, "Character"), Settings.LockPart)
			if TracerTarget then
				setrenderproperty(Tracer, "To", ConvertVector(WorldToViewportPoint(Camera, __index(TracerTarget, "Position"))))
			else
				setrenderproperty(Tracer, "Visible", false)
			end
		else
			setrenderproperty(Tracer, "Visible", false)
		end
	end)

	ServiceConnections.RenderSteppedConnection = Connect(__index(RunService, UpdateMode), function()
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

			-- Đọc Settings.OffsetToMoveDirection/OffsetIncrement ĐỘNG mỗi frame — chỉnh GUI áp dụng ngay
			local LockedCharacter = Environment.Locked and __index(Environment.Locked, "Character")
			local AimPart = LockedCharacter and GetLockPartInstance(LockedCharacter, Settings.LockPart)

			if AimPart then
				if Settings.OffsetToMoveDirection and LockedCharacter then
					local LockedHumanoid = FindFirstChildOfClass(LockedCharacter, "Humanoid")
					Offset = LockedHumanoid and (__index(LockedHumanoid, "MoveDirection") * (mathclamp(Settings.OffsetIncrement, 1, 30) / 10)) or Vector3zero
				else
					Offset = Vector3zero
				end

				local LockedPosition_Vector3 = __index(AimPart, "Position")
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
	end)

	ServiceConnections.InputBeganConnection = Connect(__index(UserInputService, "InputBegan"), function(Input)
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
	end)

	ServiceConnections.InputEndedConnection = Connect(__index(UserInputService, "InputEnded"), function(Input)
		if Typing then return end
		local TriggerKey = Settings.TriggerKey
		if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode == TriggerKey or Input.UserInputType == TriggerKey then
			Running = false; CancelLock()
		end
	end)
end

-- Không chạy aimbot / hotkey khi đang gõ chat hoặc textbox
ServiceConnections.TypingStartedConnection = Connect(__index(UserInputService, "TextBoxFocused"), function()
	Typing = true
end)

ServiceConnections.TypingEndedConnection = Connect(__index(UserInputService, "TextBoxFocusReleased"), function()
	Typing = false
end)

repeat
	taskwait(0)
until Environment and Load

Environment.Exit = function(self)
	assert(self, "EXUNYS_AIMBOT-V3.Exit: Missing parameter #1 \"self\" <table>.")
	for Index, _ in next, ServiceConnections do
		pcall(Disconnect, ServiceConnections[Index])
	end
	Load = nil; ConvertVector = nil; CancelLock = nil; GetClosestPlayer = nil; GetRainbowColor = nil; FixUsername = nil
	self.FOVCircle:Remove()
	self.FOVCircleOutline:Remove()
	self.Tracer:Remove()
	getgenv().ExunysDeveloperAimbot = nil; pcall(collectgarbage, "step", 200)
end

Environment.Restart = function()
	for Index, _ in next, ServiceConnections do
		pcall(Disconnect, ServiceConnections[Index])
	end
	Load()
end

Environment.Blacklist = function(self, Username)
	assert(self, "EXUNYS_AIMBOT-V3.Blacklist: Missing parameter #1 \"self\" <table>.")
	assert(Username, "EXUNYS_AIMBOT-V3.Blacklist: Missing parameter #2 \"Username\" <string>.")
	Username = FixUsername(Username)
	assert(self, "EXUNYS_AIMBOT-V3.Blacklist: User "..Username.." couldn't be found.")
	self.Blacklisted[#self.Blacklisted + 1] = Username
end

Environment.Whitelist = function(self, Username)
	assert(self, "EXUNYS_AIMBOT-V3.Whitelist: Missing parameter #1 \"self\" <table>.")
	assert(Username, "EXUNYS_AIMBOT-V3.Whitelist: Missing parameter #2 \"Username\" <string>.")
	Username = FixUsername(Username)
	assert(Username, "EXUNYS_AIMBOT-V3.Whitelist: User "..Username.." couldn't be found.")
	local Index = tablefind(self.Blacklisted, Username)
	assert(Index, "EXUNYS_AIMBOT-V3.Whitelist: User "..Username.." is not blacklisted.")
	tableremove(self.Blacklisted, Index)
end

Environment.GetClosestPlayer = function()
	return GetClosestPlayer(true)
end

Environment.Load = Load
setmetatable(Environment, {__call = Load})

-- ===== Persistence: lưu setting + keybind ra file, load lại khi execute =====
local HttpService = GetService("HttpService")
local CONFIG_FOLDER = "ExunysAimbot"
local CONFIG_FILE = CONFIG_FOLDER .. "/config.json"
local CurrentGuiKeybind = Enum.KeyCode.Insert

local function FileApiAvailable()
	return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
end

local function SaveConfig()
	if not FileApiAvailable() then return end

	if type(makefolder) == "function" and type(isfolder) == "function" then
		pcall(function()
			if not isfolder(CONFIG_FOLDER) then
				makefolder(CONFIG_FOLDER)
			end
		end)
	end

	local data = {
		GuiKeybind = (tostring(CurrentGuiKeybind):gsub("Enum.KeyCode.", "")),
		Settings = {
			Enabled = Environment.Settings.Enabled,
			TeamCheck = Environment.Settings.TeamCheck,
			WallCheck = Environment.Settings.WallCheck,
			Sensitivity = Environment.Settings.Sensitivity,
			LockPart = Environment.Settings.LockPart,
			OffsetToMoveDirection = Environment.Settings.OffsetToMoveDirection,
			OffsetIncrement = Environment.Settings.OffsetIncrement,
		},
		FOVSettings = {
			Visible = Environment.FOVSettings.Visible,
			Radius = Environment.FOVSettings.Radius,
		},
		EnemyHighlight = {
			Enabled = Environment.EnemyHighlight.Enabled,
			HighlightAll = Environment.EnemyHighlight.HighlightAll,
			WallCheck = Environment.EnemyHighlight.WallCheck,
			NameTagSize = Environment.EnemyHighlight.NameTagSize,
		},
	}

	local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
	if ok and encoded then
		pcall(writefile, CONFIG_FILE, encoded)
	end
end

local function LoadConfig()
	if not FileApiAvailable() then return end

	local exists = false
	pcall(function() exists = isfile(CONFIG_FILE) end)
	if not exists then return end

	local ok, content = pcall(readfile, CONFIG_FILE)
	if not ok or type(content) ~= "string" or content == "" then return end

	local ok2, decoded = pcall(function() return HttpService:JSONDecode(content) end)
	if not ok2 or type(decoded) ~= "table" then return end

	if type(decoded.GuiKeybind) == "string" then
		local kc = Enum.KeyCode[decoded.GuiKeybind]
		if kc and kc ~= Enum.KeyCode.Unknown then
			CurrentGuiKeybind = kc
		end
	end

	if type(decoded.Settings) == "table" then
		for k, v in pairs(decoded.Settings) do
			if Environment.Settings[k] ~= nil then
				Environment.Settings[k] = v
			end
		end
	end

	if type(decoded.FOVSettings) == "table" then
		for k, v in pairs(decoded.FOVSettings) do
			if Environment.FOVSettings[k] ~= nil then
				Environment.FOVSettings[k] = v
			end
		end
	end

	if type(decoded.EnemyHighlight) == "table" then
		for k, v in pairs(decoded.EnemyHighlight) do
			if Environment.EnemyHighlight[k] ~= nil then
				Environment.EnemyHighlight[k] = v
			end
		end
	end
end

LoadConfig()

-- ===== Team Outline Highlight: 1 Highlight gắn lên từng BasePart của Character =====

local Instancenew = Instance.new

local TeamOutlineHighlights, TeamOutlineConnections, TeamOutlineServiceConnections = {}, {}, {}
local TeamOutlineNameTags = {}
local TeamOutlineRaycastParams = RaycastParams.new()
local WorkspaceRaycast = __index(workspace, "Raycast")

TeamOutlineRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
TeamOutlineRaycastParams.IgnoreWater = true
-- Bỏ qua part CanCollide=false (cỏ, lá, hiệu ứng) để không tính là vật cản che tầm nhìn
TeamOutlineRaycastParams.RespectCanCollide = true

-- Raycast visibility chỉ cần 20Hz, giữa các lần update thì lerp màu mượt theo frame
local VISIBILITY_UPDATE_INTERVAL = 0.05
local LastVisibilityUpdate = 0

-- Cache player list, refresh qua PlayerAdded/PlayerRemoving thay vì gọi GetPlayers() mỗi frame
local CachedPlayers = {}
local function RefreshCachedPlayers()
	CachedPlayers = GetPlayers(Players)
end
RefreshCachedPlayers()

local IsTeammate = function(Player)
	local LocalTeam, PlayerTeam = __index(LocalPlayer, "Team"), __index(Player, "Team")
	return LocalTeam ~= nil and LocalTeam == PlayerTeam
end

local IsTeamOutlineEnemy = function(Player)
	if Player == LocalPlayer then return false end
	local EnemyHighlight = Environment.EnemyHighlight
	if EnemyHighlight.HighlightAll then return true end
	if not EnemyHighlight.TeamCheck then return true end
	return not IsTeammate(Player)
end

-- Lấy tất cả BasePart trực tiếp của Character, trừ HumanoidRootPart (thân ẩn, không cần viền)
local GetOutlineParts = function(Character)
	local Parts = {}
	for _, Child in next, Character:GetChildren() do
		if Child:IsA("BasePart") and Child.Name ~= "HumanoidRootPart" then
			Parts[#Parts + 1] = Child
		end
	end
	return Parts
end

-- Raycast từ Camera tới tâm Part. Trả về true nếu không bị chặn (nhìn thấy trực tiếp).
local IsPartVisible = function(Part, Blacklist)
	local CurrentCamera = __index(workspace, "CurrentCamera")
	if not CurrentCamera then return false end
	local Origin = __index(CurrentCamera, "CFrame").Position
	local Direction = __index(Part, "Position") - Origin
	if Direction.Magnitude <= 0.001 then return true end
	TeamOutlineRaycastParams.FilterDescendantsInstances = Blacklist
	return WorkspaceRaycast(workspace, Origin, Direction, TeamOutlineRaycastParams) == nil
end

local CreatePartHighlight = function(Part, EnemyHighlight)
	local Highlight = Instancenew("Highlight")
	Highlight.Name = "ExunysTeamOutlinePart"
	Highlight.Parent = Part
	Highlight.DepthMode = EnemyHighlight.DepthMode
	Highlight.FillTransparency = EnemyHighlight.FillTransparency
	Highlight.OutlineTransparency = EnemyHighlight.OutlineTransparency
	Highlight.OutlineColor = EnemyHighlight.OccludedColor
	return Highlight
end

-- NameTag = Drawing Text hiển thị "Tên [HP]" trên đầu player. Tạo lazily, tái sử dụng.
local GetNameTag = function(Player)
	local Tag = TeamOutlineNameTags[Player]
	if not Tag then
		local ok, NewTag = pcall(Drawingnew, "Text")
		if not ok or not NewTag then return nil end
		Tag = NewTag
		Tag.Center = true
		Tag.Outline = true
		Tag.OutlineColor = Color3fromRGB(0, 0, 0)
		Tag.Font = 2 -- SourceSansBold
		Tag.Visible = false
		TeamOutlineNameTags[Player] = Tag
	end
	return Tag
end

local RemoveNameTag = function(Player)
	local Tag = TeamOutlineNameTags[Player]
	if Tag then
		TeamOutlineNameTags[Player] = nil
		pcall(Tag.Remove, Tag)
	end
end

local RemoveTeamOutline = function(Player)
	local Data = TeamOutlineHighlights[Player]
	if Data then
		for _, Highlight in next, Data.Highlights do
			pcall(Highlight.Destroy, Highlight)
		end
		TeamOutlineHighlights[Player] = nil
	end
	-- NameTag luôn đi chung với highlight: tắt highlight = tắt luôn tên
	RemoveNameTag(Player)
end

local ClearTeamOutlines = function()
	for Player, _ in next, TeamOutlineHighlights do
		RemoveTeamOutline(Player)
	end
	-- Defensive: dọn tag mồ côi (nếu có) — chủ yếu an toàn khi Exit giữa chừng
	for Player, Tag in next, TeamOutlineNameTags do
		TeamOutlineNameTags[Player] = nil
		pcall(Tag.Remove, Tag)
	end
end

-- DoVisibility = true => tính lại raycast từng part; false => chỉ lerp màu giữa 2 lần raycast
local RefreshTeamOutline = function(Player, DoVisibility)
	local EnemyHighlight = Environment.EnemyHighlight

	if not EnemyHighlight.Enabled or not IsTeamOutlineEnemy(Player) then
		RemoveTeamOutline(Player)
		return
	end

	local Character = __index(Player, "Character")
	local Humanoid = Character and FindFirstChildOfClass(Character, "Humanoid")

	if not Character or not Humanoid or (EnemyHighlight.AliveCheck and __index(Humanoid, "Health") <= 0) then
		RemoveTeamOutline(Player)
		return
	end

	local Data = TeamOutlineHighlights[Player]
	if not Data or Data.Character ~= Character then
		RemoveTeamOutline(Player)
		Data = {
			Character = Character,
			Parts = GetOutlineParts(Character),
			Highlights = {},
			Targets = {},
		}
		for _, Part in next, Data.Parts do
			Data.Highlights[Part] = CreatePartHighlight(Part, EnemyHighlight)
			Data.Targets[Part] = EnemyHighlight.OccludedColor
		end
		TeamOutlineHighlights[Player] = Data
	end

	local VisibleColor, OccludedColor
	if EnemyHighlight.HighlightAll and IsTeammate(Player) then
		VisibleColor = EnemyHighlight.TeammateVisibleColor
		OccludedColor = EnemyHighlight.TeammateOccludedColor
	else
		VisibleColor = EnemyHighlight.VisibleColor
		OccludedColor = EnemyHighlight.OccludedColor
	end

	if DoVisibility then
		local CurrentParts = GetOutlineParts(Character)
		local CurrentSet = {}
		for _, Part in next, CurrentParts do
			CurrentSet[Part] = true
			if not Data.Highlights[Part] then
				Data.Highlights[Part] = CreatePartHighlight(Part, EnemyHighlight)
				Data.Targets[Part] = OccludedColor
			end
		end
		for Part, Highlight in next, Data.Highlights do
			if not CurrentSet[Part] then
				pcall(Highlight.Destroy, Highlight)
				Data.Highlights[Part] = nil
				Data.Targets[Part] = nil
			end
		end
		Data.Parts = CurrentParts

		for _, Highlight in next, Data.Highlights do
			Highlight.DepthMode = EnemyHighlight.DepthMode
			Highlight.FillTransparency = EnemyHighlight.FillTransparency
			Highlight.OutlineTransparency = EnemyHighlight.OutlineTransparency
		end

		if not EnemyHighlight.WallCheck then
			for _, Part in next, CurrentParts do
				Data.Targets[Part] = VisibleColor
			end
		else
			local Blacklist = { Character }
			local LocalCharacter = __index(LocalPlayer, "Character")
			if LocalCharacter then
				Blacklist[#Blacklist + 1] = LocalCharacter
			end
			for _, Part in next, CurrentParts do
				-- Cull off-screen trước khi raycast: part ngoài màn hình hoặc sau Camera thì bỏ qua
				local ScreenPos, OnScreen = WorldToViewportPoint(Camera, Part.Position)
				if not OnScreen or ScreenPos.Z <= 0 then
					Data.Targets[Part] = OccludedColor
				else
					Data.Targets[Part] = IsPartVisible(Part, Blacklist) and VisibleColor or OccludedColor
				end
			end
		end
	end

	-- Lerp màu mỗi frame; skip phép lerp nếu màu đã gần target (<1% khác biệt)
	local Smoothing = EnemyHighlight.Smoothing
	for Part, Highlight in next, Data.Highlights do
		local Target = Data.Targets[Part] or OccludedColor
		local Current = Highlight.OutlineColor
		local Diff = math.abs(Current.R - Target.R) + math.abs(Current.G - Target.G) + math.abs(Current.B - Target.B)
		if Diff < 0.01 then
			if Diff > 0 then
				Highlight.OutlineColor = Target
			end
		elseif Smoothing > 0 then
			Highlight.OutlineColor = Current:Lerp(Target, Smoothing)
		else
			Highlight.OutlineColor = Target
		end
	end

	-- NameTag: hiện tên + HP hiện tại, bám theo đầu player, tô màu theo màu đầu (visible/occluded)
	local NameTag = GetNameTag(Player)
	if NameTag then
		local HeadPart = FindFirstChild(Character, "Head") or FindFirstChild(Character, "HumanoidRootPart")
		if HeadPart then
			local HeadScreenPos, HeadOnScreen = WorldToViewportPoint(Camera, HeadPart.Position + Vector3new(0, 2.5, 0))
			if HeadOnScreen and HeadScreenPos.Z > 0 then
				NameTag.Visible = true
				NameTag.Position = Vector2new(HeadScreenPos.X, HeadScreenPos.Y)
				NameTag.Text = string.format("%s [%d]", __index(Player, "Name"), mathfloor(__index(Humanoid, "Health")))
				NameTag.Size = EnemyHighlight.NameTagSize

				local HeadHighlight = Data.Highlights[HeadPart]
				NameTag.Color = (HeadHighlight and HeadHighlight.OutlineColor) or VisibleColor
			else
				NameTag.Visible = false
			end
		else
			NameTag.Visible = false
		end
	end
end

local UpdateTeamOutlines = function()
	if not Environment.EnemyHighlight.Enabled then
		if next(TeamOutlineHighlights) ~= nil then
			ClearTeamOutlines()
		end
		return
	end

	local Now = tick()
	local DoVisibility = (Now - LastVisibilityUpdate) >= VISIBILITY_UPDATE_INTERVAL
	if DoVisibility then
		LastVisibilityUpdate = Now
	end

	for _, Player in next, CachedPlayers do
		RefreshTeamOutline(Player, DoVisibility)
	end

	for Player, _ in next, TeamOutlineHighlights do
		if __index(Player, "Parent") == nil then
			RemoveTeamOutline(Player)
		end
	end
end

local DisconnectTeamOutlinePlayer = function(Player)
	local Connections = TeamOutlineConnections[Player]
	if Connections then
		for Index, _ in next, Connections do
			pcall(Disconnect, Connections[Index])
		end
		TeamOutlineConnections[Player] = nil
	end
	RemoveTeamOutline(Player)
end

local ConnectTeamOutlinePlayer = function(Player)
	if Player == LocalPlayer or TeamOutlineConnections[Player] then
		return
	end

	TeamOutlineConnections[Player] = {
		CharacterAdded = Connect(__index(Player, "CharacterAdded"), function()
			RefreshTeamOutline(Player, true)
		end),
		CharacterRemoving = Connect(__index(Player, "CharacterRemoving"), function()
			RemoveTeamOutline(Player)
		end)
	}

	RefreshTeamOutline(Player, true)
end

local DestroyTeamOutlines = function()
	for Player, _ in next, TeamOutlineConnections do
		DisconnectTeamOutlinePlayer(Player)
	end
	for Index, _ in next, TeamOutlineServiceConnections do
		pcall(Disconnect, TeamOutlineServiceConnections[Index])
		TeamOutlineServiceConnections[Index] = nil
	end
	ClearTeamOutlines()
end

TeamOutlineServiceConnections.PlayerAdded_Cache = Connect(__index(Players, "PlayerAdded"), function(Player)
	RefreshCachedPlayers()
	ConnectTeamOutlinePlayer(Player)
end)

TeamOutlineServiceConnections.PlayerRemoving_Cache = Connect(__index(Players, "PlayerRemoving"), function(Player)
	-- defer để Player thực sự rời khỏi Players trước khi refresh cache
	task.defer(RefreshCachedPlayers)
	DisconnectTeamOutlinePlayer(Player)
end)

TeamOutlineServiceConnections.Update = Connect(__index(RunService, Environment.DeveloperSettings.UpdateMode), function()
	UpdateTeamOutlines()
end)

for _, Player in next, CachedPlayers do
	ConnectTeamOutlinePlayer(Player)
end

Environment.ClearTeamOutlines = ClearTeamOutlines

local OriginalExit = Environment.Exit
Environment.Exit = function(self, ...)
	SaveConfig()
	DestroyTeamOutlines()
	return OriginalExit(self, ...)
end

-- ===== GUI =====

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

	-- Keybind ẩn/hiện GUI — nạp từ file config, fallback Insert nếu chưa có
	local GuiKeybind = CurrentGuiKeybind
	local ListeningForKey = false

	local function KeyName(KeyCode)
		if not KeyCode then return "None" end
		return (tostring(KeyCode):gsub("Enum.KeyCode.", ""))
	end

	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Size = UDim2.new(0, 240, 0, 620)
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
	Title.Text = "  Exunys Aimbot + ESP"
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

	local function CreateSectionHeader(text)
		local header = Instance.new("TextLabel")
		header.Size = UDim2.new(1, 0, 0, 22)
		header.BackgroundTransparency = 1
		header.Text = "— " .. text .. " —"
		header.TextColor3 = Color3.fromRGB(130, 170, 255)
		header.Font = Enum.Font.SourceSansBold
		header.TextSize = 12
		header.TextXAlignment = Enum.TextXAlignment.Left
		header.Parent = List
		return header
	end

	local function CreateToggle(name, defaultVal, callback)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 28)
		btn.BackgroundColor3 = defaultVal and Color3.fromRGB(45, 120, 60) or Color3.fromRGB(60, 60, 65)
		btn.Text = "  " .. name .. ": " .. (defaultVal and "ON" or "OFF")
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Font = Enum.Font.SourceSansSemibold
		btn.TextSize = 13
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.BorderSizePixel = 0
		btn.Parent = List

		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 5)
		c.Parent = btn

		local state = defaultVal
		btn.MouseButton1Click:Connect(function()
			state = not state
			btn.BackgroundColor3 = state and Color3.fromRGB(45, 120, 60) or Color3.fromRGB(60, 60, 65)
			btn.Text = "  " .. name .. ": " .. (state and "ON" or "OFF")
			callback(state)
			SaveConfig()
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
				SaveConfig()
			else
				box.Text = tostring(defaultVal)
			end
		end)
	end

	-- ===== AIMBOT =====
	CreateSectionHeader("AIMBOT")

	CreateToggle("Aimbot", Environment.Settings.Enabled, function(val)
		Environment.Settings.Enabled = val
	end)

	CreateToggle("Team Check", Environment.Settings.TeamCheck, function(val)
		Environment.Settings.TeamCheck = val
	end)

	CreateToggle("Wall Check", Environment.Settings.WallCheck, function(val)
		Environment.Settings.WallCheck = val
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

	-- Đón đầu: toggle + input, áp dụng real-time qua Settings động trong aim block
	CreateToggle("Aim Prediction", Environment.Settings.OffsetToMoveDirection, function(val)
		Environment.Settings.OffsetToMoveDirection = val
	end)

	CreateInput("Prediction Strength", Environment.Settings.OffsetIncrement, function(num)
		Environment.Settings.OffsetIncrement = mathclamp(mathfloor(num), 1, 30)
	end)

	do
		-- Thêm "Torso" cho R6 + giữ "UpperTorso" cho R15; helper tự fallback
		local parts = {"Head", "UpperTorso", "Torso", "HumanoidRootPart"}
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
		partBtn.Text = "  Target Part: " .. Environment.Settings.LockPart
		partBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		partBtn.Font = Enum.Font.SourceSansSemibold
		partBtn.TextSize = 13
		partBtn.TextXAlignment = Enum.TextXAlignment.Left
		partBtn.BorderSizePixel = 0
		partBtn.Parent = List

		local partCorner = Instance.new("UICorner")
		partCorner.CornerRadius = UDim.new(0, 5)
		partCorner.Parent = partBtn

		partBtn.MouseButton1Click:Connect(function()
			currentPartIdx = (currentPartIdx % #parts) + 1
			local nextPart = parts[currentPartIdx]
			Environment.Settings.LockPart = nextPart
			partBtn.Text = "  Target Part: " .. nextPart
			SaveConfig()
		end)
	end

	-- ===== ESP =====
	CreateSectionHeader("ESP")

	CreateToggle("Team Outline", Environment.EnemyHighlight.Enabled, function(val)
		Environment.EnemyHighlight.Enabled = val
		if not val then
			Environment.ClearTeamOutlines()
		end
	end)

	CreateToggle("Highlight Teammates", Environment.EnemyHighlight.HighlightAll, function(val)
		Environment.EnemyHighlight.HighlightAll = val
	end)

	CreateToggle("ESP Wall Check", Environment.EnemyHighlight.WallCheck, function(val)
		Environment.EnemyHighlight.WallCheck = val
	end)

	CreateInput("NameTag Size", Environment.EnemyHighlight.NameTagSize, function(num)
		Environment.EnemyHighlight.NameTagSize = mathclamp(mathfloor(num), 8, 32)
	end)

	-- ===== SYSTEM =====
	CreateSectionHeader("SYSTEM")

	do
		local keybindBtn = Instance.new("TextButton")
		keybindBtn.Size = UDim2.new(1, 0, 0, 28)
		keybindBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
		keybindBtn.Text = "  GUI Toggle: " .. KeyName(GuiKeybind)
		keybindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		keybindBtn.Font = Enum.Font.SourceSansSemibold
		keybindBtn.TextSize = 13
		keybindBtn.TextXAlignment = Enum.TextXAlignment.Left
		keybindBtn.BorderSizePixel = 0
		keybindBtn.Parent = List

		local keybindCorner = Instance.new("UICorner")
		keybindCorner.CornerRadius = UDim.new(0, 5)
		keybindCorner.Parent = keybindBtn

		keybindBtn.MouseButton1Click:Connect(function()
			ListeningForKey = true
			keybindBtn.Text = "  Press any key... (Esc to cancel)"
			keybindBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 40)
		end)

		UIS.InputBegan:Connect(function(input)
			if ListeningForKey then
				if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
				if input.KeyCode == Enum.KeyCode.Unknown then return end

				if input.KeyCode == Enum.KeyCode.Escape then
					ListeningForKey = false
					keybindBtn.Text = "  GUI Toggle: " .. KeyName(GuiKeybind)
					keybindBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
					return
				end

				GuiKeybind = input.KeyCode
				CurrentGuiKeybind = input.KeyCode
				ListeningForKey = false
				keybindBtn.Text = "  GUI Toggle: " .. KeyName(GuiKeybind)
				keybindBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
				SaveConfig()
				return
			end

			if Typing then return end

			if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == GuiKeybind then
				MainFrame.Visible = not MainFrame.Visible
			end
		end)
	end
end)

return Environment