"""Inventaire joueur, crafting 3x3, fourneau (smelting), barre de raccourcis."""
from . import blocks as B

HOTBAR_SIZE = 9
INVENTORY_SIZE = 36


def _normalize_grid(grid):
    """Supprime les lignes/colonnes vides de bordure d'une grille de craft."""
    rows = [list(row) for row in grid]
    while rows and all(c is None for c in rows[0]):
        rows.pop(0)
    while rows and all(c is None for c in rows[-1]):
        rows.pop()
    if not rows:
        return []
    while all(row[0] is None for row in rows):
        for row in rows:
            row.pop(0)
    while all(row[-1] is None for row in rows):
        for row in rows:
            row.pop()
    return rows


def find_recipe(grid):
    """grid : liste de 3 listes de 3 ids (None = vide). Retourne (result_id, qty) ou None."""
    norm = _normalize_grid(grid)
    if not norm:
        return None
    h = len(norm)
    w = len(norm[0])
    for (result, qty), raw_pattern in B.RECIPES:
        pattern = _normalize_grid(raw_pattern)
        if (h, w) != (len(pattern), len(pattern[0])):
            continue
        if norm == pattern:
            return result, qty
    return None


TOOL_DURABILITY = {
    B.WOOD_PICKAXE: 59, B.STONE_PICKAXE: 131, B.IRON_PICKAXE: 250, B.DIAMOND_PICKAXE: 1561,
    B.WOOD_AXE: 59, B.STONE_AXE: 131, B.IRON_AXE: 250,
    B.WOOD_SWORD: 59, B.STONE_SWORD: 131, B.IRON_SWORD: 250, B.DIAMOND_SWORD: 1561,
    B.BOW: 384,
}


class Slot:
    __slots__ = ("item", "count", "durability")

    def __init__(self, item=None, count=0, durability=None):
        self.item = item
        self.count = count
        self.durability = durability if durability is not None else TOOL_DURABILITY.get(item)

    def is_empty(self):
        return self.item is None or self.count <= 0

    def add(self, item, count=1):
        """Ajoute des items. Retourne le nombre réellement ajouté."""
        if self.is_empty():
            self.item = item
            self.count = 0
            self.durability = TOOL_DURABILITY.get(item)
        if self.item != item:
            return 0
        max_stack = 1 if not B.info(item).stackable else 64
        space = max_stack - self.count
        added = min(space, count)
        self.count += added
        return added

    def take(self, count=1):
        taken = min(self.count, count)
        self.count -= taken
        if self.count <= 0:
            self.item = None
            self.count = 0
            self.durability = None
        return taken

    def damage(self, amount=1):
        if self.item in TOOL_DURABILITY:
            self.durability = (self.durability or 0) - amount
            if self.durability <= 0:
                self.take(1)
                return True
        return False

    def to_dict(self):
        return {"item": B.ID_TO_NAME.get(self.item), "count": self.count, "durability": self.durability}

    @staticmethod
    def from_dict(data):
        item = B.NAME_TO_ID.get(data["item"]) if data["item"] else None
        return Slot(item, data["count"], data.get("durability"))


class Inventory:
    def __init__(self):
        self.slots = [Slot() for _ in range(INVENTORY_SIZE)]
        self.selected = 0
        self.craft_grid = [[None, None, None] for _ in range(3)]
        self.craft_result = None

    def hotbar(self):
        return self.slots[:HOTBAR_SIZE]

    def selected_slot(self):
        return self.slots[self.selected]

    def add_item(self, item, count=1):
        """Ajoute un item, d'abord en stackant puis dans les cases vides. Retourne le reste."""
        remaining = count
        for slot in self.slots:
            if remaining <= 0:
                break
            if slot.item == item and not slot.is_empty():
                remaining -= slot.add(item, remaining)
        for slot in self.slots:
            if remaining <= 0:
                break
            if slot.is_empty():
                remaining -= slot.add(item, remaining)
        return remaining

    def count_item(self, item):
        return sum(s.count for s in self.slots if s.item == item)

    def remove_item(self, item, count=1):
        remaining = count
        for slot in self.slots:
            if remaining <= 0:
                break
            if slot.item == item:
                remaining -= slot.take(remaining)
        return count - remaining

    def has_items(self, item, count=1):
        return self.count_item(item) >= count

    def damage_tool(self, amount=1):
        """Usure l'outil sélectionné. Retourne True si l'outil casse."""
        slot = self.selected_slot()
        if slot.item is None or slot.item not in TOOL_DURABILITY:
            return False
        return slot.damage(amount)

    def craft(self):
        """Tente de crafter la grille 3x3. Retourne True si réussi."""
        found = find_recipe(self.craft_grid)
        if found is None:
            return False
        result, qty = found
        needed = {}
        for row in self.craft_grid:
            for cell in row:
                if cell is not None:
                    needed[cell] = needed.get(cell, 0) + 1
        if not all(self.has_items(item, n) for item, n in needed.items()):
            return False
        for item, n in needed.items():
            self.remove_item(item, n)
        self.add_item(result, qty)
        return True

    def smelt(self, fuel_slot_index, input_slot_index, output_slot_index):
        """Fourneau : input + fuel -> output. Retourne True si une fusion a eu lieu."""
        src = self.slots[input_slot_index]
        fuel = self.slots[fuel_slot_index]
        out = self.slots[output_slot_index]
        if src.is_empty() or fuel.is_empty() or src.item not in B.SMELTING:
            return False
        result = B.SMELTING[src.item]
        if not out.is_empty() and (out.item != result or out.count >= 64):
            return False
        fuel_value = 8 if fuel.item in (B.COAL, B.WOOD) else 0
        if fuel_value == 0:
            return False
        src.take(1)
        fuel.take(1)
        out.add(result, 1)
        return True

    def to_dict(self):
        return {
            "slots": [s.to_dict() for s in self.slots],
            "selected": self.selected,
        }

    @staticmethod
    def from_dict(data):
        inv = Inventory()
        for i, s in enumerate(data["slots"]):
            if i < INVENTORY_SIZE:
                inv.slots[i] = Slot.from_dict(s)
        inv.selected = data.get("selected", 0)
        return inv
