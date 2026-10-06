#!/bin/bash
# ============================================================
#  VoxelCraft — Telechargement et lancement (VERSION CORRIGEE)
#  Telecharge le projet depuis GitHub et le place dans la bonne
#  arborescence (package voxelcraft/ + main.py a la racine).
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

echo "[1/3] Telechargement des fichiers depuis GitHub..."

# Fichiers a la racine du projet local
ROOT_FILES=("main.py" "requirements.txt" "README.md" "LANCER.command")
for f in "${ROOT_FILES[@]}"; do
    if [ ! -f "$f" ]; then
        curl -sL --fail "$BASE_URL/$f" -o "$f" && echo "  OK   $f" || echo "  ERREUR $f"
    else
        echo "  present $f"
    fi
done

# Fichiers du package voxelcraft/
PKG_FILES=("__init__.py" "blocks.py" "noise.py" "world.py" "physics.py" "inventory.py" "mobs.py" "save.py" "renderer.py" "game.py")
for f in "${PKG_FILES[@]}"; do
    if [ ! -f "voxelcraft/$f" ]; then
        curl -sL --fail "$BASE_URL/$f" -o "voxelcraft/$f" && echo "  OK   voxelcraft/$f" || echo "  ERREUR voxelcraft/$f"
    else
        echo "  present voxelcraft/$f"
    fi
done

# Sous-dossiers du package
curl -sL --fail "$BASE_URL/ui/__init__.py" -o "voxelcraft/ui/__init__.py" 2>/dev/null && echo "  OK   voxelcraft/ui/__init__.py" || true
curl -sL --fail "$BASE_URL/tests/__init__.py" -o "voxelcraft/tests/__init__.py" 2>/dev/null && echo "  OK   voxelcraft/tests/__init__.py" || true

echo ""
echo "Verification des fichiers essentiels..."
MISSING=0
for f in "voxelcraft/game.py" "voxelcraft/blocks.py" "voxelcraft/noise.py" "voxelcraft/world.py" "voxelcraft/physics.py" "voxelcraft/inventory.py" "voxelcraft/mobs.py" "voxelcraft/save.py" "voxelcraft/renderer.py" "voxelcraft/__init__.py" "main.py" "requirements.txt"; do
    if [ ! -f "$f" ]; then
        echo "  MANQUANT: $f"
        MISSING=1
    fi
done
if [ "$MISSING" = "1" ]; then
    echo ""
    echo "ERREUR: Des fichiers sont manquants. Telechargement incomplet."
    exit 1
fi
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
