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


def gerar(arquivo: str, nome: str, tamanho: float, entrelinha: int) -> None:
    fonte = ImageFont.truetype(str(ORIGEM / arquivo), tamanho)
    ascendente, descendente = fonte.getmetrics()
    glifos = []
    for ch in CARACTERES:
        try:
            esquerda, topo, direita, base = fonte.getbbox(ch)
        except Exception:
            continue
        avanco = round(fonte.getlength(ch))
        largura, altura = max(direita - esquerda, 0), max(base - topo, 0)
        img = None
        if largura > 0 and altura > 0:
            img = Image.new("L", (largura + 2, altura + 2), 0)
            d = ImageDraw.Draw(img)
            d.fontmode = "1"
            d.text((1 - esquerda, 1 - topo), ch, font=fonte, fill=255)
            caixa = img.getbbox()
            if caixa:
                img = img.crop(caixa)
                esquerda += caixa[0] - 1
                topo += caixa[1] - 1
                largura, altura = img.size
            else:
                img = None
        glifos.append((ch, img, esquerda, topo, largura if img else 0, altura if img else 0, avanco))

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
