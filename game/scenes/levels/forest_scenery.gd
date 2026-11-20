class_name ForestScenery
extends RefCounted
## 腐敗之森看得到的東西：天空與光、地面、樹、草、路邊的小東西、飄著的孢子。只是場景——規則與劇情在 CorruptForest，地圖在 ForestMap。
## 地面是一片平面（顏色、路與空地的邊緣、落葉、毒沼都在 forest_ground.gdshader 裡算），上面長一團一團的草（GrassTufts）。
## 玩家走不到的外圍是土坡（ForestMap.height）：只是畫出來的，碰撞還是平的；種在坡上的樹與草照 ForestMap.ground_y 墊高。
## 樹、毒蕈、灌木是 Tripo 的模型（scripts/gen_props.sh 擺正後放 assets/props/tripo/，不進 git）；檔案不在就用程式拼的替身。

const TREE_MODEL: String = "tripo/prop_corrupt_tree"
const MUSHROOM_MODEL: String = "tripo/prop_glow_toxic_mushroom"
const BUSH_MODEL: String = "tripo/prop_rotten_fruit_bush"
## 夜光毒蕈放的算圖層：它們自己的燈不照這一層（small_prop）
const GLOW_PROP_LAYER: int = 1 << 1
const MUSHROOM_SHADER: Shader = preload("res://src/world/glow_mushroom.gdshader")
const GROUND_SHADER: Shader = preload("res://src/world/forest_ground.gdshader")
const SKY_SHADER: Shader = preload("res://src/world/forest_sky.gdshader")
const SWAY_SHADER: Shader = preload("res://src/world/wind_sway.gdshader")
const RING_SHADER: Shader = preload("res://src/world/pickup_ring.gdshader")
## 樹與灌木隨風擺（wind_sway.gdshader）：從多高開始擺、擺到多高、最多擺幾公尺（模型自己的座標）
const TREE_SWAY: Vector3 = Vector3(1.2, 6.5, 0.16)
const BUSH_SWAY: Vector3 = Vector3(0.15, 1.6, 0.07)
## 月亮在天上的方向：北偏東 8°、仰角 15°（站在森林口往北看，路的上方偏右）。月光（Moon）是從玩家背後照過來的，兩個不一致是故意的
const MOON_DIR: Vector3 = Vector3(0.134, 0.259, -0.956)
## 體積霧蓋天空蓋多少（1＝跟地上一樣濃，看不到星星與月亮）
const FOG_SKY: float = 0.3
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
## 地面的網格切成幾格（每邊）：外圍的土坡靠它彎起來
const GROUND_CELLS: int = 100
## 祭壇路口的遺跡：路的盡頭兩根斷柱夾著路（x、z 是對路口中心的位移，y＝幾節）、倒在地上的橫樑
const GATE_PILLARS: Array[Vector3] = [Vector3(-2.8, -3.6, 3.0), Vector3(2.8, -3.4, 2.0)]
const GATE_DRUM_HEIGHT: float = 1.1
const GATE_DRUM_RADIUS: float = 0.55
const GATE_RUNE_GLOW: float = 0.35
## 營火旁坐的圓木（x、z 對營火的位移，y＝朝向的角度）與行李（Quaternius 的小物，scripts/gen_props.sh 的 QUAT）
const CAMP_LOGS: Array[Vector3] = [Vector3(-2.3, 0.4, 80.0), Vector3(1.0, -2.2, 160.0)]
const CAMP_GEAR: Array[String] = ["quaternius/Bag", "quaternius/Pouch_Large", "quaternius/Bucket_Wooden_1"]
const CAMP_GEAR_SPOTS: Array[Vector3] = [Vector3(-2.9, -1.0, 30.0), Vector3(-2.5, -1.6, 75.0), Vector3(2.4, -1.4, 10.0)]
## 孢子跟著玩家飄：這麼大的一塊（公尺，半邊長）
const SPORE_BOX: Vector3 = Vector3(16.0, 1.5, 22.0)


