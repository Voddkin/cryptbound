#!/usr/bin/env bash
# Exporta as versões Windows (x86_64) e Linux do CRYPTBOUND e confere o resultado.
# Uso: ferramentas/exportar.sh [windows|linux|todos]
set -euo pipefail
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-godot}"
ALVO="${1:-todos}"
cd "$RAIZ"
timeout 600 "$GODOT" --headless --path . --import >/dev/null 2>&1 || true

exportar() {
  local preset="$1" saida="$2"
  mkdir -p "$(dirname "$saida")"
  rm -f "$saida"
  echo "== Exportando $preset → $saida"
  timeout 900 "$GODOT" --headless --path . --export-release "$preset" "$saida" 2>&1 | grep -vE "^\s*$|reimport|Godot Engine" || true
  if [[ ! -s "$saida" ]]; then
    echo "ERRO: exportação de $preset não gerou $saida"
    exit 1
  fi
  ls -la "$(dirname "$saida")"
}

if [[ "$ALVO" == "windows" || "$ALVO" == "todos" ]]; then
  exportar "Windows Desktop" "build/windows/CRYPTBOUND.exe"
  python3 - "build/windows/CRYPTBOUND.exe" <<'EOF'
import sys, pefile
pe = pefile.PE(sys.argv[1])
print("PE32+ (64 bits):", pe.OPTIONAL_HEADER.Magic == 0x20B, "| máquina:", hex(pe.FILE_HEADER.Machine))
icones = 0
info = {}
if hasattr(pe, "DIRECTORY_ENTRY_RESOURCE"):
    for e in pe.DIRECTORY_ENTRY_RESOURCE.entries:
        if e.id == 3:  # RT_ICON
            icones = sum(len(s.directory.entries) for s in e.directory.entries)
if hasattr(pe, "FileInfo"):
    for fi in pe.FileInfo:
        for item in fi:
            if hasattr(item, "StringTable"):
                for st in item.StringTable:
                    info.update({k.decode(): v.decode() for k, v in st.entries.items()})
print("ícones embutidos:", icones)
print("ProductName:", info.get("ProductName"), "| FileVersion:", info.get("FileVersion"), "| CompanyName:", info.get("CompanyName"))
EOF
fi
if [[ "$ALVO" == "linux" || "$ALVO" == "todos" ]]; then
  exportar "Linux" "build/linux/cryptbound.x86_64"
fi
