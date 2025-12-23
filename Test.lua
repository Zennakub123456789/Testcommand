--[[ 
    ULTIMATE ADMIN PANEL V4 - FULLY CONNECTED
    Platform: Roblox Lua (LocalScript)
    
    Instruction:
    1. Place this in StarterPlayerScripts (LocalScript).
    2. Ensure RemoteEvent exists at: game.ReplicatedStorage.AdminSystem.AdminAction
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

-- // 0. CONNECT TO SERVER REMOTE // --
-- รอการเชื่อมต่อกับ RemoteEvent (ถ้าหาไม่เจอจะค้างหน้านี้ เพื่อกัน Error)
local AdminEvent = ReplicatedStorage:WaitForChild("AdminSystem"):WaitForChild("AdminAction")

-- ฟังก์ชันช่วยส่งคำสั่ง
local function FireCmd(action, target, extra)
    AdminEvent:FireServer(action, target, extra)
end

-- // 1. CONFIGURATION // --
local Config = {
    MainColor = Color3.fromRGB(26, 26, 26),      -- #1a1a1a
    SidebarColor = Color3.fromRGB(34, 34, 34),   -- #222222
    ContentColor = Color3.fromRGB(30, 30, 30),   -- #1e1e1e
    AccentColor = Color3.fromRGB(59, 130, 246),  -- #3b82f6 (Blue)
    DangerColor = Color3.fromRGB(239, 68, 68),   -- #ef4444 (Red)
    WarningColor = Color3.fromRGB(245, 158, 11), -- #f59e0b (Orange)
    TextColor = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(136, 136, 136),
    Font = Enum.Font.Gotham,
    FontBold = Enum.Font.GothamBold,
    ToggleKey = Enum.KeyCode.RightShift
}

-- // 2. UI LIBRARY HELPER // --
local Library = {}

function Library:Create(className, properties, children)
    local instance = Instance.new(className)
    for k, v in pairs(properties or {}) do
        instance[k] = v
    end
    for _, child in pairs(children or {}) do
        child.Parent = instance
    end
    return instance
end

-- // 3. LOCAL ADMIN LOGIC (Fly, Noclip, etc.) // --
local LocalStates = {
    Flying = false,
    Noclipping = false,
    FreeCam = false,
    Invisible = false
}

-- Fly Logic
local function ToggleFly()
    LocalStates.Flying = not LocalStates.Flying
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local Humanoid = Character:FindFirstChild("Humanoid")
    local Root = Character:FindFirstChild("HumanoidRootPart")
    
    if LocalStates.Flying and Root then
        local BodyGyro = Instance.new("BodyGyro", Root)
        BodyGyro.P = 9e4
        BodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
        BodyGyro.cframe = Root.CFrame
        
        local BodyVel = Instance.new("BodyVelocity", Root)
        BodyVel.velocity = Vector3.new(0, 0, 0)
        BodyVel.maxForce = Vector3.new(9e9, 9e9, 9e9)
        
        task.spawn(function()
            while LocalStates.Flying do
                RunService.RenderStepped:Wait()
                Humanoid.PlatformStand = true
                
                local speed = 50
                local moveDir = Vector3.new(0,0,0)
                
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0,1,0) end
                
                BodyGyro.CFrame = Camera.CFrame
                BodyVel.Velocity = moveDir * speed
            end
            -- Stop Flying
            Humanoid.PlatformStand = false
            BodyGyro:Destroy()
            BodyVel:Destroy()
        end)
    end
end

-- Noclip Logic
RunService.Stepped:Connect(function()
    if LocalStates.Noclipping then
        if LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- // 4. UI CONSTRUCTION // --

local ScreenGui = Library:Create("ScreenGui", {
    Name = "AdminPanelV4_Connected",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = LocalPlayer:WaitForChild("PlayerGui")
})

-- Background Blur
local BlurEffect = Library:Create("BlurEffect", {
    Size = 20,
    Enabled = true,
    Parent = game:GetService("Lighting")
})

-- Main Window
local MainFrame = Library:Create("Frame", {
    Name = "MainFrame",
    BackgroundColor3 = Config.MainColor,
    Size = UDim2.new(0, 720, 0, 500),
    Position = UDim2.new(0.5, -360, 0.5, -250),
    BorderSizePixel = 0,
    Parent = ScreenGui
}, {
    Library:Create("UICorner", {CornerRadius = UDim.new(0, 8)}),
    Library:Create("UIStroke", {Color = Color3.fromRGB(255,255,255), Transparency = 0.9, Thickness = 1})
})

-- Shadow
local Shadow = Library:Create("ImageLabel", {
    Name = "Shadow",
    BackgroundTransparency = 1,
    Image = "rbxassetid://6015897843",
    ImageColor3 = Color3.new(0, 0, 0),
    ImageTransparency = 0.5,
    Position = UDim2.new(0, -40, 0, -40),
    Size = UDim2.new(1, 80, 1, 80),
    ZIndex = 0,
    SliceCenter = Rect.new(49, 49, 450, 450),
    ScaleType = Enum.ScaleType.Slice,
    Parent = MainFrame
})

-- Draggable Logic
local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Layout Containers
local Sidebar = Library:Create("Frame", {
    Name = "Sidebar",
    BackgroundColor3 = Config.SidebarColor,
    Size = UDim2.new(0, 170, 1, 0),
    Parent = MainFrame
}, {
    Library:Create("UICorner", {CornerRadius = UDim.new(0, 8)}),
    Library:Create("Frame", {BackgroundColor3 = Config.SidebarColor, Size = UDim2.new(0, 10, 1, 0), Position = UDim2.new(1, -10, 0, 0), ZIndex = 1}), -- Fix corner
    Library:Create("Frame", {BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.95, Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, 0, 0, 0), ZIndex = 2}) -- Separator
})

local Content = Library:Create("Frame", {
    Name = "Content",
    BackgroundColor3 = Config.ContentColor,
    Size = UDim2.new(1, -170, 1, 0),
    Position = UDim2.new(0, 170, 0, 0),
    ClipsDescendants = true,
    Parent = MainFrame
}, {
    Library:Create("UICorner", {CornerRadius = UDim.new(0, 8)}),
    Library:Create("Frame", {BackgroundColor3 = Config.ContentColor, Size = UDim2.new(0, 10, 1, 0), Position = UDim2.new(0, 0, 0, 0)}) -- Fix corner
})

-- Sidebar Elements
local LogoContainer = Library:Create("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 60), Parent = Sidebar})
Library:Create("TextLabel", {Text = "🛡️ ADMIN V4", Font = Config.FontBold, TextSize = 18, TextColor3 = Config.TextColor, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = LogoContainer})

local NavContainer = Library:Create("Frame", {
    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -60), Position = UDim2.new(0, 0, 0, 60), Parent = Sidebar
}, {
    Library:Create("UIListLayout", {Padding = UDim.new(0, 5), HorizontalAlignment = Enum.HorizontalAlignment.Center}),
    Library:Create("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)})
})

-- Tab System
local CurrentTab = nil
local TabButtons = {}
local Pages = {}

local function SwitchTab(tabName)
    for name, btn in pairs(TabButtons) do
        if name == tabName then
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Config.AccentColor}):Play()
            TweenService:Create(btn.Title, TweenInfo.new(0.2), {TextColor3 = Color3.new(1,1,1)}):Play()
        else
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255,255,255), BackgroundTransparency = 1}):Play()
            TweenService:Create(btn.Title, TweenInfo.new(0.2), {TextColor3 = Config.TextDim}):Play()
        end
    end
    for name, page in pairs(Pages) do
        page.Visible = (name == tabName)
    end
