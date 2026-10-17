"""A Coveira — protagonista. Quadros de 24×24, origem (pés) em (12, 23).

O tronco (cabeça, chapéu, cachecol, sobretudo) é desenhado à mão em grades; as pernas
e a barra do sobretudo são procedurais, para gerar o ciclo de corrida com consistência.
"""
from PIL import Image

from paleta import rgba
from util import contornar, espelhar, imagem, salvar_sprite, trocar_cores

Q = 24  # tamanho do quadro
OX = 4  # margem horizontal do corpo dentro do quadro

# Tronco: linhas 0–18 (o resto é perna/barra). Sem contorno nas pernas: o contorno é aplicado no fim.
FRENTE = """
................
......0000......
.....0HjjH0.....
.....0HHHh0.....
....0yOOOOo0....
..00hHHHHHHh00..
.0hjjjjjjjjjjh0.
..001sSSSSs100..
...01s0kk0s10...
...01kkkkkk10...
...00SkkkkS00...
..0oOOyyOOOo0...
.0MoOyOOOOoMM0..
.0MMoOOMggMMM0..
.0SMmMMggMMM0S0.
.0kMmmMggMMm0k0.
..0MhhYLhhhhM0..
..0MMm1YLmMMM0..
..0MMMMmMMMMM0..
"""

COSTAS = """
................
......0000......
.....0HjjH0.....
.....0HHHh0.....
....0oOOOOo0....
..00hHHHHHHh00..
.0hjjjjjjjjjjh0.
..00222222200...
...0223322220...
...0222232220...
...0022222200...
..0oOOOOOOOo0...
.0MoOOOyOOOom0..
.0gMMMMOMMMMm0..
.0SgMMMOMMMMm0S0
.0kgMMMOMMMMm0k0
..0ghhhhhhhhm0..
..0gMMMMMMMMm0..
..0gMMMMMMMMMm0.
"""

LADO = """
................
.....0000.......
....0HjjH0......
....0HHHh0......
...0yOOOo0......
.00hHHHHHhh000..
0hjjjjjjjjjjjh0.
.0011sSSSk00....
...02sSk0k0.....
...02kkkkk0.....
...00SkkS0......
...0oOOyOo0.....
..0oOyOgMMM0....
..0OMMggMM0.....
..0OMMggSM0.....
..00MMggk0......
...0MhhYL0......
...0MMMYL0......
...0MMMMgMM0....
"""

# Olhos fechados (dano/morte): troca pele clara por sombra nos olhos.
OLHOS_FECHADOS = {"0": "s"}


def _tronco(grade_txt):
    return imagem(grade_txt, 16, 19)


def _perna(img, x, topo, comprimento, cor_calca="2", cor_bota="1"):
    """Perna de 2 px de largura com bota de 2 px; `comprimento` inclui a bota."""
    if topo >= img.height:
        return
    comprimento = max(1, min(comprimento, img.height - topo))
    for y in range(topo, topo + comprimento):
        bota = y >= topo + comprimento - 2
        for dx in (0, 1):
            c = cor_bota if bota else cor_calca
            if bota and dx == 1 and y == topo + comprimento - 1:
                c = "0"
            img.putpixel((x + dx, y), rgba(c))
    if comprimento >= 2:
        img.putpixel((x, topo + comprimento - 2), rgba("h"))


def _barra(img, linha, x0, x1, abertura=None, cor="M"):
    """Barra do sobretudo (uma linha), com abertura opcional entre as pernas."""
    for x in range(x0, x1 + 1):
        if abertura and abertura[0] <= x <= abertura[1]:
            continue
        img.putpixel((x, linha), rgba("m" if x in (x0, x1) else cor))


def quadro_frente(costas=False, bob=0, pernas=(0, 0), balanco=0, olhos_fechados=False, agachar=0):
    """pernas = (elevação esquerda, elevação direita) em px; balanco desloca a barra do sobretudo."""
    q = Image.new("RGBA", (Q, Q))
    tronco = _tronco(COSTAS if costas else FRENTE)
    if olhos_fechados and not costas:
        tronco = trocar_cores(tronco.crop((0, 8, 16, 9)), OLHOS_FECHADOS)
        base = _tronco(FRENTE)
        base.paste(tronco, (0, 8))
        tronco = base
    y0 = 1 + bob + agachar
    q.alpha_composite(tronco, (OX, y0))
    corpo = Image.new("RGBA", (Q, Q))
    # Barra do sobretudo logo abaixo do tronco (comprimida quando agachada)
    linha = min(y0 + 19, Q - 2)
    _barra(corpo, linha, OX + 2 + balanco, OX + 13 + balanco, abertura=(OX + 7 + balanco, OX + 8 + balanco))
    # Pernas
    alt_total = Q - 1 - (linha + 1)
    for i, x in enumerate((OX + 5, OX + 9)):
        elev = pernas[i]
        comp = max(alt_total - elev, 1)
        _perna(corpo, x, linha + 1, comp)
    q.alpha_composite(corpo)
    return contornar(q)


