"""Boucle de jeu principale : joueur FPS, interaction blocs, UI, mobs, jour/nuit."""
import math
import os
import random
import sys

from ursina import (
    Ursina, Entity, Text, WindowPanel, Button, camera, mouse, held_keys,
    color as ucolor, Vec3, Vec2, invoke, application,
    Sky, DirectionalLight, AmbientLight, scene, time as utime,
)

from . import blocks as B
from .world import World, CHUNK_SIZE, CHUNK_HEIGHT, SEA_LEVEL
from .physics import PlayerPhysics, raycast, EYE_HEIGHT, REACH
from .inventory import Inventory, HOTBAR_SIZE
from .renderer import ChunkMesh
from .mobs import Mob, spawn_candidates
from . import save as savemod

DAY_LENGTH = 240.0
RENDER_DISTANCE = 6
MAX_MOBS = 24


class VoxelGame:
    def __init__(self, seed=1337, save_path=None):
        self.seed = seed
        self.save_path = save_path or os.path.join("saves", f"world_{seed}.json")
        self.world = World(seed=seed)
        self.inventory = Inventory()
        self.physics = None
        self.time_of_day = 6000.0
        self.mobs = []
        self.chunk_meshes = {}
        self.paused = False
        self.hp = 20
        self.hunger = 20
        self.invincibility = 0.0
        self.build_mode = False
        self._setup_ui()
        self._spawn_player()
        self._refresh_chunks(force=True)
        self._spawn_initial_mobs()

    def _setup_ui(self):
        self.crosshair = Entity(parent=scene.ui, model="quad", color=ucolor.white, scale=0.008, rotation_z=45)
        self.crosshair2 = Entity(parent=scene.ui, model="quad", color=ucolor.white, scale=0.008)
        self.hotbar_slots = []
        for i in range(HOTBAR_SIZE):
            slot = Entity(parent=scene.ui, model="quad", color=ucolor.dark_gray, scale=0.08,
                          position=(-0.36 + i * 0.09, -0.42))
            slot.border = Entity(parent=slot, model="quad", color=ucolor.black, scale=1.05, z=0.01)
            slot.text = Text(parent=slot, text="", scale=2, position=(0.32, -0.32), color=ucolor.white)
            slot.icon = Entity(parent=slot, model="cube", scale=0.5, color=ucolor.gray, z=-0.01, double_sided=True)
            slot.index = i
            self.hotbar_slots.append(slot)
        self.selected_frame = Entity(parent=scene.ui, model="quad", color=ucolor.clear,
                                    position=(-0.36, -0.42), scale=0.085)
        self.selected_frame.border = Entity(parent=self.selected_frame, model="quad",
                                            color=ucolor.yellow, scale=1.08, z=0.01)
        self.hud_text = Text(text="", position=(-0.98, 0.45), scale=1.2, color=ucolor.white)
        self.fps_text = Text(text="", position=(0.75, 0.45), scale=1, color=ucolor.light_gray)
        self.health_text = Text(text="", position=(-0.98, -0.38), scale=1.2, color=ucolor.red)
        self.message_text = Text(text="", position=(0, 0.3), scale=2, color=ucolor.yellow, origin=(0, 0))
        self.message_timer = 0.0

        self.inventory_panel = WindowPanel(
            title="Inventaire", content=(), enabled=False, visible=False,
            position=(-0.5, -0.1), scale=(1.0, 0.7))
        self.inv_slots_ui = []
        for i in range(36):
            row, col = divmod(i, 9)
            s = Button(parent=self.inventory_panel.content, model="quad", color=ucolor.dark_gray,
                       scale=0.1, position=(-0.4 + col * 0.105, 0.25 - row * 0.105))
            s.text_entity = Text(parent=s, text="", scale=1.6, color=ucolor.white)
            s.icon = Entity(parent=s, model="cube", scale=0.6, z=-0.01, double_sided=True)
            s.on_click = self._make_inv_click(i)
            self.inv_slots_ui.append(s)
        craft_y = -0.14
        self.craft_slots_ui = []
        for r in range(3):
            for c in range(3):
                s = Button(parent=self.inventory_panel.content, model="quad", color=ucolor.gray,
                           scale=0.09, position=(0.18 + c * 0.095, craft_y + (2 - r) * 0.095))
                s.text_entity = Text(parent=s, text="", scale=1.4, color=ucolor.white)
                s.index = (r, c)
                s.on_click = self._make_craft_click(r, c)
                self.craft_slots_ui.append(s)
        self.craft_result_ui = Button(parent=self.inventory_panel.content, model="quad",
                                      color=ucolor.green, scale=0.09, position=(0.55, craft_y + 0.095))
        self.craft_result_ui.text_entity = Text(parent=self.craft_result_ui, text="", scale=1.4, color=ucolor.white)
        self.craft_result_ui.on_click = self._craft_result

        self.help_text = Text(
            text="ZQSDF/WASD: bouger | Espace: sauter | F: vol | Clic G: casser | Clic D: poser | "
                 "E: inventaire | 1-9: barre | Molette: selection | Echappe: menu | M: mobs",
            position=(0, -0.48), scale=1, color=ucolor.light_gray, origin=(0, 0))
        self.help_text.enabled = True

        self.menu_panel = WindowPanel(title="Menu", content=(), enabled=False, visible=False,
                                      position=(0, 0), scale=(0.5, 0.5))
        self.menu_buttons = []
        for label, fn in [("Reprendre", self.resume), ("Sauvegarder", self.save),
                          ("Sauvegarder & quitter", self.save_and_quit)]:
            btn = Button(parent=self.menu_panel.content, text=label, scale=(0.8, 0.15),
                         position=(0, 0.15 - len(self.menu_buttons) * 0.2))
            btn.on_click = fn
            self.menu_buttons.append(btn)

        self.sky = Sky()
        self.sun = DirectionalLight(shadows=True)
        self.sun.rotation = (60, -30, 0)
        self.ambient = AmbientLight(color=ucolor.white)
        self.fog_enabled = True

    def _make_inv_click(self, index):
        def fn():
            if not self.inventory_panel.enabled:
                return
            self._inventory_click(index)
        return fn

    def _make_craft_click(self, r, c):
        def fn():
            if not self.inventory_panel.enabled:
                return
            self._craft_grid_click(r, c)
        return fn

    def _spawn_player(self):
        x, z = 0.5, 0.5
        y = self.world.surface_height(0, 0) + 2
        self.physics = PlayerPhysics(self.world, x=x, y=y, z=z)

    def _spawn_initial_mobs(self):
        rng = random.Random(self.seed + 99)
        for pos in spawn_candidates(self.world, (self.physics.x, 0, self.physics.z), True, rng)[:8]:
            kind = rng.choice(["cow", "chicken", "cow"])
            self.mobs.append(Mob(kind, *pos))

    def toggle_pause(self):
        self.paused = not self.paused
        self.inventory_panel.enabled = self.paused
        self.inventory_panel.visible = self.paused
        self.menu_panel.enabled = False
        if self.paused:
            mouse.locked = False
            self.inventory_panel.enabled = False
            self.menu_panel.enabled = True
            self.menu_panel.visible = True
        else:
            mouse.locked = True

    def resume(self):
        self.menu_panel.enabled = False
        self.menu_panel.visible = False
        self.paused = False
        mouse.locked = True

    def save(self):
        class P:
            pass
        p = P()
        p.x, p.y, p.z = self.physics.x, self.physics.y, self.physics.z
        p.hp, p.hunger = self.hp, self.hunger
        savemod.save_game(self.save_path, self.world, p, self.inventory, self.time_of_day, seed=self.seed)
        self.message("Partie sauvegardee")

    def save_and_quit(self):
        self.save()
        application.quit()

    def message(self, text, duration=2.0):
        self.message_text.text = text
        self.message_timer = duration

    def _refresh_chunks(self, force=False):
        pcx = int(self.physics.x // CHUNK_SIZE)
        pcz = int(self.physics.z // CHUNK_SIZE)
        needed = set()
        for dx in range(-RENDER_DISTANCE, RENDER_DISTANCE + 1):
            for dz in range(-RENDER_DISTANCE, RENDER_DISTANCE + 1):
                needed.add((pcx + dx, pcz + dz))
        for key in list(self.chunk_meshes.keys()):
            if key not in needed:
                self.chunk_meshes.pop(key).destroy()
        for key in needed:
            if key not in self.chunk_meshes:
                self.chunk_meshes[key] = ChunkMesh(self.world, key[0], key[1], parent=scene)
        if force:
            for key in needed:
                self.chunk_meshes[key].rebuild()

    def rebuild_chunk_at(self, wx, wz):
        pcx = int(wx // CHUNK_SIZE)
        pcz = int(wz // CHUNK_SIZE)
        for dx in (-1, 0, 1):
            for dz in (-1, 0, 1):
                key = (pcx + dx, pcz + dz)
                mesh = self.chunk_meshes.get(key)
                if mesh:
                    mesh.rebuild()

    def break_block(self):
        origin = self.physics.eye_position()
        direction = self._look_direction()
        hit = raycast(self.world, origin, direction)
        if not hit:
            return
        (bx, by, bz), normal, prev = hit
        block = self.world.get_block(bx, by, bz)
        if block in (B.AIR, B.BEDROCK):
            return
        slot = self.inventory.selected_slot()
        tool = slot.item
        kind = B.TOOL_OF_ITEM.get(tool, (None, None))[0]
        info = B.info(block)
        if info.tool != "hand" and kind != info.tool:
            self.message("Mauvais outil !")
            return
        speed_mult = 1.0
        if kind == info.tool:
            tier = B.TOOL_OF_ITEM[tool][1]
            speed_mult = B.TOOL_TIER.get(tier, 1)
        for drop_id, qty in info.drops:
            if drop_id is None:
                continue
            self.inventory.add_item(drop_id, qty)
        self.world.set_block(bx, by, bz, B.AIR)
        self.rebuild_chunk_at(bx, bz)
        if tool in B.TOOL_OF_ITEM:
            self.inventory.damage_tool()

    def place_block(self):
        slot = self.inventory.selected_slot()
        if slot.is_empty():
            return
        item = slot.item
        if item == B.TORCH_ITEM:
            block = B.TORCH
        elif item in (B.WOOD_PICKAXE, B.STONE_PICKAXE, B.IRON_PICKAXE, B.DIAMOND_PICKAXE,
                      B.WOOD_AXE, B.STONE_AXE, B.IRON_AXE, B.WOOD_SWORD, B.STONE_SWORD,
                      B.IRON_SWORD, B.DIAMOND_SWORD, B.BOW):
            return
        else:
            block = item
        origin = self.physics.eye_position()
        direction = self._look_direction()
        hit = raycast(self.world, origin, direction)
        if not hit:
            return
        (bx, by, bz), normal, prev = hit
        px, py, pz = prev
        if B.info(block).liquid:
            return
        from .physics import AABB
        if AABB(self.physics.x, self.physics.y, self.physics.z).intersects_block(px, py, pz):
            return
        if self.world.get_block(px, py, pz) != B.AIR:
            return
        self.world.set_block(px, py, pz, block)
        slot.take(1)
        self.rebuild_chunk_at(px, pz)

    def attack(self):
        slot = self.inventory.selected_slot()
        tool = slot.item
        damage = 1
        if tool in B.SWORD_DAMAGE:
            damage = B.SWORD_DAMAGE[tool]
            self.inventory.damage_tool()
        origin = self.physics.eye_position()
        direction = self._look_direction()
        hit_mob = None
        best = REACH
        for mob in self.mobs:
            if mob.dead:
                continue
            mx, my, mz = mob.x, mob.y + 0.8, mob.z
            to = (mx - origin[0], my - origin[1], mz - origin[2])
            d = math.sqrt(sum(c * c for c in to))
            if d > REACH or d == 0:
                continue
            to = tuple(c / d for c in to)
            dot = sum(a * b for a, b in zip(to, direction))
            if dot > 0.85:
                hit_mob = mob
                best = d
                break
        if hit_mob:
            hit_mob.damage(damage)
            if hit_mob.dead:
                for drop_id, qty in hit_mob.drops():
                    self.inventory.add_item(drop_id, qty)
                self.message(f"{hit_mob.kind} vaincu !")
        else:
            self.break_block()

    def eat_selected(self):
        slot = self.inventory.selected_slot()
        if slot.is_empty():
            return
        food = B.info(slot.item).food
        if food <= 0:
            return
        slot.take(1)
        self.hunger = min(20, self.hunger + food)

    def _look_direction(self):
        rx, ry = camera.rotation_x, camera.rotation_y
        return (
            -math.sin(math.radians(ry)) * math.cos(math.radians(rx)),
            math.sin(math.radians(rx)),
            math.cos(math.radians(ry)) * math.cos(math.radians(rx)),
        )

    def _inventory_click(self, index):
        pass

    def _craft_grid_click(self, r, c):
        pass

    def _craft_result(self):
        if self.inventory.craft():
            self.message("Fabrique !")

    def _key(self, keys, name):
        try:
            return bool(keys[name])
        except (KeyError, TypeError):
            return False

    def update(self, dt):
        if self.message_timer > 0:
            self.message_timer -= dt
            if self.message_timer <= 0:
                self.message_text.text = ""

        keys = held_keys
        forward = int(self._key(keys, "w") or self._key(keys, "z")) - int(self._key(keys, "s"))
        strafe = int(self._key(keys, "d")) - int(self._key(keys, "a"))
        if mouse.locked and not self.paused:
            yaw = camera.rotation_y
            sin_y, cos_y = math.sin(math.radians(yaw)), math.cos(math.radians(yaw))
            mx = strafe * cos_y + forward * sin_y
            mz = -strafe * sin_y + forward * cos_y
            self.physics.update(
                dt, move_input=(mx, mz),
                jump=self._key(keys, "space"), sprint=self._key(keys, "left shift"),
                fly_toggle=self._key(keys, "f") and not getattr(self, "_f_pressed", False))
            self._f_pressed = self._key(keys, "f")
            camera.position = (self.physics.x, self.physics.y + EYE_HEIGHT, self.physics.z)
        else:
            self.physics.vy = 0

        self.time_of_day = (self.time_of_day + dt * (24000 / DAY_LENGTH)) % 24000
        self._update_daynight()

        if mouse.locked and not self.paused:
            if mouse.left:
                self.attack()
            elif mouse.right:
                self.place_block()

        self._update_mobs(dt)
        self._update_ui()

        if self._key(keys, "escape") and not getattr(self, "_esc_pressed", False):
            self.toggle_pause()
        self._esc_pressed = self._key(keys, "escape")
        if self._key(keys, "e") and not getattr(self, "_e_pressed", False) and not self.paused:
            self.inventory_panel.enabled = not self.inventory_panel.enabled
            self.inventory_panel.visible = self.inventory_panel.enabled
            mouse.locked = not self.inventory_panel.enabled
        self._e_pressed = self._key(keys, "e")
        wheel = getattr(mouse, "wheel", 0) or 0
        if wheel:
            self.inventory.selected = (self.inventory.selected - int(wheel)) % HOTBAR_SIZE
        for i in range(9):
            if self._key(keys, str(i + 1)):
                self.inventory.selected = i
        if self._key(keys, "q") and not getattr(self, "_q_pressed", False):
            slot = self.inventory.selected_slot()
            if not slot.is_empty():
                self.world.set_block(int(self.physics.x), int(self.physics.y + 2), int(self.physics.z), slot.item)
                slot.take(slot.count)
        self._q_pressed = self._key(keys, "q")
        if self._key(keys, "t") and not getattr(self, "_t_pressed", False):
            self.eat_selected()
        self._t_pressed = self._key(keys, "t")

    def _update_daynight(self):
        t = self.time_of_day
        angle = (t / 24000.0) * 360 - 90
        self.sun.rotation = (angle, -30, 0)
        day_factor = max(0.0, math.sin(math.radians(angle)))
        self.sun.color = ucolor.rgb(255, 240 + int(15 * day_factor), 200 + int(55 * day_factor))
        scene.fog_density = 0.008 if day_factor > 0.3 else 0.02
        scene.background_color = ucolor.rgb(int(90 + 60 * day_factor), int(130 + 50 * day_factor), int(200 + 20 * day_factor))
        self.is_day = 6000 <= t < 18000

    def _update_mobs(self, dt):
        player_pos = self.physics.position()
        rng = random.Random(int(self.time_of_day * 7) + self.seed)
        for mob in self.mobs:
            mob.update(dt, self.world, player_pos, self.is_day)
            if getattr(mob, "entity", None) is None:
                mobcol = {"cow": ucolor.brown, "chicken": ucolor.white, "zombie": ucolor.green, "spider": ucolor.black}[mob.kind]
                mob.entity = Entity(model="cube", color=mobcol, scale=(0.6, 1.6 if mob.kind != "chicken" else 0.7, 0.6),
                                    position=(mob.x, mob.y, mob.z))
            mob.entity.position = (mob.x, mob.y, mob.z)
            mob.entity.visible = not mob.dead
            if mob.dead and getattr(mob, "_dropped", False) is False:
                mob._dropped = True
        alive = [m for m in self.mobs if not m.dead]
        self.mobs = alive
        if len(self.mobs) < MAX_MOBS and rng.random() < 0.02:
            pos_list = spawn_candidates(self.world, player_pos, self.is_day, rng)
            if pos_list:
                kind = rng.choice(["zombie", "spider"] if not self.is_day else ["cow", "chicken"])
                x, y, z = pos_list[0]
                if math.dist((x, z), (player_pos[0], player_pos[2])) > 8:
                    self.mobs.append(Mob(kind, x, y, z))
        if self.invincibility > 0:
            self.invincibility -= dt
        for mob in self.mobs:
            if math.dist((mob.x, mob.y, mob.z), player_pos) < 1.6 and self.invincibility <= 0:
                if mob.kind in ("zombie", "spider"):
                    self.hp -= mob.touch_damage
                    self.invincibility = 1.0
                    if self.hp <= 0:
                        self.message("Vous etes mort ! Respawn...")
                        self.hp = 20
                        self.physics.y = self.world.surface_height(int(self.physics.x), int(self.physics.z)) + 2

    def _update_ui(self):
        for i, ui in enumerate(self.hotbar_slots):
            s = self.inventory.slots[i]
            ui.text.text = str(s.count) if not s.is_empty() and s.count > 1 else ""
            ui.icon.color = ucolor.color(255, *B.info(s.item).color) if not s.is_empty() else ucolor.gray
            ui.icon.enabled = not s.is_empty()
        self.selected_frame.x = -0.36 + self.inventory.selected * 0.09
        self.hud_text.text = f"Vie: {self.hp} | Faim: {self.hunger} | Seed: {self.seed} | Biome: {self.world.noise.biome_at(int(self.physics.x), int(self.physics.z))}"
        self.health_text.text = "♥" * (self.hp // 2) + "♡" * max(0, (20 - self.hp) // 2)
        self.fps_text.text = f"FPS: {int(1/max(utime.dt, 0.0001))}"
        if self.inventory_panel.enabled:
            for i, ui in enumerate(self.inv_slots_ui):
                s = self.inventory.slots[i]
                ui.text_entity.text = str(s.count) if not s.is_empty() and s.count > 1 else ""
                ui.icon.color = ucolor.color(255, *B.info(s.item).color) if not s.is_empty() else ucolor.gray
                ui.icon.enabled = not s.is_empty()
            for ui in self.craft_slots_ui:
                r, c = ui.index
                cell = self.inventory.craft_grid[r][c]
                ui.text_entity.text = ""
                ui.icon.color = ucolor.color(255, *B.info(cell).color) if cell is not None else ucolor.gray
                ui.icon.enabled = cell is not None
            from .inventory import find_recipe
            found = find_recipe(self.inventory.craft_grid)
            self.craft_result_ui.icon.color = ucolor.color(255, *B.info(found[0]).color) if found else ucolor.gray
            self.craft_result_ui.icon.enabled = bool(found)


def run(seed=1337, save_path=None):
    app = Ursina(size=(1280, 720), title="VoxelCraft - moteur voxel avance")
    game = VoxelGame(seed=seed, save_path=save_path)
    camera.clip_plane_far = 600
    mouse.locked = True

    def input(key):
        if key == "f1":
            game.help_text.enabled = not game.help_text.enabled

    def update():
        game.update(utime.dt)
        if int(game.physics.x // CHUNK_SIZE) != getattr(game, "_last_cx", None) or \
           int(game.physics.z // CHUNK_SIZE) != getattr(game, "_last_cz", None):
            game._last_cx = int(game.physics.x // CHUNK_SIZE)
            game._last_cz = int(game.physics.z // CHUNK_SIZE)
            game._refresh_chunks()

    app.run()
    return game