end

local function CreateNavButton(name, icon, targetTab)
    local Btn = Library:Create("TextButton", {
        Name = name, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), Text = "", AutoButtonColor = false, Parent = NavContainer
    }, { Library:Create("UICorner", {CornerRadius = UDim.new(0, 6)}) })

    local Title = Library:Create("TextLabel", {
        Name = "Title", Text = icon .. "  " .. name, Font = Config.Font, TextSize = 14, TextColor3 = Config.TextDim, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 15, 0, 0), Parent = Btn
    })

    Btn.MouseEnter:Connect(function()
        if CurrentTab ~= targetTab then
            TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.95}):Play()
            TweenService:Create(Title, TweenInfo.new(0.2), {TextColor3 = Config.TextColor}):Play()
        end
    end)
    Btn.MouseLeave:Connect(function()
        if CurrentTab ~= targetTab then
            TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            TweenService:Create(Title, TweenInfo.new(0.2), {TextColor3 = Config.TextDim}):Play()
        end
    end)
    Btn.MouseButton1Click:Connect(function() CurrentTab = targetTab SwitchTab(targetTab) end)
    TabButtons[targetTab] = Btn
end

CreateNavButton("Home", "🏠", "Home")
CreateNavButton("Players", "👥", "Players")
CreateNavButton("Server", "🖥️", "Server")
Library:Create("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,0,190), Parent=NavContainer}) -- Spacer
CreateNavButton("Settings", "⚙️", "Settings")

local PageContainer = Library:Create("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = Content}, {Library:Create("UIPadding", {PaddingTop=UDim.new(0,20), PaddingLeft=UDim.new(0,20), PaddingRight=UDim.new(0,20), PaddingBottom=UDim.new(0,20)})})
local function CreatePage(name)
    local P = Library:Create("ScrollingFrame", {Name = name, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarThickness = 4, ScrollBarImageColor3 = Color3.fromRGB(60,60,60), Visible = false, Parent = PageContainer})
    Library:Create("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = P})
    P.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Pages[name] = P
    return P
end

-- ====================
-- TAB: HOME
-- ====================
local HomePage = CreatePage("Home")
Library:Create("TextLabel", {Text="General Admin", Font=Config.FontBold, TextSize=20, TextColor3=Config.TextColor, TextXAlignment=Enum.TextXAlignment.Left, Size=UDim2.new(1,0,0,25), BackgroundTransparency=1, Parent=HomePage})
Library:Create("TextLabel", {Text="Common commands and server broadcast.", Font=Config.Font, TextSize=14, TextColor3=Config.TextDim, TextXAlignment=Enum.TextXAlignment.Left, Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, Parent=HomePage})

Library:Create("TextLabel", {Text="📢 ANNOUNCEMENT", Font=Config.FontBold, TextSize=12, TextColor3=Config.AccentColor, TextXAlignment=Enum.TextXAlignment.Left, Size=UDim2.new(1,0,0,30), BackgroundTransparency=1, Parent=HomePage})

-- Scope Selectors
local ScopeFrame = Library:Create("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,0,25), Parent=HomePage}, {Library:Create("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,15)})})
local function CreateRadio(text, active)
    local Container = Library:Create("TextButton", {Text="", BackgroundTransparency=1, Size=UDim2.new(0, 120, 1, 0), Parent=ScopeFrame})
    local Outer = Library:Create("Frame", {BackgroundColor3=Config.MainColor, Size=UDim2.new(0,14,0,14), Parent=Container}, {Library:Create("UICorner", {CornerRadius=UDim.new(1,0)}), Library:Create("UIStroke", {Color=Color3.fromRGB(85,85,85), Thickness=2})})
    local Inner = Library:Create("Frame", {BackgroundColor3=Config.AccentColor, Size=UDim2.new(0,8,0,8), Position=UDim2.new(0.5,-4,0.5,-4), Visible=active, Parent=Outer}, {Library:Create("UICorner", {CornerRadius=UDim.new(1,0)})})
    if active then Outer.UIStroke.Color = Config.AccentColor end
    Library:Create("TextLabel", {Text=text, Font=Config.Font, TextSize=14, TextColor3=active and Config.TextColor or Config.TextDim, BackgroundTransparency=1, Position=UDim2.new(0,20,0,0), Size=UDim2.new(1,-20,1,0), TextXAlignment=Enum.TextXAlignment.Left, Parent=Container})
    Container.MouseButton1Click:Connect(function()
        -- Reset others (visual only for this scope)
        for _, c in pairs(ScopeFrame:GetChildren()) do
            if c:IsA("TextButton") then
                c.Frame.UIStroke.Color = Color3.fromRGB(85,85,85)
                c.Frame.Frame.Visible = false
                c.TextLabel.TextColor3 = Config.TextDim
            end
        end
        Inner.Visible = true
        Outer.UIStroke.Color = Config.AccentColor
        Container.TextLabel.TextColor3 = Config.TextColor
    end)
