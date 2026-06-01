#!/usr/bin/env bash
# Installe photo-souvenir (script Python + .desktop) dans le user-space.
# Detecte le Python a utiliser, installe PySide6, substitue les chemins.

set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
warn() { printf '\033[33mATTENTION: %s\033[0m\n' "$*"; }
ok()   { printf '  \033[32mOK\033[0m %s\n' "$*"; }
err()  { printf '\033[31mERREUR: %s\033[0m\n' "$*" >&2; }

# --- Prerequis ---
bold "Verification des prerequis"

command -v darktable-cli >/dev/null || { err "darktable-cli manquant (sudo dnf install darktable)"; exit 1; }
ok "darktable-cli"
command -v ffmpeg >/dev/null  || { err "ffmpeg manquant"; exit 1; }
ok "ffmpeg"
if command -v magick >/dev/null || command -v convert >/dev/null; then
  ok "ImageMagick"
else
  err "ImageMagick manquant (sudo dnf install ImageMagick)"; exit 1
fi
if command -v exiftool >/dev/null; then
  ok "exiftool"
else
  warn "exiftool absent -> metadonnees/orientation non recopiees (sudo dnf install perl-Image-ExifTool)"
fi

# --- Detection Python ---
bold "Detection de Python"
PYTHON=""
for cand in "$HOME/miniconda3/bin/python3" "$HOME/anaconda3/bin/python3" "$HOME/.local/bin/python3" "$(command -v python3 || true)"; do
  if [[ -n "$cand" && -x "$cand" ]]; then PYTHON="$cand"; break; fi
done
[[ -z "$PYTHON" ]] && { err "Python 3 introuvable"; exit 1; }
ok "Python: $PYTHON"

# --- Install dependances Python (PySide6 pour l'UI, numpy/Pillow pour la detection de bruit) ---
bold "Installation des dependances Python"
pip_install() {
  "$PYTHON" -m pip install --quiet "$@" 2>/dev/null || "$PYTHON" -m pip install --quiet --user "$@"
}
if "$PYTHON" -c "import PySide6" 2>/dev/null; then
  ok "PySide6 deja installe"
else
  echo "  Installation de PySide6..."; pip_install PySide6; ok "PySide6 installe"
fi
if "$PYTHON" -c "import numpy, PIL" 2>/dev/null; then
  ok "numpy / Pillow deja installes"
else
  echo "  Installation de numpy + Pillow (detection de bruit)..."; pip_install numpy Pillow
  ok "numpy / Pillow installes"
fi

# --- Install script ---
bold "Installation du script"
BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"
mkdir -p "$BIN_DIR" "$APP_DIR" "$ICON_DIR"

sed "1s|.*|#!$PYTHON|" photo-souvenir > "$BIN_DIR/photo-souvenir"
chmod +x "$BIN_DIR/photo-souvenir"
ok "$BIN_DIR/photo-souvenir"

sed "s|/home/goss/.local/bin/photo-souvenir|$BIN_DIR/photo-souvenir|g" photo-souvenir.desktop > "$APP_DIR/photo-souvenir.desktop"
ok "$APP_DIR/photo-souvenir.desktop"

cp -f photo-souvenir.svg "$ICON_DIR/photo-souvenir.svg"
ok "$ICON_DIR/photo-souvenir.svg"

# PNG multi-tailles (KDE/Plasma resout plus fiablement le PNG que le SVG seul)
MAGICK="$(command -v magick || command -v convert || true)"
if [[ -n "$MAGICK" ]]; then
  for sz in 32 48 64 128 256; do
    d="$HOME/.local/share/icons/hicolor/${sz}x${sz}/apps"
    mkdir -p "$d"
    "$MAGICK" -background none photo-souvenir.svg -resize ${sz}x${sz} "$d/photo-souvenir.png" 2>/dev/null
  done
  ok "icones PNG 32->256 generees"
fi

# --- Install LUTs ---
LUT_DIR="$HOME/.local/share/photo-souvenir/luts"
mkdir -p "$LUT_DIR"
if [[ -d luts ]]; then
  cp -f luts/*.cube "$LUT_DIR/" 2>/dev/null && \
    ok "$(ls $LUT_DIR/*.cube 2>/dev/null | wc -l) LUTs installees dans $LUT_DIR"
fi

# --- Refresh menu + caches d'icones KDE/GNOME ---
rm -f "$HOME/.cache/icon-cache.kcache" 2>/dev/null || true
command -v gtk-update-icon-cache >/dev/null && gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true
command -v kbuildsycoca6 >/dev/null && kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
command -v update-desktop-database >/dev/null && update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true

if ! echo ":$PATH:" | grep -q ":$BIN_DIR:"; then
  warn "$BIN_DIR n'est pas dans ton PATH. Ajoute a ton ~/.bashrc :"
  echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

bold "Installe."
echo "  Lance avec: photo-souvenir                   (UI)"
echo "          ou: photo-souvenir <dossier>         (CLI)"
echo "  Ou via le menu Plasma: cherche 'Photo Souvenir'"
