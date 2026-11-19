#!/usr/bin/env python3
"""程序生成音效（不進 git），輸出到 game/assets/generated/sfx/*.wav。

只用標準函式庫（wave、math、random），固定亂數種子，每次產生的檔案相同。
每一個音的樣子寫在它自己的函式說明裡；這裡只列有哪些（main() 的順序）：
- 戰鬥：blunt／blunt_weak（敵人倒地、樹人的下砸）、cut_hit／cut_heavy（諾恩的劍砍中）、slash（揮劍）、whoosh（閃避）、
  iron_clang、interrupt、brace_warn、poison_burst（poison_hiss 只是它的一層）、curse_sting＋reversal_shatter（反轉回饋的前後半）
- 腳步：step_dirt／step_stone／step_wood、treant_step、golem_step
- 席菈：vial_shot／vial_shatter／vial_load；glass_clink（喝藥）
- 森林：forest_night（整片的夜晚）、swamp_bubble、campfire_crackle、vent_hiss（從東西發出來的循環）、
  mushroom_pick、fruit_bite、web_stick、wolf_bite、chest_open、distant_scream
- 祭壇：altar_air（整片）、boss_theme（Boss 戰配樂）、golem_roar、gaze_charge／gaze_beam、golem_slam、
  core_glow、stone_deflect、core_shatter、core_land、stone_peel（席菈的石殼剝落）
- 公會：hall_murmur（人聲）、guild_theme（大廳的配樂）、crystal_alarm、crowd_laugh、door_creak／door_shut、chapter_end_theme（「第一章　完」）
- 介面與漫符：ui_tick、title_theme（標題配樂）、manga_shock／manga_sparkle／manga_drop／manga_question
- 循環的（環境音、配樂）頭尾交叉淡化，Ambience 設成整段循環；bell() 只給配樂裡的鐘聲用。
授權：程序生成，無外部素材（docs/CREDITS.md）。
"""
import math
import random
import struct
import sys
import wave
from pathlib import Path

RATE = 44100
ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "game" / "assets" / "generated" / "sfx"


def write(name, samples):
    OUT.mkdir(parents=True, exist_ok=True)
    peak = max(1e-9, max(abs(s) for s in samples))
    k = 0.89 / peak
    path = OUT / f"{name}.wav"
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s * k)) * 32767)) for s in samples))
    return path


def onepole_lp(xs, cutoff):
    a = math.exp(-2.0 * math.pi * cutoff / RATE)
    y = 0.0
    out = []
    for x in xs:
        y = (1 - a) * x + a * y
        out.append(y)
    return out


def hp(xs, cutoff):
    low = onepole_lp(xs, cutoff)
    return [x - l for x, l in zip(xs, low)]


def noise(n, rng):
    return [rng.uniform(-1.0, 1.0) for _ in range(n)]


def bell(fundamental, seconds, beat=0.0):
    # 鐘的泛音比例（hum、prime、tierce、quint、nominal…）與相對強度、衰減
    partials = [(0.5, 0.35, 0.9), (1.0, 0.6, 1.4), (1.183, 0.4, 2.0), (1.506, 0.25, 2.6),
                (2.0, 0.45, 3.2), (2.514, 0.18, 4.5), (2.662, 0.15, 5.0), (3.011, 0.1, 6.0), (4.166, 0.06, 8.0)]
    n = int(seconds * RATE)
    out = [0.0] * n
    for ratio, amp, decay in partials:
        f = fundamental * ratio
        for i in range(n):
            t = i / RATE
            env = math.exp(-decay * t / seconds * 2.2)
            wob = 1.0 + (0.12 * math.sin(2 * math.pi * beat * t) if beat else 0.0)
            out[i] += amp * env * wob * math.sin(2 * math.pi * f * t)
    # 敲擊瞬間的金屬噪音
    rng = random.Random(9)
    strike = hp(noise(int(0.03 * RATE), rng), 2500)
    for i, s in enumerate(strike):
        out[i] += 0.5 * s * (1 - i / len(strike))
    # 起音 3 ms
    for i in range(int(0.003 * RATE)):
        out[i] *= i / (0.003 * RATE)
    return out


def thump(seconds, f0, f1, crack=0.0, seed=1):
    rng = random.Random(seed)
    n = int(seconds * RATE)
    out = []
    phase = 0.0
    nz = onepole_lp(noise(n, rng), 900)
    for i in range(n):
        t = i / RATE
        f = f1 + (f0 - f1) * math.exp(-t * 30)
        phase += 2 * math.pi * f / RATE
        env = math.exp(-t * 18)
        out.append(0.9 * env * math.sin(phase) + 0.6 * nz[i] * math.exp(-t * 40))
    if crack:
        c = hp(noise(int(0.04 * RATE), rng), 3000)
        for i, s in enumerate(c):
            out[i] += crack * s * math.exp(-i / RATE * 90)
    return out


def swish(seconds, lo, hi, seed, rise=0.35, metal=0.0):
    rng = random.Random(seed)
    n = int(seconds * RATE)
    band = onepole_lp(hp(noise(n, rng), lo), hi)
    out = []
    for i in range(n):
        t = i / seconds / RATE
        env = (t / rise) if t < rise else math.exp(-(t - rise) * 6)
        s = band[i] * env
        if metal:
            s += metal * env * math.sin(2 * math.pi * 3150 * i / RATE) * math.exp(-t * 4)
        out.append(s)
    return out


def scrape(seconds=0.42, seed=9):
    """搬瓦礫：石頭互相刮、碎石滾落（帶顆粒的中頻雜訊＋幾下小碰撞）。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    band = onepole_lp(hp(noise(n, rng), 280), 2600)
    out = []
    grain = 0.0
    for i in range(n):
        t = i / RATE
        if rng.random() < 0.004:
            grain = rng.uniform(0.6, 1.0)
        grain *= 0.9993
        env = min(t / 0.04, 1.0) * math.exp(-max(t - 0.12, 0.0) * 7)
        out.append(band[i] * env * (0.35 + grain))
    for k in range(3):
        start = int(rng.uniform(0.05, seconds - 0.12) * RATE)
        hit = thump(0.1, rng.uniform(220, 320), 90, crack=0.4, seed=seed + k + 1)
        for j, v in enumerate(hit):
            if start + j < n:
                out[start + j] += 0.35 * v
    return out


def clang(seconds=1.1, seed=11):
    """鐵架撞上石拱：不和諧的金屬泛音（快速衰減）＋一下沉重的撞擊。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    partials = [(410, 1.0, 5.0), (1130, 0.6, 7.0), (1870, 0.45, 9.0), (2930, 0.3, 12.0), (4410, 0.18, 16.0)]
    out = [0.0] * n
    for f, a, d in partials:
        f *= rng.uniform(0.98, 1.02)
        for i in range(n):
            t = i / RATE
            out[i] += a * math.exp(-t * d) * math.sin(2 * math.pi * f * t)
    hit = thump(0.35, 120, 45, crack=1.0, seed=seed + 1)
    for i, v in enumerate(hit):
        out[i] = 0.35 * out[i] + 0.9 * v
    return out


def ui_tick(seconds=0.14, seed=17):
    """選單切換值：很小的一聲高音鐘「叮」＋極短的木頭「喀」，跟遊戲的鐘同一個語彙、不搶戲。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    click = onepole_lp(hp(noise(int(0.004 * RATE), rng), 1500), 6000)
    out = []
    for i in range(n):
        t = i / RATE
        ping = (math.sin(2 * math.pi * 1568.0 * t) * 0.55 + math.sin(2 * math.pi * 1568.0 * 2.41 * t) * 0.2) * math.exp(-t * 38.0)
        attack = min(1.0, t / 0.0015)
        c = click[i] * 0.5 if i < len(click) else 0.0
        out.append(ping * attack + c)
    return out


def svf_band(xs, freq_at, damping):
    """狀態變數濾波器的帶通輸出；freq_at(i) 回傳第 i 個樣本的中心頻率（可以隨時間滑動）。"""
    low = band = 0.0
    out = []
    for i, x in enumerate(xs):
        fc = 2.0 * math.sin(math.pi * min(freq_at(i), RATE / 6.0) / RATE)
        high = x - low - damping * band
        band += fc * high
        low += fc * band
        out.append(band)
    return out


def _loop_crossfade(out, n, fade):
    looped = out[:n]
    for i in range(fade):
        w = i / fade
        looped[i] = out[i] * w + out[n + i] * (1.0 - w)
    return looped


def _far_voice(total, rng, f0, formant_lo, formant_hi):
    """遠處一個人在講話（聽不出內容）：鋸齒波的聲帶（每個音節音高滑一點）→ 一個共振峰（每個音節換一個母音）。
    音節一個個起伏，一句 3～9 個音節，句子之間停下來換氣、聽別人講。"""
    env = [0.0] * total
    form = [0.0] * total
    pitch = [0.0] * total
    cur_f = rng.uniform(formant_lo, formant_hi)
    cur_p = f0
    i = int(rng.uniform(0.0, 1.4) * RATE)
    while i < total:
        for _ in range(rng.randint(3, 9)):
            dur = int(rng.uniform(0.11, 0.26) * RATE)
            amp = rng.uniform(0.45, 1.0)
            nf = rng.uniform(formant_lo, formant_hi)
            npitch = f0 * rng.uniform(0.86, 1.2)
            for k in range(min(dur, total - i)):
                w = k / dur
                env[i + k] = amp * math.sin(math.pi * w)
                form[i + k] = cur_f + (nf - cur_f) * w
                pitch[i + k] = cur_p + (npitch - cur_p) * w
            cur_f, cur_p = nf, npitch
            i += dur + int(rng.uniform(0.0, 0.05) * RATE)
            if i >= total:
                break
        i += int(rng.uniform(0.35, 1.5) * RATE)
    out = []
    phase = 0.0
    low = band = 0.0
    fc = 2.0 * math.pi * cur_f / RATE
    for j in range(total):
        e = env[j]
        src = 0.0
        if e > 0.0:
            fc = 2.0 * math.pi * form[j] / RATE
            phase += pitch[j] / RATE
            phase -= int(phase)
            src = (2.0 * phase - 1.0) * e
        high = src - low - 0.3 * band
        band += fc * high
        low += fc * band
        out.append(band)
    return out


def hall_murmur(seconds=12.0, seed=131):
    """公會大廳的人聲（可循環 12 秒）：六個人在別桌講話疊起來（聽不出內容的嗡嗡聲，有起伏、不會整片安靜）
    ＋屋裡低低的空氣聲＋兩道短回音（木牆）＋偶爾一聲很小的杯子、餐具碰撞。頭尾交叉淡化。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    fade = int(1.2 * RATE)
    total = n + fade
    crowd = [0.0] * total
    for f0 in (104.0, 127.0, 149.0, 183.0, 208.0, 236.0):
        gain = rng.uniform(0.5, 1.0)
        voice = _far_voice(total, rng, f0, 290.0, 820.0)
        for i in range(total):
            crowd[i] += voice[i] * gain
    # 隔著幾張桌子：高頻收掉
    crowd = onepole_lp(onepole_lp(crowd, 2400), 3200)
    room = onepole_lp(onepole_lp(hp(noise(total, rng), 60), 260), 340)
    out = [crowd[i] + room[i] * 2.2 for i in range(total)]
    # 木牆的兩道短回音
    for delay, amount in ((int(0.083 * RATE), 0.3), (int(0.137 * RATE), 0.22)):
        for i in range(delay, total):
            out[i] += out[i - delay] * amount
    peak = max(abs(v) for v in out) or 1.0
    out = [v / peak for v in out]
    # 偶爾的小碰撞聲（杯子、餐具）：很小聲，不落在交叉淡化的那一段
    for _ in range(4):
        at = int(rng.uniform(0.8, seconds - 1.0) * RATE)
        freq = rng.uniform(1900.0, 3300.0)
        amp = rng.uniform(0.05, 0.11)
        for k in range(int(0.22 * RATE)):
            tt = k / RATE
            out[at + k] += amp * math.exp(-tt * 34.0) * (math.sin(2 * math.pi * freq * tt) + 0.5 * math.sin(2 * math.pi * freq * 2.31 * tt))
    looped = _loop_crossfade(out, n, fade)
    peak = max(abs(v) for v in looped) or 1.0
    return [v / peak * 0.7 for v in looped]


