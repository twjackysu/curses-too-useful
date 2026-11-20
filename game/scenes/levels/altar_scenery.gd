class_name AltarScenery
extends RefCounted
## 廢棄祭壇那一塊空地看得到的東西（docs/story/chapter-1.md 節點 3）：一圈石板、周圍的斷柱、北邊台階上的祭壇、外圍的樹與草。
## 天空、月光、霧、樹、草、孢子沿用腐敗之森的（ForestScenery）——這裡是同一座森林的深處。只是場景；規則與劇情在 RuinedAltar。
## 祭壇是 Tripo 的模型（顏色貼圖是灰的，顏色用 ruin_stone.gdshader 照形狀算）；柱子與台階是程式拼的圓柱，用同一個 shader。

const PLAZA_RADIUS: float = 16.0
const PATH_HALF: float = 2.6
## 從森林走進來的地方（南邊那條路上）
const ENTRANCE: Vector3 = Vector3(0, 0.05, 30.0)
## 走得到的範圍：石板外面一小圈，加上南邊那條路
const WALK_RADIUS: float = 17.5
const PATH_WALK_HALF: float = 4.0
const PATH_END_Z: float = 33.0
const ALTAR_POS: Vector3 = Vector3(0, 0, -11.5)
const ALTAR_MODEL: String = "tripo/prop_ruined_altar"
## 模型高 1.4 m、半徑約 0.9 m：放大到比人高
const ALTAR_SCALE: float = 1.7
const DAIS_STEPS: Array[Vector2] = [Vector2(3.6, 0.2), Vector2(2.8, 0.4)]
const STONE_SHADER: Shader = preload("res://src/world/ruin_stone.gdshader")
const GROUND_SHADER: Shader = preload("res://src/world/altar_ground.gdshader")
## 斷柱：繞著石板一圈（角度、幾節；一節 DRUM_HEIGHT 高）。南邊（路）與北邊（祭壇）空著
const PILLAR_RING: float = 14.3
const PILLARS: Array[Vector2] = [
	Vector2(22, 4), Vector2(56, 2), Vector2(124, 3), Vector2(158, 4),
	Vector2(203, 1), Vector2(236, 3), Vector2(304, 4), Vector2(338, 2),
]
## 倒在地上的兩截（x、z、朝向的角度）
## （離 RuinedAltar.hold_spot 的八個位置都有三公尺以上：席菈退到後面的時候不會卡在柱子上）
const FALLEN: Array[Vector3] = [Vector3(-10.6, 6.2, 35.0), Vector3(10.9, 5.6, 120.0)]
const DRUM_HEIGHT: float = 1.15
const DRUM_RADIUS: float = 0.72
const TREE_COUNT: int = 48
const GRASS_PATCHES: int = 170
## 符文平常多亮、魔像醒著的時候多亮
const RUNE_GLOW: float = 0.55
## 斷柱一圈幾道凹槽（ruin_stone.gdshader 的 flutes）、圓柱繞一圈幾個面（太少看得出一面一面的）
const FLUTES: float = 16.0
const DRUM_SEGMENTS: int = 32
## 斷掉的那一節：斷口最深往下缺多少（公尺）
const BREAK_DEPTH: float = 0.42

## 關卡要調的東西：地面的材質（石板縫的光）、每一塊會亮符文的石頭的材質、祭壇上面那盞紅燈
var ground: ShaderMaterial
var stones: Array[ShaderMaterial] = []
var omen: OmniLight3D


## 把場景蓋進 level。rng：固定種子的亂數（每次長得一樣）。
static func build(level: Node3D, rng: RandomNumberGenerator) -> AltarScenery:
	var s := AltarScenery.new()
	ForestScenery.build_environment(level)
	var trees: PackedVector3Array = s._build_trees(level, rng)
	s._build_ground(level, trees)
	s._build_pillars(level, rng)
	s._build_altar(level)
	return s


