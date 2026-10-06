"""VoxelCraft — Moteur de jeu voxel avancé from scratch en Python.

Modules :
- blocks: registre des blocs, recettes, fontes, outils
- noise: bruit de valeur fBm 2D/3D, cartes de hauteur/biomes
- world: chunks, génération procédurale, caves, minerais, arbres
- physics: gravité, collision AABB, raycast DDA
- inventory: slots, crafting 3x3, fourneau, durabilité
- mobs: IA (passifs, hostiles)
- save: sérialisation JSON
- renderer: maillage de chunks Ursina
- game: boucle de jeu FPS, UI, cycle jour/nuit
"""

__version__ = "1.0.0"
