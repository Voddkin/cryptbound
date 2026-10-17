#!/usr/bin/env python3
"""Gera os efeitos sonoros (WAV mono 44,1 kHz) em audio/sfx/.

Convenção: <id>.wav ou <id>_<n>.wav para variações (o jogo sorteia entre elas).
Uso: python3 ferramentas/audio/gerar_sfx.py
"""
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from sintetizador import (TAXA, distorcer, env_exp, esmagar_bits, filtro, filtro_variavel, misturar,  # noqa: E402
                          normalizar, nota, quadrada, reverb, ruido, salvar_wav, seno, serra, sino,
                          suavizar_bordas, tempo, triangulo, varredura)

DESTINO = Path(__file__).resolve().parents[2] / "audio" / "sfx"


def varrida(semente, dur=0.16, f0=2600, f1=500, peso=1.0):
    """Golpe cortando o ar: ruído filtrado com corte descendo."""
    r = ruido(dur, semente)
    cortes = varredura(f0, f1, dur, 0.7)
    s = filtro_variavel(r, cortes) * 3.0
    env = np.sin(np.linspace(0, np.pi, len(s))) ** 1.5
    corpo = seno(varredura(180 * peso, 90 * peso, dur), None) * env_exp(dur, dur / 3) * 0.25
    return suavizar_bordas(s * env + corpo)


def acerto_osso(semente):
    dur = 0.22
    t = tempo(dur)
    estalo = filtro(ruido(dur, semente), passa_alta=1200, passa_baixa=5000) * env_exp(dur, 0.012)
    baque = seno(varredura(170, 55, dur, 0.5)) * env_exp(dur, 0.07) * 1.4
    cliques = np.zeros_like(t)
    rng = np.random.default_rng(semente)
    for k in range(3):
        i = int(rng.uniform(0.005, 0.05) * TAXA)
        n = int(0.006 * TAXA)
        cliques[i:i + n] += filtro(ruido(0.006, semente + k), passa_alta=2000, passa_baixa=6500)[:n] * 0.5
    return suavizar_bordas(distorcer(estalo * 0.9 + baque * 0.8 + cliques, 1.5))


def acerto_cera(semente):
    dur = 0.25
    massa = filtro(ruido(dur, semente), passa_baixa=900) * env_exp(dur, 0.05) * 2.5
    baque = seno(varredura(120, 60, dur)) * env_exp(dur, 0.08)
    chiado = filtro(ruido(dur, semente + 9), passa_alta=4000) * env_exp(dur, 0.03) * 0.3
    return suavizar_bordas(massa + baque + chiado)


def jogador_dano():
    dur = 0.45
    baque = seno(varredura(110, 45, dur, 0.4)) * env_exp(dur, 0.12)
    pano = filtro(ruido(dur, 31), passa_baixa=1400) * env_exp(dur, 0.06) * 1.5
    dissonante = (seno(311, dur) + seno(329.6, dur)) * env_exp(dur, 0.2) * 0.15
    return suavizar_bordas(distorcer(baque + pano + dissonante, 1.8))


def esquiva():
    dur = 0.2
    r = ruido(dur, 5)
    cortes = varredura(400, 3500, dur, 1.4)
    s = filtro_variavel(r, cortes) * 2.5
    env = np.sin(np.linspace(0, np.pi, len(s))) ** 2
    return suavizar_bordas(s * env)


def passo(semente):
    dur = 0.09
    s = filtro(ruido(dur, semente), passa_baixa=1600, passa_alta=150) * env_exp(dur, 0.018) * 2
    s += seno(varredura(90, 60, dur)) * env_exp(dur, 0.02) * 0.4
    return suavizar_bordas(s)


def ressequido_preparar(semente):
    dur = 0.55
    t = tempo(dur)
    trem = 0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 28 * t))
    rangido = filtro(ruido(dur, semente), centro=700, largura=500) * trem * 3
    grunhido = serra(varredura(70, 120, dur, 1.2)) * 0.25
    grunhido = filtro(grunhido, passa_baixa=600)
    env = np.clip(t / 0.4, 0, 1) * np.exp(-np.maximum(t - 0.45, 0) / 0.05)
    return suavizar_bordas(distorcer((rangido + grunhido) * env, 2.0))


