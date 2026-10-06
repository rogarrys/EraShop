#!/bin/bash
# ============================================================
#  VoxelCraft — Téléchargement et lancement en UNE commande
# ============================================================
#  Usage :
#    curl -sL https://raw.githubusercontent.com/rogarrys/EraShop/main/voxelcraft/TELECHARGER.sh | bash
#    ou : ./TELECHARGER.sh [seed]
#
#  Ce script :
#    1. Télécharge le projet depuis GitHub
#    2. Décompresse game.py et les tests
#    3. Installe les dépendances Python
#    4. Lance le jeu
# ============================================================
set -e

SEED="${1:-42}"
BASE_URL="https://raw.githubusercontent.com/rogarrys/EraShop/main/voxelcraft"
TARGET_DIR="voxelcraft-game"

echo "========================================"
echo "  VoxelCraft — Téléchargement & Lancement"
echo "========================================"

mkdir -p "$TARGET_DIR/voxelcraft/ui" "$TARGET_DIR/voxelcraft/tests" "$TARGET_DIR/tests" "$TARGET_DIR/saves"
cd "$TARGET_DIR"

FILES=(
    "main.py"
    "requirements.txt"
    "README.md"
    ".gitignore"
    "LANCER.bat"
    "LANCER.command"
    "RECUPERATION.md"
    "voxelcraft/__init__.py"
    "voxelcraft/blocks.py"
    "voxelcraft/noise.py"
    "voxelcraft/world.py"
    "voxelcraft/physics.py"
    "voxelcraft/inventory.py"
    "voxelcraft/mobs.py"
    "voxelcraft/save.py"
    "voxelcraft/renderer.py"
    "voxelcraft/game.b64.txt"
    "voxelcraft/ui/__init__.py"
    "voxelcraft/tests/test_voxelcraft.b64.txt"
)

echo "[1/4] Téléchargement des fichiers depuis GitHub..."
for f in "${FILES[@]}"; do
    mkdir -p "$(dirname "$f")"
    curl -sL --fail "$BASE_URL/$f" -o "$f" && echo "  ✓ $f" || echo "  ✗ $f (ERREUR)"
done

echo "[2/4] Décompression de game.py et des tests..."
python3 -c "
import base64, zlib
with open('voxelcraft/game.b64.txt') as f:
    src = zlib.decompress(base64.b64decode(f.read()))
open('voxelcraft/game.py', 'wb').write(src)
print(f'  ✓ game.py décompressé ({len(src)} octets)')
with open('voxelcraft/tests/test_voxelcraft.b64.txt') as f:
    src = zlib.decompress(base64.b64decode(f.read()))
open('tests/test_voxelcraft.py', 'wb').write(src)
print(f'  ✓ tests décompressés ({len(src)} octets)')
"

echo "[3/4] Installation des dépendances (cela peut prendre 1-2 min)..."
python3 -m pip install -r requirements.txt --quiet 2>&1 | tail -1 || true

echo "[4/4] Lancement de VoxelCraft (seed=$SEED)..."
echo ""
echo "  Contrôles : ZQSD/WASD = bouger | Espace = sauter | Clic G = casser"
echo "              Clic D = poser | E = inventaire | F = vol | Échap = menu"
echo ""
python3 main.py --seed "$SEED"