def _wavetable(partials, size=2048):
    """一個週期的波形表（整數倍泛音），長音用查表比逐點算 sin 快得多。"""
    return [sum(a * math.sin(2 * math.pi * k * i / size) for k, a in partials) for i in range(size)]


def title_theme(seconds=24.0, seed=67):
    """標題畫面的配樂：長音鋪底＋霧裡遠遠的鐘聲動機（往下走的三聲，第二次落得更低）。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    fade = int(2.0 * RATE)
    total = n + fade
    table = _wavetable([(1, 1.0), (2, 0.45), (3, 0.22), (4, 0.1), (5, 0.05)])
    size = len(table)
    drone = [0.0] * total
    # D2、A2、D3；每個音兩個聲部差零點幾 Hz，慢慢拍頻
    for f, amp in [(73.42, 0.5), (73.61, 0.42), (110.0, 0.3), (110.21, 0.26), (146.83, 0.12), (146.6, 0.1)]:
        ph = rng.random() * size
        step = f * size / RATE
        for i in range(total):
            drone[i] += amp * table[int(ph) % size]
            ph += step
    for i in range(total):
        t = i / RATE
        drone[i] *= 0.68 + 0.32 * math.sin(2 * math.pi * t / 12.0 - 1.2)  # 12 秒一次漲落，24 秒剛好兩次
    drone = onepole_lp(onepole_lp(drone, 650), 900)
    dpeak = max(abs(v) for v in drone) or 1.0
    out = [v / dpeak * 0.42 for v in drone]
    # 鐘聲動機：同一個音只合成一次
    bells = {}
    motif = [(2.0, 293.66, 1.0), (3.6, 261.63, 0.82), (5.2, 220.0, 0.9),
             (14.0, 293.66, 0.75), (15.6, 261.63, 0.66), (17.6, 174.61, 1.0)]
    for at, f, gain in motif:
        if f not in bells:
            b = onepole_lp(bell(f, 4.5), 2400)
            bpeak = max(abs(v) for v in b) or 1.0
            bells[f] = [v / bpeak for v in b]
        b = bells[f]
        # 原聲＋三個越來越小、越來越晚的回音（霧裡、石牆之間）
        for delay, tap in [(0.0, 0.34), (0.43, 0.12), (1.01, 0.06), (1.67, 0.03)]:
            start = int((at + delay) * RATE)
            g = gain * tap
            for j, v in enumerate(b):
                if start + j >= total:
                    break
                out[start + j] += g * v
    looped = _loop_crossfade(out, n, fade)
    peak = max(abs(v) for v in looped) or 1.0
    return [v / peak * 0.7 for v in looped]


def chapter_end_theme(seconds=28.0, seed=97):
    """「第一章　完」的配樂（回答標題的鐘聲）：F2＋C3 的長音、往上走的鐘聲（回答標題往下走的那三聲），第二次停在 D4。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    fade = int(2.5 * RATE)
    total = n + fade
    table = _wavetable([(1, 1.0), (2, 0.38), (3, 0.16), (4, 0.06)])
    size = len(table)
    drone = [0.0] * total
    for f, amp in [(87.31, 0.5), (87.47, 0.42), (130.81, 0.32), (130.6, 0.27), (174.61, 0.12), (220.0, 0.07)]:
        ph = rng.random() * size
        step = f * size / RATE
        for i in range(total):
            drone[i] += amp * table[int(ph) % size]
            ph += step
    for i in range(total):
        t = i / RATE
        drone[i] *= 0.7 + 0.3 * math.sin(2 * math.pi * t / 14.0 - 1.0)  # 14 秒一次，28 秒剛好兩次
    drone = onepole_lp(onepole_lp(drone, 750), 950)
    dpeak = max(abs(v) for v in drone) or 1.0
    out = [v / dpeak * 0.42 for v in drone]
    bells = {}
    motif = [(2.5, 174.61, 0.85), (4.1, 220.0, 0.8), (5.9, 261.63, 0.9),
             (15.5, 220.0, 0.7), (17.1, 261.63, 0.75), (19.4, 293.66, 1.0)]
    for at, f, gain in motif:
        if f not in bells:
            b = onepole_lp(bell(f, 4.5), 2600)
            bpeak = max(abs(v) for v in b) or 1.0
            bells[f] = [v / bpeak for v in b]
        b = bells[f]
        for delay, tap in [(0.0, 0.32), (0.43, 0.11), (1.01, 0.055), (1.67, 0.028)]:
            start = int((at + delay) * RATE)
            g = gain * tap
            for j, v in enumerate(b):
                if start + j >= total:
                    break
                out[start + j] += g * v
    looped = _loop_crossfade(out, n, fade)
    peak = max(abs(v) for v in looped) or 1.0
    return [v / peak * 0.7 for v in looped]


def _step_env(n, attack, decay):
    return [min(1.0, (i / RATE) / attack) * math.exp(-(i / RATE) * decay) for i in range(n)]


def step_dirt(seed=75):
    """踩在森林的土上：軟軟的低頻悶聲＋幾片乾葉子碎掉的細響（比雪稀、比較乾）。"""
    rng = random.Random(seed)
    n = int(0.15 * RATE)
    leaves = [0.0] * n
    for _ in range(14):
        at = int(abs(rng.gauss(0.025, 0.03)) * RATE)
        amp = rng.uniform(0.3, 1.0)
        width = int(rng.uniform(0.002, 0.006) * RATE)
        for j in range(width):
            if at + j >= n:
                break
            leaves[at + j] += amp * rng.uniform(-1, 1) * (1 - j / width)
    leaves = onepole_lp(hp(leaves, 1400), 6000)
    thud = onepole_lp(noise(n, rng), 220)
    out = []
    for i in range(n):
        t = i / RATE
        body = math.sin(2 * math.pi * (95 - 120 * t) * t) * math.exp(-t * 45)
        out.append(body * 0.5 + thud[i] * 2.6 + leaves[i] * 0.55)
    env = _step_env(n, 0.004, 22)
    return [out[i] * env[i] for i in range(n)]


def step_stone(seed=73):
    """踩在石板上：很短的低頻「咚」＋一點砂粒的擦聲。"""
    rng = random.Random(seed)
    n = int(0.12 * RATE)
    out = []
    grit = hp(noise(n, rng), 2500)
    for i in range(n):
        t = i / RATE
        thump = math.sin(2 * math.pi * (130 - 300 * t) * t) * math.exp(-t * 60)
        out.append(thump * 0.9 + grit[i] * 0.25 * math.exp(-t * 90))
    env = _step_env(n, 0.002, 18)
    return [out[i] * env[i] for i in range(n)]


def step_wood(seed=79):
    """踩在木板地上：中空的「叩」＋一點木板的吱。"""
    rng = random.Random(seed)
    n = int(0.15 * RATE)
    out = []
    click = onepole_lp(noise(n, rng), 3000)
    for i in range(n):
        t = i / RATE
        body = math.sin(2 * math.pi * 182 * t) * math.exp(-t * 38) * 0.8 + math.sin(2 * math.pi * 421 * t) * math.exp(-t * 70) * 0.45
        creak = math.sin(2 * math.pi * (760 + 900 * t) * t) * math.exp(-((t - 0.05) / 0.025) ** 2) * 0.05
        out.append(body + click[i] * 0.3 * math.exp(-t * 200) + creak)
    env = _step_env(n, 0.002, 10)
    return [out[i] * env[i] for i in range(n)]


def poison_hiss(seconds=0.9, seed=107):
    """毒爆的嘶聲那一層：高頻的嘶聲（滑動的帶通噪音＋一點更高的氣聲），快起慢落＋一聲很短的低頻「噗」。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    src = noise(n, rng)
    band = svf_band(src, lambda i: 5200.0 - 1800.0 * (i / n), 0.45)
    air = hp(src, 6000)
    out = []
    for i in range(n):
        t = i / n
        env = min(t / 0.04, 1.0) * math.exp(-t * 4.2)
        s = (band[i] * 0.9 + air[i] * 0.25) * env
        s += 0.5 * math.sin(2 * math.pi * 95 * i / RATE) * math.exp(-t * 18)
        out.append(s)
    return out


def poison_burst(seconds=0.75, seed=149):
    """毒爆（D-245）：諾恩把身上的毒一次放出去。一聲往下掉的悶響（有份量）＋往外散開的嘶聲（聽得出是毒，不是鈍擊）。"""
    low = thump(seconds, 190, 42, crack=0.5, seed=seed)
    hiss = poison_hiss(seconds, seed=seed + 2)
    n = min(len(low), len(hiss))
    return [1.0 * low[i] + 0.8 * hiss[i] for i in range(n)]


def glass_clink(seconds=0.42, seed=113):
    """玻璃瓶互相碰到（D-209，藥箱）：三下很短的高音「叮」（玻璃的非諧波泛音，衰減快），最後一下最輕。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    out = [0.0] * n
    tick = onepole_lp(hp(noise(int(0.003 * RATE), rng), 2500), 9000)
    for at, f, gain in [(0.0, 3320.0, 1.0), (0.07, 4150.0, 0.7), (0.13, 2890.0, 0.4)]:
        start = int(at * RATE)
        for j in range(int(0.26 * RATE)):
            if start + j >= n:
                break
            t = j / RATE
            v = math.sin(2 * math.pi * f * t) + 0.5 * math.sin(2 * math.pi * f * 2.32 * t) + 0.25 * math.sin(2 * math.pi * f * 3.9 * t)
            c = tick[j] * 0.6 if j < len(tick) else 0.0
            out[start + j] += gain * (0.3 * v * math.exp(-t * 42) * min(1.0, t / 0.0008) + c)
    peak = max(abs(v) for v in out) or 1.0
    return [v / peak * 0.6 for v in out]


