@echo off
echo ========================================
echo   VoxelCraft - Lancement rapide (CORRIGE)
echo ========================================
echo.

REM Verifier que les fichiers essentiels existent
if not exist "voxelcraft\game.py" (
    echo ERREUR: voxelcraft\game.py est manquant !
    echo.
    echo Telecharge le projet complet depuis:
    echo   https://github.com/rogarrys/EraShop/tree/main/voxelcraft
    echo.
    echo Ou execute TELECHARGER.bat pour tout telecharger automatiquement.
    echo.
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
    echo Lance ce script depuis le dossier racine du jeu (la ou se trouve main.py).
    pause
    exit /b 1
)

echo Fichiers verifies. Installation des dependances...
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