end
CreateRadio("This Server", true)
CreateRadio("Global", false)

local AnnounceInput = Library:Create("TextBox", {PlaceholderText="Type message here...", Text="", Font=Config.Font, TextSize=14, TextColor3=Config.TextColor, PlaceholderColor3=Color3.fromRGB(100,100,100), BackgroundColor3=Color3.fromRGB(17,17,17), Size=UDim2.new(1,0,0,40), Parent=HomePage}, {Library:Create("UICorner",{CornerRadius=UDim.new(0,6)}), Library:Create("UIStroke",{Color=Color3.fromRGB(51,51,51)}), Library:Create("UIPadding",{PaddingLeft=UDim.new(0,10)})})
local AnnounceBtn = Library:Create("TextButton", {Text="Send Broadcast", Font=Config.FontBold, TextSize=14, TextColor3=Color3.new(1,1,1), BackgroundColor3=Config.AccentColor, Size=UDim2.new(1,0,0,35), Parent=HomePage}, {Library:Create("UICorner",{CornerRadius=UDim.new(0,6)})})

-- Connect Broadcast
AnnounceBtn.MouseButton1Click:Connect(function()
    FireCmd("Broadcast", nil, AnnounceInput.Text)
    AnnounceInput.Text = "" -- Clear input
end)

