// Engine_ChordexCHIP.sc
// Chordex CHIP — mismo instrumento de acordes que Chordex80 / ChordexFM /
// ChordexWT (una tecla = un acorde de 4 tonos + bajo, arpegio, retener,
// crackle), con un motor CHIPTUNE.
//
// Tablas: 24 ondas cortas de pocos bits (las mismas cadenas que el script
//   de Lua usa para dibujarlas; las genera tools/tablas.py). Se leen SIN
//   interpolar, escalón por escalón, como un chip de consola.
//   SQ TRI SAW, GBA-GBD (wave channel 4 bits), PCA-PCC (5 bits),
//   AMA-AMD (muestras de 8 bits), P4 P5 N93 (ruidos LFSR), BUZ (buzzer AY),
//   STRI SAT (triángulo y saw&tri combinada SID), OSIN OHALF OABS OQUAR (OPL).
// Voz chip (\chip_voice / \chip_pluck / \chip_legato):
//   fase -> duty (deforma la fase: con SQ es ancho de pulso) + PWM ->
//   tabla escalonada + ruido LFSR (noise) -> envolvente de 16 pasos.
//   Tono: pitch sweep (arranca corrido y vuelve) + vibrato con retardo.
//   Arpegio de chip: una sola voz recorre las notas del acorde a 12-60 Hz.
// Voz FM (\fm_*): 2 operadores estilo OPL; duty = índice de modulación,
//   pwm = LFO del índice, noise = cuánto cae el brillo con la nota.
// FX (\chip_fx): filtro resonante (cutoff, reso) -> sample rate -> bits ->
//   crackle -> eco a tempo -> hall -> compresor.

