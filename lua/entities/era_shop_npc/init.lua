--[[
    EraShop — Shop NPC Entity (Server)
    Handles NPC initialization, use interaction, and persistence.
]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel(EraShop.Config.DefaultNPCModel)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionGroup(COLLISION_GROUP_PLAYER)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetUseType(SIMPLE_USE)

    self:PhysicsInit(SOLID_BBOX)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
    end

    -- Set idle animation
    self:ResetSequence("idle_all_01")
    self:SetPlaybackRate(1)

    -- Default networked values
    if self:GetShopID() == 0 then
        self:SetShopName("Nouveau Shop")
    end
end

function ENT:Think()
    self:NextThink(CurTime() + 0.1)

    -- Keep the animation running
    if self:GetSequence() ~= self:LookupSequence("idle_all_01") then
        local seq = self:LookupSequence("idle_all_01")
        if seq and seq > 0 then
            self:ResetSequence(seq)
        end
    end

    return true
end

function ENT:Use(activator, caller)
    if not IsValid(caller) or not caller:IsPlayer() then return end

    local shopId = self:GetShopID()
    if not shopId or shopId <= 0 then
        if caller:IsSuperAdmin() then
            caller:ChatPrint("[EraShop] Ce NPC n'a pas de shop assigné.")
        end
        return
    end

    -- Send the shop state to the player
    net.Start("EraShop_OpenShop")
    net.WriteInt(shopId, 32)
    net.Send(caller)

    -- Server-side: also send the full shop data
    local shopData = EraShop.DB.GetFullShopData(shopId)
    if not shopData then return end

    local state = {
        shop = shopData,
        player = {
            steamid = caller:SteamID64(),
            name = caller:Nick(),
            isAdmin = caller:IsSuperAdmin(),
        },
        config = {
            sectors = EraShop.GetSectors(),
            npcModels = EraShop.Config.NPCModels,
        },
    }

    -- Get player's company info
    local companyInfo = EraShop.GetPlayerCompanyInfo(caller)
    if companyInfo then
        state.player.company = companyInfo
    end

    -- Get player money (DarkRP)
    if caller.getDarkRPVar then
        state.player.money = caller:getDarkRPVar("money") or 0
    else
        state.player.money = 0
    end

    local json = util.TableToJSON(state)
    net.Start("EraShop_ShopState")
    net.WriteUInt(#json, 32)
    net.WriteData(json, #json)
    net.Send(caller)
end

function ENT:OnRemove()
    -- Clean up entity reference
    local shopId = self:GetShopID()
    if shopId and shopId > 0 and EraShop.NPCEntities then
        EraShop.NPCEntities[shopId] = nil
    end
end
