"""Arma, objetos de cenário, itens, interface, luzes e ícone do jogo."""
import math
import random

from PIL import Image, ImageDraw

from paleta import rgba
from util import ARTE, RAIZ, ampliar, contornar, espelhar, imagem, salvar, salvar_sprite, trocar_cores

# Chamas em gota (nunca em cruz): três quadros de tremulação.
CHAMAS = [
    """
    .Y.
    YLY
    YLy
    .y.
    """,
    """
    ..Y
    .YL
    YLy
    .y.
    """,
    """
    Y..
    YL.
    yLY
    .y.
    """,
]


def chama(f):
    return imagem(CHAMAS[f % 3])


# --- Arma ------------------------------------------------------------------------------

def gerar_pa():
    pa = imagem("""
        ...............0000.
        ..............07W970
        00jjjjjjjjjjjj088W970
        0hHHHHHHHHHHHH0789870
        ...............07787.
        ................0660.
        """)
    # pegada da mão (pele) no cabo
    mao = imagem("""
        .kk.
        kSSk
        .ss.
        """)
    img = Image.new("RGBA", (22, 7))
    img.alpha_composite(pa, (0, 0))
    img.alpha_composite(mao, (2, 1))
    salvar(contornar(img), "armas/pa.png")


# --- Objetos de cenário -------------------------------------------------------------

def gerar_velas():
    # Vela solitária no chão, com poça de cera
    quadros = []
    for f in range(3):
        img = Image.new("RGBA", (8, 14))
        img.alpha_composite(chama(f), (2, 0))
        img.alpha_composite(imagem("""
            ..WX..
            ..Xc..
            ..Xc..
            ..cx..
            .XcxX.
            XcxxcX
            .xxxx.
            """), (1, 4))
        quadros.append(contornar(img))
    salvar_sprite("vela", "props", {"acesa": quadros}, (8, 14), (4, 13), {"acesa": 8}, {"acesa": True},
                  {"chama": [4, 2]})
    # Grupo de velas de alturas diferentes
    quadros = []
    for f in range(3):
        img = Image.new("RGBA", (16, 16))
        img.alpha_composite(chama(f), (2, 1))
        img.alpha_composite(chama(f + 1), (7, 4))
        img.alpha_composite(chama(f + 2), (11, 2))
        img.alpha_composite(imagem("""
            ...WX...........
            ...Xc......WX...
            ...Xc......Xc...
            ...Xc...WX.Xc...
            ...cx...Xc.cx...
            ...cx...cx.cx...
            ..XcxX.XcxXcxX..
            .XcxxcXcxxcxxcX.
            ..xxxxxxxxxxxx..
            """), (0, 5))
        quadros.append(contornar(img))
    salvar_sprite("velas", "props", {"acesas": quadros}, (16, 16), (8, 15), {"acesas": 7}, {"acesas": True},
                  {"chama": [8, 4]})
    # Candelabro de ferro (bloqueia)
    quadros = []
    for f in range(3):
        img = Image.new("RGBA", (14, 26))
        for i, x in enumerate((1, 5, 9)):
            img.alpha_composite(chama(f + i), (x, 0 + (2 if i != 1 else 0)))
        img.alpha_composite(imagem("""
            ..WX..WX..WX..
            ..Xc..Xc..Xc..
            .6666.66.6666.
            ..56..56..65..
            ...565665655..
            ......65......
            ......56......
            ......65......
            ......56......
            ......65......
            ......56......
            .....6556.....
            ......56......
            ......65......
            ......56......
            .....5665.....
            ....556655....
            ...45566554...
            ...33333333...
            """), (0, 5))
        quadros.append(contornar(img))
    salvar_sprite("candelabro", "props", {"aceso": quadros}, (14, 26), (7, 24), {"aceso": 7}, {"aceso": True},
                  {"chama": [7, 3]})


