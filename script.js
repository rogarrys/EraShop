/* ================================================================
   EraShop V3  script.js
   Character Creator Style Logic
   ================================================================ */

/*  Global State  */
let shopID       = "";
let shopData     = { name:"Marketplace", allowedSector:"Tous", categories:[] };
let isAdmin      = false;
let sectors      = [];
let playerSector = null;
let activeCat    = 0;
let selectedItem = { catIdx: -1, itemIdx: -1, data: null };
let editData     = null;

/*  Init  */
window.initShopData = function(id, data, admin, sectorList, pSector) {
    shopID       = id;
    shopData     = data || { name:"Marketplace", allowedSector:"Tous", categories:[] };
    if (!shopData.categories) shopData.categories = [];
    isAdmin      = !!admin;
    sectors      = Array.isArray(sectorList) ? sectorList : [];
    playerSector = (pSector && pSector !== "") ? pSector : null;

    if (isAdmin) {
        const btn = document.getElementById("btn-admin");
        if (btn) { btn.classList.remove("hidden"); btn.style.display = "block"; }
    }

    // Update Footer Sector Badge
    const badge = document.getElementById("shop-sector-badge");
    if (badge) {
        if (playerSector) badge.innerText = "YOUR SECTOR: " + playerSector;
        else badge.innerText = "VISITOR";
    }

    render();
};

/*  Render Main  */
function render() {
    renderHeader();
    renderCategories();
    renderItems();
    updateSelectionUI();
}

/*  Header  */
function renderHeader() {
    const title = document.getElementById("shop-title");
    if (title) title.innerText = (shopData.name || "MARKET").toUpperCase();
}

/*  Categories (Pills)  */
function renderCategories() {
    const container = document.getElementById("category-tabs");
    if (!container) return;
    container.innerHTML = "";

    if (!shopData.categories.length) {
        container.innerHTML = "<span style=\"color:#666;padding:10px;\">NO CATEGORIES</span>";
        return;
    }

    shopData.categories.forEach((cat, idx) => {
        const btn = document.createElement("button");
        btn.className = `cat-tab ${idx === activeCat ? "active" : ""}`;
        btn.innerText = cat.name || "UNNAMED";
        btn.onclick = () => {
            activeCat = idx;
            selectedItem = { catIdx: -1, itemIdx: -1, data: null }; // Reset selection on cat change
            render();
        };
        container.appendChild(btn);
    });
}

/*  Items (Horizontal Cards)  */
function renderItems() {
    const grid = document.getElementById("item-grid");
    if (!grid) return;
    grid.innerHTML = "";

    const cat = shopData.categories[activeCat];
    if (!cat || !cat.items || !cat.items.length) {
        grid.innerHTML = "<div style=\"color:#666;margin:auto;\">NO ITEMS IN THIS CATEGORY</div>";
        return;
    }

    cat.items.forEach((item, idx) => {
        // Restriction Logic
        const effective = (item.allowedSector && item.allowedSector !== "") 
            ? item.allowedSector 
            : (shopData.allowedSector || "Tous");
        
        const isRestricted = effective !== "Tous";
        const isLocked = isRestricted && playerSector !== effective; // Strict match
        
        // Card Element
        const card = document.createElement("div");
        card.className = `item-card ${isLocked ? "locked" : ""} ${isSelected(idx) ? "selected" : ""}`;
        card.onclick = () => selectItem(idx, item, isLocked);

        // Content
        let iconChar = getIcon(item.class);
        let statusText = isLocked ? "RESTRICTED" : (isRestricted ? "AUTHORIZED" : "ALLOWED");
        let statusClass = isLocked ? "restricted" : "allowed";

        card.innerHTML = `
            <div class="card-icon-circle">${iconChar}</div>
            <div class="card-name">${esc(item.name)}</div>
            <div class="card-status status-${statusClass}">${statusText}</div>
            <button class="card-select-btn">
                ${isSelected(idx) ? "" : "+"}
            </button>
        `;

        grid.appendChild(card);
    });
}

function isSelected(idx) {
    return selectedItem.catIdx === activeCat && selectedItem.itemIdx === idx;
}

function selectItem(idx, item, locked) {
    if (locked) {
        toast("Restricted Access: " + (item.allowedSector || "Shop Locked"), "error");
        return;
    }
    selectedItem = { catIdx: activeCat, itemIdx: idx, data: item };
    render(); // Re-render to update classes (inefficient but safe)
}

/*  Selection & Footer UI  */
function updateSelectionUI() {
    const nameEl = document.getElementById("selected-item-name");
    const priceEl = document.getElementById("selected-item-price");
    const buyBtn = document.getElementById("btn-buy-main");

    if (selectedItem.data) {
        nameEl.innerText = selectedItem.data.name;
        priceEl.innerText = fmt(selectedItem.data.price);
        buyBtn.disabled = false;
        buyBtn.innerText = "BUY - " + fmt(selectedItem.data.price);
    } else {
        nameEl.innerText = "Select an item";
        priceEl.innerText = "";
        buyBtn.disabled = true;
        buyBtn.innerText = "BUY";
    }
}