Library:Create("TextLabel", {Text="🛡️ LOCAL PLAYER", Font=Config.FontBold, TextSize=12, TextColor3=Config.AccentColor, TextXAlignment=Enum.TextXAlignment.Left, Size=UDim2.new(1,0,0,40), BackgroundTransparency=1, Parent=HomePage})
local Grid = Library:Create("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,0,100), Parent=HomePage}, {Library:Create("UIGridLayout", {CellSize=UDim2.new(0.48,0,0,35), CellPadding=UDim2.new(0.04,0,0,10)})})

local function CreateLocalBtn(text, icon, callback)
    local btn = Library:Create("TextButton", {Text = icon .. " " .. text, Font = Config.Font, TextSize=13, TextColor3=Config.TextColor, BackgroundColor3=Color3.fromRGB(42,42,42), Parent = Grid}, {Library:Create("UICorner", {CornerRadius=UDim.new(0,6)}), Library:Create("UIStroke", {Color=Color3.fromRGB(255,255,255), Transparency=0.9})})
    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(50,50,50)}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(42,42,42)}):Play() end)
    btn.MouseButton1Click:Connect(callback)
end

-- Connect Local Buttons
CreateLocalBtn("Fly", "🕊️", ToggleFly)
CreateLocalBtn("Noclip", "👻", function() LocalStates.Noclipping = not LocalStates.Noclipping end)
CreateLocalBtn("God Mode", "⚡", function() FireCmd("GodMode", LocalPlayer.Name) end) -- Send to server
CreateLocalBtn("Invisible", "👁️", function() FireCmd("Invisible", LocalPlayer.Name) end) -- Send to server
CreateLocalBtn("Btools", "🔨", function() 
    local Tool1 = Instance.new("HopperBin", LocalPlayer.Backpack) Tool1.BinType = Enum.BinType.Hammer
    local Tool2 = Instance.new("HopperBin", LocalPlayer.Backpack) Tool2.BinType = Enum.BinType.Clone
    local Tool3 = Instance.new("HopperBin", LocalPlayer.Backpack) Tool3.BinType = Enum.BinType.GameTool
end)
CreateLocalBtn("Free Cam", "🎥", function() -- Simple Freecam toggle logic (placeholder)
    print("FreeCam Toggled") 
    -- Note: FreeCam usually requires a larger module, keeping it simple here as 'Print'
end)

-- ====================
-- TAB: PLAYER MANAGER
-- ====================
local PlayerPage = CreatePage("Players")
Library:Create("TextLabel", {Text="Player Manager", Font=Config.FontBold, TextSize=20, TextColor3=Config.TextColor, TextXAlignment=Enum.TextXAlignment.Left, Size=UDim2.new(1,0,0,25), BackgroundTransparency=1, Parent=PlayerPage})
Library:Create("TextLabel", {Text="Manage users actions and moderation.", Font=Config.Font, TextSize=14, TextColor3=Config.TextDim, TextXAlignment=Enum.TextXAlignment.Left, Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, Parent=PlayerPage})

