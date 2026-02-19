/* ================================================================
   EraShop — script.js
   Gère la vue client, l'achat, le panel admin et la restriction
   de secteur (shop-level ET per-item via EraCompanies).
   ================================================================ */

/* ── État global ──────────────────────────────────────────────── */
let shopID       = "";
let shopData     = { name:"Boutique", allowedSector:"Tous", categories:[] };
let isAdmin      = false;
let sectors      = [];
let playerSector = null;   // secteur EraCompanies du joueur connecté
let activeCat    = 0;
let editData     = null;

/* ── Initialisation (appelée par GMod via html:AddFunction) ───── */
window.initShopData = function(id, data, admin, sectorList, pSector) {
    shopID       = id;
    shopData     = data || { name:"Boutique", allowedSector:"Tous", categories:[] };
    if (!shopData.categories) shopData.categories = [];
    isAdmin      = !!admin;
    sectors      = Array.isArray(sectorList) ? sectorList : [];
    playerSector = (pSector && pSector !== "") ? pSector : null;

    if (isAdmin) {
        const btnAdmin = document.getElementById("btn-admin");
        if (btnAdmin) btnAdmin.classList.remove("hidden");
    }

    const sectorInfo = document.getElementById("player-sector-info");
    if (sectorInfo) {
        if (playerSector) {
            sectorInfo.textContent = "🏢 " + playerSector;
            sectorInfo.classList.remove("hidden");
        } else {
            sectorInfo.classList.add("hidden");
        }
    }
    
    render();
};

/* ── Rendu principal ──────────────────────────────────────────── */
function render() {
    renderHeader();
    renderCategoryTabs();
    renderItems();
}

/* ── Header ───────────────────────────────────────────────────── */
function renderHeader() {
    const titleEl = document.getElementById("shop-title");
    const badgeEl = document.getElementById("shop-sector-badge");
    
    if (titleEl) titleEl.textContent = shopData.name || "Boutique";
    
    if (badgeEl) {
        const s = shopData.allowedSector || "Tous";
        badgeEl.textContent = s === "Tous" ? "🌐 Ouvert à tous" : "🔒 " + s + " uniquement";
        badgeEl.className = "badge" + (s !== "Tous" ? " restricted" : "");
    }
}

/* ── Catégories en haut ───────────────────────────────────────── */
function renderCategoryTabs() {
    const tabs = document.getElementById("category-tabs");
    if (!tabs) return;
    
    tabs.innerHTML = "";
    if (!shopData.categories || !shopData.categories.length) {
        tabs.innerHTML = '<span style="color:var(--text3);font-size:12px;padding:8px 0;">Aucune catégorie</span>';
        return;
    }
    
    shopData.categories.forEach((cat, i) => {
        const btn = document.createElement("button");
        btn.className = "cat-tab" + (i === activeCat ? " active" : "");
        btn.innerHTML = `<span>${esc(cat.name || "?")}</span><span class="cat-count">${(cat.items||[]).length}</span>`;
        btn.onclick = () => { activeCat = i; render(); };
        tabs.appendChild(btn);
    });
}

/* ── Grille d'objets ──────────────────────────────────────────── */
function renderItems() {
    const grid = document.getElementById("item-grid");
    if (!grid) return;
    
    grid.innerHTML = "";
    const cat = shopData.categories[activeCat];
    if (!cat || !cat.items || !cat.items.length) {
        grid.innerHTML = '<div class="empty-state"><div class="ei">📦</div><p>Aucun objet dans cette catégorie</p></div>';
        return;
    }
    
    cat.items.forEach((item, i) => {
        // Restriction effective : item > shop > "Tous"
        const effective = (item.allowedSector && item.allowedSector !== "")
            ? item.allowedSector
            : (shopData.allowedSector || "Tous");

        // Verrouillé si le joueur n'est pas dans le bon secteur (et qu'on connaît son secteur)
        const locked = effective !== "Tous" && playerSector !== null && playerSector !== effective;

        const card = document.createElement("div");
        card.className = "item-card" + (locked ? " locked" : "");
        card.style.animationDelay = (i * 0.045) + "s";
        card.innerHTML = `
            <div class="card-top">
                <div class="card-icon">${getIcon(item.class)}</div>
                <div class="card-price">${fmt(item.price)}</div>
            </div>
            <div class="card-body">
                <div class="card-name">${esc(item.name || "Objet")}</div>
                <div class="card-class">${esc(item.class || "???")}</div>
                ${effective !== "Tous" ? `<div class="card-sector-tag">🔒 ${esc(effective)}</div>` : ""}
            </div>
            <div class="card-footer">
                <button class="btn-buy" ${locked ? "disabled" : ""} onclick="buyItem(${activeCat},${i})">Acheter</button>
            </div>`;
        grid.appendChild(card);
    });
}