def gerar_estaticos():
    pecas = {
        "ossada_1": """
            .9W.....8...
            W998..W99W..
            .8...89..W8.
            ......8.....
            """,
        "ossada_2": """
            ..WW9.......
            .W9098..8W..
            .9W99W.W99W8
            ..899....8..
            """,
        "ossada_3": """
            ....8W......
            ..W9988.....
            ...8...9WW8.
            ........88..
            """,
        "cranios": """
            ....99W9........
            ...9WW9W9.99W9..
            ..9W1W1W99WW9W9.
            ..9WWWWW91W1W99.
            .99W8W8W9WWWWW8.
            9WW99898W8W8W99.
            W1W1W9W99898998.
            WWWWW99WW9W9W9W8
            9W8W89W1W1WW1W1W
            .989899WWWW9WWWW
            ..88889W8W8W8W89
            ...88889898989..
            """,
        "urna": """
            ..BBBB..
            .bzzzzb.
            ..bBBb..
            .bBzzBb.
            bBzWWzBb
            bBzzzzBb
            bBBzzBBb
            .bBBBBb.
            ..bbbb..
            .aaaaaa.
            """,
        "caixao": """
            ...HHHHHHHH...
            ..HjJJJJJJjH..
            .HjJjjjjjjJjH.
            .HjjjjjjjjjjH.
            HjjjjhhhhjjjjH
            HjjjjhYYhjjjjH
            HjjjjhYYhjjjjH
            HjjjjhhhhjjjjH
            HjjjjjjjjjjjjH
            HjjjjjjjjjjjjH
            .HjjjjjjjjjjH.
            .HjjjjjjjjjjH.
            .HjjjjjjjjjjH.
            .HjjjjjjjjjjH.
            ..HjjjjjjjjH..
            ..HjjjjjjjjH..
            ..HjjjjjjjjH..
            ...HjjjjjjH...
            ...HHHHHHHH...
            """,
        "raizes_chao": """
            hh..............
            .hjh............
            ...hjHh.........
            ......hjh.......
            .......hjHh.....
            ........hqjh....
            ..........hjHhh.
            .........hj...hj
            ........hj......
            .......hq.......
            """,
        "altar": """
            ..222222222222..
            .2344444444443W.
            .3555555555555W.
            .277777777777728
            .2wwwwwwwwwwww28
            .2wwwwwBBwwwww28
            .2wwwwBzzBwwww28
            .2wwwBzbbzBwww28
            .2wwBzbaabzBww28
            .2wwwBzbbzBwww28
            .2wwwwBzzBwwww28
            .2wwwwwBBwwwww28
            .2wwwwwwwwwwww28
            .233333333333328
            2455555555555542
            2333333333333332
            """,
        "escada": """
            000000000000000000000000000000
            055555555555555555555555555550
            054000000000000000000000000450
            054111111111111111111111111450
            054000000000000000000000000450
            054222222222222222222222222450
            054111111111111111111111111450
            054000000000000000000000000450
            054333333333333333333333333450
            054222222222222222222222222450
            054000000000000000000000000450
            054444444444444444444444444450
            054333333333333333333333333450
            054000000000000000000000000450
            054555555555555555555555555450
            054444444444444444444444444450
            054000000000000000000000000450
            054666666666666666666666666450
            054555555555555555555555555450
            055555555555555555555555555550
            000000000000000000000000000000
            """,
    }
    for nome, txt in pecas.items():
        img = imagem(txt)
        if nome not in ("escada",):
            img = contornar(img)
        salvar(img, f"props/{nome}.png")
    # Arco de porta (parede norte): moldura de cantaria em volta do vão de 32 px
    arco = Image.new("RGBA", (44, 36))
    d = ImageDraw.Draw(arco)
    d.rectangle([6, 4, 37, 35], fill=rgba("0"))
    for y in range(4, 36):
        for x in (2, 3, 4, 5, 38, 39, 40, 41):
            arco.putpixel((x, y), rgba("9" if x in (3, 39) else ("w" if x in (2, 38) else "7")))
    for x in range(2, 42):
        for y in (0, 1, 2, 3):
            arco.putpixel((x, y), rgba("w" if y == 0 else ("9" if y < 3 else "7")))
    for x in (11, 21, 31):
        for y in range(0, 4):
            arco.putpixel((x, y), rgba("6"))
    arco.putpixel((21, 1), rgba("q"))  # gema de seiva na pedra-chave
    for y in range(4, 36):
        frac = (y - 4) / 31
        for x in range(6, 38):
            if (x + y) % 2 == 0 and frac > 0.7:
                arco.putpixel((x, y), rgba("1"))
    salvar(contornar(arco), "props/arco_norte.png")


