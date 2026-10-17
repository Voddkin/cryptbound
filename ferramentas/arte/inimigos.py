"""Inimigos das Catacumbas de Cal: Ressequido e Lamuriante (+ projétil Lamúria).

Ressequido (24×24, de lado, olhando para a direita): cadáver seco movido por raízes.
O tronco é desenhado à mão; braços e pernas são linhas procedurais (fáceis de animar).

Lamuriante (24×32, de frente, flutuando): figura velada de cera com velas acesas
derretendo sobre a cabeça. Lança a Lamúria (onda roxa) e fortalece Ressequidos.
"""
import math

from PIL import Image, ImageDraw

from paleta import rgba
from util import contornar, imagem, salvar_sprite, trocar_cores

# --- Ressequido ----------------------------------------------------------------

TRONCO_RESSEQUIDO = """
..............
..............
h.............
.h.......999..
.hjh....9WWW9.
..hdDh.9W1QW9.
.qhDDDd9WW1W98
.dDfDDDD899W8.
.dDDf8DD.8W8W.
.dD8fD8D..88..
.dDf8D8Dd.....
..dD8D8Dd.....
..ddDfDd......
...dHjHd......
...HjjHH......
...HHjHH......
....H.H.......
"""
# Pontos (relativos ao canto do tronco): ombro e quadril
OMBRO = (7, 8)
QUADRIL = (5, 15)


def _linha(img, a, b, cor_a="d", cor_b="D", espessura=1):
    d = ImageDraw.Draw(img)
    d.line([a, b], fill=rgba(cor_a), width=espessura)
    if espessura == 1:
        # realce de 1 px deslocado para cima
        d.line([(a[0], a[1] - 1), (b[0], b[1] - 1)], fill=rgba(cor_b), width=1)


def _garras(img, mao, direcao=1):
    x, y = mao
    for (dx, dy) in [(1, 0), (2, 1), (1, 2), (0, 2)]:
        px, py = x + dx * direcao, y + dy
        if 0 <= px < img.width and 0 <= py < img.height:
            img.putpixel((px, py), rgba("W" if dy < 2 else "8"))


