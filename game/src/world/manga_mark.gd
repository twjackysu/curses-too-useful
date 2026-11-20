class_name MangaMark
extends MeshInstance3D
## 漫符：講話的人頭上（或臉上）冒出來的符號——汗、怒筋、閃亮、臉紅、驚嚇線、陰影線、問號。
## 一片面向鏡頭的面片（`manga_mark.gdshader` 用距離場畫，不用貼圖）。跳出來的時候彈一下，`dismiss()` 之後淡掉、自己消失。
## 掛在角色底下但不跟著轉（top_level）：每一幀照那個人頭的位置與鏡頭的方向擺。
## 臉紅、陰影線貼在臉的前面：臉轉開（鏡頭看到側面、後腦）就跟著淡掉，不會浮在後腦勺上。

## 順序跟 shader 的 kind 一樣
const KINDS: PackedStringArray = ["sweat", "anger", "sparkle", "blush", "shock", "gloom", "question"]
## 每一種的大小（m）與擺在哪：side＝往鏡頭的右邊、up＝往上、front＝往臉的前面（都從頭骨頭的位置量）
const LOOK: Dictionary = {
	"sweat": {"size": 0.16, "side": 0.17, "up": 0.2, "front": 0.0},
	"anger": {"size": 0.15, "side": 0.16, "up": 0.22, "front": 0.0},
	"sparkle": {"size": 0.22, "side": 0.24, "up": 0.24, "front": 0.0},
	"blush": {"size": 0.17, "side": 0.0, "up": -0.005, "front": 0.13},
	"shock": {"size": 0.26, "side": 0.0, "up": 0.34, "front": 0.0},
	"gloom": {"size": 0.26, "side": 0.0, "up": 0.08, "front": 0.12},
	"question": {"size": 0.15, "side": 0.19, "up": 0.3, "front": 0.0},
}
const FACE_KINDS: PackedStringArray = ["blush", "gloom"]
## 對話裡冒出來時的聲音（漫畫的效果音）：驚嚇與怒筋「咚！」、閃亮與臉紅「叮♪」、汗與陰影線「咻～」、問號「嗯？」
const SOUND: Dictionary = {
	"sweat": "manga_drop", "anger": "manga_shock", "sparkle": "manga_sparkle", "blush": "manga_sparkle",
	"shock": "manga_shock", "gloom": "manga_drop", "question": "manga_question",
}
const SOUND_DB: float = -9.0
const POP_SEC: float = 0.2
const FADE_SEC: float = 0.25
## 汗往下滑多少（m）
const SWEAT_SLIDE: float = 0.06
## 頭骨頭在頸子上面：臉的中間大約再高這麼多（找不到頭的時候從腳下量 HEAD_FALLBACK）
const HEAD_FALLBACK: float = 1.55
## 離鏡頭遠的人（雷歐羞辱時站在幾公尺外）頭上的漫符跟著放大：離鏡頭 GROW_FROM 公尺以內照原本的大小，
## 再遠照距離放大、最多 GROW_MAX 倍（D-309；以前一律幾公分，遠的人頭上只剩一個小點）。貼在臉上的（臉紅、陰影線）不放大：會蓋出臉外面
const GROW_FROM: float = 3.0
const GROW_MAX: float = 2.0

static var _shader: Shader

var kind: String = "sweat"
## 跟著誰（角色的根節點）與他的頭（Puppet 的 head 掛點；沒有就用 who 的位置往上量）
var who: Node3D
var head: Node3D
var age: float = 0.0
var _leaving: float = -1.0
var _mat: ShaderMaterial


## 在 who 的頭上冒一個漫符。puppet 可以是 null（就用腳下往上量）。kind 不認得回傳 null。
static func pop(kind_name: String, p_who: Node3D, puppet: Puppet = null) -> MangaMark:
	if not KINDS.has(kind_name) or p_who == null:
		return null
	var m := MangaMark.new()
	m.kind = kind_name
	m.who = p_who
	if puppet != null:
		m.head = puppet.joint("head") if puppet.joint("head") != null else puppet.joint("neck")
	m.name = "MangaMark_" + kind_name
	p_who.add_child(m)
	return m


