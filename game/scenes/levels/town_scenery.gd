class_name TownScenery
extends RefCounted
## 公會門外那條賒帳街看得到的東西（docs/story/chapter-1-expanded.md「自由時段 A」）。只是場景；劇情與規則在 TownStreet。
## 街是東西向的（沿著 X）：西頭是公會（北側，大門朝南），往東依序是藥房（南側，門口一張櫃檯＋遮雨棚）、藥房旁邊往南的小巷與後院、
## 佈告欄、麵攤（北側）、訓練場的倉庫（北側）、街尾的商人攤（南側），最東邊是東門，門外是往森林的土路。
## - 房子是程式拼的盒子＋三角柱的屋頂（town_facade／town_roof 兩個 shader：灰泥、木骨架、窗都是畫的）；街上的小物是 Quaternius 的 CC0
##   （scripts/gen_props.sh 的 QUAT）；公會的招牌、佈告欄、門外的樹是 Tripo 的。模型檔不在的就不擺。
## - 房子有碰撞（第 1 層：也擋鏡頭——戶外鏡頭退到牆上就往前推，不會看進盒子裡）；走得到的範圍是幾個長方形（WALK），keep_inside 拉回來。
## - 光：早上，太陽從東南邊斜斜照下來（有影子），天空是程式的 ProceduralSky，淡淡的霧。

## 街的半寬（兩邊房子的正面在 ±STREET_HALF）
const STREET_HALF: float = 5.0
## 走得到的範圍（x 最小、z 最小、x 最大、z 最大）：街、藥房旁邊往南的小巷、藥房後院
const WALK: Array[Rect2] = [
	Rect2(-11.5, -4.4, 75.5, 8.8),
	Rect2(11.0, 4.0, 2.0, 7.5),
	Rect2(2.5, 11.0, 10.5, 5.5),
]
## 房子：[節點名, 中心 x, 哪一側（-1 北、1 南）, 寬（沿街）, 深, 屋簷高, 灰泥色, 屋頂色, 面向街的一樓畫不畫窗]
const BUILDINGS: Array[Array] = [
	["Guild", -6.0, -1, 12.0, 10.0, 7.4, Color(0.9, 0.82, 0.66), Color(0.24, 0.3, 0.42), false],
	["HouseN1", 3.5, -1, 7.0, 6.0, 6.0, Color(0.93, 0.86, 0.78), Color(0.62, 0.28, 0.2), true],
	["NoodleHouse", 14.5, -1, 9.0, 6.0, 5.4, Color(0.95, 0.88, 0.7), Color(0.55, 0.22, 0.18), false],
	["HouseN2", 24.5, -1, 7.0, 6.0, 6.6, Color(0.9, 0.84, 0.86), Color(0.36, 0.38, 0.5), true],
	["Warehouse", 35.0, -1, 11.0, 8.0, 5.2, Color(0.78, 0.7, 0.58), Color(0.42, 0.3, 0.2), false],
	["HouseN3", 46.5, -1, 9.0, 6.0, 6.2, Color(0.94, 0.88, 0.74), Color(0.6, 0.32, 0.18), true],
	["HouseN4", 54.5, -1, 5.0, 6.0, 5.6, Color(0.88, 0.8, 0.72), Color(0.5, 0.25, 0.2), true],
	["HouseS0", -6.0, 1, 11.0, 6.0, 6.4, Color(0.92, 0.84, 0.72), Color(0.58, 0.3, 0.22), true],
	["Pharmacy", 5.5, 1, 9.0, 6.0, 6.0, Color(0.86, 0.92, 0.84), Color(0.2, 0.44, 0.42), false],
	["HouseS1", 19.0, 1, 11.0, 6.0, 6.4, Color(0.95, 0.86, 0.76), Color(0.64, 0.3, 0.2), true],
	["HouseS2", 30.0, 1, 9.0, 6.0, 5.8, Color(0.88, 0.85, 0.9), Color(0.4, 0.34, 0.48), true],
	["MerchantHouse", 40.5, 1, 10.0, 6.0, 6.2, Color(0.9, 0.8, 0.68), Color(0.5, 0.22, 0.26), false],
	["HouseS3", 51.0, 1, 9.0, 6.0, 6.6, Color(0.93, 0.87, 0.8), Color(0.6, 0.3, 0.18), true],
]
## 西頭擋住街的那一棟（橫在街上）
const WEST_END: Vector3 = Vector3(-14.0, 0, 0)
## 藥房後院的邊：西、東、南（北邊是藥房的背面）
const YARD: Rect2 = Rect2(1.0, 9.0, 13.5, 8.5)
## 公會的大門（北側，朝南）
const GUILD_DOOR: Vector3 = Vector3(-6.0, 0, -STREET_HALF)
## 藥房門口的櫃檯（店主與小學徒站在後面）
const PHARMACY_COUNTER: Vector3 = Vector3(5.5, 0, 3.3)
## 街上的佈告欄（北側牆邊）
const BOARD_POS: Vector3 = Vector3(9.0, 0, -4.2)
## 麵攤（北側）與地下室的木門
const NOODLE_STALL: Vector3 = Vector3(15.0, 0, -3.4)
const CELLAR_DOOR: Vector3 = Vector3(19.3, 0, -4.6)
## 訓練場倉庫的門口（倉庫大叔）
const WAREHOUSE_FRONT: Vector3 = Vector3(35.0, 0, -3.6)
## 街尾的商人攤（南側）
const MERCHANT_STALL: Vector3 = Vector3(40.5, 0, 3.4)
## 東門：兩座石塔中間，往東走出去就換到森林
const GATE_X: float = 58.5
const GATE_HALF: float = 2.8
const LEAVE_X: float = 61.5
const WOOD_SHADER: Shader = preload("res://src/world/guild_wood.gdshader")
const FACADE_SHADER: Shader = preload("res://src/world/town_facade.gdshader")
const ROOF_SHADER: Shader = preload("res://src/world/town_roof.gdshader")
const GROUND_SHADER: Shader = preload("res://src/world/town_ground.gdshader")
const SIGN_MODEL: String = "tripo/prop_guild_signboard"
const BOARD_MODEL: String = "tripo/prop_guild_quest_board"
const TREE_MODEL: String = "tripo/prop_corrupt_tree"
const TIMBER: Color = Color(0.32, 0.2, 0.13)
const AWNING_GREEN: Color = Color(0.3, 0.55, 0.46)
const AWNING_RED: Color = Color(0.72, 0.3, 0.24)
const SUN_DIR: Vector3 = Vector3(-0.55, -0.62, -0.56)

