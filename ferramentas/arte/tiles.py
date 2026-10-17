"""Tiles das Catacumbas de Cal (16×16, vista 3/4).

Peças geradas:
- chão: lajes de pedra fria com variações (rachaduras, musgo, terra, ossinhos)
- topo: topo escuro das paredes, com borda iluminada — 256 combinações (máscara de 8 vizinhos)
- face: parede frontal caiada (2 tiles de altura): parte de cima (cal, manchas, nichos, raízes)
        e parte de baixo (faixa de azulejos + rodapé); "única" para paredes de 1 tile
- sombra: oclusão ambiente sobre o chão junto às paredes — 256 combinações
"""
import json

from PIL import Image

from paleta import rgba
from util import ARTE, imagem, ruido

T = 16
# Bits da máscara de vizinhos (parede = 1)
N, NE, L, SE, S, SO, O, NO = 1, 2, 4, 8, 16, 32, 64, 128


def _px(img, x, y, c, alfa=255):
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), rgba(c, alfa))


# --- Chão ---------------------------------------------------------------------

def _laje(img, x0, y0, w, h, r, base="4"):
    """Laje de pedra: textura discreta, aresta superior iluminada, sombra inferior, rejunte suave."""
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            c = base
            v = r.random()
            if v < 0.035:
                c = "5" if base == "4" else "4"
            elif v < 0.07:
                c = "3" if base == "4" else "2"
            _px(img, x, y, c)
    for x in range(x0, x0 + w):
        _px(img, x, y0, "2")              # rejunte superior
        if w > 2:
            _px(img, x, y0 + 1, "5" if base == "4" else "4")
        _px(img, x, y0 + h - 1, "3" if base == "4" else "2")
    for y in range(y0, y0 + h):
        _px(img, x0, y, "2")              # rejunte esquerdo
    _px(img, x0 + 1, y0 + 1, "6" if base == "4" else "5")


def _rachadura(img, r, comprimento=7):
    x, y = r.randint(4, 11), r.randint(4, 9)
    for _ in range(comprimento):
        _px(img, x, y, "2")
        x += r.choice([-1, 0, 1, 1])
        y += r.choice([0, 1])


def _manchas(img, r, cores, n, borda=2):
    for _ in range(n):
        x, y = r.randint(borda, T - 1 - borda), r.randint(borda, T - 1 - borda)
        for dx, dy in [(0, 0), (1, 0), (0, 1), (-1, 0), (1, 1)]:
            if r.random() < 0.6:
                _px(img, x + dx, y + dy, r.choice(cores))


def gerar_chao():
    variantes = []
    pesos = []
    divisoes = [
        [(0, 0, 16, 16)],
        [(0, 0, 16, 16)],
        [(0, 0, 16, 8), (0, 8, 16, 8)],
        [(0, 0, 16, 16)],
    ]
    for i in range(16):
        r = ruido(1000 + i)
        img = Image.new("RGBA", (T, T))
        partes = divisoes[i % len(divisoes)]
        for (x, y, w, h) in partes:
            _laje(img, x, y, w, h, r, base="4" if r.random() < 0.75 else "3")
        tipo = i // 4
        if tipo == 1:
            _rachadura(img, r, 7)
        elif tipo == 2:
            _manchas(img, r, ["M", "g"], 2)            # musgo no rejunte
            for x in range(0, T):
                if r.random() < 0.35:
                    _px(img, x, 0, "M")
        elif tipo == 3:
            _manchas(img, r, ["h", "H"], 3)            # terra
        variantes.append(img)
        pesos.append([12, 3, 2, 2][tipo])
    return variantes, pesos


# --- Topo de parede -------------------------------------------------------------

def topo(mascara):
    """Topo escuro da parede; bordas iluminadas onde o vizinho NÃO é parede."""
    r = ruido(5000 + mascara)
    img = Image.new("RGBA", (T, T))
    for y in range(T):
        for x in range(T):
            _px(img, x, y, "2" if r.random() < 0.08 else "1")
    def livre(bit):
        return not (mascara & bit)
    # Bordas retas
    if livre(N):
        for x in range(T):
            _px(img, x, 0, "5"); _px(img, x, 1, "3")
    if livre(S):
        for x in range(T):
            _px(img, x, T - 1, "4"); _px(img, x, T - 2, "2")
    if livre(O):
        for y in range(T):
            _px(img, 0, y, "4"); _px(img, 1, y, "2")
    if livre(L):
        for y in range(T):
            _px(img, T - 1, y, "4"); _px(img, T - 2, y, "2")
    # Cantos internos (vizinhos retos são parede, diagonal não)
    for bit_a, bit_b, bit_d, (cx, cy) in [(N, O, NO, (0, 0)), (N, L, NE, (T - 1, 0)),
                                         (S, O, SO, (0, T - 1)), (S, L, SE, (T - 1, T - 1))]:
        if not livre(bit_a) and not livre(bit_b) and livre(bit_d):
            _px(img, cx, cy, "4")
    # Cantos externos arredondados
    for bit_a, bit_b, (cx, cy) in [(N, O, (0, 0)), (N, L, (T - 1, 0)), (S, O, (0, T - 1)), (S, L, (T - 1, T - 1))]:
        if livre(bit_a) and livre(bit_b):
            _px(img, cx, cy, "3")
    return img


