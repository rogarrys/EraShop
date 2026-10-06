"""Physique joueur : gravité, collision AABB, vol, nage, raycast pour casser/placer."""
import math

from . import blocks as B
from .world import CHUNK_HEIGHT, SEA_LEVEL

GRAVITY = 28.0
JUMP_VELOCITY = 9.0
WALK_SPEED = 4.3
SPRINT_SPEED = 5.8
FLY_SPEED = 10.0
REACH = 6.0
PLAYER_WIDTH = 0.6
PLAYER_HEIGHT = 1.8
EYE_HEIGHT = 1.62


class AABB:
    def __init__(self, x, y, z, w=PLAYER_WIDTH, h=PLAYER_HEIGHT):
        self.x = x
        self.y = y
        self.z = z
        self.w = w
        self.h = h

    def min(self):
        return (self.x - self.w / 2, self.y, self.z - self.w / 2)

    def max(self):
        return (self.x + self.w / 2, self.y + self.h, self.z + self.w / 2)

    def intersects_block(self, bx, by, bz):
        mn, mx = self.min(), self.max()
        return (mn[0] < bx + 1 and mx[0] > bx and
                mn[1] < by + 1 and mx[1] > by and
                mn[2] < bz + 1 and mx[2] > bz)

    def collides(self, world):
        mn, mx = self.min(), self.max()
        x0, x1 = int(math.floor(mn[0])), int(math.floor(mx[0]))
        y0, y1 = int(math.floor(mn[1])), int(math.floor(mx[1]))
        z0, z1 = int(math.floor(mn[2])), int(math.floor(mx[2]))
        for bx in range(x0, x1 + 1):
            for by in range(y0, y1 + 1):
                for bz in range(z0, z1 + 1):
                    b = world.get_block(bx, by, bz)
                    if B.is_solid(b) and self.intersects_block(bx, by, bz):
                        return True
        return False


class PlayerPhysics:
    def __init__(self, world, x=0.0, y=80.0, z=0.0):
        self.world = world
        self.x = x
        self.y = y
        self.z = z
        self.vx = self.vy = self.vz = 0.0
        self.on_ground = False
        self.flying = False
        self.in_water = False
        self.fall_distance = 0.0

    def _eye_block(self):
        return self.world.get_block(int(self.x), int(self.y + EYE_HEIGHT), int(self.z))

    def update(self, dt, move_input=(0, 0), jump=False, sprint=False, fly_toggle=False):
        if fly_toggle:
            self.flying = not self.flying
        in_water = self._eye_block() == B.WATER
        self.in_water = in_water

        speed = FLY_SPEED if self.flying else (SPRINT_SPEED if sprint else WALK_SPEED)
        dx, dz = move_input
        length = math.hypot(dx, dz)
        if length > 0:
            dx, dz = dx / length, dz / length
        self.vx = dx * speed
        self.vz = dz * speed

        if self.flying:
            self.vy = 5.0 if jump else 0.0
            self._move_axis(dt)
            self.fall_distance = 0.0
            self.on_ground = False
            return

        if in_water:
            self.vy -= GRAVITY * 0.3 * dt
            self.vy *= 0.9
            if jump:
                self.vy = 4.0
        else:
            self.vy -= GRAVITY * dt
            if jump and self.on_ground:
                self.vy = JUMP_VELOCITY

        self._move_axis(dt)
        if self.vy < -35:
            self.vy = -35

    def _move_axis(self, dt):
        was_ground = self.on_ground
        self.on_ground = False

        self._sweep_x(self.vx * dt)
        self._sweep_z(self.vz * dt)
        self._sweep_y(dt, was_ground)

        if self.y < -8:
            self.y = 80.0
            self.vy = 0

    def _sweep_x(self, delta):
        steps = max(1, int(abs(delta) / 0.2))
        for _ in range(steps):
            self.x += delta / steps
            if self._collides():
                self.x -= delta / steps
                self.vx = 0
                return

    def _sweep_z(self, delta):
        steps = max(1, int(abs(delta) / 0.2))
        for _ in range(steps):
            self.z += delta / steps
            if self._collides():
                self.z -= delta / steps
                self.vz = 0
                return

    def _sweep_y(self, dt, was_ground):
        prev_y = self.y
        delta = self.vy * dt
        steps = max(1, int(abs(delta) / 0.1))
        landed = False
        for _ in range(steps):
            self.y += delta / steps
            if self._collides():
                self.y -= delta / steps
                if self.vy < 0:
                    self.on_ground = True
                    landed = True
                self.vy = 0
                break
        if self.vy < 0 and not landed:
            self.fall_distance += prev_y - self.y
        if self.on_ground:
            self.fall_distance = 0.0

    def _collides(self):
        return AABB(self.x, self.y, self.z).collides(self.world)

    def position(self):
        return (self.x, self.y, self.z)

    def eye_position(self):
        return (self.x, self.y + EYE_HEIGHT, self.z)


def raycast(world, origin, direction, max_dist=REACH, step=0.05):
    """Raycast voxel (DDA). Retourne (hit_block_pos, normal, prev_pos) ou None."""
    ox, oy, oz = origin
    dx, dy, dz = direction
    length = math.sqrt(dx * dx + dy * dy + dz * dz)
    if length == 0:
        return None
    dx, dy, dz = dx / length, dy / length, dz / length

    x, y, z = int(math.floor(ox)), int(math.floor(oy)), int(math.floor(oz))
    step_x = 1 if dx > 0 else -1
    step_y = 1 if dy > 0 else -1
    step_z = 1 if dz > 0 else -1
    t_max_x = ((x + (1 if dx > 0 else 0)) - ox) / dx if dx != 0 else float("inf")
    t_max_y = ((y + (1 if dy > 0 else 0)) - oy) / dy if dy != 0 else float("inf")
    t_max_z = ((z + (1 if dz > 0 else 0)) - oz) / dz if dz != 0 else float("inf")
    t_delta_x = abs(1 / dx) if dx != 0 else float("inf")
    t_delta_y = abs(1 / dy) if dy != 0 else float("inf")
    t_delta_z = abs(1 / dz) if dz != 0 else float("inf")

    normal = (0, 0, 0)
    t = 0.0
    prev = (x, y, z)
    while t <= max_dist:
        block = world.get_block(x, y, z)
        if B.is_solid(block):
            return (x, y, z), normal, prev
        prev = (x, y, z)
        if t_max_x < t_max_y and t_max_x < t_max_z:
            x += step_x
            t = t_max_x
            t_max_x += t_delta_x
            normal = (-step_x, 0, 0)
        elif t_max_y < t_max_z:
            y += step_y
            t = t_max_y
            t_max_y += t_delta_y
            normal = (0, -step_y, 0)
        else:
            z += step_z
            t = t_max_z
            t_max_z += t_delta_z
            normal = (0, 0, -step_z)
    return None
