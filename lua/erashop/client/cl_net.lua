--[[
    EraShop — Client Net
    Receives state from server and provides send functions.
]]

EraShop.Net = EraShop.Net or {}

-- ═══════════════════════════════════════
-- Receive shop state from server
-- ═══════════════════════════════════════

net.Receive("EraShop_ShopState", function()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    local json = util.Decompress(data) or data

    -- data is raw bytes, convert to string
    local str = util.BinaryToString and util.BinaryToString(data) or data
    local state = util.JSONToTable(str)

    if not state then
        print("[EraShop] Failed to parse shop state")
        return
    end

    EraShop.State = state

    -- Push state to DHTML
    if IsValid(EraShop.Panel) then
        local safeJson = util.TableToJSON(state)
        EraShop.Panel:RunJavascript('if(window.receiveShopState) window.receiveShopState(' .. safeJson .. ');')
    end

    -- Auto-open the menu if not already open
    if not EraShop.IsOpen then
        EraShop.OpenMenu(state)
    end
end)

-- ═══════════════════════════════════════
-- Receive admin state from server
-- ═══════════════════════════════════════

net.Receive("EraShop_AdminState", function()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    local str = util.BinaryToString and util.BinaryToString(data) or data
    local state = util.JSONToTable(str)

    if not state then
        print("[EraShop] Failed to parse admin state")
        return
    end

    -- Push admin state to DHTML
    if IsValid(EraShop.Panel) then
        local safeJson = util.TableToJSON(state)
        EraShop.Panel:RunJavascript('if(window.receiveAdminState) window.receiveAdminState(' .. safeJson .. ');')
    end
end)

-- ═══════════════════════════════════════
-- Receive notification
-- ═══════════════════════════════════════

net.Receive("EraShop_Notification", function()
    local msg = net.ReadString()
    local isError = net.ReadBool()

    -- Push to DHTML
    if IsValid(EraShop.Panel) then
        local escaped = string.JavascriptSafe(msg)
        EraShop.Panel:RunJavascript('if(window.showToast) window.showToast("' .. escaped .. '", ' .. tostring(isError) .. ');')
    end

    -- Also print in chat
    if isError then
        chat.AddText(Color(255, 80, 80), "[EraShop] ", Color(255, 200, 200), msg)
    else
        chat.AddText(Color(139, 92, 246), "[EraShop] ", Color(220, 220, 255), msg)
    end
end)

-- ═══════════════════════════════════════
-- Receive open shop trigger from entity
-- ═══════════════════════════════════════

net.Receive("EraShop_OpenShop", function()
    local shopId = net.ReadInt(32)
    EraShop.CurrentShopID = shopId
    -- The ShopState message will follow and trigger the menu opening
end)

-- ═══════════════════════════════════════
-- Send functions
-- ═══════════════════════════════════════

function EraShop.Net.RequestShop(shopId)
    net.Start("EraShop_OpenShop")
    net.WriteInt(shopId, 32)
    net.SendToServer()
end

function EraShop.Net.BuyItem(shopId, itemId)
    net.Start("EraShop_BuyItem")
    net.WriteInt(shopId, 32)
    net.WriteInt(itemId, 32)
    net.SendToServer()
end

function EraShop.Net.SpawnNPC()
    net.Start("EraShop_SpawnNPC")
    net.SendToServer()
end

function EraShop.Net.DeleteShop(shopId)
    net.Start("EraShop_DeleteShop")
    net.WriteInt(shopId, 32)
    net.SendToServer()
end

function EraShop.Net.UpdateShop(shopId, name, model)
    net.Start("EraShop_UpdateShop")
    net.WriteInt(shopId, 32)
    net.WriteString(name or "")
    net.WriteString(model or "")
    net.SendToServer()
end

function EraShop.Net.RequestAdminConfig(shopId)
    net.Start("EraShop_RequestAdminConfig")
    net.WriteInt(shopId, 32)
    net.SendToServer()
end

function EraShop.Net.CreateCategory(shopId, name, icon, sortOrder, sectorsJson)
    net.Start("EraShop_CreateCategory")
    net.WriteInt(shopId, 32)
    net.WriteString(name or "")
    net.WriteString(icon or "📦")
    net.WriteInt(sortOrder or 0, 16)
    net.WriteString(sectorsJson or "[]")
    net.SendToServer()
end

function EraShop.Net.UpdateCategory(shopId, catId, name, icon, sortOrder, sectorsJson)
    net.Start("EraShop_UpdateCategory")
    net.WriteInt(shopId, 32)
    net.WriteInt(catId, 32)
    net.WriteString(name or "")
    net.WriteString(icon or "📦")
    net.WriteInt(sortOrder or 0, 16)
    net.WriteString(sectorsJson or "[]")
    net.SendToServer()
end

function EraShop.Net.DeleteCategory(shopId, catId)
    net.Start("EraShop_DeleteCategory")
    net.WriteInt(shopId, 32)
    net.WriteInt(catId, 32)
    net.SendToServer()
end

function EraShop.Net.CreateItem(shopId, catId, name, desc, price, entityClass, model, sortOrder)
    net.Start("EraShop_CreateItem")
    net.WriteInt(shopId, 32)
    net.WriteInt(catId, 32)
    net.WriteString(name or "")
    net.WriteString(desc or "")
    net.WriteFloat(price or 0)
    net.WriteString(entityClass or "")
    net.WriteString(model or "")
    net.WriteInt(sortOrder or 0, 16)
    net.SendToServer()
end

function EraShop.Net.UpdateItem(shopId, itemId, name, desc, price, entityClass, model, sortOrder)
    net.Start("EraShop_UpdateItem")
    net.WriteInt(shopId, 32)
    net.WriteInt(itemId, 32)
    net.WriteString(name or "")
    net.WriteString(desc or "")
    net.WriteFloat(price or 0)
    net.WriteString(entityClass or "")
    net.WriteString(model or "")
    net.WriteInt(sortOrder or 0, 16)
    net.SendToServer()
end

function EraShop.Net.DeleteItem(shopId, itemId)
    net.Start("EraShop_DeleteItem")
    net.WriteInt(shopId, 32)
    net.WriteInt(itemId, 32)
    net.SendToServer()
end

print("[EraShop] cl_net.lua loaded.")
