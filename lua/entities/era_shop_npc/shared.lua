--[[
    EraShop — Shop NPC Entity (Shared)
]]

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Era Shop NPC"
ENT.Author = "Era"
ENT.Category = "EraShop"

ENT.Spawnable = true
ENT.AdminOnly = true
ENT.AutomaticFrameAdvance = true
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "ShopID")
    self:NetworkVar("String", 0, "ShopName")
end
