class_name RubblePile
extends Node3D
## 魔像倒下崩成的那一堆碎石（D-303）：以前倒地之後整隻沉進地面消失，石板上什麼都沒留下。
## 兩個 MultiMesh：幾十顆有稜角的石塊（程式做的多面體：低面數的球把每個頂點往內外推一點、每一面自己的法線＝一面一面的切面；
## 兩種形狀，大小、深淺差很多，有的長苔、有的特別暗——D-306 以前是圓圓的扁球、深淺只差一點），
## 沿著自己的 +Z 鋪成長長的一堆（兩端矮、中段高），幾片插在裡面還亮著毒綠光的晶片（核心沒了，裂縫裡剩下的；自己發光）。
## 掛在關卡上，不會消失；grow() 從地面底下長出來（身體沉下去的同時）。腳下有一塊矮的碰撞，人走不進去。

const STONE: Color = Color(0.4, 0.43, 0.4)
const MOSS: Color = Color(0.27, 0.36, 0.22)
const DARK: Color = Color(0.22, 0.23, 0.24)
const GLOW: Color = Color(0.35, 1.0, 0.2)
## 鋪多長、多寬、中間多高（公尺）
const LENGTH: float = 3.4
const WIDTH: float = 2.4
const HEIGHT: float = 1.15
const COUNT: int = 46
const GLOW_COUNT: int = 7
## 石塊的頂點往內外推多少（半徑的幾成）：越大越不圓
const JAGGED: float = 0.32

var _rocks: Array[MultiMeshInstance3D] = []
var _shards: MultiMeshInstance3D
var _heap: Node3D
## 每顆石頭的位置（自己的座標；測試用——沒有算圖的時候 MultiMesh 讀不回位置）與顏色
var spots: PackedVector3Array = []
var shades: PackedColorArray = []


## 建好一堆（還沒進場景樹）：沿著 +Z 從原點鋪到 LENGTH。seed 一樣就長一樣（讀檔回來那一堆跟倒下時差不多）。
static func create(seed_value: int = 7) -> RubblePile:
	var pile := RubblePile.new()
	pile.name = "Rubble"
	pile._build(seed_value)
	return pile


func rock_count() -> int:
	return spots.size()


## 一顆有稜角的石塊：低面數的球、每個頂點沿著半徑往內外推（同一個位置推一樣多，面不會裂開）、底下壓平一點，
## 每個三角形用自己的法線（一面一面的切面，不是圓滑的）。
static func rock_mesh(seed_value: int, material: Material) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 7
	sphere.rings = 4
	var arrays: Array = sphere.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var push: Dictionary = {}
	var moved := PackedVector3Array()
	for v: Vector3 in verts:
		var key: Vector3i = Vector3i((v * 1000.0).round())
		if not push.has(key):
			push[key] = rng.randf_range(1.0 - JAGGED, 1.0 + JAGGED * 0.4)
		var p: Vector3 = v * float(push[key])
		p.y = maxf(p.y, -0.32)
		moved.append(p)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in range(0, idx.size(), 3):
		var a: Vector3 = moved[idx[i]]
		var b: Vector3 = moved[idx[i + 1]]
		var c: Vector3 = moved[idx[i + 2]]
		var n: Vector3 = (c - a).cross(b - a)
		if n.length() < 1e-6:
			continue
		n = n.normalized()
		if n.dot((a + b + c) / 3.0) < 0.0:
			n = -n
		for p: Vector3 in [a, b, c]:
			st.set_normal(n)
			st.add_vertex(p)
	st.set_material(material)
	return st.commit()