## 魔像的疫病有多強（0＝睡著、1＝醒著）：石板的縫與符文跟著亮。pulse＝0～1 的跳動
func set_plague(level_0_1: float, pulse: float) -> void:
	ground.set_shader_parameter("plague", level_0_1 * (0.55 + 0.45 * pulse))
	for m: ShaderMaterial in stones:
		m.set_shader_parameter("glow", RUNE_GLOW + level_0_1 * (0.5 + 0.6 * pulse))


## 走出去了就拉回來：走得到的地方是石板外面一小圈，加上南邊那條路；出去了就移到這兩塊裡最近的一點。沒走出去就原樣回傳。
static func keep_inside(p: Vector3) -> Vector3:
	var flat := Vector2(p.x, p.z)
	if flat.length() <= WALK_RADIUS:
		return p
	var on_path := Vector2(clampf(p.x, -PATH_WALK_HALF, PATH_WALK_HALF), clampf(p.z, 0.0, PATH_END_Z))
	if flat.distance_to(on_path) < 0.001:
		return p
	var in_ring: Vector2 = flat.normalized() * WALK_RADIUS
	var back: Vector2 = on_path if flat.distance_to(on_path) < flat.distance_to(in_ring) else in_ring
	return Vector3(back.x, p.y, back.y)


## p 是空著的石板嗎（不在斷柱、柱腳的方石、倒著的那兩截、祭壇的台階上，離石板邊 1 m 以上）：
## margin＝東西本身多大（滾出來的核心停在哪裡，RuinedAltar.core_spot_clear）
static func open_floor(p: Vector3, margin: float) -> bool:
	var flat := Vector2(p.x, p.z)
	if flat.length() > PLAZA_RADIUS - 1.0 - margin:
		return false
	if flat.distance_to(Vector2(ALTAR_POS.x, ALTAR_POS.z)) < DAIS_STEPS[0].x + margin:
		return false
	for spec: Vector2 in PILLARS:
		var at := Vector2(cos(deg_to_rad(spec.x)), sin(deg_to_rad(spec.x))) * PILLAR_RING
		# 柱腳的方石 1.9 m 見方：對角線的一半
		if flat.distance_to(at) < 1.35 + margin:
			return false
	for spec: Vector3 in FALLEN:
		# 倒著的兩截在它自己的座標裡是一個長 2.5 m、寬 1.44 m 的方塊
		var local: Vector2 = (flat - Vector2(spec.x, spec.y)).rotated(deg_to_rad(spec.z))
		if absf(local.x) < DRUM_HEIGHT + 0.1 + margin and absf(local.y) < DRUM_RADIUS + margin:
			return false
	return true


static func _open_ground(p: Vector2) -> bool:
	return p.length() < PLAZA_RADIUS + 3.0 or (p.y > 0.0 and absf(p.x) < PATH_WALK_HALF + 1.5)


func _build_trees(level: Node3D, rng: RandomNumberGenerator) -> PackedVector3Array:
	var forest := Node3D.new()
	forest.name = "Forest"
	level.add_child(forest)
	var stand := TreeStand.new()
	forest.add_child(stand)
	var trees := PackedVector3Array()
	var tries: int = 0
	while trees.size() < TREE_COUNT and tries < TREE_COUNT * 30:
		tries += 1
		var p := Vector3(rng.randf_range(-44.0, 44.0), 0.0, rng.randf_range(-44.0, 46.0))
		if _open_ground(Vector2(p.x, p.z)) or Vector2(p.x, p.z).length() > 44.0 or ForestScenery.crowded(trees, p, 3.4):
			continue
		var size: float = rng.randf_range(0.9, 1.4)
		stand.add(p, size, rng.randf_range(0.0, TAU))
		trees.append(Vector3(p.x, size, p.z))
	stand.build()
	var spots := PackedVector3Array()
	for c: int in GRASS_PATCHES:
		var center := Vector3(rng.randf_range(-34.0, 34.0), 0.0, rng.randf_range(-34.0, 38.0))
		var spread: float = rng.randf_range(0.8, 2.2)
		for i: int in rng.randi_range(8, 20):
			var q: Vector3 = center + Vector3(rng.randfn(0.0, spread), 0.0, rng.randfn(0.0, spread))
			var flat := Vector2(q.x, q.z)
			if flat.length() > PLAZA_RADIUS + 0.6 and not (q.z > 0.0 and absf(q.x) < PATH_HALF + 0.4):
				spots.append(q)
	forest.add_child(GrassTufts.create(spots, rng))
	return trees