## 黃昏的紫黑森林：頭頂暗、地平線泛紫、灑著星星的天（forest_sky.gdshader），往北看得到一輪月亮；冷的月光、暗紫的環境光，
## 體積霧讓遠處的樹一層一層淡進紫色裡（畫質低時 QualityPreset 換成深度霧）。霧只蓋天空的一部分（FOG_SKY），星星才透得出來。
static func build_environment(level: Node3D) -> void:
	var night := ShaderMaterial.new()
	night.shader = SKY_SHADER
	night.set_shader_parameter("moon_dir", MOON_DIR)
	var sky := Sky.new()
	sky.sky_material = night
	sky.radiance_size = Sky.RADIANCE_SIZE_32  # 環境光與反射都不從天空取（下面），不用算大的
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
	env.volumetric_fog_sky_affect = FOG_SKY
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
	# 外圍的土坡是 shader 照高度圖把頂點往上推的：網格要切細（一格 2 m）
	plane.subdivide_width = GROUND_CELLS - 1
	plane.subdivide_depth = GROUND_CELLS - 1
	var mat := ShaderMaterial.new()
	mat.shader = GROUND_SHADER
	mat.set_shader_parameter("ground_size", ForestMap.SIZE)
	mat.set_shader_parameter("height_map", ImageTexture.create_from_image(ForestMap.height_mask()))
	mat.set_shader_parameter("moss_mask", ImageTexture.create_from_image(moss_mask(trees)))
	mat.set_shader_parameter("trail_mask", ImageTexture.create_from_image(ForestMap.trail_mask()))
	plane.material = mat
	mesh.mesh = plane
	# 頂點被 shader 往上推過：外框要包住坡頂，影子與裁切才不會把坡切掉
	mesh.custom_aabb = AABB(Vector3(-ForestMap.SIZE * 0.5, -0.5, -ForestMap.SIZE * 0.5), Vector3(ForestMap.SIZE, ForestMap.RELIEF_MAX + 1.0, ForestMap.SIZE))
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
		forest.add_child(tree(on_ground(p), size, yaw))
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
		if minf(ForestMap.path_distance(ForestMap.flat(p)), ForestMap.clearing_distance(ForestMap.flat(p))) > DEEP_TREE_REACH or crowded(trees, p, 3.2):
			continue
		var size: float = deep.randf_range(0.85, 1.35)
		forest.add_child(tree(on_ground(p), size, deep.randf_range(0.0, TAU)))
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


## 樹種在坡上：放在樹腳下一圈（模型自帶的土丘約 1.5 m 寬）最低的那一點的高度，下坡那一側才不會懸空。
static func on_ground(p: Vector3) -> Vector3:
	var lowest: float = ForestMap.ground_y(ForestMap.flat(p))
	for side: Vector2 in [Vector2(1.5, 0.0), Vector2(-1.5, 0.0), Vector2(0.0, 1.5), Vector2(0.0, -1.5)]:
		lowest = minf(lowest, ForestMap.ground_y(ForestMap.flat(p) + side))
	return Vector3(p.x, lowest, p.z)


static func crowded(trees: PackedVector3Array, p: Vector3, gap: float) -> bool:
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
				p.y = ForestMap.ground_y(ForestMap.flat(p))
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
		mesh.scale = Vector3.ONE * size
		look = mesh
	else:
		# 每棵長得不太一樣：高矮胖瘦、顏色偏一點（只有一種樹的模型，照位置算、每次都一樣）
		var v: Vector3 = variation(at)
		look.scale = Vector3(size * v.x, size * v.y, size * v.x)
		sway(look, TREE_SWAY, tree_tint(v.z))
	body.add_child(look)
	return body


## 照位置算的三個 0～1 之間的亂數換成：寬（x）、高（y）的倍數，與顏色偏移用的一個數（z）。純函式。
static func variation(at: Vector3) -> Vector3:
	var h1: float = fposmod(sin(at.x * 12.9898 + at.z * 78.233) * 43758.5453, 1.0)
	var h2: float = fposmod(sin(at.x * 39.346 + at.z * 11.135) * 24634.6345, 1.0)
	var h3: float = fposmod(sin(at.x * 73.156 + at.z * 52.235) * 17563.2189, 1.0)
	return Vector3(lerpf(0.86, 1.06, h1), lerpf(0.9, 1.28, h2), h3)


## 樹的顏色偏移：大多偏暗紫一點或偏青一點，少數亮一點。乘在模型的顏色上。
static func tree_tint(t: float) -> Color:
	if t < 0.4:
		return Color(0.82, 0.78, 0.95).lerp(Color.WHITE, t / 0.4 * 0.5)
	if t < 0.8:
		return Color(0.8, 0.95, 0.92).lerp(Color.WHITE, (t - 0.4) / 0.4 * 0.5)
	return Color(1.08, 1.02, 1.1)


