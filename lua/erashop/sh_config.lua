--[[
    EraShop — Shared Configuration
    Defines the global namespace, NPC models, and constants.
    Reads sector data from EraCompanies when available.
]]

EraShop = EraShop or {}
EraShop.Config = EraShop.Config or {}

-- ─── Web UI URL (hosted on Vercel) ───
EraShop.Config.WebURL = "https://era-shop.vercel.app/index.html"

-- ─── NPC Models available for shop NPCs ───
EraShop.Config.NPCModels = {
    "models/humans/group01/male_01.mdl",
    "models/humans/group01/male_02.mdl",
    "models/humans/group01/male_03.mdl",
    "models/humans/group01/male_04.mdl",
    "models/humans/group01/male_05.mdl",
    "models/humans/group01/male_06.mdl",
    "models/humans/group01/male_07.mdl",
    "models/humans/group01/male_08.mdl",
    "models/humans/group01/male_09.mdl",
    "models/humans/group02/male_01.mdl",
    "models/humans/group02/male_02.mdl",
    "models/humans/group02/male_03.mdl",
    "models/humans/group02/male_04.mdl",
    "models/humans/group02/male_05.mdl",
    "models/humans/group02/male_06.mdl",
    "models/humans/group02/male_07.mdl",
    "models/humans/group02/male_08.mdl",
    "models/humans/group02/male_09.mdl",
    "models/humans/group01/female_01.mdl",
    "models/humans/group01/female_02.mdl",
    "models/humans/group01/female_03.mdl",
    "models/humans/group01/female_04.mdl",
    "models/humans/group01/female_06.mdl",
    "models/humans/group01/female_07.mdl",
}

EraShop.Config.DefaultNPCModel = "models/humans/group01/male_07.mdl"

-- ─── Interaction distance (units) ───
EraShop.Config.InteractDistance = 200

-- ─── Anti-spam cooldown (seconds) ───
EraShop.Config.Cooldown = 1

-- ─── Fallback sectors if EraCompanies is not loaded ───
EraShop.Config.FallbackSectors = {
    "Commerçant",
    "Mécano",
    "Restaurateur",
    "Sécurité",
    "Transport",
    "Médical",
    "Artisan",
    "Légal",
    "Autre",
}

-- ─── Helper: Get sectors from EraCompanies or fallback ───
function EraShop.GetSectors()
    if EraCompanies and EraCompanies.Config and EraCompanies.Config.Sectors then
        return EraCompanies.Config.Sectors
    end
    return EraShop.Config.FallbackSectors
end

-- ─── Helper: Get player's company sector ───
function EraShop.GetPlayerSector(ply)
    if not IsValid(ply) then return nil end
    if SERVER and EraCompanies and EraCompanies.Perm and EraCompanies.Perm.GetPlayerCompany then
        local company = EraCompanies.Perm.GetPlayerCompany(ply)
        if company then
            return company.sector
        end
    end
    return nil
end

-- ─── Helper: Get player's company info ───
function EraShop.GetPlayerCompanyInfo(ply)
    if not IsValid(ply) then return nil end
    if SERVER and EraCompanies and EraCompanies.Perm and EraCompanies.Perm.GetPlayerCompany then
        local company, mem = EraCompanies.Perm.GetPlayerCompany(ply)
        if company then
            return {
                id = tonumber(company.id),
                name = company.name,
                sector = company.sector,
            }
        end
    end
    return nil
end