var _root: Node3D
## 每一棟房子（節點名 → 那個節點）：測試看
var buildings: Dictionary = {}


static func build(level: Node3D) -> TownScenery:
	var s := TownScenery.new()
	s._root = Node3D.new()
	s._root.name = "Scenery"
	level.add_child(s._root)
	s._build_environment(level)
	s._build_ground()
	for spec: Array in BUILDINGS:
		s._house(spec)
	s._house(["WestEnd", WEST_END.x, 0, 14.0, 4.0, 6.8, Color(0.9, 0.83, 0.72), Color(0.58, 0.28, 0.2), true])
	s._build_guild_front()
	s._build_pharmacy()
	s._build_yard()
	s._build_noodle_stall()
	s._build_warehouse()
	s._build_merchant()
	s._build_gate()
	s._build_street_props()
	return s


## 走得到的範圍：在任何一塊長方形裡就照原樣，不在就拉到最近的那一塊的邊上
static func keep_inside(p: Vector3) -> Vector3:
	var best := Vector2(p.x, p.z)
	var best_d: float = INF
	for r: Rect2 in WALK:
		var q := Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.z, r.position.y, r.end.y))
		var d: float = q.distance_squared_to(Vector2(p.x, p.z))
		if d < best_d:
			best_d = d
			best = q
	return Vector3(best.x, p.y, best.y)


static func is_walkable(p: Vector3) -> bool:
	for r: Rect2 in WALK:
		if r.has_point(Vector2(p.x, p.z)):
			return true
	return false


static func wood(tint: Color, along: Vector3, plank: float = 0.26) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = WOOD_SHADER
	m.set_shader_parameter("tint", tint)
	m.set_shader_parameter("along", along)
	m.set_shader_parameter("plank", plank)
	m.set_shader_parameter("wear", 0.3)
	return m