/* ── Actions joueur ───────────────────────────────────────────── */
function buyItem(c, i) {
    if (window.gmod && window.gmod.buyItem) window.gmod.buyItem(c + 1, i + 1); // Lua 1-indexed
    else toast("Achat simulé (mode test)", "success");
}
function closeUI() {
    if (window.gmod && window.gmod.closeUI) window.gmod.closeUI();
    else toast("Fermeture simulée", "success");
}

/* ── Drawer Admin ─────────────────────────────────────────────── */
function openAdmin() {
    editData = JSON.parse(JSON.stringify(shopData));
    const overlay = document.getElementById("admin-overlay");
    const drawer = document.getElementById("admin-drawer");
    if (overlay) overlay.classList.add("open");
    if (drawer) drawer.classList.add("open");
    renderAdminForm();
}
function closeAdmin() {
    const overlay = document.getElementById("admin-overlay");
    const drawer = document.getElementById("admin-drawer");
    if (overlay) overlay.classList.remove("open");
    if (drawer) drawer.classList.remove("open");
    editData = null;
}
function saveAdmin() {
    shopData = JSON.parse(JSON.stringify(editData));
    if (window.gmod && window.gmod.updateShop) window.gmod.updateShop(JSON.stringify(shopData));
    else { toast("Sauvegardé (mode test)", "success"); console.log("[EraShop] Data:", shopData); }
    closeAdmin(); render();
}
function deleteShop() {
    if (!confirm("Supprimer ce shop définitivement ?")) return;
    if (window.gmod && window.gmod.deleteShop) window.gmod.deleteShop();
    else { toast("Shop supprimé (mode test)", "error"); closeAdmin(); }
}

/* ── Formulaire Admin ─────────────────────────────────────────── */
function renderAdminForm() {
    const adminContent = document.getElementById("admin-content");
    if (!adminContent) return;

    const allSectors = ["Tous", ...sectors];
    const globalOpts = allSectors.map(s =>
        `<option value="${s}" ${editData.allowedSector === s ? "selected" : ""}>${s === "Tous" ? "🌐 Tous les secteurs" : s}</option>`
    ).join("");

    const itemSectorOpts = (val) => {
        const list = [
            { v:"", l:"↳ Hérité du shop" },
            ...allSectors.map(s => ({ v:s, l: s === "Tous" ? "🌐 Tous" : s }))
        ];
        return list.map(o =>
            `<option value="${o.v}" ${(val === o.v || (val === undefined && o.v === "")) ? "selected" : ""}>${o.l}</option>`
        ).join("");
    };

    let html = `
        <div class="form-row">
            <div class="form-group">
                <label class="form-label">Nom du shop</label>
                <input type="text" class="form-input" value="${esc(editData.name)}" oninput="editData.name=this.value">
            </div>
            <div class="form-group">
                <label class="form-label">Secteur autorisé (global)</label>
                <select class="form-select" onchange="editData.allowedSector=this.value">${globalOpts}</select>
            </div>
        </div>
        <div class="section-label">Catégories & Objets</div>`;

    if (!editData.categories) editData.categories = [];

    editData.categories.forEach((cat, ci) => {
        html += `
        <div class="cat-block">
            <div class="cat-block-head">
                <input type="text" value="${esc(cat.name)}"
                    oninput="editData.categories[${ci}].name=this.value"
                    placeholder="Nom de la catégorie">
                <button class="btn-danger-sm" onclick="removeCat(${ci})">✕ Supprimer</button>
            </div>
            <div class="cat-block-body">`;

        if (cat.items && cat.items.length) {
            html += `
                <div class="item-col-labels">
                    <div class="item-cols">
                        <span>Nom</span><span>Classe</span><span>Prix</span><span>Secteur</span><span></span>
                    </div>
                </div>`;
            cat.items.forEach((item, ii) => {
                html += `
                <div class="item-row">
                    <div class="item-cols">
                        <input type="text" value="${esc(item.name)}"
                            oninput="editData.categories[${ci}].items[${ii}].name=this.value" placeholder="Nom">
                        <input type="text" value="${esc(item.class)}"
                            oninput="editData.categories[${ci}].items[${ii}].class=this.value"
                            placeholder="weapon_pistol"
                            style="font-family:'JetBrains Mono',monospace;font-size:10px;">
                        <input type="number" value="${item.price}"
                            oninput="editData.categories[${ci}].items[${ii}].price=parseInt(this.value)||0"
                            placeholder="0">
                        <select onchange="editData.categories[${ci}].items[${ii}].allowedSector=this.value">
                            ${itemSectorOpts(item.allowedSector)}
                        </select>
                        <button class="btn-remove-item" onclick="removeItem(${ci},${ii})">✕</button>
                    </div>
                </div>`;
            });
        } else {
            html += `<p style="font-size:12px;color:var(--text3);padding:4px 0 8px;font-style:italic;">Aucun objet.</p>`;
        }

        html += `<button class="btn-add-item" onclick="addItem(${ci})">+ Ajouter un objet</button>
            </div>
        </div>`;
    });

    html += `<button class="btn-add" style="margin-top:14px;" onclick="addCat()">+ Nouvelle catégorie</button>`;
    adminContent.innerHTML = html;
}