-- Target Input
local TargetInput = Library:Create("TextBox", {PlaceholderText="Search Username...", Text="", Font=Config.Font, TextSize=14, TextColor3=Config.TextColor, PlaceholderColor3=Color3.fromRGB(100,100,100), BackgroundColor3=Color3.fromRGB(17,17,17), Size=UDim2.new(1,0,0,40), Parent=PlayerPage}, {Library:Create("UICorner",{CornerRadius=UDim.new(0,6)}), Library:Create("UIStroke",{Color=Color3.fromRGB(51,51,51)}), Library:Create("UIPadding",{PaddingLeft=UDim.new(0,10)})})

-- Quick Actions
Library:Create("TextLabel", {Text="⚡ QUICK ACTIONS", Font=Config.FontBold, TextSize=12, TextColor3=Config.AccentColor, TextXAlignment=Enum.TextXAlignment.Left, Size=UDim2.new(1,0,0,30), BackgroundTransparency=1, Parent=PlayerPage})
local QuickGrid = Library:Create("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,0,130), Parent=PlayerPage}, {Library:Create("UIGridLayout", {CellSize=UDim2.new(0.31,0,0,35), CellPadding=UDim2.new(0.02,0,0,10)})})

local function CreateActionBtn(text, cmdName, color)
    local btn = Library:Create("TextButton", {Text = text, Font = Config.Font, TextSize=13, TextColor3=color or Config.TextColor, BackgroundColor3=Color3.fromRGB(42,42,42), Parent = QuickGrid}, {Library:Create("UICorner", {CornerRadius=UDim.new(0,6)}), Library:Create("UIStroke", {Color=Color3.fromRGB(255,255,255), Transparency=0.9})})
    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(50,50,50)}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(42,42,42)}):Play() end)
    
    -- Connect to Remote
    btn.MouseButton1Click:Connect(function()
        FireCmd(cmdName, TargetInput.Text)
    end)
end

CreateActionBtn("Goto", "Goto")
CreateActionBtn("Bring", "Bring")
CreateActionBtn("Spectate", "Spectate")
CreateActionBtn("Freeze", "Freeze")
CreateActionBtn("Thaw", "Thaw")
CreateActionBtn("Refresh", "Refresh")
CreateActionBtn("Respawn", "Respawn", Config.WarningColor)
CreateActionBtn("Kill", "Kill", Config.DangerColor)
CreateActionBtn("Explode", "Explode", Config.DangerColor)

-- Moderation
Library:Create("TextLabel", {Text="⚖️ MODERATION", Font=Config.FontBold, TextSize=12, TextColor3=Config.AccentColor, TextXAlignment=Enum.TextXAlignment.Left, Size=UDim2.new(1,0,0,30), BackgroundTransparency=1, Parent=PlayerPage})

-- Kick Section
local KickBox = Library:Create("Frame", {BackgroundColor3=Color3.new(0,0,0), BackgroundTransparency=0.8, Size=UDim2.new(1,0,0,100), Parent=PlayerPage}, {Library:Create("UICorner",{CornerRadius=UDim.new(0,6)}), Library:Create("UIStroke",{Color=Color3.fromRGB(51,51,51)}), Library:Create("UIPadding", {PaddingTop=UDim.new(0,10), PaddingLeft=UDim.new(0,10), PaddingRight=UDim.new(0,10), PaddingBottom=UDim.new(0,10)}), Library:Create("UIListLayout", {Padding=UDim.new(0,8)})})
Library:Create("TextLabel", {Text="KICK OPTIONS", Font=Config.FontBold, TextSize=12, TextColor3=Config.TextDim, BackgroundTransparency=1, Size=UDim2.new(1,0,0,15), TextXAlignment=Enum.TextXAlignment.Left, Parent=KickBox})
local KickReason = Library:Create("TextBox", {PlaceholderText="Kick Reason (Optional)", Text="", Font=Config.Font, TextSize=13, TextColor3=Config.TextColor, PlaceholderColor3=Color3.fromRGB(100,100,100), BackgroundColor3=Color3.fromRGB(20,20,20), Size=UDim2.new(1,0,0,30), Parent=KickBox}, {Library:Create("UICorner",{CornerRadius=UDim.new(0,4)}), Library:Create("UIPadding",{PaddingLeft=UDim.new(0,5)})})

