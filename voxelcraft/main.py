"""Point d'entrée de VoxelCraft.

Usage :
    python main.py                # nouvelle partie (seed aléatoire)
    python main.py --seed 42      # seed fixe
    python main.py --load saves/world_42.json
    python main.py --benchmark    # test headless du moteur (sans fenêtre)
"""
import argparse
import os
import random
import sys


def run_benchmark():
    import time
    from voxelcraft.world import World
    from voxelcraft import blocks as B
    from voxelcraft.physics import PlayerPhysics, raycast
    from voxelcraft.inventory import Inventory
    from voxelcraft.save import save_game, load_game

    print("== VoxelCraft — benchmark headless ==")
    t0 = time.time()
    world = World(seed=42)
    for cx in range(-2, 3):
        for cz in range(-2, 3):
            world.get_chunk(cx, cz)
    t1 = time.time()
    print(f"Génération de 25 chunks (16x64x16): {t1 - t0:.2f}s")

    h = world.surface_height(4, 4)
    print(f"Surface en (4,4): y={h}, biome={world.noise.biome_at(4, 4)}")

    p = PlayerPhysics(world, x=4.5, y=90.0, z=4.5)
    for _ in range(600):
        p.update(1 / 60, (0, 0))
    print(f"Chute du joueur: atterri y={p.y:.2f} on_ground={p.on_ground}")

    hit = raycast(world, p.eye_position(), (0, -1, 0))
    print(f"Raycast vers le bas: touche {hit[0] if hit else None}")

    inv = Inventory()
    inv.add_item(B.WOOD, 10)
    inv.craft_grid = [[B.WOOD, None, None], [None, None, None], [None, None, None]]
    assert inv.craft()
    print(f"Craft: 10 bois -> {inv.count_item(B.PLANKS)} planches, reste {inv.count_item(B.WOOD)} bois")

    os.makedirs("saves", exist_ok=True)
    path = "saves/benchmark.json"
    class P: pass
    pp = P(); pp.x, pp.y, pp.z, pp.hp, pp.hunger = 1, 70, 1, 20, 20
    save_game(path, world, pp, inv, 6000)
    data = load_game(path)
    assert data["world"].get_block(4, h, 4) == world.get_block(4, h, 4)
    print(f"Sauvegarde OK: {path} ({os.path.getsize(path)} octets)")
    print("== Tous les checks headless sont passés ==")
    return 0


def main():
    parser = argparse.ArgumentParser(description="VoxelCraft — jeu voxel from scratch")
    parser.add_argument("--seed", type=int, default=None)
    parser.add_argument("--load", type=str, default=None, help="Chemin d'une sauvegarde JSON")
    parser.add_argument("--benchmark", action="store_true", help="Test headless sans fenêtre")
    args = parser.parse_args()

    if args.benchmark:
        sys.exit(run_benchmark())

    seed = args.seed if args.seed is not None else random.randint(0, 10 ** 9)

    if args.load:
        from voxelcraft.save import load_game
        data = load_game(args.load)
        seed = data["seed"]
        from voxelcraft import game as gamemod
        app = gamemod.Ursina(size=(1280, 720), title=f"VoxelCraft — seed {seed}")
        g = gamemod.VoxelGame(seed=seed)
        g.inventory = data["inventory"]
        pd = data["player"]
        g.physics.x, g.physics.y, g.physics.z = pd["x"], pd["y"], pd["z"]
        g.hp, g.hunger = pd.get("hp", 20), pd.get("hunger", 20)
        g.time_of_day = data.get("time", 6000)
        from ursina import mouse, camera
        mouse.locked = True

        def update():
            g.update(gamemod.utime.dt)
        app.run()
        return

    from voxelcraft.game import run
    run(seed=seed)


if __name__ == "__main__":
    main()