func _build(seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	_heap = Node3D.new()
	_heap.name = "Heap"
	add_child(_heap)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.95
	var shapes: Array[ArrayMesh] = [rock_mesh(seed_value * 31 + 1, mat), rock_mesh(seed_value * 31 + 2, mat)]
	var lists: Array[Array] = [[], []]
	for i: int in COUNT:
		# 沿著身體的位置（0＝腳那一端、1＝頭）：中間那一段（胸口）最高、最寬
		var along: float = rng.randf()
		var bulge: float = sin(clampf(along * 1.15, 0.0, 1.0) * PI)
		var side: float = rng.randf_range(-0.5, 0.5) * WIDTH * (0.45 + 0.55 * bulge)
		var size: float = rng.randf_range(0.4, 1.05) * (0.6 + 0.6 * bulge)
		var high: float = HEIGHT * bulge * (1.0 - absf(side) / (WIDTH * 0.5)) * rng.randf_range(0.4, 1.0)
		var basis := Basis.from_euler(Vector3(rng.randf_range(-0.6, 0.6), rng.randf() * TAU, rng.randf_range(-0.6, 0.6)))
		basis = basis.scaled(Vector3(size * rng.randf_range(0.8, 1.5), size * rng.randf_range(0.5, 1.0), size * rng.randf_range(0.8, 1.4)))
		var at := Vector3(side, maxf(high, size * 0.2), along * LENGTH)
		# 深淺：大部分是灰的（差很多），四分之一長苔、八分之一特別暗（縫裡、背光的）
		var shade: float = rng.randf_range(0.55, 1.3)
		var tone: Color = Color(STONE.r * shade, STONE.g * shade, STONE.b * shade)
		var pick: float = rng.randf()
		if pick < 0.25:
			tone = MOSS.lerp(tone, rng.randf_range(0.0, 0.35))
		elif pick < 0.37:
			tone = DARK
		lists[i % 2].append([Transform3D(basis, at), tone])
		spots.append(at)
		shades.append(tone)
	for k: int in 2:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = shapes[k]
		mm.instance_count = lists[k].size()
		for j: int in lists[k].size():
			mm.set_instance_transform(j, lists[k][j][0] as Transform3D)
			mm.set_instance_color(j, lists[k][j][1] as Color)
		var mi := MultiMeshInstance3D.new()
		mi.name = "Rocks%d" % k
		mi.multimesh = mm
		_heap.add_child(mi)
		_rocks.append(mi)
	# 還亮著的晶片：細長的三角柱斜插在中段，自己發光（跟石頭分開一個 MultiMesh 才能用發光的材質）
	var shard := PrismMesh.new()
	shard.size = Vector3(0.12, 0.42, 0.08)
	var glow_mat := StandardMaterial3D.new()
	glow_mat.albedo_color = GLOW
	glow_mat.emission_enabled = true
	glow_mat.emission = GLOW
	glow_mat.emission_energy_multiplier = 2.4
	shard.material = glow_mat
	var gm := MultiMesh.new()
	gm.transform_format = MultiMesh.TRANSFORM_3D
	gm.mesh = shard
	gm.instance_count = GLOW_COUNT
	for i: int in GLOW_COUNT:
		var along2: float = rng.randf_range(0.25, 0.75)
		var basis2 := Basis.from_euler(Vector3(rng.randf_range(-0.7, 0.7), rng.randf() * TAU, rng.randf_range(-0.7, 0.7))).scaled(Vector3.ONE * rng.randf_range(0.7, 1.3))
		var bulge2: float = sin(clampf(along2 * 1.15, 0.0, 1.0) * PI)
		gm.set_instance_transform(i, Transform3D(basis2, Vector3(rng.randf_range(-0.3, 0.3) * WIDTH, HEIGHT * bulge2 * rng.randf_range(0.55, 0.9), along2 * LENGTH)))
	_shards = MultiMeshInstance3D.new()
	_shards.name = "Shards"
	_shards.multimesh = gm
	_shards.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_heap.add_child(_shards)
	# 綠光照在旁邊的石頭上：一盞很弱的小燈
	var lamp := OmniLight3D.new()
	lamp.name = "Glow"
	lamp.light_color = GLOW
	lamp.light_energy = 0.6
	lamp.omni_range = 2.4
	lamp.shadow_enabled = false
	lamp.position = Vector3(0.0, HEIGHT + 0.3, LENGTH * 0.5)
	add_child(lamp)
	var body := StaticBody3D.new()
	body.name = "Block"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(WIDTH * 0.8, HEIGHT, LENGTH * 0.8)
	shape.shape = box
	shape.position = Vector3(0.0, HEIGHT * 0.5, LENGTH * 0.5)
	body.add_child(shape)
	add_child(body)


## 從地面底下長出來（seconds 秒）：一開始扁扁地埋在地裡，往上拱成一堆。
func grow(seconds: float) -> void:
	_heap.scale = Vector3(0.7, 0.05, 0.85)
	_heap.position.y = -0.3
	var t: Tween = create_tween().set_parallel()
	t.tween_property(_heap, "scale", Vector3.ONE, seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(_heap, "position:y", 0.0, seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## 讓 +Z（石堆鋪出去的方向）朝 dir（水平）
func face_along(dir: Vector3) -> void:
	var d := Vector3(dir.x, 0.0, dir.z)
	if d.length() < 0.01:
		return
	rotation.y = atan2(d.x, d.z)
