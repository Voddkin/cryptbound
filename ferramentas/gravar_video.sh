#!/usr/bin/env bash
# Grava um vídeo do robô de demonstração jogando (Movie Maker do Godot sob Xvfb) e
# converte para MP4 ampliado 2× sem suavização (1280×720), pronto para compartilhar.
# Uso: ferramentas/gravar_video.sh [segundos] [saída.mp4]
set -euo pipefail
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-godot}"
SEGUNDOS="${1:-60}"
SAIDA="${2:-$RAIZ/entregas/cryptbound-demo.mp4}"
FPS=60
cd "$RAIZ"
mkdir -p "$(dirname "$SAIDA")" capturas
AVI="capturas/video_bruto.avi"
rm -f "$AVI"
timeout 1800 xvfb-run -a -s "-screen 0 1280x720x24" "$GODOT" --path . --rendering-driver opengl3 \
  --fixed-fps "$FPS" --write-movie "$AVI" --quit-after $((SEGUNDOS * FPS)) \
  res://jogo/mundo/descida.tscn -- --demo > capturas/log_video.txt 2>&1 || true
if [[ ! -s "$AVI" ]]; then
  echo "ERRO: o Godot não gravou o vídeo (veja capturas/log_video.txt)."
  exit 1
fi
ffmpeg -v error -y -i "$AVI" -vf "scale=iw*2:ih*2:flags=neighbor,format=yuv420p" \
  -c:v libx264 -preset slow -crf 18 -c:a aac -b:a 160k -movflags +faststart "$SAIDA"
rm -f "$AVI"
ls -la "$SAIDA"