function addCat()         { if (!editData.categories) editData.categories = []; editData.categories.push({ name:"Nouvelle Catégorie", items:[] }); renderAdminForm(); }
function removeCat(i)     { if (confirm("Supprimer cette catégorie ?")) { editData.categories.splice(i,1); renderAdminForm(); } }
function addItem(ci)      { if (!editData.categories[ci].items) editData.categories[ci].items = []; editData.categories[ci].items.push({ name:"Nouvel Objet", class:"entity_class", price:100, allowedSector:"" }); renderAdminForm(); }
function removeItem(ci,ii){ editData.categories[ci].items.splice(ii,1); renderAdminForm(); }

/* ── Utilitaires ──────────────────────────────────────────────── */
function fmt(p) {
    if (p == null) return "?€";
    if (p >= 1e6)  return (p/1e6).toFixed(1) + "M€";
    if (p >= 1e3)  return (p/1e3).toFixed(p%1e3===0?0:1) + "k€";
    return p + "€";
}
function esc(s) {
    if (!s) return "";
    return String(s).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;");
}
function getIcon(cls) {
    if (!cls) return "📦"; cls = cls.toLowerCase();
    if (/weapon|gun|pistol|rifle|shot|smg|snip/.test(cls)) return "🔫";
    if (/knife|sword|blade|melee/.test(cls))               return "🗡️";
    if (/medic|health|med|kit|bandage/.test(cls))          return "🩹";
    if (/drug|weed|meth|cocaine/.test(cls))                return "💊";
    if (/car|vehicle|bike/.test(cls))                      return "🚗";
    if (/food|burger|pizza/.test(cls))                     return "🍔";
    if (/ammo|bullet/.test(cls))                           return "🔴";
    if (/tool|wrench|repair/.test(cls))                    return "🔧";
    if (/phone|radio/.test(cls))                           return "📱";
    if (/money|cash|wallet/.test(cls))                     return "💰";
    if (/armor|vest|helmet/.test(cls))                     return "🦺";
    return "📦";
}
function toast(msg, type = "success") {
    const c = document.getElementById("toast-container");
    if (!c) return;
    const t = document.createElement("div");
    t.className = "toast " + type;
    t.innerHTML = `<span class="toast-icon">${type==="success"?"✓":"✕"}</span><span>${msg}</span>`;
    c.appendChild(t);
    setTimeout(() => { t.style.animation = "toastIn .2s reverse"; setTimeout(()=>t.remove(),200); }, 3000);
}

