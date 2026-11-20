class_name TownScenery
extends RefCounted
## 公會門外那條賒帳街看得到的東西（docs/story/chapter-1-expanded.md「自由時段 A」）。只是場景；劇情與規則在 TownStreet。
## 街是東西向的（沿著 X）：西頭是公會（北側，大門朝南），往東依序是藥房（南側，門口一張櫃檯＋遮雨棚）、藥房旁邊往南的小巷與後院、
## 佈告欄、麵攤（北側）、訓練場的倉庫（北側）、街尾的商人攤（南側），最東邊是東門，門外是往森林的土路。
## - 房子是程式拼的盒子＋三角柱的屋頂（town_facade／town_roof 兩個 shader：灰泥、木骨架、窗都是畫的）；街上的小物是 Quaternius 的 CC0
##   （scripts/gen_props.sh 的 QUAT）；公會的招牌、佈告欄、門外的樹是 Tripo 的。模型檔不在的就不擺。
## - 房子有碰撞（第 1 層：也擋鏡頭——戶外鏡頭退到牆上就往前推，不會看進盒子裡）；走得到的範圍是幾個長方形（WALK），keep_inside 拉回來。
## - 光：早上，太陽從東南邊斜斜照下來（有影子），天空是程式的 ProceduralSky，淡淡的霧。環境光一半是天空、一半是暖色
##   （全照天空的話影子與石板路一片藍）；地下室另外一套很暗的（set_cellar：天花板擋得住太陽、擋不住環境光）。
## - 街的四周一圈城牆（房子後面；從房子之間的縫與後院看出去是牆，不是地平線）。
##   傍晚（回程）：太陽從西邊低低地照過來，房子的窗一扇一扇亮起來（town_facade 的 dusk）、牆上的壁燈點著（白天不點）。

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
## 麵攤的地下室：街的東邊、地面底下 12 m 另外蓋的一間（走下去是畫面暗一下、換到這裡；地面擋住太陽，從街上看不到）。
## 走得到的範圍（x、z）、地板的高度、下來站的地方、梯子。下面的位置都是「地下室裡」的（y 是相對地下室的地板）
const CELLAR: Rect2 = Rect2(90.6, -2.4, 7.8, 5.0)
const CELLAR_Y: float = -12.0
const CELLAR_CENTER: Vector3 = Vector3(94.5, 0, 0)
const CELLAR_IN: Vector3 = Vector3(91.6, CELLAR_Y + 0.05, 1.6)
const CELLAR_LADDER: Vector3 = Vector3(91.0, 0, 2.2)
## 暖管與鐵網（北牆）、牆上的油燈、備用暖管的閥、空酒桶
const CELLAR_PIPE_Z: float = -3.05
const CELLAR_MESH_Z: float = -2.65
const CELLAR_LAMP: Vector3 = Vector3(93.2, 0, -2.4)
const CELLAR_VALVE: Vector3 = Vector3(97.6, 0, -1.6)
const CELLAR_BARREL: Vector3 = Vector3(97.2, 0, 1.6)
## 抱著暖管的三團黴泥（鐵網後面）
const CELLAR_SLIMES: Array[Vector3] = [Vector3(93.6, 0, -3.1), Vector3(95.0, 0, -3.1), Vector3(96.4, 0, -3.1)]
## 東門：兩座石塔中間，往東走出去就換到森林
const GATE_X: float = 58.5
const GATE_HALF: float = 2.8
const LEAVE_X: float = 61.5
const WOOD_SHADER: Shader = preload("res://src/world/guild_wood.gdshader")
const FACADE_SHADER: Shader = preload("res://src/world/town_facade.gdshader")
const ROOF_SHADER: Shader = preload("res://src/world/town_roof.gdshader")
const GROUND_SHADER: Shader = preload("res://src/world/town_ground.gdshader")
const WALL_SHADER: Shader = preload("res://src/world/town_wall.gdshader")
const SIGN_MODEL: String = "tripo/prop_guild_signboard"
const BOARD_MODEL: String = "tripo/prop_guild_quest_board"
const TREE_MODEL: String = "tripo/prop_corrupt_tree"
const TIMBER: Color = Color(0.32, 0.2, 0.13)
const AWNING_GREEN: Color = Color(0.3, 0.55, 0.46)
const AWNING_RED: Color = Color(0.72, 0.3, 0.24)
const SUN_DIR: Vector3 = Vector3(-0.55, -0.62, -0.56)
## 傍晚（回程，TownStreet 的 return_pharmacy 階段）：太陽從西邊低低地照過來
const DUSK_SUN_DIR: Vector3 = Vector3(0.82, -0.3, -0.36)
## 環境光：白天天空佔幾成（其餘是 DAY_AMBIENT 這個暖色）、多亮；地下室裡的（不看天空，只有一點暖灰）
const DAY_SKY_SHARE: float = 0.45
const DAY_AMBIENT: Color = Color(1.0, 0.9, 0.76)
const DAY_AMBIENT_ENERGY: float = 0.55
const DUSK_AMBIENT_ENERGY: float = 0.42
const CELLAR_AMBIENT: Color = Color(0.5, 0.42, 0.36)
const CELLAR_AMBIENT_ENERGY: float = 0.3
## 城牆（房子後面一圈）：內側在街的中線往南北各多遠、西邊到哪、多高
const WALL_Z: float = 17.5
const WALL_WEST_X: float = -22.0
const WALL_HEIGHT: float = 4.4
const WALL_THICK: float = 1.4

