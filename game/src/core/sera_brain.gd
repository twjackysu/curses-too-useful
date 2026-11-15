class_name SeraBrain
extends RefCounted
## 席菈在場上要做什麼（純邏輯；數值在 data/combat/tuning.json 的 sera）。
## 跟：離諾恩超過 follow_far 就跟上，走到 follow_near 以內才停（兩個數字之間不改主意，才不會一步一停）。
## 射：諾恩附近有敵人時倒數，時間到先舉弩瞄準 aim_time 秒再擊發；沒有敵人就把倒數退回「第一瓶」。
## 要：玩家按鍵向她要一瓶（request）——不管附近有沒有敵人，馬上舉弩；要過之後 ask_cooldown 秒內她還在裝填，不能再要。

enum State { READY, AIM }

## 還沒結伴、一個人站在瘴氣前面的時候（劇本節點 2：她不敢自己進去）：往瘴氣走幾步、停下來看、轉身走回原位、再回頭看，一直重複。
## 走到最近的地方離瘴氣的邊還有半公尺以上（不到戴面具的距離：相遇的時候要看得到臉）。
const HESITATE_STEP: float = 1.1
const HESITATE_SPEED: float = 1.2
## 一輪幾秒；前面這麼多秒是「往前走＋站在前面看」，剩下的是「走回去＋站在原位看」
const HESITATE_CYCLE_SEC: float = 6.0
const HESITATE_IN_SEC: float = 2.4

var state: State = State.READY
## 正在往諾恩走
var following: bool = false
## 離開始瞄準還有幾秒（只在附近有敵人時倒數）
var shot_left: float = 0.0
## 舉著弩還要瞄幾秒
var aim_left: float = 0.0
## 剛要過一瓶：還要幾秒才能再要（她在裝填）
var ask_left: float = 0.0
var _requested: bool = false


func _init() -> void:
	shot_left = CombatTuning.num("sera.first_vial_delay", 1.5)


## 猶豫的第 t 秒，她想站在「原位往瘴氣」幾公尺的地方（0＝原位）。
static func hesitate_goal(t: float) -> float:
	return HESITATE_STEP if fposmod(t, HESITATE_CYCLE_SEC) < HESITATE_IN_SEC else 0.0


## 這一幀要往諾恩走多快（m/s；0＝站著）。dist＝跟諾恩的水平距離。瞄準中不走。
func follow_speed(dist: float) -> float:
	var far: float = CombatTuning.num("sera.follow_far", 6.0)
	if dist > far:
		following = true
	elif dist <= CombatTuning.num("sera.follow_near", 4.5):
		following = false
	if not following or state == State.AIM:
		return 0.0
	if dist > far + CombatTuning.num("sera.run_extra", 3.0):
		return CombatTuning.num("sera.run_speed", 5.6)
	return CombatTuning.num("sera.walk_speed", 3.2)


## 每幀呼叫一次。threat＝諾恩附近有活著的敵人。回傳 true＝這一幀擊發。
func tick(delta: float, threat: bool) -> bool:
	ask_left = maxf(ask_left - delta, 0.0)
	if state == State.AIM:
		aim_left -= delta
		if aim_left > 0.0:
			return false
		state = State.READY
		shot_left = CombatTuning.num("sera.vial_interval", 9.0)
		return true
	if _requested:
		shot_left = 0.0
	elif not threat:
		shot_left = CombatTuning.num("sera.first_vial_delay", 1.5)
		return false
	shot_left -= delta
	if shot_left <= 0.0:
		_requested = false
		state = State.AIM
		aim_left = CombatTuning.num("sera.aim_time", 0.6)
	return false


## 現在就要一瓶：不管附近有沒有敵人，下一幀就開始瞄準。回傳她答不答應——
## 正舉著弩、已經答應了一瓶還沒射、或剛要過（ask_cooldown 秒內還在裝填）＝false，什麼都不變。
func request() -> bool:
	if state == State.AIM or _requested or ask_left > 0.0:
		return false
	_requested = true
	ask_left = CombatTuning.num("sera.ask_cooldown", 10.0)
	return true


func is_aiming() -> bool:
	return state == State.AIM
