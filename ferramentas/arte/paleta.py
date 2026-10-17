"""Paleta-mestra do CRYPTBOUND.

Cada cor tem um caractere usado nas grades de pixel ('.' = transparente).
Rampas: as sombras puxam para roxo/azul e as luzes para amarelo (hue shifting),
para que tudo pareça iluminado por velas num lugar frio. Ver DIRECAO_ARTISTICA.md.
"""

PALETA = {
    # Escuros (contorno e sombras profundas, levemente roxos)
    "0": "#0b0910",
    "1": "#17121c",
    "2": "#241c2b",
    "3": "#352a3c",
    # Pedra fria (pisos, roupas escuras)
    "4": "#463b4c",
    "5": "#5a4f5e",
    "6": "#716671",
    "7": "#8c8189",
    # Cal e osso (paredes caiadas, ossadas)
    "8": "#a89a8c",
    "9": "#c4b6a0",
    "w": "#ddd0b6",
    "W": "#f2e8d0",
    # Azulejo vidrado
    "a": "#1c2442",
    "b": "#2c3d6e",
    "B": "#4766a8",
    "z": "#8fb0e0",
    # Fogo e cera acesa
    "o": "#5a1e10",
    "O": "#9c3a14",
    "y": "#e07a1f",
    "Y": "#f7bb47",
    "L": "#fff0b0",
    # Sangue e carne
    "r": "#2e0b12",
    "R": "#5c1520",
    "e": "#962530",
    "E": "#c94a42",
    "p": "#e3907a",
    # Pele (Coveira)
    "s": "#6e4335",
    "S": "#a8705a",
    "k": "#d9a283",
    # Cera fria (Lamuriante)
    "x": "#a39a7c",
    "c": "#cbbf98",
    "X": "#efe5c4",
    # Musgo
    "m": "#1d2619",
    "M": "#2f3f26",
    "g": "#4d6633",
    "G": "#86a050",
    # Raiz e madeira
    "h": "#2a1b16",
    "H": "#46302a",
    "j": "#6e4c3c",
    "J": "#9a7358",
    # Carne seca (Ressequido)
    "d": "#4a3d36",
    "D": "#6b5a4c",
    "f": "#8a7762",
    # Lamúria (magia roxa)
    "u": "#2d1840",
    "U": "#5a2f80",
    "i": "#9a5cd0",
    "I": "#d8b0ff",
    # Seiva luminosa da Raiz-que-Bebe
    "t": "#15333a",
    "T": "#24706e",
    "q": "#4fc4b0",
    "Q": "#b8f5e6",
}


def rgba(caractere: str, alfa: int = 255) -> tuple:
    h = PALETA[caractere].lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), alfa)


def cor(caractere: str) -> tuple:
    return rgba(caractere)