def quadro_lado(bob=0, passo=0.0, elev=(0, 0), olhos_fechados=False, agachar=0, inclinar=0):
    """passo ∈ [-1, 1]: afastamento entre os pés; elev = elevação dos pés (trás, frente)."""
    q = Image.new("RGBA", (Q, Q))
    tronco = _tronco(LADO)
    if olhos_fechados:
        tronco = trocar_cores(tronco, {"0": "s"}) if False else tronco
    y0 = 1 + bob + agachar
    q.alpha_composite(tronco, (OX + inclinar, y0))
    corpo = Image.new("RGBA", (Q, Q))
    linha = min(y0 + 19, Q - 2)
    abre = int(round(abs(passo) * 2))
    _barra(corpo, linha, OX + 3 + inclinar - abre, OX + 10 + inclinar + abre)
    quadril = OX + 6 + inclinar
    alt_total = Q - 1 - (linha + 1)
    afast = int(round(passo * 3))
    # perna de trás (mais escura) e da frente
    _perna(corpo, quadril - afast, linha + 1, max(alt_total - elev[0], 1), cor_calca="1", cor_bota="0")
    _perna(corpo, quadril + afast, linha + 1, max(alt_total - elev[1], 1))
    q.alpha_composite(corpo)
    return contornar(q)


def gerar():
    anims = {}
    # Parado: respiração (tronco desce 1 px nos quadros 2–3)
    for direcao, costas in (("baixo", False), ("cima", True)):
        anims[f"parado_{direcao}"] = [quadro_frente(costas, b) for b in (0, 0, 1, 1)]
        corrida = []
        for (bob, pe, bal) in [(0, (0, 2), -1), (1, (0, 1), 0), (0, (1, 0), 0), (0, (2, 0), 1), (1, (1, 0), 0), (0, (0, 1), 0)]:
            corrida.append(quadro_frente(costas, -bob, pe, bal))
        anims[f"correr_{direcao}"] = corrida
        anims[f"esquiva_{direcao}"] = [quadro_frente(costas, 0, (0, 0), 0, agachar=2), quadro_frente(costas, 0, (1, 1), 0, agachar=1)]
        anims[f"dano_{direcao}"] = [quadro_frente(costas, 0, (0, 0), 0, olhos_fechados=True)]
    anims["parado_lado"] = [quadro_lado(b) for b in (0, 0, 1, 1)]
    ciclo = [(0, 1.0, (0, 0)), (1, 0.4, (0, 2)), (0, -0.3, (1, 1)), (0, -1.0, (0, 0)), (1, -0.4, (2, 0)), (0, 0.3, (1, 1))]
    anims["correr_lado"] = [quadro_lado(-b, p, e) for (b, p, e) in ciclo]
    anims["esquiva_lado"] = [quadro_lado(0, 0.6, (0, 1), agachar=2, inclinar=1), quadro_lado(0, 1.0, (0, 2), agachar=1, inclinar=2)]
    anims["dano_lado"] = [quadro_lado(0, 0.2, (0, 0), inclinar=-1)]

    # Morte: de joelhos, tomba para a frente, fica no chão; o chapéu rola.
    ajoelhada = quadro_frente(False, 0, (3, 3), 0, olhos_fechados=True, agachar=3)
    curvada = quadro_frente(False, 0, (3, 3), 0, olhos_fechados=True, agachar=4)
    tombando = curvada.rotate(-35, resample=Image.Resampling.NEAREST, center=(12, 22))
    caida = curvada.rotate(-90, resample=Image.Resampling.NEAREST, center=(12, 20))
    caida = caida.transform(caida.size, Image.Transform.AFFINE, (1, 0, 0, 0, 1, -3), resample=Image.Resampling.NEAREST)
    chapeu = imagem("""
        ..0000..
        .0HjjH0.
        .0HHHh0.
        0yOOOOo0
        0hjjjjh0
        .000000.
        """)
    final = caida.copy()
    final.alpha_composite(chapeu, (15, 15))
    anims["morte"] = [anims["dano_baixo"][0], ajoelhada, curvada, tombando, caida, final]

    fps = {k: 6 for k in anims if k.startswith("parado")}
    fps.update({k: 12 for k in anims if k.startswith("correr")})
    fps.update({k: 14 for k in anims if k.startswith("esquiva")})
    fps["morte"] = 7
    loops = {k: not (k.startswith("esquiva") or k.startswith("dano") or k == "morte") for k in anims}
    pontos = {
        # Pivô de onde a arma gira (altura do quadril/mãos) e ponto da lanterna (luz).
        "pivo_arma": [12, 15],
        "lanterna": [11, 17],
    }
    return salvar_sprite("coveira", "personagens", anims, (Q, Q), (12, 23), fps, loops, pontos, colunas=8)


if __name__ == "__main__":
    print(gerar())
