#!/usr/bin/env python3
"""Gera a música provisória (OGG estéreo, loops sem emenda) em audio/musica/.

- catacumbas_exploracao / catacumbas_combate: mesma duração e andamento (tocam juntas;
  o jogo só muda o volume da camada de combate).
- titulo_exploracao: tema do menu (caixinha de sinos sobre um drone).
Todos os elementos com período (LFOs, notas) cabem um número inteiro de vezes no loop,
e o reverb é circular — o fim emenda no começo sem estalo.

Uso: python3 ferramentas/audio/gerar_musica.py
"""
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from sintetizador import (TAXA, colocar, distorcer, env_adsr, env_exp, filtro, normalizar, nota,  # noqa: E402
                          reverb, ruido, salvar_ogg, seno, serra, sino, tempo, varredura)

DESTINO = Path(__file__).resolve().parents[2] / "audio" / "musica"

ACORDES = {
    "Dm": ["D3", "F3", "A3", "D4"],
    "Bb": ["Bb2", "D3", "F3", "Bb3"],
    "F": ["F2", "A2", "C3", "F3"],
    "C": ["C3", "E3", "G3", "C4"],
    "Gm": ["G2", "Bb2", "D3", "G3"],
    "A": ["A2", "C#3", "E3", "A3"],
}
PROGRESSAO = ["Dm", "Bb", "F", "C", "Gm", "A"]  # um acorde a cada 4 compassos
PENTATONICA = ["D5", "F5", "G5", "A5", "C6", "D6", "A4", "C5"]


def ciclos_inteiros(freq, dur):
    """Ajusta a frequência para caber um número inteiro de ciclos no loop (sem estalo na emenda)."""
    return round(freq * dur) / dur


def pad(acorde, dur, ganho=1.0, semente=0):
    rng = np.random.default_rng(semente)
    s = np.zeros(int(dur * TAXA))
    for n in ACORDES[acorde]:
        f = nota(n)
        for desafino in (0.997, 1.003):
            s += serra(f * desafino, dur) * 0.15
        s += seno(f * 0.5, dur) * 0.05
    s = filtro(s, passa_baixa=850, passa_alta=60)
    return s * env_adsr(dur, a=1.6, d=0.5, s=0.85, r=2.2) * ganho * rng.uniform(0.9, 1.0)