# --- Face de parede -----------------------------------------------------------

AZULEJO = """
9wwBBww9
wwBzzBww
wBzbbzBw
BzbaabzB
BzbaabzB
wBzbbzBw
wwBzzBww
9wwBBww9
"""


def _cal(img, r, y0, y1):
    for y in range(y0, y1):
        for x in range(T):
            v = r.random()
            c = "8"
            if v < 0.05:
                c = "9"
            elif v < 0.08:
                c = "7"
            _px(img, x, y, c)
    # manchas largas e suaves de umidade (pontilhadas)
    for _ in range(2):
        cx, cy = r.randint(0, T - 1), r.randint(y0, max(y0, y1 - 1))
        for y in range(cy - 2, cy + 3):
            for x in range(cx - 3, cx + 4):
                if y0 <= y < y1 and (x + y) % 2 == 0 and r.random() < 0.7:
                    _px(img, x % T, y, "7")


def _escorrido(img, r, x, y0, comp, cor="7"):
    for y in range(y0, y0 + comp):
        _px(img, x, y, cor if y < y0 + comp - 1 else "6")


def face_cima(variante):
    r = ruido(7000 + variante)
    img = Image.new("RGBA", (T, T))
    _cal(img, r, 0, T)
    for x in range(T):                     # beiral (aresta superior)
        _px(img, x, 0, "9"); _px(img, x, 1, "w"); _px(img, x, 2, "7")
    if variante == 0:
        for _ in range(2):
            _escorrido(img, r, r.randint(1, 14), 3, r.randint(3, 8))
    elif variante == 1:                     # rachadura com pedra exposta
        x, y = r.randint(4, 10), 4
        for _ in range(9):
            _px(img, x, y, "5"); _px(img, x + 1, y, "4")
            x += r.choice([-1, 0, 1]); y += 1
        _escorrido(img, r, r.randint(1, 3), 3, 6)
    elif variante == 2:                     # nicho de ossuário com crânio
        nicho = imagem("""
            ..222222..
            .21111112.
            2110000112
            2100WWw012
            210W0W0w12
            210wWWw912
            2100w9w012
            2112222112
            2333333332
            """)
        img.alpha_composite(nicho, (3, 4))
    elif variante == 3:                     # raiz rompendo a cal
        raiz = imagem("""
            ......66........
            .....6hH6.......
            .....6hjH6......
            ......6hjH66....
            .......6hjjH6...
            .....66.6hjjH6..
            ....6hH6.6hjjH6.
            ...6hjH6..6hjjH6
            ..6hjH6....6hjjH
            ..6hH6......6hjj
            ...hq........6hj
            ...6..........6h
            """)
        img.alpha_composite(raiz, (0, 3))
        _px(img, 9, 8, "q"); _px(img, 13, 11, "q")
    elif variante == 4:                     # vela votiva num suporte
        _escorrido(img, r, 7, 3, 3)
        vela = imagem("""
            ..Y..
            .YLY.
            ..y..
            .WWW.
            .w9w.
            .w9w.
            7777777
            .6666.
            """)
        img.alpha_composite(vela, (5, 5))
    return img


def face_baixo(variante):
    r = ruido(8000 + variante)
    img = Image.new("RGBA", (T, T))
    _cal(img, r, 0, 4)
    az = imagem(AZULEJO)
    for i in range(2):
        img.alpha_composite(az, (i * 8, 3))
    if variante == 1:                       # azulejo lascado
        for (x, y) in [(9, 4), (10, 4), (10, 5), (11, 5), (9, 6), (12, 4), (11, 4)]:
            _px(img, x, y, "5")
        _px(img, 10, 6, "4")
    elif variante == 2:                     # raiz saindo pelo rodapé
        for (x, y) in [(3, 7), (4, 8), (4, 9), (5, 10), (5, 11), (6, 12), (6, 13), (7, 14)]:
            _px(img, x, y, "h"); _px(img, x + 1, y, "j")
        _px(img, 4, 9, "q")
    for x in range(T):                      # rodapé
        _px(img, x, 11, "6")
        _px(img, x, 12, "5")
        _px(img, x, 13, "3")
        _px(img, x, 14, "2")
        _px(img, x, 15, "1")
    for x in range(0, T, 4):
        _px(img, x, 12, "4")
    return img