## 把模型的材質換成會隨風擺的（wind_sway.gdshader；顏色、法線、粗糙度照原本的貼圖）。
## params＝(從多高開始擺, 擺到多高, 最多擺幾公尺)。同一個原本的材質只換一次（記在它的 meta 上，所有的樹共用）。
static func sway(model: Node3D, params: Vector3, tint: Color = Color.WHITE) -> void:
	var meshes: Array[Node] = model.find_children("*", "MeshInstance3D", true, false)
	if model is MeshInstance3D:
		meshes.append(model)
	for n: Node in meshes:
		var mi := n as MeshInstance3D
		for surface: int in mi.mesh.get_surface_count():
			var src := mi.get_active_material(surface) as BaseMaterial3D
			if src == null:
				continue
			var key: String = "sway_%d_%d_%d" % [int(params.x * 100.0), int(params.y * 100.0), int(params.z * 1000.0)]
			var mat: ShaderMaterial = src.get_meta(key) if src.has_meta(key) else null
			if mat == null:
				mat = ShaderMaterial.new()
				mat.shader = SWAY_SHADER
				mat.set_shader_parameter("albedo_tex", src.albedo_texture)
				mat.set_shader_parameter("normal_tex", src.normal_texture)
				mat.set_shader_parameter("has_normal", src.normal_enabled and src.normal_texture != null)
				mat.set_shader_parameter("orm_tex", src.roughness_texture)
				mat.set_shader_parameter("has_orm", src.roughness_texture != null)
				mat.set_shader_parameter("sway_from", params.x)
				mat.set_shader_parameter("sway_height", params.y)
				mat.set_shader_parameter("sway_amount", params.z)
				src.set_meta(key, mat)
			mi.set_surface_override_material(surface, mat)
		mi.set_instance_shader_parameter("tint", Vector3(tint.r, tint.g, tint.b))
		if mi != model:
			mi.set_instance_shader_parameter("base_y", mi.position.y)


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
	elif not glows:
		sway(look, BUSH_SWAY)
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
			# 轉檔時記了「往上看不看得到天空」的頂點色（gen_props.sh 的 --sky-mask）：分得出傘的邊緣與蕈柄
			mat.set_shader_parameter("has_sky", 1.0 if mi.mesh.surface_get_format(surface) & Mesh.ARRAY_FORMAT_COLOR else 0.0)
			mi.set_surface_override_material(surface, mat)