/* ── Mode test local (hors GMod) ─────────────────────────────── */
if (!window.gmod) {
    console.log("[EraShop] Mode test local activé");
    setTimeout(() => window.initShopData("test_id", {
        name: "Armurerie Clandestine",
        allowedSector: "Tous",
        categories: [
            { name: "🔫 Armes Légères", items: [
                { name:"Glock 18",     class:"weapon_glock",  price:500,  allowedSector:"" },
                { name:"Desert Eagle", class:"weapon_deagle", price:1200, allowedSector:"Sécurité" },
                { name:"AK-47",        class:"weapon_ak47",   price:2500, allowedSector:"" },
                { name:"AWP",          class:"weapon_awp",    price:4500, allowedSector:"Sécurité" }
            ]},
            { name: "💊 Pharmacie", items: [
                { name:"Medkit Pro", class:"item_medkit",   price:150, allowedSector:"Médical" },
                { name:"Morphine",   class:"item_morphine", price:400, allowedSector:"" }
            ]},
            { name: "🔧 Outillage", items: [
                { name:"Clé à molette",    class:"tool_wrench",   price:75,  allowedSector:"" },
                { name:"Kit crochetage",   class:"tool_lockpick", price:300, allowedSector:"" }
            ]}
        ]
    }, true, ["Commerçant","Mécano","Sécurité","Médical","Transport"], "Sécurité"), 300);
}    // Send to GMod
    if (window.gmod && window.gmod.updateShop) {
        window.gmod.updateShop(JSON.stringify(shopData));
    } else {
        console.log("Sauvegarde simulée:", shopData);
    }
    
    closeAdmin();
    renderCustomerView();
}

function deleteShop() {
    if (confirm("Voulez-vous vraiment supprimer ce shop définitivement ?")) {
        if (window.gmod && window.gmod.deleteShop) {
            window.gmod.deleteShop();
        } else {
            console.log("Suppression simulée");
        }
    }
}

