"""Monde voxel : chunks 16x64x16, génération procédurale, biomes, caves, arbres, minerais."""
import math

from . import blocks as B
from .noise import WorldNoise

CHUNK_SIZE = 16
CHUNK_HEIGHT = 64
SEA_LEVEL = 50


class Chunk:
    __slots__ = ("cx", "cz", "blocks", "dirty")

    def __init__(self, cx, cz):
        self.cx = cx
        self.cz = cz
        self.blocks = bytearray(CHUNK_SIZE * CHUNK_HEIGHT * CHUNK_SIZE)
        self.dirty = True

    def _index(self, x, y, z):
        return (y * CHUNK_SIZE + z) * CHUNK_SIZE + x

    def get(self, x, y, z):
        if not (0 <= y < CHUNK_HEIGHT):
            return B.AIR if y >= CHUNK_HEIGHT else B.BEDROCK
        return self.blocks[self._index(x, y, z)]

    def set(self, x, y, z, block_id):
        if 0 <= y < CHUNK_HEIGHT:
            self.blocks[self._index(x, y, z)] = block_id
            self.dirty = True


class World:
    def __init__(self, seed=1337):
        self.seed = seed
        self.noise = WorldNoise(seed)
        self.chunks = {}
        self.pending = {}

    def _chunk_coords(self, wx, wz):
        return (math.floor(wx / CHUNK_SIZE), math.floor(wz / CHUNK_SIZE))

    def get_chunk(self, cx, cz, generate=True):
        key = (cx, cz)
        chunk = self.chunks.get(key)
        if chunk is None and generate:
            chunk = Chunk(cx, cz)
            self.chunks[key] = chunk
            self._generate(chunk)
        return chunk

    def get_block(self, wx, wy, wz):
        cx, cz = self._chunk_coords(wx, wz)
        chunk = self.get_chunk(cx, cz)
        if chunk is None:
            return B.BEDROCK if wy <= 0 else B.AIR
        return chunk.get(wx - cx * CHUNK_SIZE, wy, wz - cz * CHUNK_SIZE)

    def get_block_no_generate(self, wx, wy, wz):
        """Lecture sans déclencher la génération (pour la phase de génération)."""
        cx, cz = self._chunk_coords(wx, wz)
        chunk = self.chunks.get((cx, cz))
        if chunk is None:
            return B.BEDROCK if wy <= 0 else B.AIR
        return chunk.get(wx - cx * CHUNK_SIZE, wy, wz - cz * CHUNK_SIZE)

    def set_block(self, wx, wy, wz, block_id):
        if wy < 0 or wy >= CHUNK_HEIGHT:
            return False
        cx, cz = self._chunk_coords(wx, wz)
        chunk = self.chunks.get((cx, cz))
        if chunk is None:
            self.pending.setdefault((cx, cz), {})[(wx - cx * CHUNK_SIZE, wy, wz - cz * CHUNK_SIZE)] = block_id
            return True
        chunk.set(wx - cx * CHUNK_SIZE, wy, wz - cz * CHUNK_SIZE, block_id)
        return True

    def surface_height(self, wx, wz):
        for y in range(CHUNK_HEIGHT - 1, -1, -1):
            b = self.get_block(wx, y, wz)
            if B.is_solid(b) and b != B.WATER:
                return y
        return SEA_LEVEL

    def _generate(self, chunk):
        cx, cz = chunk.cx, chunk.cz
        base_x = cx * CHUNK_SIZE
        base_z = cz * CHUNK_SIZE
        for lx in range(CHUNK_SIZE):
            for lz in range(CHUNK_SIZE):
                wx = base_x + lx
                wz = base_z + lz
                h = self.noise.height_at(wx, wz)
                biome = self.noise.biome_at(wx, wz)
                top = B.GRASS if biome not in ("desert", "snow") else (B.SAND if biome == "desert" else B.DIRT)
                for y in range(CHUNK_HEIGHT):
                    block = B.AIR
                    if y == 0:
                        block = B.BEDROCK
                    elif y <= h - 4:
                        block = B.STONE
                    elif y < h:
                        block = B.DIRT if biome != "desert" else B.SAND
                    elif y == h:
                        block = top
                    elif y <= SEA_LEVEL:
                        block = B.WATER
                    chunk.set(lx, y, lz, block)

        self._carve_caves(chunk, base_x, base_z)
        self._place_ores(chunk, base_x, base_z)
        self._grow_trees(chunk, base_x, base_z)
        for (lx, y, lz), block_id in self.pending.pop((cx, cz), {}).items():
            chunk.set(lx, y, lz, block_id)
        chunk.dirty = True

    def _carve_caves(self, chunk, base_x, base_z):
        for lx in range(CHUNK_SIZE):
            for lz in range(CHUNK_SIZE):
                wx, wz = base_x + lx, base_z + lz
                h = self.noise.height_at(wx, wz)
                for y in range(2, min(h - 2, 55)):
                    if self.noise.cave_at(wx, y, wz):
                        chunk.set(lx, y, lz, B.AIR)

    def _place_ores(self, chunk, base_x, base_z):
        ore_specs = [
            (B.COAL_ORE, 0.05, 20, 58), (B.COAL_ORE_DEEP, 0.03, 4, 20),
            (B.IRON_ORE, 0.03, 8, 42), (B.IRON_ORE_DEEP, 0.02, 2, 12),
            (B.GOLD_ORE, 0.015, 4, 30), (B.DIAMOND_ORE, 0.008, 2, 16),
        ]
        seed = self.seed
        for lx in range(CHUNK_SIZE):
            for lz in range(CHUNK_SIZE):
                wx, wz = base_x + lx, base_z + lz
                for ore, chance, ymin, ymax in ore_specs:
                    for y in range(ymin, ymax):
                        if chunk.get(lx, y, lz) != B.STONE:
                            continue
                        h = (wx * 73856093) ^ (wz * 19349663) ^ (y * 83492791) ^ (seed * 2654435761) ^ (ore * 97531)
                        if (h & 0xFFFF) / 65535.0 < chance:
                            chunk.set(lx, y, lz, ore)

    def _grow_trees(self, chunk, base_x, base_z):
        """Arbres générés avec porte-à-faux sur les chunks voisins (feuilles).
        Chaque chunk ne plante que les arbres dont le tronc est DANS le chunk,
        pour éviter les doublons entre chunks voisins."""
        for lx in range(CHUNK_SIZE):
            for lz in range(CHUNK_SIZE):
                wx, wz = base_x + lx, base_z + lz
                h = self.noise.height_at(wx, wz)
                surface = chunk.get(lx, h, lz)
                if surface != B.GRASS:
                    continue
                if not (2 <= h < CHUNK_HEIGHT - 8):
                    continue
                biome = self.noise.biome_at(wx, wz)
                if biome != "plains" or not self.noise.tree_at(wx, wz, h):
                    continue
                self._plant_tree(wx, h + 1, wz)

    def _plant_tree(self, wx, base_y, wz):
        trunk_h = 4 + ((wx * 73856093 ^ wz * 19349663 ^ self.seed) >> 8) % 3
        for dy in range(trunk_h):
            self.set_block(wx, base_y + dy, wz, B.WOOD)
        top_y = base_y + trunk_h
        for dy in (-1, 0):
            for dx in range(-2, 3):
                for dz in range(-2, 3):
                    if abs(dx) == 2 and abs(dz) == 2:
                        continue
                    if self.get_block_no_generate(wx + dx, top_y + dy, wz + dz) == B.AIR:
                        self.set_block(wx + dx, top_y + dy, wz + dz, B.LEAVES)
        for dx in (-1, 0, 1):
            for dz in (-1, 0, 1):
                if self.get_block_no_generate(wx + dx, top_y + 1, wz + dz) == B.AIR:
                    self.set_block(wx + dx, top_y + 1, wz + dz, B.LEAVES)
        if self.get_block_no_generate(wx, top_y + 2, wz) == B.AIR:
            self.set_block(wx, top_y + 2, wz, B.LEAVES)

    def unload_far(self, center_cx, center_cz, radius=10):
        for key in list(self.chunks.keys()):
            if abs(key[0] - center_cx) > radius or abs(key[1] - center_cz) > radius:
                del self.chunks[key]
