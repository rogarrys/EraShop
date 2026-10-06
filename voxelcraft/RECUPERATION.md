# Récupération de game.py (compressé)

Le fichier `voxelcraft/game.py` est trop volumineux pour l'API GitHub utilisée
lors de la publication initiale. Il est donc stocké compressé dans
`voxelcraft/game.b64.txt` (zlib niveau 9 + base64).

## Décompresser

```bash
# Depuis la racine du dossier voxelcraft/
python -c "import base64,zlib; open('voxelcraft/game.py','wb').write(zlib.decompress(base64.b64decode(open('voxelcraft/game.b64.txt').read())))"
```

Ou en une ligne complète (clone + décompression + install + lancement) :

```bash
git clone https://github.com/rogarrys/EraShop.git
cd EraShop/voxelcraft
python -c "import base64,zlib; open('voxelcraft/game.py','wb').write(zlib.decompress(base64.b64decode(open('voxelcraft/game.b64.txt').read())))"
pip install -r requirements.txt
python main.py --seed 42
```

## Vérification

```bash
python -c "
import base64, zlib, hashlib
src = zlib.decompress(base64.b64decode(open('voxelcraft/game.b64.txt').read()))
print('Taille:', len(src), 'octets')
print('SHA256:', hashlib.sha256(src).hexdigest())
"
```
