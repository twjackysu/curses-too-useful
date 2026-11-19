class_name GolemPhases
extends RefCounted
## 【深淵疫病魔像】這一場戰鬥走到哪（純邏輯；數值在 data/combat/tuning.json 的 plague_golem）。劇本節點 3：
## 平常（CALM）→ 生命掉到 enrage_at 就狂暴：先吼一聲（ROAR）→ 狂暴中照常出招（RAGE；席菈退到後面裝禁藥）→
## 擺石化凝視的前兆（GAZE）→ 凝視打出去：諾恩有沒有擋在席菈前面——擋住了魔像力竭跪下（SPENT），
## 沒擋住（席菈被石化）回到 RAGE，過一陣子再來一次。擋住過一次之後就不再凝視。
## 核心可以被粉碎（core_open：席菈的禁藥落在諾恩身上）之前，生命不會低於 hp_floor——凝視那一拍一定演得到。

enum Phase { CALM, ROAR, RAGE, GAZE, SPENT }

var phase: Phase = Phase.CALM
var time_in_phase: float = 0.0
## 凝視打出去幾次；擋住過了沒
var gazes: int = 0
var blocked: bool = false
var core_open: bool = false

var enrage_at: float = 0.5
var roar_sec: float = 2.2
var rage_sec: float = 8.0
var gaze_sec: float = 3.6
var spent_sec: float = 9.0
var hp_floor: float = 0.15
var block_width: float = 1.4


func configure(prefix: String = "plague_golem") -> GolemPhases:
	enrage_at = CombatTuning.num(prefix + ".enrage_at", enrage_at)
	roar_sec = CombatTuning.num(prefix + ".roar_sec", roar_sec)
	rage_sec = CombatTuning.num(prefix + ".rage_sec", rage_sec)
	gaze_sec = CombatTuning.num(prefix + ".gaze_sec", gaze_sec)
	spent_sec = CombatTuning.num(prefix + ".spent_sec", spent_sec)
	hp_floor = CombatTuning.num(prefix + ".hp_floor", hp_floor)
	block_width = CombatTuning.num(prefix + ".block_width", block_width)
	return self


## 每幀呼叫一次。回傳這一幀發生的事：""、"enrage"（開始吼）、"rage"（吼完，開始狂暴地出招）、"gaze"（開始擺凝視的前兆）、
## "fire"（凝視打出去——呼叫的人判定擋住了沒，馬上叫 resolve_gaze）、"recover"（力竭跪完）。
func tick(delta: float, hp_ratio: float) -> String:
	time_in_phase += delta
	match phase:
		Phase.CALM:
			if hp_ratio <= enrage_at:
				_enter(Phase.ROAR)
				return "enrage"
		Phase.ROAR:
			if time_in_phase >= roar_sec:
				_enter(Phase.RAGE)
				return "rage"
		Phase.RAGE:
			if not blocked and time_in_phase >= rage_sec:
				_enter(Phase.GAZE)
				return "gaze"
		Phase.GAZE:
			if time_in_phase >= gaze_sec:
				return "fire"
		Phase.SPENT:
			if time_in_phase >= spent_sec:
				_enter(Phase.RAGE)
				return "recover"
	return ""


## 凝視打出去的結果：擋住了 → 力竭；沒擋住 → 回去狂暴，之後再凝視一次。
func resolve_gaze(p_blocked: bool) -> void:
	if phase != Phase.GAZE:
		return
	gazes += 1
	blocked = blocked or p_blocked
	_enter(Phase.SPENT if p_blocked else Phase.RAGE)


func is_enraged() -> bool:
	return phase != Phase.CALM


## 凝視的前兆擺到幾成（0～1；不在擺的時候是 0）
func gaze_progress() -> float:
	return clampf(time_in_phase / gaze_sec, 0.0, 1.0) if phase == Phase.GAZE else 0.0


## 席菈的禁藥裝到幾成（狂暴之後她退到後面跪著裝；-1＝還沒開始、或已經擋住凝視、射出去了）。吼＋狂暴＋凝視的前兆一路裝，
## 凝視打出去的那一刻剛好裝滿——玩家看得出「擋住這一下，她就好了」。沒擋住（她被石化）重來一輪狂暴＋前兆，從一半開始裝
func brew_progress() -> float:
	if phase == Phase.CALM or phase == Phase.SPENT or blocked:
		return -1.0
	var first: bool = gazes == 0
	var lead: float = roar_sec if first else 0.0
	var done: float = time_in_phase
	if phase == Phase.RAGE:
		done += lead
	elif phase == Phase.GAZE:
		done += lead + rage_sec
	var start: float = 0.0 if first else 0.5
	return clampf(start + (1.0 - start) * done / maxf(lead + rage_sec + gaze_sec, 0.01), 0.0, 1.0)


## 生命最低可以被打到剩幾成：核心還不能粉碎的時候不低於 hp_floor
func floor_ratio() -> float:
	return 0.0 if core_open else hp_floor


## 諾恩有沒有擋在魔像與席菈中間（看水平位置）：他離「魔像 → 席菈」那條線不到 width，而且在兩人之間——
## 站在魔像背後、站在席菈後面都不算。
static func blocks(golem: Vector3, sera: Vector3, norn: Vector3, width: float) -> bool:
	var a := Vector2(golem.x, golem.z)
	var ab := Vector2(sera.x, sera.z) - a
	if ab.length() < 0.1:
		return false
	var u: float = (Vector2(norn.x, norn.z) - a).dot(ab) / ab.length_squared()
	if u <= 0.05 or u >= 1.0:
		return false
	return (a + ab * u).distance_to(Vector2(norn.x, norn.z)) <= width


func _enter(p: Phase) -> void:
	phase = p
	time_in_phase = 0.0