def gerar_porta_raizes():
    """Emaranhado de raízes que tranca uma passagem (horizontal, 32×20); 5 quadros de crescimento."""
    r = random.Random(42)
    galhos = []
    for i in range(9):
        x0 = r.randint(-2, 34)
        y0 = 20 if i % 2 == 0 else 0
        x1 = x0 + r.randint(-14, 14)
        y1 = r.randint(2, 18)
        galhos.append((x0, y0, x1, y1, r.randint(0, 3)))
    quadros = []
    for f in range(5):
        img = Image.new("RGBA", (32, 20))
        d = ImageDraw.Draw(img)
        prog = (f + 1) / 5
        for (x0, y0, x1, y1, atraso) in galhos:
            p = max(0.0, min(1.0, prog * 1.4 - atraso * 0.12))
            if p <= 0:
                continue
            xm = x0 + (x1 - x0) * p
            ym = y0 + (y1 - y0) * p
            d.line([(x0, y0), (xm, ym)], fill=rgba("h"), width=3)
            d.line([(x0, y0), (xm, ym - 1)], fill=rgba("j"), width=1)
            if p > 0.6:
                img.putpixel((int(xm) % 32, int(ym) % 20), rgba("q"))
        quadros.append(contornar(img))
    salvar_sprite("porta_raizes", "props", {"crescer": quadros, "fechada": [quadros[-1]]}, (32, 20), (16, 19),
                  {"crescer": 14, "fechada": 1}, {"crescer": False, "fechada": False})
    # versão vertical (passagens leste/oeste)
    verticais = [q.rotate(90, expand=True, resample=Image.Resampling.NEAREST) for q in quadros]
    salvar_sprite("porta_raizes_v", "props", {"crescer": verticais, "fechada": [verticais[-1]]}, (20, 32), (10, 31),
                  {"crescer": 14, "fechada": 1}, {"crescer": False, "fechada": False})


# --- Itens -------------------------------------------------------------------------------

def gerar_itens():
    icones = {
        "presa": """
            ..h.........h...
            ...h.......h....
            ...h.......h....
            ....h.....h.....
            .....hh.hh......
            .......Hj.......
            ......WWW8......
            ......WW98......
            ......W998......
            .......W98......
            .......W8.......
            .......98.......
            ........8.......
            ........e.......
            ........R.......
            """,
        "sino_rachado": """
            .......JJ.......
            ......J00J......
            ......jJJj......
            .....jJYYJj.....
            ....jJYYJJJj....
            ....jJY1JJJj....
            ....jJYJ1JJj....
            ...jJYJJ1JJJj...
            ...jJYJJJ1JJj...
            ..jJJYJJ1JJJJj..
            ..jjJJJJ1JJJjj..
            .HjjjjjjjjjjjjH.
            ..HHHHHHHHHHHH..
            .......jj.......
            .......JJ.......
            """,
        "vela_perene": """
            .......Q........
            ......QQ........
            ......Qq........
            ......qQq.......
            .......q........
            ......WWX.......
            ......XWc.......
            ......XWc.......
            ......XXc.......
            ......XXc.......
            .....XXXcX......
            .....XXXcx......
            ....XXXccxX.....
            ...BzzzzzzzB....
            ...bBBBBBBBb....
            """,
        "toco_vela": """
            ....Y...
            ...YLY..
            ...YLy..
            ....y...
            ..WWXc..
            .XXXcxX.
            XXcccxxX
            .xxxxxx.
            """,
        "osso": """
            W9.....9W
            9WWWWWWW9
            W9.....9W
            """,
    }
    for nome, txt in icones.items():
        salvar(contornar(imagem(txt)), f"itens/{nome}.png")


# --- Interface ------------------------------------------------------------------------

def gerar_interface():
    # Vela do HUD (cada vela = 1 ponto de vida): acesa (3 quadros), apagando, apagada.
    corpo = imagem("""
        .WX.
        .Xc.
        WXcx
        XXcx
        XXcx
        XXcx
        XXcx
        cccx
        """)
    acesas = []
    for f in range(3):
        img = Image.new("RGBA", (8, 14))
        img.alpha_composite(chama(f), (2, 0))
        img.alpha_composite(corpo, (2, 5))
        acesas.append(contornar(img))
    apagada = Image.new("RGBA", (8, 14))
    apagada.alpha_composite(trocar_cores(corpo, {"W": "7", "X": "6", "c": "5", "x": "4"}), (2, 5))
    apagada.putpixel((4, 4), rgba("2"))
    apagada = contornar(apagada)
    fumaca = []
    for f in range(3):
        img = apagada.copy()
        for k in range(3):
            y = 3 - k - f
            if y >= 0:
                img.putpixel((3 + (k + f) % 2, y), rgba("6" if k == 0 else "5"))
        fumaca.append(img)
    salvar_sprite("vela_hud", "interface", {"acesa": acesas, "apagando": fumaca, "apagada": [apagada]},
                  (8, 14), (0, 0), {"acesa": 6, "apagando": 8, "apagada": 1},
                  {"acesa": True, "apagando": False, "apagada": False})
    # Ícone de ossos (moeda)
    salvar(contornar(imagem("""
        W9.....9W
        9WWWWWWW9
        W9.....9W
        ..W9.9W..
        ..9WWW9..
        ..W9.9W..
        """)), "interface/ossos.png")
    # Painel 9-slice (18×18; margens de 6 px)
    painel = imagem("""
        ..2222222222222...
        .233333333333332..
        23W9333333333W932.
        239111111111119320
        231111111111111320
        231111111111111320
        231111111111111320
        231111111111111320
        231111111111111320
        231111111111111320
        231111111111111320
        231111111111111320
        231111111111111320
        239111111111119320
        23W9333333333W9320
        .233333333333332.0
        ..2222222222222.00
        ...0000000000000..
        """)
    salvar(painel, "interface/painel.png")
    # Marcador de foco do menu (chama ao lado da opção)
    salvar(contornar(chama(0)), "interface/marcador.png")
    # Cursor de mira
    salvar(imagem("""
        ....000....
        ....0W0....
        ....0W0....
        ....000....
        0000...0000
        0WW0.0.0WW0
        0000...0000
        ....000....
        ....0W0....
        ....0W0....
        ....000....
        """), "interface/cursor.png")
    # Barra de vida de inimigo (moldura 1 px)
    salvar(imagem("""
        0000000000000000
        0111111111111110
        0000000000000000
        """), "interface/barra_inimigo.png")


