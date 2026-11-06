-- Chordex CHIP
-- hermano chiptune de Chordex80 / ChordexFM / ChordexWT: mismo instrumento
-- de acordes (una tecla = un acorde de 4 tonos + bajo, suena la nota más
-- grave apretada, arpegio, retener, crackle con más de 2 teclas) con un
-- motor de chips de consola: 8 bancos x 8 presets.
--
-- La pantalla es un TRACKER:
--   izquierda: el patrón corriendo a tempo (1 fila = 1/16). Cada columna es
--     una voz del acorde; "===" es nota soltada, la línea vertical es una
--     nota que sigue sonando y "0xy" es el arpegio de chip (como en los
--     trackers de verdad).
--   derecha arriba: el preset y la onda tal como suena (duty, PWM, ruido,
--     bits, sample rate y filtro aplicados), en píxeles gruesos.
--   derecha abajo: los 12 faders.
--
-- Controles (los mismos de Chordex80 / ChordexFM / ChordexWT):
--   E1: preset del banco         K3 + E1: banco NES/GB/C64/ATARI/MSX/PCE/
--                                         AMIGA/OPL
--   E2: elige fader              K3 + E2: arpegio de chip (off, 12-60 Hz)
--   E3: ajusta fader             K3 + E3: tipo de acorde
--   faders: ataque, decay, duty, PWM, sweep, vibrato, ruido, fatness,
--           cutoff, resonancia, bits, sample rate
--   K2: tap = arpegiador on/off
--   K2 + E1: gate del arpegio (al máximo = legato real)
--   K2 + E2: patrón              K2 + E3: velocidad
--   K3 mantenido (sin girar nada): modo acorde on/off (off = una sola nota)
--   K1 mantenido: retener on/off (puntito arriba)
--   clock MIDI entrante: marca el tempo del arpegio y del eco

engine.name = 'ChordexCHIP'

local musicutil = require 'musicutil'

local midi_in
local current_note = nil
local current_vel = 0.8
local last_note = nil
local held_stack = {}
-- teclas que arpegia el modo simple (quedan con HOLD hasta la próxima tecla)
local arp_keys = {}
local function update_arp_keys()
  if #held_stack == 0 then return end
  arp_keys = {}
  for i, n in ipairs(held_stack) do arp_keys[i] = n end
  table.sort(arp_keys)
end
-- modo simple: qué teclas están sonando, para no redisparar si no cambió nada
local voiced_sig = nil
local function keys_sig() return table.concat(arp_keys, ",") end
local last_midi_clock = nil
local CLOCK_TIMEOUT = 0.5
local tick_sec = nil
local ext_ticks = 0
local hold_on = false
local loading = false

local chord_types = {"maj", "min", "dim", "aug", "7", "maj7", "min7", "m7b5", "sus2", "sus4"}
local chord_suffix = {maj = "", min = "m", dim = "dim", aug = "+", ["7"] = "7",
  maj7 = "maj7", min7 = "m7", m7b5 = "m7b5", sus2 = "sus2", sus4 = "sus4"}
local chord_intervals = {
  maj = {0, 4, 7}, min = {0, 3, 7}, dim = {0, 3, 6}, aug = {0, 4, 8},
  ["7"] = {0, 4, 7, 10}, maj7 = {0, 4, 7, 11}, min7 = {0, 3, 7, 10},
  m7b5 = {0, 3, 6, 10}, sus2 = {0, 2, 7}, sus4 = {0, 5, 7},
}
local note_names = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
local arp_pattern_names = {"up", "down", "up-down", "up x2", "down x2", "random", "arpa"}
local arp_rate_mult = {4, 2, 1, 0.5}
local arp_rate_names = {"x1/4", "x1/2", "x1", "x2"}
local carp_names = {"off", "12Hz", "15Hz", "20Hz", "25Hz", "30Hz", "50Hz", "60Hz"}
local carp_hz = {0, 12, 15, 20, 25, 30, 50, 60}
local strum_div_names = {"1/64", "1/32", "1/16T", "1/16", "1/8T", "1/8", "1/4"}
local strum_div_beats = {1 / 16, 1 / 8, 1 / 6, 1 / 4, 1 / 3, 1 / 2, 1}
local function strum_text(v)
  if v == 0 then return "OFF" end
  return (v > 0 and "+" or "-") .. strum_div_names[math.abs(v)]
end

-- ============================================================
-- tablas de onda (las mismas cadenas que el engine; tools/tablas.py)
-- ============================================================

local TAB = {}
do
  local defs = {
    {"SQ", 1, "10"},
    {"TRI", 4, "FEDCBA98765432100123456789ABCDEF"},
    {"SAW", 5, "0123456789ABCDEFGHIJKLMNOPQRSTUV"},
    {"GBA", 4, "89BDEFFFFEDDCB988764322100001246"},
    {"GBB", 4, "0246789ABCDEEFFFFFFEEDC000000000"},
    {"GBC", 4, "8CEFEDCCBA889ABA8545677543321013"},
    {"GBD", 4, "FFFF0000F0F0A5A5FFFF000088884444"},
    {"PCA", 5, "GQTTVVRPSVRLIGCAFLJFDA4036400225"},
    {"PCB", 5, "GVVSSOMLKLLKKJHHGEECBBAABA973300"},
    {"PCC", 5, "GPMLKIMKHRVPKEDJGCIHB604EB9DBA96"},
    {"AMA", 8, "80CAEFF8FCFFFCF9F7F3EEEBE6E1DDD8D2CDC9C3BEBAB4AEAAA59F9A958F8A85807A75706A65605A55514B45413C36322D27221E1914110C0806030003071035"},
    {"AMB", 8, "80D7FFEAB17A5D5D686F6F70788591969289817C7B7D7F808181818180808080807F7F7F7F7E7E7E7E7F808284837E766D696E7A878F909097A2A2854E150028"},
    {"AMC", 8, "80A9CEE9F9FFFFFCF9F6F3EEE7DDD2C8C2BFC1C4C7C9CACACCD0D6DAD9D0BDA1805E422F2625292F33353536383B3E403D372D2218110C090603000006163156"},
    {"AMD", 8, "80DEFFF5EEEFDFC7B8B0A59FA2A5A3A2A3A09A9A9C9D9DA2A39F9B9891898584807B7A766E6764605C5D62626365655F5C5D5C5A5D605A4F47382010110A0021"},
    {"P4", 1, "100010011010111"},
    {"P5", 1, "1000010010110011111000110111010"},
    {"N93", 1, "100000010000011000010100011110010001011001110101001111101000011100010010011011010110111101100"},
    {"BUZ", 4, "FEDCBA9876543210"},
    {"STRI", 8, "0008101820283038404850586068707880878F979FA7AFB7BFC7CFD7DFE7EFF7FFF7EFE7DFD7CFC7BFB7AFA79F978F8780787068605850484038302820181008"},
    {"SAT", 8, "000000000010001000002020001020300004080C1044584C6004082C3044586C8084888C9084988C20240A0E32261A0E00C0C0C0C09080908060604040302010"},
    {"OSIN", 8, "808C98A5B0BCC6D0DAE2EAF0F5FAFDFEFFFEFDFAF5F0EAE2DAD0C6BCB0A5988C8073675A4F43392F251D150F0A050201000102050A0F151D252F39434F5A6773"},
    {"OHALF", 8, "0019324A62788EA2B4C5D4E1ECF4FAFEFFFEFAF4ECE1D4C5B4A28E78624A32190000000000000000000000000000000000000000000000000000000000000000"},
    {"OABS", 8, "0019324A62788EA2B4C5D4E1ECF4FAFEFFFEFAF4ECE1D4C5B4A28E78624A32190019324A62788EA2B4C5D4E1ECF4FAFEFFFEFAF4ECE1D4C5B4A28E78624A3219"},
    {"OQUAR", 8, "0019324A62788EA2B4C5D4E1ECF4FAFE000000000000000000000000000000000019324A62788EA2B4C5D4E1ECF4FAFE00000000000000000000000000000000"},
  }
  local d32 = "0123456789ABCDEFGHIJKLMNOPQRSTUV"
  TAB.index = {}   -- nombre -> índice del engine (0..23)
  TAB.data = {}    -- nombre -> muestras -1..1 (sin continua, pico 1)
  for i, d in ipairs(defs) do
    local name, bits, s = d[1], d[2], d[3]
    local m, vals = 2 ^ bits - 1, {}
    if bits <= 5 then
      for k = 1, #s do vals[k] = d32:find(s:sub(k, k), 1, true) - 1 end
    else
      for k = 1, #s / 2 do vals[k] = tonumber(s:sub(k * 2 - 1, k * 2), 16) end
    end
    local mean, pk = 0, 1e-6
    for k = 1, #vals do vals[k] = vals[k] / m * 2 - 1; mean = mean + vals[k] end
    mean = mean / #vals
    for k = 1, #vals do vals[k] = vals[k] - mean; pk = math.max(pk, math.abs(vals[k])) end
    for k = 1, #vals do vals[k] = vals[k] / pk end
    TAB.index[name] = i - 1
    TAB.data[name] = vals
  end
