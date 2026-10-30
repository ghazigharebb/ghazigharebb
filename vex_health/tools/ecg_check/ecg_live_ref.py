#!/usr/bin/env python3
"""VEX ECG live — Python mirror of lib/ecg/ecg_signal.dart (v3: fixed sweep, rate lock,
playout buffer, contact re-learn, T-wave rejection).

Run:  python3 tools/ecg_check/ecg_live_ref.py
Simulates the real V8 stream: 3-byte samples in BLE packets of random size arriving
with jitter/bursts, 2-4 s of no finger (noise) and then a finger (big amplitude jump),
baseline wander, 50 Hz hum, tall T-waves, HRV, several true sample rates.
Checks: live BPM error, no doubled/halved BPM after contact, display head moves across
the whole screen (never stuck at the start), recorded tape length.
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
            n0, n1, n2 = (1 + cw) / 2, -(1 + cw), (1 + cw) / 2
        elif kind == 'lp':
            n0, n1, n2 = (1 - cw) / 2, 1 - cw, (1 - cw) / 2
        else:
            n0, n1, n2 = 1.0, -2 * cw, 1.0
        a0 = 1 + al
        self.b0, self.b1, self.b2 = n0 / a0, n1 / a0, n2 / a0
        self.a1, self.a2 = -2 * cw / a0, (1 - al) / a0
        self.z1 = self.z2 = 0.0

    def run(self, x):
        y = self.b0 * x + self.z1
        self.z1 = self.b1 * x - self.a1 * y + self.z2
        self.z2 = self.b2 * x - self.a2 * y
        return y


class Sig:
    def __init__(self, default_rate=255.0, seconds=5.0, invert=False):
        self.default_rate = default_rate
        self.seconds = seconds
        self.invert = invert
        self.hp1, self.hp2, self.lp, self.notch = Biquad(), Biquad(), Biquad(), Biquad()
        self.qhp, self.qlp = Biquad(), Biquad()
        self.reset()

    # ---------- setup ----------
    def reset(self):
        self.rate = self.default_rate
        self.locked = False; self.rate_ok = False; self.early = False
        self._design(self.rate)
        self.prev = None; self.off = 0.0; self.x0 = None
        self.n = 0
        self.t0 = None; self.last_pkt = None; self.count = 0
        self.arr = []  # (t, cumulative samples)
        self.last_id = None; self.lost = 0; self.pkt_avg = 0.0
        self.rej = []
        self.rrlog = []
        self.pol = []; self.flip = False
        self.env = 1e-6
        self.stdwin = []
        self.beat_count = 0
        self.play = []; self.playing = False; self.acc = 0.0; self.last_adv = None
        self.tape = []
        self.win = max(60, min(3000, round(self.seconds * self.rate)))
        self.sweep = [0.0] * self.win; self.cursor = 0; self.full = False
        self.railing = False
        self._reset_det()

    def _reset_det(self):
        self.since = 0
        self.ybuf = []
        self.d = [0.0, 0.0]
        self.mwi = []; self.slw = []; self.mwi_sum = 0.0; self.m1 = self.m2 = 0.0
        self.spki = self.npki = 0.0
        self.last_qrs = -10 ** 9; self.last_slope = 0.0; self.slopes = []
        self.learn = 0; self.cands = []; self.last_r = -1e9; self.rr = []
        self.quiet = 0; self.idle_mark = 0
        self.hold = 0; self.learn_e = 0.0; self.restart_at = 0; self.e_fast = 0.0

    def restart_learning(self):
        # re-baseline: filters restart from the current level -> the touch step does not ring through the high-pass
        self._design(self.rate); self.x0 = None
        self.hold = self.n + round(0.5 * self.rate)  # skip the touch artefact
        self.env = 1e-6
        self.learn_e = 0.0; self.restart_at = self.n
        self.learn = 0; self.spki = self.npki = 0.0; self.cands = []; self.rej = []
        self.last_r = -1e9; self.last_qrs = -10 ** 9; self.rr = []; self.last_slope = 0.0; self.slopes = []

    def _design(self, fs):
        self.design_rate = fs
        self.hp1.set('hp', fs, 0.5); self.hp2.set('hp', fs, 0.5)
        self.lp.set('lp', fs, min(35.0, 0.4 * fs))
        self.qhp.set('hp', fs, 5.0); self.qlp.set('lp', fs, min(15.0, 0.3 * fs))
        self.use_notch = fs > 115
        if self.use_notch:
            self.notch.set('notch', fs, 50.0, 8.0)

    # ---------- input ----------
    def add_packet(self, samples, t, pid=None):
        if not samples:
            return
        if pid is not None:
            last = self.last_id; self.last_id = pid
            if last is not None:
                lost = (pid - last - 1) & 0xff
                if 0 < lost < 8 and self.prev is not None:
                    self.lost += lost
                    a, b = self.prev, samples[0]
                    k = round(lost * (self.pkt_avg or len(samples)))
                    for i in range(1, k + 1):
                        self._push(round(a + (b - a) * i / (k + 1)))
                    self.count += k
        self.pkt_avg = len(samples) if self.pkt_avg == 0 else 0.9 * self.pkt_avg + 0.1 * len(samples)
        if self.t0 is None:
            self.t0 = t
        self.last_pkt = t
        self.count += len(samples)
        self.arr.append((t, self.count))
        while self.arr and t - self.arr[0][0] > 12.0:
            self.arr.pop(0)
        self._estimate(t)
        same = 0
        for s in samples:
            if self.prev == s:
                same += 1
            self._push(s)
        was = self.railing
        self.railing = same >= len(samples) - 1 and samples[-1] in (0, 0xFFFFFF)
        if was and not self.railing:
            self._design(self.rate); self.x0 = None

    def _estimate(self, t):
        # least-squares slope of (arrival time, cumulative samples); first 0.8 s ignored (BLE start-up burst)
        pts = [p for p in self.arr if p[0] - self.t0 >= 0.8]
        if len(pts) < 4:
            return
        span = pts[-1][0] - pts[0][0]
        if span < 3.0:
            return
        mt = sum(p[0] for p in pts) / len(pts); mc = sum(p[1] for p in pts) / len(pts)
        sxx = sum((p[0] - mt) ** 2 for p in pts)
        if sxx <= 0:
            return
        est = sum((p[0] - mt) * (p[1] - mc) for p in pts) / sxx
        if not (40 <= est <= 1100):
            return
        dev = abs(est - self.rate) / self.rate
        if not self.locked:
            if dev <= 0.12:
                self.rate_ok = True
            elif dev > 0.35 and not self.early:
                self.early = True  # clearly another rate: switch now, refine at 6 s
                self._relock(round(est))
                return
            if span >= 6.0:
                self.locked = True
                if dev > 0.04:
                    self._relock(round(est))
                self.rate_ok = True
        elif span >= 9.0 and dev > 0.06:
            self._relock(round(est))

    def _relock(self, fs):
        k = self.rate / fs
        self.rr = []  # detected with the wrong filters: re-acquire the live BPM
        self.rrlog = [x * k for x in self.rrlog]
        self.last_r = -1e9
        old = self.sweep; oc = self.cursor
        self.rate = fs
        self._design(fs)
        self.x0 = None
        self.mwi = []; self.slw = []; self.mwi_sum = 0.0; self.cands = []
        self.quiet = self.n + round(0.6 * fs)
        # thresholds were learned with the wrong filters: learn again (keep the rescaled RRs)
        self.learn = 0; self.spki = self.npki = 0.0; self.last_slope = 0.0; self.rej = []; self.slopes = []
        nw = max(60, min(3000, round(self.seconds * fs)))
        if nw != len(old):
            self.sweep = [old[min(len(old) - 1, int(i * len(old) / nw))] for i in range(nw)]
            self.cursor = min(nw - 1, round(oc * nw / len(old)))
            self.win = nw
        self.play = []  # stale queued values were scaled for the old rate

    def _push(self, raw):
        if self.hold > 0 and self.n == self.hold:
            self._design(self.rate); self.x0 = None
        p = self.prev
        if p is not None:
            d = raw - p
            if d > 0x800000: self.off -= 0x1000000
            elif d < -0x800000: self.off += 0x1000000
        self.prev = raw
        x = raw + self.off
        if self.x0 is None: self.x0 = x
        x -= self.x0
        y = self.hp2.run(self.hp1.run(x))
        if self.use_notch: y = self.notch.run(y)
        y = self.lp.run(y)
        if self.invert: y = -y
        self.n += 1; self.since += 1
        self.ybuf.append(y)
        keep = round(self.rate * 3)
        if len(self.ybuf) > keep: del self.ybuf[:len(self.ybuf) - keep]
        self._detect(self.qlp.run(self.qhp.run(y)))
        self.stdwin.append(y)
        k1 = max(20, min(1000, round(self.rate)))
        if len(self.stdwin) > k1: del self.stdwin[:len(self.stdwin) - k1]
        shown = -y if self.flip else y
        self.env = max(self.env * 0.5 ** (1 / (self.rate * 2.5)), abs(shown))
        scale = max(self.env * 1.05, 40.0)
        v = max(-1.0, min(1.0, shown / scale)) if (self.n > self.rate * 0.5 and self.n >= self.hold) else 0.0
        self.play.append(v)
        cap = round(self.rate * 3)
        if len(self.play) > cap: del self.play[:len(self.play) - cap]
        self.tape.append(v)

    def _detect(self, q):
        fs = self.rate
        self.d.append(q)
        dd = self.d[-1] - self.d[-3]
        self.d.pop(0)
        s = dd * dd
        w = max(3, round(0.12 * fs))
        self.mwi.append(s); self.mwi_sum += s; self.slw.append(abs(dd))
        while len(self.mwi) > w:
            self.mwi_sum -= self.mwi.pop(0); self.slw.pop(0)
        m = math.sqrt(max(0.0, self.mwi_sum) / len(self.mwi))
        settle = round(fs * 0.8)
        # signal energy jumped (finger placed) -> thresholds learned on noise are useless: learn again
        self.e_fast += (m - self.e_fast) * (1.0 / (0.5 * fs))
        if self.learn < round(fs * 1.2):
            self.learn_e = max(self.learn_e, self.e_fast)
        elif self.learn_e > 0 and self.e_fast > 5 * self.learn_e and self.n - self.restart_at > 2 * fs:
            self.restart_learning()
        if self.since > 3 and self.m1 > self.m2 and self.m1 >= m and self.n >= max(self.quiet, self.hold):
            pk = self.m1
            idx = self.n - 2
            slope = max(self.slw)
            if self.since < settle:
                pass
            elif self.learn < round(fs * 1.2):
                self.spki = max(self.spki, pk); self.npki = 0.5 * self.npki + 0.05 * pk
            else:
                thr = self.npki + 0.45 * (self.spki - self.npki)
                refr = 0.22 * fs
                dt = idx - self.last_qrs
                sref = sorted(self.slopes)[len(self.slopes) // 2] if len(self.slopes) >= 3 else 0.0
                if pk > thr and dt > refr:
                    if slope < 0.4 * sref:
                        # far too gentle for a QRS (noise, P or T wave)
                        self.npki = 0.125 * pk + 0.875 * self.npki
                    elif dt < 0.42 * fs and slope < 0.5 * self.last_slope:
                        # T-wave check (Pan-Tompkins): close to the last QRS with a much smaller slope
                        self.npki = 0.125 * pk + 0.875 * self.npki
                    else:
                        self.spki = 0.125 * pk + 0.875 * self.spki
                        self.last_slope = slope
                        self.slopes.append(slope)
                        if len(self.slopes) > 8: self.slopes.pop(0)
                        self._qrs(idx)
                        self.cands = []
                else:
                    self.npki = 0.125 * pk + 0.875 * self.npki
                    if dt > 0.36 * fs:
                        self.cands.append((idx, pk, slope))
        # search-back
        if self.cands and len(self.rr) >= 2:
            tail = self.rr[-8:]
            avg = sum(tail) / len(tail)
            if (self.n - self.last_qrs) > 1.66 * avg * fs:
                thr = self.npki + 0.45 * (self.spki - self.npki)
                b = max(self.cands, key=lambda c: c[1])
                self.cands = []
                sref = sorted(self.slopes)[len(self.slopes) // 2] if len(self.slopes) >= 3 else 0.0
                if b[1] > 0.5 * thr and b[2] >= 0.4 * sref:
                    self.spki = 0.25 * b[1] + 0.75 * self.spki
                    self.last_slope = b[2]
                    self._qrs(b[0])
        # no beat for 2.5 s after learning -> thresholds were too high (e.g. a touch artefact)
        if self.learn >= round(fs * 1.2) and self.n - max(self.last_qrs, self.idle_mark) > 2.5 * fs:
            self.spki *= 0.5; self.npki *= 0.5; self.idle_mark = self.n
        if self.since >= settle and self.n >= self.hold: self.learn += 1
        self.m2, self.m1 = self.m1, m

    def _qrs(self, idx):
        fs = self.rate
        span = max(3, round(0.2 * fs))
        end = len(self.ybuf) - (self.n - 1 - idx)
        if end <= 0: return
        st = max(0, end - span)
        j = st
        for i in range(st, end):
            if abs(self.ybuf[i]) > abs(self.ybuf[j]): j = i
        r = idx - (end - 1 - j)
        amp = self.ybuf[j]
        if st < j < end - 1:
            a, b, c = abs(self.ybuf[j - 1]), abs(self.ybuf[j]), abs(self.ybuf[j + 1])
            den = a - 2 * b + c
            if den != 0: r += max(-0.5, min(0.5, 0.5 * (a - c) / den))
        if self.last_r > -1e8:
            rr = (r - self.last_r) / fs
            if 0.27 <= rr <= 2.2:
                med = sorted(self.rr)[len(self.rr) // 2] if len(self.rr) >= 3 else None
                if med is None or 0.65 * med <= rr <= 1.5 * med:
                    self.rr.append(rr)
                    if len(self.rr) > 12: self.rr.pop(0)
                    self.rrlog.append(rr)
                    self.rej = []
                else:
                    # the rhythm really changed (or the old RRs were wrong): 4 consistent rejects -> adopt them
                    self.rej.append(rr)
                    if len(self.rej) >= 4:
                        tl = self.rej[-4:]
                        mm = sum(tl) / 4
                        sd = math.sqrt(sum((x - mm) ** 2 for x in tl) / 4)
                        if sd / mm < 0.15:
                            self.rr = list(tl); self.rrlog.extend(tl); self.rej = []
        self.last_r = r
        self.last_qrs = idx
        self.pol.append(1 if amp >= 0 else -1)
        if len(self.pol) > 8: self.pol.pop(0)
        if len(self.pol) >= 6:
            sm = sum(self.pol)
            if sm <= -4: self.flip = True
            if sm >= 4: self.flip = False
        self.beat_count += 1

    # ---------- display playout ----------
    def advance(self, t):
        last = self.last_adv; self.last_adv = t
        if last is None: return
        dt = max(0.0, min(0.1, t - last))
        q = len(self.play) / self.rate
        if not self.playing:
            if q < 0.15: return
            self.playing = True
        speed = 1.0
        if q > 1.2: speed = 2.0
        elif q > 0.5: speed = 1.15
        elif q < 0.06: speed = 0.85
        self.acc += self.rate * dt * speed
        k = int(self.acc); self.acc -= k
        if k > len(self.play):
            k = len(self.play); self.acc = 0.0; self.playing = False
        for v in self.play[:k]:
            self.sweep[self.cursor] = v
            self.cursor += 1
            if self.cursor >= len(self.sweep):
                self.cursor = 0; self.full = True
        del self.play[:k]

    def take_tape(self):
        t = self.tape; self.tape = []; return t

    # ---------- outputs ----------
    def contact(self, t):
        if self.last_pkt is None or t - self.last_pkt > 1.5: return False
        if self.railing: return False
        if self.n < self.rate * 0.8: return False
        if len(self.stdwin) < 2: return False
        m = sum(self.stdwin) / len(self.stdwin)
        return math.sqrt(sum((x - m) ** 2 for x in self.stdwin) / len(self.stdwin)) > 0.8

    @property
    def bpm(self):
        if not self.rate_ok or len(self.rr) < 3: return None
        s = sorted(self.rr[-8:])
        b = 60.0 / s[len(s) // 2]
        return b if 30 <= b <= 220 else None


def ecg(ph_t, period):
    x = ph_t
    r = 0.25 * min(period, 0.9)
    g = lambda c, w, a: a * math.exp(-((x - c) / w) ** 2)
    return (g(r - 0.16, 0.025, .12) - g(r - 0.028, 0.012, .12) + g(r, 0.016, 1.0)
            - g(r + 0.03, 0.013, .25) + g(r + 0.27 * min(1, period), 0.06, TWAVE))


TWAVE = 0.45


def simulate(true_fs, bpm, seed=1, invert=False, nofinger=3.0, secs=34.0, tall_t=0.45, wrap=False, verbose=False, psize=None, drop=0.01):
    global TWAVE
    TWAVE = tall_t
    rnd = random.Random(seed)
    sig = Sig(invert=False)
    # beat schedule with HRV
    beats = []; t = 0.0
    while t < secs + 2:
        period = 60.0 / bpm * (1 + 0.04 * math.sin(t * 0.9) + 0.015 * rnd.gauss(0, 1))
        beats.append((t, period)); t += period
    bi = 0
    n_total = int(true_fs * secs)
    pkt = []; pid = 0
    t_send = 0.0
    events = []  # (arrival_time, samples, pid)
    for i in range(n_total):
        ts = i / true_fs
        while bi + 1 < len(beats) and beats[bi + 1][0] <= ts: bi += 1
        b0, per = beats[bi]
        if ts < nofinger:
            v = rnd.gauss(0, 0.004)  # electrode open: tiny noise
            raw = 8_000_000 + round(v * 3000)
        else:
            v = ecg(ts - b0, per) * (-1 if invert else 1)
            v += 0.04 * rnd.gauss(0, 1) + 0.3 * math.sin(2 * math.pi * 50 * ts) + 1.5 * math.sin(2 * math.pi * 0.3 * ts)
            # contact transient
            if ts - nofinger < 0.4: v += 6 * (1 - (ts - nofinger) / 0.4)
            raw = 8_000_000 + round(3000 * v)
        if wrap: raw &= 0xFFFFFF
        pkt.append(raw)
        if len(pkt) >= (psize or rnd.randint(18, 75)):
            events.append((ts + 0.03 + abs(rnd.gauss(0, 0.04)), pkt, pid & 0xff)); pid += 1; pkt = []
    # BLE bursts: deliver groups together sometimes
    for k in range(len(events)):
        if rnd.random() < 0.15 and k + 1 < len(events):
            events[k] = (events[k + 1][0], events[k][1], events[k][2])
    # drop 1% packets
    events = [e for e in events if rnd.random() > drop]
    # BLE notifications stay in order: arrival times are non-decreasing
    mx = 0.0
    for k in range(len(events)):
        mx = max(mx, events[k][0]); events[k] = (mx, events[k][1], events[k][2])
    # run: ticks every 33 ms, deliver packets that arrived
    ei = 0; t = 0.0
    contact_since = None; measuring_from = None; no_contact_since = 0.0
    bpm_log = []; head = []
    while t < secs:
        while ei < len(events) and events[ei][0] <= t:
            sig.add_packet(events[ei][1], events[ei][0], events[ei][2]); ei += 1
        sig.advance(t)
        c = sig.contact(t)
        if c:
            if contact_since is None:
                if no_contact_since is not None and t - no_contact_since >= 0.6:
                    sig.restart_learning()
                contact_since = t; no_contact_since = None
            if measuring_from is None and t - contact_since >= 1.2:
                measuring_from = t; sig.rrlog = []
        else:
            contact_since = None
            if no_contact_since is None: no_contact_since = t
        sig.take_tape()
        if measuring_from is not None:
            bpm_log.append((t, sig.bpm))
            head.append((t, sig.cursor, sig.full))
        t += 0.033
    return sig, bpm_log, head, measuring_from


def check(true_fs, bpm, **kw):
    sig, log, head, mfrom = simulate(true_fs, bpm, **kw)
    ok = True; why = []
    if mfrom is None:
        return False, 'no contact'
    # bpm: from 6 s after contact every value must be within 6 %
    late = [b for (t, b) in log if t - 3.0 >= 8]  # finger touches at 3.0 s
    bad = [b for b in late if b is None or abs(b - bpm) / bpm > 0.06]
    first = next((t - mfrom for (t, b) in log if b is not None), None)
    any_bad = [b for (t, b) in log if b is not None and abs(b - bpm) / bpm > 0.12]
    if bad: ok = False; why.append(f'late-bad={len(bad)}/{len(late)} e.g. {bad[:3]}')
    if any_bad: ok = False; why.append(f'early-wrong={[round(x) for x in any_bad[:4]]}')
    # display head must sweep the whole screen
    wraps = sum(1 for k in range(1, len(head)) if head[k][1] < head[k - 1][1] - sig.win * 0.5)
    if wraps < 3: ok = False; why.append(f'sweep wraps={wraps}')
    stuck = max((head[k][1] for k in range(len(head))), default=0)
    if stuck < sig.win * 0.9: ok = False; why.append(f'head max={stuck}/{sig.win}')
    st = 'OK' if ok else 'FAIL ' + '; '.join(why)
    return ok, f'first bpm after {first and round(first,1)}s  final={sig.bpm and round(sig.bpm,1)} rate={sig.rate} beats={sig.beat_count} {st}'


if __name__ == '__main__':
    allok = True
    for fs in (255, 250, 256, 200, 128, 512):
        for bpm in (55, 72, 95, 130):
            for seed in (1, 2, 3):
                ps = {1: 40, 2: 81, 3: None}[seed]
                ok, msg = check(fs, bpm, seed=seed, invert=(seed == 2), wrap=(fs == 250), psize=ps)
                allok &= ok
                print(f'fs={fs:3} bpm={bpm:3} seed={seed} pkt={ps}: {msg}')
    print('ALL OK' if allok else 'SOME FAILED')
