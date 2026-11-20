class_name SlashTrail
extends MeshInstance3D
## 揮劍的劍光：揮的那一段每一幀記下手與劍尖在哪裡，拉成一條月牙形的帶子；每一段過了壽命就消失，
## 所以弧是跟在劍後面掃過去、再往劍縮回去，不是整片停在半空中。
## 跟著真的劍走（不是預先畫好的弧），所以換動作、換武器、出手變快都不用另外調。
## 掛在會跟著人轉的節點底下（諾恩的 Body）：位置記在那個節點的座標裡，人往前滑的時候弧不會被拉歪。

const SHADER: Shader = preload("res://src/world/slash_trail.gdshader")
## 平常：暗紅的鏽色（不夠亮，不會泛光）
const RUST_TINT: Color = Color(0.55, 0.1, 0.05)
const RUST_CORE: Color = Color(0.9, 0.36, 0.18)
const RUST_STRENGTH: float = 0.9
## 拿【不祥的裂刃】（PlayerController.WEAPONS 的 trail）：暗紫帶一點病態的亮紫（反轉中一樣是金色）
const SPLIT_TINT: Color = Color(0.4, 0.07, 0.55)
const SPLIT_CORE: Color = Color(0.82, 0.45, 1.0)
## 身上有反轉中的狀態：金色（亮到會泛光）
const GOLD_TINT: Color = Color(1.0, 0.72, 0.25)
const GOLD_CORE: Color = Color(1.0, 0.95, 0.75)
const GOLD_STRENGTH: float = 2.2
## 收尾的那一刀：鏽色的亮一點；金色的反而要暗——它的面積是平常的兩倍多，一樣亮的話整片白掉、蓋住後面的人
const BIG_GAIN: float = 1.25
const GOLD_BIG_GAIN: float = 0.6
## 帶子從手到劍尖的哪一段（0＝手、1＝劍尖）；收尾的那一刀比劍還長
const SPAN: Vector2 = Vector2(0.3, 1.08)
const SPAN_BIG: Vector2 = Vector2(0.12, 1.35)
## 每一段留幾秒（遊戲時間：打擊停頓時弧也停在那裡）。出手變快也不縮短——超頻時前一刀的弧還在，下一刀已經出來
const LIFE: float = 0.16
const LIFE_BIG: float = 0.22
## 刀痕的方向看劍尖最近這麼多秒走的方向（`sweep()`）：砍中那一刻前後劍正在轉彎（劈到底、開始帶過去），
## 只看最後一兩幀會量到轉彎之後的方向
const SWEEP_SEC: float = 0.04
## 兩個取樣之間劍每轉這麼多度補一段（只有兩三個取樣的時候也是圓的）
const STEP_DEG: float = 6.0

## 回傳 [手, 劍尖]（世界座標）；揮的時候每一幀問一次
var source: Callable
var recording: bool = false

var _hands: PackedVector3Array = []
var _tips: PackedVector3Array = []
var _ages: PackedFloat32Array = []
var _span: Vector2 = SPAN
var _life: float = LIFE
var _mat: ShaderMaterial


static func attach(parent: Node3D, from: Callable) -> SlashTrail:
	var t := SlashTrail.new()
	t.name = "SlashTrail"
	t.source = from
	parent.add_child(t)
	return t


func _ready() -> void:
	# 排在動畫後面：這一幀的姿勢套上骨架之後才問劍在哪裡，弧才貼得到劍
	process_priority = 10
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh = ArrayMesh.new()
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	material_override = _mat
	visible = false


## 開始記這一刀。gold＝金色（不然是這把劍自己的顏色 tint／core，預設鏽色）；big＝收尾的那一刀（更長、留得更久）。
func begin(gold: bool, big: bool, tint: Color = RUST_TINT, core: Color = RUST_CORE) -> void:
	_hands.clear()
	_tips.clear()
	_ages.clear()
	_span = SPAN_BIG if big else SPAN
	_life = LIFE_BIG if big else LIFE
	recording = true
	_mat.set_shader_parameter("tint", GOLD_TINT if gold else tint)
	_mat.set_shader_parameter("core", GOLD_CORE if gold else core)
	_mat.set_shader_parameter("strength", strength_for(gold, big))


## 這一刀多亮（shader 的 strength）。純函式。
static func strength_for(gold: bool, big: bool) -> float:
	if gold:
		return GOLD_STRENGTH * (GOLD_BIG_GAIN if big else 1.0)
	return RUST_STRENGTH * (BIG_GAIN if big else 1.0)


## 這一刀揮完了：不再記，剩下的照壽命消失。
func stop() -> void:
	recording = false


func sample_count() -> int:
	return _hands.size()