def camadas_catacumbas():
    bpm = 84
    batida = 60 / bpm
    compassos = 24
    dur = compassos * 4 * batida
    n = int(dur * TAXA)
    t = np.arange(n) / TAXA
    rng = np.random.default_rng(2024)

    # --- Exploração ---
    exp_e = np.zeros(n)
    exp_d = np.zeros(n)
    # Drone: ré grave com respiração lenta (LFO com período que divide o loop)
    lfo = 0.6 + 0.4 * np.sin(2 * np.pi * (3 / dur) * t)
    ci = lambda f: ciclos_inteiros(f, dur)  # noqa: E731
    drone = (seno(ci(nota("D2")), dur) * 0.5 + seno(ci(nota("D1")), dur) * 0.25) * lfo
    quinta = seno(ci(nota("A2")), dur) * 0.18 * (0.5 + 0.5 * np.sin(2 * np.pi * (2 / dur) * t + 1.0))
    aspero = filtro(serra(ci(nota("D2")), dur) + serra(ci(nota("D2") * 1.004), dur), passa_baixa=240) * 0.12 * lfo
    exp_e += drone + quinta + aspero
    exp_d += drone + quinta * 0.8 + aspero
    # Pads: um acorde a cada 4 compassos, com sobreposição para não haver buraco
    for i, ac in enumerate(PROGRESSAO):
        inicio = i * 16 * batida
        p = pad(ac, 16 * batida + 2.0, 0.55, semente=i)
        colocar(exp_e, p, inicio)
        colocar(exp_d, p * 0.9, inicio + 0.013)
    # Sinos esparsos (melodia aleatória mas fixa pela semente)
    for b in range(compassos * 4):
        if rng.random() < 0.28:
            n_ = PENTATONICA[rng.integers(0, len(PENTATONICA))]
            s = sino(nota(n_), 3.0, brilho=0.5, semente=b) * 0.22
            pan = rng.uniform(0.25, 0.75)
            colocar(exp_e, s * (1 - pan) * 2, b * batida + (batida / 2 if rng.random() < 0.3 else 0))
            colocar(exp_d, s * pan * 2, b * batida + (batida / 2 if rng.random() < 0.3 else 0))
    # Gotas d'água
    momento = 1.0
    while momento < dur - 0.5:
        gota = seno(varredura(rng.uniform(1600, 2600), 700, 0.08)) * env_exp(0.08, 0.02) * 0.06
        alvo = exp_e if rng.random() < 0.5 else exp_d
        colocar(alvo, gota, momento)
        momento += rng.uniform(2.5, 6.0)
    exp_e = reverb(exp_e, 0.5, 4.0, 2500, circular=True)
    exp_d = reverb(exp_d, 0.5, 4.0, 2500, circular=True)

    # --- Combate ---
    com_e = np.zeros(n)
    com_d = np.zeros(n)

    def tambor(ganho=1.0, semente=0):
        d = 0.5
        corpo = seno(varredura(95, 42, d, 0.4)) * env_exp(d, 0.16)
        pele = filtro(ruido(d, semente), passa_baixa=700) * env_exp(d, 0.04) * 0.6
        return distorcer(corpo + pele, 1.4) * ganho

    def aro(semente=0):
        d = 0.12
        return filtro(ruido(d, semente), centro=2200, largura=900) * env_exp(d, 0.02) * 0.5

    def chocalho(semente=0):
        d = 0.06
        return filtro(ruido(d, semente), passa_alta=6000) * env_exp(d, 0.012) * 0.12

    for c in range(compassos):
        base = c * 4 * batida
        for b in (0, 2):
            k = tambor(1.0 if b == 0 else 0.8, c * 10 + b)
            colocar(com_e, k, base + b * batida)
            colocar(com_d, k, base + b * batida)
        if c % 2 == 1:
            k = tambor(0.6, c)
            colocar(com_e, k, base + 3.5 * batida)
            colocar(com_d, k, base + 3.5 * batida)
        for b in (1, 3):
            a = aro(c * 4 + b)
            colocar(com_e, a * 0.8, base + b * batida)
            colocar(com_d, a, base + b * batida + 0.004)
        for oitavo in range(8):
            ch = chocalho(c * 8 + oitavo) * (1.0 if oitavo % 2 else 0.6)
            colocar(com_e if oitavo % 2 else com_d, ch, base + oitavo * batida / 2)
    # Ostinato de baixo (colcheias) seguindo a fundamental do acorde
    padrao = [0, 0, 7, 0, 12, 0, 7, 10]
    for c in range(compassos):
        acorde = PROGRESSAO[(c // 4) % len(PROGRESSAO)]
        raiz = nota(ACORDES[acorde][0]) / 2 if nota(ACORDES[acorde][0]) > 90 else nota(ACORDES[acorde][0])
        for i, semitons in enumerate(padrao):
            f = raiz * 2 ** (semitons / 12)
            d = batida / 2
            s = filtro(serra(f, d * 1.2) + serra(f * 1.005, d * 1.2), passa_baixa=650) * env_exp(d * 1.2, 0.12) * 0.35
            colocar(com_e, s, c * 4 * batida + i * d)
            colocar(com_d, s, c * 4 * batida + i * d)
    # Cordas em trêmulo nas notas do acorde
    for i, ac in enumerate(PROGRESSAO):
        d = 16 * batida
        trem = 0.55 + 0.45 * np.sin(2 * np.pi * 11 * tempo(d))
        notas = ACORDES[ac][1:]
        cordas = sum(serra(nota(x) * 2, d) for x in notas) * 0.06
        cordas = filtro(cordas, passa_baixa=2200, passa_alta=200) * trem * env_adsr(d, 0.4, 0.2, 0.9, 0.6)
        colocar(com_e, cordas, i * d)
        colocar(com_d, cordas * 0.85, i * d + 0.01)
    com_e = reverb(com_e, 0.25, 2.0, 3500, circular=True)
    com_d = reverb(com_d, 0.25, 2.0, 3500, circular=True)

    pico_exp = max(np.abs(exp_e).max(), np.abs(exp_d).max())
    pico_com = max(np.abs(com_e).max(), np.abs(com_d).max())
    alvo = 10 ** (-3 / 20)
    return (exp_e / pico_exp * alvo, exp_d / pico_exp * alvo), (com_e / pico_com * alvo * 0.9, com_d / pico_com * alvo * 0.9)


def titulo():
    bpm = 66
    batida = 60 / bpm
    compassos = 16
    dur = compassos * 4 * batida
    n = int(dur * TAXA)
    t = np.arange(n) / TAXA
    e = np.zeros(n)
    d = np.zeros(n)
    lfo = 0.65 + 0.35 * np.sin(2 * np.pi * (2 / dur) * t)
    drone = (seno(ciclos_inteiros(nota("D2"), dur), dur) * 0.45 + seno(ciclos_inteiros(nota("A2"), dur), dur) * 0.15) * lfo
    e += drone
    d += drone
    for i, ac in enumerate(["Dm", "Bb", "Gm", "A"]):
        p = pad(ac, 16 * batida + 2.0, 0.45, semente=10 + i)
        colocar(e, p, i * 16 * batida)
        colocar(d, p, i * 16 * batida + 0.015)
    # Melodia em "caixinha de sinos" (duas frases de 8 compassos)
    frase = [("D5", 0), ("F5", 2), ("A5", 4), ("G5", 6), ("F5", 7), ("E5", 8), ("D5", 12), ("C5", 14),
             ("Bb4", 16), ("D5", 18), ("F5", 19), ("A5", 20), ("G5", 24), ("F5", 25), ("E5", 26), ("F5", 27),
             ("D5", 28)]
    variacao = [("A5", 0), ("C6", 2), ("D6", 4), ("C6", 6), ("A5", 7), ("G5", 8), ("F5", 12), ("E5", 14),
                ("D5", 16), ("F5", 18), ("E5", 19), ("C#5", 20), ("E5", 24), ("D5", 26), ("A4", 28), ("D5", 30)]
    for k, (n_, b) in enumerate(frase):
        s = sino(nota(n_), 3.5, brilho=0.7, semente=k) * 0.32
        colocar(e, s * 1.1, b * batida)
        colocar(d, s * 0.9, b * batida + 0.006)
    for k, (n_, b) in enumerate(variacao):
        s = sino(nota(n_), 3.5, brilho=0.7, semente=50 + k) * 0.3
        colocar(e, s * 0.9, (32 + b) * batida)
        colocar(d, s * 1.1, (32 + b) * batida + 0.006)
    e = reverb(e, 0.55, 4.5, 2400, circular=True)
    d = reverb(d, 0.55, 4.5, 2400, circular=True)
    pico = max(np.abs(e).max(), np.abs(d).max())
    alvo = 10 ** (-3 / 20)
    return e / pico * alvo, d / pico * alvo


def main():
    DESTINO.mkdir(parents=True, exist_ok=True)
    (ee, ed), (ce, cd) = camadas_catacumbas()
    salvar_ogg(DESTINO / "catacumbas_exploracao.ogg", ee, ed)
    salvar_ogg(DESTINO / "catacumbas_combate.ogg", ce, cd)
    te, td = titulo()
    salvar_ogg(DESTINO / "titulo_exploracao.ogg", te, td)
    for f in sorted(DESTINO.glob("*.ogg")):
        print(f.name, f"{f.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
