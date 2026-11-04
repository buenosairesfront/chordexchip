[English](README.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [日本語](README.ja.md) · [中文](README.zh.md) · **हिन्दी**

# Chordex CHIP

[monome norns](https://monome.org/docs/norns/) के लिए एक चिपट्यून कॉर्ड वाद्य।
एक कुंजी चार सुरों का कॉर्ड और बेस बजाती है (दबाई गई सबसे नीची कुंजी मूल सुर तय करती है), और आवाज़ आती है गेम-कंसोल के साउंड चिप जैसे इंजन से: क्लासिक साउंड चिप्स से प्रेरित 8 बैंक, हर बैंक में 8 प्रीसेट, कुल 64 आवाज़ें।

![Chordex CHIP, छह बैंक](docs/sheet.png)

**स्क्रीन एक ट्रैकर है:**

- **बाएँ:** टेम्पो के साथ चलता पैटर्न (1 पंक्ति = 1/16)। हर कॉलम कॉर्ड की एक आवाज़ है। प्ले लाइन पर हमेशा बज रहे सुर दिखते हैं, खड़ी रेखा का मतलब है सुर अभी भी बज रहा है, `===` नोट-ऑफ़ है और `0xy` चिप आर्पेजियो है, असली ट्रैकरों की तरह।
- **ऊपर:** बैंक, प्रीसेट, `ARP` के साथ आर्पेजियो पैटर्न का छोटा आइकन (जो कदम बज रहा है वह चमकता है) और चिप आर्पेजियो की गति।
- **दाएँ:** जैसी बज रही है वैसी वेव, मोटे पिक्सेल में, ड्यूटी, PWM, नॉइज़, बिट्स, सैंपल रेट और फ़िल्टर लगने के बाद। नीचे 12 फ़ेडर।

## विशेषताएँ

- **8 बैंक × 8 प्रीसेट**: NES, GB, C64, ATARI, MSX, PCE, AMIGA और OPL — लीड, बेस, घंटियाँ, पैड, आर्पेजियो और ड्रम (ट्रायंगल किक, नॉइज़ स्नेयर, धमाका, लेज़र, सिक्का…)
- **कम बिट वाली 24 वेव**, चिप की तरह बिना इंटरपोलेशन के कदम-दर-कदम पढ़ी जाती हैं: पल्स, 4-बिट NES ट्रायंगल, Game Boy और PC Engine की वेव, Amiga जैसे 8-बिट सैंपल, Atari जैसा LFSR नॉइज़, SID की saw&tri मिली-जुली वेव और OPL साइन। कंसोल वाले बैंकों में वॉल्यूम भी 16 कदमों में बदलता है
- **OPL बैंक**: 2-ऑपरेटर FM
- **चिप आर्पेजियो** (12–60 Hz): कंसोल की तरह एक ही आवाज़ कॉर्ड के सुरों पर तेज़ी से घूमती है
- **पिच स्वीप** और देर से शुरू होने वाला **वाइब्रेटो**, **ड्यूटी / PWM**, **नॉइज़**, **बिटक्रश** और **सैंपल रेट**, रेज़ोनेंट **फ़िल्टर** (कटऑफ़ और रेज़ोनेंस), टेम्पो से जुड़ा **इको** और हॉल
- **10 कॉर्ड**: maj, min, dim, aug, 7, maj7, min7, m7b5, sus2, sus4
- **आर्पेजिएटर**: up, down, up-down, up x2, down x2, random और *arpa* (हार्प); गेट अधिकतम पर असली लेगाटो
- **कॉर्ड मोड** चालू/बंद (बंद = एक सुर) और **होल्ड**
- दो से ज़्यादा कुंजियाँ दबाने पर पुराने रिकॉर्ड जैसी चटक
- आने वाली MIDI क्लॉक से आर्पेजियो और इको का टेम्पो लेता है
- सारी सेटिंग अपने-आप सेव होती हैं

<!-- u-ma:family -->
## Chordex परिवार

कंट्रोल वही, इंजन अलग। बाकी भी आज़माएँ:

| | |
|---|---|
| <a href="https://github.com/buenosairesfront/chordex80/blob/main/README.hi.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordex80/main/docs/1_d50.png" width="200" alt="Chordex 80"></a> | **[Chordex 80](https://github.com/buenosairesfront/chordex80/blob/main/README.hi.md)**<br>outrun सूर्यास्त वाला 80 के दशक का पॉलीसिंथ<br>`;install https://github.com/buenosairesfront/chordex80` |
| <a href="https://github.com/buenosairesfront/chordexfm/blob/main/README.hi.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexfm/main/docs/3_metal.png" width="200" alt="Chordex FM"></a> | **[Chordex FM](https://github.com/buenosairesfront/chordexfm/blob/main/README.hi.md)**<br>4-ऑपरेटर FM, फूल के रूप में<br>`;install https://github.com/buenosairesfront/chordexfm` |
| <a href="https://github.com/buenosairesfront/chordexstg/blob/main/README.hi.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexstg/main/docs/2_tutti.png" width="200" alt="ChordexSTG"></a> | **[ChordexSTG](https://github.com/buenosairesfront/chordexstg/blob/main/README.hi.md)**<br>गज़ से बजे तार की असली गति वाले ऑर्केस्ट्रा स्ट्रिंग्स<br>`;install https://github.com/buenosairesfront/chordexstg` |
| <a href="https://github.com/buenosairesfront/chordexwt/blob/main/README.hi.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexwt/main/docs/2_vocal.png" width="200" alt="Chordex WT"></a> | **[Chordex WT](https://github.com/buenosairesfront/chordexwt/blob/main/README.hi.md)**<br>वेवटेबल: 8 वेव वाले 8 बैंक, 3D टेबल के रूप में<br>`;install https://github.com/buenosairesfront/chordexwt` |

**U-MA से और:** सभी वाद्य और टूल एक जगह → [U-MA शोकेस](https://github.com/buenosairesfront/U-ma/blob/main/README.hi.md)
<!-- /u-ma:family -->

## ज़रूरतें

- norns (shield, standard या fates)
- MIDI कीबोर्ड या कंट्रोलर

## इंस्टॉल

maiden में:

```
;install https://github.com/buenosairesfront/chordexchip
```

फिर नया इंजन `ChordexCHIP` कंपाइल होने के लिए **norns को रीस्टार्ट करें** (SYSTEM > RESTART), और SELECT से **chordexchip** लोड करें।

## कंट्रोल

| कंट्रोल | काम |
|---|---|
| E1 | बैंक का प्रीसेट |
| E2 | फ़ेडर चुनें |
| E3 | फ़ेडर समायोजित करें |
| K3 + E1 | बैंक |
| K3 + E2 | चिप आर्पेजियो (बंद, 12–60 Hz) |
| K3 + E3 | कॉर्ड का प्रकार |
| K3 दबाए रखें (बिना घुमाए) | कॉर्ड मोड चालू/बंद |
| K2 (टैप) | आर्पेजिएटर चालू/बंद |
| K2 + E1 | आर्पेजियो गेट (अधिकतम = लेगाटो) |
| K2 + E2 | आर्पेजियो पैटर्न |
| K2 + E3 | आर्पेजियो गति |
| K1 दबाए रखें | होल्ड चालू/बंद (ऊपर छोटा बिंदु) |

**फ़ेडर:** अटैक, डिके, ड्यूटी, PWM, स्वीप, वाइब्रेटो, नॉइज़, fatness, कटऑफ़, रेज़ोनेंस, बिट्स, सैंपल रेट। OPL बैंक में ड्यूटी FM की मात्रा तय करता है।

**PARAMETERS मेनू:** MIDI चैनल (0 = सभी, डिफ़ॉल्ट), MIDI क्लॉक डिवाइडर, सस्टेन, स्वीप का समय, ऑक्टेव, बेस का स्तर, इको, हॉल, वॉल्यूम, और ऊपर का सब कुछ।

## गैलरी

| | |
|---|---|
| ![NES](docs/1_nes.png) NES · HERO LEAD · maj7 | ![GB](docs/2_gb_arp.png) GB · WAVE ARP · चिप आर्पेजियो `047` |
| ![C64](docs/3_c64_acid.png) C64 · SID ACID · min7 | ![ATARI](docs/4_atari.png) ATARI · BUZZ 5 |
| ![AMIGA](docs/5_amiga.png) AMIGA · MOD STRINGS · min7 | ![OPL](docs/6_opl_arp.png) OPL · FM PIANO · आर्पेजियो |

## श्रेय

[Buenos Aires Front](https://github.com/buenosairesfront) / U-MA द्वारा बनाया गया।
बैंकों के नाम उन साउंड चिप्स की ओर इशारा करते हैं जिनसे वे प्रेरित हैं; यह प्रोजेक्ट Nintendo, Commodore, Atari, MSX कंसोर्टियम, NEC, Hudson Soft या Yamaha से संबद्ध नहीं है। MIT लाइसेंस।
