class_name ForestScenery
extends RefCounted
## 腐敗之森看得到的東西：天空與光、地面、樹、草、路邊的小東西、飄著的孢子。只是場景——規則與劇情在 CorruptForest，地圖在 ForestMap。
## 地面是一片平面（顏色、路與空地的邊緣、落葉、毒沼都在 forest_ground.gdshader 裡算），上面長一團一團的草（GrassTufts）。
## 樹、毒蕈、灌木是 Tripo 的模型（scripts/gen_props.sh 擺正後放 assets/props/tripo/，不進 git）；檔案不在就用程式拼的替身。

const TREE_MODEL: String = "tripo/prop_corrupt_tree"
const MUSHROOM_MODEL: String = "tripo/prop_glow_toxic_mushroom"
const BUSH_MODEL: String = "tripo/prop_rotten_fruit_bush"
## 夜光毒蕈放的算圖層：它們自己的燈不照這一層（small_prop）
const GLOW_PROP_LAYER: int = 1 << 1
const MUSHROOM_SHADER: Shader = preload("res://src/world/glow_mushroom.gdshader")
const GROUND_SHADER: Shader = preload("res://src/world/forest_ground.gdshader")
## 森林口那一帶的樹（位置跟只有入口的時候一樣）、北邊加出來的樹
const TREE_COUNT: int = 46
const DEEP_TREE_COUNT: int = 120
## 北邊的樹只種在離路與空地這麼近的地方（更遠的地方玩家走不到、霧裡也看不到）
const DEEP_TREE_REACH: float = 24.0
const GRASS_PATCHES: int = 230
const DEEP_GRASS_PATCHES: int = 420
## 樹腳下那一圈苔的半徑（公尺，再乘上樹的大小）：比模型自帶的土丘（約 3 m）大一圈，土丘才會埋在苔裡
const TREE_MOSS_RADIUS: float = 4.4
const MOSS_MASK_SIZE: int = 384
## 孢子跟著玩家飄：這麼大的一塊（公尺，半邊長）
const SPORE_BOX: Vector3 = Vector3(16.0, 1.5, 22.0)


## 黃昏的紫黑森林：頭頂暗、地平線泛紫的天，冷的月光、暗紫的環境光，
## 體積霧讓遠處的樹一層一層淡進紫色裡（畫質低時 QualityPreset 換成深度霧）。
static func build_environment(level: Node3D) -> void:
	var dusk := ProceduralSkyMaterial.new()
	dusk.sky_top_color = Color(0.05, 0.03, 0.1)
	dusk.sky_horizon_color = Color(0.3, 0.19, 0.4)
	dusk.sky_curve = 0.25
	dusk.ground_horizon_color = dusk.sky_horizon_color
	dusk.ground_bottom_color = Color(0.07, 0.05, 0.11)
	dusk.sun_angle_max = 6.0
	var sky := Sky.new()
	sky.sky_material = dusk
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.36, 0.55)
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.03
	env.volumetric_fog_albedo = Color(0.5, 0.38, 0.62)
	env.volumetric_fog_emission = Color(0.05, 0.03, 0.08)
	env.volumetric_fog_length = 70.0
	env.glow_enabled = true
	env.glow_intensity = 0.5
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	level.add_child(we)
	var moon := DirectionalLight3D.new()
	moon.name = "Moon"
	moon.light_color = Color(0.72, 0.74, 1.0)
	moon.light_energy = 1.1
	moon.shadow_enabled = true
	moon.rotation_degrees = Vector3(-48, 32, 0)
	level.add_child(moon)


## trees：每棵樹 x、z＝位置，y＝大小（樹腳下的苔照這個長）
static func build_ground(level: Node3D, trees: PackedVector3Array) -> void:
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
	var mat := ShaderMaterial.new()
	mat.shader = GROUND_SHADER
	mat.set_shader_parameter("ground_size", ForestMap.SIZE)
	mat.set_shader_parameter("moss_mask", ImageTexture.create_from_image(moss_mask(trees)))
	mat.set_shader_parameter("trail_mask", ImageTexture.create_from_image(ForestMap.trail_mask()))
	plane.material = mat
	mesh.mesh = plane
	body.add_child(mesh)
	level.add_child(body)