end

-- ============================================================
-- bancos y presets (inspirados en cada chip, sin afiliación)
-- ============================================================
-- w onda, a ataque, r decay, s sustain, d duty, p pwm, sw sweep, st tiempo
-- del sweep, v vibrato, nz ruido, f fatness, o octava, bs bajo, c cutoff,
-- q reso, bt bits, sr sample rate, ca arpegio de chip (1 = off), e eco,
-- h hall; en OPL: m onda moduladora, ra ratio (d = índice FM, nz = caída)

local DEF = {w = "SQ", a = 0.005, r = 0.4, s = 0.7, d = 0.25, p = 0, sw = 0, st = 0.12,
  v = 0.15, nz = 0, f = 0, o = 0, bs = 0.7, c = 1, q = 0, bt = 16, sr = 1, ca = 1,
  e = 0, h = 0.12, m = "OSIN", ra = 1}

local BANKS = {
  {name = "NES", bass = "TRI", quant = 1, presets = {
    {n = "HERO LEAD",  d = 0.25, s = 0.75, v = 0.35, e = 0.2},
    {n = "THIN 12%",   d = 0.125, s = 0.6, v = 0.2, e = 0.35},
    {n = "HOLLOW 50%", d = 0.5, s = 0.7, f = 0.35},
    {n = "1UP ARP",    d = 0.25, s = 0.8, ca = 8, v = 0},
    {n = "TRI BASS",   w = "TRI", o = -1, s = 0.9, r = 0.3, bs = 0, v = 0},
    {n = "COIN",       d = 0.5, a = 0, r = 0.5, s = 0, sw = -0.14, st = 0.07, v = 0, bs = 0, o = 1},
    {n = "TRI KICK",   w = "TRI", a = 0, r = 0.22, s = 0, sw = 0.85, st = 0.09, v = 0, bs = 0, o = -1},
    {n = "NOISE SNARE", nz = 1, a = 0, r = 0.2, s = 0, sw = 0.3, st = 0.05, v = 0, bs = 0, o = 1},
  }},
  {name = "GB", bass = "GBA", quant = 1, presets = {
    {n = "WAVE SOFT",  w = "GBA", s = 0.8, v = 0.25},
    {n = "WAVE GROWL", w = "GBC", o = -1, s = 0.8, v = 0.1},
    {n = "POCKET 12%", d = 0.125, r = 0.5, s = 0.5, e = 0.35},
    {n = "GB PIANO",   w = "GBB", a = 0, r = 0.9, s = 0, v = 0},
    {n = "GB BELL",    w = "GBD", a = 0, r = 1.4, s = 0, e = 0.3, h = 0.3, v = 0},
    {n = "WAVE ARP",   w = "GBA", ca = 6, s = 0.8, v = 0},
    {n = "WAVE WAH",   w = "GBC", c = 0.45, q = 0.6, p = 0.5, s = 0.8},
    {n = "GB HAT",     nz = 1, o = 2, a = 0, r = 0.07, s = 0, bs = 0, v = 0},
  }},
  {name = "C64", bass = "SQ", quant = 0, presets = {
    {n = "SID PWM",    d = 0.35, p = 0.55, s = 0.8, f = 0.2},
    {n = "SID ACID",   w = "SAW", o = -1, c = 0.35, q = 0.75, r = 0.3, s = 0.3, bs = 0.4, v = 0},
    {n = "SAW&TRI",    w = "SAT", s = 0.8, v = 0.3},
    {n = "SID LEAD",   w = "SAW", v = 0.45, c = 0.7, q = 0.3, e = 0.3},
    {n = "SID FLUTE",  w = "STRI", a = 0.04, s = 0.8, v = 0.4},
    {n = "SID ARP",    d = 0.4, p = 0.3, ca = 7, s = 0.8, v = 0},
    {n = "SID RESO",   w = "SAW", c = 0.3, q = 0.85, s = 0.7, p = 0},
    {n = "SID LASER",  d = 0.5, a = 0, sw = 0.8, st = 0.25, s = 0, r = 0.3, v = 0, bs = 0},
  }},
  {name = "ATARI", bass = "P5", quant = 1, presets = {
    {n = "BUZZ 4",     w = "P4", s = 0.8, v = 0},
    {n = "BUZZ 5",     w = "P5", s = 0.8, v = 0},
    {n = "ENGINE",     w = "P4", o = -1, v = 0.6, s = 0.9},
    {n = "PURE TONE",  d = 0.5, bt = 6, sr = 0.55, s = 0.8},
    {n = "EXPLOSION",  w = "N93", nz = 0.7, sw = 0.5, st = 0.6, a = 0, r = 1.2, s = 0, o = -1, bs = 0, v = 0},
    {n = "ALARM",      d = 0.5, v = 1, s = 0.9},
    {n = "BUZZ BASS",  w = "P5", o = -2, bs = 0, s = 0.9, v = 0},
    {n = "METAL",      w = "N93", s = 0.6, r = 0.6, v = 0},
  }},
  {name = "MSX", bass = "BUZ", quant = 1, presets = {
    {n = "AY SQUARE",  d = 0.5, s = 0.8, e = 0.3},
    {n = "AY BUZZER",  w = "BUZ", o = -1, s = 1, v = 0},
    {n = "TONE+NOISE", d = 0.5, nz = 0.3, s = 0.7},
    {n = "ECHO LEAD",  d = 0.5, v = 0.3, e = 0.5},
    {n = "AY ARP",     d = 0.5, ca = 7, s = 0.8, v = 0},
    {n = "AY BELL",    w = "TRI", a = 0, r = 1, s = 0, e = 0.4, v = 0},
    {n = "AY KICK",    d = 0.5, a = 0, sw = 0.8, st = 0.07, o = -1, r = 0.15, s = 0, bs = 0, v = 0},
    {n = "BUZZ LEAD",  w = "BUZ", v = 0.3, c = 0.7, s = 0.8},
  }},
  {name = "PCE", bass = "PCB", quant = 1, presets = {
    {n = "PCE ORGAN",  w = "PCA", s = 0.9, v = 0.1},
    {n = "PCE BRASS",  w = "PCB", a = 0.03, s = 0.8, v = 0.3},
    {n = "PCE BELL",   w = "PCC", a = 0, r = 1.6, s = 0, e = 0.3, h = 0.35, v = 0},
    {n = "PCE STRINGS", w = "PCB", a = 0.25, r = 1, f = 0.6, h = 0.4, s = 0.85},
    {n = "PCE ARP",    w = "PCA", ca = 6, s = 0.8, v = 0},
    {n = "PCE BASS",   w = "PCB", o = -1, c = 0.5, bs = 0, s = 0.8, v = 0},
    {n = "PCE CHOIR",  w = "PCA", d = 0.3, p = 0.4, a = 0.15, s = 0.85, h = 0.3},
    {n = "PCE PLUCK",  w = "PCC", a = 0, r = 0.25, s = 0, v = 0, e = 0.25},
  }},
  {name = "AMIGA", bass = "AMC", quant = 0, presets = {
    {n = "MOD STRINGS", w = "AMA", a = 0.3, r = 1.2, s = 0.9, f = 0.6, h = 0.4, bt = 8, sr = 0.8},
    {n = "MOD CHOIR",  w = "AMB", a = 0.4, r = 1.5, s = 0.9, h = 0.45, bt = 8, sr = 0.8},
    {n = "MOD EPIANO", w = "AMC", a = 0, r = 1.2, s = 0.2, bt = 8, sr = 0.8, v = 0.1},
    {n = "MOD BRASS",  w = "AMD", a = 0.06, s = 0.8, bt = 8, sr = 0.8},
    {n = "MOD BASS",   w = "AMC", o = -1, r = 0.4, s = 0.3, bs = 0, bt = 8, sr = 0.8, v = 0},
    {n = "MOD PAD",    w = "AMA", d = 0.3, p = 0.4, a = 0.8, r = 2, s = 0.9, h = 0.45, bt = 8, sr = 0.8},
    {n = "MOD ARP",    w = "AMD", ca = 7, s = 0.8, bt = 8, sr = 0.8, v = 0},
    {n = "MOD LOFI",   w = "AMA", bt = 5, sr = 0.3, s = 0.8},
  }},
  {name = "OPL", bass = "OSIN", quant = 0, fm = true, presets = {
    {n = "FM PIANO",   w = "OSIN", m = "OSIN", ra = 1, d = 0.5, nz = 0.8, a = 0, r = 1, s = 0.2, v = 0},
    {n = "FM BRASS",   w = "OSIN", m = "OSIN", ra = 1, d = 0.6, a = 0.05, s = 0.8},
    {n = "FM ORGAN",   w = "OHALF", m = "OSIN", ra = 2, d = 0.3, s = 1, v = 0.1},
    {n = "FM BELL",    w = "OSIN", m = "OSIN", ra = 3.5, d = 0.7, nz = 0.9, a = 0, r = 1.8, s = 0, h = 0.3, v = 0},
    {n = "FM BASS",    w = "OSIN", m = "OABS", ra = 1, d = 0.7, o = -1, nz = 0.6, s = 0.5, bs = 0, v = 0},
    {n = "FM CLAV",    w = "OQUAR", m = "OSIN", ra = 2, d = 0.5, a = 0, r = 0.3, s = 0, v = 0},
    {n = "FM LEAD",    w = "OHALF", m = "OHALF", ra = 1, d = 0.5, v = 0.4},
    {n = "FM GUITAR",  w = "OABS", m = "OSIN", ra = 3, d = 0.45, nz = 0.7, a = 0, r = 0.8, s = 0.1, v = 0},
  }},
}
local bank_names = {}
for i, b in ipairs(BANKS) do
  bank_names[i] = b.name
  for j, p in ipairs(b.presets) do
    for k, v in pairs(DEF) do if p[k] == nil then p[k] = v end end
  end
