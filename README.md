# photo-souvenir

Développe et étalonne tout un lot de photos RAW (Sony ARW, Canon CR2/CR3, Nikon NEF, Fuji RAF, DNG…) avec un look film, en un clic. Pensé pour les "photos souvenir" d'événement : tu shootes en RAW, tu lances photo-souvenir, tu récupères des JPEG prêts à partager avec un rendu cohérent — puis tu tries/supprimes les ratés.

Le cœur, c'est le **mode adaptatif** : chaque photo est analysée et le LUT / contraste / saturation sont **atténués automatiquement sur les images claires** (ensoleillées) pour éviter la sursaturation, tout en appliquant le plein effet sur les photos sombres ou plates. Plus besoin d'éditer photo par photo.

## Pipeline (par photo)

1. **Développement RAW** via `darktable-cli` → TIFF 16-bit, orientation redressée
2. **Détection de grain + débruitage adaptatif** (optionnel) : mesure le bruit réel de chaque photo (σ par tuiles) et débruite seulement celles qui dépassent un seuil — débruitage *chroma-focus* qui enlève les points colorés tout en gardant un grain de luminance argentique
3. **Exposition adaptative** : la luminosité est ramenée vers une cible mesurée (rattrape les sombres, maîtrise les surexposées)
4. **Contraste en courbe S** + noirs profonds
5. **LUT film** (Kodak Portra par défaut) dosé selon la clarté de l'image
6. **Métadonnées d'origine** recopiées (date/boîtier), orientation remise à normal

### Détection de grain

Le débruitage est **désactivé par défaut** (le grain donne souvent un rendu argentique voulu). En mode `auto`, chaque photo est notée par un σ de bruit mesuré en pleine résolution ; seules celles au-dessus du seuil sont débruitées. Repères de σ : ISO 200 ≈ 0.4, ISO 8000 ≈ 2.1, ISO 51200 ≈ 3.8. Le débruitage cible d'abord le bruit chroma (points colorés, le plus gênant) et préserve le grain de luminance.

## Prérequis

- **Fedora** (testé sur 44)
  ```
  sudo dnf install darktable ImageMagick ffmpeg perl-Image-ExifTool
  ```
- **Python 3** (utilise miniconda si dispo, sinon system python3) + **PySide6** (installé par `install.sh`)

## Installation

```bash
cd photo-souvenir
bash install.sh
```

Installe :
- `~/.local/bin/photo-souvenir` (exécutable)
- `~/.local/share/applications/photo-souvenir.desktop` (entrée menu Plasma)
- les LUTs dans `~/.local/share/photo-souvenir/luts`
- `PySide6` via pip dans le Python détecté

## Usage

### UI
Lance `photo-souvenir` sans argument, ou cherche **Photo Souvenir** dans le menu.

- Sélectionne le dossier source contenant tes RAW
- Choisis le style (LUT), garde le mode adaptatif coché
- Ajuste éventuellement force du LUT / contraste / cible d'expo / saturation
- Clique **Lancer** — les JPEG sortent dans `Retouche_Portra/`

### CLI

```bash
# look Portra adaptatif (defaut), sortie dans <dossier>/Retouche_Portra
photo-souvenir "/chemin/vers/dossier"

# autre style, contraste plus doux, LUT plus discret
photo-souvenir "/dossier" --style cinema-kodak --contrast 4 --lut-strength 60

# LUT custom, sans adaptatif, JPEG plus legers
photo-souvenir "/dossier" /sortie --lut /chemin/look.cube --no-adaptive --quality 88

# debruite seulement les photos tres bruitees (ISO eleve)
photo-souvenir "/dossier" --denoise auto --noise-threshold 1.5
```

Options principales : `--style` (portrait/cinema-kodak/cinema-fuji/vintage/chrome/bw/neutral/custom), `--lut`, `--no-adaptive`, `--target`, `--contrast`, `--lut-strength`, `--saturation`, `--quality`, `--max-size`, `--denoise` (off/auto/always), `--noise-threshold`, `--workers`.

## LUTs

LUTs film bundlées (Film LUTs, licence MIT — voir `luts/LICENSE-Film-Luts.txt`) :
Portrait Portra · Cinema Kodak 2383 · Cinema Fuji 3510 · Vintage Superia · Fuji Classic Chrome · N&B Tri-X.

Tu peux aussi déposer un `look.cube` dans le dossier source : il est auto-détecté.

## Voir aussi

[video-souvenir](../video-souvenir) — le pendant vidéo (assemble des clips en montage HEVC / projet Kdenlive). Mêmes LUTs, même esprit.