## 劍尖剛剛往哪裡走（世界座標的方向；刀痕照這個方向畫）：現在的劍尖減掉 SWEEP_SEC 秒前的劍尖（兩個取樣中間照時間內插）。
## 照時間取、不是照「最近幾個取樣」——幀率高低、剛好卡一下，量到的都是同一段揮的方向。還沒有兩個取樣就是零向量。
func sweep() -> Vector3:
	var d: Vector3 = global_basis * sweep_delta(_tips, _ages, SWEEP_SEC)
	return d.normalized() if d.length() > 0.001 else Vector3.ZERO


## 劍尖在 sec 秒內走了多少（tips 照時間排、ages＝每一個取樣幾秒前記的）；取樣不夠久就從最舊的那一個算。純函式。
static func sweep_delta(tips: PackedVector3Array, ages: PackedFloat32Array, sec: float) -> Vector3:
	var n: int = mini(tips.size(), ages.size())
	if n < 2:
		return Vector3.ZERO
	var newest: Vector3 = tips[n - 1]
	var want: float = ages[n - 1] + sec
	for i: int in range(n - 2, -1, -1):
		if ages[i] >= want:
			var span: float = ages[i] - ages[i + 1]
			var k: float = (want - ages[i + 1]) / span if span > 0.0001 else 1.0
			return newest - tips[i + 1].lerp(tips[i], k)
	return newest - tips[0]


func _process(delta: float) -> void:
	var dead: int = 0
	for i: int in _ages.size():
		_ages[i] += delta
		if _ages[i] >= _life:
			dead = i + 1
	if dead > 0:
		_hands = _hands.slice(dead)
		_tips = _tips.slice(dead)
		_ages = _ages.slice(dead)
	if recording and source.is_valid():
		var now: PackedVector3Array = source.call()
		if now.size() == 2:
			var to_local: Transform3D = global_transform.affine_inverse()
			_hands.append(to_local * now[0])
			_tips.append(to_local * now[1])
			_ages.append(0.0)
	visible = _hands.size() >= 2
	if visible:
		_rebuild()


func _rebuild() -> void:
	var am: ArrayMesh = mesh as ArrayMesh
	am.clear_surfaces()
	var built: Array = ribbon(_hands, _tips, _span)
	var pts: PackedVector3Array = built[0]
	var along: PackedFloat32Array = built[1]
	var uvs := PackedVector2Array()
	uvs.resize(pts.size())
	for i: int in along.size():
		var a: int = mini(int(along[i]), _ages.size() - 2)
		var left: float = 1.0 - lerpf(_ages[a], _ages[a + 1], along[i] - float(a)) / _life
		uvs[i * 2] = Vector2(left, 0.0)
		uvs[i * 2 + 1] = Vector2(left, 1.0)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = pts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, arrays)


## 帶子的點。回傳 [點, 位置]：點是一對一對（靠手的、靠劍尖的）照時間排；位置是每一對落在第幾個取樣（補出來的是小數）。
## 兩個取樣之間用曲線補（看前後各一個取樣，接起來沒有折角），補出來的劍保持原本的長度，
## 所以劍轉了 90 度而中間只有兩個取樣時，帶子的外緣還是圓弧（不是一條弦）。純函式。
static func ribbon(hands: PackedVector3Array, tips: PackedVector3Array, span: Vector2) -> Array:
	var pts := PackedVector3Array()
	var along := PackedFloat32Array()
	var n: int = mini(hands.size(), tips.size())
	for i: int in n:
		var blade: Vector3 = tips[i] - hands[i]
		if i > 0:
			var prev: Vector3 = tips[i - 1] - hands[i - 1]
			var steps: int = 1
			if prev.length() > 0.001 and blade.length() > 0.001:
				steps = clampi(ceili(rad_to_deg(prev.angle_to(blade)) / STEP_DEG), 1, 24)
			var before: int = maxi(i - 2, 0)
			var after: int = mini(i + 1, n - 1)
			for s: int in range(1, steps):
				var k: float = float(s) / float(steps)
				var hand: Vector3 = hands[i - 1].cubic_interpolate(hands[i], hands[before], hands[after], k)
				var tip: Vector3 = tips[i - 1].cubic_interpolate(tips[i], tips[before], tips[after], k)
				var dir: Vector3 = (tip - hand).normalized() * lerpf(prev.length(), blade.length(), k)
				pts.append(hand + dir * span.x)
				pts.append(hand + dir * span.y)
				along.append(float(i - 1) + k)
		pts.append(hands[i] + blade * span.x)
		pts.append(hands[i] + blade * span.y)
		along.append(float(i))
	return [pts, along]
