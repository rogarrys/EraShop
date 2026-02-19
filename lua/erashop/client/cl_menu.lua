--[[
    EraShop — Client Menu
    Creates the DHTML panel and sets up the JS↔Lua bridge.
    Uses DHTML directly for proper keyboard input.
]]

print("[EraShop] cl_menu.lua loaded!")

local function GetHTMLPath()
    return EraShop.Config.WebURL or "http://localhost/index.html"
end

function EraShop.OpenMenu(initialState)
    print("[EraShop] OpenMenu called")

    -- If already exists, just show it and push state
    if IsValid(EraShop.Panel) then
        EraShop.Panel:SetVisible(true)
        EraShop.Panel:SetKeyboardInputEnabled(true)
        EraShop.Panel:SetMouseInputEnabled(true)
        EraShop.Panel:MakePopup()
        EraShop.Panel:RequestFocus()
        EraShop.IsOpen = true

        if initialState then
            local safeJson = util.TableToJSON(initialState)
            EraShop.Panel:RunJavascript('if(window.receiveShopState) window.receiveShopState(' .. safeJson .. ');')
        end
        return
    end

    local w, h = ScrW(), ScrH()
    local pw = math.floor(w * 0.75)
    local ph = math.floor(h * 0.80)

    -- Create DHTML directly
    local html = vgui.Create("DHTML")
    html:SetSize(pw, ph)
    html:SetPos((w - pw) / 2, (h - ph) / 2)
    html:SetAllowLua(true)
    html:SetVisible(true)
    html:SetAlpha(255)
    html:MakePopup()
    html:SetKeyboardInputEnabled(true)
    html:SetMouseInputEnabled(true)
    html:RequestFocus()

    -- ─── JS → Lua bridge ───

    html:AddFunction("lua", "log", function(msg)
        print("[EraShop JS] " .. tostring(msg))
    end)

    html:AddFunction("lua", "closeMenu", function()
        EraShop.CloseMenu()
    end)

    html:AddFunction("lua", "buyItem", function(shopId, itemId)
        EraShop.Net.BuyItem(tonumber(shopId) or 0, tonumber(itemId) or 0)
    end)

    html:AddFunction("lua", "spawnNPC", function()
        EraShop.Net.SpawnNPC()
    end)

    html:AddFunction("lua", "deleteShop", function(shopId)
        EraShop.Net.DeleteShop(tonumber(shopId) or 0)
        EraShop.CloseMenu()
    end)

    html:AddFunction("lua", "updateShop", function(shopId, name, model)
        EraShop.Net.UpdateShop(tonumber(shopId) or 0, name or "", model or "")
    end)

    html:AddFunction("lua", "requestAdminConfig", function(shopId)
        EraShop.Net.RequestAdminConfig(tonumber(shopId) or 0)
    end)

    html:AddFunction("lua", "createCategory", function(shopId, name, icon, sortOrder, sectorsJson)
        EraShop.Net.CreateCategory(
            tonumber(shopId) or 0,
            name or "",
            icon or "📦",
            tonumber(sortOrder) or 0,
            sectorsJson or "[]"
        )
    end)

    html:AddFunction("lua", "updateCategory", function(shopId, catId, name, icon, sortOrder, sectorsJson)
        EraShop.Net.UpdateCategory(
            tonumber(shopId) or 0,
            tonumber(catId) or 0,
            name or "",
            icon or "📦",
            tonumber(sortOrder) or 0,
            sectorsJson or "[]"
        )
    end)

    html:AddFunction("lua", "deleteCategory", function(shopId, catId)
        EraShop.Net.DeleteCategory(tonumber(shopId) or 0, tonumber(catId) or 0)
    end)

    html:AddFunction("lua", "createItem", function(shopId, catId, name, desc, price, entityClass, model, sortOrder)
        EraShop.Net.CreateItem(
            tonumber(shopId) or 0,
            tonumber(catId) or 0,
            name or "",
            desc or "",
            tonumber(price) or 0,
            entityClass or "",
            model or "",
            tonumber(sortOrder) or 0
        )
    end)

    html:AddFunction("lua", "updateItem", function(shopId, itemId, name, desc, price, entityClass, model, sortOrder)
        EraShop.Net.UpdateItem(
            tonumber(shopId) or 0,
            tonumber(itemId) or 0,
            name or "",
            desc or "",
            tonumber(price) or 0,
            entityClass or "",
            model or "",
            tonumber(sortOrder) or 0
        )
    end)

    html:AddFunction("lua", "deleteItem", function(shopId, itemId)
        EraShop.Net.DeleteItem(tonumber(shopId) or 0, tonumber(itemId) or 0)
    end)

    print("[EraShop] Loading URL: " .. GetHTMLPath())
    html:OpenURL(GetHTMLPath())

    EraShop.Panel = html
    EraShop.IsOpen = true

    -- Push initial state after a brief delay (let HTML load)
    timer.Simple(1.2, function()
        if IsValid(html) and initialState then
            local safeJson = util.TableToJSON(initialState)
            html:RunJavascript('if(window.receiveShopState) window.receiveShopState(' .. safeJson .. ');')
        end
    end)
end

function EraShop.CloseMenu()
    if IsValid(EraShop.Panel) then
        EraShop.Panel:SetVisible(false)
        EraShop.Panel:SetKeyboardInputEnabled(false)
        EraShop.Panel:SetMouseInputEnabled(false)
    end
    EraShop.IsOpen = false
    gui.EnableScreenClicker(false)
end

-- ─── Escape to close ───
hook.Add("PlayerButtonDown", "EraShop_ButtonDown", function(ply, btn)
    if ply ~= LocalPlayer() then return end
    if btn == KEY_ESCAPE and EraShop.IsOpen then
        EraShop.CloseMenu()
    end
end)

-- ─── Console command ───
concommand.Add("erashop_menu", function()
    if EraShop.IsOpen then
        EraShop.CloseMenu()
    else
        -- Request shop state for the nearest NPC
        local ply = LocalPlayer()
        local nearestShopId = nil
        local nearestDist = math.huge

        for _, ent in ipairs(ents.FindByClass("era_shop_npc")) do
            local dist = ply:GetPos():Distance(ent:GetPos())
            if dist < nearestDist and dist < EraShop.Config.InteractDistance then
                nearestDist = dist
                nearestShopId = ent:GetShopID()
            end
        end

        if nearestShopId and nearestShopId > 0 then
            EraShop.Net.RequestShop(nearestShopId)
        else
            chat.AddText(Color(255, 80, 80), "[EraShop] ", Color(255, 200, 200), "Aucun shop NPC à proximité.")
        end
    end
end)

print("[EraShop] cl_menu.lua initialization complete")