## 麵攤的鍋；傍晚（回程）遮雨棚前緣掛出紅燈籠（整個攤子是暖的），鍋煮得開的話（boiling）有蒸氣與鍋底的火光
const POT_POS: Vector3 = NOODLE_STALL + Vector3(-2.4, 0, -0.6)
const STALL_LANTERN: Vector3 = NOODLE_STALL + Vector3(1.9, 2.2, 0.75)
const STALL_LANTERN_COLOR: Color = Color(1.0, 0.42, 0.2)
## 藥房櫃檯上的藥瓶傍晚只留西邊這幾瓶（東半邊空出來：回程擺盾與那一籃毒蕈，TownStreet）
const COUNTER_BOTTLES_DUSK: int = 3
## 傍晚的壁燈：火苗的大小、燈多亮、照多遠（白天不點：只有燈籠的模型）
const LAMP_FLAME: Vector2 = Vector2(0.15, 0.28)
const LAMP_ENERGY: float = 2.4
const LAMP_REACH: float = 7.5
const LAMP_COLOR: Color = Color(1.0, 0.68, 0.36)

## 傍晚的街（第一章的回程）
var dusk: bool = false
var boiling: bool = false
## 點著的壁燈（傍晚才有；測試看）
var lamps: Array[CandleFlame] = []
## 麵攤鍋上的蒸氣（傍晚、鍋煮得開才有）
var pot_steam: CPUParticles3D
var _env: Environment
var _root: Node3D
## 每一棟房子（節點名 → 那個節點）：測試看
var buildings: Dictionary = {}


## p_dusk＝傍晚（回程）；p_boiling＝麵攤的鍋煮得開（地下室偷暖的黴泥解決了：傍晚鍋上有蒸氣、鍋底有火光）
static func build(level: Node3D, p_dusk: bool = false, p_boiling: bool = false) -> TownScenery:
	var s := TownScenery.new()
	s.dusk = p_dusk
	s.boiling = p_boiling
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
	s._build_cellar()
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


## 地下室裡走得到的範圍
static func keep_in_cellar(p: Vector3) -> Vector3:
	return Vector3(clampf(p.x, CELLAR.position.x, CELLAR.end.x), p.y, clampf(p.z, CELLAR.position.y, CELLAR.end.y))


## 地下室裡的位置（相對地下室地板）→ 世界座標
static func in_cellar(p: Vector3) -> Vector3:
	return p + Vector3(0, CELLAR_Y, 0)


