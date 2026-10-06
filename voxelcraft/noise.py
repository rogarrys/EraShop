"""Génération procédurale de bruit (value noise fBm, caves 3D, rivières, lacs)."""
import math
import random


class Permutation:
    """Table de permutation pseudo-aléatoire déterministe (dérivée de la seed)."""
    def __init__(self, seed):
        rng = random.Random(seed)
        self.perm = list(range(256))
        rng.shuffle(self.perm)
        self.perm = self.perm * 2


def value_noise_2d(x, y, perm, octaves=4, persistence=0.5, scale=1.0):
    """Bruit de valeur 2D fractal (fBm), normalisé dans [0, 1]."""
    total = 0.0
    amplitude = 1.0
    frequency = scale
    max_value = 0.0
    for _ in range(octaves):
        fx = x * frequency
        fy = y * frequency
        x0 = int(math.floor(fx)) & 255
        y0 = int(math.floor(fy)) & 255
        x1 = (x0 + 1) & 255
        y1 = (y0 + 1) & 255
        sx = _fade(fx - math.floor(fx))
        sy = _fade(fy - math.floor(fy))
        a = perm[perm[x0] + y0]
        b = perm[perm[x1] + y0]
        c = perm[perm[x0] + y1]
        d = perm[perm[x1] + y1]
        v = _lerp(_lerp(a, b, sx), _lerp(c, d, sx), sy) / 255.0
        total += v * amplitude
        max_value += amplitude
        amplitude *= persistence
        frequency *= 2.0
    return total / max_value


def _fade(t):
    return t * t * t * (t * (t * 6 - 15) + 10)


def _lerp(a, b, t):
    return a + t * (b - a)


def value_noise_3d(x, y, z, perm, octaves=3, persistence=0.5, scale=1.0):
    """Bruit de valeur 3D fractal, normalisé dans [0, 1]."""
    total = 0.0
    amplitude = 1.0
    frequency = scale
    max_value = 0.0
    for _ in range(octaves):
        fx, fy, fz = x * frequency, y * frequency, z * frequency
        x0 = int(math.floor(fx)) & 255
        y0 = int(math.floor(fy)) & 255
        z0 = int(math.floor(fz)) & 255
        x1, y1, z1 = (x0 + 1) & 255, (y0 + 1) & 255, (z0 + 1) & 255
        sx = _fade(fx - math.floor(fx))
        sy = _fade(fy - math.floor(fy))
        sz = _fade(fz - math.floor(fz))

        def h(xx, yy, zz):
            return perm[perm[perm[xx] + yy] + zz]

        v000 = h(x0, y0, z0)
        v100 = h(x1, y0, z0)
        v010 = h(x0, y1, z0)
        v110 = h(x1, y1, z0)
        v001 = h(x0, y0, z1)
        v101 = h(x1, y0, z1)
        v011 = h(x0, y1, z1)
        v111 = h(x1, y1, z1)
        x00 = _lerp(v000, v100, sx)
        x10 = _lerp(v010, v110, sx)
        x01 = _lerp(v001, v101, sx)
        x11 = _lerp(v011, v111, sx)
        y0v = _lerp(x00, x10, sy)
        y1v = _lerp(x01, x11, sy)
        v = _lerp(y0v, y1v, sz) / 255.0
        total += v * amplitude
        max_value += amplitude
        amplitude *= persistence
        frequency *= 2.0
    return total / max_value


class WorldNoise:
    def __init__(self, seed):
        self.seed = seed
        self.perm_height = Permutation(seed)
        self.perm_temp = Permutation(seed + 1)
        self.perm_humid = Permutation(seed + 2)
        self.perm_cave = Permutation(seed + 3)
        self.perm_ore = Permutation(seed + 4)
        self.perm_detail = Permutation(seed + 5)

    def height_at(self, wx, wz):
        """Hauteur de terrain (en blocs) pour les coordonnées monde x/z."""
        base = value_noise_2d(wx, wz, self.perm_height.perm, octaves=5, persistence=0.5, scale=1 / 90.0)
        hills = value_noise_2d(wx, wz, self.perm_detail.perm, octaves=3, persistence=0.5, scale=1 / 30.0)
        h = 40 + base * 12 + hills * hills * 10
        return int(h)

    def temperature_at(self, wx, wz):
        """Température du biome : 0 = froid (neige), 1 = chaud. Centrée sur ~0.55."""
        return 0.05 + 0.85 * value_noise_2d(wx, wz, self.perm_temp.perm, octaves=3, scale=1 / 450.0)

    def humidity_at(self, wx, wz):
        """Humidité du biome, centrée sur ~0.5."""
        return 0.05 + 0.85 * value_noise_2d(wx, wz, self.perm_humid.perm, octaves=3, scale=1 / 500.0)

    def biome_at(self, wx, wz):
        t = self.temperature_at(wx, wz)
        h = self.humidity_at(wx, wz)
        if t < 0.25:
            return "snow"
        if t < 0.45:
            return "taiga"
        if h < 0.35:
            return "desert"
        if h > 0.75 and t > 0.6:
            return "jungle"
        return "plains"

    def cave_at(self, wx, wy, wz):
        """True si la position (monde) est dans une cave (spaghetti 3D)."""
        if wy > 55 or wy < 5:
            return False
        n = value_noise_3d(wx, wy, wz, self.perm_cave.perm, octaves=2, persistence=0.5, scale=1 / 14.0)
        threshold = 0.72
        depth_fade = max(0.0, min(1.0, (55 - wy) / 25.0))
        return n > threshold + (1 - depth_fade) * 0.15

    def ore_at(self, wx, wy, wz, ore_chance=0.02):
        n = value_noise_3d(wx, wy, wz, self.perm_ore.perm, octaves=2, scale=1 / 6.0)
        return n > 1.0 - ore_chance

    def tree_at(self, wx, wz, height):
        """Décide si un arbre pousse ici (~6% des colonnes herbeuses des plaines)."""
        n = value_noise_2d(wx * 3.7 + 1000, wz * 3.7 - 500, self.perm_detail.perm, octaves=2, scale=1.0)
        return n > 0.80