def interrupt_crack(seconds=0.2, seed=137):
    """出手被打斷（D-241）：棍子被敲偏的一聲短「喀」——乾的高頻一下＋很短的木頭共鳴，沒有低頻
    （跟命中的「咚」分得開：聽到這一聲＝他那一招沒了）。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    click = onepole_lp(hp(noise(n, rng), 1800), 8000)
    out = []
    for i in range(n):
        t = i / RATE
        wood = math.sin(2 * math.pi * 620 * t) * math.exp(-t * 26) + 0.5 * math.sin(2 * math.pi * 1480 * t) * math.exp(-t * 42)
        out.append(0.8 * click[i] * math.exp(-t * 70) + 0.6 * wood * min(1.0, t / 0.001))
    return out


def brace_warn(seconds=0.6, seed=139):
    """硬撐（D-241）：「這一下打不斷了，該閃」的警告。兩段：往上滑的低吼（帶泛音的 105→230 Hz，越來越大），
    收在一聲短而亮的金屬音（非諧波，像鐵箍被燒紅繃緊）。跟所有命中聲、前兆的「呼」都不像——只在這個時候出現。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    breath = svf_band(noise(n, rng), lambda i: 700.0 + 1500.0 * (i / n), 0.5)
    out = []
    phase = 0.0
    ring_at = 0.36
    for i in range(n):
        t = i / RATE
        u = min(t / ring_at, 1.0)
        f = 105.0 + 125.0 * u * u
        phase += 2 * math.pi * f / RATE
        growl = sum(math.sin(phase * k) / k for k in (1, 2, 3, 4, 5, 7))
        # 一點顫（28 Hz）：聽起來像咬牙，不是合成器的滑音
        growl *= 1.0 + 0.35 * math.sin(2 * math.pi * 28 * t)
        env = (u ** 1.5) if t < ring_at else math.exp(-(t - ring_at) * 16)
        s = 0.5 * growl * env + 0.35 * breath[i] * env
        if t >= ring_at - 0.02:
            r = t - (ring_at - 0.02)
            ring = math.sin(2 * math.pi * 1660 * r) + 0.6 * math.sin(2 * math.pi * 2490 * 1.07 * r) + 0.35 * math.sin(2 * math.pi * 4210 * r)
            s += 0.55 * ring * math.exp(-r * 14) * min(1.0, r / 0.002)
        out.append(s)
    for i in range(int(0.004 * RATE)):
        out[i] *= i / (0.004 * RATE)
    return out


def curse_sting(seconds=0.32, seed=151):
    """吃到異常狀態的那一下（反轉回饋的前半）：一聲往下沉、越來越大的暗「嗚」，尾巴突然收掉——接著就是碎裂聲。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    air = onepole_lp(hp(noise(n, rng), 300), 1800)
    out = []
    phase = 0.0
    for i in range(n):
        k = i / n
        f = 190.0 - 110.0 * k
        phase += 2 * math.pi * f / RATE
        swell = k * k * (1.0 - max(0.0, (k - 0.93) / 0.07))
        trem = 0.75 + 0.25 * math.sin(2 * math.pi * 31.0 * i / RATE)
        out.append(swell * (0.8 * trem * (math.sin(phase) + 0.4 * math.sin(phase * 1.5)) + 0.5 * air[i]))
    return out


def reversal_shatter(seconds=1.25, seed=157):
    """反轉成立的那一下：玻璃碎裂（一聲乾的爆裂＋十幾片碎片的高音「叮」散開）→ 往上走的三聲金色鐘音（D、A、D）。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    out = [0.0] * n
    burst = hp(noise(int(0.09 * RATE), rng), 2800)
    for i, v in enumerate(burst):
        out[i] += 0.9 * v * math.exp(-i / RATE * 55)
    for k in range(14):
        start = int(rng.uniform(0.0, 0.3) * RATE)
        f = rng.uniform(2600.0, 7200.0)
        gain = 0.5 * (1.0 - k / 20.0)
        decay = rng.uniform(32.0, 60.0)
        for j in range(int(0.16 * RATE)):
            if start + j >= n:
                break
            t = j / RATE
            out[start + j] += gain * math.exp(-t * decay) * (math.sin(2 * math.pi * f * t) + 0.5 * math.sin(2 * math.pi * f * 2.32 * t))
    for at, f, gain in [(0.04, 1174.7, 0.5), (0.11, 1760.0, 0.45), (0.18, 2349.3, 0.55)]:
        start = int(at * RATE)
        for j in range(n - start):
            t = j / RATE
            env = min(1.0, t / 0.004) * math.exp(-t * 4.2)
            out[start + j] += gain * env * (math.sin(2 * math.pi * f * t) + 0.3 * math.sin(2 * math.pi * f * 2.0 * t) + 0.12 * math.sin(2 * math.pi * f * 3.01 * t))
    return out


def _cut(seconds, seed, body_f, body_end, body_decay, slice_gain, wet_gain, ring, crunch):
    """劍砍進敵人身上（諾恩的鏽劍）：刃口切進去的「嚓」（很短的高頻帶通雜訊，前 3 ms 最尖）＋
    砍進肉／黏液的濕悶聲（低通雜訊，比刃口晚 6 ms）＋身體被砍中的低頻「咚」（往下滑的正弦）＋
    鏽鐵的一點餘響（不和諧的幾個泛音，收尾那一刀比較長）＋（收尾才有）碎裂的「喀啦」。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    out = [0.0] * n
    edge = onepole_lp(hp(noise(int(0.05 * RATE), rng), 2600), 7800)
    for i, v in enumerate(edge):
        t = i / RATE
        out[i] += slice_gain * v * min(1.0, t / 0.0015) * math.exp(-t * 70)
    wet = onepole_lp(hp(noise(n, rng), 180), 1300)
    lag = int(0.006 * RATE)
    for i in range(n - lag):
        t = i / RATE
        out[i + lag] += wet_gain * wet[i] * min(1.0, t / 0.004) * math.exp(-t * 26)
    phase = 0.0
    for i in range(n):
        t = i / RATE
        f = body_end + (body_f - body_end) * math.exp(-t * 28)
        phase += 2 * math.pi * f / RATE
        out[i] += 0.95 * math.sin(phase) * min(1.0, t / 0.002) * math.exp(-t * body_decay)
    for f, gain, decay in ring:
        for i in range(n):
            t = i / RATE
            out[i] += gain * math.sin(2 * math.pi * f * t) * min(1.0, t / 0.003) * math.exp(-t * decay)
    for k in range(crunch):
        start = int((0.012 + rng.uniform(0.0, 0.07)) * RATE)
        c = hp(noise(int(0.018 * RATE), rng), 1400)
        g = 0.55 * (1.0 - k / (crunch + 2.0))
        for j, v in enumerate(c):
            if start + j < n:
                out[start + j] += g * v * math.exp(-j / RATE * 140)
    fade = int(0.03 * RATE)
    for i in range(fade):
        out[n - 1 - i] *= i / fade
    return out


def cut_hit(seed=181):
    """平常的一刀砍中（第一、二下）：短、乾、尖——一秒砍三四刀也不糊。"""
    return _cut(0.26, seed, body_f=150.0, body_end=70.0, body_decay=24.0, slice_gain=0.75, wet_gain=0.85,
                ring=[(2380.0, 0.05, 30.0), (3710.0, 0.035, 38.0)], crunch=0)


def cut_heavy(seed=191):
    """收尾那一刀、砍在破綻上：低一個八度的「咚」拖得比較長、刃口更響、幾聲碎裂的「喀啦」、
    鏽鐵的餘響 0.4 秒——比平常的那一聲重，但不像鐘錘（以前借 `blunt_weak`，那是敲鐘的鈍擊）。"""
    return _cut(0.55, seed, body_f=118.0, body_end=44.0, body_decay=11.0, slice_gain=0.9, wet_gain=1.0,
                ring=[(1870.0, 0.07, 9.0), (2960.0, 0.05, 12.0), (4610.0, 0.03, 16.0)], crunch=5)


def vial_shot(seconds=0.42, seed=167):
    """席菈的手弩射出一瓶藥：弓弦放開的「繃」（撥弦：低音很快往下掉、帶泛音）＋彈簧推桿「啵嗯」一下＋木頭弩身的一聲「喀」，
    後面拖一點點藥瓶飛走的風聲。跟諾恩的揮劍（帶金屬的長風聲）分得開。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    out = [0.0] * n
    phase = 0.0
    for i in range(n):
        t = i / RATE
        f = 150.0 + 140.0 * math.exp(-t * 55)
        phase += 2 * math.pi * f / RATE
        string = (math.sin(phase) + 0.45 * math.sin(phase * 2.0) + 0.2 * math.sin(phase * 3.0)) * math.exp(-t * 24)
        spring = math.sin(2 * math.pi * (620 + 260 * math.sin(2 * math.pi * 38 * t)) * t) * math.exp(-t * 34) * 0.18
        out[i] = string * 0.75 + spring
    clack = onepole_lp(hp(noise(int(0.012 * RATE), rng), 1800), 7000)
    for i, v in enumerate(clack):
        out[i] += 0.9 * v * (1 - i / len(clack))
    air = swish(seconds - 0.04, 500, 2600, seed + 1, rise=0.25)
    for i, v in enumerate(air):
        out[i + int(0.04 * RATE)] += 0.35 * v
    for i in range(int(0.0015 * RATE)):
        out[i] *= i / (0.0015 * RATE)
    return out


def vial_shatter(seconds=0.55, seed=173):
    """藥瓶砸在諾恩身上碎掉：一聲小小的玻璃「啵」（爆開）＋五六片碎玻璃的「叮」＋藥水潑開的濕聲（低通的雜訊、有幾個咕嘟）。
    比反轉的碎裂聲小、短、沒有鐘——它在前面，0.3 秒後反轉的碎裂聲才來。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    out = [0.0] * n
    pop = hp(noise(int(0.03 * RATE), rng), 2200)
    for i, v in enumerate(pop):
        out[i] += 0.8 * v * math.exp(-i / RATE * 120)
    for k in range(6):
        start = int(rng.uniform(0.0, 0.08) * RATE)
        f = rng.uniform(3000.0, 6200.0)
        gain = 0.32 * (1.0 - k / 9.0)
        for j in range(int(0.12 * RATE)):
            if start + j >= n:
                break
            t = j / RATE
            out[start + j] += gain * math.exp(-t * 70) * (math.sin(2 * math.pi * f * t) + 0.4 * math.sin(2 * math.pi * f * 2.41 * t))
    splash = onepole_lp(hp(noise(n, rng), 250), 1500)
    for i in range(n):
        t = i / RATE
        env = min(1.0, t / 0.01) * math.exp(-t * 9)
        out[i] += 0.9 * splash[i] * env
    for at, f in [(0.06, 420.0), (0.13, 520.0), (0.21, 380.0)]:
        start = int(at * RATE)
        for j in range(int(0.05 * RATE)):
            if start + j >= n:
                break
            t = j / RATE
            # 咕嘟：往上滑的短正弦（氣泡）
            out[start + j] += 0.22 * math.sin(2 * math.pi * (f + 2400 * t) * t) * math.sin(math.pi * j / (0.05 * RATE))
    return out


def vial_load(seconds=0.3, seed=179):
    """席菈把下一瓶裝好：試管卡進槽裡的「喀、喀嚓」（兩下乾的機關聲，第二下比較響）＋玻璃輕輕「叮」一下。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    out = [0.0] * n
    for at, gain, body in [(0.0, 0.55, 760.0), (0.085, 1.0, 610.0)]:
        start = int(at * RATE)
        click = onepole_lp(hp(noise(int(0.006 * RATE), rng), 2500), 8000)
        for j, v in enumerate(click):
            out[start + j] += gain * v * (1 - j / len(click))
        for j in range(int(0.05 * RATE)):
            t = j / RATE
            out[start + j] += gain * 0.3 * math.sin(2 * math.pi * body * t) * math.exp(-t * 90)
    start = int(0.12 * RATE)
    for j in range(n - start):
        t = j / RATE
        out[start + j] += 0.12 * math.exp(-t * 30) * (math.sin(2 * math.pi * 3720 * t) + 0.5 * math.sin(2 * math.pi * 8630 * t))
    return out