local KickBtns = Library:Create("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,0,30), Parent=KickBox}, {Library:Create("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,5)})})
local SoftKickBtn = Library:Create("TextButton", {Text="Soft Kick (Leave)", BackgroundColor3=Color3.fromRGB(42,42,42), TextColor3=Config.WarningColor, Size=UDim2.new(0.5,-3,1,0), Parent=KickBtns}, {Library:Create("UICorner",{CornerRadius=UDim.new(0,4)}), Library:Create("UIStroke",{Color=Config.WarningColor, Transparency=0.7})})
local ServerBanBtn = Library:Create("TextButton", {Text="Server Ban (Block)", BackgroundColor3=Color3.fromRGB(42,42,42), TextColor3=Config.DangerColor, Size=UDim2.new(0.5,-2,1,0), Parent=KickBtns}, {Library:Create("UICorner",{CornerRadius=UDim.new(0,4)}), Library:Create("UIStroke",{Color=Config.DangerColor, Transparency=0.7})})

-- Connect Kick Buttons
SoftKickBtn.MouseButton1Click:Connect(function() FireCmd("Kick", TargetInput.Text, KickReason.Text) end)
ServerBanBtn.MouseButton1Click:Connect(function() FireCmd("ServerBan", TargetInput.Text, KickReason.Text) end)

-- Ban Section
local BanBox = Library:Create("Frame", {BackgroundColor3=Color3.new(0,0,0), BackgroundTransparency=0.8, Size=UDim2.new(1,0,0,135), Parent=PlayerPage}, {Library:Create("UICorner",{CornerRadius=UDim.new(0,6)}), Library:Create("UIStroke",{Color=Config.DangerColor, Transparency=0.5}), Library:Create("UIPadding", {PaddingTop=UDim.new(0,10), PaddingLeft=UDim.new(0,10), PaddingRight=UDim.new(0,10), PaddingBottom=UDim.new(0,10)}), Library:Create("UIListLayout", {Padding=UDim.new(0,8)})})
Library:Create("TextLabel", {Text="BAN HAMMER", Font=Config.FontBold, TextSize=12, TextColor3=Config.DangerColor, BackgroundTransparency=1, Size=UDim2.new(1,0,0,15), TextXAlignment=Enum.TextXAlignment.Left, Parent=BanBox})

local BanReason = Library:Create("TextBox", {PlaceholderText="Ban Reason (Required)", Text="", Font=Config.Font, TextSize=13, TextColor3=Config.TextColor, PlaceholderColor3=Color3.fromRGB(100,100,100), BackgroundColor3=Color3.fromRGB(20,20,20), Size=UDim2.new(1,0,0,30), Parent=BanBox}, {Library:Create("UICorner",{CornerRadius=UDim.new(0,4)}), Library:Create("UIPadding",{PaddingLeft=UDim.new(0,5)}), Library:Create("Frame", {BackgroundColor3=Config.DangerColor, Size=UDim2.new(0,2,1,0)})})

local BanBtns = Library:Create("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,0,30), Parent=BanBox}, {Library:Create("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,5)})})
local DurationInput = Library:Create("TextBox", {PlaceholderText="Duration (Hrs)", Text="", BackgroundColor3=Color3.fromRGB(20,20,20), TextColor3=Config.TextColor, Size=UDim2.new(0.3,0,1,0), Parent=BanBtns}, {Library:Create("UICorner",{CornerRadius=UDim.new(0,4)}), Library:Create("UIPadding",{PaddingLeft=UDim.new(0,5)})})
local TimeBanBtn = Library:Create("TextButton", {Text="Time Ban", BackgroundColor3=Color3.fromRGB(42,42,42), TextColor3=Config.WarningColor, Size=UDim2.new(0.7,-5,1,0), Parent=BanBtns}, {Library:Create("UICorner",{CornerRadius=UDim.new(0,4)}), Library:Create("UIStroke",{Color=Config.WarningColor, Transparency=0.7})})
local PermBanBtn = Library:Create("TextButton", {Text="PERMANENT BAN", BackgroundColor3=Config.DangerColor, TextColor3=Color3.new(1,1,1), Font=Config.FontBold, Size=UDim2.new(1,0,0,30), Parent=BanBox}, {Library:Create("UICorner",{CornerRadius=UDim.new(0,4)})})