func _build_environment(level: Node3D) -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.36, 0.58, 0.92)
	sky_mat.sky_horizon_color = Color(0.86, 0.9, 0.96)
	sky_mat.ground_horizon_color = Color(0.72, 0.7, 0.66)
	sky_mat.ground_bottom_color = Color(0.4, 0.36, 0.32)
	sky_mat.sun_angle_max = 20.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.55
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	# 霧：中、高畫質用體積霧（QualityPreset 會關掉深度霧、打開體積霧；不設的話體積霧是引擎預設的 0.05，整條街一片白）
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.004
	env.volumetric_fog_albedo = Color(0.82, 0.88, 1.0)
	env.volumetric_fog_emission = Color(0.0, 0.0, 0.0)
	env.volumetric_fog_length = 64.0
	env.volumetric_fog_sky_affect = 0.0
	env.glow_enabled = true
	env.glow_intensity = 0.35
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	level.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_color = Color(1.0, 0.93, 0.8)
	sun.light_energy = 1.4
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 70.0
	level.add_child(sun)
	sun.look_at_from_position(Vector3.ZERO, SUN_DIR, Vector3.UP)


func _build_ground() -> void:
	var body := StaticBody3D.new()
	body.name = "Ground"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(160.0, 1.0, 80.0)
	shape.shape = box
	shape.position = Vector3(25.0, -0.5, 0)
	body.add_child(shape)
	var mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(160.0, 80.0)
	var mat := ShaderMaterial.new()
	mat.shader = GROUND_SHADER
	mat.set_shader_parameter("street_half", STREET_HALF)
	mat.set_shader_parameter("gate_x", GATE_X)
	plane.material = mat
	mi.mesh = plane
	mi.position = Vector3(25.0, 0, 0)
	body.add_child(mi)
	_root.add_child(body)


## 一棟房子：盒子（牆）＋三角柱（屋頂，屋脊順著街），南側的轉 180°（正面一律是本地的 +Z）
func _house(spec: Array) -> Node3D:
	var width: float = float(spec[3])
	var depth: float = float(spec[4])
	var eave: float = float(spec[5])
	var side: int = int(spec[2])
	var house := StaticBody3D.new()
	house.name = str(spec[0])
	if side == 0:
		house.position = Vector3(float(spec[1]), 0, 0)
		house.rotation_degrees.y = 90.0
	else:
		house.position = Vector3(float(spec[1]), 0, float(side) * (STREET_HALF + depth * 0.5))
		house.rotation_degrees.y = 0.0 if side < 0 else 180.0
	var seed_value: float = float(absi(hash(str(spec[0]))) % 97)
	var walls := MeshInstance3D.new()
	walls.name = "Walls"
	var box := BoxMesh.new()
	box.size = Vector3(width, eave, depth)
	var wm := ShaderMaterial.new()
	wm.shader = FACADE_SHADER
	wm.set_shader_parameter("box_half", box.size * 0.5)
	wm.set_shader_parameter("floor_y", minf(2.9, eave * 0.5))
	wm.set_shader_parameter("plaster", spec[6] as Color)
	wm.set_shader_parameter("timber", TIMBER)
	wm.set_shader_parameter("ground_windows", 1.0 if bool(spec[8]) else 0.0)
	wm.set_shader_parameter("seed", seed_value)
	wm.set_shader_parameter("shutter", Color.from_hsv(fmod(seed_value * 0.137, 1.0), 0.35, 0.55))
	box.material = wm
	walls.mesh = box
	walls.position.y = eave * 0.5
	house.add_child(walls)
	var roof := MeshInstance3D.new()
	roof.name = "Roof"
	var prism := PrismMesh.new()
	var rise: float = depth * 0.42
	prism.size = Vector3(depth + 1.0, rise, width + 0.8)
	var rm := ShaderMaterial.new()
	rm.shader = ROOF_SHADER
	rm.set_shader_parameter("tile", spec[7] as Color)
	rm.set_shader_parameter("plaster", spec[6] as Color)
	rm.set_shader_parameter("timber", TIMBER)
	rm.set_shader_parameter("size", prism.size)
	rm.set_shader_parameter("seed", seed_value)
	prism.material = rm
	roof.mesh = prism
	# PrismMesh 的屋脊順著本地 Z：轉 90° 讓它順著房子的寬（沿街）
	roof.rotation_degrees.y = 90.0
	roof.position.y = eave + rise * 0.5
	house.add_child(roof)
	var shape := CollisionShape3D.new()
	var col := BoxShape3D.new()
	col.size = box.size
	shape.shape = col
	shape.position.y = eave * 0.5
	house.add_child(shape)
	_root.add_child(house)
	buildings[str(spec[0])] = house
	return house


