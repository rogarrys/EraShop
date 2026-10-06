#!/bin/bash
# ============================================================
#  VoxelCraft — Telechargement et lancement (CORRIGE)
#  Telecharge TOUS les fichiers depuis GitHub (y compris game.py
#  en version reelle, plus besoin de decompression).
# ============================================================
set -e

SEED="${1:-42}"
BASE_URL="https://raw.githubusercontent.com/rogarrys/EraShop/main/voxelcraft"
TARGET_DIR="voxelcraft-game"

echo "========================================"
echo "  VoxelCraft — Telechargement & Lancement"
echo "========================================"

mkdir -p "$TARGET_DIR/voxelcraft/ui" "$TARGET_DIR/voxelcraft/tests" "$TARGET_DIR/tests" "$TARGET_DIR/saves"
cd "$TARGET_DIR"

FILES=(
    "main.py"
    "requirements.txt"
    "README.md"
    "LANCER.command"
    "voxelcraft/__init__.py"
    "voxelcraft/blocks.py"
    "voxelcraft/noise.py"
    "voxelcraft/world.py"
    "voxelcraft/physics.py"
    "voxelcraft/inventory.py"
    "voxelcraft/mobs.py"
    "voxelcraft/save.py"
    "voxelcraft/renderer.py"
    "voxelcraft/game.py"
    "voxelcraft/ui/__init__.py"
    "voxelcraft/tests/__init__.py"
    "tests/__init__.py"
)

echo "[1/3] Telechargement des fichiers depuis GitHub..."
for f in "${FILES[@]}"; do
    mkdir -p "$(dirname "$f")"
    if curl -sL --fail "$BASE_URL/$f" -o "$f"; then
        echo "  OK   $f"
    else
        echo "  ERREUR $f"
    fi
done

echo ""
echo "Verification des fichiers essentiels..."
for f in "voxelcraft/game.py" "voxelcraft/blocks.py" "main.py"; do
    if [ ! -f "$f" ]; then
        echo "ERREUR: $f est manquant ! Le jeu ne peut pas se lancer."
        exit 1
    fi
done
echo "  Tous les fichiers essentiels sont presents."

echo ""
echo "[2/3] Installation des dependances (1-2 min)..."
python3 -m pip install -r requirements.txt --quiet 2>&1 | tail -1 || true

echo ""
echo "[3/3] Lancement de VoxelCraft (seed=$SEED)..."
echo ""
echo "  Controles : ZQSD/WASD = bouger | Espace = sauter | Clic G = casser"
echo "              Clic D = poser | E = inventaire | F = vol | Echap = menu"
echo ""
python3 main.py --seed "$SEED"
