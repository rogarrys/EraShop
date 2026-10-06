@echo off
REM ============================================================
REM  VoxelCraft — Lancement rapide (VERSION CORRIGEE)
REM  Verifie l'arborescence avant de lancer.
REM  Doit etre execute depuis le dossier contenant main.py
REM ============================================================
echo ========================================
echo   VoxelCraft — Lancement rapide
echo ========================================
echo.

REM Verifier qu'on est dans le bon dossier
if not exist "main.py" (
    echo ERREUR: main.py est introuvable dans le dossier courant.
    echo.
    echo Ce script doit etre lance depuis le dossier racine du jeu,
    echo celui qui contient main.py et le dossier voxelcraft\.
    echo.
    echo Si tu viens de telecharger, execute d'abord TELECHARGER.bat
    echo ou place-toi dans le dossier voxelcraft-game\.
    echo.
    pause
    exit /b 1
)

REM Verifier le package voxelcraft/
if not exist "voxelcraft\__init__.py" (
    echo ERREUR: Le dossier voxelcraft\ est manquant ou incomplet.
    echo.
    echo Execute TELECHARGER.bat pour telecharger le projet complet.
    echo.
    pause
    exit /b 1
)

if not exist "voxelcraft\game.py" (
    echo ERREUR: voxelcraft\game.py est manquant !
    echo.
    echo Execute TELECHARGER.bat pour reparer l'installation.
    echo.
    pause
    exit /b 1
)

if not exist "voxelcraft\blocks.py" (
    echo ERREUR: voxelcraft\blocks.py est manquant !
    pause
    exit /b 1
)

if not exist "requirements.txt" (
    echo ERREUR: requirements.txt est manquant !
    pause
    exit /b 1
)

echo Arborescence verifiee. Tous les fichiers sont presents.
echo.
echo Installation des dependances...
python -m pip install -r requirements.txt --quiet
if errorlevel 1 (
    echo Tentative avec --user...
    python -m pip install -r requirements.txt --quiet --user
)

echo.
echo Lancement de VoxelCraft...
echo.
echo   Controles : ZQSD/WASD = bouger ^| Espace = sauter ^| Clic G = casser
echo              Clic D = poser ^| E = inventaire ^| F = vol ^| Echap = menu
 echo.
python main.py --seed 42
pause
