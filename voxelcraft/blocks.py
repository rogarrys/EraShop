"""Registre des blocs et leurs propriétés."""

AIR = 0
DIRT = 1
GRASS = 2
STONE = 3
COBBLESTONE = 4
WOOD = 5
PLANKS = 6
LEAVES = 7
SAND = 8
WATER = 9
GLASS = 10
COAL_ORE = 11
IRON_ORE = 12
GOLD_ORE = 13
DIAMOND_ORE = 14
COAL_ORE_DEEP = 15
IRON_ORE_DEEP = 16
BEDROCK = 17
TORCH = 18
CRAFTING_TABLE = 19
FURNACE = 20
WOOD_PICKAXE = 21
STONE_PICKAXE = 22
IRON_PICKAXE = 23
DIAMOND_PICKAXE = 24
WOOD_AXE = 25
STONE_AXE = 26
IRON_AXE = 27
WOOD_SWORD = 28
STONE_SWORD = 29
IRON_SWORD = 30
DIAMOND_SWORD = 31
STICK = 32
COAL = 33
IRON_INGOT = 34
GOLD_INGOT = 35
DIAMOND = 36
APPLE = 37
BREAD = 38
COOKED_BEEF = 39
ARROW = 40
BOW = 41
TORCH_ITEM = 42


class BlockInfo:
    def __init__(self, id, name, solid=True, transparent=False, liquid=False,
                 hardness=1.0, tool="hand", light=0, color=(200, 200, 200),
                 drops=None, stackable=True, food=0):
        self.id = id
        self.name = name
        self.solid = solid
        self.transparent = transparent
        self.liquid = liquid
        self.hardness = hardness
        self.tool = tool
        self.light = light
        self.color = color
        self.drops = drops if drops is not None else [(id, 1)]
        self.stackable = stackable
        self.food = food