def face_unica(variante):
    """Parede de um tile de altura: beiral + azulejos + rodapé comprimidos."""
    r = ruido(9000 + variante)
    img = Image.new("RGBA", (T, T))
    _cal(img, r, 0, T)
    for x in range(T):
        _px(img, x, 0, "9"); _px(img, x, 1, "w"); _px(img, x, 2, "7")
    az = imagem(AZULEJO)
    for i in range(2):
        img.alpha_composite(az.crop((0, 1, 8, 7)), (i * 8, 4))
    for x in range(T):
        _px(img, x, 11, "6"); _px(img, x, 12, "5"); _px(img, x, 13, "3"); _px(img, x, 14, "2"); _px(img, x, 15, "1")
    if variante == 1:
        _px(img, 5, 6, "5"); _px(img, 6, 6, "5"); _px(img, 6, 7, "4")
    return img


def com_pontas(img, esquerda, direita):
    """Escurece a ponta de uma sequência de face (onde ela encontra o topo lateral)."""
    out = img.copy()
    for y in range(T):
        if esquerda:
            _px(out, 0, y, "2"); _px(out, 1, y, "6") if out.getpixel((1, y))[3] else None
        if direita:
            _px(out, T - 1, y, "2"); _px(out, T - 2, y, "6") if out.getpixel((T - 2, y))[3] else None
    return out


# --- Sombra (oclusão ambiente no chão) ---------------------------------------

def sombra(mascara):
    img = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    escuro = (11, 9, 16)

    def pintar(x, y, alfa):
        if 0 <= x < T and 0 <= y < T:
            atual = img.getpixel((x, y))[3]
            if alfa > atual:
                img.putpixel((x, y), (*escuro, alfa))

    for y in range(T):
        for x in range(T):
            if mascara & N:
                if y < 2: pintar(x, y, 150)
                elif y < 4: pintar(x, y, 110 if (x + y) % 2 == 0 else 60)
                elif y < 6: pintar(x, y, 60 if (x + y) % 2 == 0 else 0)
            if mascara & O:
                if x < 1: pintar(x, y, 120)
                elif x < 3: pintar(x, y, 80 if (x + y) % 2 == 0 else 30)
            if mascara & L:
                if x > T - 2: pintar(x, y, 120)
                elif x > T - 4: pintar(x, y, 80 if (x + y) % 2 == 0 else 30)
            if mascara & S:
                if y > T - 2: pintar(x, y, 70)
            if (mascara & NO) and not (mascara & (N | O)):
                if x < 3 and y < 3: pintar(x, y, 90)
            if (mascara & NE) and not (mascara & (N | L)):
                if x > T - 4 and y < 3: pintar(x, y, 90)
    return img


# --- Montagem -----------------------------------------------------------------

def gerar():
    destino = ARTE / "tiles" / "catacumbas"
    destino.mkdir(parents=True, exist_ok=True)

    chao, pesos = gerar_chao()
    atlas_chao = Image.new("RGBA", (T * 4, T * 4))
    for i, img in enumerate(chao):
        atlas_chao.alpha_composite(img, ((i % 4) * T, (i // 4) * T))
    atlas_chao.save(destino / "chao.png")

    atlas_topo = Image.new("RGBA", (T * 16, T * 16))
    for m in range(256):
        atlas_topo.alpha_composite(topo(m), ((m % 16) * T, (m // 16) * T))
    atlas_topo.save(destino / "topo.png")

    atlas_sombra = Image.new("RGBA", (T * 16, T * 16))
    for m in range(256):
        atlas_sombra.alpha_composite(sombra(m), ((m % 16) * T, (m // 16) * T))
    atlas_sombra.save(destino / "sombra.png")

    # Face: cada linha é uma variante; colunas = pontas (nenhuma, esquerda, direita, ambas)
    linhas = []
    meta_face = {"cima": [], "baixo": [], "unica": []}
    pesos_face = {"cima": [8, 3, 2, 2, 1], "baixo": [8, 2, 1], "unica": [3, 1]}
    for tipo, fabrica, n in [("cima", face_cima, 5), ("baixo", face_baixo, 3), ("unica", face_unica, 2)]:
        for v in range(n):
            meta_face[tipo].append(len(linhas))
            linhas.append(fabrica(v))
    atlas_face = Image.new("RGBA", (T * 4, T * len(linhas)))
    for linha, img in enumerate(linhas):
        for col, (e, d) in enumerate([(False, False), (True, False), (False, True), (True, True)]):
            atlas_face.alpha_composite(com_pontas(img, e, d), (col * T, linha * T))
    atlas_face.save(destino / "face.png")

    meta = {
        "tamanho": T,
        "chao": {"imagem": "chao.png", "colunas": 4, "pesos": pesos},
        "topo": {"imagem": "topo.png", "colunas": 16},
        "sombra": {"imagem": "sombra.png", "colunas": 16},
        "face": {"imagem": "face.png", "linhas": meta_face, "pesos": pesos_face},
    }
    (destino / "tiles.json").write_text(json.dumps(meta, indent=1), encoding="utf-8")
    return destino


if __name__ == "__main__":
    print(gerar())
