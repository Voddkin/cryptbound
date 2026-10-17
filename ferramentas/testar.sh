#!/usr/bin/env bash
# Roda a suíte de testes do CRYPTBOUND (headless, quadros fixos = simulação determinística).
# Uso: ferramentas/testar.sh [filtro]
set -euo pipefail
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-godot}"
cd "$RAIZ"
# Importa recursos novos/alterados antes de testar.
timeout 600 "$GODOT" --headless --path . --import >/dev/null 2>&1 || true
saida="$(mktemp)"
set +e
timeout 1200 "$GODOT" --headless --fixed-fps 60 --path . res://testes/executar_testes.tscn -- "${1:-}" 2>&1 | tee "$saida"
codigo=${PIPESTATUS[0]}
set -e
if ! grep -q "^RESULTADO:" "$saida"; then
  echo "ERRO: o executor terminou sem imprimir o resultado (código $codigo)."
  codigo=1
fi
rm -f "$saida"
exit "$codigo"