def crystal_alarm(seconds=2.4, seed=163):
    """適性測試水晶的警報（公會大廳，劇本節點 1）：刺耳的兩個音來回跳（每 0.16 秒換一次），帶玻璃的泛音，
    一開始最大聲、後面慢慢小下去——「測到不該有的結果」的聲音，跟戰鬥裡的每一種聲音都不像。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / RATE
        hi = int(t / 0.16) % 2 == 0
        f = 1480.0 if hi else 1110.0
        phase += 2 * math.pi * f / RATE
        # 方波味（奇次泛音）＋一點玻璃的高音
        tone = sum(math.sin(phase * k) / k for k in (1, 3, 5, 7))
        glass = 0.3 * math.sin(phase * 2.76) + 0.18 * math.sin(phase * 5.4)
        gate = min(1.0, (t % 0.16) / 0.004) * (0.75 + 0.25 * math.sin(2 * math.pi * 31 * t))
        env = math.exp(-t * 0.9) * min(1.0, (seconds - t) / 0.25)
        out.append(0.42 * (tone + glass) * gate * env + 0.02 * (rng.random() * 2 - 1) * env)
    return out


# ---- 森林（腐敗之森）的環境音 ----


def _mix_at(out, at_sec, samples, gain=1.0):
    """把一段聲音加進 out 的某個時間點（超出去的截掉）。"""
    start = int(at_sec * RATE)
    for j, v in enumerate(samples):
        if start + j >= len(out):
            break
        if start + j >= 0:
            out[start + j] += gain * v


def _echo(xs, taps):
    """幾道往後的回音（延遲秒數, 大小）；就地加在原本那份上，回傳同一份。"""
    for delay, amount in taps:
        d = int(delay * RATE)
        for i in range(len(xs) - 1, d - 1, -1):
            xs[i] += xs[i - d] * amount
    return xs


def _owl(seed):
    """遠處的貓頭鷹：「嗚——、嗚嗚——」兩聲（360 Hz 往下滑一點，柔柔地起落），低通、帶兩道回音。"""
    n = int(1.6 * RATE)
    out = [0.0] * n
    for at, dur, f0 in ((0.0, 0.34, 372.0), (0.55, 0.16, 360.0), (0.74, 0.46, 352.0)):
        m = int(dur * RATE)
        ph = 0.0
        start = int(at * RATE)
        for k in range(m):
            x = k / m
            f = f0 * (1.0 - 0.06 * x)
            ph += 2 * math.pi * f / RATE
            env = math.sin(math.pi * x) ** 1.5
            out[start + k] += env * (math.sin(ph) + 0.12 * math.sin(2 * ph))
    out = onepole_lp(out, 1400)
    return _echo(out, ((0.23, 0.22), (0.51, 0.1)))


def _creak(seed, seconds=0.8):
    """樹幹被風推的一聲「吱——嘎」：一串越來越密又變疏的小摩擦（黏滑），經過木頭的兩個共鳴。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    pulses = [0.0] * n
    t = 0.0
    while t < seconds:
        x = t / seconds
        rate = 38.0 + 55.0 * math.sin(math.pi * x)
        i = int(t * RATE)
        if i < n:
            pulses[i] = rng.uniform(0.6, 1.0) * math.sin(math.pi * x)
        t += 1.0 / rate
    a = svf_band(pulses, lambda i: 620.0, 0.06)
    b = svf_band(pulses, lambda i: 1380.0, 0.09)
    out = [a[i] + 0.5 * b[i] for i in range(n)]
    peak = max(abs(v) for v in out) or 1.0
    return [v / peak for v in out]


def _crickets(total, rng, freq, period, amp, phrase_on, phrase_off):
    """一隻蟲在叫：每 period 秒一聲「唧唧唧」（三下 18 ms 的高音脈衝），叫一陣停一陣。"""
    out = [0.0] * total
    t = rng.uniform(0.0, period)
    on_until = t + phrase_on
    while t < total / RATE:
        if t > on_until:
            t += phrase_off * rng.uniform(0.7, 1.3)
            on_until = t + phrase_on * rng.uniform(0.7, 1.3)
            continue
        for p in range(3):
            start = int((t + p * 0.032) * RATE)
            m = int(0.018 * RATE)
            for k in range(m):
                if start + k >= total:
                    break
                env = math.sin(math.pi * k / m)
                out[start + k] += amp * env * math.sin(2 * math.pi * freq * (start + k) / RATE)
        t += period * rng.uniform(0.94, 1.06)
    return out


def forest_night(seconds=16.0, seed=211):
    """夜晚的腐敗之森（可循環 16 秒；整片、不分位置）：樹葉間的風一陣一陣（兩個慢的起伏，週期整除 16 秒）
    ＋風大的時候葉子的沙沙聲＋兩隻蟲（唧唧，叫一陣停一陣）＋遠遠一隻貓頭鷹（兩次）＋樹幹一聲吱嘎
    ＋很低、很小的瘴氣嗡嗡聲（49／73.5 Hz 慢慢拍頻）。頭尾交叉淡化。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    fade = int(1.5 * RATE)
    total = n + fade
    wind = onepole_lp(onepole_lp(hp(noise(total, rng), 110), 650), 900)
    leaves = onepole_lp(hp(noise(total, rng), 2300), 6500)
    out = [0.0] * total
    for i in range(total):
        g = 0.55 + 0.3 * math.sin(2 * math.pi * 2 * i / n - 0.7) + 0.15 * math.sin(2 * math.pi * 5 * i / n + 1.3)
        g = max(0.12, g)
        t = i / RATE
        drone = 0.018 * (math.sin(2 * math.pi * 49.0 * t) + 0.7 * math.sin(2 * math.pi * 73.5 * t)) * (0.7 + 0.3 * math.sin(2 * math.pi * 2 * i / n))
        out[i] = wind[i] * 2.4 * g + leaves[i] * 0.16 * g * g + drone
    for c in (_crickets(total, rng, 4350.0, 0.66, 0.05, 4.0, 2.5), _crickets(total, rng, 5150.0, 0.83, 0.035, 3.0, 3.5)):
        for i in range(total):
            out[i] += c[i]
    owl = _owl(seed + 1)
    _mix_at(out, 4.6, owl, 0.11)
    _mix_at(out, 12.1, owl, 0.08)
    _mix_at(out, 9.0, _creak(seed + 2), 0.07)
    looped = _loop_crossfade(out, n, fade)
    peak = max(abs(v) for v in looped) or 1.0
    return [v / peak * 0.7 for v in looped]


def swamp_bubble(seconds=8.0, seed=223):
    """毒沼（可循環 8 秒；從毒沼中間發出來）：底下的泥慢慢翻（很低的雜訊起伏）＋一顆一顆冒上來破掉的泡泡
    （往上滑的短正弦，每秒四五顆）＋偶爾一顆大的「咕嘟」（低、長一點、帶一點泥的濕聲）。頭尾交叉淡化。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    fade = int(0.8 * RATE)
    total = n + fade
    mud = onepole_lp(onepole_lp(noise(total, rng), 170), 210)
    out = [mud[i] * 1.4 * (0.7 + 0.3 * math.sin(2 * math.pi * 3 * i / n)) for i in range(total)]
    t = 0.05
    while t < total / RATE - 0.3:
        big = rng.random() < 0.13
        f0 = rng.uniform(110.0, 170.0) if big else rng.uniform(230.0, 640.0)
        dur = rng.uniform(0.14, 0.22) if big else rng.uniform(0.035, 0.075)
        amp = rng.uniform(0.32, 0.45) if big else rng.uniform(0.07, 0.2)
        start = int(t * RATE)
        m = int(dur * RATE)
        ph = 0.0
        wet = onepole_lp(noise(m, rng), 600) if big else None
        for k in range(m):
            if start + k >= total:
                break
            x = k / m
            ph += 2 * math.pi * f0 * (1.0 + 1.4 * x * x) / RATE
            env = min(1.0, k / (0.002 * RATE)) * math.exp(-x * 4.5)
            s = math.sin(ph)
            if wet is not None:
                s += 1.4 * wet[k]
            out[start + k] += amp * env * s
        t += rng.expovariate(4.6)
    looped = _loop_crossfade(out, n, fade)
    peak = max(abs(v) for v in looped) or 1.0
    return [v / peak * 0.7 for v in looped]


def campfire_crackle(seconds=6.0, seed=227):
    """營火（可循環 6 秒；從營火發出來）：火焰低低的呼呼聲（低通雜訊，忽大忽小）＋木頭裂開的劈啪
    （一下 1～6 ms 的高頻雜訊，大部分很小、少數幾下很響，偶爾連著三四下）。頭尾交叉淡化。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    fade = int(0.8 * RATE)
    total = n + fade
    roar = onepole_lp(onepole_lp(hp(noise(total, rng), 70), 380), 520)
    flicker = onepole_lp(onepole_lp(noise(total, rng), 3.0), 3.0)
    fpeak = max(abs(v) for v in flicker) or 1.0
    out = [roar[i] * 1.6 * (0.75 + 0.35 * flicker[i] / fpeak) for i in range(total)]
    t = 0.02
    while t < total / RATE - 0.05:
        cluster = 1 if rng.random() > 0.15 else rng.randint(3, 5)
        for c in range(cluster):
            amp = min(0.9, 0.28 * rng.paretovariate(1.6))
            m = int(rng.uniform(0.001, 0.006) * RATE)
            burst = hp(noise(m + 1, rng), rng.uniform(1600.0, 3800.0))
            start = int((t + c * rng.uniform(0.006, 0.02)) * RATE)
            for k in range(m):
                if start + k >= total:
                    break
                out[start + k] += amp * burst[k] * math.exp(-k / m * 3.0)
        t += rng.expovariate(13.0)
    looped = _loop_crossfade(out, n, fade)
    peak = max(abs(v) for v in looped) or 1.0
    return [v / peak * 0.7 for v in looped]


def vent_hiss(seconds=5.0, seed=229):
    """毒氣噴發口（可循環 5 秒；從噴發口發出來）：一直往上冒的嘶聲（高通雜訊，微微一陣一陣）＋地底的低鳴
    ＋偶爾一兩下冒泡。頭尾交叉淡化。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    fade = int(0.6 * RATE)
    total = n + fade
    hiss = onepole_lp(hp(noise(total, rng), 1700), 7500)
    rumble = onepole_lp(onepole_lp(noise(total, rng), 110), 140)
    out = []
    for i in range(total):
        g = 0.78 + 0.22 * math.sin(2 * math.pi * 2 * i / n)
        out.append(hiss[i] * 0.55 * g + rumble[i] * 3.2)
    for at in (rng.uniform(0.5, 2.0), rng.uniform(2.8, 4.2)):
        m = int(0.07 * RATE)
        f0 = rng.uniform(160.0, 260.0)
        ph = 0.0
        start = int(at * RATE)
        for k in range(m):
            x = k / m
            ph += 2 * math.pi * f0 * (1.0 + x) / RATE
            out[start + k] += 0.12 * math.exp(-x * 4.0) * math.sin(ph)
    looped = _loop_crossfade(out, n, fade)
    peak = max(abs(v) for v in looped) or 1.0
    return [v / peak * 0.7 for v in looped]