end

-- faders (E2 elige, E3 ajusta)
local P = {
  {id = "atk",    lb = "ATK",  min = 0.001, max = 2,    step = 0.01},
  {id = "rel",    lb = "DEC",  min = 0.02,  max = 4,    step = 0.03},
  {id = "duty",   lb = "DUTY", min = 0.04,  max = 0.96, step = 0.01},
  {id = "pwm",    lb = "PWM",  min = 0,     max = 1,    step = 0.02},
  {id = "sweep",  lb = "SWP",  min = -1,    max = 1,    step = 0.02},
  {id = "vib",    lb = "VIB",  min = 0,     max = 1,    step = 0.02},
  {id = "noise",  lb = "NOIS", min = 0,     max = 1,    step = 0.02},
  {id = "fat",    lb = "FAT",  min = 0,     max = 1,    step = 0.02},
  {id = "cutoff", lb = "CUT",  min = 0,     max = 1,    step = 0.01},
  {id = "reso",   lb = "RES",  min = 0,     max = 1,    step = 0.02},
  {id = "bits",   lb = "BITS", min = 2,     max = 16,   step = 1},
  {id = "srate",  lb = "RATE", min = 0,     max = 1,    step = 0.02},
}
local focus_index = 3

local arp_on = false
local arp_clock_id = nil
local arp_step_lit = 0
local k2_held, k2_turned, k3_held = false, false, false
local k3_turned = false
local k3_press = nil
local K3_LONG = 0.5   -- segundos manteniendo K3 para alternar el modo acorde

-- animación
local PULSE = 24
local pulse = {}          -- pulso por nombre de control
local flash = 0
local chord_flash = 0
local bank_flash = 0
local carp_flash = 0
local hold_flash = 0
local strum_ui = false    -- panel de strum abierto (K2+K3)
local strum_t = 0         -- último movimiento en el panel
local STRUM_CLOSE = 3     -- segundos sin tocar E3 para cerrarlo
local strum_gen = 0
local last_t = nil

-- voces "simuladas" para que la pantalla respire igual que el sonido
local VS = {chord = nil, arp = nil}

local function pv(id) return params:get(id) end
local function bump(name) pulse[name] = PULSE end
local function cur_bank() return BANKS[pv("bank")] end
local function cur_preset() return cur_bank().presets[pv("preset")] end
local function shift(n) return n + 12 * pv("oct") end
local function note_to_hz(n) return musicutil.note_num_to_freq(n) end

local function four_tone_intervals(name)
  -- modo acorde apagado: suena solo la nota tocada
  if params:get("chord_on") == 1 then return {0} end
  local iv = chord_intervals[name]
  if #iv >= 4 then return iv end
  return {iv[1], iv[2], iv[3], iv[1] + 12}
end

local function chord_name() return chord_types[pv("chord")] end

-- ============================================================
-- tracker (lo que se ve a la izquierda)
-- ============================================================

local TR = {rows = {}, count = 0, acc = 0, run = 0, live = {}}  -- live[col] = nota que suena
local TR_VIS, TR_CUR = 7, 5     -- filas visibles, fila de la línea de play
for i = 1, TR_VIS do TR.rows[i] = {c = {}} end

local function tr_name(n)
  local pc = n % 12
  local nm = note_names[pc + 1]
  if #nm == 1 then nm = nm .. "-" end
  return nm .. math.max(0, math.floor(n / 12) - 1)
end

-- la fila de la línea de play (las de arriba ya pasaron)
local function tr_row() return TR.rows[TR_CUR] end

local function tr_scroll()
  table.remove(TR.rows, 1)
  TR.rows[TR_VIS] = {c = {}}
  TR.count = TR.count + 1
  for col = 1, 4 do
    if TR.live[col] then TR.rows[TR_CUR].c[col] = TR.rows[TR_CUR].c[col] or "|" end
  end
end

local function tr_note(col, n, fx)
  local r = tr_row()
  r.c[col] = tr_name(n)
  if fx then r.fx = fx end
  if TR.live[col] then TR.live[col] = r.c[col] end
  r.hit = PULSE
  TR.run = 16
end

local function tr_off()
  local r = tr_row()
  for col = 1, 4 do
    if TR.live[col] then r.c[col] = "==="; TR.live[col] = nil end
  end
  TR.run = 10
end

local function tr_tick(dt, step)
  if TR.run <= 0 and current_note == nil then return end
  TR.acc = TR.acc + dt
  local guard = 0
  while TR.acc >= step and guard < 4 do
    TR.acc = TR.acc - step
    guard = guard + 1
    tr_scroll()
    if current_note == nil then TR.run = TR.run - 1 end
  end
  if guard >= 4 then TR.acc = 0 end
end

-- ============================================================
-- sonido
-- ============================================================