Engine_ChordexCHIP : CroneEngine {

  var voiceBus, fxSynth, bufs, tabN;
  var noteGroup, releasingGroup, padSynth, legatoSynth, plucks;

  var atk = 0.005, rel = 0.4, sus = 0.7;
  var duty = 0.25, pwm = 0, noise = 0, sweep = 0, swt = 0.12, vib = 0.2, fat = 0;
  var tab = 0, btab = 1, quant = 1, fm = 0, mtab = 20, ratio = 1;
  var carp = 0, bass = 0.7, strum = 0;

  alloc {
    var tables, mkChip, mkFm, d32 = "0123456789ABCDEFGHIJKLMNOPQRSTUV";
    plucks = List.new;

    tables = [
      ["SQ", 1, "10"],
      ["TRI", 4, "FEDCBA98765432100123456789ABCDEF"],
      ["SAW", 5, "0123456789ABCDEFGHIJKLMNOPQRSTUV"],
      ["GBA", 4, "89BDEFFFFEDDCB988764322100001246"],
      ["GBB", 4, "0246789ABCDEEFFFFFFEEDC000000000"],
      ["GBC", 4, "8CEFEDCCBA889ABA8545677543321013"],
      ["GBD", 4, "FFFF0000F0F0A5A5FFFF000088884444"],
      ["PCA", 5, "GQTTVVRPSVRLIGCAFLJFDA4036400225"],
      ["PCB", 5, "GVVSSOMLKLLKKJHHGEECBBAABA973300"],
      ["PCC", 5, "GPMLKIMKHRVPKEDJGCIHB604EB9DBA96"],
      ["AMA", 8, "80CAEFF8FCFFFCF9F7F3EEEBE6E1DDD8D2CDC9C3BEBAB4AEAAA59F9A958F8A85807A75706A65605A55514B45413C36322D27221E1914110C0806030003071035"],
      ["AMB", 8, "80D7FFEAB17A5D5D686F6F70788591969289817C7B7D7F808181818180808080807F7F7F7F7E7E7E7E7F808284837E766D696E7A878F909097A2A2854E150028"],
      ["AMC", 8, "80A9CEE9F9FFFFFCF9F6F3EEE7DDD2C8C2BFC1C4C7C9CACACCD0D6DAD9D0BDA1805E422F2625292F33353536383B3E403D372D2218110C090603000006163156"],
      ["AMD", 8, "80DEFFF5EEEFDFC7B8B0A59FA2A5A3A2A3A09A9A9C9D9DA2A39F9B9891898584807B7A766E6764605C5D62626365655F5C5D5C5A5D605A4F47382010110A0021"],
      ["P4", 1, "100010011010111"],
      ["P5", 1, "1000010010110011111000110111010"],
      ["N93", 1, "100000010000011000010100011110010001011001110101001111101000011100010010011011010110111101100"],
      ["BUZ", 4, "FEDCBA9876543210"],
      ["STRI", 8, "0008101820283038404850586068707880878F979FA7AFB7BFC7CFD7DFE7EFF7FFF7EFE7DFD7CFC7BFB7AFA79F978F8780787068605850484038302820181008"],
      ["SAT", 8, "000000000010001000002020001020300004080C1044584C6004082C3044586C8084888C9084988C20240A0E32261A0E00C0C0C0C09080908060604040302010"],
      ["OSIN", 8, "808C98A5B0BCC6D0DAE2EAF0F5FAFDFEFFFEFDFAF5F0EAE2DAD0C6BCB0A5988C8073675A4F43392F251D150F0A050201000102050A0F151D252F39434F5A6773"],
      ["OHALF", 8, "0019324A62788EA2B4C5D4E1ECF4FAFEFFFEFAF4ECE1D4C5B4A28E78624A32190000000000000000000000000000000000000000000000000000000000000000"],
      ["OABS", 8, "0019324A62788EA2B4C5D4E1ECF4FAFEFFFEFAF4ECE1D4C5B4A28E78624A32190019324A62788EA2B4C5D4E1ECF4FAFEFFFEFAF4ECE1D4C5B4A28E78624A3219"],
      ["OQUAR", 8, "0019324A62788EA2B4C5D4E1ECF4FAFE000000000000000000000000000000000019324A62788EA2B4C5D4E1ECF4FAFE00000000000000000000000000000000"]
    ];

    // cadena -> muestras -1..1, sin continua y con pico 1 (igual que en Lua)
    tabN = Array.newClear(tables.size);
    bufs = tables.collect({ |t, i|
      var bits = t[1], s = t[2], m = (2 ** bits) - 1, vals, mean, pk;
      vals = if (bits <= 5) {
        s.as(Array).collect({ |c| d32.indexOf(c) })
      } {
        (s.size div: 2).collect({ |k| ("0x" ++ s.copyRange(k * 2, (k * 2) + 1)).interpret })
      };
      vals = vals.collect({ |v| (v / m * 2) - 1 });
      mean = vals.sum / vals.size;
      vals = vals - mean;
      pk = vals.abs.maxItem.max(1e-6);
      vals = vals / pk;
      tabN[i] = vals.size;
      Buffer.loadCollection(context.server, vals, 1);
    });
    context.server.sync;

    voiceBus = Bus.audio(context.server, 2);

    // tono común: chip arp (recorre f1..f4), sweep, vibrato con retardo
    // mode 0 = acorde (gate), 1 = pluck del arpegio (dur), 2 = legato
    mkChip = { |name, mode|
      SynthDef(name, {
        arg out = 0, f1 = 440, f2 = 0, f3 = 0, f4 = 0, nf = 1, carp = 0,
            gate = 1, vel = 0.8, amp = 0.2, pan = 0, dur = 0.3,
            atk = 0.005, rel = 0.4, sus = 0.7, quant = 1,
            buf = 0, tn = 32, duty = 0.25, pwm = 0, noise = 0,
            sweep = 0, swt = 0.12, vib = 0, fat = 0;
        var g, env, master, ci, fr, swe, vdel, vb, f, dy, osc, nz, sig, relE;

        if (mode == 1) {
          g = Trig1.kr(1, dur * 0.5);
          relE = (rel * 0.5).min(dur * 1.5) + 0.02;
          env = EnvGen.kr(Env.adsr(atk.min(dur * 0.3) + 0.001, rel, sus, relE), g);
        } {
          g = gate;
          relE = rel;
          env = EnvGen.kr(Env.adsr(atk + 0.001, rel, sus, relE), g);
        };
        // volumen de 16 pasos como en los chips (no en AMIGA / OPL)
        env = Select.kr(quant, [env, (env * 15).round(1) / 15]);

        ci = (PulseCount.kr(Impulse.kr(carp)) - 1) % nf.max(1);
        fr = Select.kr(ci, [f1, f2, f3, f4]);
        if (mode == 2) { fr = Lag.kr(fr, 0.03) };
        swe = EnvGen.kr(Env([1, 0], [swt], -3));
        vdel = EnvGen.kr(Env([0, 0, 1], [0.25, 0.4]));
        vb = LFTri.kr(5.8) * vib * vdel;
        f = fr * (2 ** (((sweep * 36 * swe) + vb) / 12));

        // duty: deforma la fase (en SQ = ancho de pulso), PWM = LFO lento
        dy = (duty + (LFTri.kr(0.35 + (pwm * 2.5)) * pwm * 0.4)).clip(0.04, 0.96);
        osc = [f, f * (1 + (fat * 0.012))].collect({ |ff|
          var ph = Phasor.ar(0, ff / SampleRate.ir, 0, 1), w;
          w = Select.ar(ph > dy, [ph * 0.5 / dy, 0.5 + ((ph - dy) * 0.5 / (1 - dy))]);
          BufRd.ar(1, buf, (w * tn).floor, 1, 1)
        });
        // ruido LFSR de 1 bit, más agudo con la nota
        nz = Latch.ar(WhiteNoise.ar, Impulse.ar((f * 24).min(SampleRate.ir * 0.5))).sign;
        sig = (osc * (1 - noise)) + (nz * noise * 0.8);
        sig = [sig[0], (sig[0] * (1 - fat)) + (sig[1] * fat)];

        if (mode == 1) {
          master = EnvGen.kr(Env([1, 1, 0], [(dur * 0.5) + relE, 0.03]), doneAction: 2)
            * EnvGen.kr(Env.asr(0, 1, 0.04), gate, doneAction: 2);
        } {
          master = EnvGen.kr(Env.asr(0, 1, relE + 0.05), gate, doneAction: 2);
        };
        sig = sig * env * master * amp * (0.6 + (vel * 0.4));
        Out.ar(out, Balance2.ar(sig[0], sig[1], if (mode == 2) { Lag.kr(pan, 0.05) } { pan }));
      }).add;
    };

    // FM de 2 operadores (OPL): modulador -> fase de la portadora
    mkFm = { |name, mode|
      SynthDef(name, {
        arg out = 0, f1 = 440, f2 = 0, f3 = 0, f4 = 0, nf = 1, carp = 0,
            gate = 1, vel = 0.8, amp = 0.2, pan = 0, dur = 0.3,
            atk = 0.005, rel = 0.4, sus = 0.7,
            buf = 0, tn = 64, mbuf = 0, mtn = 64, ratio = 1,
            duty = 0.5, pwm = 0, noise = 0, sweep = 0, swt = 0.12, vib = 0, fat = 0;
        var g, env, master, ci, fr, swe, vdel, vb, f, idx, menv, sig, relE;

        if (mode == 1) {
          g = Trig1.kr(1, dur * 0.5);
          relE = (rel * 0.5).min(dur * 1.5) + 0.02;
          env = EnvGen.kr(Env.adsr(atk.min(dur * 0.3) + 0.001, rel, sus, relE), g);
        } {
          g = gate;
          relE = rel;
          env = EnvGen.kr(Env.adsr(atk + 0.001, rel, sus, relE), g);
        };

        ci = (PulseCount.kr(Impulse.kr(carp)) - 1) % nf.max(1);
        fr = Select.kr(ci, [f1, f2, f3, f4]);
        if (mode == 2) { fr = Lag.kr(fr, 0.03) };
        swe = EnvGen.kr(Env([1, 0], [swt], -3));
        vdel = EnvGen.kr(Env([0, 0, 1], [0.25, 0.4]));
        vb = LFTri.kr(5.8) * vib * vdel;
        f = fr * (2 ** (((sweep * 36 * swe) + vb) / 12));

        // el brillo cae con la nota (noise = cuánto), velocidad lo abre
        menv = 1 - (noise * (1 - EnvGen.kr(Env([1, 0.0001], [0.15 + (rel * 0.8)], \exp))));
        idx = duty * 2.2 * menv * (0.6 + (vel * 0.5)) * (1 + (LFTri.kr(0.5 + (pwm * 4)) * pwm * 0.5));
        sig = [f, f * (1 + (fat * 0.008))].collect({ |ff|
          var m = BufRd.ar(1, mbuf, Phasor.ar(0, ff * ratio / SampleRate.ir, 0, 1) * mtn, 1, 2);
          var ph = (Phasor.ar(0, ff / SampleRate.ir, 0, 1) + (m * idx)).wrap(0, 1);
          BufRd.ar(1, buf, ph * tn, 1, 2)
        });
        sig = [sig[0], (sig[0] * (1 - fat)) + (sig[1] * fat)];

        if (mode == 1) {
          master = EnvGen.kr(Env([1, 1, 0], [(dur * 0.5) + relE, 0.03]), doneAction: 2)
            * EnvGen.kr(Env.asr(0, 1, 0.04), gate, doneAction: 2);
        } {
          master = EnvGen.kr(Env.asr(0, 1, relE + 0.05), gate, doneAction: 2);
        };
        sig = sig * env * master * amp * (0.6 + (vel * 0.4));
        Out.ar(out, Balance2.ar(sig[0], sig[1], if (mode == 2) { Lag.kr(pan, 0.05) } { pan }));
      }).add;
    };

    mkChip.(\chip_voice, 0); mkChip.(\chip_pluck, 1); mkChip.(\chip_legato, 2);
    mkFm.(\fm_voice, 0); mkFm.(\fm_pluck, 1); mkFm.(\fm_legato, 2);

    // bajo: la tabla de bajo del banco, sin sweep ni ruido
    SynthDef(\chip_bass, {
      arg out = 0, freq = 55, gate = 1, atk = 0.005, rel = 0.4, sus = 0.8,
          amp = 0.3, buf = 0, tn = 32, quant = 1;
      var env, ph, sig;
      env = EnvGen.kr(Env.adsr(atk + 0.001, rel, sus.max(0.35), rel), gate, doneAction: 2);
      env = Select.kr(quant, [env, (env * 15).round(1) / 15]);
      ph = Phasor.ar(0, freq / SampleRate.ir, 0, 1);
      sig = BufRd.ar(1, buf, (ph * tn).floor, 1, 1);
      sig = LPF.ar(sig, 2500);
      Out.ar(out, Pan2.ar(sig * env * amp, 0));
    }).add;

    SynthDef(\chip_fx, {
      arg in, out, cutoff = 1, reso = 0, bits = 16, srate = 1, crackle = 0,
          eco = 0, ecot = 0.375, space = 0.15, gain = 1.0;
      var dry, sig, fc, cn, cg, sr, lofi, q, fb, d, verb, comp;

      dry = In.ar(in, 2);
      sig = dry;

      // filtro resonante (estilo SID): cutoff 0..1 = 60 Hz .. 18 kHz
      fc = (60 * (2 ** (Lag.kr(cutoff, 0.05) * 8.23))).clip(40, 18000);
      sig = RLPF.ar(sig, fc, (1 - (reso * 0.92)).max(0.06)) * (1 - (reso * 0.35));

      // sample rate (1 = sin reducir) y bits (16 = sin reducir)
      sr = 1500 * (2 ** (srate * 5));
      lofi = Latch.ar(sig, Impulse.ar(sr));
      sig = Select.ar(srate > 0.99, [lofi, sig]);
      q = 2 ** (bits - 1);
      sig = (sig * q).round(1) / q;

      cn = HPF.ar(Crackle.ar(1.85, mul: [1, 1]), 1600);
      cg = Amplitude.kr(Mix(dry), 0.01, 0.08) > 0.02;
      sig = sig + (cn * crackle * 0.3 * cg);

      // eco a tempo (ping-pong)
      fb = LocalIn.ar(2);
      d = DelayC.ar(sig + (fb.reverse * 0.45), 1.5, Lag.kr(ecot, 0.2));
      LocalOut.ar(LPF.ar(d, 6000));
      sig = sig + (d * eco * 0.8);

      verb = HPF.ar(sig, 250) * space;
      verb = FreeVerb2.ar(verb[0], verb[1], 1, 0.82, 0.5);
      sig = sig + (verb * 0.9);

      sig = LPF.ar(HPF.ar(sig, 30), 15000);
      comp = Compander.ar(sig, Mix(sig) * 0.5, 0.25, 1, 0.5, 0.008, 0.18);
      sig = comp * 1.4 * gain;
      sig = Limiter.ar(LeakDC.ar(sig), 0.92, 0.002);
      Out.ar(out, sig);
    }).add;

    context.server.sync;

    fxSynth = Synth.tail(context.xg, \chip_fx, [\in, voiceBus, \out, context.out_b]);

    // f1..f4 (0 = esa voz no suena), bajo, vel
    this.addCommand("noteOn", "ffffff", { |msg|
      var freqs = [msg[1], msg[2], msg[3], msg[4]].select({ |f| f > 0 });
      var subf = msg[5], vel = msg[6], nv;

      if (releasingGroup.notNil) { releasingGroup.free };
      if (noteGroup.notNil) {
        noteGroup.set(\gate, 0);
        releasingGroup = noteGroup;
      };
      noteGroup = Group.head(context.xg);
      if (freqs.size == 0) { freqs = [subf * 4] };

      if (carp > 0 and: { freqs.size > 1 }) {
        // arpegio de chip: una sola voz recorre el acorde
        Synth.new(this.def(\voice), this.voiceArgs ++ this.chipFreqs(freqs) ++ [
          \vel, vel, \amp, 0.3 * this.ampFix, \pan, 0
        ], noteGroup);
      } {
        // strum: cada voz entra strum segundos después de la anterior;
        // positivo = de grave a agudo, negativo = de agudo a grave
        var g = noteGroup, args;
        nv = freqs.size;
        freqs.do({ |f, i|
          var wait = strum.abs * (if (strum < 0) { nv - 1 - i } { i });
          args = this.voiceArgs ++ [
            \f1, f, \nf, 1, \vel, vel, \amp, 0.2 * this.ampFix * ((4 / nv) ** 0.5),
            \pan, if (nv == 1) { 0 } { ((i - 1.5) * 0.35).clip(-0.9, 0.9) }
          ];
          if (wait <= 0) { Synth.new(this.def(\voice), args, g) } {
            SystemClock.sched(wait, {
              if (noteGroup === g) { Synth.new(this.def(\voice), args, g) };
              nil
            });
          };
        });
      };
      if (bass > 0) { Synth.new(\chip_bass, this.bassArgs(subf, 0.24 * bass), noteGroup) };
    });

    this.addCommand("noteOff", "", { |msg|
      var g;
      if (releasingGroup.notNil) { releasingGroup.free; releasingGroup = nil };
      if (noteGroup.notNil) {
        g = noteGroup;
        g.set(\gate, 0);
        releasingGroup = g;
        noteGroup = nil;
        SystemClock.sched(rel + 0.6, {
          if (releasingGroup === g) { g.free; releasingGroup = nil };
          nil
        });
      };
    });

    this.addCommand("padOn", "f", { |msg|
      if (padSynth.notNil) {
        padSynth.set(\freq, this.bassFreq(msg[1]));
      } {
        if (bass > 0) { padSynth = Synth.new(\chip_bass, this.bassArgs(msg[1], 0.28 * bass), context.xg) };
      };
    });

    this.addCommand("padOff", "", { |msg|
      if (padSynth.notNil) { padSynth.set(\gate, 0); padSynth = nil };
    });

    // freq, dur, vel, pan
    this.addCommand("arpStep", "ffff", { |msg|
      var p;
      while { plucks.size >= 8 } { plucks.removeAt(0).set(\gate, 0) };
      p = Synth.new(this.def(\pluck), this.voiceArgs ++ [
        \f1, msg[1], \nf, 1, \dur, msg[2], \vel, msg[3], \pan, msg[4], \amp, 0.3 * this.ampFix
      ], context.xg);
      plucks.add(p);
      p.onFree { plucks.remove(p) };
    });

    // freq, vel, pan: la primera vez crea la voz, después solo la mueve
    this.addCommand("arpLegato", "fff", { |msg|
      if (legatoSynth.notNil) {
        legatoSynth.set(\f1, msg[1], \vel, msg[2], \pan, msg[3]);
      } {
        legatoSynth = Synth.new(this.def(\legato), this.voiceArgs ++ [
          \f1, msg[1], \nf, 1, \vel, msg[2], \pan, msg[3], \amp, 0.36 * this.ampFix
        ], context.xg);
      };
    });
    this.addCommand("arpLegatoOff", "", { |msg|
      if (legatoSynth.notNil) { legatoSynth.set(\gate, 0); legatoSynth = nil };
    });

    // onda: tabla de la voz, tabla de bajo, 16 pasos (0/1), fm (0/1), tabla moduladora, ratio
    this.addCommand("wave", "iiiiif", { |msg|
      tab = msg[1].clip(0, bufs.size - 1);
      btab = msg[2].clip(0, bufs.size - 1);
      quant = msg[3]; fm = msg[4];
      mtab = msg[5].clip(0, bufs.size - 1);
      ratio = msg[6];
    });

    this.addCommand("atk", "f", { |msg| atk = msg[1] });
    this.addCommand("rel", "f", { |msg| rel = msg[1]; this.setLive([\rel, rel]) });
    this.addCommand("sus", "f", { |msg| sus = msg[1]; this.setLive([\sus, sus]) });
    this.addCommand("duty", "f", { |msg| duty = msg[1]; this.setLive([\duty, duty]) });
    this.addCommand("pwm", "f", { |msg| pwm = msg[1]; this.setLive([\pwm, pwm]) });
    this.addCommand("noise", "f", { |msg| noise = msg[1]; this.setLive([\noise, noise]) });
    this.addCommand("sweep", "f", { |msg| sweep = msg[1] });
    this.addCommand("swt", "f", { |msg| swt = msg[1] });
    this.addCommand("vib", "f", { |msg| vib = msg[1]; this.setLive([\vib, vib]) });
    this.addCommand("fat", "f", { |msg| fat = msg[1]; this.setLive([\fat, fat]) });
    this.addCommand("carp", "f", { |msg| carp = msg[1] });
    this.addCommand("bass", "f", { |msg| bass = msg[1] });
    this.addCommand("strum", "f", { |msg| strum = msg[1].clip(-0.5, 0.5) });

    this.addCommand("cutoff", "f", { |msg| fxSynth.set(\cutoff, msg[1]) });
    this.addCommand("reso", "f", { |msg| fxSynth.set(\reso, msg[1]) });
    this.addCommand("bits", "f", { |msg| fxSynth.set(\bits, msg[1]) });
    this.addCommand("srate", "f", { |msg| fxSynth.set(\srate, msg[1]) });
    this.addCommand("eco", "f", { |msg| fxSynth.set(\eco, msg[1]) });
    this.addCommand("ecot", "f", { |msg| fxSynth.set(\ecot, msg[1].clip(0.05, 1.5)) });
    this.addCommand("space", "f", { |msg| fxSynth.set(\space, msg[1]) });
    this.addCommand("gain", "f", { |msg| fxSynth.set(\gain, msg[1]) });
    this.addCommand("crackle", "f", { |msg| fxSynth.set(\crackle, msg[1]) });
  }

  def { |kind| ^((if (fm == 1) { "fm_" } { "chip_" }) ++ kind).asSymbol }

  // los pulsos y ruidos suenan más fuerte que el seno
  ampFix { ^if (fm == 1) { 0.9 } { [0.55, 0.8, 0.6][tab.min(2)] * (1 - (noise * 0.3)) } }

  chipFreqs { |freqs|
    var f = freqs ++ [0, 0, 0];
    ^[\f1, f[0], \f2, f[1], \f3, f[2], \f4, f[3], \nf, freqs.size.min(4), \carp, carp]
  }

  voiceArgs {
    ^[\out, voiceBus, \buf, bufs[tab].bufnum, \tn, tabN[tab],
      \mbuf, bufs[mtab].bufnum, \mtn, tabN[mtab], \ratio, ratio,
      \atk, atk, \rel, rel, \sus, sus, \quant, quant,
      \duty, duty, \pwm, pwm, \noise, noise, \sweep, sweep, \swt, swt,
      \vib, vib, \fat, fat, \carp, 0]
  }

  bassArgs { |f, amp|
    ^[\out, voiceBus, \freq, this.bassFreq(f), \atk, atk, \rel, rel.max(0.15), \sus, sus,
      \buf, bufs[btab].bufnum, \tn, tabN[btab], \quant, quant, \amp, amp]
  }

  setLive { |args|
    if (noteGroup.notNil) { noteGroup.set(*args) };
    if (legatoSynth.notNil) { legatoSynth.set(*args) };
  }

  bassFreq { |f| ^if (f < 40) { f * 2 } { f } }

  free {
    if (noteGroup.notNil) { noteGroup.free };
    if (releasingGroup.notNil) { releasingGroup.free };
    if (padSynth.notNil) { padSynth.free };
    if (legatoSynth.notNil) { legatoSynth.free };
    fxSynth.free;
    voiceBus.free;
    bufs.do(_.free);
  }
}