# ---- 森林裡的事件（採集、陷阱、敵人） ----


def _ping(seconds, f, decay, attack=0.004, partials=((1.0, 1.0), (2.0, 0.3), (3.01, 0.1))):
    """一聲柔柔的「叮」（整數倍附近的幾個泛音、指數衰減）。"""
    n = int(seconds * RATE)
    out = []
    for i in range(n):
        t = i / RATE
        env = min(1.0, t / attack) * math.exp(-t * decay)
        out.append(env * sum(a * math.sin(2 * math.pi * f * r * t) for r, a in partials))
    return out


def mushroom_pick(seconds=0.75, seed=233):
    """採一朵夜光毒蕈：蕈柄被折斷的濕濕一聲「啵」（往下掉的短音＋一點濕的雜訊）
    ＋拿到手的一小串亮亮的「叮鈴」（E6、B6，微微顫，像蕈傘的光）。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    out = [0.0] * n
    ph = 0.0
    wet = onepole_lp(noise(int(0.08 * RATE), rng), 1300)
    for i in range(int(0.08 * RATE)):
        t = i / RATE
        ph += 2 * math.pi * (300.0 + 650.0 * math.exp(-t * 70)) / RATE
        out[i] += math.exp(-t * 45) * (0.8 * math.sin(ph) + 1.6 * wet[i])
    snap = hp(noise(int(0.006 * RATE), rng), 2500)
    for i, v in enumerate(snap):
        out[i] += 0.5 * v * math.exp(-i / RATE * 600)
    for at, f, g in ((0.07, 1318.5, 0.32), (0.13, 1975.5, 0.26)):
        p = _ping(seconds - at, f, 7.0, 0.006)
        start = int(at * RATE)
        for j, v in enumerate(p):
            t = j / RATE
            out[start + j] += g * v * (0.85 + 0.15 * math.sin(2 * math.pi * 9.0 * t))
    return out


def fruit_bite(seconds=0.6, seed=239):
    """咬一口腐敗野果：兩下脆脆的「喀嚓」（帶顆粒的中高頻雜訊）＋爛掉的果肉擠出汁的濕聲（低通雜訊、慢慢收）
    ＋吞下去的一聲低低的「咕」。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    out = [0.0] * n
    for at, g in ((0.0, 1.0), (0.07, 0.6)):
        m = int(0.05 * RATE)
        band = onepole_lp(hp(noise(m, rng), 1100), 5200)
        start = int(at * RATE)
        for k in range(m):
            grain = 1.0 if rng.random() < 0.25 else 0.35
            out[start + k] += g * band[k] * grain * math.exp(-k / m * 5.0)
    m = int(0.32 * RATE)
    squish = onepole_lp(hp(noise(m, rng), 180), 900)
    start = int(0.05 * RATE)
    for k in range(m):
        x = k / m
        out[start + k] += 1.5 * squish[k] * min(1.0, x * 6.0) * math.exp(-x * 4.0) * (0.7 + 0.3 * math.sin(2 * math.pi * 23.0 * k / RATE))
    ph = 0.0
    start = int(0.42 * RATE)
    for k in range(n - start):
        t = k / RATE
        ph += 2 * math.pi * (190.0 - 70.0 * min(1.0, t / 0.1)) / RATE
        out[start + k] += 0.1 * math.sin(math.pi * min(1.0, t / 0.12)) * math.sin(ph)
    return out


def web_stick(seconds=0.55, seed=241):
    """撞進麻痺蜘蛛網：黏黏的絲被扯開的細碎「嘶啦」（很密的小顆粒，像撕開魔鬼氈，越來越疏）
    ＋網被拉長又彈回來的一聲低低的「嗡——」（往上滑再往下、帶一點顫）。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    out = [0.0] * n
    grains = [0.0] * n
    for i in range(int(0.4 * RATE)):
        x = i / (0.4 * RATE)
        if rng.random() < 0.06 * (1.0 - x) ** 1.5:
            grains[i] = rng.uniform(-1.0, 1.0)
    crackle = svf_band(grains, lambda i: 3200.0, 0.5)
    ph = 0.0
    for i in range(n):
        t = i / RATE
        x = i / n
        f = 150.0 + 90.0 * math.sin(math.pi * min(1.0, x * 1.6))
        ph += 2 * math.pi * f * (1.0 + 0.02 * math.sin(2 * math.pi * 14.0 * t)) / RATE
        env = min(1.0, t / 0.02) * math.exp(-t * 6.0)
        out[i] = 1.4 * crackle[i] + 0.3 * env * (math.sin(ph) + 0.35 * math.sin(2 * ph))
    return out


def wolf_bite(seconds=0.5, seed=251):
    """瘴氣狼撲上來咬：一聲短短的低吼（粗糙的鋸齒波 105 Hz、帶噪音、經過一個喉嚨的共振）
    → 牙齒合起來的「喀」（很硬、很短的高頻共鳴）＋一點撕扯的雜訊。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    m = int(0.22 * RATE)
    src = []
    ph = 0.0
    for i in range(m):
        t = i / RATE
        f = 105.0 * (1.0 + 0.25 * t / 0.22) * (1.0 + 0.06 * rng.uniform(-1.0, 1.0))
        ph = (ph + f / RATE) % 1.0
        src.append((2.0 * ph - 1.0) + 0.6 * rng.uniform(-1.0, 1.0))
    growl = svf_band(src, lambda i: 520.0 + 300.0 * i / m, 0.35)
    out = [0.0] * n
    for i in range(m):
        t = i / RATE
        out[i] += 0.9 * growl[i] * min(1.0, t / 0.03) * (0.6 + 0.4 * math.sin(2 * math.pi * 28.0 * t))
    snap_at = int(0.2 * RATE)
    click = [0.0] * (n - snap_at)
    click[0] = 1.0
    click[1] = -0.7
    teeth = svf_band(click, lambda i: 2300.0, 0.08)
    tear = onepole_lp(hp(noise(n - snap_at, rng), 1200), 6000)
    for k in range(n - snap_at):
        t = k / RATE
        out[snap_at + k] += 6.0 * teeth[k] + 0.45 * tear[k] * math.exp(-t * 22.0)
    return out


def treant_step(seed=257):
    """孢子樹人的一步（約 0.6 秒）：很重的木頭「咚」（85 → 48 Hz 往下掉、加一個高八度讓小喇叭也聽得到）
    ＋樹幹被壓的一聲短吱嘎＋落地時葉子、孢子沙沙地抖。"""
    rng = random.Random(seed)
    n = int(0.6 * RATE)
    out = [0.0] * n
    ph = 0.0
    for i in range(n):
        t = i / RATE
        f = 48.0 + 37.0 * math.exp(-t * 18)
        ph += 2 * math.pi * f / RATE
        out[i] += math.exp(-t * 9.0) * (math.sin(ph) + 0.35 * math.sin(2 * ph)) * min(1.0, t / 0.004)
    dull = onepole_lp(noise(int(0.12 * RATE), rng), 500)
    for i, v in enumerate(dull):
        out[i] += 0.9 * v * math.exp(-i / RATE * 30)
    _mix_at(out, 0.03, _creak(seed + 1, 0.28), 0.1)
    knock = [0.0] * int(0.25 * RATE)
    knock[0] = 1.0
    hollow = svf_band(knock, lambda i: 210.0, 0.05)
    hollow2 = svf_band(knock, lambda i: 470.0, 0.07)
    kpeak = max(abs(v) for v in hollow) or 1.0
    for i in range(len(knock)):
        out[i] += 0.45 * (hollow[i] + 0.5 * hollow2[i]) / kpeak
    rustle = onepole_lp(hp(noise(int(0.35 * RATE), rng), 2600), 7000)
    for i, v in enumerate(rustle):
        x = i / len(rustle)
        out[int(0.04 * RATE) + i] += 0.18 * v * math.sin(math.pi * x) * (0.5 + 0.5 * (rng.random() < 0.3))
    return out


