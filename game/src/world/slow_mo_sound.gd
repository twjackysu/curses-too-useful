class_name SlowMoSound
extends Node
## 粉碎核心的那一刀（定格＋慢動作）時聲音跟著變：音效（SFX 匯流排）一下子悶下去（低通從聽得到全部掉到 CUTOFF_HZ）、
## 整個聲音放慢、變低（AudioServer.playback_speed_scale），慢動作演完再慢慢回來。
## 碎裂的那一聲剛好在悶下去之前（DIP_SEC 內）——先聽到「喀」，尾巴是悶悶拖長的。配樂另外收（RuinedAltar._fade_out_music）。
## 用真實時間（定格的時候遊戲時間幾乎不走）；被釋放時（倒下重來、換關卡）一定還原。

const BUS: StringName = &"SFX"
const OPEN_HZ: float = 20000.0
const CUTOFF_HZ: float = 650.0
## 多久悶到底、悶著多久（呼叫的人給：定格＋慢動作）、多久回來
const DIP_SEC: float = 0.12
const BACK_SEC: float = 0.9
## 悶到底的時候聲音放慢成幾倍
const SLOW_SPEED: float = 0.7

var hold_sec: float = 1.0
var filter: AudioEffectLowPassFilter
var _bus: int = -1
var _t: float = 0.0


## 開始（parent 被釋放時一起收掉）。hold＝悶著多久（真實時間，不含悶下去與回來）
static func play(parent: Node, hold: float) -> SlowMoSound:
	var n := SlowMoSound.new()
	n.name = "SlowMoSound"
	n.hold_sec = hold
	parent.add_child(n)
	return n


## 這一刻悶了多少（0＝照常、1＝悶到底）；t＝開始之後的真實秒數（純函式，測試用）
static func depth_at(t: float, hold: float) -> float:
	if t < DIP_SEC:
		return clampf(t / DIP_SEC, 0.0, 1.0)
	if t < DIP_SEC + hold:
		return 1.0
	return 1.0 - clampf((t - DIP_SEC - hold) / BACK_SEC, 0.0, 1.0)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bus = AudioServer.get_bus_index(BUS)
	if _bus < 0:
		return
	filter = AudioEffectLowPassFilter.new()
	filter.cutoff_hz = OPEN_HZ
	AudioServer.add_bus_effect(_bus, filter)


func depth() -> float:
	return depth_at(_t, hold_sec)


func _process(delta: float) -> void:
	_t += delta / maxf(Engine.time_scale, 0.01)
	var k: float = depth()
	# 頻率照比例掉（線性掉的話前半段聽不出差別）
	if filter != null:
		filter.cutoff_hz = OPEN_HZ * pow(CUTOFF_HZ / OPEN_HZ, k)
	AudioServer.playback_speed_scale = lerpf(1.0, SLOW_SPEED, k)
	if _t >= DIP_SEC + hold_sec + BACK_SEC:
		queue_free()


func _exit_tree() -> void:
	AudioServer.playback_speed_scale = 1.0
	if filter == null or _bus < 0:
		return
	for i: int in AudioServer.get_bus_effect_count(_bus):
		if AudioServer.get_bus_effect(_bus, i) == filter:
			AudioServer.remove_bus_effect(_bus, i)
			break
	filter = null