def ressequido_investida(semente):
    dur = 0.3
    rasp = filtro(ruido(dur, semente), passa_baixa=2500, passa_alta=300) * env_exp(dur, 0.1) * 2.0
    voz = filtro(serra(varredura(150, 80, dur)), passa_baixa=900) * env_exp(dur, 0.12) * 0.5
    return suavizar_bordas(distorcer(rasp + voz, 2.5))


def ressequido_morte():
    dur = 0.9
    s = np.zeros(int(dur * TAXA))
    rng = np.random.default_rng(77)
    for k in range(14):
        inicio = rng.uniform(0, 0.55) ** 1.5
        clique = filtro(ruido(0.03, 100 + k), passa_alta=900 + rng.uniform(0, 1500), passa_baixa=5500) * env_exp(0.03, 0.006)
        i = int(inicio * TAXA)
        s[i:i + len(clique)] += clique * rng.uniform(0.3, 0.9)
    terra = filtro(ruido(dur, 78), passa_baixa=500) * env_exp(dur, 0.25) * 1.2
    return suavizar_bordas(s + terra)


def lamuriante_lamento():
    """Lamento: vogal 'ó' cantada, com vibrato largo e glissando descendente."""
    dur = 1.0
    t = tempo(dur)
    f = varredura(520, 330, dur, 0.8) * (1 + 0.025 * np.sin(2 * np.pi * 5.5 * t))
    voz = np.zeros_like(t)
    for h, a in [(1, 1.0), (2, 0.5), (3, 0.35), (4, 0.2), (5, 0.12)]:
        voz += a * np.sin(np.cumsum(2 * np.pi * f * h / TAXA))
    voz = filtro(voz, centro=550, largura=400) * 2 + filtro(voz, centro=900, largura=300) * 0.8
    ar = filtro(ruido(dur, 12), centro=1200, largura=900) * 0.15
    env = np.clip(t / 0.25, 0, 1) * np.clip((dur - t) / 0.3, 0, 1)
    return suavizar_bordas(reverb((voz + ar) * env, 0.35, 1.2)[: int(dur * 1.3 * TAXA)])


def lamuria_disparo():
    dur = 0.4
    t = tempo(dur)
    sopro = filtro_variavel(ruido(dur, 21), varredura(3000, 600, dur)) * 2
    tom = seno(varredura(700, 300, dur)) * 0.3 * (1 + 0.5 * np.sin(2 * np.pi * 30 * t))
    return suavizar_bordas((sopro + tom) * env_exp(dur, 0.15, 0.02))


def lamuriante_morte():
    dur = 1.2
    t = tempo(dur)
    chiado = filtro(ruido(dur, 44), passa_alta=2000, passa_baixa=7000) * env_exp(dur, 0.5) * 0.25
    f = varredura(480, 120, dur, 0.6)
    voz = sum(a * np.sin(np.cumsum(2 * np.pi * f * h / TAXA)) for h, a in [(1, 1), (2, 0.4), (3, 0.2)])
    voz = filtro(voz, centro=500, largura=400) * np.exp(-t / 0.5)
    return suavizar_bordas(reverb(chiado + voz * 1.5, 0.3, 1.0)[: int(dur * 1.2 * TAXA)])


def sino_badalo():
    s = sino(nota("D5"), 1.4, brilho=0.8, rachado=0.6, semente=3)
    return suavizar_bordas(s)


def vela_apagar():
    dur = 0.5
    t = tempo(dur)
    sopro = filtro(ruido(dur, 61), passa_alta=1800, passa_baixa=7000) * np.exp(-t / 0.18) * np.clip(t / 0.03, 0, 1)
    baque = seno(varredura(90, 50, dur)) * env_exp(dur, 0.1) * 0.7
    return suavizar_bordas(sopro * 1.3 + baque)


