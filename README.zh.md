[English](README.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [日本語](README.ja.md) · **中文** · [हिन्दी](README.hi.md)

# Chordex CHIP

为 [monome norns](https://monome.org/docs/norns/) 打造的芯片音乐（chiptune）和弦乐器。
按一个键即可演奏四音和弦加低音（按住的最低键决定根音），声音来自游戏机声音芯片风格的引擎：8 个库灵感来自经典声音芯片，每库 8 个预设，共 64 种音色。

![Chordex CHIP，六个库](docs/sheet.png)

**屏幕是一个 tracker：**

- **左侧：** 随节奏滚动的 pattern（1 行 = 1/16）。每一列是和弦中的一个声部。播放线上始终显示正在发声的音符，竖线表示仍在延续的音符，`===` 表示松键（note-off），`0xy` 表示芯片琶音，与真正的 tracker 写法一致。
- **顶部：** 库、预设、`ARP` 以及琶音模式的小图标（正在演奏的那一步会亮起），还有芯片琶音的速度。
- **右侧：** 以粗像素显示实际发声的波形，已经过占空比、PWM、噪声、位深、采样率和滤波器的处理。下方是 12 个推子。

## 功能

- **8 个库 × 8 个预设**：NES、GB、C64、ATARI、MSX、PCE、AMIGA 和 OPL——主音、贝斯、钟声、铺底、琶音和鼓（三角波底鼓、噪声军鼓、爆炸、激光、金币……）
- **24 种低位深波形**，像芯片一样逐级读取、不做插值：脉冲波、4 位 NES 三角波、Game Boy 与 PC Engine 的波表音色、Amiga 风格 8 位采样、Atari 风格 LFSR 噪声、SID 的 saw&tri 组合波和 OPL 正弦波。在游戏机类的库中，音量也以 16 级变化
- **OPL 库**：2 算子 FM
- **芯片琶音**（12–60 Hz）：像游戏机那样，用一个声部快速轮流演奏和弦
- **音高扫频**和带延迟的**颤音**、**占空比 / PWM**、**噪声**、**降位（bitcrush）**和**采样率**、带共振的**滤波器**（截止频率与共振）、与节拍同步的**回声**和混响厅
- **10 种和弦**：maj、min、dim、aug、7、maj7、min7、m7b5、sus2、sus4
- **琶音器**：up、down、up-down、up x2、down x2、random 和 *arpa*（竖琴）；门限开到最大即为真正的连奏
- **和弦模式**开/关（关 = 单音）和**保持**
- 跟随外部 MIDI 时钟决定琶音与回声的速度
- 所有设置自动保存

<!-- u-ma:family -->
## Chordex 系列

操作相同，引擎不同。也来试试其他几款：

| | |
|---|---|
| <a href="https://github.com/buenosairesfront/chordex80/blob/main/README.zh.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordex80/main/docs/1_d50.png" width="200" alt="Chordex 80"></a> | **[Chordex 80](https://github.com/buenosairesfront/chordex80/blob/main/README.zh.md)**<br>80 年代复音合成器，配 outrun 日落画面<br>`;install https://github.com/buenosairesfront/chordex80` |
| <a href="https://github.com/buenosairesfront/chordexfm/blob/main/README.zh.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexfm/main/docs/3_metal.png" width="200" alt="Chordex FM"></a> | **[Chordex FM](https://github.com/buenosairesfront/chordexfm/blob/main/README.zh.md)**<br>4 算子 FM，画成一朵花<br>`;install https://github.com/buenosairesfront/chordexfm` |
| <a href="https://github.com/buenosairesfront/chordexstg/blob/main/README.zh.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexstg/main/docs/2_tutti.png" width="200" alt="ChordexSTG"></a> | **[ChordexSTG](https://github.com/buenosairesfront/chordexstg/blob/main/README.zh.md)**<br>管弦乐弦乐，呈现真实的拉弦运动<br>`;install https://github.com/buenosairesfront/chordexstg` |
| <a href="https://github.com/buenosairesfront/chordexwt/blob/main/README.zh.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexwt/main/docs/2_vocal.png" width="200" alt="Chordex WT"></a> | **[Chordex WT](https://github.com/buenosairesfront/chordexwt/blob/main/README.zh.md)**<br>波表：8 个库、每库 8 个波形，画成 3D 波表<br>`;install https://github.com/buenosairesfront/chordexwt` |

**更多 U-MA 作品：** 所有乐器和工具汇集一处 → [U-MA 作品集](https://github.com/buenosairesfront/U-ma/blob/main/README.zh.md)
<!-- /u-ma:family -->

## 需求

- norns（shield、标准版或 fates）
- MIDI 键盘或控制器

## 安装

在 maiden 中：

```
;install https://github.com/buenosairesfront/chordexchip
```

然后**重启 norns**（SYSTEM > RESTART）以编译新引擎 `ChordexCHIP`，再从 SELECT 载入 **chordexchip**。

## 操作

| 操作 | 功能 |
|---|---|
| E1 | 库中的预设 |
| E2 | 选择推子 |
| E3 | 调节推子 |
| K3 + E1 | 库 |
| K3 + E2 | 芯片琶音（关、12–60 Hz） |
| K3 + E3 | 和弦类型 |
| 按住 K3（不旋转） | 和弦模式开/关 |
| K2（轻按） | 琶音器开/关 |
| K2 + E1 | 琶音门限（最大 = 连奏） |
| K2 + E2 | 琶音模式 |
| K2 + E3 | 琶音速度 |
| K2 + K3 | 打开 STRUM 面板（保持打开；最后一次旋转 3 秒后或再按 K2 + K3 关闭）：E3 = 和弦音之间的间隔，以拍的分割计（有 MIDI 时钟时用它，否则用 norns 速度）；+ 从第一个音到最后一个，− 从最后一个到第一个 |
| 按住 K1 | 保持开/关（顶部的小点） |

**推子：** 起音、衰减、占空比、PWM、扫频、颤音、噪声、厚度（fatness）、截止频率、共振、位深、采样率。在 OPL 库中，占空比控制 FM 的量。

**PARAMETERS 菜单：** MIDI 通道（0 = 全部，默认）、MIDI 时钟分频、延音（sustain）、扫频时间、八度、低音音量、回声、混响厅、音量，以及以上全部参数。

## 图库

| | |
|---|---|
| ![NES](docs/1_nes.png) NES · HERO LEAD · maj7 | ![GB](docs/2_gb_arp.png) GB · WAVE ARP · 芯片琶音 `047` |
| ![C64](docs/3_c64_acid.png) C64 · SID ACID · min7 | ![ATARI](docs/4_atari.png) ATARI · BUZZ 5 |
| ![AMIGA](docs/5_amiga.png) AMIGA · MOD STRINGS · min7 | ![OPL](docs/6_opl_arp.png) OPL · FM PIANO · 琶音 |

## 致谢

由 [Buenos Aires Front](https://github.com/buenosairesfront) / U-MA 制作。
库名指的是给予灵感的声音芯片；本项目与 Nintendo、Commodore、Atari、MSX 联盟、NEC、Hudson Soft 及 Yamaha 均无关联。以 MIT 许可证发布。
