--[[
    EraShop — Shop NPC Entity (Client)
    Renders 3D text above the NPC with shop name and interaction hint.
]]

include("shared.lua")

local FONT_TITLE = "EraShopNPCTitle"
local FONT_HINT = "EraShopNPCHint"

surface.CreateFont(FONT_TITLE, {
    font = "Roboto",
    size = 40,
    weight = 700,
    antialias = true,
})

surface.CreateFont(FONT_HINT, {
    font = "Roboto",
    size = 24,
    weight = 400,
    antialias = true,
})

function ENT:Initialize()
    self.GlowAmount = 0
end

function ENT:Draw()
    self:DrawModel()
end

function ENT:DrawTranslucent()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local dist = ply:GetPos():Distance(self:GetPos())
    if dist > 400 then return end

    local alpha = math.Clamp(1 - (dist - 200) / 200, 0, 1) * 255

    local pos = self:GetPos() + Vector(0, 0, 85)
    local ang = (ply:GetPos() - pos):Angle()
    ang = Angle(0, ang.y - 180, 0)

    local shopName = self:GetShopName() or "Shop"

    -- Background panel
    cam.Start3D2D(pos + Vector(0, 0, 12), ang, 0.08)
        -- Glow effect
        local pulse = math.sin(CurTime() * 2) * 0.15 + 0.85
        draw.RoundedBox(12, -200, -30, 400, 60, Color(139, 92, 246, alpha * 0.25 * pulse))
        draw.RoundedBox(8, -195, -25, 390, 50, Color(15, 15, 30, alpha * 0.85))

        -- Shop name
        draw.SimpleText(shopName, FONT_TITLE, 0, 0, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()

    -- Hint text
    if dist < 200 then
        local hintAlpha = math.Clamp(1 - (dist - 100) / 100, 0, 1) * 255
        cam.Start3D2D(pos - Vector(0, 0, 5), ang, 0.06)
            draw.SimpleText("Appuyez sur  E  pour ouvrir", FONT_HINT, 0, 0, Color(200, 200, 220, hintAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end

    -- Small icon indicator
    cam.Start3D2D(pos + Vector(0, 0, 28), ang, 0.05)
        local iconPulse = math.sin(CurTime() * 3) * 5
        draw.SimpleText("🛒", "DermaLarge", 0, iconPulse, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end