def chest_open(seconds=1.5, seed=263):
    """打開毒沼裡的詛咒寶箱：鎖扣彈開的「喀噠」→ 沉重的箱蓋慢慢掀開的「嘰——」（低的木頭吱嘎）
    → 一口不祥的低音和弦吐出來（三個走音的低音慢慢漲起來，D2、Ab2、D3＝三全音，接著就是詛咒上身）。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    out = [0.0] * n
    latch = thump(0.12, 900, 350, crack=0.9, seed=seed + 1)
    _mix_at(out, 0.0, latch, 0.55)
    _mix_at(out, 0.09, latch, 0.35)
    creak = _creak(seed + 2, 0.7)
    creak = onepole_lp(creak, 1800)
    _mix_at(out, 0.18, creak, 0.6)
    table = _wavetable([(1, 1.0), (2, 0.5), (3, 0.3), (4, 0.15), (5, 0.08)])
    size = len(table)
    chord = [0.0] * n
    start = int(0.55 * RATE)
    for f, a in ((73.4, 0.5), (73.9, 0.4), (103.8, 0.35), (104.4, 0.3), (146.8, 0.2)):
        ph = rng.random() * size
        for i in range(start, n):
            chord[i] += a * table[int(ph) % size]
            ph += f * size / RATE
    chord = onepole_lp(onepole_lp(chord, 700), 900)
    for i in range(start, n):
        x = (i - start) / (n - start)
        out[i] += 0.25 * chord[i] * math.sin(math.pi * min(1.0, x * 1.3)) ** 2
    return out


def distant_scream(seconds=2.6, seed=269):
    """祭壇那邊傳來的慘叫（遠、隔著樹林）：一個人拉長的「啊——」（鋸齒波的聲帶 300 → 560 → 280 Hz，越喊越抖，
    經過「啊」的三個共振峰），低通（遠）＋好幾道越來越悶的回音（樹林）。不是近的、尖的那種。"""
    rng = random.Random(seed)
    m = int(1.25 * RATE)
    src = []
    ph = 0.0
    for i in range(m):
        x = i / m
        f = 300.0 + 260.0 * math.sin(math.pi * min(1.0, x * 1.6)) - 40.0 * x
        f *= 1.0 + (0.01 + 0.04 * x) * math.sin(2 * math.pi * 6.5 * i / RATE) + 0.01 * rng.uniform(-1.0, 1.0)
        ph = (ph + f / RATE) % 1.0
        env = min(1.0, x / 0.06) * (1.0 - max(0.0, (x - 0.7) / 0.3)) ** 1.5
        src.append(env * ((2.0 * ph - 1.0) + 0.15 * rng.uniform(-1.0, 1.0)))
    voice = [0.0] * m
    for fc, d, g in ((850.0, 0.12, 1.0), (1250.0, 0.12, 0.7), (2700.0, 0.15, 0.35)):
        b = svf_band(src, lambda i, fc=fc: fc, d)
        for i in range(m):
            voice[i] += g * b[i]
    n = int(seconds * RATE)
    out = [0.0] * n
    _mix_at(out, 0.0, onepole_lp(onepole_lp(voice, 2200), 3000), 1.0)
    taps = ((0.19, 0.35), (0.37, 0.24), (0.61, 0.15), (0.9, 0.09))
    wet = list(out)
    for delay, amount in taps:
        d = int(delay * RATE)
        damp = onepole_lp(wet, 1500 - delay * 800)
        for i in range(d, n):
            out[i] += damp[i - d] * amount
    return out


# ---- 廢棄祭壇：深淵疫病魔像 ----


def _rough_saw(n, rng, f_at, jitter):
    """粗糙的鋸齒波（每個樣本的音高 f_at(i)，加一點隨機抖動）：吼聲、喉嚨的聲帶。"""
    out = []
    ph = 0.0
    for i in range(n):
        ph = (ph + f_at(i) * (1.0 + jitter * rng.uniform(-1.0, 1.0)) / RATE) % 1.0
        out.append(2.0 * ph - 1.0)
    return out


def golem_roar(seconds=2.0, seed=271):
    """魔像的吼（醒來、狂暴）：很低、很粗的「吼——」（58 Hz 的鋸齒波＋低八度的次諧波，經過兩個石頭胸腔的共振，
    慢慢漲起來再往下掉）＋整個身體的石頭互相磨的沙沙聲＋最後一點碎石落地。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    f_at = lambda i: 58.0 * (1.0 + 0.18 * math.sin(math.pi * min(1.0, i / n * 1.4)) - 0.12 * i / n)
    src = _rough_saw(n, rng, f_at, 0.08)
    sub = []
    ph = 0.0
    for i in range(n):
        ph += 2 * math.pi * f_at(i) * 0.5 / RATE
        sub.append(math.sin(ph))
    air = noise(n, rng)
    body = [src[i] + 0.5 * air[i] for i in range(n)]
    chest = [0.0] * n
    for fc, d, g in ((240.0, 0.3, 1.0), (560.0, 0.25, 0.6), (1100.0, 0.3, 0.25)):
        b = svf_band(body, lambda i, fc=fc: fc * (1.0 + 0.15 * math.sin(math.pi * i / n)), d)
        for i in range(n):
            chest[i] += g * b[i]
    grind = onepole_lp(hp(noise(n, rng), 400), 2400)
    out = []
    for i in range(n):
        x = i / n
        env = min(1.0, x / 0.18) ** 1.5 * (1.0 - max(0.0, (x - 0.62) / 0.38)) ** 1.3
        trem = 0.8 + 0.2 * math.sin(2 * math.pi * 11.0 * i / RATE)
        out.append(env * (0.9 * chest[i] * trem + 0.7 * sub[i] + 0.25 * grind[i] * (0.5 + 0.5 * math.sin(2 * math.pi * 3.0 * i / RATE))))
    for k in range(5):
        hit = thump(0.1, rng.uniform(260, 420), 120, crack=0.5, seed=seed + 10 + k)
        _mix_at(out, rng.uniform(1.2, 1.8), hit, 0.12)
    return out


def gaze_charge(seconds=2.4, seed=277):
    """石化凝視的前兆（眼睛開始亮）：一聲越來越高、越來越抖的嗡鳴（220 → 880 Hz，兩個走音的聲部拍頻越來越快）
    ＋水晶般細細的沙沙聲越來越亮——聽到就知道「要來了，快去擋」。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    shimmer = hp(noise(n, rng), 5000)
    out = []
    pa = pb = 0.0
    for i in range(n):
        x = i / n
        f = 220.0 * (4.0 ** (x * x))
        pa += 2 * math.pi * f / RATE
        pb += 2 * math.pi * f * (1.0 + 0.004 + 0.02 * x) / RATE
        env = 0.2 + 0.8 * x ** 1.5
        trem = 0.7 + 0.3 * math.sin(2 * math.pi * (5.0 + 20.0 * x) * i / RATE)
        tone = math.sin(pa) + 0.8 * math.sin(pb) + 0.25 * math.sin(3 * pa)
        out.append(env * (0.5 * trem * tone + 0.35 * x * x * shimmer[i]))
    return out


def gaze_beam(seconds=1.3, seed=281):
    """石化凝視打出去：一道很亮的「嗤——」（寬頻雜訊一下子衝出來）＋底下一聲低沉的「咚」
    ＋石頭一下子凝固的「喀啦」（一串很快的小裂聲）。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    blast = onepole_lp(hp(noise(n, rng), 900), 9000)
    out = []
    ph = 0.0
    for i in range(n):
        t = i / RATE
        ph += 2 * math.pi * (95.0 * math.exp(-t * 3.0) + 45.0) / RATE
        out.append(1.4 * blast[i] * min(1.0, t / 0.008) * math.exp(-t * 5.0) + 0.9 * math.exp(-t * 6.0) * math.sin(ph))
    for k in range(16):
        at = 0.12 + k * rng.uniform(0.02, 0.045)
        hit = thump(0.06, rng.uniform(900, 1600), 500, crack=1.0, seed=seed + 20 + k)
        _mix_at(out, at, hit, 0.12 * (1.0 - k / 20.0))
    return out


def golem_slam(seconds=1.2, seed=283):
    """魔像的重拳與震地：地面被砸的一聲很低的「轟」（62 → 28 Hz、加一個高八度讓小喇叭也聽得到）＋石板裂開的乾裂聲
    ＋碎石往四周滾的沙沙聲。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    out = [0.0] * n
    ph = 0.0
    for i in range(n):
        t = i / RATE
        ph += 2 * math.pi * (28.0 + 34.0 * math.exp(-t * 10.0)) / RATE
        env = min(1.0, t / 0.003) * math.exp(-t * 4.5)
        out[i] = env * (math.sin(ph) + 0.6 * math.sin(2 * ph) + 0.3 * math.sin(3 * ph))
    dull = onepole_lp(noise(int(0.25 * RATE), rng), 420)
    for i, v in enumerate(dull):
        out[i] += 1.2 * v * math.exp(-i / RATE * 14)
    crack = hp(noise(int(0.06 * RATE), rng), 2000)
    for i, v in enumerate(crack):
        out[i] += 0.8 * v * math.exp(-i / RATE * 60)
    _mix_at(out, 0.05, scrape(0.9, seed + 1), 0.7)
    return out


def golem_step(seed=293):
    """魔像的一步（約 0.5 秒）：石頭腳砸在石板上的「咚」（70 → 40 Hz）＋膝蓋、腳踝的石頭互相磨的一聲短「嘎」
    ＋一點碎石。比樹人的硬、乾，沒有葉子。"""
    rng = random.Random(seed)
    n = int(0.5 * RATE)
    out = [0.0] * n
    ph = 0.0
    for i in range(n):
        t = i / RATE
        ph += 2 * math.pi * (40.0 + 30.0 * math.exp(-t * 22)) / RATE
        out[i] = math.exp(-t * 11.0) * (math.sin(ph) + 0.5 * math.sin(2 * ph) + 0.25 * math.sin(3 * ph)) * min(1.0, t / 0.002)
    click = hp(noise(int(0.012 * RATE), rng), 1800)
    for i, v in enumerate(click):
        out[i] += 0.6 * v * math.exp(-i / RATE * 200)
    m = int(0.22 * RATE)
    grind = onepole_lp(hp(noise(m, rng), 500), 2200)
    start = int(0.04 * RATE)
    for k in range(m):
        x = k / m
        out[start + k] += 0.45 * grind[k] * math.sin(math.pi * x) * (0.5 + 0.5 * math.sin(2 * math.pi * 37.0 * k / RATE))
    return out


def core_glow(seconds=1.4, seed=307):
    """魔像胸口的核心亮起來（露出來了，快砍）：一聲往上浮的水晶嗡鳴（A3 → A4，帶幾個亮的泛音）
    ＋三下細細的「叮」往上走——跟反轉的金色鐘音同一個語彙，但比較暗、比較紫。"""
    n = int(seconds * RATE)
    out = [0.0] * n
    ph = 0.0
    for i in range(n):
        t = i / RATE
        x = i / n
        f = 220.0 * (2.0 ** min(1.0, x * 1.8))
        ph += 2 * math.pi * f / RATE
        env = min(1.0, x / 0.15) * (1.0 - x) ** 1.2
        out[i] = 0.45 * env * (math.sin(ph) + 0.35 * math.sin(2.01 * ph) + 0.2 * math.sin(3.0 * ph) + 0.12 * math.sin(4.2 * ph))
    for at, f in ((0.25, 1046.5), (0.38, 1396.9), (0.51, 1760.0)):
        _mix_at(out, at, _ping(0.8, f, 6.0), 0.18)
    return out


def core_shatter(seconds=2.2, seed=311):
    """粉碎魔像的核心（第一章的最後一刀）：一聲又低又大的爆裂（很低的「轟」＋寬頻的炸開聲）
    ＋幾十片水晶碎片的「叮」往外散、越來越小＋長長的、往下沉的嗡鳴（核心的光熄掉）。
    跟反轉的碎裂聲不同：沒有往上走的金色鐘音，比較重、比較長。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    out = [0.0] * n
    ph = 0.0
    for i in range(n):
        t = i / RATE
        ph += 2 * math.pi * (32.0 + 60.0 * math.exp(-t * 7.0)) / RATE
        out[i] = 1.1 * min(1.0, t / 0.002) * math.exp(-t * 3.2) * (math.sin(ph) + 0.35 * math.sin(2 * ph))
    burst = onepole_lp(hp(noise(int(0.35 * RATE), rng), 700), 11000)
    for i, v in enumerate(burst):
        out[i] += 1.3 * v * math.exp(-i / RATE * 12)
    for k in range(34):
        start = int(rng.uniform(0.0, 0.9) * RATE * (k / 34.0) ** 0.7)
        f = rng.uniform(1800.0, 6800.0)
        gain = 0.5 * (1.0 - k / 40.0)
        decay = rng.uniform(18.0, 40.0)
        for j in range(int(0.3 * RATE)):
            if start + j >= n:
                break
            t = j / RATE
            out[start + j] += gain * math.exp(-t * decay) * (math.sin(2 * math.pi * f * t) + 0.5 * math.sin(2 * math.pi * f * 2.32 * t))
    pa = pb = 0.0
    start = int(0.15 * RATE)
    for j in range(n - start):
        x = j / (n - start)
        f = 330.0 * (1.0 - 0.45 * x)
        pa += 2 * math.pi * f / RATE
        pb += 2 * math.pi * f * 1.006 / RATE
        out[start + j] += 0.22 * min(1.0, x / 0.05) * (1.0 - x) ** 2 * (math.sin(pa) + math.sin(pb))
    return out