static func is_in_cellar(p: Vector3) -> bool:
	return p.y < CELLAR_Y * 0.5


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
	sky_mat.sky_top_color = Color(0.3, 0.3, 0.6) if dusk else Color(0.36, 0.58, 0.92)
	sky_mat.sky_horizon_color = Color(1.0, 0.62, 0.42) if dusk else Color(0.86, 0.9, 0.96)
	sky_mat.ground_horizon_color = Color(0.72, 0.7, 0.66)
	sky_mat.ground_bottom_color = Color(0.4, 0.36, 0.32)
	sky_mat.sun_angle_max = 20.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	_env = env
	set_cellar(false)
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
	sun.light_color = Color(1.0, 0.6, 0.36) if dusk else Color(1.0, 0.93, 0.8)
	sun.light_energy = 1.25 if dusk else 1.4
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 70.0
	level.add_child(sun)
	sun.look_at_from_position(Vector3.ZERO, DUSK_SUN_DIR if dusk else SUN_DIR, Vector3.UP)


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
	mat.set_shader_parameter("yard", Vector4(YARD.position.x, YARD.position.y + 1.6, YARD.end.x, YARD.end.y))
	mat.set_shader_parameter("alley", Vector4(WALK[1].position.x - 1.0, 0.0, WALK[1].end.x + 0.6, YARD.position.y + 1.6))
	plane.material = mat
	mi.mesh = plane
	mi.position = Vector3(25.0, 0, 0)
	body.add_child(mi)
	_root.add_child(body)


## 在地下室裡嗎：環境光換成很暗的一點暖灰（只剩油燈與梯子口的光）；回到街上換回來。傍晚照舊全照天空（紫色的影子是那時候要的）
func set_cellar(on: bool) -> void:
	if on:
		_env.ambient_light_color = CELLAR_AMBIENT
		_env.ambient_light_sky_contribution = 0.0
		_env.ambient_light_energy = CELLAR_AMBIENT_ENERGY
	else:
		_env.ambient_light_color = DAY_AMBIENT
		_env.ambient_light_sky_contribution = 1.0 if dusk else DAY_SKY_SHARE
		_env.ambient_light_energy = DUSK_AMBIENT_ENERGY if dusk else DAY_AMBIENT_ENERGY


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
	wm.set_shader_parameter("dusk", 1.0 if dusk else 0.0)
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


## 牆上的一盞壁燈：燈籠的模型（不在就不擺）；傍晚點著——籠子裡一朵火苗＋一盞會閃的暖燈，照得到牆與腳下的石板
func _lamp_on_wall(at: Vector3, yaw_deg: float) -> void:
	var holder := Node3D.new()
	holder.name = "WallLamp%d" % _root.get_child_count()
	holder.position = at
	holder.rotation_degrees.y = yaw_deg
	_root.add_child(holder)
	_prop("quaternius/Lantern_Wall", Vector3.ZERO, 0.0, 1.0, holder)
	if not dusk:
		return
	var f: CandleFlame = CandleFlame.create(LAMP_FLAME, float(lamps.size()) * 1.9 + 0.4, 0.5, GuildScenery.LANTERN_PULL, LAMP_ENERGY, LAMP_REACH, LAMP_COLOR)
	f.position = GuildScenery.LANTERN_FLAME
	# 整條街十盞：遠的那幾盞淡掉（站在東門看不到西頭的燈照在地上的那一圈）
	f.light.distance_fade_enabled = true
	f.light.distance_fade_begin = 38.0
	f.light.distance_fade_length = 10.0
	holder.add_child(f)
	lamps.append(f)


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
	for i: int in (COUNTER_BOTTLES_DUSK if dusk else 5):
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
	_prop("quaternius/Cauldron", POT_POS, 0.0)
	if dusk:
		_root.add_child(_stall_lantern())
	if dusk and boiling:
		pot_steam = steam(0.5, 10)
		pot_steam.name = "PotSteam"
		pot_steam.position = POT_POS + Vector3(0, 0.82, 0)
		_root.add_child(pot_steam)
		var fire := OmniLight3D.new()
		fire.name = "PotFire"
		fire.light_color = Color(1.0, 0.5, 0.2)
		fire.light_energy = 1.3
		fire.omni_range = 3.2
		fire.shadow_enabled = false
		fire.position = POT_POS + Vector3(0, 0.25, 0.75)
		_root.add_child(fire)
	for i: int in 3:
		_prop("quaternius/Stool", s + Vector3(-1.0 + 1.0 * float(i), 0, 1.5), 15.0 * float(i))
	var door := _box(_root, "CellarDoor", Vector3(1.4, 0.08, 1.2), CELLAR_DOOR + Vector3(0, 0.4, 0.5), wood(Color(0.3, 0.2, 0.13), Vector3(1, 0, 0), 0.2))
	door.rotation_degrees.x = -38.0
	_box(_root, "CellarFrame", Vector3(1.6, 0.2, 1.4), CELLAR_DOOR + Vector3(0, 0.1, 0.55), wood(Color(0.2, 0.13, 0.08), Vector3(1, 0, 0)))


