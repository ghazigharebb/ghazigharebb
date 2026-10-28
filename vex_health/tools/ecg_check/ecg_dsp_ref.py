#!/usr/bin/env python3
"""VEX ECG — Python mirror of lib/ecg/ecg_signal.dart (same math, sample by sample).

Run:  python3 tools/ecg_check/ecg_dsp_ref.py
Tests the filter chain + R-peak detector on synthetic ECG with baseline wander,
50 Hz mains hum, noise, inverted polarity (right wrist), 24-bit wrap and several sample rates.
"""
import math
import random


class Biquad:
    def __init__(self):
        self.b0 = 1.0; self.b1 = self.b2 = self.a1 = self.a2 = 0.0
        self.z1 = self.z2 = 0.0

    def set(self, kind, fs, fc, q=0.7071):
        w = 2 * math.pi * fc / fs
        cw, sw = math.cos(w), math.sin(w)
        al = sw / (2 * q)
        if kind == 'hp':
            b0, b1, b2 = (1 + cw) / 2, -(1 + cw), (1 + cw) / 2
        elif kind == 'lp':
            b0, b1, b2 = (1 - cw) / 2, 1 - cw, (1 - cw) / 2
        else:  # notch
            b0, b1, b2 = 1.0, -2 * cw, 1.0
        a0, a1, a2 = 1 + al, -2 * cw, 1 - al
        self.b0, self.b1, self.b2, self.a1, self.a2 = b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0

    def run(self, x):  # transposed direct form II
        y = self.b0 * x + self.z1
        self.z1 = self.b1 * x - self.a1 * y + self.z2
        self.z2 = self.b2 * x - self.a2 * y
        return y

    def reset(self):
        self.z1 = self.z2 = 0.0


