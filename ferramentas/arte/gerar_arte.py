#!/usr/bin/env python3
"""Regenera toda a arte do jogo a partir das fontes em ferramentas/arte/.

Uso: python3 ferramentas/arte/gerar_arte.py
A arte é determinística (sementes fixas): rodar de novo produz os mesmos arquivos.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import coveira  # noqa: E402
import gerar_fontes  # noqa: E402
import inimigos  # noqa: E402
import objetos  # noqa: E402
import tiles  # noqa: E402


def main() -> None:
    print("Tiles:", tiles.gerar())
    print("Coveira:", coveira.gerar())
    for caminho in inimigos.gerar():
        print("Inimigo:", caminho)
    objetos.gerar()
    print("Objetos, itens, interface, luzes e ícone: ok")
    gerar_fontes.main()


if __name__ == "__main__":
    main()
