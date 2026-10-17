"""Sintetizador mínimo em numpy para efeitos e música provisórios do CRYPTBOUND.

Blocos: osciladores com frequência variável, ruídos, envelopes, filtros (por FFT, sem
fase), distorção, sinos inarmônicos e reverb por convolução (circular para loops).
"""
import subprocess
import wave
from pathlib import Path

import numpy as np

TAXA = 44100


def tempo(duracao: float) -> np.ndarray:
    return np.arange(int(duracao * TAXA)) / TAXA


def _fase(freq) -> np.ndarray:
    return 2 * np.pi * np.cumsum(np.asarray(freq, dtype=np.float64)) / TAXA


def seno(freq, duracao=None):
    if np.isscalar(freq):
        return np.sin(2 * np.pi * freq * tempo(duracao))
    return np.sin(_fase(freq))


def serra(freq, duracao=None):
    f = np.full(int(duracao * TAXA), freq) if np.isscalar(freq) else freq
    fase = _fase(f) / (2 * np.pi)
    return 2.0 * (fase - np.floor(fase + 0.5))


def quadrada(freq, duracao=None, ciclo=0.5):
    f = np.full(int(duracao * TAXA), freq) if np.isscalar(freq) else freq
    fase = (_fase(f) / (2 * np.pi)) % 1.0
    return np.where(fase < ciclo, 1.0, -1.0)


def triangulo(freq, duracao=None):
    return 2.0 * np.abs(serra(freq, duracao)) - 1.0


def ruido(duracao, semente=0):
    return np.random.default_rng(semente).uniform(-1, 1, int(duracao * TAXA))


def varredura(f0, f1, duracao, curva=1.0):
    """Frequência que vai de f0 a f1 (curva > 1 cai rápido no início)."""
    x = np.linspace(0, 1, int(duracao * TAXA)) ** curva
    return f0 * (f1 / f0) ** x if f0 > 0 and f1 > 0 else f0 + (f1 - f0) * x


def env_exp(duracao, decaimento, ataque=0.002):
    t = tempo(duracao)
    e = np.exp(-t / max(decaimento, 1e-4))
    if ataque > 0:
        e *= np.clip(t / ataque, 0, 1)
    return e


def env_adsr(duracao, a=0.01, d=0.1, s=0.6, r=0.2):
    n = int(duracao * TAXA)
    t = np.arange(n) / TAXA
    e = np.empty(n)
    fim_s = max(duracao - r, a + d)
    e = np.where(t < a, t / max(a, 1e-6),
                 np.where(t < a + d, 1 - (1 - s) * (t - a) / max(d, 1e-6),
                          np.where(t < fim_s, s, s * np.clip(1 - (t - fim_s) / max(r, 1e-6), 0, 1))))
    return e


def filtro(sinal, passa_baixa=None, passa_alta=None, ressonancia=0.0, centro=None, largura=None):
    """Filtro estático no domínio da frequência (sem fase). Para passa-faixa use centro/largura."""
    n = len(sinal)
    espectro = np.fft.rfft(sinal)
    f = np.fft.rfftfreq(n, 1 / TAXA)
    ganho = np.ones_like(f)
    if passa_baixa:
        ganho *= 1.0 / np.sqrt(1.0 + (f / passa_baixa) ** 4)
        if ressonancia > 0:
            ganho *= 1.0 + ressonancia * np.exp(-((f - passa_baixa) / (passa_baixa * 0.15)) ** 2)
    if passa_alta:
        ganho *= 1.0 / np.sqrt(1.0 + (passa_alta / np.maximum(f, 1e-3)) ** 4)
    if centro:
        ganho *= np.exp(-((f - centro) / (largura or centro * 0.3)) ** 2)
    return np.fft.irfft(espectro * ganho, n)


def filtro_variavel(sinal, cortes):
    """Passa-baixa de um polo com corte variando no tempo (laço em Python: só para sons curtos)."""
    saida = np.empty_like(sinal)
    y = 0.0
    cortes = np.broadcast_to(cortes, sinal.shape)
    for i in range(len(sinal)):
        a = 1.0 - np.exp(-2 * np.pi * cortes[i] / TAXA)
        y += a * (sinal[i] - y)
        saida[i] = y
    return saida


def distorcer(sinal, quantidade=2.0):
    return np.tanh(sinal * quantidade) / np.tanh(quantidade)


def esmagar_bits(sinal, bits=6, reducao=2):
    s = np.repeat(sinal[::reducao], reducao)[: len(sinal)]
    niveis = 2 ** bits
    return np.round(s * niveis) / niveis


PARCIAIS_SINO = [(0.5, 0.7, 2.2), (1.0, 1.0, 1.6), (1.19, 0.55, 1.2), (1.56, 0.4, 0.9), (2.0, 0.5, 0.8),
                 (2.74, 0.35, 0.55), (3.76, 0.22, 0.35), (5.4, 0.12, 0.2)]