REGISTRY = {
    AIR: BlockInfo(AIR, "air", solid=False, transparent=True, hardness=0.0, drops=[], color=(0, 0, 0)),
    DIRT: BlockInfo(DIRT, "dirt", hardness=0.5, color=(134, 96, 67), drops=[(DIRT, 1)]),
    GRASS: BlockInfo(GRASS, "grass", hardness=0.6, color=(91, 145, 54), drops=[(DIRT, 1)]),
    STONE: BlockInfo(STONE, "stone", hardness=1.5, tool="pickaxe", color=(128, 128, 128), drops=[(COBBLESTONE, 1)]),
    COBBLESTONE: BlockInfo(COBBLESTONE, "cobblestone", hardness=2.0, tool="pickaxe", color=(110, 110, 110)),
    WOOD: BlockInfo(WOOD, "wood", hardness=2.0, tool="axe", color=(101, 75, 45)),
    PLANKS: BlockInfo(PLANKS, "planks", hardness=2.0, tool="axe", color=(183, 141, 90)),
    LEAVES: BlockInfo(LEAVES, "leaves", hardness=0.2, tool="hoe", transparent=True, color=(47, 111, 38),
                      drops=[]),
    SAND: BlockInfo(SAND, "sand", hardness=0.5, color=(237, 223, 179)),
    WATER: BlockInfo(WATER, "water", solid=False, transparent=True, liquid=True, hardness=100.0,
                     drops=[], color=(50, 100, 220)),
    GLASS: BlockInfo(GLASS, "glass", transparent=True, hardness=0.3, color=(200, 240, 255)),
    COAL_ORE: BlockInfo(COAL_ORE, "coal_ore", hardness=3.0, tool="pickaxe", color=(90, 90, 100),
                        drops=[(COAL, 1)]),
    IRON_ORE: BlockInfo(IRON_ORE, "iron_ore", hardness=3.0, tool="pickaxe", color=(160, 130, 110),
                        drops=[(IRON_ORE, 1)]),
    GOLD_ORE: BlockInfo(GOLD_ORE, "gold_ore", hardness=3.0, tool="pickaxe", color=(200, 170, 60),
                        drops=[(GOLD_ORE, 1)]),
    DIAMOND_ORE: BlockInfo(DIAMOND_ORE, "diamond_ore", hardness=3.0, tool="pickaxe", color=(100, 200, 220),
                           drops=[(DIAMOND, 1)]),
    COAL_ORE_DEEP: BlockInfo(COAL_ORE_DEEP, "coal_ore_deep", hardness=4.0, tool="pickaxe", color=(70, 70, 85),
                             drops=[(COAL, 2)]),
    IRON_ORE_DEEP: BlockInfo(IRON_ORE_DEEP, "iron_ore_deep", hardness=4.0, tool="pickaxe", color=(150, 115, 95),
                             drops=[(IRON_ORE, 2)]),
    BEDROCK: BlockInfo(BEDROCK, "bedrock", hardness=float("inf"), color=(40, 40, 40), drops=[]),
    TORCH: BlockInfo(TORCH, "torch", solid=False, hardness=0.0, light=14, color=(255, 200, 80), drops=[(TORCH_ITEM, 1)]),
    CRAFTING_TABLE: BlockInfo(CRAFTING_TABLE, "crafting_table", hardness=2.5, tool="axe", color=(150, 110, 70)),
    FURNACE: BlockInfo(FURNACE, "furnace", hardness=3.5, tool="pickaxe", color=(110, 110, 110)),
    WOOD_PICKAXE: BlockInfo(WOOD_PICKAXE, "wood_pickaxe", hardness=0.0, tool="hand", stackable=False, color=(140, 100, 60)),
    STONE_PICKAXE: BlockInfo(STONE_PICKAXE, "stone_pickaxe", hardness=0.0, stackable=False, color=(120, 120, 120)),
    IRON_PICKAXE: BlockInfo(IRON_PICKAXE, "iron_pickaxe", hardness=0.0, stackable=False, color=(200, 200, 210)),
    DIAMOND_PICKAXE: BlockInfo(DIAMOND_PICKAXE, "diamond_pickaxe", hardness=0.0, stackable=False, color=(120, 230, 220)),
    WOOD_AXE: BlockInfo(WOOD_AXE, "wood_axe", hardness=0.0, stackable=False, color=(140, 100, 60)),
    STONE_AXE: BlockInfo(STONE_AXE, "stone_axe", hardness=0.0, stackable=False, color=(120, 120, 120)),
    IRON_AXE: BlockInfo(IRON_AXE, "iron_axe", hardness=0.0, stackable=False, color=(200, 200, 210)),
    WOOD_SWORD: BlockInfo(WOOD_SWORD, "wood_sword", hardness=0.0, stackable=False, color=(160, 120, 70)),
    STONE_SWORD: BlockInfo(STONE_SWORD, "stone_sword", hardness=0.0, stackable=False, color=(130, 130, 130)),
    IRON_SWORD: BlockInfo(IRON_SWORD, "iron_sword", hardness=0.0, stackable=False, color=(210, 210, 220)),
    DIAMOND_SWORD: BlockInfo(DIAMOND_SWORD, "diamond_sword", hardness=0.0, stackable=False, color=(130, 240, 230)),
    STICK: BlockInfo(STICK, "stick", hardness=0.0, color=(120, 85, 50)),
    COAL: BlockInfo(COAL, "coal", hardness=0.0, color=(40, 40, 45)),
    IRON_INGOT: BlockInfo(IRON_INGOT, "iron_ingot", hardness=0.0, color=(215, 215, 215)),
    GOLD_INGOT: BlockInfo(GOLD_INGOT, "gold_ingot", hardness=0.0, color=(250, 215, 60)),
    DIAMOND: BlockInfo(DIAMOND, "diamond", hardness=0.0, color=(110, 240, 230)),
    APPLE: BlockInfo(APPLE, "apple", hardness=0.0, color=(220, 40, 40), food=4),
    BREAD: BlockInfo(BREAD, "bread", hardness=0.0, color=(190, 140, 80), food=5),
    COOKED_BEEF: BlockInfo(COOKED_BEEF, "cooked_beef", hardness=0.0, color=(120, 60, 40), food=8),
    ARROW: BlockInfo(ARROW, "arrow", hardness=0.0, color=(140, 110, 80)),
    BOW: BlockInfo(BOW, "bow", hardness=0.0, stackable=False, color=(150, 110, 60)),
    TORCH_ITEM: BlockInfo(TORCH_ITEM, "torch", hardness=0.0, color=(255, 200, 80)),
}

NAME_TO_ID = {info.name: bid for bid, info in REGISTRY.items()}
ID_TO_NAME = {bid: info.name for bid, info in REGISTRY.items()}

TOOL_TIER = {
    "hand": 1,
    "wood": 2,
    "stone": 3,
    "iron": 4,
    "diamond": 5,
}

