[English](README.md) · [Español](README.es.md) · **Français** · [Deutsch](README.de.md) · [日本語](README.ja.md) · [中文](README.zh.md) · [हिन्दी](README.hi.md)

# Chordex CHIP

Un instrument d'accords chiptune pour [monome norns](https://monome.org/docs/norns/).
Une touche joue un accord de quatre notes plus la basse (la touche la plus
grave tenue donne la fondamentale) à travers un moteur de puces de console :
8 banques inspirées de puces sonores classiques, avec 8 presets chacune,
soit 64 sons.

![Chordex CHIP, six banques](docs/sheet.png)

**L'écran est un tracker :**

- **à gauche :** le pattern qui défile en rythme (1 ligne = 1/16). Chaque
  colonne est une voix de l'accord. La ligne de lecture montre toujours les
  notes qui sonnent, le trait vertical est une note encore tenue, `===` est
  un note-off et `0xy` l'arpège de puce, comme dans les vrais trackers.
- **en haut :** banque, preset, `ARP` avec une petite icône du motif
  d'arpège (le pas joué s'allume) et la vitesse de l'arpège de puce.
- **à droite :** l'onde telle qu'elle sonne, en gros pixels, déjà passée par
  le duty, la PWM, le bruit, les bits, la fréquence d'échantillonnage et le
  filtre. En dessous, les 12 faders.

## Fonctions

- **8 banques × 8 presets** : NES, GB, C64, ATARI, MSX, PCE, AMIGA et OPL —
  leads, basses, cloches, nappes, arpèges et percussions (kick triangle,
  caisse claire de bruit, explosion, laser, pièce…)
- **24 ondes à peu de bits** lues pas à pas, sans interpolation, comme une
  puce : pulse, triangle NES 4 bits, ondes Game Boy et PC Engine,
  échantillons 8 bits façon Amiga, bruits LFSR façon Atari, l'onde combinée
  saw&tri du SID et les sinus OPL. Sur les banques de console, le volume
  bouge aussi en 16 pas
- **banque OPL** : FM à 2 opérateurs
- **arpège de puce** (12–60 Hz) : une seule voix parcourt l'accord, comme sur
  les consoles
- **pitch sweep** et **vibrato** retardé, **duty / PWM**, **bruit**,
  **bitcrush** et **fréquence d'échantillonnage**, **filtre** résonant
  (cutoff et résonance), **écho** synchronisé au tempo et hall
- **10 accords** : maj, min, dim, aug, 7, maj7, min7, m7b5, sus2, sus4
- **arpégiateur** : up, down, up-down, up x2, down x2, random et *arpa*
  (harpe) ; gate au maximum = vrai legato
- **mode accord** on/off (off = notes seules) et **hold**
- craquement de vieux disque au-delà de deux touches tenues
- suit l'horloge MIDI entrante pour le tempo de l'arpège et de l'écho
- tous les réglages sont sauvegardés automatiquement

<!-- u-ma:family -->
## La famille Chordex

Mêmes contrôles, moteurs différents. Essayez les autres :

| | |
|---|---|
| <a href="https://github.com/buenosairesfront/chordex80/blob/main/README.fr.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordex80/main/docs/1_d50.png" width="200" alt="Chordex 80"></a> | **[Chordex 80](https://github.com/buenosairesfront/chordex80/blob/main/README.fr.md)**<br>polysynthé des années 80 avec un coucher de soleil outrun<br>`;install https://github.com/buenosairesfront/chordex80` |
| <a href="https://github.com/buenosairesfront/chordexfm/blob/main/README.fr.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexfm/main/docs/3_metal.png" width="200" alt="Chordex FM"></a> | **[Chordex FM](https://github.com/buenosairesfront/chordexfm/blob/main/README.fr.md)**<br>FM à 4 opérateurs, dessinée comme une fleur<br>`;install https://github.com/buenosairesfront/chordexfm` |
| <a href="https://github.com/buenosairesfront/chordexstg/blob/main/README.fr.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexstg/main/docs/2_tutti.png" width="200" alt="ChordexSTG"></a> | **[ChordexSTG](https://github.com/buenosairesfront/chordexstg/blob/main/README.fr.md)**<br>cordes d'orchestre avec le vrai mouvement d'une corde frottée<br>`;install https://github.com/buenosairesfront/chordexstg` |
| <a href="https://github.com/buenosairesfront/chordexwt/blob/main/README.fr.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexwt/main/docs/2_vocal.png" width="200" alt="Chordex WT"></a> | **[Chordex WT](https://github.com/buenosairesfront/chordexwt/blob/main/README.fr.md)**<br>wavetable : 8 banques de 8 ondes, dessinée comme une table en 3D<br>`;install https://github.com/buenosairesfront/chordexwt` |

**Plus de U-MA :** tous les instruments et outils au même endroit → [vitrine U-MA](https://github.com/buenosairesfront/U-ma/blob/main/README.fr.md)
<!-- /u-ma:family -->

## Prérequis

- norns (shield, standard ou fates)
- un clavier ou contrôleur MIDI

## Installation

Depuis maiden :

```
;install https://github.com/buenosairesfront/chordexchip
```

Ensuite **redémarrez norns** (SYSTEM > RESTART) pour compiler le nouveau
moteur `ChordexCHIP`, puis chargez **chordexchip** depuis SELECT.

## Contrôles

| contrôle | action |
|---|---|
| E1 | preset de la banque |
| E2 | choisir le fader |
| E3 | régler le fader |
| K3 + E1 | banque |
| K3 + E2 | arpège de puce (off, 12–60 Hz) |
| K3 + E3 | type d'accord |
| K3 maintenu (sans tourner) | mode accord on/off |
| K2 (appui court) | arpégiateur on/off |
| K2 + E1 | gate de l'arpège (max = legato) |
| K2 + E2 | motif de l'arpège |
| K2 + E3 | vitesse de l'arpège |
| K1 maintenu | hold on/off (petit point en haut) |

**Faders :** attaque, decay, duty, PWM, sweep, vibrato, bruit, fatness,
cutoff, résonance, bits, fréquence d'échantillonnage. Dans la banque OPL, le
duty règle la quantité de FM.

**Menu PARAMETERS :** canal MIDI (0 = tous, par défaut), diviseur d'horloge
MIDI, sustain, durée du sweep, octave, niveau de basse, écho, hall, volume et
tout ce qui précède.

## Galerie

| | |
|---|---|
| ![NES](docs/1_nes.png) NES · HERO LEAD · maj7 | ![GB](docs/2_gb_arp.png) GB · WAVE ARP · arpège de puce `047` |
| ![C64](docs/3_c64_acid.png) C64 · SID ACID · min7 | ![ATARI](docs/4_atari.png) ATARI · BUZZ 5 |
| ![AMIGA](docs/5_amiga.png) AMIGA · MOD STRINGS · min7 | ![OPL](docs/6_opl_arp.png) OPL · FM PIANO · arpège |

## Crédits

Réalisé par [Buenos Aires Front](https://github.com/buenosairesfront) / U-MA.
Les noms des banques renvoient aux puces sonores qui les ont inspirées ; ce
projet n'est affilié ni à Nintendo, Commodore, Atari, au consortium MSX, NEC,
Hudson Soft ou Yamaha. Publié sous licence MIT.
