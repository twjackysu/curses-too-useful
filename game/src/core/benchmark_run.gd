class_name BenchmarkRun
extends RefCounted
## 一次 benchmark 的計時與統計（純邏輯）。暖機時間不計入；超過 SPIKE_MS 的幀記為尖峰
## （常見原因：第一次出現某材質時編譯 shader）。

const SPIKE_MS: float = 50.0
const MAX_SPIKES: int = 64

var duration_sec: float
var warmup_sec: float
var elapsed: float = 0.0
var stats: FrameStats
var spikes: Array[Dictionary] = []
## 照幀數跑（>0）：雲端只有軟體算圖、一幀要一兩秒，照秒數跑只拍得到幾幀——改成固定跑這麼多幀、前 warmup_frames 幀不算
var frame_limit: int = 0
var warmup_frames: int = 0
var frames: int = 0
## 每一幀畫了多少東西（跟機器快慢無關：雲端量的也能比改前改後）
var _render_frames: int = 0
var _draw_calls_sum: float = 0.0
var _draw_calls_max: int = 0
var _objects_sum: float = 0.0
var _primitives_sum: float = 0.0
var _last_counted: bool = false


func _init(p_duration_sec: float = 30.0, p_warmup_sec: float = 2.0) -> void:
	duration_sec = maxf(p_duration_sec, 1.0)
	warmup_sec = maxf(p_warmup_sec, 0.0)
	stats = FrameStats.new(int(ceil(duration_sec * 240.0)))


## 照幀數跑的一次：count 幀（不含暖機的 warmup 幀）。
static func by_frames(count: int, warmup: int = 5) -> BenchmarkRun:
	var run := BenchmarkRun.new(1.0, 0.0)
	run.frame_limit = maxi(count, 1)
	run.warmup_frames = maxi(warmup, 0)
	run.stats = FrameStats.new(run.frame_limit + 1)
	return run


## 0～1，給鏡頭路徑用（含暖機）。
func progress() -> float:
	if frame_limit > 0:
		return clampf(float(frames) / float(warmup_frames + frame_limit), 0.0, 1.0)
	return clampf(elapsed / (warmup_sec + duration_sec), 0.0, 1.0)


func is_finished() -> bool:
	if frame_limit > 0:
		return frames >= warmup_frames + frame_limit
	return elapsed >= warmup_sec + duration_sec


func _warming_up() -> bool:
	return frames < warmup_frames if frame_limit > 0 else elapsed < warmup_sec


## 每幀呼叫；回傳是否已結束。
func push(delta_sec: float) -> bool:
	if is_finished():
		_last_counted = false
		return true
	var frame_ms: float = delta_sec * 1000.0
	if frame_ms > SPIKE_MS and spikes.size() < MAX_SPIKES:
		spikes.append({"t": snappedf(elapsed, 0.01), "ms": snappedf(frame_ms, 0.1)})
	_last_counted = not _warming_up()
	if _last_counted:
		stats.push(frame_ms)
	elapsed += delta_sec
	frames += 1
	return is_finished()


## 這一幀畫了幾次（draw calls）、幾個東西、幾個三角面：跟在 push() 後面呼叫，那一幀算進統計才算（暖機的不算）。
func push_render(draw_calls: int, objects: int, primitives: int) -> void:
	if not _last_counted:
		return
	_render_frames += 1
	_draw_calls_sum += float(draw_calls)
	_draw_calls_max = maxi(_draw_calls_max, draw_calls)
	_objects_sum += float(objects)
	_primitives_sum += float(primitives)


func render_dict() -> Dictionary:
	var n: float = maxf(float(_render_frames), 1.0)
	return {
		"frames": _render_frames,
		"draw_calls_avg": snappedf(_draw_calls_sum / n, 0.1),
		"draw_calls_max": _draw_calls_max,
		"objects_avg": snappedf(_objects_sum / n, 0.1),
		"primitives_avg_k": snappedf(_primitives_sum / n / 1000.0, 0.1),
	}


func to_dict(meta: Dictionary = {}) -> Dictionary:
	var d: Dictionary = meta.duplicate(true)
	d["duration_sec"] = duration_sec
	d["warmup_sec"] = warmup_sec
	d["stats"] = stats.to_dict()
	d["spikes"] = spikes.duplicate(true)
	d["render"] = render_dict()
	if frame_limit > 0:
		d["frames"] = {"count": frame_limit, "warmup": warmup_frames}
	d["target"] = {"fps": 60, "frame_ms": 16.7}
	d["meets_target"] = stats.count() > 0 and stats.average_fps() >= 60.0 and stats.one_percent_low_fps() >= 45.0
	return d