def vela_acender():
    dur = 0.9
    fogo = filtro(ruido(dur, 62), passa_baixa=1200) * env_exp(dur, 0.12, 0.03) * 1.2
    brilho = sino(nota("A5"), dur, brilho=0.5) * 0.35 + sino(nota("D6"), dur, brilho=0.4) * 0.25
    return suavizar_bordas(fogo + brilho)


def coletar_osso(k):
    dur = 0.18
    f = nota(["E6", "G6", "A6"][k])
    s = (triangulo(f, dur) * 0.6 + seno(f * 2, dur) * 0.3) * env_exp(dur, 0.05)
    s += filtro(ruido(dur, 90 + k), passa_alta=3000) * env_exp(dur, 0.006) * 0.4
    return suavizar_bordas(s)


def coletar_item():
    dur = 2.0
    s = np.zeros(int(dur * TAXA))
    for i, n in enumerate(["D5", "F5", "A5", "D6"]):
        b = sino(nota(n), 1.6, brilho=0.6, semente=i) * (0.5 if i < 3 else 0.7)
        inicio = int(i * 0.09 * TAXA)
        s[inicio:inicio + len(b)] += b[: len(s) - inicio]
    s += filtro(ruido(dur, 5), passa_alta=5000) * env_exp(dur, 0.4, 0.2) * 0.08
    return suavizar_bordas(reverb(s, 0.35, 2.0)[: int(2.4 * TAXA)])


def porta_fechar():
    dur = 0.8
    t = tempo(dur)
    rangido = filtro(ruido(dur, 71), centro=400, largura=300) * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 35 * t))) * 2
    estalos = np.zeros_like(t)
    rng = np.random.default_rng(72)
    for k in range(8):
        i = int(rng.uniform(0.0, 0.6) * TAXA)
        c = filtro(ruido(0.02, 200 + k), passa_alta=800, passa_baixa=4500) * env_exp(0.02, 0.004)
        estalos[i:i + len(c)] += c * 0.8
    ronco = filtro(ruido(dur, 73), passa_baixa=180) * 3
    env = np.clip(t / 0.05, 0, 1) * np.exp(-t / 0.4)
    return suavizar_bordas(distorcer((rangido + ronco) * env + estalos, 1.5))


def porta_abrir():
    dur = 0.7
    t = tempo(dur)
    farfalhar = filtro_variavel(ruido(dur, 81), varredura(3000, 500, dur)) * 2
    env = np.clip(t / 0.1, 0, 1) * np.exp(-t / 0.3)
    return suavizar_bordas(farfalhar * env)


def sala_limpa():
    dur = 3.0
    b = sino(nota("D4"), dur, brilho=0.5, semente=9) * 0.8 + sino(nota("A4"), dur, brilho=0.4, semente=10) * 0.4
    return suavizar_bordas(reverb(b, 0.4, 2.5)[: int(3.5 * TAXA)])


def ui_mover():
    dur = 0.05
    return suavizar_bordas(triangulo(nota("A5"), dur) * env_exp(dur, 0.015) * 0.5)


def ui_confirmar():
    dur = 0.5
    return suavizar_bordas(sino(nota("D6"), dur, brilho=0.4) * 0.5 + sino(nota("A6"), dur, brilho=0.3) * 0.3)


def ui_voltar():
    dur = 0.08
    return suavizar_bordas(triangulo(nota("D5"), dur) * env_exp(dur, 0.02) * 0.5)


def morte_jogador():
    dur = 4.0
    t = tempo(dur)
    sino_grave = sino(nota("D3"), dur, brilho=0.4, rachado=0.3, semente=4)
    drone = filtro(serra(nota("D2"), dur) + serra(nota("D2") * 1.005, dur), passa_baixa=300) * np.exp(-t / 1.5) * 0.3
    return suavizar_bordas(reverb(sino_grave + drone, 0.4, 3.0)[: int(4.5 * TAXA)])


