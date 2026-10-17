#!/usr/bin/env python3
"""Converte as fontes pixel (TTF, licença OFL) em fontes bitmap BMFont (.fnt + .png)
na grade exata de pixels, para que o Godot as desenhe sem serrilhado nem borrão.

Uso: python3 ferramentas/arte/gerar_fontes.py
Saída: fontes/<nome>.fnt e fontes/<nome>.png
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

RAIZ = Path(__file__).resolve().parents[2]
ORIGEM = Path(__file__).resolve().parent / "fontes_origem"
DESTINO = RAIZ / "fontes"

# (arquivo, nome de saída, tamanho em px da grade nativa, entrelinha extra)
FONTES = [
    ("Jacquard12-Regular.ttf", "jacquard12", 1260 / 60, 1),
    ("Jersey10-Regular.ttf", "jersey10", 1400 / 75, 0),
    ("Micro5-Regular.ttf", "micro5", 1650 / 150, 1),
]

CARACTERES = (
    "".join(chr(c) for c in range(32, 127))
    + "ÀÁÂÃÄÇÈÉÊËÌÍÎÏÑÒÓÔÕÖÙÚÛÜÝàáâãäçèéêëìíîïñòóôõöùúûüýÿ"
    + "ºª°·•—–…“”‘’«»×¿¡"
)


SUPER = 8


def _rasterizar(fonte_grande, ch):
    """Renderiza o glifo em 8× e amostra o centro de cada bloco de 8×8 (sem efeito de hinting).
    Devolve (imagem L, esquerda, topo) em pixels da grade nativa, ou (None, 0, 0)."""
    esquerda, topo, direita, base = fonte_grande.getbbox(ch)
    if direita <= esquerda or base <= topo:
        return None, 0, 0
    x0, y0 = esquerda // SUPER - 1, topo // SUPER - 1
    x1, y1 = -(-direita // SUPER) + 1, -(-base // SUPER) + 1
    grande = Image.new("L", ((x1 - x0) * SUPER, (y1 - y0) * SUPER), 0)
    ImageDraw.Draw(grande).text((-x0 * SUPER, -y0 * SUPER), ch, font=fonte_grande, fill=255)
    w, h = x1 - x0, y1 - y0
    pequena = Image.new("L", (w, h), 0)
    px = grande.load()
    for y in range(h):
        for x in range(w):
            if px[x * SUPER + SUPER // 2, y * SUPER + SUPER // 2] > 127:
                pequena.putpixel((x, y), 255)
    caixa = pequena.getbbox()
    if not caixa:
        return None, 0, 0
    return pequena.crop(caixa), x0 + caixa[0], y0 + caixa[1]


def gerar(arquivo: str, nome: str, tamanho: float, entrelinha: int) -> None:
    fonte = ImageFont.truetype(str(ORIGEM / arquivo), tamanho)
    fonte_grande = ImageFont.truetype(str(ORIGEM / arquivo), tamanho * SUPER)
    ascendente, descendente = fonte.getmetrics()
    glifos = []
    for ch in CARACTERES:
        avanco = round(fonte_grande.getlength(ch) / SUPER)
        img, esquerda, topo = _rasterizar(fonte_grande, ch)
        largura, altura = img.size if img else (0, 0)
        glifos.append((ch, img, esquerda, topo, largura, altura, avanco))

    # Empacota em linhas numa folha de 256 px de largura.
    largura_folha, x, y, linha = 256, 1, 1, 0
    posicoes = {}
    for ch, img, *_ in glifos:
        if img is None:
            posicoes[ch] = (0, 0)
            continue
        w, h = img.size
        if x + w + 1 > largura_folha:
            x, y, linha = 1, y + linha + 1, 0
        posicoes[ch] = (x, y)
        x += w + 1
        linha = max(linha, h)
    altura_folha = 1
    while altura_folha < y + linha + 2:
        altura_folha *= 2
    folha = Image.new("RGBA", (largura_folha, altura_folha), (0, 0, 0, 0))
    for ch, img, *_ in glifos:
        if img is not None:
            branco = Image.new("RGBA", img.size, (255, 255, 255, 255))
            folha.paste(branco, posicoes[ch], img.point(lambda v: 255 if v > 127 else 0))
    folha.save(DESTINO / f"{nome}.png")

    tamanho_int = round(tamanho)
    altura_linha = ascendente + descendente + entrelinha
    linhas = [
        f'info face="{nome}" size={tamanho_int} bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=0 padding=0,0,0,0 spacing=1,1 outline=0',
        f"common lineHeight={altura_linha} base={ascendente} scaleW={largura_folha} scaleH={altura_folha} pages=1 packed=0 alphaChnl=0 redChnl=4 greenChnl=4 blueChnl=4",
        f'page id=0 file="{nome}.png"',
        f"chars count={len(glifos)}",
    ]
    for ch, img, esquerda, topo, w, h, avanco in glifos:
        px, py = posicoes[ch]
        linhas.append(
            f"char id={ord(ch)} x={px} y={py} width={w} height={h} xoffset={esquerda if img else 0} "
            f"yoffset={topo if img else 0} xadvance={avanco} page=0 chnl=15"
        )
    (DESTINO / f"{nome}.fnt").write_text("\n".join(linhas) + "\n", encoding="utf-8")
    print(f"{nome}: {len(glifos)} glifos, tamanho {tamanho_int}px, linha {altura_linha}px, folha {largura_folha}x{altura_folha}")


def main() -> None:
    DESTINO.mkdir(exist_ok=True)
    for args in FONTES:
        gerar(*args)


if __name__ == "__main__":
    main()
