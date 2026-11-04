[English](README.md) · [Español](README.es.md) · [Français](README.fr.md) · **Deutsch** · [日本語](README.ja.md) · [中文](README.zh.md) · [हिन्दी](README.hi.md)

# Chordex CHIP

Ein Chiptune-Akkordinstrument für [monome norns](https://monome.org/docs/norns/).
Eine Taste spielt einen Vierklang plus Bass (die tiefste gehaltene Taste
bestimmt den Grundton) über eine Konsolenchip-Engine: 8 Bänke, inspiriert von
klassischen Soundchips, mit je 8 Presets – 64 Klänge.

![Chordex CHIP, sechs Bänke](docs/sheet.png)

**Der Bildschirm ist ein Tracker:**

- **links:** das Pattern läuft im Takt durch (1 Zeile = 1/16). Jede Spalte
  ist eine Stimme des Akkords. Die Abspielzeile zeigt immer die klingenden
  Noten, der senkrechte Strich ist eine noch gehaltene Note, `===` ein
  Note-off und `0xy` das Chip-Arpeggio, wie in echten Trackern.
- **oben:** Bank, Preset, `ARP` mit einem winzigen Symbol des
  Arpeggio-Patterns (der gespielte Schritt leuchtet) und das Tempo des
  Chip-Arpeggios.
- **rechts:** die Welle so, wie sie klingt, in groben Pixeln, schon durch
  Duty, PWM, Rauschen, Bits, Samplerate und Filter geformt. Darunter die
  12 Fader.

## Funktionen

- **8 Bänke × 8 Presets**: NES, GB, C64, ATARI, MSX, PCE, AMIGA und OPL –
  Leads, Bässe, Glocken, Flächen, Arpeggios und Drums (Dreieck-Kick,
  Rausch-Snare, Explosion, Laser, Münze …)
- **24 Wellen mit wenigen Bits**, Schritt für Schritt ohne Interpolation
  gelesen, wie ein Chip: Puls, 4-Bit-NES-Dreieck, Game-Boy- und
  PC-Engine-Wellen, 8-Bit-Samples im Amiga-Stil, LFSR-Rauschen im Atari-Stil,
  die kombinierte Saw&Tri-Welle des SID und OPL-Sinus. In den Konsolenbänken
  bewegt sich auch die Lautstärke in 16 Stufen
- **OPL-Bank**: FM mit 2 Operatoren
- **Chip-Arpeggio** (12–60 Hz): eine einzige Stimme läuft durch den Akkord,
  wie bei den Konsolen
- **Pitch-Sweep** und verzögertes **Vibrato**, **Duty / PWM**, **Rauschen**,
  **Bitcrush** und **Samplerate**, resonanter **Filter** (Cutoff und
  Resonanz), tempo-synchrones **Echo** und Hall
- **10 Akkorde**: maj, min, dim, aug, 7, maj7, min7, m7b5, sus2, sus4
- **Arpeggiator**: up, down, up-down, up x2, down x2, random und *arpa*
  (Harfe); Gate am Maximum = echtes Legato
- **Akkordmodus** an/aus (aus = Einzelnoten) und **Hold**
- Knistern einer alten Platte bei mehr als zwei gehaltenen Tasten
- folgt eingehender MIDI-Clock für das Tempo von Arpeggio und Echo
- alle Einstellungen werden automatisch gespeichert

<!-- u-ma:family -->
## Die Chordex-Familie

Gleiche Bedienung, andere Engines. Probier die anderen aus:

| | |
|---|---|
| <a href="https://github.com/buenosairesfront/chordex80/blob/main/README.de.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordex80/main/docs/1_d50.png" width="200" alt="Chordex 80"></a> | **[Chordex 80](https://github.com/buenosairesfront/chordex80/blob/main/README.de.md)**<br>80er-Polysynth mit Outrun-Sonnenuntergang<br>`;install https://github.com/buenosairesfront/chordex80` |
| <a href="https://github.com/buenosairesfront/chordexfm/blob/main/README.de.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexfm/main/docs/3_metal.png" width="200" alt="Chordex FM"></a> | **[Chordex FM](https://github.com/buenosairesfront/chordexfm/blob/main/README.de.md)**<br>FM mit 4 Operatoren, als Blume gezeichnet<br>`;install https://github.com/buenosairesfront/chordexfm` |
| <a href="https://github.com/buenosairesfront/chordexstg/blob/main/README.de.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexstg/main/docs/2_tutti.png" width="200" alt="ChordexSTG"></a> | **[ChordexSTG](https://github.com/buenosairesfront/chordexstg/blob/main/README.de.md)**<br>Orchesterstreicher mit echter Bewegung einer gestrichenen Saite<br>`;install https://github.com/buenosairesfront/chordexstg` |
| <a href="https://github.com/buenosairesfront/chordexwt/blob/main/README.de.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexwt/main/docs/2_vocal.png" width="200" alt="Chordex WT"></a> | **[Chordex WT](https://github.com/buenosairesfront/chordexwt/blob/main/README.de.md)**<br>Wavetable: 8 Bänke mit je 8 Wellen, als 3D-Tabelle gezeichnet<br>`;install https://github.com/buenosairesfront/chordexwt` |

**Mehr von U-MA:** alle Instrumente und Werkzeuge an einem Ort → [U-MA-Übersicht](https://github.com/buenosairesfront/U-ma/blob/main/README.de.md)
<!-- /u-ma:family -->

## Voraussetzungen

- norns (shield, Standard oder fates)
- ein MIDI-Keyboard oder -Controller

## Installation

In maiden:

```
;install https://github.com/buenosairesfront/chordexchip
```

Danach **norns neu starten** (SYSTEM > RESTART), damit die neue Engine
`ChordexCHIP` kompiliert wird, und **chordexchip** über SELECT laden.

## Bedienung

| Bedienelement | Funktion |
|---|---|
| E1 | Preset der Bank |
| E2 | Fader wählen |
| E3 | Fader einstellen |
| K3 + E1 | Bank |
| K3 + E2 | Chip-Arpeggio (aus, 12–60 Hz) |
| K3 + E3 | Akkordtyp |
| K3 halten (ohne Drehen) | Akkordmodus an/aus |
| K2 (Tippen) | Arpeggiator an/aus |
| K2 + E1 | Arpeggio-Gate (Maximum = Legato) |
| K2 + E2 | Arpeggio-Pattern |
| K2 + E3 | Arpeggio-Tempo |
| K1 halten | Hold an/aus (kleiner Punkt oben) |

**Fader:** Attack, Decay, Duty, PWM, Sweep, Vibrato, Rauschen, Fatness,
Cutoff, Resonanz, Bits, Samplerate. In der OPL-Bank bestimmt Duty die
FM-Menge.

**PARAMETERS-Menü:** MIDI-Kanal (0 = alle, Standard), MIDI-Clock-Teiler,
Sustain, Sweep-Zeit, Oktave, Basspegel, Echo, Hall, Lautstärke und alles
oben Genannte.

## Galerie

| | |
|---|---|
| ![NES](docs/1_nes.png) NES · HERO LEAD · maj7 | ![GB](docs/2_gb_arp.png) GB · WAVE ARP · Chip-Arpeggio `047` |
| ![C64](docs/3_c64_acid.png) C64 · SID ACID · min7 | ![ATARI](docs/4_atari.png) ATARI · BUZZ 5 |
| ![AMIGA](docs/5_amiga.png) AMIGA · MOD STRINGS · min7 | ![OPL](docs/6_opl_arp.png) OPL · FM PIANO · Arpeggio |

## Credits

Erstellt von [Buenos Aires Front](https://github.com/buenosairesfront) / U-MA.
Die Banknamen verweisen auf die Soundchips, die sie inspiriert haben; dieses
Projekt steht in keiner Verbindung zu Nintendo, Commodore, Atari, dem
MSX-Konsortium, NEC, Hudson Soft oder Yamaha. Veröffentlicht unter der
MIT-Lizenz.
