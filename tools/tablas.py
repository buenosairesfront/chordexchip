# genera las tablas de onda de Chordex CHIP (mismo texto va al .sc y al .lua)
# cada tabla: (nombre, bits, cadena); muestra = digito / (2^bits - 1) * 2 - 1
# digitos: 0-9 A-Z a-z ... (base 64 para 6 bits; 8 bits usa 2 hex por muestra)
import math
D32 = "0123456789ABCDEFGHIJKLMNOPQRSTUV"
def q(v, bits):            # v en -1..1 -> entero 0..2^bits-1
    m = 2 ** bits - 1
    return max(0, min(m, round((v + 1) / 2 * m)))
def enc(vals, bits):
    if bits <= 5: return "".join(D32[x] for x in vals)
    return "".join("%02X" % x for x in vals)
def harm(N, hs, bits, ph=None):
    ys = [sum(a * math.sin(2 * math.pi * h * k / N + (ph or 0) * h) for h, a in hs) for k in range(N)]
    pk = max(abs(y) for y in ys)
    return [q(y / pk, bits) for y in ys]
def lfsr(n, taps, length):
    s, out = 1, []
    for _ in range(length):
        out.append(s & 1)
        fb = 0
        for t in taps: fb ^= (s >> t) & 1
        s = (s >> 1) | (fb << (n - 1))
    return out
T = []
T.append(("SQ", 1, "10"))
T.append(("TRI", 4, "FEDCBA98765432100123456789ABCDEF"))
T.append(("SAW", 5, "".join(D32[k] for k in range(32))))
T.append(("GBA", 4, enc(harm(32, [(1, 1), (2, 0.15)], 4), 4)))
T.append(("GBB", 4, "0246789ABCDEEFFFFFFEEDC000000000"))
T.append(("GBC", 4, enc(harm(32, [(1, 1), (2, 0.6), (3, 0.5), (5, 0.3)], 4), 4)))
T.append(("GBD", 4, "FFFF0000F0F0A5A5FFFF000088884444"))
T.append(("PCA", 5, enc(harm(32, [(1, 1), (2, 0.5), (4, 0.35), (8, 0.2)], 5), 5)))
T.append(("PCB", 5, enc(harm(32, [(h, 1 / h * (1.6 if h in (3, 4) else 1)) for h in range(1, 12)], 5), 5)))
T.append(("PCC", 5, enc(harm(32, [(1, 1), (4, 0.6), (7, 0.45), (11, 0.3)], 5), 5)))
T.append(("AMA", 8, enc(harm(64, [(h, 1 / h * math.exp(-h / 9)) for h in range(1, 20)], 8), 8)))
T.append(("AMB", 8, enc(harm(64, [(h, math.exp(-((h * 130 - 700) / 220) ** 2) + 0.6 * math.exp(-((h * 130 - 1150) / 260) ** 2) + 0.1 / h) for h in range(1, 20)], 8), 8)))
T.append(("AMC", 8, enc(harm(64, [(1, 1), (2, 0.2), (3, 0.45), (5, 0.12), (7, 0.08)], 8), 8)))
T.append(("AMD", 8, enc(harm(64, [(h, 1 / h * (2.0 if 3 <= h <= 6 else 1)) for h in range(1, 18)], 8), 8)))
T.append(("P4", 1, "".join(str(b) for b in lfsr(4, [0, 1], 15))))
T.append(("P5", 1, "".join(str(b) for b in lfsr(5, [0, 2], 31))))
T.append(("N93", 1, "".join(str(b) for b in lfsr(7, [0, 1], 93))))
T.append(("BUZ", 4, "FEDCBA9876543210"))
T.append(("STRI", 8, enc([q(1 - 4 * abs(k / 64 - 0.5), 8) for k in range(64)], 8)))
# SID: saw AND tri (forma combinada)
saw8 = [int(k / 63 * 255) for k in range(64)]
tri8 = [q(1 - 4 * abs(k / 64 - 0.5), 8) for k in range(64)]
T.append(("SAT", 8, enc([(a & (b << 1 & 255)) for a, b in zip(saw8, tri8)], 8)))
osin = [math.sin(2 * math.pi * k / 64) for k in range(64)]
T.append(("OSIN", 8, enc([q(v, 8) for v in osin], 8)))
T.append(("OHALF", 8, enc([q(max(0, v) * 2 - 1, 8) for v in osin], 8)))
T.append(("OABS", 8, enc([q(abs(v) * 2 - 1, 8) for v in osin], 8)))
T.append(("OQUAR", 8, enc([q((abs(v) * 2 - 1) if (k // 16) % 2 == 0 else -1, 8) for k, v in enumerate(osin)], 8)))
print("-- lua")
for n, b, s in T: print('  {"%s", %d, "%s"},' % (n, b, s))
print("// sc")
for n, b, s in T: print('      ["%s", %d, "%s"],' % (n, b, s))
