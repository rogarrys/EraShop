--[[
    EraShop — Server Net API
    All net string registrations and handlers.
    Manages NPC spawning, shop config, and purchases.
]]

-- ═══════════════════════════════════════
-- Net string registration
-- ═══════════════════════════════════════

local netStrings = {
    "EraShop_OpenShop",
    "EraShop_ShopState",
    "EraShop_Notification",
    "EraShop_BuyItem",
    "EraShop_SpawnNPC",
    "EraShop_DeleteShop",
    "EraShop_UpdateShop",
    "EraShop_CreateCategory",
    "EraShop_UpdateCategory",
    "EraShop_DeleteCategory",
    "EraShop_CreateItem",
    "EraShop_UpdateItem",
    "EraShop_DeleteItem",
    "EraShop_RequestAdminConfig",
    "EraShop_AdminState",
}

for _, name in ipairs(netStrings) do
    util.AddNetworkString(name)
end

-- ═══════════════════════════════════════
-- Cooldown system
-- ═══════════════════════════════════════

local cooldowns = {}

local function CheckCooldown(ply, action)
    local key = ply:SteamID64() .. "_" .. action
    local now = CurTime()
    if cooldowns[key] and cooldowns[key] > now then return false end
    cooldowns[key] = now + (EraShop.Config.Cooldown or 1)
    return true
end

-- ═══════════════════════════════════════
-- Helper: Send notification
-- ═══════════════════════════════════════

local function Notify(ply, msg, isError)
    net.Start("EraShop_Notification")
    net.WriteString(msg)
    net.WriteBool(isError or false)
    net.Send(ply)
end

-- ═══════════════════════════════════════
-- Helper: Send shop state to player
-- ═══════════════════════════════════════