## 麵攤的紅燈籠：一條繩、上下兩個木蓋、中間一顆發光的紙球，裡面一朵會閃的火（帶燈）
func _stall_lantern() -> Node3D:
	var root := Node3D.new()
	root.name = "StallLantern"
	root.position = STALL_LANTERN
	var paper := StandardMaterial3D.new()
	paper.albedo_color = Color(0.8, 0.22, 0.14)
	paper.emission_enabled = true
	paper.emission = STALL_LANTERN_COLOR
	paper.emission_energy_multiplier = 1.1
	var ball := MeshInstance3D.new()
	ball.name = "Paper"
	var sm := SphereMesh.new()
	sm.radius = 0.17
	sm.height = 0.4
	sm.radial_segments = 12
	sm.rings = 6
	sm.material = paper
	ball.mesh = sm
	root.add_child(ball)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.16, 0.1, 0.07)
	for y: float in [0.2, -0.2]:
		var cap := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.07
		cm.bottom_radius = 0.07
		cm.height = 0.04
		cm.material = dark
		cap.mesh = cm
		cap.position.y = y
		root.add_child(cap)
	var cord := MeshInstance3D.new()
	var cord_mesh := CylinderMesh.new()
	cord_mesh.top_radius = 0.008
	cord_mesh.bottom_radius = 0.008
	cord_mesh.height = 0.5
	cord_mesh.material = dark
	cord.mesh = cord_mesh
	cord.position.y = 0.46
	root.add_child(cord)
	var flame: CandleFlame = CandleFlame.create(Vector2(0.01, 0.01), 2.3, 0.0, 0.0, 2.0, 6.0, STALL_LANTERN_COLOR)
	flame.name = "LanternFlame"
	root.add_child(flame)
	return root


