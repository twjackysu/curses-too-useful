class_name RubblePile
extends Node3D
## 魔像倒下崩成的那一堆碎石（D-303）：以前倒地之後整隻沉進地面消失，石板上什麼都沒留下。
## 一個 MultiMesh（幾十顆面數很少的扁球＝有稜角的石頭，大小、深淺不一樣），沿著自己的 +Z 鋪成長長的一堆
## （頭那一端矮、身體那一段高），幾顆小的還留著一點毒的綠光（核心沒了，裂縫裡剩下的）。
## 掛在關卡上，不會消失；grow() 從地面底下長出來（身體沉下去的同時）。腳下有一塊矮的碰撞，人走不進去。

const STONE: Color = Color(0.4, 0.43, 0.4)
const GLOW: Color = Color(0.35, 1.0, 0.2)
## 鋪多長、多寬、中間多高（公尺）
const LENGTH: float = 3.4
const WIDTH: float = 2.4
const HEIGHT: float = 1.15
const COUNT: int = 46
const GLOW_COUNT: int = 5

var _rocks: MultiMeshInstance3D
## 每顆石頭的位置（自己的座標；測試用——沒有算圖的時候 MultiMesh 讀不回位置）
var spots: PackedVector3Array = []


## 建好一堆（還沒進場景樹）：沿著 +Z 從原點鋪到 LENGTH。seed 一樣就長一樣（讀檔回來那一堆跟倒下時差不多）。
static func create(seed_value: int = 7) -> RubblePile:
	var pile := RubblePile.new()
	pile.name = "Rubble"
	pile._build(seed_value)
	return pile


func rock_count() -> int:
	return spots.size()


func _build(seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var rock := SphereMesh.new()
	rock.radius = 0.5
	rock.height = 0.7
	rock.radial_segments = 6
	rock.rings = 3
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.95
	rock.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = rock
	mm.instance_count = COUNT + GLOW_COUNT
	for i: int in COUNT:
		# 沿著身體的位置（0＝腳那一端、1＝頭）：中間那一段（胸口）最高、最寬
		var along: float = rng.randf()
		var bulge: float = sin(clampf(along * 1.15, 0.0, 1.0) * PI)
		var side: float = rng.randf_range(-0.5, 0.5) * WIDTH * (0.45 + 0.55 * bulge)
		var size: float = rng.randf_range(0.45, 1.0) * (0.6 + 0.6 * bulge)
		var high: float = HEIGHT * bulge * (1.0 - absf(side) / (WIDTH * 0.5)) * rng.randf_range(0.4, 1.0)
		var basis := Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU))
		basis = basis.scaled(Vector3(size * rng.randf_range(0.8, 1.4), size * rng.randf_range(0.6, 1.0), size * rng.randf_range(0.8, 1.3)))
		var at := Vector3(side, maxf(high, size * 0.25), along * LENGTH)
		mm.set_instance_transform(i, Transform3D(basis, at))
		spots.append(at)
		var shade: float = rng.randf_range(0.7, 1.15)
		mm.set_instance_color(i, Color(STONE.r * shade, STONE.g * shade, STONE.b * shade))
	for i: int in GLOW_COUNT:
		var along2: float = rng.randf_range(0.3, 0.7)
		var size2: float = rng.randf_range(0.14, 0.24)
		var basis2 := Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, 0.0)).scaled(Vector3.ONE * size2)
		mm.set_instance_transform(COUNT + i, Transform3D(basis2, Vector3(rng.randf_range(-0.35, 0.35) * WIDTH, HEIGHT * 0.75, along2 * LENGTH)))
		mm.set_instance_color(COUNT + i, GLOW)
	_rocks = MultiMeshInstance3D.new()
	_rocks.name = "Rocks"
	_rocks.multimesh = mm
	add_child(_rocks)
	# 綠的那幾顆自己會亮一點：同一個 MultiMesh 分不開材質，另外一盞很弱的小燈照在石堆上
	var lamp := OmniLight3D.new()
	lamp.name = "Glow"
	lamp.light_color = GLOW
	lamp.light_energy = 0.5
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
	_rocks.scale = Vector3(0.7, 0.05, 0.85)
	_rocks.position.y = -0.3
	var t: Tween = create_tween().set_parallel()
	t.tween_property(_rocks, "scale", Vector3.ONE, seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(_rocks, "position:y", 0.0, seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## 讓 +Z（石堆鋪出去的方向）朝 dir（水平）
func face_along(dir: Vector3) -> void:
	var d := Vector3(dir.x, 0.0, dir.z)
	if d.length() < 0.01:
		return
	rotation.y = atan2(d.x, d.z)