func _build_ground(level: Node3D, trees: PackedVector3Array) -> void:
	var body := StaticBody3D.new()
	body.name = "Ground"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(ForestMap.SIZE, 1.0, ForestMap.SIZE)
	shape.shape = box
	shape.position = Vector3(0, -0.5, 0)
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(ForestMap.SIZE, ForestMap.SIZE)
	ground = ShaderMaterial.new()
	ground.shader = GROUND_SHADER
	ground.set_shader_parameter("ground_size", ForestMap.SIZE)
	ground.set_shader_parameter("plaza_radius", PLAZA_RADIUS)
	ground.set_shader_parameter("path_half", PATH_HALF)
	ground.set_shader_parameter("moss_mask", ImageTexture.create_from_image(ForestScenery.moss_mask(trees)))
	plane.material = ground
	mesh.mesh = plane
	body.add_child(mesh)
	level.add_child(body)


## 一塊會亮符文的石頭的材質（位置、高度、半徑照那一塊算）
func _stone(base: Vector3, height: float, radius: float, top_ring: bool, flutes: float = 0.0) -> ShaderMaterial:
	var mat: ShaderMaterial = stone_material(base, height, radius, top_ring, RUNE_GLOW, flutes)
	stones.append(mat)
	return mat


## 祭壇的石頭（ruin_stone.gdshader）：base＝這塊石頭底部中心的世界座標，符文的那一圈照高度與半徑擺。森林的祭壇路口也用。
## flutes＞0＝斷柱（側面一圈凹槽、一節 course 公尺一節的深淺與接縫）
static func stone_material(base: Vector3, height: float, radius: float, top_ring: bool, glow: float = RUNE_GLOW,
		flutes: float = 0.0, course: float = DRUM_HEIGHT) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = STONE_SHADER
	mat.set_shader_parameter("base_pos", base)
	mat.set_shader_parameter("height", height)
	mat.set_shader_parameter("radius", radius)
	mat.set_shader_parameter("top_ring", 1.0 if top_ring else 0.0)
	mat.set_shader_parameter("glow", glow)
	mat.set_shader_parameter("flutes", flutes)
	mat.set_shader_parameter("course", course)
	return mat


