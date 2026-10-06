@echo off
REM ============================================================
REM  VoxelCraft — Telechargement et lancement (VERSION CORRIGEE)
REM  Telecharge le projet depuis GitHub et le place dans la bonne
REM  arborescence (package voxelcraft/ + main.py a la racine).
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

echo [1/3] Creation de l'arborescence...
if not exist "voxelcraft" mkdir "voxelcraft\ui" "voxelcraft\tests"
if not exist "tests" mkdir "tests"
if not exist "saves" mkdir "saves"

echo [2/3] Telechargement des fichiers depuis GitHub...

REM Fichiers a la racine du projet local
set ROOT_FILES=main.py requirements.txt README.md LANCER.bat LANCER.command
for %%f in (%ROOT_FILES%) do (
    if not exist "%%f" (
        curl -sL --fail "%BASE_URL%/%%f" -o "%%f"
        if exist "%%f" (echo   OK   %%f) else (echo   ERREUR %%f)
    ) else (echo   present %%f)
)

REM Fichiers du package voxelcraft/
set PKG_FILES=__init__.py blocks.py noise.py world.py physics.py inventory.py mobs.py save.py renderer.py game.py
for %%f in (%PKG_FILES%) do (
    if not exist "voxelcraft\%%f" (
        curl -sL --fail "%BASE_URL%/%%f" -o "voxelcraft\%%f"
        if exist "voxelcraft\%%f" (echo   OK   voxelcraft\%%f) else (echo   ERREUR voxelcraft\%%f)
    ) else (echo   present voxelcraft\%%f)
)

REM Sous-dossiers du package
if not exist "voxelcraft\ui\__init__.py" (
    curl -sL --fail "%BASE_URL%/ui/__init__.py" -o "voxelcraft\ui\__init__.py"
    if exist "voxelcraft\ui\__init__.py" (echo   OK   voxelcraft\ui\__init__.py) else (echo   ERREUR voxelcraft\ui\__init__.py)
)
if not exist "voxelcraft\tests\__init__.py" (
    curl -sL --fail "%BASE_URL%/tests/__init__.py" -o "voxelcraft\tests\__init__.py"
    if exist "voxelcraft\tests\__init__.py" (echo   OK   voxelcraft\tests\__init__.py) else (echo   ERREUR voxelcraft\tests\__init__.py)
)

echo.
echo Verification des fichiers essentiels...
set MISSING=0
for %%f in (voxelcraft\game.py voxelcraft\blocks.py voxelcraft\noise.py voxelcraft\world.py voxelcraft\physics.py voxelcraft\inventory.py voxelcraft\mobs.py voxelcraft\save.py voxelcraft\renderer.py voxelcraft\__init__.py main.py requirements.txt) do (
    if not exist "%%f" (
        echo   MANQUANT: %%f
        set MISSING=1
    )
)
if %MISSING%==1 (
    echo.
    echo ERREUR: Des fichiers sont manquants. Telechargement incomplet.
    pause
    exit /b 1
)
echo   Tous les fichiers essentiels sont presents.

echo.
echo [3/3] Installation des dependances (1-2 min)...
python -m pip install -r requirements.txt --quiet
if errorlevel 1 (
    echo Tentative avec --user...
    python -m pip install -r requirements.txt --quiet --user
)

echo.
echo Lancement de VoxelCraft (seed=%SEED%)...
echo.
echo   Controles : ZQSD/WASD = bouger ^| Espace = sauter ^| Clic G = casser
echo              Clic D = poser ^| E = inventaire ^| F = vol ^| Echap = menu
echo.
python main.py --seed %SEED%
pause