## 樹散在路的兩邊與空地外圍；毒蕈與灌木點在森林口那段路邊。位置用固定的亂數種子，每次都一樣。
## keep_out（Callable(Vector3) -> bool）＝關卡另外不要種樹的地方（瘴氣裡）。回傳每棵樹（x、大小、z）。
static func build_forest(level: Node3D, rng: RandomNumberGenerator, keep_out: Callable) -> PackedVector3Array:
	var forest := Node3D.new()
	forest.name = "Forest"
	level.add_child(forest)
	var trees := PackedVector3Array()
	# 森林口那一帶：亂數照只有入口的時候的順序抽，樹的位置跟那時候一樣；後來變成路或空地的位置就不種
	var placed: int = 0
	var tries: int = 0
	while placed < TREE_COUNT and tries < TREE_COUNT * 20:
		tries += 1
		var p := Vector3(rng.randf_range(-30.0, 30.0), 0.0, rng.randf_range(-40.0, 26.0))
		if not _entrance_tree_ok(p) or bool(keep_out.call(p)):
			continue
		var size: float = rng.randf_range(0.85, 1.3)
		var yaw: float = rng.randf_range(0.0, TAU)
		placed += 1
		if not ForestMap.tree_ok(ForestMap.flat(p)):
			continue
		forest.add_child(tree(p, size, yaw))
		trees.append(Vector3(p.x, size, p.z))
	for i: int in 9:
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var at := Vector3(side * rng.randf_range(ForestMap.PATH_HALF_WIDTH * 0.8, ForestMap.PATH_HALF_WIDTH + 2.0), 0.0, 16.0 - float(i) * 4.5)
		forest.add_child(small_prop(MUSHROOM_MODEL if i % 3 != 0 else BUSH_MODEL, at, rng.randf_range(0.0, TAU), i % 3 != 0))
	# 北邊：沿著路與空地的外圍種（另一個亂數，不動到上面的順序）
	var deep := RandomNumberGenerator.new()
	deep.seed = 20261115
	placed = 0
	tries = 0
	while placed < DEEP_TREE_COUNT and tries < DEEP_TREE_COUNT * 40:
		tries += 1
		var p := Vector3(deep.randf_range(-62.0, 66.0), 0.0, deep.randf_range(-96.0, 40.0))
		if Rect2(-30.0, -40.0, 60.0, 66.0).has_point(ForestMap.flat(p)) or not ForestMap.tree_ok(ForestMap.flat(p)) or bool(keep_out.call(p)):
			continue
		if minf(ForestMap.path_distance(ForestMap.flat(p)), ForestMap.clearing_distance(ForestMap.flat(p))) > DEEP_TREE_REACH or _crowded(trees, p, 3.2):
			continue
		var size: float = deep.randf_range(0.85, 1.35)
		forest.add_child(tree(p, size, deep.randf_range(0.0, TAU)))
		trees.append(Vector3(p.x, size, p.z))
		placed += 1
	var spots: PackedVector3Array = _grass_spots(rng, trees, GRASS_PATCHES, Rect2(-28.0, -38.0, 56.0, 64.0))
	spots.append_array(_grass_spots(deep, trees, DEEP_GRASS_PATCHES, Rect2(-50.0, -92.0, 104.0, 54.0)))
	forest.add_child(GrassTufts.create(spots, rng))
	return trees


## 只有入口那時候的規則（路只有一條直的、空地只有一塊）：照它抽亂數，樹的位置才不會變
static func _entrance_tree_ok(p: Vector3) -> bool:
	if absf(p.x) < ForestMap.PATH_HALF_WIDTH and p.z > ForestMap.GLADE.y:
		return false
	return Vector2(p.x - ForestMap.GLADE.x, p.z - ForestMap.GLADE.y).length() >= ForestMap.GLADE.z + 1.5