def stone_deflect(seconds=0.5, seed=313):
    """砍在還沒露出核心的魔像身上、扣不下去（打不下去）：石頭很硬的一聲「鏗」（短、悶，不是鐵的長餘響）
    ＋核心外面那層護罩的一聲很短的水晶「嗡」。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    out = [0.0] * n
    hit = thump(0.2, 520, 180, crack=1.2, seed=seed + 1)
    _mix_at(out, 0.0, hit, 0.8)
    for f, a, d in ((690.0, 0.5, 26.0), (1410.0, 0.35, 34.0), (2230.0, 0.2, 45.0)):
        f *= rng.uniform(0.98, 1.02)
        for i in range(n):
            t = i / RATE
            out[i] += a * math.exp(-t * d) * math.sin(2 * math.pi * f * t)
    ph = 0.0
    for i in range(n):
        t = i / RATE
        ph += 2 * math.pi * 523.3 / RATE
        out[i] += 0.18 * min(1.0, t / 0.01) * math.exp(-t * 9.0) * (math.sin(ph) * (0.7 + 0.3 * math.sin(2 * math.pi * 30.0 * t)))
    return out


def core_land(seconds=0.55, seed=317):
    """掉出來的核心落在石板上：沉沉的「咚」（像一大塊水晶）＋一聲短短的、帶餘響的晶體「嗡」。"""
    out = thump(seconds, 240, 80, crack=0.4, seed=seed)
    ring = _ping(seconds, 660.0, 9.0, 0.003, ((1.0, 1.0), (2.76, 0.4), (5.4, 0.15)))
    return [out[i] + 0.3 * ring[i] for i in range(len(out))]


def stone_peel(seconds=0.9, seed=331):
    """席菈身上的石殼剝落（石化解除）：一串很密的小裂聲（石殼裂開，越來越疏）→ 一片片碎石掉在地上的「喀啦」。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    out = [0.0] * n
    t = 0.0
    while t < 0.45:
        hit = thump(0.04, rng.uniform(1200, 2600), 700, crack=1.0, seed=rng.randint(0, 99999))
        _mix_at(out, t, hit, rng.uniform(0.08, 0.2))
        t += rng.expovariate(40.0 * (1.0 - t / 0.5) + 6.0)
    for k in range(7):
        hit = thump(0.12, rng.uniform(300, 520), 140, crack=0.6, seed=seed + 40 + k)
        _mix_at(out, rng.uniform(0.3, 0.8), hit, rng.uniform(0.15, 0.3))
    return out


# ---- 祭壇的環境音與 Boss 戰的配樂 ----


def altar_air(seconds=12.0, seed=337):
    """廢棄祭壇（可循環 12 秒；整片）：石柱之間低低的風（比森林悶、沒有葉子，6 秒一次慢慢漲落）
    ＋遠處的石頭偶爾悶悶地「嗡」一聲（很低的長音）＋水滴落進石縫的「滴」（帶兩道石壁的回音）
    ＋很低、會拍頻的疫病嗡嗡聲。頭尾交叉淡化。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    fade = int(1.5 * RATE)
    total = n + fade
    wind = onepole_lp(onepole_lp(hp(noise(total, rng), 80), 380), 520)
    whistle = svf_band(noise(total, rng), lambda i: 820.0 + 120.0 * math.sin(2 * math.pi * 2 * i / n), 0.04)
    out = []
    for i in range(total):
        g = 0.6 + 0.4 * math.sin(2 * math.pi * 2 * i / n + 0.4)
        t = i / RATE
        hum = 0.03 * (math.sin(2 * math.pi * 55.0 * t) + 0.6 * math.sin(2 * math.pi * 55.7 * t) + 0.3 * math.sin(2 * math.pi * 110.4 * t))
        out.append(wind[i] * 2.6 * g + whistle[i] * 0.05 * g * g + hum)
    for at in (2.2, 8.4):
        m = int(2.2 * RATE)
        ph = 0.0
        start = int(at * RATE)
        for k in range(m):
            x = k / m
            ph += 2 * math.pi * (41.0 + 6.0 * x) / RATE
            out[start + k] += 0.09 * math.sin(math.pi * x) ** 2 * (math.sin(ph) + 0.4 * math.sin(2 * ph))
    drip = _ping(0.25, 1.0, 1.0)
    for k in range(6):
        at = 0.7 + k * 1.9 + rng.uniform(-0.3, 0.3)
        f = rng.uniform(1700.0, 2500.0)
        d = []
        ph = 0.0
        for j in range(int(0.12 * RATE)):
            t = j / RATE
            ph += 2 * math.pi * f * (1.0 + 0.6 * t / 0.12) / RATE
            d.append(math.exp(-t * 40.0) * math.sin(ph))
        d = _echo(d + [0.0] * int(0.6 * RATE), ((0.13, 0.3), (0.29, 0.15)))
        _mix_at(out, at, d, rng.uniform(0.05, 0.09))
    looped = _loop_crossfade(out, n, fade)
    peak = max(abs(v) for v in looped) or 1.0
    return [v / peak * 0.7 for v in looped]


def _drum(seconds, f0, f1, decay, click, seed):
    """一下太鼓：往下掉的正弦（f0 → f1）＋鼓皮的一點雜訊。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    skin = onepole_lp(noise(n, rng), 1200)
    out = []
    ph = 0.0
    for i in range(n):
        t = i / RATE
        ph += 2 * math.pi * (f1 + (f0 - f1) * math.exp(-t * 25.0)) / RATE
        out.append(math.exp(-t * decay) * (math.sin(ph) + click * skin[i] * math.exp(-t * 40.0)))
    return out


def _saw_note(seconds, f, rng, detune=0.004, cutoff=900.0, attack=0.01, release=0.08):
    """一個鋸齒波的音（兩個微微走音的聲部，低通）：低音的頑固音型、銅管一樣的和弦。"""
    n = int(seconds * RATE)
    raw = []
    pa = rng.random()
    pb = rng.random()
    for i in range(n):
        pa = (pa + f / RATE) % 1.0
        pb = (pb + f * (1.0 + detune) / RATE) % 1.0
        raw.append((2.0 * pa - 1.0) + (2.0 * pb - 1.0))
    raw = onepole_lp(onepole_lp(raw, cutoff), cutoff * 1.3)
    out = []
    for i in range(n):
        t = i / RATE
        env = min(1.0, t / attack) * min(1.0, (seconds - t) / release)
        out.append(env * raw[i])
    return out


def boss_theme(seed=347):
    """深淵疫病魔像的戰鬥配樂（可循環 16 秒＝120 BPM、8 小節；走 Music 匯流排）：D 弗里吉亞（D、Eb 往返，很不安）。
    底下是太鼓（每小節第一拍最重的一下、反拍的小鼓）＋八分音符的低音頑固音型（D2 D2 Eb2 D2…，鋸齒波低通）
    ＋兩小節換一次的銅管和弦（Dm → Eb → Dm → Bb、A；前一個和弦拖進下一個 0.2 秒，換的時候不會斷）＋第 1、5 小節標題那三聲往下走的鐘（D4、C4、A3），但快、硬、帶回音。
    循環的頭尾是同一拍（第 8 小節的最後一拍接回第 1 小節），不用交叉淡化；尾巴的殘響加回開頭。"""
    rng = random.Random(seed)
    beat = 0.5
    bar = 4 * beat
    n = int(8 * bar * RATE)
    out = [0.0] * (n + int(2.0 * RATE))
    big = _drum(0.9, 120.0, 46.0, 4.5, 0.8, seed + 1)
    mid = _drum(0.5, 160.0, 70.0, 8.0, 1.0, seed + 2)
    small = _drum(0.25, 260.0, 140.0, 18.0, 1.4, seed + 3)
    for b in range(8):
        t0 = b * bar
        _mix_at(out, t0, big, 0.55)
        _mix_at(out, t0 + 1.5 * beat, mid, 0.3)
        _mix_at(out, t0 + 2 * beat, mid, 0.38)
        _mix_at(out, t0 + 3.5 * beat, small, 0.25)
        if b % 2 == 1:
            _mix_at(out, t0 + 3.0 * beat, mid, 0.3)
            _mix_at(out, t0 + 3.25 * beat, small, 0.2)
            _mix_at(out, t0 + 3.75 * beat, small, 0.25)
    D2, Eb2, Bb1, A1 = 73.42, 77.78, 58.27, 55.0
    roots = [D2, D2, Eb2, Eb2, D2, D2, Bb1, A1]
    pattern = [0, 0, 1, 0, 0, 1, 0, 2]
    for b in range(8):
        r = roots[b]
        for e in range(8):
            step = pattern[e]
            f = r if step == 0 else (r * 2.0 if step == 1 else r * 1.0595)
            note = _saw_note(beat / 2 * 0.85, f, rng, 0.003, 700.0, 0.004, 0.03)
            _mix_at(out, b * bar + e * beat / 2, note, 0.16 if e % 2 == 0 else 0.11)
    chords = [(0, [146.83, 174.61, 220.0]), (2, [155.56, 196.0, 233.08]), (4, [146.83, 174.61, 220.0]),
              (6, [116.54, 146.83, 174.61]), (7, [110.0, 138.59, 164.81])]
    for k, (b, freqs) in enumerate(chords):
        bars = (chords[k + 1][0] if k + 1 < len(chords) else 8) - b
        for f in freqs:
            note = _saw_note(bars * bar + 0.2, f, rng, 0.006, 1100.0, 0.25, 0.35)
            _mix_at(out, b * bar, note, 0.08)
    bells = {}
    for b in (0, 4):
        for k, (off, f) in enumerate(((0.0, 293.66), (0.75, 261.63), (1.5, 220.0))):
            if f not in bells:
                bb = onepole_lp(bell(f, 2.2), 3000)
                pk = max(abs(v) for v in bb) or 1.0
                bells[f] = [v / pk for v in bb]
            for delay, tap in ((0.0, 0.22), (0.375, 0.08), (0.75, 0.04)):
                _mix_at(out, b * bar + off * beat + delay, bells[f], tap * (1.0 if k < 2 else 1.2))
    tail = out[n:]
    looped = out[:n]
    for i, v in enumerate(tail):
        looped[i] += v
    peak = max(abs(v) for v in looped) or 1.0
    return [v / peak * 0.7 for v in looped]


# ---- 公會大廳與漫符 ----


