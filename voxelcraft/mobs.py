"""Mobs : vaches/poulets passifs, zombies hostiles de nuit, araignées."""
import math
import random

from . import blocks as B
from .physics import AABB, GRAVITY, JUMP_VELOCITY


class Mob:
    def __init__(self, kind, x, y, z):
        self.kind = kind
        self.x = x
        self.y = y
        self.z = z
        self.vx = self.vy = self.vz = 0.0
        self.hp = 10
        self.max_hp = 10
        self.on_ground = False
        self.attack_cooldown = 0.0
        self.wander_timer = 0.0
        self.wander_dir = (0.0, 0.0)
        self.dead = False
        self.touch_damage = 0
        speed = 3.5
        if kind == "zombie":
            self.hp = self.max_hp = 16
            self.touch_damage = 4
            speed = 4.0
        elif kind == "spider":
            self.hp = self.max_hp = 12
            self.touch_damage = 3
            speed = 4.5
        elif kind == "cow":
            self.hp = self.max_hp = 10
            speed = 2.5
        elif kind == "chicken":
            self.hp = self.max_hp = 4
            speed = 3.0
        self.speed = speed
        self.drop_table = {
            "cow": [(B.COOKED_BEEF, 1), (B.COOKED_BEEF, 1)],
            "chicken": [(B.COOKED_BEEF, 1)],
            "zombie": [(B.DIRT, 1)],
            "spider": [(B.STICK, 1)],
        }.get(kind, [])

    def aabb(self):
        return AABB(self.x, self.y, self.z, w=0.6, h=1.6 if self.kind != "chicken" else 0.7)

    def update(self, dt, world, player_pos, is_day):
        if self.dead:
            return
        self.attack_cooldown = max(0.0, self.attack_cooldown - dt)
        self.wander_timer -= dt

        hostile = self.kind in ("zombie", "spider")
        if hostile and is_day and self.kind == "zombie":
            self.vy -= GRAVITY * dt * 2
        target = None
        px, py, pz = player_pos
        dist = math.dist((self.x, self.z), (px, pz))
        if hostile and dist < 24:
            target = (px, pz)
        elif self.wander_timer <= 0:
            self.wander_timer = random.uniform(1.0, 3.0)
            angle = random.uniform(0, math.tau)
            self.wander_dir = (math.cos(angle), math.sin(angle))

        move_x, move_z = 0.0, 0.0
        if target is not None:
            dx, dz = target[0] - self.x, target[1] - self.z
            d = math.hypot(dx, dz) or 1.0
            move_x, move_z = dx / d, dz / d
        elif not hostile or is_day:
            move_x, move_z = self.wander_dir

        self.vx = move_x * self.speed
        self.vz = move_z * self.speed
        self.vy -= GRAVITY * dt
        if hostile and self.on_ground and (self.vx != 0 or self.vz != 0):
            ahead = world.get_block(int(self.x + self.vx * dt * 2), int(self.y), int(self.z + self.vz * dt * 2))
            above_ahead = world.get_block(int(self.x + self.vx * dt * 2), int(self.y + 1), int(self.z + self.vz * dt * 2))
            if B.is_solid(ahead) and not B.is_solid(above_ahead):
                self.vy = JUMP_VELOCITY * 0.8

        self._move(dt, world)

        if hostile and dist < 1.6 and self.attack_cooldown <= 0:
            self.attack_cooldown = 1.0

    def _move(self, dt, world):
        self.on_ground = False
        self._sweep(dt, world, axis="x")
        self._sweep(dt, world, axis="z")
        self._sweep_y(dt, world)

    def _sweep(self, dt, world, axis):
        delta = (self.vx if axis == "x" else self.vz) * dt
        steps = max(1, int(abs(delta) / 0.2))
        for _ in range(steps):
            if axis == "x":
                self.x += delta / steps
            else:
                self.z += delta / steps
            if self.aabb().collides(world):
                if axis == "x":
                    self.x -= delta / steps
                    self.vx = 0
                else:
                    self.z -= delta / steps
                    self.vz = 0
                return

    def _sweep_y(self, dt, world):
        delta = self.vy * dt
        steps = max(1, int(abs(delta) / 0.1))
        for _ in range(steps):
            self.y += delta / steps
            if self.aabb().collides(world):
                self.y -= delta / steps
                if self.vy < 0:
                    self.on_ground = True
                self.vy = 0
                return

    def damage(self, amount):
        self.hp -= amount
        if self.hp <= 0:
            self.dead = True

    def drops(self):
        return list(self.drop_table)


def spawn_candidates(world, player_pos, is_day, rng):
    """Retourne une liste de positions de spawn possibles autour du joueur."""
    px, pz = int(player_pos[0]), int(player_pos[2])
    candidates = []
    for _ in range(40):
        wx = px + rng.randint(-20, 20)
        wz = pz + rng.randint(-20, 20)
        wy = world.surface_height(wx, wz) + 1
        candidates.append((wx + 0.5, wy, wz + 0.5))
    return candidates
