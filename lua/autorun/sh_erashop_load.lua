--[[
    EraShop — Shared Loader
    Loads all shared files and includes server/client files.
    Depends on EraCompanies for company sector data.
]]

print("[EraShop] Autorun loading...")

-- Shared
AddCSLuaFile("erashop/sh_config.lua")
include("erashop/sh_config.lua")

if SERVER then
    print("[EraShop] SERVER: Loading server files...")

    -- Server files
    include("erashop/server/sv_database.lua")
    include("erashop/server/sv_net.lua")

    -- Client files to send
    AddCSLuaFile("erashop/client/cl_state.lua")
    AddCSLuaFile("erashop/client/cl_net.lua")
    AddCSLuaFile("erashop/client/cl_menu.lua")

    print("[EraShop] SERVER: All files loaded.")
end

if CLIENT then
    print("[EraShop] CLIENT: Loading client files...")

    include("erashop/client/cl_state.lua")
    include("erashop/client/cl_net.lua")
    include("erashop/client/cl_menu.lua")

    print("[EraShop] CLIENT: All files loaded.")
end
