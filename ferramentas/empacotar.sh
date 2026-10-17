#!/usr/bin/env bash
# Monta o pacote Windows para distribuição: CRYPTBOUND.exe + LEIA-ME + licenças, num .zip.
# Rode ferramentas/exportar.sh antes. Uso: ferramentas/empacotar.sh [pasta de saída]
set -euo pipefail
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-godot}"
cd "$RAIZ"
VERSAO="$(sed -n 's/^config\/version="\(.*\)"/\1/p' project.godot)"
SAIDA="$(mkdir -p "${1:-entregas}" && cd "${1:-entregas}" && pwd)"
touch "$SAIDA/.gdignore"  # o Godot não deve importar o que está aqui
EXE="build/windows/CRYPTBOUND.exe"
if [[ ! -s "$EXE" ]]; then
  echo "ERRO: $EXE não existe; rode ferramentas/exportar.sh windows antes."
  exit 1
fi
TEMP="$(mktemp -d)"
trap 'rm -rf "$TEMP"' EXIT
PASTA="$TEMP/CRYPTBOUND-$VERSAO"
mkdir -p "$PASTA"
cp "$EXE" "$PASTA/"
# Textos com quebra de linha do Windows (CRLF) para abrir bem no Bloco de Notas.
sed "s/{versao}/$VERSAO/; s/\$/\r/" ferramentas/pacote/LEIA-ME.txt > "$PASTA/LEIA-ME.txt"
sed 's/$/\r/' fontes/OFL.txt > "$PASTA/OFL.txt"
"$GODOT" --headless --path . -s res://ferramentas/pacote/licencas.gd -- "$TEMP/licencas.txt" >/dev/null 2>&1
if [[ ! -s "$TEMP/licencas.txt" ]]; then
  echo "ERRO: não foi possível gerar as licenças do Godot."
  exit 1
fi
sed 's/$/\r/' "$TEMP/licencas.txt" > "$PASTA/LICENCAS.txt"
ZIP="$SAIDA/CRYPTBOUND-windows-x64-$VERSAO.zip"
rm -f "$ZIP"
(cd "$TEMP" && zip -9 -r -q "$ZIP" "CRYPTBOUND-$VERSAO")
unzip -l "$ZIP"