// --- Admin Form Rendering & Logic ---
function renderAdminForm() {
    const container = document.getElementById('admin-content');
    
    let html = `
        <div class="grid grid-cols-2 gap-6 mb-6">
            <div>
                <label class="block text-sm font-bold text-gray-300 mb-2">Nom du Shop</label>
                <input type="text" value="${editingData.name}" onchange="editingData.name = this.value" class="w-full bg-gray-900 border border-gray-600 text-white p-3 rounded-lg focus:outline-none focus:border-blue-500 transition">
            </div>
            <div>
                <label class="block text-sm font-bold text-gray-300 mb-2">Secteur Autorisé (EraCompanies)</label>
                <select onchange="editingData.allowedSector = this.value" class="w-full bg-gray-900 border border-gray-600 text-white p-3 rounded-lg focus:outline-none focus:border-blue-500 transition">
                    ${availableSectors.map(s => `<option value="${s}" ${editingData.allowedSector === s ? 'selected' : ''}>${s}</option>`).join('')}
                </select>
            </div>
        </div>
        
        <div class="flex justify-between items-center mb-4">
            <h3 class="text-xl font-bold text-white border-b-2 border-blue-500 pb-1 inline-block">Catégories & Objets</h3>
            <button onclick="addCategory()" class="bg-blue-600 hover:bg-blue-500 text-white px-4 py-2 rounded-lg font-semibold transition text-sm shadow">+ Nouvelle Catégorie</button>
        </div>
        
        <div class="space-y-6">
    `;

    editingData.categories.forEach((cat, cIdx) => {
        html += `
            <div class="bg-gray-900 border border-gray-700 p-5 rounded-xl shadow-inner">
                <div class="flex justify-between items-center mb-4">
                    <input type="text" value="${cat.name}" onchange="editingData.categories[${cIdx}].name = this.value" placeholder="Nom de la catégorie" class="bg-gray-800 border border-gray-600 text-white p-2 rounded-lg w-1/2 focus:outline-none focus:border-blue-500 font-bold text-lg">
                    <button onclick="removeCategory(${cIdx})" class="bg-red-600 hover:bg-red-500 text-white px-3 py-1 rounded-lg text-sm transition">Supprimer Catégorie</button>
                </div>
                
                <div class="space-y-3 pl-4 border-l-2 border-gray-600">
        `;
        
        if (!cat.items) cat.items = [];
        if (cat.items.length === 0) {
            html += `<p class="text-gray-500 text-sm italic">Aucun objet dans cette catégorie.</p>`;
        }

        cat.items.forEach((item, iIdx) => {
            html += `
                <div class="flex gap-3 items-center bg-gray-800 p-3 rounded-lg border border-gray-700">
                    <div class="flex-1">
                        <label class="text-xs text-gray-400 block mb-1">Nom de l'objet</label>
                        <input type="text" value="${item.name}" onchange="editingData.categories[${cIdx}].items[${iIdx}].name = this.value" placeholder="Ex: Pistolet" class="w-full bg-gray-900 border border-gray-600 text-white p-2 rounded focus:outline-none focus:border-blue-500 text-sm">
                    </div>
                    <div class="flex-1">
                        <label class="text-xs text-gray-400 block mb-1">Classe (Entité/Arme)</label>
                        <input type="text" value="${item.class}" onchange="editingData.categories[${cIdx}].items[${iIdx}].class = this.value" placeholder="Ex: weapon_pistol" class="w-full bg-gray-900 border border-gray-600 text-white p-2 rounded focus:outline-none focus:border-blue-500 text-sm font-mono">
                    </div>
                    <div class="w-32">
                        <label class="text-xs text-gray-400 block mb-1">Prix (€)</label>
                        <input type="number" value="${item.price}" onchange="editingData.categories[${cIdx}].items[${iIdx}].price = parseInt(this.value) || 0" placeholder="0" class="w-full bg-gray-900 border border-gray-600 text-white p-2 rounded focus:outline-none focus:border-blue-500 text-sm">
                    </div>
                    <div class="pt-5">
                        <button onclick="removeItem(${cIdx}, ${iIdx})" class="bg-red-600 hover:bg-red-500 text-white w-8 h-8 rounded flex items-center justify-center transition" title="Supprimer l'objet">✕</button>
                    </div>
                </div>
            `;
        });

        html += `
                    <div class="mt-3">
                        <button onclick="addItem(${cIdx})" class="bg-green-600 hover:bg-green-500 text-white px-3 py-1.5 rounded-lg text-sm transition shadow">+ Ajouter un objet</button>
                    </div>
                </div>
            </div>
        `;
    });

    if (editingData.categories.length === 0) {
        html += `<div class="text-center p-8 bg-gray-900 rounded-xl border border-gray-700 text-gray-500">Cliquez sur "Nouvelle Catégorie" pour commencer.</div>`;
    }

    html += `</div>`;
    container.innerHTML = html;
}

function addCategory() {
    editingData.categories.push({ name: "Nouvelle Catégorie", items: [] });
    renderAdminForm();
}

function removeCategory(cIdx) {
    if (confirm("Supprimer cette catégorie et tous ses objets ?")) {
        editingData.categories.splice(cIdx, 1);
        renderAdminForm();
    }
}

function addItem(cIdx) {
    editingData.categories[cIdx].items.push({ name: "Nouvel Objet", class: "ent_class", price: 100 });
    renderAdminForm();
}

function removeItem(cIdx, iIdx) {
    editingData.categories[cIdx].items.splice(iIdx, 1);
    renderAdminForm();
}

// For local testing without GMod
if (!window.gmod) {
    console.log("Mode test local activé.");
    setTimeout(() => {
        window.initShopData("test_id", {
            name: "Armurerie Clandestine",
            allowedSector: "Tous",
            categories: [
                {
                    name: "Armes Légères",
                    items: [
                        { name: "Glock 18", class: "weapon_glock", price: 500 },
                        { name: "Desert Eagle", class: "weapon_deagle", price: 1200 }
                    ]
                },
                {
                    name: "Munitions",
                    items: [
                        { name: "Boîte 9mm", class: "ammo_9mm", price: 50 }
                    ]
                }
            ]
        }, true, ["Commerçant", "Mécano", "Sécurité"]);
    }, 500);
}