def sino(freq, duracao, brilho=1.0, rachado=0.0, semente=0):
    """Sino com parciais inarmônicos; `rachado` adiciona batimento e zumbido."""
    t = tempo(duracao)
    rng = np.random.default_rng(semente)
    s = np.zeros_like(t)
    for (razao, amp, dec) in PARCIAIS_SINO:
        desafino = 1.0 + rachado * rng.uniform(-0.012, 0.012)
        f = freq * razao * desafino
        if f > TAXA / 2.2:
            continue
        a = amp * (brilho if razao > 2 else 1.0)
        s += a * np.sin(2 * np.pi * f * t + rng.uniform(0, 6.28)) * np.exp(-t / (dec * duracao / 2.5))
        if rachado:
            s += a * rachado * 0.6 * np.sin(2 * np.pi * (f * 1.006) * t) * np.exp(-t / (dec * duracao / 4))
    if rachado:
        zumbido = ruido(duracao, semente + 1) * np.exp(-t / 0.06) * rachado
        s += filtro(zumbido, passa_baixa=4000, passa_alta=800) * 0.8
    ataque = np.clip(t / 0.002, 0, 1)
    soltura = np.clip((duracao - t) / 0.04, 0, 1)  # termina em zero: sem estalo no corte
    return s * ataque * soltura


def resposta_reverb(duracao=2.5, brilho=3000, semente=7):
    r = ruido(duracao, semente) * np.exp(-tempo(duracao) / (duracao / 6))
    r = filtro(r, passa_baixa=brilho, passa_alta=120)
    r[: int(0.012 * TAXA)] *= np.linspace(0, 1, int(0.012 * TAXA))
    return r / np.sqrt(np.sum(r ** 2))


def reverb(sinal, molhado=0.3, duracao=2.5, brilho=3000, circular=False):
    """Reverb por convolução. `circular=True` faz a cauda dar a volta (loop sem emenda)."""
    ir = resposta_reverb(duracao, brilho)
    if circular:
        n = len(sinal)
        ir_n = np.zeros(n)
        ir_n[: min(len(ir), n)] = ir[: n]
        molhado_sinal = np.fft.irfft(np.fft.rfft(sinal) * np.fft.rfft(ir_n), n)
        return sinal * (1 - molhado * 0.5) + molhado_sinal * molhado
    sinal = suavizar_bordas(sinal, 0.0, 0.02)  # o seco precisa terminar em zero antes da cauda
    n = len(sinal) + len(ir) - 1
    tamanho = 1 << (n - 1).bit_length()
    molhado_sinal = np.fft.irfft(np.fft.rfft(sinal, tamanho) * np.fft.rfft(ir, tamanho), tamanho)[:n]
    seco = np.concatenate([sinal, np.zeros(n - len(sinal))])
    return seco * (1 - molhado * 0.5) + molhado_sinal * molhado


def misturar(*faixas):
    n = max(len(f) for f in faixas)
    saida = np.zeros(n)
    for f in faixas:
        saida[: len(f)] += f
    return saida


def colocar(destino, sinal, inicio_s, ganho=1.0, circular=True):
    """Soma `sinal` em `destino` a partir de `inicio_s` segundos (dando a volta se circular)."""
    i = int(inicio_s * TAXA)
    n = len(destino)
    for k in range(0, len(sinal), n):
        trecho = sinal[k: k + n]
        pos = (i + k) % n if circular else i + k
        fim = pos + len(trecho)
        if fim <= n:
            destino[pos:fim] += trecho * ganho
        elif circular:
            corte = n - pos
            destino[pos:] += trecho[:corte] * ganho
            destino[: len(trecho) - corte] += trecho[corte:] * ganho
        else:
            destino[pos:n] += trecho[: n - pos] * ganho


def normalizar(sinal, pico_db=-1.0):
    pico = np.max(np.abs(sinal))
    if pico < 1e-9:
        return sinal
    return sinal / pico * (10 ** (pico_db / 20))


def suavizar_bordas(sinal, entrada=0.003, saida=0.02):
    s = sinal.copy()
    ni, nf = int(entrada * TAXA), int(saida * TAXA)
    if ni:
        s[:ni] *= np.linspace(0, 1, ni)
    if nf:
        s[-nf:] *= np.linspace(1, 0, nf)
    return s


def salvar_wav(caminho: Path, sinal, estereo=None):
    caminho.parent.mkdir(parents=True, exist_ok=True)
    if estereo is not None:
        dados = np.stack([sinal, estereo], axis=1)
        canais = 2
    else:
        dados = sinal
        canais = 1
    pcm = (np.clip(dados, -1, 1) * 32767).astype("<i2")
    with wave.open(str(caminho), "wb") as w:
        w.setnchannels(canais)
        w.setsampwidth(2)
        w.setframerate(TAXA)
        w.writeframes(pcm.tobytes())


def salvar_ogg(caminho: Path, esquerda, direita=None, qualidade=5):
    temporario = caminho.with_suffix(".tmp.wav")
    salvar_wav(temporario, esquerda, direita)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(temporario), "-c:a", "libvorbis",
                    "-q:a", str(qualidade), str(caminho)], check=True)
    temporario.unlink()


def nota(nome: str) -> float:
    """'D4' → frequência em Hz (lá 440)."""
    nomes = {"C": -9, "C#": -8, "Db": -8, "D": -7, "D#": -6, "Eb": -6, "E": -5, "F": -4, "F#": -3,
             "Gb": -3, "G": -2, "G#": -1, "Ab": -1, "A": 0, "A#": 1, "Bb": 1, "B": 2}
    letra = nome[:-1]
    oitava = int(nome[-1])
    return 440.0 * 2 ** ((nomes[letra] + (oitava - 4) * 12) / 12)