local function SendShopState(ply, shopId)
    local shopData = EraShop.DB.GetFullShopData(shopId)
    if not shopData then return end

    local state = {
        shop = shopData,
        player = {
            steamid = ply:SteamID64(),
            name = ply:Nick(),
            isAdmin = ply:IsSuperAdmin(),
        },
        config = {
            sectors = EraShop.GetSectors(),
            npcModels = EraShop.Config.NPCModels,
        },
    }

    -- Get player's company info from EraCompanies
    local companyInfo = EraShop.GetPlayerCompanyInfo(ply)
    if companyInfo then
        state.player.company = companyInfo
    end

    -- Get player money (DarkRP)
    if ply.getDarkRPVar then
        state.player.money = ply:getDarkRPVar("money") or 0
    else
        state.player.money = 0
    end

    local json = util.TableToJSON(state)
    net.Start("EraShop_ShopState")
    net.WriteUInt(#json, 32)
    net.WriteData(json, #json)
    net.Send(ply)
end

-- ═══════════════════════════════════════
-- Helper: Send admin config state
-- ═══════════════════════════════════════

local function SendAdminState(ply, shopId)
    local shopData = EraShop.DB.GetFullShopData(shopId)
    if not shopData then return end

    local state = {
        shop = shopData,
        config = {
            sectors = EraShop.GetSectors(),
            npcModels = EraShop.Config.NPCModels,
        },
    }

    local json = util.TableToJSON(state)
    net.Start("EraShop_AdminState")
    net.WriteUInt(#json, 32)
    net.WriteData(json, #json)
    net.Send(ply)
end

-- ═══════════════════════════════════════
-- NPC Spawning & Persistence
-- ═══════════════════════════════════════

EraShop.NPCEntities = EraShop.NPCEntities or {}

function EraShop.SpawnNPCFromData(shopData)
    local ent = ents.Create("era_shop_npc")
    if not IsValid(ent) then return nil end

    local pos = Vector(
        tonumber(shopData.pos_x) or 0,
        tonumber(shopData.pos_y) or 0,
        tonumber(shopData.pos_z) or 0
    )
    local ang = Angle(0, tonumber(shopData.ang_y) or 0, 0)

    ent:SetPos(pos)
    ent:SetAngles(ang)
    ent:SetModel(shopData.npc_model or EraShop.Config.DefaultNPCModel)
    ent:Spawn()
    ent:Activate()

    ent:SetShopID(tonumber(shopData.id))
    ent:SetShopName(shopData.name or "Shop")

    EraShop.NPCEntities[tonumber(shopData.id)] = ent

    return ent
end

function EraShop.RemoveNPCByShopID(shopId)
    local ent = EraShop.NPCEntities[shopId]
    if IsValid(ent) then
        ent:Remove()
    end
    EraShop.NPCEntities[shopId] = nil
end

-- Spawn all saved NPCs on map load
hook.Add("InitPostEntity", "EraShop_SpawnSavedNPCs", function()
    timer.Simple(3, function()
        EraShop.DB.Init()
        local map = game.GetMap()
        local shops = EraShop.DB.GetShopsForMap(map)

        print("[EraShop] Spawning " .. #shops .. " saved shop NPCs on map: " .. map)

        for _, shop in ipairs(shops) do
            EraShop.SpawnNPCFromData(shop)
        end
    end)
end)

-- ═══════════════════════════════════════
-- NET: Spawn NPC (Admin only)
-- ═══════════════════════════════════════

net.Receive("EraShop_SpawnNPC", function(len, ply)
    if not IsValid(ply) then return end
    if not ply:IsSuperAdmin() then
        Notify(ply, "Vous devez être SuperAdmin.", true)
        return
    end
    if not CheckCooldown(ply, "spawn") then return end

    -- Get the position the admin is looking at
    local trace = ply:GetEyeTrace()
    if not trace.Hit then
        Notify(ply, "Visez un endroit valide.", true)
        return
    end

    local pos = trace.HitPos + Vector(0, 0, 5)
    local ang = Angle(0, (ply:GetPos() - pos):Angle().y, 0)
    local map = game.GetMap()

    local shopId, err = EraShop.DB.CreateShop(
        "Nouveau Shop",
        EraShop.Config.DefaultNPCModel,
        pos.x, pos.y, pos.z,
        ang.y,
        map,
        ply:SteamID64()
    )

    if not shopId then
        Notify(ply, "Erreur: " .. (err or "Inconnue"), true)
        return
    end

    local shopData = EraShop.DB.GetShop(shopId)
    if shopData then
        EraShop.SpawnNPCFromData(shopData)
    end

    Notify(ply, "Shop NPC créé ! (ID: " .. shopId .. ") Configurez-le en appuyant sur E.")

    -- Send admin config state so they can immediately configure
    timer.Simple(0.5, function()
        if IsValid(ply) then
            SendAdminState(ply, shopId)
        end
    end)
end)

-- ═══════════════════════════════════════
-- NET: Open Shop (player presses E)
-- ═══════════════════════════════════════

net.Receive("EraShop_OpenShop", function(len, ply)
    if not IsValid(ply) then return end
    if not CheckCooldown(ply, "open") then return end

    local shopId = net.ReadInt(32)
    if not shopId or shopId <= 0 then return end

    -- Verify shop exists
    local shop = EraShop.DB.GetShop(shopId)
    if not shop then
        Notify(ply, "Ce shop n'existe pas.", true)
        return
    end

    -- Verify player is near the NPC
    local npc = EraShop.NPCEntities[shopId]
    if IsValid(npc) then
        local dist = ply:GetPos():Distance(npc:GetPos())
        if dist > EraShop.Config.InteractDistance then
            Notify(ply, "Vous êtes trop loin.", true)
            return
        end
    end

    SendShopState(ply, shopId)
end)

-- ═══════════════════════════════════════
-- NET: Buy Item
-- ═══════════════════════════════════════

net.Receive("EraShop_BuyItem", function(len, ply)
    if not IsValid(ply) then return end
    if not CheckCooldown(ply, "buy") then return end

    local shopId = net.ReadInt(32)
    local itemId = net.ReadInt(32)

    if not shopId or not itemId then return end

    -- Verify shop exists
    local shop = EraShop.DB.GetShop(shopId)
    if not shop then
        Notify(ply, "Ce shop n'existe pas.", true)
        return
    end

    -- Verify player is near the NPC
    local npc = EraShop.NPCEntities[shopId]
    if IsValid(npc) then
        local dist = ply:GetPos():Distance(npc:GetPos())
        if dist > EraShop.Config.InteractDistance then
            Notify(ply, "Vous êtes trop loin.", true)
            return
        end
    end

    -- Get item
    local item = EraShop.DB.GetItem(itemId)
    if not item then
        Notify(ply, "Cet article n'existe pas.", true)
        return
    end

    -- Verify item belongs to this shop
    local category = EraShop.DB.GetCategory(item.category_id)
    if not category or tonumber(category.shop_id) ~= shopId then
        Notify(ply, "Article invalide pour ce shop.", true)
        return
    end

    -- Check sector restrictions
    local allowedSectors = util.JSONToTable(category.allowed_sectors) or {}
    if #allowedSectors > 0 then
        local playerSector = EraShop.GetPlayerSector(ply)
        local allowed = false
        for _, sector in ipairs(allowedSectors) do
            if sector == playerSector then
                allowed = true
                break
            end
        end
        if not allowed then
            Notify(ply, "Votre secteur d'activité ne permet pas d'acheter cet article.", true)
            return
        end
    end

    -- Check money
    local price = tonumber(item.price) or 0
    if price > 0 then
        if ply.canAfford then
            if not ply:canAfford(price) then
                Notify(ply, "Vous n'avez pas assez d'argent. (Requis: $" .. price .. ")", true)
                return
            end
        elseif ply.getDarkRPVar then
            local money = ply:getDarkRPVar("money") or 0
            if money < price then
                Notify(ply, "Vous n'avez pas assez d'argent. (Requis: $" .. price .. ")", true)
                return
            end
        end
    end

    -- Deduct money
    if price > 0 and ply.addMoney then
        ply:addMoney(-price)
    end

    -- Give item
    local entityClass = item.entity_class or ""
    if entityClass ~= "" then
        -- Check if it's a weapon
        if string.StartWith(entityClass, "weapon_") or weapons.Get(entityClass) then
            ply:Give(entityClass)
            Notify(ply, "Vous avez acheté: " .. item.name .. " pour $" .. price)
        -- Check if it's ammo
        elseif string.StartWith(entityClass, "item_ammo_") then
            ply:Give(entityClass)
            Notify(ply, "Vous avez acheté: " .. item.name .. " pour $" .. price)
        else
            -- Spawn entity near player
            local ent = ents.Create(entityClass)
            if IsValid(ent) then
                local spawnPos = ply:GetPos() + ply:GetForward() * 50 + Vector(0, 0, 20)
                ent:SetPos(spawnPos)
                ent:SetAngles(Angle(0, 0, 0))
                ent:Spawn()
                ent:Activate()

                -- If DarkRP entity, set owner
                if ent.Setowning_ent then
                    ent:Setowning_ent(ply)
                end

                Notify(ply, "Vous avez acheté: " .. item.name .. " pour $" .. price)
            else
                -- Refund if spawn failed
                if price > 0 and ply.addMoney then
                    ply:addMoney(price)
                end
                Notify(ply, "Erreur lors du spawn de l'entité.", true)
            end
        end
    else
        Notify(ply, "Article acheté: " .. item.name, false)
    end

    -- Send updated state (money changed)
    timer.Simple(0.3, function()
        if IsValid(ply) then
            SendShopState(ply, shopId)
        end
    end)
end)

-- ═══════════════════════════════════════
-- NET: Admin - Request Config
-- ═══════════════════════════════════════

net.Receive("EraShop_RequestAdminConfig", function(len, ply)
    if not IsValid(ply) then return end
    if not ply:IsSuperAdmin() then return end
    if not CheckCooldown(ply, "adminconfig") then return end

    local shopId = net.ReadInt(32)
    if not shopId or shopId <= 0 then return end

    SendAdminState(ply, shopId)
end)

-- ═══════════════════════════════════════
-- NET: Admin - Update Shop
-- ═══════════════════════════════════════

net.Receive("EraShop_UpdateShop", function(len, ply)
    if not IsValid(ply) then return end
    if not ply:IsSuperAdmin() then
        Notify(ply, "Accès refusé.", true)
        return
    end
    if not CheckCooldown(ply, "updateshop") then return end

    local shopId = net.ReadInt(32)
    local name = net.ReadString()
    local model = net.ReadString()

    if not shopId or shopId <= 0 then return end
    if not name or name == "" then name = "Shop" end

    EraShop.DB.UpdateShop(shopId, name, model)

    -- Update NPC entity
    local npc = EraShop.NPCEntities[shopId]
    if IsValid(npc) then
        npc:SetShopName(name)
        if model and model ~= "" then
            npc:SetModel(model)
        end
    end

    Notify(ply, "Shop mis à jour !")
    SendAdminState(ply, shopId)
end)

-- ═══════════════════════════════════════
-- NET: Admin - Delete Shop
-- ═══════════════════════════════════════

net.Receive("EraShop_DeleteShop", function(len, ply)
    if not IsValid(ply) then return end
    if not ply:IsSuperAdmin() then
        Notify(ply, "Accès refusé.", true)
        return
    end
    if not CheckCooldown(ply, "deleteshop") then return end

    local shopId = net.ReadInt(32)
    if not shopId or shopId <= 0 then return end

    -- Remove NPC
    EraShop.RemoveNPCByShopID(shopId)

    -- Delete from DB
    EraShop.DB.DeleteShop(shopId)

    Notify(ply, "Shop supprimé !")
end)

-- ═══════════════════════════════════════
-- NET: Admin - Create Category
-- ═══════════════════════════════════════

net.Receive("EraShop_CreateCategory", function(len, ply)
    if not IsValid(ply) then return end
    if not ply:IsSuperAdmin() then
        Notify(ply, "Accès refusé.", true)
        return
    end
    if not CheckCooldown(ply, "createcat") then return end

    local shopId = net.ReadInt(32)
    local name = net.ReadString()
    local icon = net.ReadString()
    local sortOrder = net.ReadInt(16)
    local sectorsJson = net.ReadString()

    if not shopId or shopId <= 0 then return end
    if not name or name == "" then
        Notify(ply, "Nom de catégorie requis.", true)
        return
    end

    local catId = EraShop.DB.CreateCategory(shopId, name, icon, sortOrder, sectorsJson)
    if catId then
        Notify(ply, "Catégorie créée !")
        SendAdminState(ply, shopId)
    else
        Notify(ply, "Erreur lors de la création.", true)
    end
end)

-- ═══════════════════════════════════════
-- NET: Admin - Update Category
-- ═══════════════════════════════════════

net.Receive("EraShop_UpdateCategory", function(len, ply)
    if not IsValid(ply) then return end
    if not ply:IsSuperAdmin() then
        Notify(ply, "Accès refusé.", true)
        return
    end
    if not CheckCooldown(ply, "updatecat") then return end

    local shopId = net.ReadInt(32)
    local catId = net.ReadInt(32)
    local name = net.ReadString()
    local icon = net.ReadString()
    local sortOrder = net.ReadInt(16)
    local sectorsJson = net.ReadString()

    if not catId or catId <= 0 then return end

    EraShop.DB.UpdateCategory(catId, name, icon, sortOrder, sectorsJson)
    Notify(ply, "Catégorie mise à jour !")
    SendAdminState(ply, shopId)
end)

-- ═══════════════════════════════════════
-- NET: Admin - Delete Category
-- ═══════════════════════════════════════

net.Receive("EraShop_DeleteCategory", function(len, ply)
    if not IsValid(ply) then return end
    if not ply:IsSuperAdmin() then
        Notify(ply, "Accès refusé.", true)
        return
    end
    if not CheckCooldown(ply, "deletecat") then return end

    local shopId = net.ReadInt(32)
    local catId = net.ReadInt(32)
    if not catId or catId <= 0 then return end

    EraShop.DB.DeleteCategory(catId)
    Notify(ply, "Catégorie supprimée !")
    SendAdminState(ply, shopId)
end)

-- ═══════════════════════════════════════
-- NET: Admin - Create Item
-- ═══════════════════════════════════════

net.Receive("EraShop_CreateItem", function(len, ply)
    if not IsValid(ply) then return end
    if not ply:IsSuperAdmin() then
        Notify(ply, "Accès refusé.", true)
        return
    end
    if not CheckCooldown(ply, "createitem") then return end

    local shopId = net.ReadInt(32)
    local catId = net.ReadInt(32)
    local name = net.ReadString()
    local description = net.ReadString()
    local price = net.ReadFloat()
    local entityClass = net.ReadString()
    local model = net.ReadString()
    local sortOrder = net.ReadInt(16)

    if not catId or catId <= 0 then return end
    if not name or name == "" then
        Notify(ply, "Nom d'article requis.", true)
        return
    end

    local itemId = EraShop.DB.CreateItem(catId, name, description, price, entityClass, model, sortOrder)
    if itemId then
        Notify(ply, "Article créé !")
        SendAdminState(ply, shopId)
    else
        Notify(ply, "Erreur lors de la création.", true)
    end
end)

-- ═══════════════════════════════════════
-- NET: Admin - Update Item
-- ═══════════════════════════════════════

net.Receive("EraShop_UpdateItem", function(len, ply)
    if not IsValid(ply) then return end
    if not ply:IsSuperAdmin() then
        Notify(ply, "Accès refusé.", true)
        return
    end
    if not CheckCooldown(ply, "updateitem") then return end

    local shopId = net.ReadInt(32)
    local itemId = net.ReadInt(32)
    local name = net.ReadString()
    local description = net.ReadString()
    local price = net.ReadFloat()
    local entityClass = net.ReadString()
    local model = net.ReadString()
    local sortOrder = net.ReadInt(16)

    if not itemId or itemId <= 0 then return end

    EraShop.DB.UpdateItem(itemId, name, description, price, entityClass, model, sortOrder)
    Notify(ply, "Article mis à jour !")
    SendAdminState(ply, shopId)
end)

-- ═══════════════════════════════════════
-- NET: Admin - Delete Item
-- ═══════════════════════════════════════

net.Receive("EraShop_DeleteItem", function(len, ply)
    if not IsValid(ply) then return end
    if not ply:IsSuperAdmin() then
        Notify(ply, "Accès refusé.", true)
        return
    end
    if not CheckCooldown(ply, "deleteitem") then return end

    local shopId = net.ReadInt(32)
    local itemId = net.ReadInt(32)
    if not itemId or itemId <= 0 then return end

    EraShop.DB.DeleteItem(itemId)
    Notify(ply, "Article supprimé !")
    SendAdminState(ply, shopId)
end)

-- ═══════════════════════════════════════
-- Console / Chat commands
-- ═══════════════════════════════════════

concommand.Add("erashop_spawn", function(ply, cmd, args)
    if not IsValid(ply) then return end
    if not ply:IsSuperAdmin() then
        ply:ChatPrint("[EraShop] Vous devez être SuperAdmin.")
        return
    end

    -- Simulate the net message
    local trace = ply:GetEyeTrace()
    if not trace.Hit then
        ply:ChatPrint("[EraShop] Visez un endroit valide.")
        return
    end

    local pos = trace.HitPos + Vector(0, 0, 5)
    local ang = Angle(0, (ply:GetPos() - pos):Angle().y, 0)
    local map = game.GetMap()

    local shopId, err = EraShop.DB.CreateShop(
        "Nouveau Shop",
        EraShop.Config.DefaultNPCModel,
        pos.x, pos.y, pos.z,
        ang.y,
        map,
        ply:SteamID64()
    )

    if not shopId then
        ply:ChatPrint("[EraShop] Erreur: " .. (err or "Inconnue"))
        return
    end

    local shopData = EraShop.DB.GetShop(shopId)
    if shopData then
        EraShop.SpawnNPCFromData(shopData)
    end

    ply:ChatPrint("[EraShop] Shop NPC créé ! (ID: " .. shopId .. ")")
end)

-- Chat command: !shopnpc
hook.Add("PlayerSay", "EraShop_ChatCommands", function(ply, text)
    local lower = string.lower(text)
    if lower == "!shopnpc" or lower == "!erashop" then
        if ply:IsSuperAdmin() then
            ply:ConCommand("erashop_spawn")
        else
            ply:ChatPrint("[EraShop] Vous devez être SuperAdmin.")
        end
        return ""
    end
end)

print("[EraShop] sv_net.lua loaded.")