class EcgDsp:
    def __init__(self, fs=50.0, invert=False):
        self.fs = fs
        self.invert = invert
        self.hp1, self.hp2, self.lp, self.notch = Biquad(), Biquad(), Biquad(), Biquad()
        self.qhp, self.qlp = Biquad(), Biquad()  # QRS band 5-15 Hz (detection only)
        self.use_notch = False
        self._design(fs)
        self.prev = None; self.off = 0.0; self.x0 = None
        self.n = 0
        self.ybuf = []           # filtered history (for R location)
        self.dbuf = [0.0, 0.0]   # for derivative
        self.mwi = []            # integration window
        self.mwi_sum = 0.0
        self.m1 = self.m2 = 0.0  # last two mwi values
        self.spki = 0.0; self.npki = 0.0
        self.last_qrs = -10 ** 9
        self.learn = 0
        self.rr = []             # accepted RR (s)
        self.all_rr = []
        self.beats = []          # (index, signed amplitude)
        self.pol_votes = []
        self.cands = []

    def _design(self, fs):
        self.fs = fs
        self.hp1.set('hp', fs, 0.5); self.hp2.set('hp', fs, 0.5)
        self.lp.set('lp', fs, min(35.0, 0.4 * fs))
        self.qhp.set('hp', fs, 5.0); self.qlp.set('lp', fs, min(15.0, 0.3 * fs))
        self.use_notch = fs > 115
        if self.use_notch:
            self.notch.set('notch', fs, 50.0, 8.0)

    def push(self, raw):
        # 24-bit unwrap (values may be signed 24-bit sent as unsigned)
        if self.prev is not None:
            d = raw - self.prev
            if d > 2 ** 23: self.off -= 2 ** 24
            elif d < -2 ** 23: self.off += 2 ** 24
        self.prev = raw
        x = raw + self.off
        if self.x0 is None: self.x0 = x
        x -= self.x0
        y = self.hp2.run(self.hp1.run(x))
        if self.use_notch: y = self.notch.run(y)
        y = self.lp.run(y)
        if self.invert: y = -y
        self.n += 1
        self.ybuf.append(y)
        if len(self.ybuf) > int(self.fs * 3): self.ybuf.pop(0)
        self._detect(self.qlp.run(self.qhp.run(y)))
        return y

    def _detect(self, y):
        fs = self.fs
        self.dbuf.append(y)
        d = self.dbuf[-1] - self.dbuf[-3]
        self.dbuf.pop(0)
        s = d * d
        w = max(3, round(0.12 * fs))
        self.mwi.append(s); self.mwi_sum += s
        while len(self.mwi) > w: self.mwi_sum -= self.mwi.pop(0)
        m = math.sqrt(max(0.0, self.mwi_sum) / len(self.mwi))  # RMS envelope (linear in amplitude)
        # local max of mwi one sample ago
        if self.n > 3 and self.m1 > self.m2 and self.m1 >= m:
            pk = self.m1
            idx = self.n - 2
            settle = int(fs * 1.2)
            if self.n < settle:   # filters settling
                pass
            elif self.learn < int(fs * 2):
                self.spki = max(self.spki, pk); self.npki = 0.5 * self.npki + 0.5 * pk * 0.1
            else:
                thr = self.npki + 0.45 * (self.spki - self.npki)
                refr = 0.25 * fs
                if pk > thr and idx - self.last_qrs > refr:
                    self.spki = 0.125 * pk + 0.875 * self.spki
                    self._qrs(idx)
                    self.cands = []
                else:
                    self.npki = 0.125 * pk + 0.875 * self.npki
                    if idx - self.last_qrs > refr:
                        self.cands.append((idx, pk))
        # search-back: no beat for 1.66 x the usual RR -> take the best skipped peak
        if self.cands and len(self.rr) >= 2:
            avg = sum(self.rr[-8:]) / len(self.rr[-8:])
            if (self.n - self.last_qrs) > 1.66 * avg * fs:
                thr = self.npki + 0.45 * (self.spki - self.npki)
                i2, p2 = max(self.cands, key=lambda c: c[1])
                self.cands = []
                if p2 > 0.5 * thr:
                    self.spki = 0.25 * p2 + 0.75 * self.spki
                    self._qrs(i2, back=True)
        if self.n >= int(fs * 1.2): self.learn += 1
        self.m2, self.m1 = self.m1, m

    def _qrs(self, idx, back=False):
        fs = self.fs
        # R = largest |y| in the ~0.2 s before the integrator peak (it lags the QRS)
        span = max(3, round(0.2 * fs))
        end = len(self.ybuf) - (self.n - 1 - idx)
        seg = self.ybuf[max(0, end - span):end]
        if not seg: return
        j = max(range(len(seg)), key=lambda i: abs(seg[i]))
        r_idx = idx - (len(seg) - 1 - j)
        amp = seg[j]
        # sub-sample R position (parabola through the 3 samples around the peak)
        if 0 < j < len(seg) - 1:
            a, b, c = abs(seg[j - 1]), abs(seg[j]), abs(seg[j + 1])
            den = a - 2 * b + c
            if den != 0:
                r_idx += max(-0.5, min(0.5, 0.5 * (a - c) / den))
        if self.beats:
            rr = (r_idx - self.beats[-1][0]) / fs
            if 0.27 <= rr <= 2.2:
                self.all_rr.append(rr)
                med = sorted(self.rr)[len(self.rr) // 2] if len(self.rr) >= 3 else None
                if med is None or 0.65 * med <= rr <= 1.5 * med:
                    self.rr.append(rr)
                    if len(self.rr) > 12: self.rr.pop(0)
        self.beats.append((r_idx, amp))
        self.last_qrs = idx
        self.pol_votes.append(1 if amp >= 0 else -1)
        if len(self.pol_votes) > 8: self.pol_votes.pop(0)

    @property
    def flipped(self):
        return len(self.pol_votes) >= 6 and sum(self.pol_votes) <= -4

    @property
    def bpm(self):
        if len(self.rr) < 3: return None
        s = sorted(self.rr[-8:])
        return 60.0 / s[len(s) // 2]


def ecg(t, bpm):
    # realistic lead-I shape with absolute widths (s): P, Q, R, S, T
    period = 60.0 / bpm
    x = t % period
    r = 0.25 * min(period, 0.9)
    g = lambda c, w, a: a * math.exp(-((x - c) / w) ** 2)
    return (g(r - 0.16, 0.025, .12) - g(r - 0.028, 0.012, .12) + g(r, 0.016, 1.0)
            - g(r + 0.03, 0.013, .25) + g(r + 0.24 * min(1, period), 0.05, .3))


def run(fs, bpm, invert_body=False, invert_cfg=False, noise=0.05, hum=0.3, wander=2.0, base=8_000_000, gain=3000, secs=30, wrap=False, seed=1):
    random.seed(seed)
    dsp = EcgDsp(fs, invert=invert_cfg)
    for i in range(int(fs * secs)):
        t = i / fs
        v = ecg(t, bpm) * (-1 if invert_body else 1)
        v += noise * random.gauss(0, 1) + hum * math.sin(2 * math.pi * 50 * t) + wander * math.sin(2 * math.pi * 0.25 * t)
        raw = round((0 if wrap else base) + gain * v)
        if wrap: raw &= 0xFFFFFF
        dsp.push(raw)
    return dsp


if __name__ == '__main__':
    ok = True
    for fs in (50, 125, 250, 512):
        for bpm in (52, 72, 110, 150):
            for inv in (False, True):
                hum = 0.3 if fs > 115 else 0.0  # at 50 Hz sampling, hum aliases to DC
                d = run(fs, bpm, invert_body=inv, hum=hum, wrap=(fs == 250))
                b = d.bpm
                err = abs((b or 0) - bpm)
                pol_ok = d.flipped == inv
                exp_beats = (30 - 2.4) * bpm / 60
                good = b is not None and err <= max(2.0, bpm * 0.03) and pol_ok and abs(len(d.beats) - exp_beats) <= 3
                ok &= good
                print(f"fs={fs:3} bpm={bpm:3} inv={inv!s:5} -> {b and round(b,1)!s:6} beats={len(d.beats):3} flip={d.flipped!s:5} {'OK' if good else 'FAIL'}")
    print('ALL OK' if ok else 'SOME FAILED')
