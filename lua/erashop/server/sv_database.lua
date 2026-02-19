--[[
    EraShop — SQLite Database
    Creates tables, performs migrations, and provides query helpers
    for shops, categories, and items.
]]

EraShop.DB = EraShop.DB or {}

-- ─── Initialise database ───
function EraShop.DB.Init()
    local queries = {
        [[CREATE TABLE IF NOT EXISTS era_shops (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL DEFAULT 'Nouveau Shop',
            npc_model TEXT DEFAULT 'models/humans/group01/male_07.mdl',
            pos_x REAL DEFAULT 0,
            pos_y REAL DEFAULT 0,
            pos_z REAL DEFAULT 0,
            ang_y REAL DEFAULT 0,
            map TEXT NOT NULL,
            created_by TEXT,
            created_at INTEGER DEFAULT (strftime('%s','now'))
        )]],
        [[CREATE TABLE IF NOT EXISTS era_shop_categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            shop_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            icon TEXT DEFAULT '📦',
            sort_order INTEGER DEFAULT 0,
            allowed_sectors TEXT DEFAULT '[]',
            FOREIGN KEY (shop_id) REFERENCES era_shops(id)
        )]],
        [[CREATE TABLE IF NOT EXISTS era_shop_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            description TEXT DEFAULT '',
            price REAL DEFAULT 0,
            entity_class TEXT DEFAULT '',
            model TEXT DEFAULT '',
            sort_order INTEGER DEFAULT 0,
            FOREIGN KEY (category_id) REFERENCES era_shop_categories(id)
        )]],
    }

    for _, q in ipairs(queries) do
        sql.Query(q)
        if sql.LastError() and sql.LastError() ~= "" then
            ErrorNoHalt("[EraShop] SQL Error: " .. sql.LastError() .. "\n")
        end
    end

    print("[EraShop] Database initialised.")
end

-- ═══════════════════════════════════════
-- SHOP queries
-- ═══════════════════════════════════════

function EraShop.DB.CreateShop(name, model, posX, posY, posZ, angY, map, createdBy)
    sql.Query(string.format(
        "INSERT INTO era_shops (name, npc_model, pos_x, pos_y, pos_z, ang_y, map, created_by) VALUES (%s, %s, %f, %f, %f, %f, %s, %s)",
        sql.SQLStr(name),
        sql.SQLStr(model),
        posX, posY, posZ, angY,
        sql.SQLStr(map),
        sql.SQLStr(createdBy)
    ))
    if sql.LastError() and sql.LastError() ~= "" then return nil, sql.LastError() end
    return tonumber(sql.QueryValue("SELECT last_insert_rowid()"))
end

function EraShop.DB.GetShop(shopId)
    return sql.QueryRow("SELECT * FROM era_shops WHERE id = " .. tonumber(shopId))
end

function EraShop.DB.GetShopsForMap(map)
    return sql.Query("SELECT * FROM era_shops WHERE map = " .. sql.SQLStr(map)) or {}
end

function EraShop.DB.GetAllShops()
    return sql.Query("SELECT * FROM era_shops ORDER BY name ASC") or {}
end

function EraShop.DB.UpdateShop(shopId, name, model)
    sql.Query(string.format(
        "UPDATE era_shops SET name = %s, npc_model = %s WHERE id = %d",
        sql.SQLStr(name),
        sql.SQLStr(model),
        tonumber(shopId)
    ))
end

function EraShop.DB.UpdateShopPosition(shopId, posX, posY, posZ, angY)
    sql.Query(string.format(
        "UPDATE era_shops SET pos_x = %f, pos_y = %f, pos_z = %f, ang_y = %f WHERE id = %d",
        posX, posY, posZ, angY, tonumber(shopId)
    ))
end

function EraShop.DB.DeleteShop(shopId)
    local id = tonumber(shopId)
    -- Delete items from all categories of this shop
    sql.Query("DELETE FROM era_shop_items WHERE category_id IN (SELECT id FROM era_shop_categories WHERE shop_id = " .. id .. ")")
    -- Delete categories
    sql.Query("DELETE FROM era_shop_categories WHERE shop_id = " .. id)
    -- Delete shop
    sql.Query("DELETE FROM era_shops WHERE id = " .. id)
end

-- ═══════════════════════════════════════
-- CATEGORY queries
-- ═══════════════════════════════════════

function EraShop.DB.GetCategories(shopId)
    return sql.Query(string.format(
        "SELECT * FROM era_shop_categories WHERE shop_id = %d ORDER BY sort_order ASC, id ASC",
        tonumber(shopId)
    )) or {}
end

function EraShop.DB.GetCategory(categoryId)
    return sql.QueryRow("SELECT * FROM era_shop_categories WHERE id = " .. tonumber(categoryId))
end

