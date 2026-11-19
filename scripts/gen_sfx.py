#!/usr/bin/env python3
"""程序生成音效（不進 git），輸出到 game/assets/generated/sfx/*.wav。

只用標準函式庫（wave、math、random），固定亂數種子，每次產生的檔案相同。
- （bell() 沒有自己的音檔了：鐘聲的合成只給 title_theme／part_end_theme 裡遠遠的鐘用。非諧波泛音、各自指數衰減。）
- blunt / blunt_weak：鈍擊（魔像的拳、樹人的下砸、敵人倒地）。低頻下滑正弦＋短噪音；blunt_weak 多一層高頻「喀」。
- cut_hit／cut_heavy：諾恩的劍砍中（平常的一刀／收尾那一刀與砍在破綻上）。刃口的「嚓」＋砍進黏液的濕悶聲＋身體的低頻「咚」＋鏽鐵的一點餘響；重的那一聲低一個八度、拖得長、多幾聲碎裂。
- claw：爪擊。高通噪音快掃。
- slash：揮劍。帶通噪音＋金屬泛音。
- vial_shot／vial_shatter／vial_load：席菈的手弩射出一瓶（弓弦＋彈簧＋木頭）、藥瓶在諾恩身上碎掉（小小的玻璃＋潑開的藥水）、下一瓶裝好（兩下機關聲＋一點玻璃）。
- whoosh：閃避風聲。慢起慢落的低通噪音。
- ui_tick：選單切換值。很小的一聲高音鐘「叮」（兩個非諧波泛音快速衰減）＋極短的木頭「喀」。
- market_murmur：地下市場的底噪（可循環 12 秒，D-230）。六個遠處的人聲（鋸齒波聲帶＋一個共振峰，音節一個個起伏、句子之間停頓）疊成聽不出內容的嗡嗡聲＋岩洞的空氣聲＋兩道短回音＋偶爾很小的碰撞聲。
- title_theme：標題畫面的配樂（可循環 24 秒，D-181；走 Music 匯流排）。低低的長音鋪底（D2＋A2＋D3，每個音兩個微微走音的聲部互相拍頻，12 秒一次慢慢漲落）＋霧裡遠遠的鐘聲動機：D4、C4、A3 往下走三聲，十二秒後 D4、C4 再往下落到 F3（第二次停在更低的地方）；鐘聲低通、帶三個越來越悶的回音。
- step_dirt／step_stone／step_wood：腳步聲（D-182，各約 0.12～0.16 秒；播放時音高與音量隨機一點）。土（森林）：軟軟的低頻悶聲＋幾片乾葉子碎掉的細響；石：很短的低頻「咚」＋一點砂粒的高頻擦聲；木：中空的「叩」（180／420 Hz 兩個共鳴快速衰減）＋一點木板的吱。
- part_end_theme：第一部前半的收尾配樂（可循環 28 秒，D-188；結尾卡＋感謝試玩頁，走 Music 匯流排）。回答標題的鐘聲：標題是往下走（D4、C4、A3，第二次落到 F3），這裡從 F3 往上走（F3、A3、C4），第二次 A3、C4 停在 D4＝標題開頭那個音。底下是 F2＋C3 的長音（比收束的小三度暖一點）＋很小聲的 A3，14 秒一次漲落；鐘聲帶三個越來越悶的回音。
- step_heavy：送葬者的拖步（D-187，約 0.65 秒；不分地面）。很重的低頻「咚」（72 → 38 Hz 往下掉、加一個高八度的泛音讓小喇叭也聽得到）＋落地的悶悶碎響＋拖在後面的鐵鏈擦地（高通噪音、斷斷續續地抖）＋三下鐵環碰撞。
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


def market_murmur(seconds=12.0, seed=131):
    """地下市場的底噪（可循環 12 秒，D-230）：六個遠處的人聲疊起來（聽不出內容的嗡嗡聲，有起伏、不會整片安靜）
    ＋岩洞裡低低的空氣聲＋兩道短回音（岩壁）＋偶爾一聲很小的鍋蓋／瓶子的碰撞。頭尾交叉淡化。"""
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
    # 遠、隔著攤子與布棚：高頻收掉
    crowd = onepole_lp(onepole_lp(crowd, 2400), 3200)
    room = onepole_lp(onepole_lp(hp(noise(total, rng), 60), 260), 340)
    out = [crowd[i] + room[i] * 2.2 for i in range(total)]
    # 岩壁的兩道短回音
    for delay, amount in ((int(0.083 * RATE), 0.3), (int(0.137 * RATE), 0.22)):
        for i in range(delay, total):
            out[i] += out[i - delay] * amount
    peak = max(abs(v) for v in out) or 1.0
    out = [v / peak for v in out]
    # 偶爾的小碰撞聲（鍋蓋、玻璃瓶）：很小聲，不落在交叉淡化的那一段
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


def part_end_theme(seconds=28.0, seed=97):
    """第一部前半的收尾配樂（D-188）：F2＋C3 的長音、往上走的鐘聲（回答標題往下走的那三聲），第二次停在 D4。"""
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


def step_heavy(seed=89):
    """送葬者的拖步：很重的「咚」＋落地碎響＋拖在後面的鐵鏈擦地＋三下鐵環碰撞。"""
    rng = random.Random(seed)
    n = int(0.66 * RATE)
    out = [0.0] * n
    body = onepole_lp(noise(n, rng), 320)
    phase = 0.0
    for i in range(n):
        t = i / RATE
        f = 38.0 + 34.0 * math.exp(-t * 14.0)
        phase += 2 * math.pi * f / RATE
        attack = min(1.0, t / 0.004)
        boom = (math.sin(phase) + 0.7 * math.sin(2.0 * phase)) * math.exp(-t * 8.5) * attack
        out[i] = boom + body[i] * 2.4 * math.exp(-t * 16.0) * attack
    crunch = onepole_lp(hp(noise(int(0.07 * RATE), rng), 400), 2400)
    for i, v in enumerate(crunch):
        out[i] += 0.32 * v * math.exp(-(i / RATE) * 55.0) * min(1.0, (i / RATE) / 0.004)
    # 鐵鏈擦地：0.08～0.62 秒，忽大忽小地抖（兩個不成比例的慢正弦相乘）
    drag = onepole_lp(hp(noise(n, rng), 1600), 5200)
    t0, t1 = 0.08, 0.62
    for i in range(int(t0 * RATE), min(n, int(t1 * RATE))):
        t = i / RATE
        w = math.sin(math.pi * (t - t0) / (t1 - t0)) ** 1.5
        flutter = 0.55 + 0.45 * math.sin(2 * math.pi * 23.0 * t + 0.7) * math.sin(2 * math.pi * 6.3 * t)
        out[i] += 0.17 * drag[i] * w * flutter
    for at, f in [(0.11, 1750.0), (0.27, 2320.0), (0.44, 1980.0)]:
        start = int(at * RATE)
        for j in range(int(0.09 * RATE)):
            if start + j >= n:
                break
            t = j / RATE
            v = math.sin(2 * math.pi * f * t) + 0.5 * math.sin(2 * math.pi * f * 2.71 * t)
            out[start + j] += 0.1 * v * math.exp(-t * 60.0)
    # 尾巴 20 ms 淡出，避免截斷的爆音
    fade = int(0.02 * RATE)
    for j in range(fade):
        out[n - 1 - j] *= j / fade
    return out


def poison_hiss(seconds=0.9, seed=107):
    """噴毒（D-207）：高頻的嘶聲（滑動的帶通噪音＋一點更高的氣聲），快起慢落＋一聲很短的低頻「噗」。"""
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


def main():
    made = [
        write("blunt", thump(0.3, 140, 55, seed=2)),
        write("blunt_weak", thump(0.38, 170, 50, crack=0.8, seed=3)),
        write("claw", swish(0.22, 1800, 9000, seed=4, rise=0.2)),
        write("slash", swish(0.28, 900, 7000, seed=5, rise=0.3, metal=0.25)),
        write("whoosh", swish(0.35, 200, 1600, seed=6, rise=0.45)),
        write("rubble_scrape", scrape()),
        write("iron_clang", clang()),
        write("ui_tick", ui_tick()),
        write("market_murmur", market_murmur()),
        write("title_theme", title_theme()),
        write("part_end_theme", part_end_theme()),
        write("step_dirt", step_dirt()),
        write("step_stone", step_stone()),
        write("step_wood", step_wood()),
        write("step_heavy", step_heavy()),
        write("poison_hiss", poison_hiss(0.9, seed=109)),
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
    ]
    for p in made:
        print(f"{p.name}: {p.stat().st_size // 1024} KB")


if __name__ == "__main__":
    sys.exit(main())