-- Connect Ban Buttons
TimeBanBtn.MouseButton1Click:Connect(function() 
    FireCmd("TimeBan", TargetInput.Text, BanReason.Text .. "|" .. DurationInput.Text) 
end)
PermBanBtn.MouseButton1Click:Connect(function() 
    FireCmd("PermBan", TargetInput.Text, BanReason.Text) 
end)


-- ====================
-- TAB: SERVER
-- ====================
local ServerPage = CreatePage("Server")
Library:Create("TextLabel", {Text="Server Control", Font=Config.FontBold, TextSize=20, TextColor3=Config.TextColor, TextXAlignment=Enum.TextXAlignment.Left, Size=UDim2.new(1,0,0,25), BackgroundTransparency=1, Parent=ServerPage})
local ServerGrid = Library:Create("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,0,100), Parent=ServerPage}, {Library:Create("UIGridLayout", {CellSize=UDim2.new(0.48,0,0,35), CellPadding=UDim2.new(0.04,0,0,10)})})

local function CreateServerBtn(text, icon, cmd, color)
    local btn = Library:Create("TextButton", {Text = icon .. " " .. text, Font = Config.Font, TextSize=13, TextColor3=color or Config.TextColor, BackgroundColor3=Color3.fromRGB(42,42,42), Parent = ServerGrid}, {Library:Create("UICorner", {CornerRadius=UDim.new(0,6)}), Library:Create("UIStroke", {Color=Color3.fromRGB(255,255,255), Transparency=0.9})})
    btn.MouseButton1Click:Connect(function() FireCmd(cmd) end)
end

CreateServerBtn("Time: Day", "☀️", "TimeDay")
CreateServerBtn("Time: Night", "🌙", "TimeNight")
CreateServerBtn("Clear Lag", "🧹", "ClearLag")
CreateServerBtn("Shutdown", "🛑", "Shutdown", Config.DangerColor)


-- ====================
-- TAB: SETTINGS
-- ====================
local SettingsPage = CreatePage("Settings")
Library:Create("TextLabel", {Text="Settings", Font=Config.FontBold, TextSize=20, TextColor3=Config.TextColor, TextXAlignment=Enum.TextXAlignment.Left, Size=UDim2.new(1,0,0,25), BackgroundTransparency=1, Parent=SettingsPage})
Library:Create("TextLabel", {Text="Configure interface and functionality.", Font=Config.Font, TextSize=14, TextColor3=Config.TextDim, TextXAlignment=Enum.TextXAlignment.Left, Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, Parent=SettingsPage})

Library:Create("TextLabel", {Text="⌨️ INTERFACE", Font=Config.FontBold, TextSize=12, TextColor3=Config.AccentColor, TextXAlignment=Enum.TextXAlignment.Left, Size=UDim2.new(1,0,0,30), BackgroundTransparency=1, Parent=SettingsPage})

-- Keybind
local KeybindRow = Library:Create("Frame", {BackgroundColor3=Color3.fromRGB(37,37,37), Size=UDim2.new(1,0,0,45), Parent=SettingsPage}, {Library:Create("UICorner",{CornerRadius=UDim.new(0,6)}), Library:Create("UIPadding", {PaddingLeft=UDim.new(0,12), PaddingRight=UDim.new(0,12)})})
Library:Create("TextLabel", {Text="Toggle GUI Keybind", Font=Config.Font, TextSize=14, TextColor3=Config.TextColor, Size=UDim2.new(0.5,0,1,0), BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left, Parent=KeybindRow})
Library:Create("TextButton", {Text="Right Shift", Font=Enum.Font.Code, TextSize=12, TextColor3=Config.TextColor, BackgroundColor3=Color3.fromRGB(51,51,51), Size=UDim2.new(0,100,0,25), Position=UDim2.new(1,-100,0.5,-12.5), Parent=KeybindRow}, {Library:Create("UICorner",{CornerRadius=UDim.new(0,4)}), Library:Create("UIStroke",{Color=Color3.fromRGB(85,85,85), Thickness=1})})

-- Toggles
local function CreateToggle(text, state, callback)
    local Row = Library:Create("Frame", {BackgroundColor3=Color3.fromRGB(37,37,37), Size=UDim2.new(1,0,0,45), Parent=SettingsPage}, {Library:Create("UICorner",{CornerRadius=UDim.new(0,6)}), Library:Create("UIPadding", {PaddingLeft=UDim.new(0,12), PaddingRight=UDim.new(0,12)})})
    Library:Create("TextLabel", {Text=text, Font=Config.Font, TextSize=14, TextColor3=Config.TextColor, Size=UDim2.new(0.5,0,1,0), BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left, Parent=Row})
    local Switch = Library:Create("TextButton", {Text="", BackgroundColor3=state and Config.AccentColor or Color3.fromRGB(68,68,68), Size=UDim2.new(0,40,0,20), Position=UDim2.new(1,-40,0.5,-10), Parent=Row}, {Library:Create("UICorner",{CornerRadius=UDim.new(1,0)})})
    local Circle = Library:Create("Frame", {BackgroundColor3=Color3.new(1,1,1), Size=UDim2.new(0,16,0,16), Position=state and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8), Parent=Switch}, {Library:Create("UICorner",{CornerRadius=UDim.new(1,0)})})
    Switch.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(Switch, TweenInfo.new(0.2), {BackgroundColor3=state and Config.AccentColor or Color3.fromRGB(68,68,68)}):Play()
        TweenService:Create(Circle, TweenInfo.new(0.2), {Position=state and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)}):Play()
        if callback then callback(state) end
    end)