# --- Luzes ----------------------------------------------------------------------------

BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def luz(tamanho, faixas=5, nucleo=0.18):
    """Gradiente radial em faixas com pontilhado nas transições (luz de pixel art)."""
    img = Image.new("RGBA", (tamanho, tamanho))
    px = img.load()
    c = (tamanho - 1) / 2
    for y in range(tamanho):
        for x in range(tamanho):
            dist = math.hypot(x - c, y - c) / c
            if dist >= 1.0:
                continue
            v = 1.0 if dist < nucleo else max(0.0, 1.0 - (dist - nucleo) / (1.0 - nucleo))
            v = v ** 1.4
            nivel = v * faixas
            base = math.floor(nivel)
            frac = nivel - base
            limiar = (BAYER[y % 4][x % 4] + 0.5) / 16
            if frac > limiar:
                base += 1
            a = int(255 * min(base / faixas, 1.0))
            px[x, y] = (255, 255, 255, a)
    return img


def gerar_luzes():
    salvar(luz(128), "luzes/luz_suave.png")
    salvar(luz(64, faixas=4, nucleo=0.1), "luzes/luz_pequena.png")
    # Vinheta para a tela inteira (640×360): bordas escurecidas, pontilhadas
    w, h = 640, 360
    vin = Image.new("RGBA", (w, h))
    px = vin.load()
    for y in range(h):
        for x in range(w):
            dx = (x - w / 2) / (w / 2)
            dy = (y - h / 2) / (h / 2)
            d = math.sqrt(dx * dx * 0.8 + dy * dy)
            v = max(0.0, (d - 0.75) / 0.6)
            nivel = v * 4
            base = math.floor(nivel)
            if nivel - base > (BAYER[y % 4][x % 4] + 0.5) / 16:
                base += 1
            a = int(min(base, 4) / 4 * 170)
            if a:
                px[x, y] = (11, 9, 16, a)
    salvar(vin, "interface/vinheta.png")


# --- Ícone do jogo ---------------------------------------------------------------------

def gerar_icone():
    """Crânio com uma vela acesa e raízes, 32×32 ampliado ×8 (256×256)."""
    base = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(base)
    d.ellipse([1, 1, 30, 30], fill=rgba("1"))
    d.ellipse([3, 3, 28, 28], fill=rgba("2"))
    raizes = imagem("""
        h..............................h
        .h............................h.
        ..hj........................jh..
        ...hj......................jh...
        ....hq....................qh....
        """)
    base.alpha_composite(raizes, (0, 18))
    cranio = imagem("""
        ....999999....
        ..99WWWWWW99..
        .9WWWWWWWWWW9.
        9WWWWWWWWWWWW9
        9WW11WWWW11WW9
        9W1qq1WW1qq1W9
        9W1qq1WW1qq1W9
        9WW11WWWW11WW9
        .9WWWW11WWWW9.
        ..99WW11WW99..
        ...9W8W8W8W9..
        ...9W8W8W8W9..
        ....9999999...
        """)
    base.alpha_composite(cranio, (9, 14))
    vela = imagem("""
        ..Y...
        .YL...
        YLLY..
        YLy...
        .y....
        .WWX..
        .XWc..
        .XXc..
        XXXcx.
        """)
    base.alpha_composite(vela, (13, 4))
    icone = contornar(base)
    ampliar(icone, 8).save(RAIZ / "icon.png")
    salvar(icone, "interface/icone_32.png")


def gerar():
    gerar_pa()
    gerar_velas()
    gerar_estaticos()
    gerar_porta_raizes()
    gerar_itens()
    gerar_interface()
    gerar_luzes()
    gerar_icone()


if __name__ == "__main__":
    gerar()
    print("ok")