func _ready() -> void:
	top_level = true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var q := QuadMesh.new()
	var size: float = float((LOOK[kind] as Dictionary)["size"])
	q.size = Vector2(size, size)
	mesh = q
	if _shader == null:
		_shader = load("res://src/world/manga_mark.gdshader") as Shader
	_mat = ShaderMaterial.new()
	_mat.shader = _shader
	_mat.set_shader_parameter("kind", KINDS.find(kind))
	_mat.render_priority = 2
	material_override = _mat
	_place()


## 收起來：淡掉之後自己消失
func dismiss() -> void:
	if _leaving < 0.0:
		_leaving = 0.0


func is_leaving() -> bool:
	return _leaving >= 0.0


func _process(delta: float) -> void:
	age += delta
	if _leaving >= 0.0:
		_leaving += delta
		if _leaving >= FADE_SEC:
			queue_free()
			return
	_place()


## 彈出來的大小：0 → 1.15 → 1
static func pop_scale(t: float) -> float:
	if t >= POP_SEC:
		return 1.0
	var u: float = t / POP_SEC
	return sin(u * PI * 0.75) / sin(PI * 0.75) * (1.0 + 0.15 * (1.0 - u)) if u < 1.0 else 1.0


func _place() -> void:
	if who == null or not is_instance_valid(who):
		queue_free()
		return
	var cam: Camera3D = get_viewport().get_camera_3d() if is_inside_tree() else null
	var look: Dictionary = LOOK[kind] as Dictionary
	var at: Vector3 = head.global_position if head != null and is_instance_valid(head) else who.global_position + Vector3.UP * HEAD_FALLBACK
	var right: Vector3 = Vector3.RIGHT
	var to_cam: Vector3 = Vector3.BACK
	if cam != null:
		right = cam.global_basis.x
		to_cam = (cam.global_position - at).normalized()
	# 臉朝哪：Puppet 的頭掛點跟人偶同一個方向（−Z 朝前），轉頭、低頭都跟著；沒有就用整個人的方向
	var f: Vector3 = -(head.global_basis.z if head != null and is_instance_valid(head) else who.global_basis.z)
	var face: Vector3 = Vector3(f.x, 0.0, f.z).normalized() if Vector3(f.x, 0.0, f.z).length() > 0.2 else Vector3.FORWARD
	var grow: float = 1.0
	if cam != null and not FACE_KINDS.has(kind):
		grow = clampf(cam.global_position.distance_to(at) / GROW_FROM, 1.0, GROW_MAX)
	var pos: Vector3 = at + (right * float(look["side"]) + Vector3.UP * float(look["up"])) * grow + face * float(look["front"])
	if FACE_KINDS.has(kind) and head != null and is_instance_valid(head):
		# 貼在臉前面的（臉紅、陰影線）照頭自己的上與前擺：低著頭的時候臉往下、往前，貼的位置跟著低下去
		# （以前照世界的上擺，雷歐低頭時陰影線浮在頭頂上）
		var hb: Basis = head.global_basis.orthonormalized()
		pos = at + right * float(look["side"]) + hb.y * float(look["up"]) - hb.z * float(look["front"])
	if kind == "sweat":
		pos += Vector3.DOWN * SWEAT_SLIDE * clampf(age / 1.2, 0.0, 1.0)
	global_position = pos
	var s: float = pop_scale(age) * grow
	scale = Vector3.ONE * maxf(s, 0.001)
	var a: float = 1.0
	if FACE_KINDS.has(kind):
		# 臉轉開就淡掉：正對鏡頭 1、側面 0
		a = clampf(face.dot(Vector3(to_cam.x, 0.0, to_cam.z).normalized()) * 2.0 - 0.2, 0.0, 1.0)
	if _leaving >= 0.0:
		a *= 1.0 - _leaving / FADE_SEC
	_mat.set_shader_parameter("alpha", a)
	_mat.set_shader_parameter("age", age)
