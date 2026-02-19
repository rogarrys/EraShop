// State
let currentShopID = "";
let shopData = { name: "Boutique", allowedSector: "Tous", categories: [] };
let isAdmin = false;
let availableSectors = ["Tous"];
let activeCategoryIndex = 0;
let editingData = null;

// Initialize from GMod
window.initShopData = function(shopID, data, adminStatus, sectors) {
    currentShopID = shopID;
    shopData = data || { name: "Boutique", allowedSector: "Tous", categories: [] };
    if (!shopData.categories) shopData.categories = [];
    isAdmin = adminStatus;
    
    availableSectors = ["Tous"];
    if (sectors && Array.isArray(sectors)) {
        availableSectors = availableSectors.concat(sectors);
    }

    if (isAdmin) {
        document.getElementById('btn-admin').classList.remove('hidden');
    }

    renderCustomerView();
};

// --- Customer View ---
function renderCustomerView() {
    document.getElementById('shop-title').innerText = shopData.name || "Boutique";
    document.getElementById('shop-sector').innerText = `Secteur requis: ${shopData.allowedSector || "Tous"}`;

    const catList = document.getElementById('category-list');
    const itemGrid = document.getElementById('item-grid');

    // Render Categories
    catList.innerHTML = '';
    if (shopData.categories.length === 0) {
        catList.innerHTML = '<p class="text-gray-500 text-center mt-4">Aucune catégorie</p>';
        itemGrid.innerHTML = '<div class="flex h-full items-center justify-center text-gray-500 text-xl">Ce shop est vide.</div>';
        return;
    }

    shopData.categories.forEach((cat, idx) => {
        const btn = document.createElement('button');
        btn.className = `category-btn w-full text-left px-4 py-3 rounded-lg mb-2 border border-gray-600 text-gray-300 hover:bg-gray-700 ${idx === activeCategoryIndex ? 'active' : ''}`;
        btn.innerText = cat.name || "Sans nom";
        btn.onclick = () => {
            activeCategoryIndex = idx;
            renderCustomerView();
        };
        catList.appendChild(btn);
    });

    // Render Items
    itemGrid.innerHTML = '';
    const activeCat = shopData.categories[activeCategoryIndex];
    if (!activeCat || !activeCat.items || activeCat.items.length === 0) {
        itemGrid.innerHTML = '<div class="flex h-full items-center justify-center text-gray-500 text-xl">Aucun objet dans cette catégorie.</div>';
        return;
    }

    const grid = document.createElement('div');
    grid.className = 'grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6';

    activeCat.items.forEach((item, idx) => {
        const card = document.createElement('div');
        card.className = 'item-card bg-gray-800 border border-gray-700 rounded-xl p-5 flex flex-col justify-between animate-fade-in';
        card.style.animationDelay = `${idx * 0.05}s`;
        
        card.innerHTML = `
            <div>
                <h3 class="text-xl font-bold text-white mb-1">${item.name || "Objet inconnu"}</h3>
                <p class="text-sm text-gray-400 mb-4 font-mono">${item.class || "unknown_class"}</p>
            </div>
            <div class="flex justify-between items-center mt-4">
                <span class="text-2xl font-extrabold text-green-400">${item.price || 0}€</span>
                <button onclick="buyItem(${activeCategoryIndex}, ${idx})" class="bg-blue-600 hover:bg-blue-500 text-white px-4 py-2 rounded-lg font-semibold transition shadow">Acheter</button>
            </div>
        `;
        grid.appendChild(card);
    });

    itemGrid.appendChild(grid);
}

// --- Actions ---
function buyItem(catIdx, itemIdx) {
    if (window.gmod && window.gmod.buyItem) {
        // Lua is 1-indexed, JS is 0-indexed
        window.gmod.buyItem(catIdx + 1, itemIdx + 1);
    } else {
        console.log(`Achat simulé: Catégorie ${catIdx + 1}, Objet ${itemIdx + 1}`);
        alert("Achat simulé (hors GMod)");
    }
}

function closeUI() {
    if (window.gmod && window.gmod.closeUI) {
        window.gmod.closeUI();
    } else {
        console.log("Fermeture de l'UI");
    }
}

// --- Admin View ---
function openAdmin() {
    // Deep copy for editing
    editingData = JSON.parse(JSON.stringify(shopData));
    document.getElementById('admin-modal').classList.remove('hidden');
    renderAdminForm();
}

function closeAdmin() {
    document.getElementById('admin-modal').classList.add('hidden');
    editingData = null;
}

function saveAdmin() {
    // Update local state
    shopData = JSON.parse(JSON.stringify(editingData));
    
    // Send to GMod
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
