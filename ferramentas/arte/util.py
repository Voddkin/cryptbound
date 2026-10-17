"""Utilitários do gerador de arte: grades de texto → imagens, composição e folhas."""
import json
import random
from pathlib import Path

from PIL import Image

from paleta import PALETA, rgba

RAIZ = Path(__file__).resolve().parents[2]
ARTE = RAIZ / "arte"


def grade(texto: str) -> list[str]:
    """Converte um bloco de texto em linhas, removendo indentação e linhas vazias das pontas."""
    linhas = [l.rstrip() for l in texto.split("\n")]
    while linhas and not linhas[0].strip():
        linhas.pop(0)
    while linhas and not linhas[-1].strip():
        linhas.pop()
    recuo = min((len(l) - len(l.lstrip())) for l in linhas if l.strip())
    linhas = [l[recuo:] for l in linhas]
    largura = max(len(l) for l in linhas)
    return [l.ljust(largura, ".") for l in linhas]


def imagem(texto_ou_linhas, largura: int | None = None, altura: int | None = None) -> Image.Image:
    linhas = grade(texto_ou_linhas) if isinstance(texto_ou_linhas, str) else texto_ou_linhas
    w = largura or max(len(l) for l in linhas)
    h = altura or len(linhas)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    for y, linha in enumerate(linhas[:h]):
        for x, ch in enumerate(linha[:w]):
            if ch in (".", " "):
                continue
            if ch not in PALETA:
                raise ValueError(f"Caractere fora da paleta: {ch!r} na linha {y}: {linha}")
            px[x, y] = rgba(ch)
    return img


def colar(base: Image.Image, peca: Image.Image, x: int, y: int) -> Image.Image:
    base.alpha_composite(peca, (x, y)) if x >= 0 and y >= 0 else _colar_recortado(base, peca, x, y)
    return base


def _colar_recortado(base, peca, x, y):
    cx, cy = max(0, -x), max(0, -y)
    recorte = peca.crop((cx, cy, peca.width, peca.height))
    base.alpha_composite(recorte, (max(0, x), max(0, y)))


def espelhar(img: Image.Image) -> Image.Image:
    return img.transpose(Image.Transpose.FLIP_LEFT_RIGHT)


def deslocar(img: Image.Image, dx: int, dy: int) -> Image.Image:
    nova = Image.new("RGBA", img.size, (0, 0, 0, 0))
    colar(nova, img, dx, dy)
    return nova


def contornar(img: Image.Image, caractere: str = "0", diagonais: bool = False) -> Image.Image:
    """Adiciona contorno de 1 px ao redor dos pixels opacos (sem engordar o interior)."""
    w, h = img.size
    src = img.load()
    out = img.copy()
    dst = out.load()
    c = rgba(caractere)
    cor_contorno = c[:3]
    vizinhos = [(1, 0), (-1, 0), (0, 1), (0, -1)]
    if diagonais:
        vizinhos += [(1, 1), (1, -1), (-1, 1), (-1, -1)]
    for y in range(h):
        for x in range(w):
            if src[x, y][3] != 0:
                continue
            for dx, dy in vizinhos:
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] != 0 and src[nx, ny][:3] != cor_contorno:
                    dst[x, y] = c
                    break
    return out


def trocar_cores(img: Image.Image, mapa: dict[str, str]) -> Image.Image:
    """Substitui cores da paleta (por caractere) — útil para variantes e piscar de olhos."""
    trocas = {rgba(a)[:3]: rgba(b) for a, b in mapa.items()}
    out = img.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            p = px[x, y]
            if p[3] and p[:3] in trocas:
                px[x, y] = trocas[p[:3]]
    return out


def folha(quadros: list[Image.Image], colunas: int) -> Image.Image:
    w, h = quadros[0].size
    linhas = (len(quadros) + colunas - 1) // colunas
    sheet = Image.new("RGBA", (w * colunas, h * linhas), (0, 0, 0, 0))
    for i, q in enumerate(quadros):
        sheet.alpha_composite(q, ((i % colunas) * w, (i // colunas) * h))
    return sheet


def salvar_sprite(nome: str, pasta: str, quadros_por_anim: dict, tamanho: tuple, origem: tuple,
                  fps: dict | None = None, loops: dict | None = None, pontos: dict | None = None,
                  colunas: int = 8) -> Path:
    """Salva folha + JSON de metadados lidos pelo jogo (BibliotecaSprites)."""
    todos, anims = [], {}
    for anim, quadros in quadros_por_anim.items():
        indices = []
        for q in quadros:
            if q.size != tuple(tamanho):
                raise ValueError(f"{nome}/{anim}: quadro {q.size} difere de {tamanho}")
            indices.append(len(todos))
            todos.append(q)
        anims[anim] = {
            "quadros": indices,
            "fps": (fps or {}).get(anim, 8),
            "loop": (loops or {}).get(anim, True),
        }
    if origem[1] is None:
        base = max((q.getbbox() or (0, 0, 0, 1))[3] - 1 for q in todos)
        origem = (origem[0], base)
    destino = ARTE / pasta
    destino.mkdir(parents=True, exist_ok=True)
    colunas = min(colunas, len(todos))
    folha(todos, colunas).save(destino / f"{nome}.png")
    meta = {
        "imagem": f"{nome}.png",
        "quadro": list(tamanho),
        "colunas": colunas,
        "origem": list(origem),
        "animacoes": anims,
        "pontos": pontos or {},
    }
    (destino / f"{nome}.json").write_text(json.dumps(meta, indent=1, ensure_ascii=False), encoding="utf-8")
    return destino / f"{nome}.png"


def salvar(img: Image.Image, caminho_relativo: str) -> Path:
    destino = ARTE / caminho_relativo
    destino.parent.mkdir(parents=True, exist_ok=True)
    img.save(destino)
    return destino


def ampliar(img: Image.Image, fator: int) -> Image.Image:
    return img.resize((img.width * fator, img.height * fator), Image.Resampling.NEAREST)


def ruido(seed: int) -> random.Random:
    return random.Random(seed)