static func _crowded(trees: PackedVector3Array, p: Vector3, gap: float) -> bool:
	for t: Vector3 in trees:
		if Vector2(t.x - p.x, t.z - p.z).length() < gap:
			return true
	return false


## 草叢的位置：一團一團地長（每團十幾叢），路邊與樹腳下（土丘的邊緣）多幾團。
static func _grass_spots(rng: RandomNumberGenerator, trees: PackedVector3Array, patches: int, area: Rect2) -> PackedVector3Array:
	var spots := PackedVector3Array()
	for c: int in patches:
		var center := Vector3(rng.randf_range(area.position.x, area.end.x), 0.0, rng.randf_range(area.position.y, area.end.y))
		if c % 5 == 0:
			center.x = (-1.0 if c % 2 == 0 else 1.0) * rng.randf_range(ForestMap.PATH_HALF_WIDTH * 0.7, ForestMap.PATH_HALF_WIDTH * 1.6)
		elif c % 5 < 3 and not trees.is_empty():
			var t: Vector3 = trees[rng.randi_range(0, trees.size() - 1)]
			center = Vector3(t.x, 0.0, t.z) + Vector3.RIGHT.rotated(Vector3.UP, rng.randf_range(0.0, TAU)) * 3.0 * t.y
		var spread: float = rng.randf_range(0.8, 2.4)
		for i: int in rng.randi_range(8, 22):
			var p: Vector3 = center + Vector3(rng.randfn(0.0, spread), 0.0, rng.randfn(0.0, spread))
			if ForestMap.grass_ok(ForestMap.flat(p)) and not ForestMap.in_swamp(ForestMap.flat(p)):
				spots.append(p)
	return spots


## 樹腳下的苔：一張 MOSS_MASK_SIZE 見方的灰階圖蓋住整片地面，離樹越近越白（forest_ground.gdshader 照它長苔）。純函式。
static func moss_mask(trees: PackedVector3Array) -> Image:
	var img := Image.create_empty(MOSS_MASK_SIZE, MOSS_MASK_SIZE, false, Image.FORMAT_R8)
	var per_meter: float = float(MOSS_MASK_SIZE) / ForestMap.SIZE
	for t: Vector3 in trees:
		var center := Vector2(t.x, t.z) * per_meter + Vector2.ONE * float(MOSS_MASK_SIZE) * 0.5
		var reach: float = TREE_MOSS_RADIUS * t.y * per_meter
		for y: int in range(maxi(int(center.y - reach), 0), mini(int(center.y + reach) + 2, MOSS_MASK_SIZE)):
			for x: int in range(maxi(int(center.x - reach), 0), mini(int(center.x + reach) + 2, MOSS_MASK_SIZE)):
				var near: float = 1.0 - smoothstep(0.55, 1.0, Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(center) / reach)
				if near > img.get_pixel(x, y).r:
					img.set_pixel(x, y, Color(near, 0, 0))
	return img


static func tree(at: Vector3, size: float, yaw: float) -> Node3D:
	var body := StaticBody3D.new()
	body.position = at
	body.rotation.y = yaw
	var shape := CollisionShape3D.new()
	var trunk := CylinderShape3D.new()
	trunk.radius = 0.45 * size
	trunk.height = 4.0
	shape.shape = trunk
	shape.position = Vector3(0, 2.0, 0)
	body.add_child(shape)
	var look: Node3D = PropModels.instance(TREE_MODEL)
	if look == null:
		var mesh := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.2
		cyl.bottom_radius = 0.45
		cyl.height = 6.0
		var bark := StandardMaterial3D.new()
		bark.albedo_color = Color(0.2, 0.15, 0.2)
		cyl.material = bark
		mesh.mesh = cyl
		mesh.position = Vector3(0, 3.0, 0)
		look = mesh
	look.scale = Vector3.ONE * size
	body.add_child(look)
	return body