local function chord_tone_notes(note)
  local t = {}
  for _, iv in ipairs(four_tone_intervals(chord_name())) do t[#t + 1] = shift(note + iv) end
  -- modo simple con varias teclas: suenan todas juntas (hasta 4, las más agudas)
  if pv("chord_on") == 1 and #arp_keys > 1 then
    t = {}
    for i = math.max(1, #arp_keys - 3), #arp_keys do t[#t + 1] = shift(arp_keys[i]) end
  end
  return t
end

-- forward: definidas más abajo (dependen del reloj MIDI)
local strum_step

-- strum: n notas del acorde repetido hacia arriba por octavas;
-- positivo = de grave a agudo, negativo = de agudo a grave
local function strum_notes(t, n)
  -- solo las notas del acorde: + de la primera a la última, - al revés
  local out = {}
  if n > 0 then
    for i = 1, #t do out[i] = t[i] end
  else
    for i = #t, 1, -1 do out[#out + 1] = t[i] end
  end
  return out
end

local function sound_strum(note, t)
  local sn = strum_notes(t, pv("strum"))
  local n = #sn
  local step = strum_step()
  voiced_sig = keys_sig()
  engine.strumOn(note_to_hz(note - 24), current_vel)
  for i, m in ipairs(sn) do
    local pan = n > 1 and ((i - 1) / (n - 1) * 2 - 1) * 0.7 or 0
    if pv("strum") < 0 then pan = -pan end   -- cada nota queda en su lugar del panorama
    engine.strumNote(note_to_hz(m), (i - 1) * step, n, pan)
  end
  VS.chord = {t0 = util.time(), note = sn[1], vel = current_vel}
  -- tracker: las notas van cayendo a su tiempo, rotando por las 4 columnas
  for col = 1, 4 do TR.live[col] = nil end
  TR.fx = nil
  strum_gen = strum_gen + 1
  local g = strum_gen
  clock.run(function()
    for i, m in ipairs(sn) do
      if strum_gen ~= g or current_note == nil then return end
      local col = pv("strum") > 0 and i or (n - i + 1)   -- cada nota en su columna
      TR.live[col] = true
      tr_note(col, m)
      if i < n then clock.sleep(step) end
    end
  end)
  flash = 1
end

local function sound_chord(note)
  local t = chord_tone_notes(note)
  if pv("strum") ~= 0 then return sound_strum(note, t) end
  local f = {}
  for i = 1, 4 do f[i] = t[i] and note_to_hz(t[i]) or 0 end
  voiced_sig = keys_sig()
  engine.noteOn(f[1], f[2], f[3], f[4], note_to_hz(note - 24), current_vel)
  VS.chord = {t0 = util.time(), note = t[1], vel = current_vel}
  -- tracker: una columna por voz, o una sola con el efecto 0xy del arpegio de chip
  for col = 1, 4 do TR.live[col] = nil end
  TR.fx = nil
  if pv("carp") > 1 and #t > 1 then
    local fx = "0"
    for i = 2, math.min(3, #t) do fx = fx .. string.format("%X", (t[i] - t[1]) % 16) end
    TR.live[1] = true
    TR.fx = fx
    tr_note(1, t[1], fx)
  else
    for i, n in ipairs(t) do TR.live[i] = true; tr_note(i, n) end
  end
  flash = 1
end

local function release_chord_vs()
  if VS.chord and not VS.chord.t1 then VS.chord.t1 = util.time() end
end

local function step_order(pat, n)
  local t = {}
  if pat == 1 or pat == 7 then for i = 1, n do t[#t + 1] = i end
  elseif pat == 2 then for i = n, 1, -1 do t[#t + 1] = i end
  elseif pat == 3 then
    for i = 1, n do t[#t + 1] = i end
    for i = n - 1, 2, -1 do t[#t + 1] = i end
  elseif pat == 4 then for i = 1, n do t[#t + 1] = i; t[#t + 1] = i end
  elseif pat == 5 then for i = n, 1, -1 do t[#t + 1] = i; t[#t + 1] = i end
  end
  return t
end

-- notas del arpegio (en número MIDI); "arpa" recorre dos octavas
local function arp_notes()
  local t = {}
  for _, iv in ipairs(four_tone_intervals(chord_name())) do t[#t + 1] = current_note + iv end
  if pv("chord_on") == 1 and #arp_keys > 0 then
    t = {}
    for i, n in ipairs(arp_keys) do t[i] = n end
  end
  if pv("arp_pattern") == 7 then
    local n = #t
    for i = 1, n do t[#t + 1] = t[i] + 12 end
  end
  for i = 1, #t do t[i] = shift(t[i]) end
  return t
end

local function ext_clock_on()
  return last_midi_clock ~= nil and (util.time() - last_midi_clock) < CLOCK_TIMEOUT
end

local function ticks_per_step()
  local div = ({1, 2, 4, 8})[params:get("midi_clock_div")]
  return math.max(1, 24 * (1 / 16) * div * arp_rate_mult[pv("arp_rate")])
end

local function step_seconds()
  if ext_clock_on() and tick_sec then return tick_sec * ticks_per_step() end
  return clock.get_beat_sec() * (1 / 16) * arp_rate_mult[pv("arp_rate")]
end

local function beat_seconds()
  if ext_clock_on() and tick_sec then return tick_sec * 24 end
  return clock.get_beat_sec()
end

-- múltiplos del pulso: del reloj MIDI si entra, si no del tempo de la norns
strum_step = function()
  local v = math.abs(pv("strum"))
  if v == 0 then return 0 end
  return beat_seconds() * strum_div_beats[v]
end

local function arp_note_dur(step_sec)
  local g = params:get("arp_gate")
  return util.clamp(step_sec * 0.25 * (32 ^ g), 0.03, 4)
end

local step_i = 1
local function arp_step()
  if current_note == nil then return end
  local notes = arp_notes()
  local pat = pv("arp_pattern")
  local idx, pos
  if pat == 6 then
    idx = math.random(1, #notes); pos = 1
  else
    local order = step_order(pat, #notes)
    pos = ((step_i - 1) % #order) + 1
    idx = order[pos]
  end
  step_i = step_i + 1
  local step_sec = step_seconds()
  local n = notes[idx]
  local vel = (pos == 1 and 1 or 0.72) * (0.55 + current_vel * 0.45)
  local pan = ((idx - 1) % 4 - 1.5) * 0.22
  local dur = arp_note_dur(step_sec)
  if params:get("arp_gate") >= 0.995 then
    engine.arpLegato(note_to_hz(n), vel, pan)
    if not (VS.arp and VS.arp.legato and not VS.arp.t1) then
      VS.arp = {t0 = util.time(), note = n, vel = vel, legato = true}
    else
      VS.arp.note = n; VS.arp.vel = vel
    end
  else
    engine.arpLegatoOff()
    engine.arpStep(note_to_hz(n), dur, vel, pan)
    VS.arp = {t0 = util.time(), note = n, vel = vel, pluck = true, dur = dur}
  end
  arp_step_lit = idx
  tr_note(((idx - 1) % 4) + 1, n)
  flash = math.max(flash, 0.35 * vel)
end

local function arp_legato_off()
  engine.arpLegatoOff()
  if VS.arp and VS.arp.legato and not VS.arp.t1 then VS.arp.t1 = util.time() end
end

-- el loop termina solo (generación) en vez de clock.cancel: cancelar un
-- coroutine que ya estaba por despertarse tira "resume (thread expected)"
local arp_gen = 0
local function arp_loop(gen)
  while arp_on and current_note and gen == arp_gen do
    if ext_clock_on() then
      clock.sleep(0.05)
    else
      local quantum = (1 / 16) * arp_rate_mult[pv("arp_rate")]
      if params:get("clock_source") == 1 then clock.sync(quantum)
      else clock.sleep(clock.get_beat_sec() * quantum) end
      if arp_on and current_note and gen == arp_gen and not ext_clock_on() then arp_step() end
    end
  end
  if gen == arp_gen then
    arp_step_lit = 0
    arp_legato_off()
    arp_clock_id = nil
  end
end

local function start_arp_if_needed()
  if arp_clock_id == nil and current_note then
    engine.padOn(note_to_hz(current_note - 24))
    step_i = 1
    ext_ticks = 0
    arp_step()
    arp_gen = arp_gen + 1
    arp_clock_id = clock.run(arp_loop, arp_gen)
  end
end

local function stop_arp()
  if arp_clock_id ~= nil then
    arp_gen = arp_gen + 1
    arp_clock_id = nil
  end
  arp_step_lit = 0
  engine.padOff()
  arp_legato_off()
end

local crackle_amt = 0
local function update_crackle()
  crackle_amt = util.clamp((#held_stack - 2) * 0.35, 0, 1)
  engine.crackle(crackle_amt)
end

-- con clock MIDI, algunos equipos repiten la nota apretada a tempo: el
-- soltar espera un poco y si vuelve la misma nota no se redispara
local release_id = nil

local function cancel_release()
  if release_id then clock.cancel(release_id); release_id = nil end
end

local function release_now()
  release_id = nil
  if #held_stack == 0 and not hold_on and current_note ~= nil then
    if arp_on then stop_arp() else engine.noteOff(); release_chord_vs() end
    current_note = nil
    tr_off()
  end
end

local function release_grace()
  return util.clamp((tick_sec or 0.02) * 13, 0.05, 0.8)
end

local function on_note_on(note, vel)
  cancel_release()
  local prev = current_note
  local fresh = hold_on and #held_stack == 0 and prev ~= nil
  local added = hold_on and #held_stack > 0
  table.insert(held_stack, note)
  if added then
    -- con HOLD, una tecla más mientras hay otras apretadas se suma a lo
    -- retenido (aunque alguna ya se haya soltado)
    local dup = false
    for _, n in ipairs(arp_keys) do if n == note then dup = true end end
    if not dup then table.insert(arp_keys, note); table.sort(arp_keys) end
  else
    update_arp_keys()
  end
  -- modo acorde: manda la última tecla apretada (también si es más aguda);
  -- modo simple: suenan todas las apretadas y la más grave da el bajo
  local simple = pv("chord_on") == 1
  local low = simple and arp_keys[1] or note
  if low ~= prev or fresh or (simple and not arp_on and keys_sig() ~= voiced_sig) then
    current_note = low
    last_note = low
    current_vel = vel / 127
    if arp_on then
      if arp_clock_id == nil then start_arp_if_needed()
      else engine.padOn(note_to_hz(current_note - 24)) end
    else
      sound_chord(current_note)
    end
  end
  update_crackle()
end

local function on_note_off(note)
  for i = #held_stack, 1, -1 do
    if held_stack[i] == note then table.remove(held_stack, i); break end
  end
  -- con HOLD, soltar teclas no cambia nada: queda el acorde / las notas
  -- del arpegio tal como se apretaron
  if hold_on then update_crackle(); return end
  update_arp_keys()
  -- modo acorde: al soltar la que suena vuelve la última que sigue apretada;
  -- modo simple: soltar una de varias no redispara (cambia con la próxima tecla)
  local low = held_stack[#held_stack]
  if pv("chord_on") == 1 then low = (low ~= nil) and current_note or nil end
  if low == nil then
    if not hold_on and current_note ~= nil then
      if ext_clock_on() then
        cancel_release()
        local wait = release_grace()
        release_id = clock.run(function() clock.sleep(wait); release_now() end)
      else
        release_now()
      end
    end
  elseif low ~= current_note then
    current_note = low
    last_note = low
    if arp_on then engine.padOn(note_to_hz(current_note - 24))
    else sound_chord(current_note) end
  end
  update_crackle()
end

local function set_hold(on)
  hold_on = on
  hold_flash = PULSE
  if not on then cancel_release(); release_now() end
end

-- teclas soltadas con clock corriendo que esperan por si el equipo las repite
local repeat_off = {}
local function midi_event(data)
  local msg = midi.to_msg(data)
  if msg.type == "clock" then
    local now = util.time()
    if last_midi_clock then
      local d = now - last_midi_clock
      if d > 0.002 and d < 0.25 then
        tick_sec = tick_sec and (tick_sec * 0.9 + d * 0.1) or d
      end
    end
    last_midi_clock = now
    if arp_on and arp_clock_id and current_note then
      local tps = ticks_per_step()
      ext_ticks = ext_ticks + 1
      if ext_ticks >= tps then
        ext_ticks = math.min(ext_ticks - tps, tps - 1)
        arp_step()
      end
    end
    return
  elseif msg.type == "start" then
    ext_ticks = 0
    step_i = 1
    return
  elseif msg.type == "stop" or msg.type == "continue" then
    return
  end
  local ch = params:get("midi_channel")
  if ch ~= 0 and msg.ch ~= ch then return end
  if msg.type == "note_on" and msg.vel > 0 then
    -- con clock MIDI el equipo repite las teclas apretadas a cada pulso:
    -- si la tecla se soltó hace poco, sigue apretada y no se redispara
    if repeat_off[msg.note] then repeat_off[msg.note] = nil; return end
    on_note_on(msg.note, msg.vel)
  elseif msg.type == "note_off" or (msg.type == "note_on" and msg.vel == 0) then
    if ext_clock_on() then
      local note = msg.note
      local tok = {}
      repeat_off[note] = tok
      local wait = util.clamp((tick_sec or 0.02) * 30, 0.05, 1)
      clock.run(function()
        clock.sleep(wait)
        if repeat_off[note] == tok then repeat_off[note] = nil; on_note_off(note) end
      end)
    else
      on_note_off(msg.note)
    end
  end
end

-- ============================================================
-- parámetros (se guardan solos en data/chordexchip/estado.pset)
-- ============================================================

local STATE_FILE

local function send_wave()
  local b, p = cur_bank(), cur_preset()
  engine.wave(TAB.index[p.w], TAB.index[b.bass], b.quant, b.fm and 1 or 0, TAB.index[p.m], p.ra)
end

-- un preset carga todo el sonido (no toca acorde, arpegio ni volumen)
local function load_preset()
  local p = cur_preset()
  send_wave()
  params:set("atk", p.a); params:set("rel", p.r); params:set("sus", p.s)
  params:set("duty", p.d); params:set("pwm", p.p)
  params:set("sweep", p.sw); params:set("swt", p.st); params:set("vib", p.v)
  params:set("noise", p.nz); params:set("fat", p.f); params:set("oct", p.o)
  params:set("bass", p.bs); params:set("cutoff", p.c); params:set("reso", p.q)
  params:set("bits", p.bt); params:set("srate", p.sr); params:set("carp", p.ca)
  params:set("eco", p.e); params:set("space", p.h)
  if current_note and not arp_on then sound_chord(current_note) end
end

local function add_params()
  params:add_separator("chordex_chip", "CHORDEX CHIP")
  params:add_number("midi_channel", "canal MIDI (0=todos)", 0, 16, 0)
  params:add_option("midi_clock_div", "divisor reloj MIDI", {"1x", "2x", "4x", "8x"}, 3)
  params:add_option("bank", "banco", bank_names, 1)
  params:set_action("bank", function()
    if not loading then
      if pv("preset") ~= 1 then params:set("preset", 1) else load_preset() end
    end
  end)
  params:add_number("preset", "preset", 1, 8, 1)
  params:set_action("preset", function()
    if loading then send_wave() else load_preset() end
  end)
  params:add_option("chord", "acorde", chord_types, 1)
  params:set_action("chord", function()
    if current_note and not arp_on then sound_chord(current_note) end
  end)
  params:add_option("chord_on", "modo acorde", {"no", "sí"}, 2)
  params:set_action("chord_on", function()
    if current_note and not arp_on and not loading then sound_chord(current_note) end
  end)
  params:add_option("arp_pattern", "patrón arp", arp_pattern_names, 1)
  params:add_option("arp_rate", "velocidad arp", arp_rate_names, 3)
  params:add_control("arp_gate", "gate arp (1=legato)", controlspec.new(0, 1, "lin", 0, 0.6, ""))
  params:add_option("carp", "arpegio de chip", carp_names, 1)
  params:set_action("carp", function(v) engine.carp(carp_hz[v]) end)
  -- strum: división del pulso entre nota y nota; + de la primera nota a la
  -- última, - de la última a la primera, 0 = apagado
  params:add_number("strum", "strum (división, +/- = sentido)", -#strum_div_names, #strum_div_names, 0,
    function(p) return strum_text(p:get()) end)

  params:add_separator("chordex_chip_voz", "VOZ")
  params:add_control("atk", "ataque", controlspec.new(0.001, 2, "lin", 0, 0.005, "s"))
  params:set_action("atk", function(v) engine.atk(v) end)
  params:add_control("rel", "decay", controlspec.new(0.02, 4, "lin", 0, 0.4, "s"))
  params:set_action("rel", function(v) engine.rel(v) end)
  params:add_control("sus", "sustain", controlspec.new(0, 1, "lin", 0, 0.7, ""))
  params:set_action("sus", function(v) engine.sus(v) end)
  params:add_control("duty", "duty", controlspec.new(0.04, 0.96, "lin", 0, 0.25, ""))
  params:set_action("duty", function(v) engine.duty(v) end)
  params:add_control("pwm", "PWM", controlspec.new(0, 1, "lin", 0, 0, ""))
  params:set_action("pwm", function(v) engine.pwm(v) end)
  params:add_control("sweep", "pitch sweep", controlspec.new(-1, 1, "lin", 0, 0, ""))
  params:set_action("sweep", function(v) engine.sweep(v) end)
  params:add_control("swt", "tiempo sweep", controlspec.new(0.01, 1.5, "lin", 0, 0.12, "s"))
  params:set_action("swt", function(v) engine.swt(v) end)
  params:add_control("vib", "vibrato", controlspec.new(0, 1, "lin", 0, 0.15, ""))
  params:set_action("vib", function(v) engine.vib(v) end)
  params:add_control("noise", "ruido", controlspec.new(0, 1, "lin", 0, 0, ""))
  params:set_action("noise", function(v) engine.noise(v) end)
  params:add_control("fat", "fatness", controlspec.new(0, 1, "lin", 0, 0, ""))
  params:set_action("fat", function(v) engine.fat(v) end)
  params:add_number("oct", "octava", -2, 2, 0)
  params:add_control("bass", "bajo", controlspec.new(0, 1, "lin", 0, 0.7, ""))
  params:set_action("bass", function(v) engine.bass(v) end)

  params:add_separator("chordex_chip_fx", "FX")
  params:add_control("cutoff", "cutoff", controlspec.new(0, 1, "lin", 0, 1, ""))
  params:set_action("cutoff", function(v) engine.cutoff(v) end)
  params:add_control("reso", "resonancia", controlspec.new(0, 1, "lin", 0, 0, ""))
  params:set_action("reso", function(v) engine.reso(v) end)
  params:add_number("bits", "bits", 2, 16, 16)
  params:set_action("bits", function(v) engine.bits(v) end)
  params:add_control("srate", "sample rate", controlspec.new(0, 1, "lin", 0, 1, ""))
  params:set_action("srate", function(v) engine.srate(v) end)
  params:add_control("eco", "eco", controlspec.new(0, 1, "lin", 0, 0, ""))
  params:set_action("eco", function(v) engine.eco(v) end)
  params:add_control("space", "hall", controlspec.new(0, 0.6, "lin", 0, 0.12, ""))
  params:set_action("space", function(v) engine.space(v) end)
  params:add_control("gain", "volumen", controlspec.new(0, 1.5, "lin", 0, 1.0, ""))
  params:set_action("gain", function(v) engine.gain(v) end)
end

-- ============================================================
-- init / controles
-- ============================================================

local screen_metro
local splash_start = nil
-- primero la intro U-MA de particulas (la de uma_splash/splash), despues CHORDEX
local SPLASH_IN, SPLASH_HOLD, SPLASH_FADE = 0.5, 1.6, 0.7
local uma_intro = include("lib/uma_splash_particles")
local uma_sound = include("lib/uma_splash") -- base de la intro, maneja el sonido

local function skip_splash()
  if splash_start and util.time() - splash_start < uma_intro.DUR then uma_sound.sound_off() end
  splash_start = nil
end

local eco_sent = 0
local function update_eco_time()
  local t = beat_seconds() * 0.75
  if math.abs(t - eco_sent) > 0.005 then eco_sent = t; engine.ecot(t) end
end

function init()
  midi_in = {}
  for i = 1, #midi.vports do
    midi_in[i] = midi.connect(i)
    midi_in[i].event = midi_event
  end

  add_params()
  STATE_FILE = norns.state.data .. "estado.pset"
  loading = true
  if util.file_exists(STATE_FILE) then params:read(STATE_FILE) end
  params:bang()
  loading = false
  update_eco_time()

  uma_sound.sound_on(norns.state.path .. "lib/uma_particles.wav")
  splash_start = util.time()
  screen_metro = metro.init(function() redraw() end, 1 / 24, -1)
  screen_metro:start()
end

function cleanup()
  if STATE_FILE then params:write(STATE_FILE, "chordexchip") end
end

local function nudge(p, d)
  params:set(p.id, util.clamp(pv(p.id) + d * p.step, p.min, p.max))
end

local function strum_toggle()
  k2_turned = true; k3_turned = true
  strum_ui = not strum_ui
  strum_t = util.time()
end

function enc(n, d)
  if splash_start then return end
  local dir = d > 0 and 1 or -1
  -- panel de strum abierto: E3 = división del pulso (+ / - = sentido)
  if strum_ui and n == 3 then
    strum_t = util.time()
    if k2_held then k2_turned = true end
    if k3_held then k3_turned = true end
    params:set("strum", util.clamp(pv("strum") + dir, -#strum_div_names, #strum_div_names))
    return
  end
  if n == 1 then
    if k2_held then
      params:set("arp_gate", util.clamp(params:get("arp_gate") + d * 0.02, 0, 1))
      k2_turned = true
      bump("arp")
    elseif k3_held then
      k3_turned = true
      params:set("bank", util.clamp(pv("bank") + dir, 1, #BANKS))
      bank_flash = PULSE * 2
    else
      params:set("preset", util.clamp(pv("preset") + dir, 1, 8))
      bump("preset")
    end
  elseif n == 2 then
    if k2_held then
      params:set("arp_pattern", ((pv("arp_pattern") - 1 + dir) % #arp_pattern_names) + 1)
      k2_turned = true
      bump("arp")
    elseif k3_held then
      k3_turned = true
      params:set("carp", util.clamp(pv("carp") + dir, 1, #carp_names))
      carp_flash = PULSE * 2
      if current_note and not arp_on then sound_chord(current_note) end
    else
      focus_index = ((focus_index - 1 + dir) % #P) + 1
      bump(P[focus_index].id)
    end
  elseif n == 3 then
    if k2_held then
      params:set("arp_rate", util.clamp(pv("arp_rate") + dir, 1, #arp_rate_names))
      k2_turned = true
      bump("arp")
    elseif k3_held then
      k3_turned = true
      params:set("chord", util.clamp(pv("chord") + dir, 1, #chord_types))
      chord_flash = PULSE * 2
    else
      nudge(P[focus_index], d)
      bump(P[focus_index].id)
    end
  end
end

function key(n, z)
  -- K1 llega acá solo si se mantiene (el toque corto abre el menú de norns)
  if n == 1 then
    if z == 1 then
      if splash_start then skip_splash() end
      set_hold(not hold_on)
    end
  elseif n == 2 then
    if z == 1 then
      k2_held = true; k2_turned = false
      if k3_held then strum_toggle() end
    else
      if splash_start then skip_splash()
      elseif k2_held and not k2_turned then
        arp_on = not arp_on
        bump("arp")
        if arp_on then
          engine.noteOff(); release_chord_vs()
          for col = 1, 4 do TR.live[col] = nil end
          if current_note then start_arp_if_needed() end
        else
          stop_arp()
          if current_note then sound_chord(current_note) end
        end
      end
      k2_held = false
    end
  elseif n == 3 then
    k3_held = (z == 1)
    if z == 1 and splash_start then skip_splash() end
    if z == 1 then
      -- mantener K3 sin girar ningún encoder alterna el modo acorde
      k3_turned = false
      if k2_held then strum_toggle() end
      local press = util.time()
      k3_press = press
      clock.run(function()
        clock.sleep(K3_LONG)
        if k3_held and not k3_turned and k3_press == press then
          params:set("chord_on", 3 - params:get("chord_on"))
          chord_flash = PULSE * 2
        end
      end)
    end
  end
end

-- ============================================================
-- GRÁFICOS — acumulador por nivel (mismo esquema que Chordex80)
-- ============================================================

local G = {}
do
local bt, b1, b2, b3, b4, bn = {}, {}, {}, {}, {}, {}
for lv = 1, 15 do bt[lv] = {}; b1[lv] = {}; b2[lv] = {}; b3[lv] = {}; b4[lv] = {}; bn[lv] = 0 end

local function add(lv, ty, a, b, c, d)
  lv = math.floor(lv + 0.5)
  if lv < 1 then return end
  if lv > 15 then lv = 15 end
  local n = bn[lv] + 1
  bn[lv] = n
  bt[lv][n] = ty; b1[lv][n] = a; b2[lv][n] = b; b3[lv][n] = c; b4[lv][n] = d
end

function G.px(lv, x, y) add(lv, 0, x, y) end
function G.rect(lv, x, y, w, h) add(lv, 4, x, y, w, h) end

function G.flush()
  local floor = math.floor
  for lv = 1, 15 do
    local n = bn[lv]
    if n > 0 then
      local T, A, B, C, D = bt[lv], b1[lv], b2[lv], b3[lv], b4[lv]
      screen.level(lv)
      for k = 1, n do
        if T[k] == 0 then screen.rect(floor(A[k]), floor(B[k]), 1, 1)
        else screen.rect(floor(A[k]), floor(B[k]), C[k], D[k]) end
      end
      screen.fill()
      bn[lv] = 0
    end
  end
end
end

local lane = include("lib/chip_lane")
lane.init(G)

-- envolvente simulada (la misma ADSR que el engine) para la onda en pantalla
local function env_at(vs, t)
  if not vs then return 0 end
  local a, d, s = pv("atk") + 0.001, pv("rel"), pv("sus")
  local e
  if vs.pluck then
    local el = t - vs.t0
    local g = vs.dur * 0.5
    if el < a then e = el / a
    elseif el < g then e = s + (1 - s) * math.exp(-(el - a) / math.max(0.01, d) * 3)
    else
      local hold = s + (1 - s) * math.exp(-(g - a) / math.max(0.01, d) * 3)
      e = hold * math.max(0, 1 - (el - g) / math.max(0.02, d * 0.5))
    end
  else
    local t1 = vs.t1 or t
    local el = t1 - vs.t0
    if el < a then e = el / a
    else e = s + (1 - s) * math.exp(-(el - a) / math.max(0.01, d) * 3) end
    if vs.t1 then e = e * math.max(0, 1 - (t - vs.t1) / math.max(0.02, d)) end
  end
  return util.clamp(e, 0, 1) * (0.6 + vs.vel * 0.4)
end

-- ---- la onda tal como suena ----
local SC = {X = 77, Y = 23, W = 50, CYC = 25, H = 11, y = {}}
local function wave_value(p, b, ph, dy, idx)
  if b.fm then
    local mt, ct = TAB.data[p.m], TAB.data[p.w]
    local m = mt[math.floor((ph * p.ra % 1) * #mt) + 1]
    local cp = (ph + m * idx) % 1
    return ct[math.floor(cp * #ct) + 1]
  end
  local w = ph < dy and ph * 0.5 / dy or 0.5 + (ph - dy) * 0.5 / (1 - dy)
  local tb = TAB.data[p.w]
  return tb[math.min(#tb, math.floor(w * #tb) + 1)]
end

local function draw_scope(t)
  local b, p = cur_bank(), cur_preset()
  local amp = math.max(env_at(VS.chord, t), env_at(VS.arp, t))
  local live = amp > 0.03
  if not live then amp = 0.35 end
  local pwm = pv("pwm")
  local dy = util.clamp(pv("duty") + math.sin(t * (0.35 + pwm * 2.5) * 2 * math.pi) * pwm * 0.4, 0.04, 0.96)
  local nz = pv("noise")
  local idx = pv("duty") * 2.2 * (1 + math.sin(t * 3) * pwm * 0.5)
  local q = 2 ^ (pv("bits") - 1)
  -- sample rate: cuántos píxeles dura cada muestra (2 ciclos = 50 px)
  local note = (VS.arp and VS.arp.note) or (VS.chord and VS.chord.note) or 57
  local f = note_to_hz(note)
  local hold = 1
  if pv("srate") < 0.99 then hold = math.max(1, SC.CYC * f / (1500 * 2 ^ (pv("srate") * 5))) end
  -- filtro: un polo, aproximado, por píxel
  local fc = 60 * 2 ^ (pv("cutoff") * 8.23)
  local a = 1 - math.exp(-2 * math.pi * fc / (f * SC.CYC))
  local ys, last, held = 0, 0, 0
  for x = -SC.CYC, SC.W - 1 do
    local ph = ((x + 2 * SC.CYC) / SC.CYC) % 1
    local v = wave_value(p, b, ph, dy, idx)
    if nz > 0 then v = v * (1 - nz) + (math.random() < 0.5 and -1 or 1) * nz end
    v = math.floor(v * q + 0.5) / q
    if held <= 0 then last = v; held = held + hold end
    held = held - 1
    ys = ys + a * (last - ys)
    if x >= 0 then SC.y[x + 1] = ys end
  end
  local lv = live and 15 or 5
  local prev
  for x = 1, SC.W do
    local yy = math.floor(SC.Y - util.clamp(SC.y[x] * amp, -1, 1) * SC.H + 0.5)
    local px = SC.X + x - 1
    if prev and prev ~= yy then
      local y0, y1 = math.min(prev, yy), math.max(prev, yy)
      G.rect(lv, px, y0, 1, y1 - y0 + 1)
    else
      G.px(lv, px, yy)
    end
    prev = yy
  end
end

-- ---- tracker ----
local function draw_tracker(t)
  screen.font_face(1)
  screen.font_size(8)
  local cols = {7, 24, 41, 58}
  for i = 1, TR_VIS do
    local r = TR.rows[i]
    local y = 8 + i * 7
    local cur = (i == TR_CUR)
    local rn = (TR.count + i - TR_CUR) % 16   -- filas 0-F, como una frase de LSDJ
    -- número de fila (cada 4 un poco más brillante, como en los trackers)
    screen.level(cur and 15 or (rn % 4 == 0 and 7 or 4))
    screen.move(0, y)
    screen.text(string.format("%X", rn))
    for c = 1, 4 do
      local v = r.c[c]
      if v == "|" and cur then
        screen.level(10)
        screen.move(cols[c], y)
        screen.text(TR.live[c] or "")
      elseif v == "|" then
        G.rect(5, cols[c] + 5, y - 7, 1, 7)
      elseif v then
        local hot = r.hit and r.hit > 0 and cur
        screen.level(hot and 15 or (i <= TR_CUR and (cur and 15 or 8) or 4))
        screen.move(cols[c], y)
        screen.text(v)
      elseif i > TR_CUR or not TR.live[c] then
        G.px(i == TR_CUR and 6 or 3, cols[c] + 5, y - 3)
      end
    end
    local fx = r.fx or (cur and TR.live[1] and TR.fx)
    if fx then
      screen.level(cur and 10 or 5)
      screen.move(cols[2], y)
      screen.text(fx)
    end
    if r.hit then r.hit = math.max(0, r.hit - 1) end
  end
end

-- ---- cabecera ----
-- up, down, up-down, up x2, down x2, random, arpa (altura 0..5 por paso)
local ARP_ICON = {"024024", "420420", "024202", "002244", "442200", "305124", "012345"}

local function draw_header(t)
  screen.font_face(1)
  screen.font_size(8)
  local b, p = cur_bank(), cur_preset()
  screen.level(10)
  screen.move(0, 7)
  screen.text(b.name .. " " .. pv("preset"))
  local ax = 36
  if arp_on then
    screen.level(pulse.arp and pulse.arp > 0 and 15 or 8)
    screen.move(ax, 7)
    screen.text("ARP")
    -- ícono del patrón: 6 pasos, altura = nota; el paso que suena brilla
    local shape = ARP_ICON[pv("arp_pattern")]
    local lit = (step_i - 2) % 6 + 1
    for k = 1, 6 do
      local h = tonumber(shape:sub(k, k))
      G.rect(k == lit and 15 or 7, ax + 15 + (k - 1) * 2, 6 - h, 2, 1)
    end
  end
  if pv("carp") > 1 then
    screen.level(6)
    screen.move(75, 7)
    screen.text_right(tostring(carp_hz[pv("carp")]))
  end
  screen.level((pulse.preset and pulse.preset > 0) and 15 or 12)
  screen.move(77, 7)
  screen.text(p.n)
  if hold_on then G.rect(15, 75, 1, 2, 2) end
end

-- ---- faders ----
local function fader_text(p)
  local v = pv(p.id)
  if p.id == "atk" or p.id == "rel" then
    return v < 1 and string.format("%dms", math.floor(v * 1000 + 0.5)) or string.format("%.1fs", v)
  elseif p.id == "duty" then
    return string.format("%d%%", math.floor(v * 100 + 0.5))
  elseif p.id == "bits" then
    return v >= 16 and "OFF" or tostring(math.floor(v))
  elseif p.id == "srate" then
    if v >= 0.99 then return "OFF" end
    local hz = 1500 * 2 ^ (v * 5)
    return string.format("%.1fk", hz / 1000)
  elseif p.id == "cutoff" then
    local hz = 60 * 2 ^ (v * 8.23)
    return hz >= 1000 and string.format("%.1fk", hz / 1000) or tostring(math.floor(hz))
  elseif p.id == "sweep" then
    return string.format("%+d", math.floor(v * 36 + 0.5))
  end
  return string.format("%02d", math.floor(v * 99 + 0.5))
end

local function draw_faders()
  local p = P[focus_index]
  screen.font_face(1)
  screen.font_size(8)
  screen.level(15)
  screen.move(77, 44)
  screen.text(p.lb)
  screen.level(10)
  screen.move(127, 44)
  screen.text_right(fader_text(p))
  for i, f in ipairs(P) do
    local u = (pv(f.id) - f.min) / (f.max - f.min)
    if f.id == "bits" then u = 1 - u end   -- menos bits = más fader
    if f.id == "srate" then u = 1 - u end
    local h = math.floor(u * 14 + 0.5)
    local x = 77 + math.floor((i - 1) * 4.3)
    local sel = (i == focus_index)
    local pl = pulse[f.id] and pulse[f.id] > 0
    if h > 0 then G.rect(sel and 15 or (pl and 12 or 7), x, 63 - h, 3, h) end
    G.rect(sel and 15 or 4, x, 63, 3, 1)
    if sel then G.px(15, x + 1, 47) end
  end
end

-- ---- carteles ----
local function boxed_text(txt, size, a)
  screen.font_face(1)
  screen.font_size(size)
  local w = screen.text_extents(txt)
  local h = size + 2
  screen.level(0)
  screen.rect(64 - w / 2 - 3, 32 - h / 2 - 2, w + 6, h + 4)
  screen.fill()
  screen.level(math.floor(15 * a))
  screen.move(64 - w / 2, 32 + size / 2 - 1)
  screen.text(txt)
end

-- panel de strum: E3 elige la división (con signo = sentido); la escalera
-- muestra las notas del acorde en el orden en que suenan
local function draw_strum_panel()
  local x0, y0, w, h = 26, 18, 76, 28
  screen.level(0)
  screen.rect(x0, y0, w, h)
  screen.fill()
  screen.font_face(1)
  screen.font_size(8)
  screen.level(15)
  screen.move(x0 + 4, y0 + 9)
  screen.text("STRUM")
  local v = pv("strum")
  screen.level(v == 0 and 6 or 15)
  screen.move(x0 + 4, y0 + 21)
  screen.text(strum_text(v))
  screen.level(6)
  screen.move(x0 + 4 + screen.text_extents(strum_text(v)) + 5, y0 + 21)
  screen.text("E3")
  if v ~= 0 then
    local n = 4
    local sx = x0 + w - 4 - (n - 1) * 4 - 2
    local step = math.max(0.03, strum_step())
    local lit = math.floor(util.time() / step) % (n + 3) + 1
    for i = 1, n do
      local hgt = math.floor((i - 1) * 14 / (n - 1) + 0.5)
      if v < 0 then hgt = 14 - hgt end
      G.rect(i == lit and 15 or 8, sx + (i - 1) * 4, y0 + 22 - hgt, 3, 2)
    end
  end
  G.flush()
end

local function draw_overlays()
  if strum_ui then
    draw_strum_panel()
  elseif bank_flash > 0 then
    boxed_text(cur_bank().name, 16, math.min(1, bank_flash / PULSE))
  elseif carp_flash > 0 then
    boxed_text("CHIP ARP " .. carp_names[pv("carp")], 8, math.min(1, carp_flash / PULSE))
  elseif chord_flash > 0 or k3_held then
    -- nombre del acorde, solo mientras se elige (K3)
    local root = current_note or last_note
    local txt = (root and note_names[(root % 12) + 1] or "") ..
      (chord_suffix[chord_name()] ~= "" and chord_suffix[chord_name()] or (root and "" or "maj"))
    -- modo acorde apagado: solo la nota (o "1" si todavía no se tocó nada)
    if params:get("chord_on") == 1 then txt = root and note_names[(root % 12) + 1] or "1" end
    boxed_text(txt, 8, k3_held and 1 or math.min(1, chord_flash / PULSE))
  end
end

-- ---- splash ----
local CHIP_FONT = {
  C = {"#####", "#....", "#....", "#....", "#####"},
  H = {"#...#", "#...#", "#####", "#...#", "#...#"},
  I = {"#####", "..#..", "..#..", "..#..", "#####"},
  P = {"####.", "#...#", "####.", "#....", "#...."},
}
local function draw_splash(alpha)
  screen.clear()
  local lv = math.max(0, math.min(15, math.floor(15 * alpha)))
  screen.level(lv)
  screen.font_face(1)
  screen.font_size(16)
  local txt = "C H O R D E X"
  local w = screen.text_extents(txt)
  screen.move(64 - w / 2, 22)
  screen.text(txt)
  -- "CHIP" en bloques de 3 px, cada letra prende a su turno como un 8-bit
  local t = util.time()
  local x0 = 64 - (4 * 18 - 3) / 2
  for i, ch in ipairs({"C", "H", "I", "P"}) do
    local glow = (math.floor(t * 6) % 4) + 1 == i
    screen.level(math.max(0, math.floor((glow and 15 or 9) * alpha)))
    local rows = CHIP_FONT[ch]
    for yy = 1, 5 do
      for xx = 1, 5 do
        if rows[yy]:sub(xx, xx) == "#" then
          screen.rect(x0 + (i - 1) * 18 + (xx - 1) * 3, 32 + (yy - 1) * 3, 3, 3)
        end
      end
    end
    screen.fill()
  end
  -- onda cuadrada corriendo abajo
  screen.level(math.max(0, math.floor(6 * alpha)))
  local off = math.floor(t * 30) % 16
  for x = 0, 127 do
    local hi = ((x + off) % 16) < 8
    screen.rect(x, hi and 53 or 58, 1, 1)
    if ((x + off) % 8) == 0 then screen.rect(x, 53, 1, 6) end
  end
  screen.fill()
  screen.update()
end

local function tick(dt)
  for k, v in pairs(pulse) do pulse[k] = math.max(0, v - 1) end
  bank_flash = math.max(0, bank_flash - 1)
  carp_flash = math.max(0, carp_flash - 1)
  chord_flash = math.max(0, chord_flash - 1)
  hold_flash = math.max(0, hold_flash - 1)
  if strum_ui and util.time() - strum_t > STRUM_CLOSE then strum_ui = false end
  flash = math.max(0, flash - dt * 3)
end

local eco_timer = 0
function redraw()
  local now = util.time()
  if splash_start then
    local e = now - splash_start
    if e < uma_intro.DUR then
      uma_intro.render(e)
      screen.update()
      return
    end
    e = e - uma_intro.DUR
    local t1 = SPLASH_IN
    local t2 = t1 + SPLASH_HOLD
    local t3 = t2 + SPLASH_FADE
    if e < t1 then draw_splash(e / SPLASH_IN) return
    elseif e < t2 then draw_splash(1) return
    elseif e < t3 then draw_splash(1 - (e - t2) / SPLASH_FADE) return
    else splash_start = nil end
  end

  local dt = last_t and math.min(0.2, now - last_t) or 1 / 24
  last_t = now
  tick(dt)
  tr_tick(dt, beat_seconds() / 4)
  eco_timer = eco_timer + dt
  if eco_timer > 1 then eco_timer = 0; update_eco_time() end

  screen.clear()
  draw_header(now)
  draw_tracker(now)
  draw_scope(now)
  draw_faders()
  lane.draw(cur_bank().name, now)
  G.flush()
  draw_overlays()
  screen.update()
end