## 「這個可以拿」的地面光圈（pickup_ring.gdshader）：平放在腳下、一圈一圈往外擴。radius＝公尺。節點名 PickupRing。
static func pickup_ring(radius: float, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "PickupRing"
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * radius * 2.0
	quad.orientation = PlaneMesh.FACE_Y
	var mat := ShaderMaterial.new()
	mat.shader = RING_SHADER
	mat.set_shader_parameter("color", color)
	quad.material = mat
	mi.mesh = quad
	mi.position = Vector3(0, 0.04, 0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## 地圖上認得出來的地方：祭壇路口的斷柱與倒下的橫樑、營火旁坐的圓木與行李。只是場景（擋人的碰撞有）。
static func build_landmarks(level: Node3D) -> void:
	level.add_child(altar_gate_ruins())
	level.add_child(camp_site())


## 祭壇路口：路的盡頭兩根斷柱（左邊三節＋柱頭、右邊斷成兩節）、倒在地上斷成兩截的橫樑、幾塊碎石。
## 石頭跟祭壇那一關同一套（AltarScenery.stone_material：苔、會亮的符文），從路上遠遠看得出「那邊是遺跡」。
static func altar_gate_ruins() -> Node3D:
	var root := Node3D.new()
	root.name = "AltarRuins"
	var center: Vector3 = ForestMap.at(ForestMap.ALTAR_GATE)
	root.position = center
	for spec: Vector3 in GATE_PILLARS:
		var drums: int = int(spec.z)
		var at := Vector3(spec.x, 0.0, spec.y)
		var pillar := StaticBody3D.new()
		pillar.name = "GatePillar%d" % (root.get_child_count() + 1)
		pillar.position = at
		var tall: float = GATE_DRUM_HEIGHT * float(drums)
		var mat: ShaderMaterial = AltarScenery.stone_material(center + at, maxf(tall, 2.2), GATE_DRUM_RADIUS, false, GATE_RUNE_GLOW,
			AltarScenery.FLUTES, GATE_DRUM_HEIGHT)
		var plinth := MeshInstance3D.new()
		var slab := BoxMesh.new()
		slab.size = Vector3(1.5, 0.3, 1.5)
		slab.material = mat
		plinth.mesh = slab
		plinth.position = Vector3(0, 0.15, 0)
		plinth.rotation.y = 0.12 * spec.x
		pillar.add_child(plinth)
		for k: int in drums:
			var broken: bool = drums < 3 and k == drums - 1
			var drum: MeshInstance3D = AltarScenery.broken_drum(GATE_DRUM_RADIUS - 0.02 * float(k), GATE_DRUM_HEIGHT, mat, k + 11) if broken \
				else AltarScenery._drum(GATE_DRUM_RADIUS - 0.02 * float(k), GATE_DRUM_HEIGHT, mat)
			drum.position = Vector3(0.0, 0.3 + GATE_DRUM_HEIGHT * (float(k) + 0.5), 0.0)
			drum.rotation.y = float(k) * 1.9
			if drums < 3 and k == drums - 1:
				drum.rotation.z = 0.09
			pillar.add_child(drum)
		if drums >= 3:
			var cap := MeshInstance3D.new()
			var block := BoxMesh.new()
			block.size = Vector3(1.4, 0.34, 1.4)
			block.material = mat
			cap.mesh = block
			cap.position = Vector3(0, 0.3 + tall + 0.17, 0)
			pillar.add_child(cap)
		var shape := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = GATE_DRUM_RADIUS + 0.15
		cyl.height = tall + 0.3
		shape.shape = cyl
		shape.position = Vector3(0, cyl.height * 0.5, 0)
		pillar.add_child(shape)
		root.add_child(pillar)
	# 倒下來的橫樑：斷成兩截，一截斜靠在右邊那根斷柱腳下、一截躺在路邊
	var beam := StaticBody3D.new()
	beam.name = "FallenLintel"
	var beam_mat: ShaderMaterial = AltarScenery.stone_material(center + Vector3(1.6, -0.4, -5.2), 1.2, 0.5, false, GATE_RUNE_GLOW)
	for piece: Array in [[Vector3(1.9, 0.32, -5.0), Vector3(0.0, deg_to_rad(18.0), 0.0), 2.6], [Vector3(-0.6, 0.3, -6.2), Vector3(0.0, deg_to_rad(-7.0), deg_to_rad(4.0)), 2.2]]:
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(float(piece[2]), 0.62, 0.8)
		box.material = beam_mat
		mi.mesh = box
		mi.position = piece[0]
		mi.rotation = piece[1]
		beam.add_child(mi)
		var shape := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = box.size
		shape.shape = bs
		shape.position = mi.position
		shape.rotation = mi.rotation
		beam.add_child(shape)
	root.add_child(beam)
	# 碎石
	var rubble_mat: ShaderMaterial = AltarScenery.stone_material(center + Vector3(0, -0.3, -4.0), 0.8, 0.4, false, 0.0)
	for r: Vector4 in [Vector4(-1.6, -4.4, 0.32, 0.4), Vector4(3.9, -2.4, 0.26, 1.2), Vector4(-3.8, -2.0, 0.38, 2.3), Vector4(0.9, -3.4, 0.2, 0.7), Vector4(-2.2, -5.6, 0.28, 2.9)]:
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(r.z * 1.6, r.z, r.z * 1.2)
		box.material = rubble_mat
		mi.mesh = box
		mi.position = Vector3(r.x, r.z * 0.35, r.y)
		mi.rotation = Vector3(r.w * 0.3, r.w, r.w * 0.2)
		root.add_child(mi)
	return root


## 營火那一塊空地：兩根坐的圓木圍著火、旁邊放著行李（布袋、皮袋、木桶）。模型不在就只有圓木。
static func camp_site() -> Node3D:
	var root := Node3D.new()
	root.name = "CampSite"
	root.position = ForestMap.at(ForestMap.CAMP)
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color(0.3, 0.21, 0.2)
	bark.roughness = 0.95
	var cut := StandardMaterial3D.new()
	cut.albedo_color = Color(0.62, 0.48, 0.36)
	for i: int in CAMP_LOGS.size():
		var spec: Vector3 = CAMP_LOGS[i]
		var log_body := StaticBody3D.new()
		log_body.name = "Log%d" % (i + 1)
		log_body.position = Vector3(spec.x, 0.0, spec.y)
		log_body.rotation.y = deg_to_rad(spec.z)
		var mi := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.24
		cyl.bottom_radius = 0.27
		cyl.height = 1.9
		cyl.radial_segments = 12
		cyl.material = bark
		mi.mesh = cyl
		mi.rotation.z = PI * 0.5
		mi.position = Vector3(0, 0.25, 0)
		log_body.add_child(mi)
		# 兩頭鋸開的截面（亮一點的木頭色）
		for end: float in [-0.951, 0.951]:
			var cap := MeshInstance3D.new()
			var disc := CylinderMesh.new()
			disc.top_radius = 0.23
			disc.bottom_radius = 0.23
			disc.height = 0.02
			disc.radial_segments = 12
			disc.material = cut
			cap.mesh = disc
			cap.rotation.z = PI * 0.5
			cap.position = Vector3(end, 0.25, 0)
			log_body.add_child(cap)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(1.9, 0.5, 0.5)
		shape.shape = box
		shape.position = Vector3(0, 0.25, 0)
		log_body.add_child(shape)
		root.add_child(log_body)
	for i: int in CAMP_GEAR.size():
		var gear: Node3D = PropModels.instance(CAMP_GEAR[i])
		if gear == null:
			continue
		gear.name = "Gear%d" % (i + 1)
		gear.position = Vector3(CAMP_GEAR_SPOTS[i].x, 0.0, CAMP_GEAR_SPOTS[i].y)
		gear.rotation.y = deg_to_rad(CAMP_GEAR_SPOTS[i].z)
		root.add_child(gear)
	return root


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
