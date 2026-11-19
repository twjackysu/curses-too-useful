class_name ScreenFade
extends CanvasLayer
## 換關卡的黑幕：Game 持有一個（跨場景留著）。換之前淡成黑再換（章節卡播完已經是黑的，就直接換），
## 新的一關載入之後停幾幀、從黑淡進來——不會「卡一下新的一關就整個跳出來」。
## 淡的速度一幀最多算 MAX_STEP 秒：載入卡住的那一幀（森林要種一百六十幾棵樹）不會把淡入一口氣吃掉。
## 用真實時間（打擊停頓的慢動作不影響）；暫停時照樣跑（暫停選單的「回標題」）。
## 聲音跟著畫面一起收：Master 匯流排上掛一個 AudioEffectAmplify（不動設定頁的音量），
## 變黑的時候一起變小聲、新的一關淡進來的時候一起變大聲（`duck`：0＝照常、1＝聽不到）。

const LAYER: int = 45
const OUT_SEC: float = 0.45
const IN_SEC: float = 0.9
## 新的一關載入後先黑著幾幀（第一幀常常還在擺鏡頭、編 shader）
const HOLD_FRAMES: int = 4
const MAX_STEP: float = 1.0 / 30.0
const COLOR: Color = Color(0.015, 0.017, 0.025, 1.0)

## 現在多黑（0＝看得到畫面、1＝全黑）
var alpha: float = 0.0
## 正在往哪裡淡
var target: float = 0.0
var _sec: float = IN_SEC
var _hold: int = 0
var _then: Callable = Callable()
var _rect: ColorRect
## 聲音收了多少（0＝照常、1＝聽不到）
var duck: float = 0.0
var _duck_target: float = 0.0
var _duck_sec: float = IN_SEC
var _amp: AudioEffectAmplify


func _init() -> void:
	name = "ScreenFade"
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.name = "Black"
	_rect.color = COLOR
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)
	_apply()


func _ready() -> void:
	_amp = AudioEffectAmplify.new()
	AudioServer.add_bus_effect(0, _amp)
	_apply_audio()


func _exit_tree() -> void:
	if _amp == null:
		return
	for i: int in AudioServer.get_bus_effect_count(0):
		if AudioServer.get_bus_effect(0, i) == _amp:
			AudioServer.remove_bus_effect(0, i)
			break
	_amp = null


## 這一幀淡多少（純函式，測試用）：一幀最多算 MAX_STEP 秒
static func step(from: float, to: float, delta: float, sec: float) -> float:
	return move_toward(from, to, minf(maxf(delta, 0.0), MAX_STEP) / maxf(sec, 0.001))


## 淡成黑（聲音一起收），黑了之後呼叫 then（已經是黑的就馬上呼叫）
func fade_out(then: Callable = Callable(), sec: float = OUT_SEC) -> void:
	target = 1.0
	_sec = sec
	_hold = 0
	_then = then
	duck_to(1.0, sec if alpha < 1.0 else maxf(sec * 0.5, 0.05))
	if alpha >= 1.0:
		_done()


## 從現在的黑淡進來（先停 hold 幀；聲音一起回來）
func fade_in(sec: float = IN_SEC, hold: int = HOLD_FRAMES) -> void:
	_then = Callable()
	target = 0.0
	_sec = sec
	_hold = hold
	duck_to(0.0, sec)


## 聲音馬上收到 v（製作名單最後跟著字一起收）
func set_duck(v: float) -> void:
	duck = clampf(v, 0.0, 1.0)
	_duck_target = duck
	_apply_audio()


## 現在 Master 上那一層的音量（dB；測試用）
func duck_db() -> float:
	return _amp.volume_db if _amp != null else 0.0


## 聲音在 sec 秒內收到 to（章節卡播的時候慢慢收掉這一關的聲音）
func duck_to(to: float, sec: float) -> void:
	_duck_target = clampf(to, 0.0, 1.0)
	_duck_sec = maxf(sec, 0.001)


## 馬上全黑（章節卡播完的那一刻：畫面已經是卡的黑）
func cover() -> void:
	alpha = 1.0
	target = 1.0
	_hold = 0
	_apply()
	_done()


## 馬上看得到畫面（測試不換場景時）
func clear() -> void:
	_then = Callable()
	alpha = 0.0
	target = 0.0
	_hold = 0
	duck = 0.0
	_duck_target = 0.0
	_apply()
	_apply_audio()


## 正在變黑或黑著等換場景：玩家不能動
func covering() -> bool:
	return target >= 1.0


func _process(delta: float) -> void:
	if _hold > 0:
		_hold -= 1
		return
	var real: float = delta / maxf(Engine.time_scale, 0.01)
	if not is_equal_approx(duck, _duck_target):
		duck = step(duck, _duck_target, real, _duck_sec)
		_apply_audio()
	if is_equal_approx(alpha, target):
		return
	alpha = step(alpha, target, real, _sec)
	_apply()
	if alpha >= 1.0 and target >= 1.0:
		_done()


func _done() -> void:
	var f: Callable = _then
	_then = Callable()
	if f.is_valid():
		f.call()


func _apply_audio() -> void:
	if _amp != null:
		_amp.volume_db = maxf(linear_to_db(maxf(1.0 - duck, 0.0001)), -80.0)


func _apply() -> void:
	_rect.modulate.a = alpha
	visible = alpha > 0.001
