#!/bin/bash
# VoxelCraft — Script d'installation et de lancement complet
# Usage: ./INSTALLER.sh [seed]
set -e

SEED="${1:-42}"
REPO_URL="https://github.com/rogarrys/EraShop.git"
TARGET_DIR="voxelcraft-game"

echo "========================================"
echo "  VoxelCraft — Installation automatique"
echo "========================================"

# 1. Cloner le repo (partie voxelcraft/)
if [ ! -d "$TARGET_DIR" ]; then
    echo "[1/5] Clonage du dépôt GitHub..."
    git clone --depth 1 "$REPO_URL" "$TARGET_DIR-tmp"
    mkdir -p "$TARGET_DIR"
    cp -r "$TARGET_DIR-tmp/voxelcraft" "$TARGET_DIR/"
    rm -rf "$TARGET_DIR-tmp"
else
    echo "[1/5] Dossier $TARGET_DIR déjà présent, on continue."
fi

cd "$TARGET_DIR"

# 2. Décompresser game.py
echo "[2/5] Décompression de game.py..."
python3 -c "import base64,zlib; open('voxelcraft/game.py','wb').write(zlib.decompress(base64.b64decode(open('voxelcraft/game.b64.txt').read())))"

# 3. Décompresser les tests
echo "[3/5] Décompression des tests..."
python3 -c "import base64,zlib; open('tests/test_voxelcraft.py','wb').write(zlib.decompress(base64.b64decode(open('voxelcraft/tests/test_voxelcraft.b64.txt').read())))"

# 4. Installer les dépendances
echo "[4/5] Installation des dépendances Python..."
python3 -m pip install -r requirements.txt --quiet

# 5. Lancer le jeu
echo "[5/5] Lancement de VoxelCraft (seed=$SEED)..."
echo ""
echo "  Contrôles: ZQSD/WASD = bouger | Clic G = casser | Clic D = poser"
echo "             E = inventaire | F = vol | Échap = menu | F1 = aide"
echo ""
python3 main.py --seed "$SEED"