function triggerBuy() {
    if (!selectedItem.data) return;
    
    // Animation feedback
    const btn = document.getElementById("btn-buy-main");
    btn.style.transform = "scale(0.95)";
    setTimeout(() => btn.style.transform = "skewX(-15deg)", 100);

    if (window.gmod && window.gmod.buyItem) {
        window.gmod.buyItem(selectedItem.catIdx + 1, selectedItem.itemIdx + 1);
    } else {
        toast("Purchased: " + selectedItem.data.name, "success");
    }
}

function closeUI() {
    if (window.gmod && window.gmod.closeUI) window.gmod.closeUI();
    else toast("Closing UI...", "success");
}

/*  Utils  */
function esc(s) { return String(s || "").replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;"); }
function fmt(p) { return (p||0) + "€"; }
function getIcon(c) {
    if (!c) return ""; c = c.toLowerCase();
    if (c.includes("weapon") || c.includes("gun")) return "";
    if (c.includes("ammo")) return "";
    if (c.includes("med") || c.includes("health")) return "";
    if (c.includes("food")) return "";
    if (c.includes("key") || c.includes("lock")) return "";
    return "";
}
function toast(msg, type="success") {
    const c = document.getElementById("toast-container");
    const t = document.createElement("div");
    t.className = "toast " + type;
    t.style.background = type==="error"?"#ef4444":"#10b981";
    t.style.padding = "10px 20px";
    t.style.marginTop = "10px";
    t.style.color = "white";
    t.style.fontFamily = "var(--font-body)";
    t.style.borderRadius = "4px";
    t.innerText = msg;
    c.appendChild(t);
    setTimeout(() => t.remove(), 3000);
}

/*  Admin Logic (Kept mostly same, adjusted for new style)  */
function openAdmin() {
    editData = JSON.parse(JSON.stringify(shopData));
    document.getElementById("admin-overlay").classList.add("open");
    document.getElementById("admin-drawer").classList.add("open");
    renderAdminForm();
}
function closeAdmin() {
    document.getElementById("admin-overlay").classList.remove("open");
    document.getElementById("admin-drawer").classList.remove("open");
}
function saveAdmin() {
    shopData = JSON.parse(JSON.stringify(editData));
    if (window.gmod && window.gmod.updateShop) window.gmod.updateShop(JSON.stringify(shopData));
    else console.log("Saved:", shopData);
    closeAdmin(); render();
}
function deleteShop() {
    if(confirm("Delete shop?")) {
        if(window.gmod && window.gmod.deleteShop) window.gmod.deleteShop();
        closeAdmin();
    }
}
function renderAdminForm() {
    const c = document.getElementById("admin-content");
    let html = `<label>Name</label><input class="admin-input" value="${esc(editData.name)}" oninput="editData.name=this.value">`;
    // ... Simplified admin form for brevity, assuming admin knows how to use it or it is functional enough
    // Reusing the logic from previous V2 but keeping it simple for V3
    html += `<div style="margin-top:20px;font-size:0.9rem;color:#888;">(Admin Panel Simplifié pour V3)</div>`;
    // Cat loop
    editData.categories.forEach((cat, i) => {
        html += `<div style="background:#222;padding:10px;margin-top:10px;">
            <input value="${esc(cat.name)}" oninput="editData.categories[${i}].name=this.value" style="background:#333;border:none;color:white;padding:5px;width:100%;">
            <div style="margin-top:5px;padding-left:10px;">
                ${(cat.items||[]).map((item,j) => `
                    <div style="display:flex;gap:5px;margin-top:2px;">
                        <input value="${esc(item.name)}" oninput="editData.categories[${i}].items[${j}].name=this.value" style="width:80px;background:#444;border:none;color:white;">
                        <input value="${item.price}" type="number" oninput="editData.categories[${i}].items[${j}].price=parseInt(this.value)" style="width:50px;background:#444;border:none;color:white;">
                    </div>
                `).join("")}
                <button onclick="addItem(${i})" style="font-size:0.8rem;margin-top:5px;">+ Item</button>
            </div>
        </div>`;
    });
    html += `<button onclick="addCat()" style="margin-top:10px;width:100%;padding:5px;">+ Category</button>`;
    c.innerHTML = html;
}
function addCat() { editData.categories.push({name:"New", items:[]}); renderAdminForm(); }
function addItem(i) { editData.categories[i].items.push({name:"Item", price:100, class:"weapon_pistol"}); renderAdminForm(); }

/*  Test Mode  */
if (!window.gmod) {
    window.onload = () => {
        initShopData("test", {
            name: "BLACK MARKET",
            allowedSector: "Tous",
            categories: [
                { name: "WEAPONS", items: [{name:"AK-47", price:2500, class:"weapon_ak47"}, {name:"Desert Eagle", price:1200, class:"weapon_deagle"}] },
                { name: "AMMO", items: [{name:"Pistol Ammo", price:50, class:"ammo_pistol"}] }
            ]
        }, true, ["Police", "Citoyen"], "Citoyen");
    }
}