func _box(parent: Node3D, node_name: String, size: Vector3, at: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var b := BoxMesh.new()
	b.size = size
	b.material = mat
	mi.mesh = b
	mi.position = at
	parent.add_child(mi)
	return mi


## 擋路的一塊（第 1 層）
func _block(node_name: String, size: Vector3, at: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.position = at
	_root.add_child(body)
	return body


func _prop(model: String, at: Vector3, yaw_deg: float = 0.0, size: float = 1.0, parent: Node3D = null) -> Node3D:
	var n: Node3D = PropModels.instance(model)
	if n == null:
		return null
	n.position = at
	n.rotation_degrees.y = yaw_deg
	n.scale = Vector3.ONE * size
	(parent if parent != null else _root).add_child(n)
	return n


## 遮雨棚：從牆上斜斜伸出來的一片布，邊上垂一圈布條（條紋是兩種顏色交錯的小塊）
func _awning(node_name: String, center_x: float, z_wall: float, width: float, reach: float, height: float, color: Color) -> void:
	var a := Node3D.new()
	a.name = node_name
	_root.add_child(a)
	var dir: float = signf(-z_wall)
	var stripes: int = maxi(2, int(width / 0.6))
	for i: int in stripes:
		var m := StandardMaterial3D.new()
		m.albedo_color = color if i % 2 == 0 else Color(0.95, 0.92, 0.84)
		m.roughness = 0.95
		var piece := _box(a, "Stripe%d" % i, Vector3(width / float(stripes), 0.05, reach), Vector3(center_x - width * 0.5 + (float(i) + 0.5) * width / float(stripes), height, z_wall + dir * reach * 0.5), m)
		piece.rotation_degrees.x = -dir * 16.0
		_box(a, "Flap%d" % i, Vector3(width / float(stripes), 0.28, 0.03), Vector3(piece.position.x, height - reach * 0.27 - 0.14, z_wall + dir * reach), m)


func _lamp_on_wall(at: Vector3, yaw_deg: float) -> void:
	var lamp: Node3D = _prop("quaternius/Lantern_Wall", at, yaw_deg)
	if lamp == null:
		return
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.72, 0.4)
	light.light_energy = 0.6
	light.omni_range = 3.5
	light.position = Vector3(0, 0.3, 0.8)
	lamp.add_child(light)


## 公會的正面：大門（兩片木門板，開著一條縫）、門上的木框、門口的招牌與兩盞壁燈
func _build_guild_front() -> void:
	var z: float = -STREET_HALF + 0.02
	var door_wood: ShaderMaterial = wood(Color(0.34, 0.2, 0.12), Vector3(0, 1, 0), 0.22)
	_box(_root, "GuildDoorFrame", Vector3(3.2, 3.7, 0.12), Vector3(GUILD_DOOR.x, 1.85, z + 0.04), wood(Color(0.22, 0.13, 0.08), Vector3(1, 0, 0)))
	for i: int in 2:
		var leaf := _box(_root, "GuildDoorLeaf%d" % i, Vector3(1.3, 3.3, 0.08), Vector3(GUILD_DOOR.x + (-0.66 if i == 0 else 0.66), 1.65, z + 0.12), door_wood)
		leaf.rotation_degrees.y = 8.0 if i == 0 else -8.0
	var sign_post: Node3D = _prop(SIGN_MODEL, Vector3(GUILD_DOOR.x - 3.4, 0, -4.2), 160.0)
	if sign_post != null:
		sign_post.name = "Signboard"
	_lamp_on_wall(Vector3(GUILD_DOOR.x - 2.3, 2.6, z), 0.0)
	_lamp_on_wall(Vector3(GUILD_DOOR.x + 2.3, 2.6, z), 0.0)
	_prop("quaternius/Banner_1", Vector3(GUILD_DOOR.x - 4.5, 4.6, z), 90.0)
	_prop("quaternius/Banner_1", Vector3(GUILD_DOOR.x + 4.5, 4.6, z), 90.0)


## 藥房：門口一張長櫃檯（上面擺藥瓶）、牆邊兩個藥瓶架、綠白條紋的遮雨棚、門邊一張凳子（席菈蹲在旁邊修面具的扣帶）
func _build_pharmacy() -> void:
	var c: Vector3 = PHARMACY_COUNTER
	var z_wall: float = STREET_HALF
	_awning("PharmacyAwning", c.x, z_wall, 8.4, 2.4, 3.1, AWNING_GREEN)
	var counter: Node3D = _prop("quaternius/Table_Large", c, 90.0)
	if counter != null:
		counter.name = "PharmacyCounter"
	_block("PharmacyCounterBlock", Vector3(3.0, 1.0, 1.1), c + Vector3(0, 0.5, 0))
	for i: int in 5:
		_prop(["quaternius/Potion_1", "quaternius/Potion_2", "quaternius/Potion_4", "quaternius/SmallBottles_1", "quaternius/Potion_2"][i], c + Vector3(-1.1 + 0.55 * float(i), 0.92, -0.15 + 0.12 * float(i % 2)), 20.0 * float(i))
	_prop("quaternius/Shelf_Small_Bottles", Vector3(c.x - 3.2, 0, z_wall - 0.35), 180.0)
	_prop("quaternius/Shelf_Small_Bottles", Vector3(c.x + 3.2, 0, z_wall - 0.35), 180.0)
	_prop("quaternius/Stool", Vector3(c.x + 2.4, 0, c.z - 0.4), 30.0)
	_prop("quaternius/Bucket_Wooden_1", Vector3(c.x - 2.5, 0, c.z - 0.6), 0.0)
	_lamp_on_wall(Vector3(c.x - 4.2, 2.6, z_wall - 0.02), 180.0)
	# 藥房的招牌：一塊掛在牆上的木板（畫一個綠色的十字瓶）
	var plate := _box(_root, "PharmacySign", Vector3(2.2, 0.7, 0.08), Vector3(c.x, 4.3, z_wall - 0.06), wood(Color(0.45, 0.3, 0.18), Vector3(1, 0, 0)))
	var cross := StandardMaterial3D.new()
	cross.albedo_color = Color(0.36, 0.78, 0.5)
	cross.emission_enabled = true
	cross.emission = Color(0.2, 0.5, 0.3)
	_box(plate, "CrossH", Vector3(0.5, 0.14, 0.03), Vector3(0, 0, -0.05), cross)
	_box(plate, "CrossV", Vector3(0.14, 0.5, 0.03), Vector3(0, 0, -0.05), cross)


## 藥房後院：木頭圍籬、曬衣繩（兩根柱子＋一條繩）、一張小桌、幾個木桶。盾牌是 TownStreet 掛的（劇情的東西）
func _build_yard() -> void:
	var fence: ShaderMaterial = wood(Color(0.42, 0.3, 0.2), Vector3(0, 1, 0), 0.18)
	var y: Rect2 = YARD
	_box(_root, "YardFenceS", Vector3(y.size.x, 1.4, 0.1), Vector3(y.get_center().x, 0.7, y.end.y), fence)
	_box(_root, "YardFenceW", Vector3(0.1, 1.4, y.size.y), Vector3(y.position.x, 0.7, y.get_center().y), fence)
	_box(_root, "YardFenceE", Vector3(0.1, 1.4, y.size.y - 2.5), Vector3(y.end.x, 0.7, y.position.y + 2.5 + (y.size.y - 2.5) * 0.5), fence)
	for post_x: float in [4.0, 10.0]:
		_box(_root, "LinePost%d" % int(post_x), Vector3(0.12, 2.2, 0.12), Vector3(post_x, 1.1, 14.2), fence)
	var rope := MeshInstance3D.new()
	rope.name = "DryingLine"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.012
	cyl.bottom_radius = 0.012
	cyl.height = 6.0
	var rope_mat := StandardMaterial3D.new()
	rope_mat.albedo_color = Color(0.78, 0.72, 0.6)
	cyl.material = rope_mat
	rope.mesh = cyl
	rope.rotation_degrees.z = 90.0
	rope.position = Vector3(7.0, 2.05, 14.2)
	_root.add_child(rope)
	# 晾著的布（兩塊）
	for i: int in 2:
		var cloth := StandardMaterial3D.new()
		cloth.albedo_color = [Color(0.92, 0.9, 0.84), Color(0.55, 0.68, 0.82)][i]
		cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
		_box(_root, "Laundry%d" % i, Vector3(0.9, 0.8, 0.02), Vector3(4.9 + 1.2 * float(i), 1.62, 14.2), cloth)
	_prop("quaternius/Barrel", Vector3(2.0, 0, 10.2), 0.0)
	_prop("quaternius/Barrel", Vector3(2.8, 0, 10.0), 40.0)
	_prop("quaternius/Crate_Wooden", Vector3(12.6, 0, 16.4), 15.0)
	_prop("quaternius/Bench", Vector3(5.0, 0, 16.6), 0.0)


## 麵攤：攤車、冒煙的大鍋、兩張凳子、紅白的遮雨棚；旁邊往地下室的木門（斜斜地靠在牆上）
func _build_noodle_stall() -> void:
	var s: Vector3 = NOODLE_STALL
	_awning("NoodleAwning", s.x, -STREET_HALF, 6.0, 2.2, 3.0, AWNING_RED)
	var cart: Node3D = _prop("quaternius/Stall_Cart_Empty", s, 0.0)
	if cart != null:
		cart.name = "NoodleCart"
	_block("NoodleCartBlock", Vector3(2.6, 1.2, 1.4), s + Vector3(0, 0.6, 0))
	_prop("quaternius/Cauldron", s + Vector3(-2.4, 0, -0.6), 0.0)
	for i: int in 3:
		_prop("quaternius/Stool", s + Vector3(-1.0 + 1.0 * float(i), 0, 1.5), 15.0 * float(i))
	var door := _box(_root, "CellarDoor", Vector3(1.4, 0.08, 1.2), CELLAR_DOOR + Vector3(0, 0.4, 0.5), wood(Color(0.3, 0.2, 0.13), Vector3(1, 0, 0), 0.2))
	door.rotation_degrees.x = -38.0
	_box(_root, "CellarFrame", Vector3(1.6, 0.2, 1.4), CELLAR_DOOR + Vector3(0, 0.1, 0.55), wood(Color(0.2, 0.13, 0.08), Vector3(1, 0, 0)))


## 訓練場的倉庫：門口堆木箱與木桶、一個練習用的木人、武器架
func _build_warehouse() -> void:
	var w: Vector3 = WAREHOUSE_FRONT
	_box(_root, "WarehouseDoor", Vector3(3.4, 3.4, 0.1), Vector3(w.x, 1.7, -STREET_HALF + 0.06), wood(Color(0.36, 0.24, 0.14), Vector3(0, 1, 0), 0.3))
	_prop("quaternius/Crate_Wooden", Vector3(w.x - 3.4, 0, w.z - 0.4), 10.0)
	_prop("quaternius/Crate_Wooden", Vector3(w.x - 3.3, 0.9, w.z - 0.5), 35.0)
	_prop("quaternius/Barrel", Vector3(w.x - 4.4, 0, w.z - 0.3), 0.0)
	_prop("quaternius/Dummy", Vector3(w.x + 3.2, 0, w.z + 0.3), -20.0)
	_prop("quaternius/WeaponStand", Vector3(w.x + 4.6, 0, w.z - 0.6), 0.0)
	_prop("quaternius/Barrel_Holder", Vector3(w.x - 2.0, 0, w.z - 0.7), 0.0)


## 街尾的商人攤：攤子、上面擺零碎的小東西與一小堆錢
func _build_merchant() -> void:
	var m: Vector3 = MERCHANT_STALL
	var stall: Node3D = _prop("quaternius/Stall_Empty", m, 180.0)
	if stall != null:
		stall.name = "MerchantStall"
	_block("MerchantStallBlock", Vector3(2.6, 1.2, 1.2), m + Vector3(0, 0.6, 0))
	_prop("quaternius/Vase_2", m + Vector3(-0.8, 0.95, 0.1), 0.0)
	_prop("quaternius/Coin_Pile", m + Vector3(0.8, 0.95, 0.0), 0.0)
	_prop("quaternius/Crate_Wooden", m + Vector3(-2.2, 0, 0.6), 25.0)
	_prop("quaternius/Bag", m + Vector3(2.1, 0, 0.5), 0.0)
	_lamp_on_wall(Vector3(m.x + 3.0, 2.6, STREET_HALF - 0.02), 180.0)


## 東門：兩座石塔、上面一道木頭的門楣、兩片開到底的門板；門外兩排樹（往森林的路）
func _build_gate() -> void:
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.62, 0.6, 0.56)
	stone.roughness = 0.95
	var gate := Node3D.new()
	gate.name = "EastGateArch"
	_root.add_child(gate)
	for side: float in [-1.0, 1.0]:
		var tower := _box(gate, "Tower%s" % ("N" if side < 0 else "S"), Vector3(2.4, 6.4, 2.4), Vector3(GATE_X, 3.2, side * (GATE_HALF + 1.2)), stone)
		var cap := StandardMaterial3D.new()
		cap.albedo_color = Color(0.3, 0.34, 0.44)
		var cone := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = 1.9
		cm.height = 2.2
		cm.radial_segments = 4
		cm.material = cap
		cone.mesh = cm
		cone.rotation_degrees.y = 45.0
		cone.position = Vector3(0, 4.3, 0)
		tower.add_child(cone)
		_block("TowerBlock%s" % ("N" if side < 0 else "S"), Vector3(2.4, 6.4, 2.4), Vector3(GATE_X, 3.2, side * (GATE_HALF + 1.2)))
		# 城牆往兩邊接到房子後面
		_box(gate, "Wall%s" % ("N" if side < 0 else "S"), Vector3(1.4, 4.4, 12.0), Vector3(GATE_X, 2.2, side * (GATE_HALF + 8.4)), stone)
		_box(gate, "GateLeaf%s" % ("N" if side < 0 else "S"), Vector3(2.6, 4.0, 0.14), Vector3(GATE_X + 1.3, 2.0, side * (GATE_HALF - 0.1)), wood(Color(0.36, 0.22, 0.12), Vector3(0, 1, 0), 0.24))
	_box(gate, "Lintel", Vector3(1.6, 0.9, GATE_HALF * 2.0 + 0.6), Vector3(GATE_X, 5.4, 0), wood(Color(0.3, 0.19, 0.11), Vector3(0, 0, 1)))
	# 門外的路兩邊：森林那邊的樹（遠遠看得到往哪裡走）
	for i: int in 8:
		var x: float = GATE_X + 9.0 + 6.0 * floorf(float(i) / 2.0)
		var z: float = (7.5 + 2.0 * float(i % 3)) * (1.0 if i % 2 == 0 else -1.0)
		_prop(TREE_MODEL, Vector3(x, 0, z), 37.0 * float(i), 0.9 + 0.08 * float(i % 3))