## 一縷往上飄的白蒸氣（鍋、湯碗）：puff＝一團多大（公尺）
static func steam(puff: float, amount: int) -> CPUParticles3D:
	var ps := CPUParticles3D.new()
	ps.name = "Steam"
	ps.amount = amount
	ps.lifetime = 2.2
	ps.preprocess = 2.2
	ps.direction = Vector3.UP
	ps.spread = 12.0
	ps.gravity = Vector3(0.12, 0.25, 0)
	ps.initial_velocity_min = puff * 0.7
	ps.initial_velocity_max = puff * 1.3
	ps.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	ps.emission_sphere_radius = puff * 0.45
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.2, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0.5), Color(1, 1, 1, 0)])
	ps.color_ramp = fade
	var quad := QuadMesh.new()
	quad.size = Vector2(puff, puff)
	quad.material = ParticleLook.material(Color(1.0, 0.96, 0.9, 0.5))
	ps.mesh = quad
	ps.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return ps


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
	var stone := ShaderMaterial.new()
	stone.shader = WALL_SHADER
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
		# 城牆往兩邊接到房子後面，再沿著房子後面繞到西頭（WALL_Z）：從房子之間的縫、藥房後院看出去是牆
		var east_len: float = WALL_Z + WALL_THICK - GATE_HALF - 2.4
		_box(gate, "Wall%s" % ("N" if side < 0 else "S"), Vector3(WALL_THICK, WALL_HEIGHT, east_len), Vector3(GATE_X, WALL_HEIGHT * 0.5, side * (GATE_HALF + 2.4 + east_len * 0.5)), stone)
		_box(gate, "TownWall%s" % ("N" if side < 0 else "S"), Vector3(GATE_X - WALL_WEST_X, WALL_HEIGHT, WALL_THICK), Vector3((GATE_X + WALL_WEST_X) * 0.5, WALL_HEIGHT * 0.5, side * (WALL_Z + WALL_THICK * 0.5)), stone)
		_box(gate, "GateLeaf%s" % ("N" if side < 0 else "S"), Vector3(2.6, 4.0, 0.14), Vector3(GATE_X + 1.3, 2.0, side * (GATE_HALF - 0.1)), wood(Color(0.36, 0.22, 0.12), Vector3(0, 1, 0), 0.24))
	_box(gate, "Lintel", Vector3(1.6, 0.9, GATE_HALF * 2.0 + 0.6), Vector3(GATE_X, 5.4, 0), wood(Color(0.3, 0.19, 0.11), Vector3(0, 0, 1)))
	_box(gate, "TownWallW", Vector3(WALL_THICK, WALL_HEIGHT, (WALL_Z + WALL_THICK) * 2.0), Vector3(WALL_WEST_X - WALL_THICK * 0.5, WALL_HEIGHT * 0.5, 0), stone)
	# 門外的路兩邊：森林那邊的樹（遠遠看得到往哪裡走）
	# 從街上穿過門洞看得到路兩邊的樹（門洞只有 ±GATE_HALF 寬：近的種在路邊、遠的往兩邊散開）
	for i: int in 10:
		var x: float = GATE_X + 10.0 + 5.5 * floorf(float(i) / 2.0)
		var z: float = (3.6 + 1.2 * float(i % 3) + 0.5 * floorf(float(i) / 2.0)) * (1.0 if i % 2 == 0 else -1.0)
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