def quadro_ressequido(desloc=(0, 0), mao_frente=(3, 7), mao_tras=(1, 6), pes=((-3, 0), (2, 0)),
                       joelhos=(0, 0), olho="Q", inclinar=0):
    """desloc: deslocamento do tronco; mãos relativas ao ombro; pés relativos ao quadril."""
    q = Image.new("RGBA", (24, 24))
    ox, oy = 4 + desloc[0], 2 + desloc[1]
    tronco = imagem(TRONCO_RESSEQUIDO)
    if olho != "Q":
        tronco = trocar_cores(tronco, {"Q": olho})
    camada_tras = Image.new("RGBA", (24, 24))
    camada_frente = Image.new("RGBA", (24, 24))
    ombro = (ox + OMBRO[0], oy + OMBRO[1])
    quadril = (ox + QUADRIL[0], oy + QUADRIL[1])
    # braço de trás (mais escuro)
    mt = (ombro[0] + mao_tras[0] - 2, ombro[1] + mao_tras[1])
    _linha(camada_tras, (ombro[0] - 2, ombro[1]), mt, "1", "d")
    _garras(camada_tras, mt)
    # pernas: quadril → joelho → pé
    for i, (pe, cor) in enumerate(zip(pes, ("1", "d"))):
        pe_abs = (quadril[0] + pe[0], 23 - pe[1])
        joelho = ((quadril[0] + pe_abs[0]) // 2 + 2 + joelhos[i], (quadril[1] + pe_abs[1]) // 2)
        alvo = camada_tras if i == 0 else camada_frente
        _linha(alvo, quadril, joelho, cor, "D" if i else "d")
        _linha(alvo, joelho, pe_abs, cor, "D" if i else "d")
        alvo.putpixel((min(pe_abs[0] + 1, 23), pe_abs[1]), rgba(cor))
    # raiz que sai das costas e se arrasta pelo chão, presa à terra
    raiz_ini = (ox + 1, oy + 10)
    raiz_fim = (max(ox - 4, 0), 23)
    _linha(camada_tras, raiz_ini, ((raiz_ini[0] + raiz_fim[0]) // 2 - 1, (raiz_ini[1] + raiz_fim[1]) // 2), "h", "H")
    _linha(camada_tras, ((raiz_ini[0] + raiz_fim[0]) // 2 - 1, (raiz_ini[1] + raiz_fim[1]) // 2), raiz_fim, "h", "j")
    camada_tras.putpixel(((raiz_ini[0] + raiz_fim[0]) // 2 - 1, (raiz_ini[1] + raiz_fim[1]) // 2), rgba("q"))
    q.alpha_composite(camada_tras)
    q.alpha_composite(tronco, (ox, oy))
    # braço da frente
    mf = (ombro[0] + mao_frente[0], ombro[1] + mao_frente[1])
    _linha(camada_frente, ombro, mf, "d", "f")
    _garras(camada_frente, mf)
    q.alpha_composite(camada_frente)
    return contornar(q)


def gerar_ressequido():
    andar = [
        quadro_ressequido((0, 0), (2, 7), (0, 6), ((-3, 0), (2, 0))),
        quadro_ressequido((0, -1), (3, 6), (-1, 7), ((-1, 1), (0, 0))),
        quadro_ressequido((0, 0), (1, 7), (1, 6), ((2, 0), (-3, 0))),
        quadro_ressequido((0, -1), (0, 7), (2, 6), ((0, 0), (-1, 1))),
    ]
    preparar = [
        quadro_ressequido((-1, 0), (-3, 2), (-4, 1), ((-4, 0), (1, 0)), olho="W"),
        quadro_ressequido((-2, 0), (-4, 0), (-5, -1), ((-4, 0), (0, 0)), olho="W"),
    ]
    investir = [
        quadro_ressequido((2, 1), (7, 1), (6, 2), ((-5, 0), (3, 0)), olho="W"),
        quadro_ressequido((3, 1), (8, 2), (6, 3), ((-4, 0), (4, 0)), olho="Q"),
    ]
    recuperar = [
        quadro_ressequido((1, 2), (4, 9), (2, 8), ((-3, 0), (3, 0)), olho="q"),
        quadro_ressequido((0, 1), (3, 8), (1, 7), ((-3, 0), (2, 0)), olho="q"),
    ]
    dano = [quadro_ressequido((-2, 0), (0, 5), (-2, 4), ((-3, 0), (1, 0)), olho="W")]
    # Morte: desmorona em ossos e terra; a seiva se apaga.
    morte = []
    base = quadro_ressequido((0, 2), (3, 8), (1, 7), ((-3, 0), (3, 0)), olho="q")
    for i, (escala_y, apagar) in enumerate([(0.85, False), (0.65, True), (0.45, True), (0.3, True)]):
        h = max(int(24 * escala_y), 4)
        achatado = base.resize((24, h), Image.Resampling.NEAREST)
        quadro = Image.new("RGBA", (24, 24))
        quadro.alpha_composite(achatado, (0, 24 - h))
        if apagar:
            quadro = trocar_cores(quadro, {"q": "d", "Q": "D", "W": "8"})
        morte.append(quadro)
    monte = imagem("""
        ......8W..h.....
        ...8.dDf8W.hj...
        ..dDfW8DDf8dDh..
        .1dDDf88DDDfDd1.
        """)
    final = Image.new("RGBA", (24, 24))
    final.alpha_composite(contornar(monte), (4, 19))
    morte.append(final)
    anims = {"andar": andar, "preparar": preparar, "investir": investir, "recuperar": recuperar,
             "dano": dano, "morte": morte}
    fps = {"andar": 6, "preparar": 8, "investir": 12, "recuperar": 5, "dano": 10, "morte": 10}
    loops = {"andar": True, "preparar": True, "investir": False, "recuperar": True, "dano": False, "morte": False}
    # Pontos derivados das mesmas constantes do desenho (tronco em (4, 2), olho na coluna 10, linha 5).
    olho = [4 + 10, 2 + 5]
    garras_investida = [4 + 3 + OMBRO[0] + 8, 2 + 1 + OMBRO[1] + 2]
    return salvar_sprite("ressequido", "personagens", anims, (24, 24), (12, 23), fps, loops,
                         {"olho": olho, "garras_investida": garras_investida})


# --- Lamuriante ----------------------------------------------------------------

LAMURIANTE = """
...........Y............
..........YL.....Y......
.......Y..LY....YL......
......YL..XX....LY......
......LY..XW....XX......
......XX..Xc....XW......
......XW.XcX....Xc......
......XcXXccXXXXcX......
.......XcccccccccX......
......XccccccccccX......
......Xcc1111111cX......
.....Xcc111uuu111cX.....
.....Xcc11uIuIu11cX.....
.....Xcx11uuuuu11xX.....
.....Xcx111uuu111xX.....
....XccxX1111111XxcX....
....XcxccXX111XXcxcX....
...XcccxcccXXXcccxccX...
...Xcxcxcccc8ccccxcxX...
...XcxccxccXcXcccxcxX...
...XcxccxccXWXcccxccX...
..XccxccxcccXccccxcxcX..
..XcxccxcccccccccxcxcX..
..XcxcxccccxcccccxcxcX..
..XcxcxccccxcccccxcxcX..
..xcxcxccccxccccxxcxcx..
..xcxcxcxccxcxccxcxcxx..
..x.x.xcx.cx.xc.x.x.x...
..x...x..xx..x...x..x...
.........x.......x......
"""


def quadro_lamuriante(bob=0, boca=0, bracos=0, balanco=0, chama=0):
    q = Image.new("RGBA", (24, 32))
    corpo = imagem(LAMURIANTE)
    if chama == 1:
        corpo = trocar_cores(corpo, {"Y": "y", "L": "Y"})
    elif chama == 2:
        corpo = trocar_cores(corpo, {"L": "Y"})
    # barra esvoaçante: desloca as últimas linhas
    if balanco:
        barra = corpo.crop((0, 24, 24, corpo.height))
        limpa = Image.new("RGBA", (24, corpo.height - 24))
        corpo.paste(limpa, (0, 24))
        corpo.alpha_composite(barra, (balanco, 24))
    q.alpha_composite(corpo, (0, 1 + bob))
    d = ImageDraw.Draw(q)
    rosto_y = 1 + bob + 10
    if boca >= 1:
        # o vazio do rosto se alonga num lamento; o brilho roxo cresce no centro
        d.ellipse([10, rosto_y + 2, 13, rosto_y + 4 + boca * 2], fill=rgba("1"))
        d.ellipse([11, rosto_y + 3, 12, rosto_y + 3 + boca * 2], fill=rgba("U" if boca < 3 else "i"))
        if boca >= 3:
            q.putpixel((11, rosto_y + 4 + boca), rgba("I"))
            q.putpixel((12, rosto_y + 4 + boca), rgba("I"))
    if bracos:
        # braços finos de cera erguidos
        for lado in (-1, 1):
            base_x = 12 + lado * 7
            for k in range(bracos * 2):
                x = base_x + lado * (k // 2)
                y = rosto_y + 9 - k
                if 0 <= x < 24 and 0 <= y < 32:
                    q.putpixel((x, y), rgba("c" if k % 2 else "X"))
            topo_x, topo_y = base_x + lado * bracos, rosto_y + 9 - bracos * 2
            for (dx, dy) in [(0, -1), (lado, -1), (-lado, -1)]:
                if 0 <= topo_x + dx < 24 and 0 <= topo_y + dy < 32:
                    q.putpixel((topo_x + dx, topo_y + dy), rgba("W"))
    return contornar(q)


def gerar_lamuriante():
    flutuar = [quadro_lamuriante(0, 0, 0, 0, 0), quadro_lamuriante(-1, 0, 0, 1, 1),
               quadro_lamuriante(-1, 0, 0, 0, 2), quadro_lamuriante(0, 0, 0, -1, 1)]
    preparar = [quadro_lamuriante(0, 1, 1, 0, 2), quadro_lamuriante(-1, 2, 2, 1, 0), quadro_lamuriante(-1, 3, 3, -1, 2)]
    lancar = [quadro_lamuriante(-2, 4, 3, 1, 0), quadro_lamuriante(-1, 3, 2, 0, 1)]
    dano = [trocar_cores(quadro_lamuriante(0, 1, 0, 1, 1), {"X": "W"})]
    # Morte: derrete numa poça de cera com as velas tombadas, ainda acesas.
    morte = []
    base = quadro_lamuriante(0, 2, 0, 0, 0)
    for escala in (0.85, 0.65, 0.45, 0.28, 0.16):
        h = max(int(32 * escala), 3)
        w = int(24 * (1.0 + (1.0 - escala) * 0.35))
        derretido = base.resize((min(w, 24), h), Image.Resampling.NEAREST)
        quadro = Image.new("RGBA", (24, 32))
        quadro.alpha_composite(derretido, ((24 - derretido.width) // 2, 32 - h))
        morte.append(quadro)
    poca = imagem("""
        .....Y.......L......
        ....YLY..cXXYLY.....
        ..XXcxcXXcccxXcXX...
        .XcccxcccccxccccxcX.
        ..xxcxxccxcxxcxxx...
        """)
    final = Image.new("RGBA", (24, 32))
    final.alpha_composite(contornar(poca), (1, 26))
    morte.append(final)
    anims = {"flutuar": flutuar, "preparar": preparar, "lancar": lancar, "dano": dano, "morte": morte}
    fps = {"flutuar": 5, "preparar": 6, "lancar": 10, "dano": 10, "morte": 8}
    loops = {"flutuar": True, "preparar": False, "lancar": False, "dano": False, "morte": False}
    return salvar_sprite("lamuriante", "personagens", anims, (24, 32), (12, 31), fps, loops,
                         {"boca": [12, 14], "velas": [12, 2]})


# --- Projétil: Lamúria -------------------------------------------------------------

def gerar_lamuria():
    quadros = []
    for f in range(3):
        img = Image.new("RGBA", (16, 16))
        d = ImageDraw.Draw(img)
        raio = 5 + f % 2
        d.arc([8 - raio - 2, 8 - raio, 8 + raio - 2, 8 + raio], -70, 70, fill=rgba("i"), width=2)
        d.arc([8 - raio, 8 - raio + 1, 8 + raio - 4, 8 + raio - 1], -55, 55, fill=rgba("I"), width=1)
        d.arc([8 - raio - 5, 8 - raio + 2, 8 + raio - 7, 8 + raio - 2], -50, 50, fill=rgba("U"), width=1)
        quadros.append(img)
    return salvar_sprite("lamuria", "efeitos", {"voar": quadros}, (16, 16), (8, 8), {"voar": 12}, {"voar": True})


def gerar():
    return [gerar_ressequido(), gerar_lamuriante(), gerar_lamuria()]


if __name__ == "__main__":
    for c in gerar():
        print(c)
