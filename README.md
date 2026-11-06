**English** · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [日本語](README.ja.md) · [中文](README.zh.md) · [हिन्दी](README.hi.md)

# Chordex CHIP

A chiptune chord instrument for [monome norns](https://monome.org/docs/norns/).
One key plays a four-note chord plus bass (the lowest key held sets the root)
through a console-chip engine: 8 banks inspired by classic sound chips, with
8 presets each — 64 sounds.

![Chordex CHIP, six banks](docs/sheet.png)

**The screen is a tracker:**

- **left:** the pattern scrolling in time (1 row = 1/16). Each column is one
  voice of the chord. The play line always shows the notes that are sounding,
  the vertical line is a note still held, `===` is a note-off and `0xy` is the
  chip arpeggio, as in real trackers.
- **top:** bank, preset, `ARP` with a tiny icon of the arpeggio pattern (the
  step that is playing lights up) and the chip-arpeggio speed.
- **right:** the wave as it sounds, in chunky pixels, already shaped by duty,
  PWM, noise, bits, sample rate and filter. Below, the 12 faders.

## Features

- **8 banks × 8 presets**: NES, GB, C64, ATARI, MSX, PCE, AMIGA and OPL —
  leads, basses, bells, pads, arpeggios and drums (triangle kick, noise snare,
  explosion, laser, coin…)
- **24 low-bit waves** read step by step with no interpolation, like a chip:
  pulse, 4-bit NES triangle, Game Boy and PC Engine wave-channel waves, 8-bit
  Amiga-style samples, Atari-style LFSR noise, the SID saw&tri combined wave
  and OPL sines. On the console banks the volume also moves in 16 steps
- **OPL bank**: 2-operator FM
- **chip arpeggio** (12–60 Hz): one voice runs through the chord, like the
  consoles did
- **pitch sweep** and delayed **vibrato**, **duty / PWM**, **noise**,
  **bitcrush** and **sample rate**, resonant **filter** (cutoff and
  resonance), tempo-synced **echo** and hall
- **10 chords**: maj, min, dim, aug, 7, maj7, min7, m7b5, sus2, sus4
- **arpeggiator**: up, down, up-down, up x2, down x2, random and *arpa*
  (harp); gate at maximum = real legato
- **chord mode** on/off (off = single notes) and **hold**
- old-record crackle when more than two keys are held
- follows incoming MIDI clock for the arpeggio and echo tempo
- all settings are saved automatically

<!-- u-ma:family -->
## The Chordex family

Same controls, different engines. Try the others:

| | |
|---|---|
| <a href="https://github.com/buenosairesfront/chordex80"><img src="https://raw.githubusercontent.com/buenosairesfront/chordex80/main/docs/1_d50.png" width="200" alt="Chordex 80"></a> | **[Chordex 80](https://github.com/buenosairesfront/chordex80)**<br>'80s polysynth with an outrun sunset<br>`;install https://github.com/buenosairesfront/chordex80` |
| <a href="https://github.com/buenosairesfront/chordexfm"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexfm/main/docs/3_metal.png" width="200" alt="Chordex FM"></a> | **[Chordex FM](https://github.com/buenosairesfront/chordexfm)**<br>4-operator FM, drawn as a flower<br>`;install https://github.com/buenosairesfront/chordexfm` |
| <a href="https://github.com/buenosairesfront/chordexstg"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexstg/main/docs/2_tutti.png" width="200" alt="ChordexSTG"></a> | **[ChordexSTG](https://github.com/buenosairesfront/chordexstg)**<br>orchestral strings with real bowed-string motion<br>`;install https://github.com/buenosairesfront/chordexstg` |
| <a href="https://github.com/buenosairesfront/chordexwt"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexwt/main/docs/2_vocal.png" width="200" alt="Chordex WT"></a> | **[Chordex WT](https://github.com/buenosairesfront/chordexwt)**<br>wavetable: 8 banks of 8 waves, drawn as a 3D table<br>`;install https://github.com/buenosairesfront/chordexwt` |

**More from U-MA:** every instrument and tool in one place → [U-MA showcase](https://github.com/buenosairesfront/U-ma)
<!-- /u-ma:family -->

## Requirements

- norns (shield, standard or fates)
- a MIDI keyboard or controller

## Install

From maiden:

```
;install https://github.com/buenosairesfront/chordexchip
```

Then **restart norns** (SYSTEM > RESTART) so the new engine `ChordexCHIP` is
compiled, and load **chordexchip** from SELECT.

## Controls

| control | action |
|---|---|
| E1 | preset of the bank |
| E2 | select fader |
| E3 | adjust fader |
| K3 + E1 | bank |
| K3 + E2 | chip arpeggio (off, 12–60 Hz) |
| K3 + E3 | chord type |
| K3 held (without turning) | chord mode on/off |
| K2 (tap) | arpeggiator on/off |
| K2 + E1 | arpeggio gate (max = legato) |
| K2 + E2 | arpeggio pattern |
| K2 + E3 | arpeggio speed |
| K2 + K3 | opens the STRUM panel (stays open; closes 3 s after the last turn or with K2 + K3 again): E3 = time between the chord notes in beat divisions (MIDI clock if present, otherwise the norns tempo); + plays from the first note to the last, − from the last to the first |
| K1 held | hold on/off (small dot at the top) |

**Faders:** attack, decay, duty, PWM, sweep, vibrato, noise, fatness,
cutoff, resonance, bits, sample rate. In the OPL bank, duty sets the amount
of FM.

**PARAMETERS menu:** MIDI channel (0 = all, the default), MIDI clock divider,
sustain, sweep time, octave, bass level, echo, hall, volume, and everything
above.

## Gallery

| | |
|---|---|
| ![NES](docs/1_nes.png) NES · HERO LEAD · maj7 | ![GB](docs/2_gb_arp.png) GB · WAVE ARP · chip arpeggio `047` |
| ![C64](docs/3_c64_acid.png) C64 · SID ACID · min7 | ![ATARI](docs/4_atari.png) ATARI · BUZZ 5 |
| ![AMIGA](docs/5_amiga.png) AMIGA · MOD STRINGS · min7 | ![OPL](docs/6_opl_arp.png) OPL · FM PIANO · arpeggio |

## Credits

Made by [Buenos Aires Front](https://github.com/buenosairesfront) / U-MA.
Bank names refer to the sound chips that inspired them; this project is not
affiliated with Nintendo, Commodore, Atari, the MSX consortium, NEC, Hudson
Soft or Yamaha. Released under the MIT license.