end

Library:Create("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,0,10), Parent=SettingsPage})
CreateToggle("Background Blur", true, function(val) BlurEffect.Enabled = val end)
Library:Create("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,0,5), Parent=SettingsPage})
CreateToggle("Show Notifications", true, nil)

-- Config Buttons
Library:Create("TextLabel", {Text="💾 CONFIGURATION", Font=Config.FontBold, TextSize=12, TextColor3=Config.AccentColor, TextXAlignment=Enum.TextXAlignment.Left, Size=UDim2.new(1,0,0,30), BackgroundTransparency=1, Parent=SettingsPage})
local ConfigGrid = Library:Create("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,0,40), Parent=SettingsPage}, {Library:Create("UIGridLayout", {CellSize=UDim2.new(0.48,0,0,35), CellPadding=UDim2.new(0.04,0,0,0)})})

local function CreateConfBtn(text, icon)
    local btn = Library:Create("TextButton", {Text = icon .. " " .. text, Font = Config.Font, TextSize=13, TextColor3=Config.TextColor, BackgroundColor3=Color3.fromRGB(42,42,42), Parent = ConfigGrid}, {Library:Create("UICorner", {CornerRadius=UDim.new(0,6)}), Library:Create("UIStroke", {Color=Color3.fromRGB(255,255,255), Transparency=0.9})})
end
CreateConfBtn("Save Config", "⬇️")
CreateConfBtn("Load Config", "⬆️")

Library:Create("TextLabel", {Text="Ghost Admin v4.0 Connected | Created by Gemini", Font=Config.Font, TextSize=12, TextColor3=Color3.fromRGB(80,80,80), Size=UDim2.new(1,0,0,30), BackgroundTransparency=1, TextYAlignment=Enum.TextYAlignment.Bottom, Parent=SettingsPage})

-- // 5. INITIALIZATION // --
SwitchTab("Home")

-- Toggle GUI Keybind
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Config.ToggleKey then
        MainFrame.Visible = not MainFrame.Visible
        BlurEffect.Enabled = MainFrame.Visible
    end
end)

-- Top Bar Controls
local CloseBtn = Library:Create("TextButton", {Text="", BackgroundColor3=Config.DangerColor, Size=UDim2.new(0,12,0,12), Position=UDim2.new(1,-25,0,15), Parent=Content}, {Library:Create("UICorner",{CornerRadius=UDim.new(1,0)})})
CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false BlurEffect.Enabled = false end)
local MinBtn = Library:Create("Frame", {BackgroundColor3=Config.WarningColor, Size=UDim2.new(0,12,0,12), Position=UDim2.new(1,-45,0,15), Parent=Content}, {Library:Create("UICorner",{CornerRadius=UDim.new(1,0)})})

print("✅ ADMIN V4 CONNECTED & LOADED!")
