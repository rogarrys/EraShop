# 🎮 VoxelCraft — Moteur de jeu voxel avancé from scratch

Un clone/moteur voxel inspiré de Minecraft, écrit entièrement from scratch en Python.
Le noyau logique (monde, physique, inventaire) est 100 % testable en headless ;
le rendu 3D est assuré par [Ursina](https://www.ursinaengine.org/) (Panda3D).

> **Note** : `voxelcraft/game.py` est fourni sous forme compressée (`game.b64.txt`)
> pour respecter les limites de l'API. Voir [RÉCUPÉRATION.md](voxelcraft/RÉCUPÉRATION.md)
> pour le décompresser.

## 🚀 Lancer le jeu

```bash
pip install -r requirements.txt
python main.py                 # nouvelle partie, seed aléatoire
python main.py --seed 42       # seed fixe (monde reproductible)
python main.py --load saves/world_42.json   # charger une sauvegarde
python main.py --benchmark     # test headless du moteur (sans fenêtre)
python -m pytest tests/ -q     # 28 tests unitaires
```

Ou simplement double-cliquer sur `LANCER.bat` (Windows) / `LANCER.command` (macOS/Linux).

## 🎹 Contrôles

| Touche | Action |
|--------|--------|
| ZQSD / WASD | Se déplacer |
| Espace | Sauter / monter (en vol) |
| Shift gauche | Courir |
| Souris | Regarder (FPS) |
| Clic gauche | Casser un bloc / attaquer |
| Clic droit | Poser un bloc |
| Molette / 1-9 | Sélectionner la barre de raccourcis |
| E | Inventaire + crafting 3×3 |
| F | Activer/désactiver le vol |
| T | Manger l'objet sélectionné |
| Q | Lâcher l'objet sélectionné |
| Échap | Menu (pause, sauvegarder, quitter) |
| F1 | Masquer/afficher l'aide |

## ✨ Fonctionnalités

### Monde & génération procédurale
- **Chunks 16×64×16** avec chargement/déchargement dynamique
- **Bruit de valeur fractal (fBm)** 2D et 3D, déterministe par seed
- **5 biomes** : plaines, taïga, désert, jungle, neige
- **Caves 3D** en « spaghetti » via bruit 3D
- **Minerais** par profondeur : charbon, fer, or, diamant
- **Arbres** avec tronc + houppier, sans doublon entre chunks
- **Océans** au niveau de la mer (y=50), bedrock indestructible en y=0

### Gameplay
- **Physique FPS complète** : gravité, saut, collision AABB, nage, vol, sprint
- **Raycast voxel (DDA)** pour casser/poser/attaquer à 6 blocs de portée
- **Inventaire 36 slots** + **barre de raccourcis 9 slots**, stack jusqu'à 64
- **Crafting 3×3** avec 20+ recettes (outils, armes, table, fourneau, torches…)
- **Fourneau** : fusion minerais → lingots, sable → verre
- **Outils avec durabilité** : pioches, haches, épées, arc (bois/pierre/fer/diamant)
- **Système de vie/faim** : manger restaure la faim
- **Cycle jour/nuit** (4 min) avec soleil dynamique, brouillard et couleurs du ciel
- **Mobs avec IA** : vaches & poulets (errance), zombies & araignées (chasse, dégâts)
- **Sauvegarde JSON** : monde, position, vie, faim, inventaire avec durabilités

### Rendu
- **Maillage de chunks optimisé** : face culling contre les voisins solides opaques
- **Éclairage par sommet** : haut 100 %, côtés 80 %, dessous 50 %
- **Textures procédurales** générées avec PIL (pas d'assets externes)
- **Distance de vue 6 chunks**, rebuild incrémental

## 🏗️ Architecture

```
voxelcraft/
├── blocks.py      # Registre des 43 blocs, propriétés, recettes, fontes, outils
├── noise.py       # Bruit de valeur fBm 2D/3D, cartes de hauteur/température/humidité
├── world.py       # Chunks, génération procédurale, caves, minerais, arbres
├── physics.py     # AABB, gravité, collision sweep, raycast DDA
├── inventory.py   # Slots, stacking, crafting 3×3, fourneau, durabilité outils
├── mobs.py        # IA mobs (passifs, hostiles, drops)
├── save.py        # Sérialisation JSON monde + joueur + inventaire
├── renderer.py    # Maillage de chunks Ursina (face culling, textures PIL)
├── game.py        # Boucle de jeu : FPS, UI, HUD, cycle jour/nuit (voir game.b64.txt)
└── game.b64.txt   # Source compressée de game.py (zlib+base64)
main.py            # Point d'entrée (jeu, --seed, --load, --benchmark)
tests/             # 28 tests pytest
```

## 🧪 Tests

```bash
python -m pytest tests/ -q
# 28 passed — couvre : génération (bedrock, surface, minerais, caves, arbres,
# biomes), physique (chute, marche, mur, saut, raycast), inventaire (stacking,
# recettes, craft, durabilité, fourneau), mobs (chute, dégâts, poursuite),
# sauvegarde (roundtrip JSON).
```

## 📦 Télécharger le jeu complet

```bash
# Cloner le dossier voxelcraft/
git clone https://github.com/rogarrys/EraShop.git
cd EraShop/voxelcraft

# Décompresser game.py
python -c "import base64,zlib; open('voxelcraft/game.py','wb').write(zlib.decompress(base64.b64decode(open('voxelcraft/game.b64.txt').read())))"

# Lancer
pip install -r requirements.txt
python main.py --seed 42
```

## 📄 Licence

Projet éducatif — libre d'utilisation et de modification.
