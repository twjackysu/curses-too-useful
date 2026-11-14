class_name SlashMark
extends MeshInstance3D
## 砍中的那一點閃一道刀痕：一條兩頭尖的亮線，照劍掃過去的方向橫過敵人身上——一出現就有六成長，
## 很快衝到全長，再變細、淡掉。看得出是「劍砍的」、往哪裡砍的（碎屑與閃光看不出來）。
## 顏色跟劍光（SlashTrail）同一組：平常鏽色，身上有反轉中的狀態是金的；收尾的那一刀比較長、比較粗、留得比較久。
## 面向鏡頭只在生出來的那一刻算一次（只活 0.2 秒）。照遊戲時間走：打擊停頓時整條亮線停在敵人身上。

const SHADER: Shader = preload("res://src/world/slash_mark.gdshader")
const LENGTH: float = 1.9
const LENGTH_BIG: float = 2.9
const WIDTH: float = 0.22
const WIDTH_BIG: float = 0.36
const LIFE: float = 0.2
const LIFE_BIG: float = 0.28
## 一出現就有全長的幾成；SHOOT_SEC 秒內衝到全長
const START_LEN: float = 0.6
const SHOOT_SEC: float = 0.05
const RUST_STRENGTH: float = 1.5
const GOLD_STRENGTH: float = 2.6

var gold: bool = false
var big: bool = false
## 截圖用：停在剛砍下去的樣子，不淡、不收
var hold: bool = false

var _age: float = 0.0
var _mat: ShaderMaterial


## 在 at（世界座標）閃一道。cut＝劍往哪裡掃；to_eye＝從那一點看向鏡頭的方向。
static func spawn(parent: Node, at: Vector3, cut: Vector3, to_eye: Vector3, is_gold: bool, is_big: bool) -> SlashMark:
	var m := SlashMark.new()
	m.name = "SlashMark"
	m.gold = is_gold
	m.big = is_big
	m.top_level = true
	m.mesh = QuadMesh.new()
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m._mat = ShaderMaterial.new()
	m._mat.shader = SHADER
	m._mat.set_shader_parameter("tint", SlashTrail.GOLD_TINT if is_gold else SlashTrail.RUST_CORE)
	m._mat.set_shader_parameter("core", SlashTrail.GOLD_CORE if is_gold else Color(1.0, 0.85, 0.7))
	m._mat.set_shader_parameter("strength", GOLD_STRENGTH if is_gold else RUST_STRENGTH)
	m.material_override = m._mat
	parent.add_child(m)
	# top_level：自己的 transform 就是世界座標
	m.transform = Transform3D(facing(cut, to_eye), at)
	m._apply()
	return m


## 刀痕的朝向：x 軸沿著劍掃的方向（壓到畫面上）、z 軸朝鏡頭。劍剛好朝著鏡頭掃（壓到畫面上幾乎沒有長度）就用一條斜線。純函式。
static func facing(cut: Vector3, to_eye: Vector3) -> Basis:
	var z: Vector3 = to_eye.normalized() if to_eye.length() > 0.001 else Vector3.BACK
	var x: Vector3 = cut - z * cut.dot(z)
	if x.length() < 0.2 * maxf(cut.length(), 0.005):
		var side: Vector3 = Vector3.UP.cross(z)
		x = (side.normalized() if side.length() > 0.001 else Vector3.RIGHT) - Vector3.UP
		x -= z * x.dot(z)
	x = x.normalized()
	return Basis(x, z.cross(x), z)


## 現在多長、多寬（m）
func size() -> Vector2:
	var k: float = clampf(_age / (LIFE_BIG if big else LIFE), 0.0, 1.0)
	var shoot: float = 1.0 - pow(1.0 - clampf(_age / SHOOT_SEC, 0.0, 1.0), 2.0)
	return Vector2((LENGTH_BIG if big else LENGTH) * lerpf(START_LEN, 1.0, shoot), (WIDTH_BIG if big else WIDTH) * (1.0 - 0.75 * k))


func _process(delta: float) -> void:
	if hold:
		return
	_age += delta
	if _age >= (LIFE_BIG if big else LIFE):
		queue_free()
		return
	_apply()


func _apply() -> void:
	var s: Vector2 = size()
	var b: Basis = basis.orthonormalized()
	basis = Basis(b.x * s.x, b.y * s.y, b.z)
	var k: float = _age / (LIFE_BIG if big else LIFE)
	_mat.set_shader_parameter("fade", 1.0 - k * k)