## 路邊的小東西（夜光毒蕈、灌木）。glows＝夜光毒蕈：顏色照形狀算、旁邊掛一盞青色的小燈（節點名 Glow）。
static func small_prop(model: String, at: Vector3, yaw: float, glows: bool) -> Node3D:
	var root := Node3D.new()
	root.position = at
	root.rotation.y = yaw
	var look: Node3D = PropModels.instance(model)
	if look == null:
		var mesh := MeshInstance3D.new()
		var ball := SphereMesh.new()
		ball.radius = 0.4
		ball.height = 0.6
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.4, 0.5, 0.9) if glows else Color(0.25, 0.4, 0.2)
		ball.material = mat
		mesh.mesh = ball
		mesh.position = Vector3(0, 0.3, 0)
		look = mesh
	look.name = "Look"
	root.add_child(look)
	if glows:
		paint_mushroom(look)
		var light := OmniLight3D.new()
		light.name = "Glow"
		light.light_color = Color(0.45, 0.75, 1.0)
		light.light_energy = 1.6
		light.omni_range = 5.0
		light.position = Vector3(0, 0.8, 0)
		# 這盞燈就在蕈傘中間：照到毒蕈自己的話整叢被打成一片白。毒蕈放在另一個算圖層、這盞燈不照那一層——
		# 它自己的亮是 shader 的發光，燈只照地面與旁邊的東西
		light.light_cull_mask = 0xFFFFF & ~GLOW_PROP_LAYER
		root.add_child(light)
	return root


## 夜光毒蕈的顏色照形狀算（glow_mushroom.gdshader）：Tripo 那個模型的顏色貼圖是一張灰的，直接用整叢是白的。
## 原本的灰貼圖與法線貼圖留著當表面的細節。
static func paint_mushroom(model: Node3D) -> void:
	var meshes: Array[Node] = model.find_children("*", "MeshInstance3D", true, false)
	if model is MeshInstance3D:
		meshes.append(model)
	for n: Node in meshes:
		var mi := n as MeshInstance3D
		mi.layers = GLOW_PROP_LAYER
		for surface: int in mi.mesh.get_surface_count():
			var mat := ShaderMaterial.new()
			mat.shader = MUSHROOM_SHADER
			var src := mi.get_active_material(surface) as BaseMaterial3D
			if src != null:
				mat.set_shader_parameter("detail", src.albedo_texture)
				mat.set_shader_parameter("normal_map", src.normal_texture)
			mi.set_surface_override_material(surface, mat)


## 飄在林子裡的孢子：慢慢往上飄的紫色亮點，淡入淡出。只是氣氛。關卡每幀把它移到玩家那裡（粒子留在原地飄，新的在玩家周圍冒出來）。
static func build_spores(level: Node3D) -> CPUParticles3D:
	var spores := CPUParticles3D.new()
	spores.name = "Spores"
	spores.amount = 520
	spores.lifetime = 10.0
	spores.preprocess = 10.0
	spores.local_coords = false
	spores.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	spores.emission_box_extents = SPORE_BOX
	spores.position = Vector3(0.0, 1.5, 0.0)
	spores.direction = Vector3.UP
	spores.spread = 60.0
	spores.gravity = Vector3.ZERO
	spores.initial_velocity_min = 0.05
	spores.initial_velocity_max = 0.25
	spores.scale_amount_min = 0.5
	spores.scale_amount_max = 1.3
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color.WHITE, Color.WHITE, Color(1, 1, 1, 0)])
	spores.color_ramp = fade
	var quad := QuadMesh.new()
	quad.size = Vector2(0.13, 0.13)
	quad.material = ParticleLook.material(Color(0.85, 0.6, 1.0, 1.0), true)
	spores.mesh = quad
	spores.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	level.add_child(spores)
	return spores
