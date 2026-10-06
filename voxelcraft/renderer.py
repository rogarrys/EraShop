"""Rendu Ursina : maillage de chunks (greedy-ish faces visibles), textures procédurales."""
import math

from ursina import Entity, Mesh, Vec3, color as ucolor, held_keys, camera, mouse, time as utime

from . import blocks as B
from .world import CHUNK_SIZE, CHUNK_HEIGHT, World

FACES = [
    ((0, 1, 0), [(0, 1, 0), (1, 1, 0), (1, 1, 1), (0, 1, 1)]),     # haut
    ((0, -1, 0), [(0, 0, 1), (1, 0, 1), (1, 0, 0), (0, 0, 0)]),    # bas
    ((1, 0, 0), [(1, 0, 0), (1, 0, 1), (1, 1, 1), (1, 1, 0)]),     # +x
    ((-1, 0, 0), [(0, 0, 1), (0, 0, 0), (0, 1, 0), (0, 1, 1)]),    # -x
    ((0, 0, 1), [(0, 0, 1), (0, 1, 1), (1, 1, 1), (1, 0, 1)]),     # +z
    ((0, 0, -1), [(1, 0, 0), (1, 1, 0), (0, 1, 0), (0, 0, 0)]),    # -z
]


def make_texture(rgb, size=16):
    """Texture procédurale : couleur de base + variation de bruit par pixel."""
    from ursina import Texture
    from PIL import Image
    r, g, b = rgb
    img = Image.new("RGB", (size, size))
    px = img.load()
    for x in range(size):
        for y in range(size):
            n = int((math.sin(x * 12.9898 + y * 78.233) * 43758.5453 % 1) * 24)
            px[x, y] = (max(0, min(255, r + n - 12)), max(0, min(255, g + n - 12)), max(0, min(255, b + n - 12)))
    return Texture(img)


class ChunkMesh(Entity):
    """Maillage d'un chunk : seules les faces visibles (non cachées par un voisin
    solide opaque) sont générées. Les couleurs par sommet teintent chaque face
    (haut = plein jour, bas = sombre, côtés = atténués)."""
    _texture_cache = {}

    def __init__(self, world, cx, cz, parent=None):
        super().__init__(parent=parent)
        self.world = world
        self.cx = cx
        self.cz = cz
        self.chunk = world.get_chunk(cx, cz)
        self.build()

    def tex(self, block_id):
        if block_id not in ChunkMesh._texture_cache:
            ChunkMesh._texture_cache[block_id] = make_texture(B.info(block_id).color)
        return ChunkMesh._texture_cache[block_id]

    def build(self):
        chunk = self.chunk
        base_x = self.cx * CHUNK_SIZE
        base_z = self.cz * CHUNK_SIZE
        vertices = []
        uvs = []
        colors = []
        tris = []
        for lx in range(CHUNK_SIZE):
            for lz in range(CHUNK_SIZE):
                for ly in range(CHUNK_HEIGHT):
                    block = chunk.get(lx, ly, lz)
                    if block == B.AIR:
                        continue
                    for normal, corners in FACES:
                        nx, ny, nz = normal
                        wx, wy, wz = base_x + lx + nx, ly + ny, base_z + lz + nz
                        neighbor = self.world.get_block(wx, wy, wz)
                        if B.is_solid(neighbor) and not B.is_transparent(neighbor):
                            continue
                        base_v = len(vertices)
                        shade = 1.0
                        if ny == -1:
                            shade = 0.5
                        elif nx != 0:
                            shade = 0.8
                        else:
                            shade = 0.6
                        for cx_, cy_, cz_ in corners:
                            vertices.append((lx + cx_, ly + cy_, lz + cz_))
                            uvs.append(((cx_ + cz_) % 2, (cy_ + cz_ + cx_) % 2))
                            colors.append((shade, shade, shade, 1.0))
                        tris.extend([base_v, base_v + 1, base_v + 2, base_v, base_v + 2, base_v + 3])
        if vertices:
            self.model = Mesh(vertices=vertices, uvs=uvs, colors=colors, triangles=tris, mode="triangle")
            self.texture = self.tex(B.STONE)
        self.position = (base_x, 0, base_z)

    def rebuild(self):
        if self.model:
            self.model = None
        self.build()