function EraShop.DB.CreateCategory(shopId, name, icon, sortOrder, allowedSectors)
    sql.Query(string.format(
        "INSERT INTO era_shop_categories (shop_id, name, icon, sort_order, allowed_sectors) VALUES (%d, %s, %s, %d, %s)",
        tonumber(shopId),
        sql.SQLStr(name),
        sql.SQLStr(icon or "📦"),
        tonumber(sortOrder) or 0,
        sql.SQLStr(allowedSectors or "[]")
    ))
    if sql.LastError() and sql.LastError() ~= "" then return nil end
    return tonumber(sql.QueryValue("SELECT last_insert_rowid()"))
end

function EraShop.DB.UpdateCategory(categoryId, name, icon, sortOrder, allowedSectors)
    sql.Query(string.format(
        "UPDATE era_shop_categories SET name = %s, icon = %s, sort_order = %d, allowed_sectors = %s WHERE id = %d",
        sql.SQLStr(name),
        sql.SQLStr(icon or "📦"),
        tonumber(sortOrder) or 0,
        sql.SQLStr(allowedSectors or "[]"),
        tonumber(categoryId)
    ))
end

function EraShop.DB.DeleteCategory(categoryId)
    local id = tonumber(categoryId)
    sql.Query("DELETE FROM era_shop_items WHERE category_id = " .. id)
    sql.Query("DELETE FROM era_shop_categories WHERE id = " .. id)
end

-- ═══════════════════════════════════════
-- ITEM queries
-- ═══════════════════════════════════════

function EraShop.DB.GetItems(categoryId)
    return sql.Query(string.format(
        "SELECT * FROM era_shop_items WHERE category_id = %d ORDER BY sort_order ASC, id ASC",
        tonumber(categoryId)
    )) or {}
end

function EraShop.DB.GetAllItemsForShop(shopId)
    return sql.Query(string.format(
        "SELECT i.* FROM era_shop_items i INNER JOIN era_shop_categories c ON i.category_id = c.id WHERE c.shop_id = %d ORDER BY c.sort_order ASC, i.sort_order ASC",
        tonumber(shopId)
    )) or {}
end

function EraShop.DB.GetItem(itemId)
    return sql.QueryRow("SELECT * FROM era_shop_items WHERE id = " .. tonumber(itemId))
end

function EraShop.DB.CreateItem(categoryId, name, description, price, entityClass, model, sortOrder)
    sql.Query(string.format(
        "INSERT INTO era_shop_items (category_id, name, description, price, entity_class, model, sort_order) VALUES (%d, %s, %s, %f, %s, %s, %d)",
        tonumber(categoryId),
        sql.SQLStr(name),
        sql.SQLStr(description or ""),
        tonumber(price) or 0,
        sql.SQLStr(entityClass or ""),
        sql.SQLStr(model or ""),
        tonumber(sortOrder) or 0
    ))
    if sql.LastError() and sql.LastError() ~= "" then return nil end
    return tonumber(sql.QueryValue("SELECT last_insert_rowid()"))
end

function EraShop.DB.UpdateItem(itemId, name, description, price, entityClass, model, sortOrder)
    sql.Query(string.format(
        "UPDATE era_shop_items SET name = %s, description = %s, price = %f, entity_class = %s, model = %s, sort_order = %d WHERE id = %d",
        sql.SQLStr(name),
        sql.SQLStr(description or ""),
        tonumber(price) or 0,
        sql.SQLStr(entityClass or ""),
        sql.SQLStr(model or ""),
        tonumber(sortOrder) or 0,
        tonumber(itemId)
    ))
end

function EraShop.DB.DeleteItem(itemId)
    sql.Query("DELETE FROM era_shop_items WHERE id = " .. tonumber(itemId))
end

-- ═══════════════════════════════════════
-- Helper: Build full shop state for a shop
-- ═══════════════════════════════════════

function EraShop.DB.GetFullShopData(shopId)
    local shop = EraShop.DB.GetShop(shopId)
    if not shop then return nil end

    local data = {
        id = tonumber(shop.id),
        name = shop.name,
        npc_model = shop.npc_model,
    }

    data.categories = {}
    local categories = EraShop.DB.GetCategories(shopId)
    for _, cat in ipairs(categories) do
        local catData = {
            id = tonumber(cat.id),
            name = cat.name,
            icon = cat.icon,
            sort_order = tonumber(cat.sort_order),
            allowed_sectors = util.JSONToTable(cat.allowed_sectors) or {},
            items = {},
        }

        local items = EraShop.DB.GetItems(cat.id)
        for _, item in ipairs(items) do
            table.insert(catData.items, {
                id = tonumber(item.id),
                name = item.name,
                description = item.description,
                price = tonumber(item.price),
                entity_class = item.entity_class,
                model = item.model,
                sort_order = tonumber(item.sort_order),
            })
        end

        table.insert(data.categories, catData)
    end

    return data
end