def crowd_laugh(seconds=1.6, seed=349):
    """公會裡的冒險者在笑（水晶警報之後）：兩三個人「哈、哈、哈」的笑聲（每一聲是一個短音節：鋸齒波的聲帶
    往下滑一點，經過「啊」的共振峰，帶一點氣音），一個低一個高、錯開一點，最後一聲拖長。木頭大廳的短回音。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    out = [0.0] * n
    for f0, start, count, gap, gain in ((128.0, 0.0, 6, 0.15, 1.0), (176.0, 0.08, 5, 0.17, 0.8), (150.0, 0.32, 4, 0.19, 0.6)):
        t = start
        for k in range(count):
            last = k == count - 1
            dur = 0.24 if last else rng.uniform(0.08, 0.11)
            m = int(dur * RATE)
            src = []
            ph = 0.0
            for i in range(m):
                x = i / m
                f = f0 * (1.25 - 0.3 * x) * (1.0 - 0.04 * k)
                ph = (ph + f / RATE) % 1.0
                env = min(1.0, x / 0.12) * (1.0 - x) ** 1.4
                src.append(env * ((2.0 * ph - 1.0) + 0.7 * rng.uniform(-1.0, 1.0)))
            syl = [0.0] * m
            for fc, d, g in ((750.0, 0.18, 1.0), (1200.0, 0.2, 0.6), (2600.0, 0.25, 0.25)):
                b = svf_band(src, lambda i, fc=fc: fc, d)
                for i in range(m):
                    syl[i] += g * b[i]
            _mix_at(out, t, syl, gain * (1.0 - 0.08 * k))
            t += gap * rng.uniform(0.9, 1.15)
    out = onepole_lp(out, 4200)
    return _echo(out, ((0.045, 0.22), (0.09, 0.12)))


def door_creak(seconds=1.1, seed=353):
    """公會的大門打開：門閂拉開的「喀」→ 厚木門板的一聲長「嘰——呀」（低的木頭吱嘎，越來越慢）
    ＋門外的風灌進來一點（低通雜訊慢慢漲）。關門不另外做。"""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    out = [0.0] * n
    _mix_at(out, 0.0, thump(0.1, 700, 260, crack=0.8, seed=seed + 1), 0.45)
    creak = onepole_lp(_creak(seed + 2, 0.75), 2200)
    _mix_at(out, 0.12, creak, 0.7)
    air = onepole_lp(onepole_lp(noise(n, rng), 500), 700)
    for i in range(n):
        x = i / n
        out[i] += 1.4 * air[i] * min(1.0, max(0.0, x - 0.15) / 0.5) * (1.0 - x) ** 0.5
    return out


def _glide(seconds, f0, f1, decay, partials=((1.0, 1.0), (2.0, 0.25))):
    """往上或往下滑的一聲（漫畫的效果音）。"""
    n = int(seconds * RATE)
    out = []
    ph = 0.0
    for i in range(n):
        t = i / RATE
        x = i / n
        ph += 2 * math.pi * (f0 * (f1 / f0) ** x) / RATE
        env = min(1.0, t / 0.004) * math.exp(-t * decay)
        out.append(env * sum(a * math.sin(r * ph) for r, a in partials))
    return out


def manga_shock(seed=359):
    """漫符：驚嚇線、怒筋冒出來的「咚！」（短短一下往下掉的低音＋一點拍掌一樣的雜訊），漫畫的那一下。"""
    rng = random.Random(seed)
    out = _glide(0.28, 420.0, 160.0, 14.0, ((1.0, 1.0), (2.0, 0.4), (3.0, 0.15)))
    slap = onepole_lp(hp(noise(int(0.03 * RATE), rng), 900), 5000)
    for i, v in enumerate(slap):
        out[i] += 0.6 * v * math.exp(-i / RATE * 120)
    return out


def manga_sparkle(seed=361):
    """漫符：閃亮、臉紅冒出來的「叮♪」（兩個很快往上的高音，像小小的鈴）。"""
    out = [0.0] * int(0.5 * RATE)
    _mix_at(out, 0.0, _ping(0.4, 1567.98, 9.0, 0.003), 0.5)
    _mix_at(out, 0.07, _ping(0.4, 2349.32, 8.0, 0.003), 0.45)
    return out


def manga_drop(seed=367):
    """漫符：汗、陰影線冒出來的「咻～」（往下滑的軟軟一聲，像一滴汗掉下來）。"""
    return _glide(0.36, 1150.0, 380.0, 7.0, ((1.0, 1.0), (2.0, 0.12)))


def manga_question(seed=373):
    """漫符：問號冒出來的「嗯？」（往上翹的軟軟一聲）。"""
    return _glide(0.3, 420.0, 900.0, 7.5, ((1.0, 1.0), (2.0, 0.15)))


def door_shut(seconds=0.55, seed=379):
    """公會的大門關上：厚木門板撞上門框的悶悶一聲「碰」＋門閂落下的「喀」＋門板微微震一下。"""
    out = [0.0] * int(seconds * RATE)
    _mix_at(out, 0.0, thump(0.4, 170, 58, crack=0.4, seed=seed), 1.0)
    _mix_at(out, 0.05, thump(0.08, 1100, 500, crack=1.0, seed=seed + 1), 0.25)
    knock = [0.0] * int(0.3 * RATE)
    knock[0] = 1.0
    body = svf_band(knock, lambda i: 230.0, 0.04)
    peak = max(abs(v) for v in body) or 1.0
    _mix_at(out, 0.0, [v / peak for v in body], 0.35)
    return out


def _pluck(seconds, f, rng, damp=0.996, bright=0.5):
    """撥一下弦（Karplus-Strong：一小段雜訊在延遲線裡來回、每圈平均一次就越來越圓、越來越小）。"""
    period = max(2, int(RATE / f))
    buf = [rng.uniform(-1.0, 1.0) for _ in range(period)]
    buf = onepole_lp(buf, 1500.0 + 6000.0 * bright)
    n = int(seconds * RATE)
    out = []
    idx = 0
    prev = 0.0
    for i in range(n):
        cur = buf[idx]
        buf[idx] = damp * 0.5 * (cur + prev)
        prev = cur
        out.append(cur)
        idx = (idx + 1) % period
    tail = int(0.03 * RATE)
    for i in range(max(0, n - tail), n):
        out[i] *= (n - i) / tail
    return out


def guild_theme(seed=383):
    """公會大廳的配樂（可循環 12 秒＝三拍子、120 BPM、8 小節；走 Music 匯流排，小小聲墊在人聲底下）：
    角落有人在彈魯特琴——每小節第一拍撥低音、第二三拍撥和弦音（D、G、A、D、Bm、G、A、D），上面一支軟軟的直笛旋律
    （正弦＋一點泛音與氣音、輕輕抖），手鼓在第一拍「咚」、二三拍「嗒」。有點舊、有點暖，不是英雄的那種。
    循環的頭尾是同一拍，尾巴的殘響加回開頭。"""
    rng = random.Random(seed)
    beat = 0.5
    bar = 3 * beat
    n = int(8 * bar * RATE)
    out = [0.0] * (n + int(2.0 * RATE))
    D3, G2, A2, B2 = 146.83, 98.0, 110.0, 123.47
    chords = [(D3, (185.0, 220.0, 293.66)), (G2, (246.94, 293.66, 392.0)), (A2, (277.18, 329.63, 440.0)), (D3, (185.0, 220.0, 293.66)),
              (B2, (293.66, 369.99, 493.88)), (G2, (246.94, 293.66, 392.0)), (A2, (277.18, 329.63, 440.0)), (D3, (220.0, 293.66, 369.99))]
    for b, (root, tones) in enumerate(chords):
        t0 = b * bar
        _mix_at(out, t0, _pluck(1.4, root, rng, 0.997, 0.3), 0.5)
        for k in range(4):
            f = tones[(k + (b % 2)) % 3]
            _mix_at(out, t0 + beat + k * beat / 2, _pluck(0.8, f, rng, 0.994, 0.55), 0.26 if k % 2 == 0 else 0.2)
    melody = [[(440.0, 1), (369.99, 1), (440.0, 1)], [(493.88, 2), (440.0, 1)], [(554.37, 1), (493.88, 1), (440.0, 1)], [(369.99, 3)],
              [(587.33, 1), (554.37, 1), (493.88, 1)], [(493.88, 1), (392.0, 1), (493.88, 1)], [(440.0, 1), (392.0, 1), (329.63, 1)], [(293.66, 3)]]
    for b, notes in enumerate(melody):
        t = b * bar
        for f, beats in notes:
            dur = beats * beat
            m = int(dur * RATE)
            breath = onepole_lp(hp(noise(m, rng), 1800), 6000)
            note = []
            ph = 0.0
            for i in range(m):
                tt = i / RATE
                vib = 1.0 + 0.006 * math.sin(2 * math.pi * 5.2 * tt) * min(1.0, tt / 0.3)
                ph += 2 * math.pi * f * vib / RATE
                env = min(1.0, tt / 0.04) * min(1.0, (dur - tt) / 0.08) * (1.0 - 0.15 * tt / dur)
                note.append(env * (math.sin(ph) + 0.18 * math.sin(2 * ph) + 0.06 * math.sin(3 * ph) + 0.08 * breath[i]))
            _mix_at(out, t, note, 0.13)
            t += dur
    low = _drum(0.35, 140.0, 80.0, 12.0, 0.6, seed + 1)
    high = _drum(0.12, 420.0, 300.0, 35.0, 1.4, seed + 2)
    for b in range(8):
        _mix_at(out, b * bar, low, 0.25)
        _mix_at(out, b * bar + beat, high, 0.08)
        _mix_at(out, b * bar + 2 * beat, high, 0.1)
    out = onepole_lp(out, 5000)
    _echo(out, ((0.07, 0.18), (0.13, 0.1)))
    looped = out[:n]
    for i, v in enumerate(out[n:]):
        looped[i] += v
    peak = max(abs(v) for v in looped) or 1.0
    return [v / peak * 0.7 for v in looped]


def main():
    made = [
        write("blunt", thump(0.3, 140, 55, seed=2)),
        write("blunt_weak", thump(0.38, 170, 50, crack=0.8, seed=3)),
        write("slash", swish(0.28, 900, 7000, seed=5, rise=0.3, metal=0.25)),
        write("whoosh", swish(0.35, 200, 1600, seed=6, rise=0.45)),
        write("iron_clang", clang()),
        write("ui_tick", ui_tick()),
        write("hall_murmur", hall_murmur()),
        write("title_theme", title_theme()),
        write("chapter_end_theme", chapter_end_theme()),
        write("step_dirt", step_dirt()),
        write("step_stone", step_stone()),
        write("step_wood", step_wood()),
        write("glass_clink", glass_clink()),
        write("interrupt", interrupt_crack()),
        write("brace_warn", brace_warn()),
        write("poison_burst", poison_burst()),
        write("curse_sting", curse_sting()),
        write("reversal_shatter", reversal_shatter()),
        write("crystal_alarm", crystal_alarm()),
        write("vial_shot", vial_shot()),
        write("vial_shatter", vial_shatter()),
        write("vial_load", vial_load()),
        write("cut_hit", cut_hit()),
        write("cut_heavy", cut_heavy()),
        write("forest_night", forest_night()),
        write("swamp_bubble", swamp_bubble()),
        write("campfire_crackle", campfire_crackle()),
        write("vent_hiss", vent_hiss()),
        write("mushroom_pick", mushroom_pick()),
        write("fruit_bite", fruit_bite()),
        write("web_stick", web_stick()),
        write("wolf_bite", wolf_bite()),
        write("treant_step", treant_step()),
        write("chest_open", chest_open()),
        write("distant_scream", distant_scream()),
        write("golem_roar", golem_roar()),
        write("gaze_charge", gaze_charge()),
        write("gaze_beam", gaze_beam()),
        write("golem_slam", golem_slam()),
        write("golem_step", golem_step()),
        write("core_glow", core_glow()),
        write("core_shatter", core_shatter()),
        write("stone_deflect", stone_deflect()),
        write("core_land", core_land()),
        write("stone_peel", stone_peel()),
        write("altar_air", altar_air()),
        write("boss_theme", boss_theme()),
        write("crowd_laugh", crowd_laugh()),
        write("door_creak", door_creak()),
        write("door_shut", door_shut()),
        write("guild_theme", guild_theme()),
        write("manga_shock", manga_shock()),
        write("manga_sparkle", manga_sparkle()),
        write("manga_drop", manga_drop()),
        write("manga_question", manga_question()),
    ]
    for p in made:
        print(f"{p.name}: {p.stat().st_size // 1024} KB")


if __name__ == "__main__":
    sys.exit(main())
