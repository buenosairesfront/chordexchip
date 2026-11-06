[English](README.md) · **Español** · [Français](README.fr.md) · [Deutsch](README.de.md) · [日本語](README.ja.md) · [中文](README.zh.md) · [हिन्दी](README.hi.md)

# Chordex CHIP

Instrumento de acordes chiptune para [monome norns](https://monome.org/docs/norns/).
Una tecla toca un acorde de cuatro notas más el bajo (la tecla más grave
apretada marca la raíz) a través de un motor de chips de consola: 8 bancos
inspirados en chips de sonido clásicos, con 8 presets cada uno, 64 sonidos.

![Chordex CHIP, seis bancos](docs/sheet.png)

**La pantalla es un tracker:**

- **izquierda:** el patrón corriendo a tempo (1 fila = 1/16). Cada columna es
  una voz del acorde. La línea de play muestra siempre las notas que suenan,
  la línea vertical es una nota que sigue sonando, `===` es nota soltada y
  `0xy` es el arpegio de chip, como en los trackers de verdad.
- **arriba:** banco, preset, `ARP` con un iconito del patrón de arpegio (se
  ilumina el paso que suena) y la velocidad del arpegio de chip.
- **derecha:** la onda tal como suena, en píxeles gruesos, ya pasada por
  duty, PWM, ruido, bits, sample rate y filtro. Abajo, los 12 faders.

## Características

- **8 bancos × 8 presets**: NES, GB, C64, ATARI, MSX, PCE, AMIGA y OPL:
  leads, bajos, campanas, pads, arpegios y percusión (kick de triángulo,
  redoblante de ruido, explosión, láser, moneda…)
- **24 ondas de pocos bits** leídas escalón por escalón, sin interpolar, como
  un chip: pulso, triángulo NES de 4 bits, ondas de Game Boy y PC Engine,
  muestras de 8 bits estilo Amiga, ruidos LFSR estilo Atari, la onda
  combinada saw&tri del SID y senos OPL. En los bancos de consola el volumen
  también se mueve en 16 pasos
- **banco OPL**: FM de 2 operadores
- **arpegio de chip** (12–60 Hz): una sola voz recorre el acorde, como en las
  consolas
- **pitch sweep** y **vibrato** con retardo, **duty / PWM**, **ruido**,
  **bitcrush** y **sample rate**, **filtro** resonante (cutoff y resonancia),
  **eco** a tempo y hall
- **10 acordes**: maj, min, dim, aug, 7, maj7, min7, m7b5, sus2, sus4
- **arpegiador**: up, down, up-down, up x2, down x2, random y *arpa*; con el
  gate al máximo, legato real
- **modo acorde** on/off (off = una sola nota) y **retener**
- crackle de disco viejo con más de dos teclas apretadas
- sigue el clock MIDI entrante para el tempo del arpegio y del eco
- todo se guarda solo

<!-- u-ma:family -->
## La familia Chordex

Mismos controles, motores distintos. Probá los otros:

| | |
|---|---|
| <a href="https://github.com/buenosairesfront/chordex80/blob/main/README.es.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordex80/main/docs/1_d50.png" width="200" alt="Chordex 80"></a> | **[Chordex 80](https://github.com/buenosairesfront/chordex80/blob/main/README.es.md)**<br>polisynth ochentoso con atardecer outrun<br>`;install https://github.com/buenosairesfront/chordex80` |
| <a href="https://github.com/buenosairesfront/chordexfm/blob/main/README.es.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexfm/main/docs/3_metal.png" width="200" alt="Chordex FM"></a> | **[Chordex FM](https://github.com/buenosairesfront/chordexfm/blob/main/README.es.md)**<br>FM de 4 operadores, dibujado como una flor<br>`;install https://github.com/buenosairesfront/chordexfm` |
| <a href="https://github.com/buenosairesfront/chordexstg/blob/main/README.es.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexstg/main/docs/2_tutti.png" width="200" alt="ChordexSTG"></a> | **[ChordexSTG](https://github.com/buenosairesfront/chordexstg/blob/main/README.es.md)**<br>cuerdas de orquesta con el movimiento real de una cuerda frotada<br>`;install https://github.com/buenosairesfront/chordexstg` |
| <a href="https://github.com/buenosairesfront/chordexwt/blob/main/README.es.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexwt/main/docs/2_vocal.png" width="200" alt="Chordex WT"></a> | **[Chordex WT](https://github.com/buenosairesfront/chordexwt/blob/main/README.es.md)**<br>wavetable: 8 bancos de 8 ondas, dibujado como una tabla en 3D<br>`;install https://github.com/buenosairesfront/chordexwt` |

**Más de U-MA:** todos los instrumentos y herramientas en un solo lugar → [muestrario U-MA](https://github.com/buenosairesfront/U-ma/blob/main/README.es.md)
<!-- /u-ma:family -->

## Requisitos

- norns (shield, estándar o fates)
- un teclado o controlador MIDI

## Instalación

Desde maiden:

```
;install https://github.com/buenosairesfront/chordexchip
```

Después **reiniciá norns** (SYSTEM > RESTART) para que se compile el engine
nuevo `ChordexCHIP`, y cargá **chordexchip** desde SELECT.

## Controles

| control | acción |
|---|---|
| E1 | preset del banco |
| E2 | elige fader |
| E3 | ajusta fader |
| K3 + E1 | banco |
| K3 + E2 | arpegio de chip (off, 12–60 Hz) |
| K3 + E3 | tipo de acorde |
| K3 mantenido (sin girar) | modo acorde on/off |
| K2 (toque) | arpegiador on/off |
| K2 + E1 | gate del arpegio (máximo = legato) |
| K2 + E2 | patrón del arpegio |
| K2 + E3 | velocidad del arpegio |
| K2 + K3 + E3 | strum: + de grave a agudo, − de agudo a grave (ms entre voces) |
| K1 mantenido | retener on/off (puntito arriba) |

**Faders:** ataque, decay, duty, PWM, sweep, vibrato, ruido, fatness,
cutoff, resonancia, bits, sample rate. En el banco OPL, el duty marca cuánta
FM hay.

**Menú PARAMETERS:** canal MIDI (0 = todos, por defecto), divisor del reloj
MIDI, sustain, tiempo del sweep, octava, nivel del bajo, eco, hall, volumen y
todo lo anterior.

## Galería

| | |
|---|---|
| ![NES](docs/1_nes.png) NES · HERO LEAD · maj7 | ![GB](docs/2_gb_arp.png) GB · WAVE ARP · arpegio de chip `047` |
| ![C64](docs/3_c64_acid.png) C64 · SID ACID · min7 | ![ATARI](docs/4_atari.png) ATARI · BUZZ 5 |
| ![AMIGA](docs/5_amiga.png) AMIGA · MOD STRINGS · min7 | ![OPL](docs/6_opl_arp.png) OPL · FM PIANO · arpegio |

## Créditos

Hecho por [Buenos Aires Front](https://github.com/buenosairesfront) / U-MA.
Los nombres de los bancos remiten a los chips de sonido que los inspiraron;
este proyecto no está afiliado a Nintendo, Commodore, Atari, el consorcio
MSX, NEC, Hudson Soft ni Yamaha. Publicado bajo licencia MIT.