TOOL_OF_ITEM = {
    WOOD_PICKAXE: ("pickaxe", "wood"), STONE_PICKAXE: ("pickaxe", "stone"),
    IRON_PICKAXE: ("pickaxe", "iron"), DIAMOND_PICKAXE: ("pickaxe", "diamond"),
    WOOD_AXE: ("axe", "wood"), STONE_AXE: ("axe", "stone"), IRON_AXE: ("axe", "iron"),
    WOOD_SWORD: ("sword", "wood"), STONE_SWORD: ("sword", "stone"),
    IRON_SWORD: ("sword", "iron"), DIAMOND_SWORD: ("sword", "diamond"),
    BOW: ("bow", "wood"),
}

SWORD_DAMAGE = {WOOD_SWORD: 4, STONE_SWORD: 5, IRON_SWORD: 6, DIAMOND_SWORD: 7}
PICKAXE_SPEED = {None: 1.0, WOOD_PICKAXE: 2.0, STONE_PICKAXE: 4.0, IRON_PICKAXE: 6.0, DIAMOND_PICKAXE: 8.0}
AXE_SPEED = {None: 1.0, WOOD_AXE: 2.0, STONE_AXE: 4.0, IRON_AXE: 6.0}

# Recettes de crafting : resultat (id, quantite) <- grille 3x3 d'ids (None = vide)
RECIPES = [
    ((PLANKS, 1), [[WOOD, None, None], [None, None, None], [None, None, None]]),
    ((STICK, 4), [[PLANKS, None, None], [PLANKS, None, None], [None, None, None]]),
    ((TORCH_ITEM, 4), [[COAL, None, None], [STICK, None, None], [None, None, None]]),
    ((CRAFTING_TABLE, 1), [[PLANKS, PLANKS, None], [PLANKS, PLANKS, None], [None, None, None]]),
    ((WOOD_PICKAXE, 1), [[PLANKS, PLANKS, PLANKS], [None, STICK, None], [None, STICK, None]]),
    ((WOOD_AXE, 1), [[PLANKS, PLANKS, None], [PLANKS, STICK, None], [None, STICK, None]]),
    ((WOOD_SWORD, 1), [[PLANKS, None, None], [PLANKS, None, None], [STICK, None, None]]),
    ((COBBLESTONE, 1), [[STONE, None, None], [None, None, None], [None, None, None]]),
    ((STONE_PICKAXE, 1), [[COBBLESTONE, COBBLESTONE, COBBLESTONE], [None, STICK, None], [None, STICK, None]]),
    ((STONE_AXE, 1), [[COBBLESTONE, COBBLESTONE, None], [COBBLESTONE, STICK, None], [None, STICK, None]]),
    ((STONE_SWORD, 1), [[COBBLESTONE, None, None], [COBBLESTONE, None, None], [STICK, None, None]]),
    ((FURNACE, 1), [[COBBLESTONE, COBBLESTONE, COBBLESTONE], [COBBLESTONE, None, COBBLESTONE], [COBBLESTONE, COBBLESTONE, COBBLESTONE]]),
    ((GLASS, 1), [[SAND, None, None], [None, None, None], [None, None, None]]),
    ((IRON_PICKAXE, 1), [[IRON_INGOT, IRON_INGOT, IRON_INGOT], [None, STICK, None], [None, STICK, None]]),
    ((IRON_AXE, 1), [[IRON_INGOT, IRON_INGOT, None], [IRON_INGOT, STICK, None], [None, STICK, None]]),
    ((IRON_SWORD, 1), [[IRON_INGOT, None, None], [IRON_INGOT, None, None], [STICK, None, None]]),
    ((DIAMOND_PICKAXE, 1), [[DIAMOND, DIAMOND, DIAMOND], [None, STICK, None], [None, STICK, None]]),
    ((DIAMOND_SWORD, 1), [[DIAMOND, None, None], [DIAMOND, None, None], [STICK, None, None]]),
    ((BOW, 1), [[None, STICK, STICK], [STICK, None, STICK], [None, STICK, STICK]]),
    ((ARROW, 4), [[None, STICK, None], [None, STICK, None], [STICK, STICK, None]]),
    ((BREAD, 1), [[PLANKS, PLANKS, PLANKS], [None, None, None], [None, None, None]]),
]

SMELTING = {
    IRON_ORE: IRON_INGOT,
    GOLD_ORE: GOLD_INGOT,
    IRON_ORE_DEEP: IRON_INGOT,
    SAND: GLASS,
    COBBLESTONE: STONE,
    WOOD: COAL,
}


def info(block_id):
    return REGISTRY.get(block_id, REGISTRY[AIR])


def is_solid(block_id):
    return info(block_id).solid


def is_transparent(block_id):
    return info(block_id).transparent


def can_place_against(block_id):
    return info(block_id).solid
