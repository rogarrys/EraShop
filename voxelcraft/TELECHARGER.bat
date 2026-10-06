@echo off
REM ============================================================
REM  VoxelCraft — Telechargement et lancement en UN double-clic
REM ============================================================
REM  Ce script telecharge tous les fichiers depuis GitHub,
REM  decompresse game.py, installe les dependances et lance le jeu.
REM ============================================================
setlocal EnableDelayedExpansion

set SEED=42
if not "%1"=="" set SEED=%1

set BASE_URL=https://raw.githubusercontent.com/rogarrys/EraShop/main/voxelcraft
set TARGET_DIR=voxelcraft-game

echo ========================================
echo   VoxelCraft — Telechargement ^& Lancement
echo ========================================

if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"
cd "%TARGET_DIR%"
if not exist "voxelcraft" mkdir "voxelcraft\ui" "voxelcraft\tests" "tests" "saves"

echo [1/4] Telechargement des fichiers depuis GitHub...

set FILES=main.py requirements.txt README.md .gitignore LANCER.bat LANCER.command RECUPERATION.md voxelcraft/__init__.py voxelcraft/blocks.py voxelcraft/noise.py voxelcraft/world.py voxelcraft/physics.py voxelcraft/inventory.py voxelcraft/mobs.py voxelcraft/save.py voxelcraft/renderer.py voxelcraft/game.b64.txt voxelcraft/ui/__init__.py voxelcraft/tests/test_voxelcraft.b64.txt

for %%f in (%FILES%) do (
    if not exist "%%f" (
        mkdir "%%~dpf" 2>nul
        curl -sL --fail "%BASE_URL%/%%f" -o "%%f" && echo   OK  %%f || echo   ERREUR %%f
    ) else (
        echo   present %%f
    )
)

echo [2/4] Decompression de game.py et des tests...
python -c "import base64,zlib; f=open('voxelcraft/game.b64.txt'); src=zlib.decompress(base64.b64decode(f.read())); open('voxelcraft/game.py','wb').write(src); print('  OK game.py ('+str(len(src))+' octets)')"
python -c "import base64,zlib; f=open('voxelcraft/tests/test_voxelcraft.b64.txt'); src=zlib.decompress(base64.b64decode(f.read())); open('tests/test_voxelcraft.py','wb').write(src); print('  OK tests ('+str(len(src))+' octets)')"

echo [3/4] Installation des dependances...
python -m pip install -r requirements.txt --quiet

echo [4/4] Lancement de VoxelCraft (seed=%SEED%)...
echo.
echo   Controles : ZQSD/WASD = bouger ^| Espace = sauter ^| Clic G = casser
echo              Clic D = poser ^| E = inventaire ^| F = vol ^| Echap = menu
echo.
python main.py --seed %SEED%
pause
