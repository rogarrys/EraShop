@echo off
REM VoxelCraft — Installation et lancement automatique (Windows)
REM Usage: INSTALLER.bat [seed]
setlocal
set SEED=%1
if "%SEED%"=="" set SEED=42

echo ========================================
echo   VoxelCraft — Installation automatique
echo ========================================

if not exist voxelcraft-game (
    echo [1/5] Clonage du depot GitHub...
    git clone --depth 1 https://github.com/rogarrys/EraShop.git voxelcraft-tmp
    mkdir voxelcraft-game
    xcopy /E /I voxelcraft-tmp\voxelcraft voxelcraft-game\voxelcraft >nul
    rmdir /S /Q voxelcraft-tmp
) else (
    echo [1/5] Dossier deja present.
)

cd voxelcraft-game

echo [2/5] Decompression de game.py...
python -c "import base64,zlib; open('voxelcraft/game.py','wb').write(zlib.decompress(base64.b64decode(open('voxelcraft/game.b64.txt').read())))"

echo [3/5] Decompression des tests...
python -c "import base64,zlib; open('tests/test_voxelcraft.py','wb').write(zlib.decompress(base64.b64decode(open('voxelcraft/tests/test_voxelcraft.b64.txt').read())))"

echo [4/5] Installation des dependances...
python -m pip install -r requirements.txt --quiet

echo [5/5] Lancement de VoxelCraft (seed=%SEED%)...
echo.
echo   Controles: ZQSD/WASD = bouger ^| Clic G = casser ^| Clic D = poser
echo              E = inventaire ^| F = vol ^| Echap = menu ^| F1 = aide
echo.
python main.py --seed %SEED%
pause
