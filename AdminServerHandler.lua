-- [[ SERVER SCRIPT SERVICE: AdminServerHandler ]] --

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

-- 1. ตั้งค่า Folder และ Remote
local AdminFolder = ReplicatedStorage:WaitForChild("AdminSystem")
local AdminEvent = AdminFolder:WaitForChild("AdminAction")

-- 2. ตั้งค่า Admin (ใส่ User ID ของคุณลงไปตรงนี้)
-- วิธีหา ID: ไปที่หน้าโปรไฟล์ Roblox ของคุณ แล้วดูตัวเลขใน URL
local AdminList = {
    12345678, -- เปลี่ยนเป็น ID ของคุณ
    87654321, -- ID เพื่อนแอดมิน (ถ้ามี)
}

-- ตารางเก็บคนโดนแบน (ใช้ DataStore ถ้าจะแบนถาวรจริงจัง)
local BannedUsers = {}

-- ฟังก์ชันตรวจสอบ Admin
local function IsAdmin(player)
    for _, id in pairs(AdminList) do
        if player.UserId == id then return true end
    end
    return false
end

-- 3. ฟังก์ชันจัดการคำสั่ง
AdminEvent.OnServerEvent:Connect(function(player, action, targetName, extraData)
    -- ระบบความปลอดภัย: ถ้าไม่ใช่ Admin สั่ง ให้หยุดทำงานทันที
    if not IsAdmin(player) then
        warn(player.Name .. " พยายามแฮ็กระบบ Admin!")
        return 
    end

    -- หาตัวผู้เล่นเป้าหมาย (Target)
    local targetPlayer = nil
    if targetName then
        -- ค้นหาชื่อแบบย่อได้ (เช่นพิมพ์ "gem" ก็เจอ "gemini")
        for _, p in pairs(Players:GetPlayers()) do
            if string.sub(string.lower(p.Name), 1, string.len(targetName)) == string.lower(targetName) or
               string.sub(string.lower(p.DisplayName), 1, string.len(targetName)) == string.lower(targetName) then
                targetPlayer = p
                break
            end
        end
    end

    print("Admin: " .. player.Name .. " สั่งคำสั่ง: " .. action)

    -- === โซนคำสั่ง (LOGIC) === --
    
    if action == "Kick" and targetPlayer then
        -- extraData คือ Reason
        targetPlayer:Kick("คุณถูกเตะโดย Admin: " .. (extraData or "ไม่ระบุเหตุผล"))

    elseif action == "Ban" and targetPlayer then
        -- แบนแบบง่าย (Server Ban)
        table.insert(BannedUsers, targetPlayer.UserId)
        targetPlayer:Kick("คุณถูกแบนจากเซิร์ฟเวอร์นี้: " .. (extraData or "ละเมิดกฎ"))

    elseif action == "Kill" and targetPlayer then
        if targetPlayer.Character then
            targetPlayer.Character:BreakJoints()
        end

    elseif action == "Explode" and targetPlayer then
        if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local exp = Instance.new("Explosion")
            exp.Position = targetPlayer.Character.HumanoidRootPart.Position
            exp.Parent = workspace
        end

    elseif action == "Bring" and targetPlayer then
        if targetPlayer.Character and player.Character then
            -- วาร์ปคนอื่นมาหาเรา
            targetPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5)
        end

    elseif action == "Freeze" and targetPlayer then
        if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            targetPlayer.Character.HumanoidRootPart.Anchored = true
        end

    elseif action == "Thaw" and targetPlayer then
         if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            targetPlayer.Character.HumanoidRootPart.Anchored = false
        end
        
    elseif action == "Respawn" and targetPlayer then
        targetPlayer:LoadCharacter()

    elseif action == "TimeDay" then
        Lighting.ClockTime = 12

    elseif action == "TimeNight" then
        Lighting.ClockTime = 0

    elseif action == "ClearLag" then
        -- ลบ Part ที่ตกพื้น หรือขยะในแมพ (ตัวอย่าง)
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v.Anchored and v.Parent:IsA("Model") == false then
                v:Destroy()
            end
        end
        
    elseif action == "Shutdown" then
        for _, p in pairs(Players:GetPlayers()) do
            p:Kick("เซิร์ฟเวอร์ปิดปรับปรุง (Server Shutdown)")
        end
    
    elseif action == "Broadcast" then
        -- ส่งประกาศให้ทุกคนเห็น (ส่งกลับไปหา Client ทุกคน)
        -- ต้องสร้าง Remote อีกตัวชื่อ "ShowAlert" หรือใช้ Chat
        local msg = Instance.new("Message", workspace)
        msg.Text = "[ADMIN ANNOUNCEMENT]: " .. (extraData or "")
        task.wait(5)
        msg:Destroy()
    end
end)

-- ระบบกันคนโดนแบนเข้าเกม (Server Ban Logic)
Players.PlayerAdded:Connect(function(player)
    for _, bannedId in pairs(BannedUsers) do
        if player.UserId == bannedId then
            player:Kick("คุณติดแบนในเซิร์ฟเวอร์นี้")
        end
    end
end)