## 麵攤的地下室：石牆、木頭天花板、北牆上兩根銅色的暖管（前面一排鐵網）、一截備用暖管與閥、空酒桶、牆上的油燈、往上的梯子。
## 天花板擋住太陽：只有油燈與從梯子口照下來的一點光
func _build_cellar() -> void:
	var c := Node3D.new()
	c.name = "Cellar"
	c.position.y = CELLAR_Y
	_root.add_child(c)
	var down := Vector3(0, CELLAR_Y, 0)
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.36, 0.33, 0.3)
	stone.roughness = 0.95
	var w: float = CELLAR.size.x + 1.4
	var d: float = CELLAR.size.y + 1.4
	var cx: float = CELLAR_CENTER.x
	for spec: Array in [
		["WallN", Vector3(w + 1.0, 3.2, 0.5), Vector3(cx, 1.6, CELLAR.position.y - 0.95)],
		["WallS", Vector3(w + 1.0, 3.2, 0.5), Vector3(cx, 1.6, CELLAR.end.y + 0.95)],
		["WallW", Vector3(0.5, 3.2, d + 1.0), Vector3(CELLAR.position.x - 0.95, 1.6, 0)],
		["WallE", Vector3(0.5, 3.2, d + 1.0), Vector3(CELLAR.end.x + 0.95, 1.6, 0)],
	]:
		_box(c, str(spec[0]), spec[1] as Vector3, spec[2] as Vector3, stone)
		_block("Cellar" + str(spec[0]), spec[1] as Vector3, (spec[2] as Vector3) + down)
	var ceiling := _box(c, "Ceiling", Vector3(w + 1.0, 0.3, d + 1.0), Vector3(cx, 3.15, 0), wood(Color(0.26, 0.18, 0.12), Vector3(1, 0, 0), 0.3))
	ceiling.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.28, 0.25, 0.22)
	_box(c, "Floor", Vector3(w, 0.04, d), Vector3(cx, 0.02, 0), floor_mat)
	_block("CellarFloor", Vector3(w + 1.0, 0.5, d + 1.0), Vector3(cx, -0.25, 0) + down)
	var copper := StandardMaterial3D.new()
	copper.albedo_color = Color(0.72, 0.42, 0.26)
	copper.metallic = 0.7
	copper.roughness = 0.4
	for y: float in [0.55, 1.05]:
		var pipe := MeshInstance3D.new()
		pipe.name = "Pipe%d" % int(y * 100.0)
		var cm := CylinderMesh.new()
		cm.top_radius = 0.09
		cm.bottom_radius = 0.09
		cm.height = CELLAR.size.x
		cm.material = copper
		pipe.mesh = cm
		pipe.rotation_degrees.z = 90.0
		pipe.position = Vector3(cx, y, CELLAR_PIPE_Z)
		c.add_child(pipe)
	# 鐵網：一排細鐵條＋上下兩道橫條（黴泥縮在後面，劍搆不到）
	var iron := StandardMaterial3D.new()
	iron.albedo_color = Color(0.22, 0.22, 0.24)
	iron.metallic = 0.6
	var bars: int = int(CELLAR.size.x / 0.16)
	for i: int in bars:
		_box(c, "Bar%d" % i, Vector3(0.025, 1.5, 0.025), Vector3(CELLAR.position.x + 0.1 + 0.16 * float(i), 0.75, CELLAR_MESH_Z), iron)
	for y: float in [0.06, 1.48]:
		_box(c, "Rail%d" % int(y * 100.0), Vector3(CELLAR.size.x, 0.05, 0.04), Vector3(cx, y, CELLAR_MESH_Z), iron)
	_block("CellarMesh", Vector3(CELLAR.size.x, 1.5, 0.2), Vector3(cx, 0.75, CELLAR_MESH_Z) + down)
	# 備用暖管與閥（東牆邊）
	var spare := MeshInstance3D.new()
	spare.name = "SparePipe"
	var sm := CylinderMesh.new()
	sm.top_radius = 0.07
	sm.bottom_radius = 0.07
	sm.height = 1.8
	sm.material = copper
	spare.mesh = sm
	spare.position = CELLAR_VALVE + Vector3(0.4, 0.9, 0)
	c.add_child(spare)
	var red := StandardMaterial3D.new()
	red.albedo_color = Color(0.7, 0.16, 0.12)
	var wheel := MeshInstance3D.new()
	wheel.name = "ValveWheel"
	var tm := TorusMesh.new()
	tm.inner_radius = 0.1
	tm.outer_radius = 0.16
	tm.material = red
	wheel.mesh = tm
	wheel.rotation_degrees.z = 90.0
	wheel.position = CELLAR_VALVE + Vector3(0.2, 1.1, 0)
	c.add_child(wheel)
	var barrel: Node3D = _prop("quaternius/Barrel", CELLAR_BARREL, 0.0, 1.0, c)
	if barrel != null:
		barrel.name = "CellarBarrel"
	_block("CellarBarrelBlock", Vector3(0.8, 1.0, 0.8), CELLAR_BARREL + Vector3(0, 0.5, 0) + down)
	_prop("quaternius/Crate_Wooden", Vector3(CELLAR.end.x - 0.2, 0, CELLAR.position.y + 2.2), 20.0, 1.0, c)
	_prop("quaternius/Barrel", Vector3(CELLAR.position.x + 0.3, 0, CELLAR.position.y + 0.3), 0.0, 1.0, c)
	# 梯子（往上回麵攤）
	var ladder_wood: ShaderMaterial = wood(Color(0.4, 0.28, 0.18), Vector3(0, 1, 0), 0.2)
	for side: float in [-0.25, 0.25]:
		_box(c, "LadderRail%d" % int(side * 10.0), Vector3(0.06, 3.0, 0.06), CELLAR_LADDER + Vector3(side, 1.5, 0.5), ladder_wood)
	for i: int in 7:
		_box(c, "LadderRung%d" % i, Vector3(0.5, 0.04, 0.05), CELLAR_LADDER + Vector3(0, 0.35 + 0.4 * float(i), 0.5), ladder_wood)
	var hatch := OmniLight3D.new()
	hatch.name = "HatchLight"
	hatch.light_color = Color(0.9, 0.92, 1.0)
	hatch.light_energy = 1.6
	hatch.omni_range = 4.5
	hatch.position = CELLAR_LADDER + Vector3(0, 2.8, 0.5)
	c.add_child(hatch)
