@echo off
REM ============================================================
REM  VoxelCraft — Telechargement et lancement (CORRIGE)
REM  Telecharge TOUS les fichiers depuis GitHub (y compris game.py
REM  en version reelle, plus besoin de decompression).
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

echo [1/3] Telechargement des fichiers depuis GitHub...

set FILES=main.py requirements.txt README.md LANCER.bat LANCER.command voxelcraft/__init__.py voxelcraft/blocks.py voxelcraft/noise.py voxelcraft/world.py voxelcraft/physics.py voxelcraft/inventory.py voxelcraft/mobs.py voxelcraft/save.py voxelcraft/renderer.py voxelcraft/game.py voxelcraft/ui/__init__.py voxelcraft/tests/__init__.py tests/__init__.py

for %%f in (%FILES%) do (
    if not exist "%%f" (
        mkdir "%%~dpf" 2>nul
        curl -sL --fail "%BASE_URL%/%%f" -o "%%f"
        if exist "%%f" (
            echo   OK   %%f
        ) else (
            echo   ERREUR %%f - telechargement echoue
        )
    ) else (
        echo   present %%f
    )
)

echo.
echo Verification des fichiers essentiels...
if not exist "voxelcraft\game.py" (
    echo ERREUR: voxelcraft\game.py est manquant ! Le jeu ne peut pas se lancer.
    pause
    exit /b 1
)
if not exist "voxelcraft\blocks.py" (
    echo ERREUR: voxelcraft\blocks.py est manquant !
    pause
    exit /b 1
)
if not exist "main.py" (
    echo ERREUR: main.py est manquant !
    pause
    exit /b 1
)
echo   Tous les fichiers essentiels sont presents.

echo.
echo [2/3] Installation des dependances (1-2 min)...
python -m pip install -r requirements.txt --quiet
if errorlevel 1 (
    echo Tentative avec --user...
    python -m pip install -r requirements.txt --quiet --user
)

echo.
echo [3/3] Lancement de VoxelCraft (seed=%SEED%)...
echo.
echo   Controles : ZQSD/WASD = bouger ^| Espace = sauter ^| Clic G = casser
echo              Clic D = poser ^| E = inventaire ^| F = vol ^| Echap = menu
echo.
python main.py --seed %SEED%
pause