## 街上零碎的東西：木桶、水果箱、長凳、佈告欄、牆上的燈
func _build_street_props() -> void:
	var board: Node3D = _prop(BOARD_MODEL, BOARD_POS, 0.0)
	if board != null:
		board.name = "StreetBoard"
	_block("BoardBlock", Vector3(1.6, 2.0, 0.4), BOARD_POS + Vector3(0, 1.0, 0))
	for spec: Array in [
		["quaternius/Barrel_Apples", Vector3(-0.8, 0, -4.3), 0.0],
		["quaternius/FarmCrate_Apple", Vector3(0.4, 0, -4.4), 10.0],
		["quaternius/Bench", Vector3(27.0, 0, -4.4), 0.0],
		["quaternius/Barrel", Vector3(23.2, 0, 4.4), 0.0],
		["quaternius/FarmCrate_Carrot", Vector3(24.4, 0, 4.5), -12.0],
		["quaternius/Barrel", Vector3(47.5, 0, -4.4), 20.0],
		["quaternius/Crate_Wooden", Vector3(53.0, 0, 4.4), 5.0],
		["quaternius/Bucket_Wooden_1", Vector3(30.5, 0, 4.4), 0.0],
	]:
		_prop(str(spec[0]), spec[1] as Vector3, float(spec[2]))
	for x: float in [3.0, 25.0, 47.0]:
		_lamp_on_wall(Vector3(x, 2.7, -STREET_HALF + 0.02), 0.0)
	for x: float in [19.0, 30.0, 51.0]:
		_lamp_on_wall(Vector3(x, 2.7, STREET_HALF - 0.02), 180.0)