def descer():
    dur = 1.6
    s = np.zeros(int(dur * TAXA))
    for k in range(4):
        p = passo(300 + k) * (1.0 - k * 0.18)
        i = int((0.1 + k * 0.28) * TAXA)
        s[i:i + len(p)] += p
    vento = filtro(ruido(dur, 99), centro=300, largura=200) * np.clip(tempo(dur) / 1.2, 0, 1) * 1.5
    return suavizar_bordas(s + vento)


def carga_pronta():
    dur = 0.25
    return suavizar_bordas((seno(varredura(600, 1200, dur, 0.5)) * 0.4 + sino(nota("E6"), dur) * 0.3) * env_exp(dur, 0.1))


def impacto_pesado():
    dur = 0.6
    boom = seno(varredura(90, 35, dur, 0.4)) * env_exp(dur, 0.18) * 1.2
    terra = filtro(ruido(dur, 111), passa_baixa=1200) * env_exp(dur, 0.12) * 1.3
    estalo = filtro(ruido(dur, 112), passa_alta=2000) * env_exp(dur, 0.01) * 0.7
    return suavizar_bordas(distorcer(boom + terra + estalo, 1.8))


def sangria():
    dur = 0.12
    gota = seno(varredura(900, 300, dur, 0.5)) * env_exp(dur, 0.03) * 0.5
    return suavizar_bordas(gota + filtro(ruido(dur, 120), passa_baixa=2000) * env_exp(dur, 0.01) * 0.3)


def pa_pancada(semente):
    return varrida(semente, 0.26, 1800, 260, 0.7)


def main():
    DESTINO.mkdir(parents=True, exist_ok=True)
    for antigo in DESTINO.glob("*.wav"):
        antigo.unlink()
    sons = {
        "pa_varrida_1": varrida(1), "pa_varrida_2": varrida(2, f0=2900), "pa_varrida_3": varrida(3, f1=420),
        "pa_pancada_1": pa_pancada(4), "pa_pancada_2": pa_pancada(5),
        "acerto_osso_1": acerto_osso(10), "acerto_osso_2": acerto_osso(11), "acerto_osso_3": acerto_osso(12),
        "acerto_cera_1": acerto_cera(20), "acerto_cera_2": acerto_cera(21),
        "jogador_dano": jogador_dano(), "esquiva": esquiva(),
        "passo_1": passo(40), "passo_2": passo(41), "passo_3": passo(42), "passo_4": passo(43),
        "ressequido_preparar_1": ressequido_preparar(50), "ressequido_preparar_2": ressequido_preparar(51),
        "ressequido_investida_1": ressequido_investida(52), "ressequido_investida_2": ressequido_investida(53),
        "ressequido_morte": ressequido_morte(),
        "lamuriante_lamento": lamuriante_lamento(), "lamuria_disparo": lamuria_disparo(),
        "lamuriante_morte": lamuriante_morte(), "sino_badalo": sino_badalo(),
        "vela_apagar": vela_apagar(), "vela_acender": vela_acender(),
        "coletar_osso_1": coletar_osso(0), "coletar_osso_2": coletar_osso(1), "coletar_osso_3": coletar_osso(2),
        "coletar_item": coletar_item(), "porta_fechar": porta_fechar(), "porta_abrir": porta_abrir(),
        "sala_limpa": sala_limpa(), "ui_mover": ui_mover(), "ui_confirmar": ui_confirmar(), "ui_voltar": ui_voltar(),
        "morte_jogador": morte_jogador(), "descer": descer(), "carga_pronta": carga_pronta(),
        "impacto_pesado": impacto_pesado(), "sangria_1": sangria(),
    }
    volumes = {"ui_mover": -14, "ui_voltar": -12, "ui_confirmar": -8, "passo": -16, "sangria": -10,
               "pa_varrida": -5, "esquiva": -7, "coletar_osso": -9}
    for nome, sinal in sons.items():
        base = nome.rsplit("_", 1)[0] if nome[-1].isdigit() else nome
        pico = volumes.get(base, -2.0)
        salvar_wav(DESTINO / f"{nome}.wav", normalizar(sinal, pico))
    print(f"{len(sons)} efeitos gerados em {DESTINO}")


if __name__ == "__main__":
    main()
