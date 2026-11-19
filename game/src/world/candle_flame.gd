class_name CandleFlame
extends Node3D
## 一朵火苗（公會的壁燈、吊燈上的蠟燭）：一片直立、面向鏡頭的火（candle_flame.gdshader），
## 要的話再帶一盞會閃的小燈（亮度照幾個不同快慢的 sin 疊起來，每一盞錯開）。

const SHADER: Shader = preload("res://src/world/candle_flame.gdshader")
## 閃的幅度（燈的亮度在 1 ± 這個比例之間跳）
const FLICKER: float = 0.18
## 面片比火苗大幾倍（外圈畫火光；跟 shader 的 spread 一樣）；火苗的底在面片從上往下 0.806 的地方
const SPREAD: float = 1.8
const BASE_V: float = 0.5 + 0.55 / SPREAD

var light: OmniLight3D
var _base_energy: float = 0.0
var _phase: float = 0.0
var _t: float = 0.0


## size＝火苗的寬、高（公尺）；halo＝外圈的火光多亮；pull＝往鏡頭拉近幾公尺（火在實心的燈籠裡面時）；
## light_energy > 0 就帶一盞燈（reach＝照多遠）
static func create(size: Vector2, phase: float, halo: float = 0.2, pull: float = 0.0, light_energy: float = 0.0,
		reach: float = 3.0, color: Color = Color(1.0, 0.66, 0.36)) -> CandleFlame:
	var f := CandleFlame.new()
	f.name = "Flame"
	f._phase = phase * 7.3
	var mi := MeshInstance3D.new()
	mi.name = "FlameQuad"
	var q := QuadMesh.new()
	q.size = size * SPREAD
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("seed", phase)
	m.set_shader_parameter("spread", SPREAD)
	m.set_shader_parameter("halo", halo)
	m.set_shader_parameter("pull", pull)
	q.material = m
	mi.mesh = q
	# 火苗的底在節點的位置（面片往上長）
	mi.position = Vector3(0, size.y * SPREAD * (BASE_V - 0.5), 0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	f.add_child(mi)
	if light_energy > 0.0:
		f.light = OmniLight3D.new()
		f.light.name = "FlameLight"
		f.light.light_color = color
		f.light.light_energy = light_energy
		f.light.omni_range = reach
		f.light.shadow_enabled = false
		f.light.position = Vector3(0, size.y * 0.5, 0)
		f._base_energy = light_energy
		f.add_child(f.light)
	return f


func _process(delta: float) -> void:
	if light == null:
		return
	_t += delta
	var w: float = 0.55 * sin(_t * 9.1 + _phase) + 0.3 * sin(_t * 15.7 + _phase * 1.9) + 0.15 * sin(_t * 3.3 + _phase * 0.7)
	light.light_energy = _base_energy * (1.0 + FLICKER * w)