static func _drum(radius: float, height: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius * 1.04
	cyl.height = height
	cyl.radial_segments = DRUM_SEGMENTS
	cyl.material = mat
	mi.mesh = cyl
	return mi


## 斷掉的那一節：上緣參差不齊（一圈往下缺、深淺不一）、斷口是一面一面的碎面往中間凹。原點在這一節的中心（跟 _drum 一樣）
static func broken_drum(radius: float, height: float, mat: Material, seed_value: int) -> MeshInstance3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var n: int = DRUM_SEGMENTS
	var half: float = height * 0.5
	# 每個角度往下缺多少：兩個不同頻率的波加一點亂數（缺口是一塊一塊的，不是鋸齒）
	var phase := Vector2(rng.randf() * TAU, rng.randf() * TAU)
	var drops := PackedFloat32Array()
	for i: int in n:
		var a: float = TAU * float(i) / float(n)
		var w: float = 0.5 + 0.3 * sin(a * 2.0 + phase.x) + 0.2 * sin(a * 5.0 + phase.y)
		drops.append(clampf(w + rng.randf_range(-0.12, 0.12), 0.0, 1.0) * BREAK_DEPTH)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in n:
		var j: int = (i + 1) % n
		var a0: float = TAU * float(i) / float(n)
		var a1: float = TAU * float(j) / float(n)
		var d0 := Vector3(cos(a0), 0.0, sin(a0))
		var d1 := Vector3(cos(a1), 0.0, sin(a1))
		var b0: Vector3 = d0 * radius * 1.04 + Vector3.DOWN * half
		var b1: Vector3 = d1 * radius * 1.04 + Vector3.DOWN * half
		var t0: Vector3 = d0 * radius + Vector3.UP * (half - drops[i])
		var t1: Vector3 = d1 * radius + Vector3.UP * (half - drops[j])
		for v: Array in [[b0, d0], [t1, d1], [t0, d0], [b0, d0], [b1, d1], [t1, d1]]:
			st.set_normal(v[1] as Vector3)
			st.add_vertex(v[0] as Vector3)
		# 斷口：往中間凹下去的一圈碎面（每一面自己的法線）
		var c: Vector3 = Vector3.UP * (half - BREAK_DEPTH * 0.75)
		var face: Vector3 = (t0 - c).cross(t1 - c).normalized()
		if face.y < 0.0:
			face = -face
		for v2: Vector3 in [c, t0, t1]:
			st.set_normal(face)
			st.add_vertex(v2)
	st.set_material(mat)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	return mi


func _build_pillars(level: Node3D, rng: RandomNumberGenerator) -> void:
	var ruins := Node3D.new()
	ruins.name = "Ruins"
	level.add_child(ruins)
	for spec: Vector2 in PILLARS:
		var drums: int = int(spec.y)
		var at := Vector3(cos(deg_to_rad(spec.x)), 0.0, sin(deg_to_rad(spec.x))) * PILLAR_RING
		var pillar := StaticBody3D.new()
		pillar.name = "Pillar%d" % int(spec.x)
		pillar.position = at
		var tall: float = DRUM_HEIGHT * float(drums)
		var mat: ShaderMaterial = _stone(at, maxf(tall, DRUM_HEIGHT * 2.0), DRUM_RADIUS, false, FLUTES)
		# 柱腳的方石
		var plinth := MeshInstance3D.new()
		var slab := BoxMesh.new()
		slab.size = Vector3(1.9, 0.26, 1.9)
		slab.material = mat
		plinth.mesh = slab
		plinth.position = Vector3(0, 0.13, 0)
		plinth.rotation.y = rng.randf_range(-0.2, 0.2)
		pillar.add_child(plinth)
		for k: int in drums:
			# 斷掉的柱子（四節以下）最上面那一節的上緣是參差的斷口
			var top: bool = k == drums - 1 and drums < 4
			var drum: MeshInstance3D = broken_drum(DRUM_RADIUS - 0.02 * float(k), DRUM_HEIGHT, mat, int(spec.x)) if top else _drum(DRUM_RADIUS - 0.02 * float(k), DRUM_HEIGHT, mat)
			drum.position = Vector3(rng.randf_range(-0.03, 0.03), 0.26 + DRUM_HEIGHT * (float(k) + 0.5), rng.randf_range(-0.03, 0.03))
			drum.rotation.y = rng.randf_range(0.0, TAU)
			# 斷掉的那一節歪一點
			if k == drums - 1 and drums < 4:
				drum.rotation.x = rng.randf_range(-0.07, 0.07)
				drum.rotation.z = rng.randf_range(-0.07, 0.07)
			pillar.add_child(drum)
		var shape := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = DRUM_RADIUS + 0.12
		cyl.height = tall + 0.26
		shape.shape = cyl
		shape.position = Vector3(0, cyl.height * 0.5, 0)
		pillar.add_child(shape)
		ruins.add_child(pillar)
	for spec: Vector3 in FALLEN:
		var at := Vector3(spec.x, 0.0, spec.y)
		var fallen := StaticBody3D.new()
		fallen.name = "FallenPillar"
		fallen.position = at
		fallen.rotation.y = deg_to_rad(spec.z)
		var mat: ShaderMaterial = _stone(at + Vector3(0, -0.6, 0), 2.4, DRUM_RADIUS, false)
		for k: int in 2:
			var drum: MeshInstance3D = _drum(DRUM_RADIUS, DRUM_HEIGHT, mat)
			# 躺著：圓柱的軸轉到水平，兩截之間留一道縫
			drum.rotation.z = PI * 0.5
			drum.position = Vector3((float(k) - 0.5) * (DRUM_HEIGHT + 0.12), DRUM_RADIUS * 0.92, 0.12 * float(k))
			drum.rotation.y = 0.08 * float(k)
			fallen.add_child(drum)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(DRUM_HEIGHT * 2.0 + 0.2, DRUM_RADIUS * 2.0, DRUM_RADIUS * 2.0)
		shape.shape = box
		shape.position = Vector3(0, DRUM_RADIUS, 0)
		fallen.add_child(shape)
		ruins.add_child(fallen)


func _build_altar(level: Node3D) -> void:
	var altar := StaticBody3D.new()
	altar.name = "Altar"
	altar.position = ALTAR_POS
	var top: float = 0.0
	var dais_mat: ShaderMaterial = _stone(ALTAR_POS, 3.0, DAIS_STEPS[0].x, false)
	for step: Vector2 in DAIS_STEPS:
		var mi: MeshInstance3D = _drum(step.x, step.y, dais_mat)
		(mi.mesh as CylinderMesh).radial_segments = 40
		mi.position = Vector3(0, step.y * 0.5, 0)
		altar.add_child(mi)
		top = step.y
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = DAIS_STEPS[1].x
	cyl.height = 1.2
	shape.shape = cyl
	shape.position = Vector3(0, 0.6, 0)
	altar.add_child(shape)
	var base: Vector3 = ALTAR_POS + Vector3(0, top, 0)
	var mat: ShaderMaterial = _stone(base, 1.4 * ALTAR_SCALE, 0.9 * ALTAR_SCALE, true)
	var look: Node3D = PropModels.instance(ALTAR_MODEL)
	if look == null:
		# 模型檔不在：一截粗圓柱，同一個 shader（符文與圓環照樣有）
		look = _drum(0.8, 1.4, mat)
		look.position = Vector3(0, top + 0.7 * ALTAR_SCALE, 0)
	else:
		look.position = Vector3(0, top, 0)
		paint(look, mat)
	look.name = "Look"
	look.scale = Vector3.ONE * ALTAR_SCALE
	altar.add_child(look)
	# 祭壇上面一盞不祥的紅光（從森林的路口就看得到這片紅）
	omen = OmniLight3D.new()
	omen.name = "Omen"
	omen.light_color = Color(1.0, 0.25, 0.3)
	omen.light_energy = 4.0
	omen.omni_range = 15.0
	omen.shadow_enabled = false
	omen.light_volumetric_fog_energy = 3.0
	omen.position = Vector3(0, 4.2, 0)
	altar.add_child(omen)
	level.add_child(altar)


## 把模型每一塊的材質換成 mat（原本的灰貼圖與法線貼圖留著當表面的細節）
static func paint(model: Node3D, mat: ShaderMaterial) -> void:
	var meshes: Array[Node] = model.find_children("*", "MeshInstance3D", true, false)
	if model is MeshInstance3D:
		meshes.append(model)
	for n: Node in meshes:
		var mi := n as MeshInstance3D
		for surface: int in mi.mesh.get_surface_count():
			var src := mi.get_active_material(surface) as BaseMaterial3D
			if src != null:
				mat.set_shader_parameter("detail", src.albedo_texture)
				mat.set_shader_parameter("normal_map", src.normal_texture)
			mi.set_surface_override_material(surface, mat)
