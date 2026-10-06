"""Sauvegarde/chargement du monde et du joueur en JSON."""
import json
import os

from . import blocks as B
from .inventory import Inventory
from .world import World, CHUNK_SIZE

SAVE_VERSION = 1


def save_game(path, world, player, inventory, time_of_day, seed=None):
    data = {
        "version": SAVE_VERSION,
        "seed": world.seed if seed is None else seed,
        "time": time_of_day,
        "player": {
            "x": player.x, "y": player.y, "z": player.z,
            "hp": getattr(player, "hp", 20),
            "hunger": getattr(player, "hunger", 20),
        },
        "inventory": inventory.to_dict(),
        "modified_chunks": {},
    }
    for (cx, cz), chunk in world.chunks.items():
        if chunk.dirty:
            data["modified_chunks"][f"{cx},{cz}"] = list(chunk.blocks)
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f)
    return path


def load_game(path, world=None):
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    if data.get("version") != SAVE_VERSION:
        raise ValueError("Version de sauvegarde incompatible")
    seed = data["seed"]
    world = world or World(seed=seed)
    for key, blocks in data.get("modified_chunks", {}).items():
        cx, cz = (int(v) for v in key.split(","))
        chunk = world.get_chunk(cx, cz)
        chunk.blocks = bytearray(blocks)
        chunk.dirty = False
    player_data = data.get("player", {})
    inventory = Inventory.from_dict(data.get("inventory", {"slots": [], "selected": 0}))
    return {
        "seed": seed,
        "time": data.get("time", 6000),
        "player": player_data,
        "inventory": inventory,
        "world": world,
    }


def list_saves(directory):
    if not os.path.isdir(directory):
        return []
    saves = []
    for name in sorted(os.listdir(directory)):
        if name.endswith(".json"):
            saves.append(os.path.join(directory, name))
    return saves
