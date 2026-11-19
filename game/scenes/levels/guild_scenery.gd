class_name GuildScenery
extends RefCounted
## 奧爾德冒險者公會的大廳看得到的東西（docs/story/chapter-1.md 節點 1 與章節結尾）。第一個室內場景。
## 南邊是大門、北邊是櫃檯，櫃檯上面是二樓的迴廊（結尾王都巡察官站在那裡），東西兩面牆各三扇窗。
## 只是場景；規則與劇情在 GuildHall。
## - 牆、天花板、門、窗都是「只有朝屋裡那一面」的面（背面不畫）：過肩鏡頭退到牆外的時候看得進來，不用把鏡頭往諾恩背上推。
##   所以牆沒有鏡頭會撞到的碰撞（第 1 層只有地板）；擋人的東西（牆、櫃檯那一排、桌子、柱子、站著的人）都放在 PEOPLE_LAYER，
##   關卡讓諾恩與席菈多撞這一層。
## - 櫃檯、水晶、佈告欄、招牌是 Tripo 的模型；桌椅、木桶、吊燈、書櫃是 Quaternius 的 CC0 小物（scripts/gen_props.sh 複製進來）；
##   牆、地板、樑、迴廊、樓梯是程式拼的（guild_wall／guild_wood／guild_window 三個 shader）。模型檔不在的就不擺（櫃檯與水晶有替身）。
## - 光：早上太陽從東邊的窗照進來（WindowLight：一道一道的光柱＋地上一格一格的窗影），結尾是傍晚，改成西邊的窗照進橘紅的光、
##   光柱低低地拉長，吊燈比較亮（evening）。吊燈的蠟燭、北牆的壁燈有火苗（CandleFlame，壁燈的會閃）。

const HALF_W: float = 8.0
const HALF_L: float = 11.0
const HEIGHT: float = 6.4
## 只擋人、不擋鏡頭的碰撞層（第 3 層）
const PEOPLE_LAYER: int = 4
## 諾恩走得到的範圍離牆這麼遠（牆的碰撞之外再保險一次：用開發旗標放到牆外也會被拉回來）
const WALL_MARGIN: float = 0.45
## 大門（南牆中間）與走出去的那條線
const DOOR_POS: Vector3 = Vector3(0, 0, HALF_L)
const DOOR_SIZE: Vector2 = Vector2(2.6, 3.3)
## 門開到底轉幾度（往屋裡開）
const DOOR_SWING_DEG: float = 78.0
## 門外那條街：街對面的房子離南牆多遠、石板路多寬（沿著街）
const STREET_DEPTH: float = 7.0
const STREET_HALF_W: float = 14.0
## 櫃檯那一排：中間是櫃檯，兩邊各兩個矮櫃接成一條長吧台；這條線以北是櫃檯裡面（上面是二樓的迴廊），客人進不去
const COUNTER_POS: Vector3 = Vector3(0, 0, -8.0)
const COUNTER_STRETCH: float = 1.45
const STAFF_LINE_Z: float = -7.35
## 適性測試水晶：放在櫃檯右邊第一個矮櫃上、靠外側的邊（站在櫃檯前伸手摸得到）
const CRYSTAL_POS: Vector3 = Vector3(2.0, 1.0, -7.8)
## 莉莉絲擱到櫃檯上的那張綠色委託單：上緣（標題那一邊）在這裡、朝大門那邊攤開——她手放下來的地方
const SLIP_ON_COUNTER: Vector3 = Vector3(-0.07, 1.168, -8.31)
const SLIP_ON_COUNTER_YAW: float = 172.0
const BOARD_POS: Vector3 = Vector3(-7.5, 0, 0.0)
## 西北角武器架旁邊的凳子（開場席菈縮著坐在上面）與它的高度
const STOOL_POS: Vector3 = Vector3(-6.3, 0, -6.4)
const STOOL_TOP: float = 0.58
## 公會的招牌（戶外的立牌）：立在門外右手邊（從屋裡往外看），門開了看得到
const SIGN_POS: Vector3 = Vector3(1.75, 0, HALF_L + 2.3)
## 二樓的迴廊：地板的高度、前緣（欄杆）在哪
const LOFT_Y: float = 3.5
const LOFT_EDGE_Z: float = -7.4
## 窗：東西兩面牆各三扇（z）、窗台高、寬與高
const WINDOW_Z: Array[float] = [-2.5, 2.5, 7.5]
const WINDOW_SILL: float = 1.75
const WINDOW_SIZE: Vector2 = Vector2(1.9, 2.7)
## 桌子（x、z；長邊順著 Z，兩邊各一條長凳）
const TABLES: Array[Vector2] = [Vector2(-4.4, 5.2), Vector2(-4.4, -3.3), Vector2(4.4, 5.6), Vector2(4.2, 0.9)]
const CHANDELIER_Z: Array[float] = [4.0, -2.6]
## 吊燈（Quaternius 的 Chandelier，量模型量出來的）：八根蠟燭在半徑 0.578 的圈上每 45° 一根，蠟燭頂的高度（模型座標）
const CANDLE_RADIUS: float = 0.578
const CANDLE_TOPS: Array[float] = [-0.908, -0.969, -0.943, -0.908, -0.908, -0.969, -0.943, -0.908]
## 壁燈（Lantern_Wall）的燈籠裡面、火苗的底（模型座標：燈籠的籠子在 y 0.08～0.61、離牆 0.81 m）
const LANTERN_FLAME: Vector3 = Vector3(0, 0.22, 0.81)
## 燈籠是實心的：火苗往鏡頭拉近這麼多才不會被擋住
const LANTERN_PULL: float = 0.22
## 太陽往哪裡照：早上從東邊的窗斜斜往下（約 38°），傍晚從西邊的窗低低地照進來（約 22°，光柱拉得很長、橫過紅地毯）
const SUN_DIR_MORNING: Vector3 = Vector3(-1.0, -0.8, 0.18)
const SUN_DIR_EVENING: Vector3 = Vector3(1.0, -0.42, 0.25)
## 光柱（每一片面片）與地上窗影的亮度
const SHAFT_ENERGY: float = 0.05
const SHAFT_ENERGY_EVENING: float = 0.06
const PATCH_ENERGY: float = 0.3
const PATCH_ENERGY_EVENING: float = 0.36
const COUNTER_MODEL: String = "tripo/prop_guild_counter_v2"
const CRYSTAL_MODEL: String = "tripo/prop_aptitude_crystal"
const BOARD_MODEL: String = "tripo/prop_guild_quest_board"
const SIGN_MODEL: String = "tripo/prop_guild_signboard"
const STREET_SHADER: Shader = preload("res://src/world/guild_street.gdshader")
const WOOD_SHADER: Shader = preload("res://src/world/guild_wood.gdshader")
const WALL_SHADER: Shader = preload("res://src/world/guild_wall.gdshader")
const WINDOW_SHADER: Shader = preload("res://src/world/guild_window.gdshader")
const CRYSTAL_GLOW_SHADER: Shader = preload("res://src/world/crystal_glow.gdshader")
const CRYSTAL_TINT_SHADER: Shader = preload("res://src/world/crystal_tint.gdshader")
## 地板：偏灰的中間棕（以前 0.46/0.3/0.18 在暖色的燈底下整片偏橘）
const FLOOR_WOOD: Color = Color(0.4, 0.29, 0.2)
const DARK_WOOD: Color = Color(0.24, 0.15, 0.09)
const BEAM_WOOD: Color = Color(0.3, 0.19, 0.11)
## 水晶的三種樣子：平常（藍）、警報（紅，一閃一閃）、測完之後（暗掉）。發光那一層只給純的顏色（綠、藍幾乎是 0），
## 才不會亮過頭被色調映射沖成粉白；模型本身乘上 *_TINT（警報時整顆染紅、測完是灰的）
const CRYSTAL_CALM: Color = Color(0.3, 0.68, 1.0)
const CRYSTAL_ALARM: Color = Color(1.0, 0.04, 0.02)
const CRYSTAL_DEAD: Color = Color(0.3, 0.3, 0.38)
const CRYSTAL_CALM_TINT: Color = Color(0.92, 1.0, 1.08)
const CRYSTAL_ALARM_TINT: Color = Color(1.25, 0.16, 0.12)
const CRYSTAL_DEAD_TINT: Color = Color(0.5, 0.5, 0.56)

var evening: bool = false
var crystal: Node3D
var crystal_light: OmniLight3D
var windows: Array[MeshInstance3D] = []
## 受光的那一側每扇窗一個（光柱＋地上的窗影）
var window_lights: Array[WindowLight] = []
## 有帶燈的火苗（北牆的壁燈）
var flames: Array[CandleFlame] = []
## 大門的兩片門板（門軸；set_door_open 轉它們）
var door_hinges: Array[Node3D] = []
## 門開了多少（0～1）
var door_open: float = 0.0
## 莉莉絲拿出來的那張綠色委託單（放在櫃檯上；關卡在她拿出來的時候才讓它出現）
var slip: Node3D
var _root: Node3D
var _crystal_glow: ShaderMaterial
var _crystal_tint: ShaderMaterial


## 把大廳蓋進 level。p_evening＝傍晚（章節結尾）。
static func build(level: Node3D, p_evening: bool) -> GuildScenery:
	var s := GuildScenery.new()
	s.evening = p_evening
	s._root = Node3D.new()
	s._root.name = "Hall"
	level.add_child(s._root)
	s._build_environment(level)
	s._build_shell()
	s._build_street()
	s._build_loft()
	s._build_counter()
	s._build_furniture()
	s._build_lights()
	return s


## 走到牆外就拉回來（櫃檯裡面也進不去）
static func keep_inside(p: Vector3) -> Vector3:
	return Vector3(clampf(p.x, -HALF_W + WALL_MARGIN, HALF_W - WALL_MARGIN), p.y,
		clampf(p.z, STAFF_LINE_Z + WALL_MARGIN, HALF_L - WALL_MARGIN))


## 水晶現在的樣子：alarm 0～1（紅的警報有多強，關卡讓它一閃一閃）；dead＝測完暗掉了
func set_crystal(alarm: float, dead: bool) -> void:
	var a: float = clampf(alarm, 0.0, 1.0)
	# 顏色一響就是紅的（一閃一閃只閃亮度）：以前藍與紅照 alarm 內插，閃到一半是紫的、看起來是粉紅
	var hue: float = smoothstep(0.0, 0.3, a)
	var c: Color = CRYSTAL_DEAD if dead else CRYSTAL_CALM.lerp(CRYSTAL_ALARM, hue)
	_crystal_glow.set_shader_parameter("color", c)
	_crystal_glow.set_shader_parameter("energy", 0.3 if dead else 0.9 + 1.1 * a)
	_crystal_tint.set_shader_parameter("tint", CRYSTAL_DEAD_TINT if dead else CRYSTAL_CALM_TINT.lerp(CRYSTAL_ALARM_TINT, hue))
	crystal_light.light_color = c
	crystal_light.light_energy = 0.15 if dead else 1.2 + 4.0 * alarm


## 大門開到 amount（0＝關著、1＝全開）：兩片門板往屋裡轉
func set_door_open(amount: float) -> void:
	door_open = clampf(amount, 0.0, 1.0)
	for i: int in door_hinges.size():
		var side: float = -1.0 if i == 0 else 1.0
		door_hinges[i].rotation.y = deg_to_rad(DOOR_SWING_DEG) * door_open * -side


static func wood(tint: Color, along: Vector3, plank: float = 0.26, wear: float = 0.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = WOOD_SHADER
	m.set_shader_parameter("tint", tint)
	m.set_shader_parameter("along", along)
	m.set_shader_parameter("plank", plank)
	m.set_shader_parameter("wear", wear)
	return m


## 室內：背景是暗的（牆外什麼都沒有），暖色的環境光；一點點體積霧讓窗的光變成光柱（畫質低時 QualityPreset 換成深度霧）。
func _build_environment(level: Node3D) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.022, 0.018)
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.47, 0.48) if evening else Color(0.63, 0.6, 0.57)
	env.ambient_light_energy = 0.62 if evening else 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.014
	env.volumetric_fog_albedo = Color(0.95, 0.8, 0.62)
	env.volumetric_fog_emission = Color(0.0, 0.0, 0.0)
	env.volumetric_fog_length = 40.0
	env.glow_enabled = true
	env.glow_intensity = 0.55
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	level.add_child(we)


func _quad(node_name: String, size: Vector2, at: Vector3, rot_deg: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var q := QuadMesh.new()
	q.size = size
	q.material = mat
	mi.mesh = q
	mi.position = at
	mi.rotation_degrees = rot_deg
	_root.add_child(mi)
	return mi


func _box(parent: Node3D, size: Vector3, at: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	b.material = mat
	mi.mesh = b
	mi.position = at
	parent.add_child(mi)
	return mi


## 只擋人的一塊碰撞（PEOPLE_LAYER）
func _block(node_name: String, size: Vector3, at: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.collision_layer = PEOPLE_LAYER
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.position = at
	_root.add_child(body)
	return body


## 地板、四面牆、天花板與樑、大門、窗
func _build_shell() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(60.0, 1.0, 60.0)
	shape.shape = box
	shape.position = Vector3(0, -0.5, 0)
	floor_body.add_child(shape)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(HALF_W * 2.0, HALF_L * 2.0)
	plane.material = wood(FLOOR_WOOD, Vector3(0, 0, 1), 0.3, 1.0)
	floor_mesh.mesh = plane
	floor_body.add_child(floor_mesh)
	_root.add_child(floor_body)
	# 從大門到櫃檯的一條紅地毯（兩邊各一道金線）
	var carpet := StandardMaterial3D.new()
	carpet.albedo_color = Color(0.5, 0.09, 0.1)
	carpet.roughness = 1.0
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(0.8, 0.62, 0.25)
	gold.roughness = 0.8
	var run_len: float = HALF_L - 0.3 - (STAFF_LINE_Z + 0.5)
	var run_mid: float = (HALF_L - 0.3 + STAFF_LINE_Z + 0.5) * 0.5
	_quad("Carpet", Vector2(2.4, run_len), Vector3(0, 0.012, run_mid), Vector3(-90, 0, 0), carpet)
	for side: float in [-1.0, 1.0]:
		_quad("CarpetTrim", Vector2(0.1, run_len), Vector3(side * 1.0, 0.016, run_mid), Vector3(-90, 0, 0), gold)
	# 牆：朝屋裡的四片
	var wall_ew := ShaderMaterial.new()
	wall_ew.shader = WALL_SHADER
	wall_ew.set_shader_parameter("height", HEIGHT)
	var wall_ns: ShaderMaterial = wall_ew.duplicate() as ShaderMaterial
	wall_ns.set_shader_parameter("shift", 2.5)
	_quad("WallEast", Vector2(HALF_L * 2.0, HEIGHT), Vector3(HALF_W, HEIGHT * 0.5, 0), Vector3(0, -90, 0), wall_ew)
	_quad("WallWest", Vector2(HALF_L * 2.0, HEIGHT), Vector3(-HALF_W, HEIGHT * 0.5, 0), Vector3(0, 90, 0), wall_ew)
	_quad("WallNorth", Vector2(HALF_W * 2.0, HEIGHT), Vector3(0, HEIGHT * 0.5, -HALF_L), Vector3(0, 0, 0), wall_ns)
	# 南牆在大門的地方開一個洞（左、右、門上三片；shader 照世界座標畫，接起來看不出縫）——門開了看得到外面的街
	var door_half: float = DOOR_SIZE.x * 0.5
	var side_w: float = HALF_W - door_half
	_quad("WallSouth", Vector2(side_w, HEIGHT), Vector3(-door_half - side_w * 0.5, HEIGHT * 0.5, HALF_L), Vector3(0, 180, 0), wall_ns)
	_quad("WallSouthR", Vector2(side_w, HEIGHT), Vector3(door_half + side_w * 0.5, HEIGHT * 0.5, HALF_L), Vector3(0, 180, 0), wall_ns)
	_quad("WallSouthTop", Vector2(DOOR_SIZE.x, HEIGHT - DOOR_SIZE.y), Vector3(0, (HEIGHT + DOOR_SIZE.y) * 0.5, HALF_L), Vector3(0, 180, 0), wall_ns)
	_block("WallEastBlock", Vector3(1.0, HEIGHT, HALF_L * 2.0 + 2.0), Vector3(HALF_W + 0.5, HEIGHT * 0.5, 0))
	_block("WallWestBlock", Vector3(1.0, HEIGHT, HALF_L * 2.0 + 2.0), Vector3(-HALF_W - 0.5, HEIGHT * 0.5, 0))
	_block("WallNorthBlock", Vector3(HALF_W * 2.0 + 2.0, HEIGHT, 1.0), Vector3(0, HEIGHT * 0.5, -HALF_L - 0.5))
	_block("WallSouthBlock", Vector3(HALF_W * 2.0 + 2.0, HEIGHT, 1.0), Vector3(0, HEIGHT * 0.5, HALF_L + 0.5))
	# 天花板（朝下的一片）與橫樑
	_quad("Ceiling", Vector2(HALF_W * 2.0, HALF_L * 2.0), Vector3(0, HEIGHT, 0), Vector3(90, 0, 0), wood(DARK_WOOD, Vector3(1, 0, 0), 0.34))
	var beams := Node3D.new()
	beams.name = "Beams"
	_root.add_child(beams)
	var beam_mat: ShaderMaterial = wood(BEAM_WOOD, Vector3(1, 0, 0), 0.4)
	for z: float in [-10.0, -5.0, 0.0, 5.0, 10.0]:
		_box(beams, Vector3(HALF_W * 2.0, 0.42, 0.36), Vector3(0, HEIGHT - 0.21, z), beam_mat)
	_box(beams, Vector3(0.4, 0.3, HALF_L * 2.0), Vector3(0, HEIGHT - 0.57, 0), wood(BEAM_WOOD, Vector3(0, 0, 1), 0.4))
	# 大門：門框（兩邊的門柱與門楣）＋兩片會往裡面開的門板（set_door_open）；門外是 _build_street 的街
	var door := Node3D.new()
	door.name = "Door"
	_root.add_child(door)
	var frame_mat: ShaderMaterial = wood(DARK_WOOD * 0.7, Vector3(0, 1, 0), 0.5)
	for side: float in [-1.0, 1.0]:
		_quad("DoorJamb", Vector2(0.25, DOOR_SIZE.y + 0.25), DOOR_POS + Vector3(side * (door_half + 0.125), (DOOR_SIZE.y + 0.25) * 0.5, -0.02), Vector3(0, 180, 0), frame_mat).reparent(door)
	_quad("DoorLintel", Vector2(DOOR_SIZE.x, 0.25), DOOR_POS + Vector3(0, DOOR_SIZE.y + 0.125, -0.02), Vector3(0, 180, 0), frame_mat).reparent(door)
	var leaf_mat: ShaderMaterial = wood(Color(0.4, 0.24, 0.13), Vector3(0, 1, 0), 0.32)
	var iron := StandardMaterial3D.new()
	iron.albedo_color = Color(0.13, 0.12, 0.13)
	iron.metallic = 0.6
	iron.roughness = 0.5
	var half: float = door_half
	for side: float in [-1.0, 1.0]:
		# 門軸在兩邊的門框上，門板往中間伸
		var hinge := Node3D.new()
		hinge.name = "DoorHingeL" if side < 0.0 else "DoorHingeR"
		hinge.position = DOOR_POS + Vector3(side * half, 0, -0.07)
		door.add_child(hinge)
		door_hinges.append(hinge)
		_quad("DoorLeaf", Vector2(half, DOOR_SIZE.y), Vector3(-side * half * 0.5, DOOR_SIZE.y * 0.5, 0), Vector3(0, 180, 0), leaf_mat).reparent(hinge, false)
		for y: float in [0.55, 2.6]:
			_quad("DoorBand", Vector2(half, 0.14), Vector3(-side * half * 0.5, y, -0.02), Vector3(0, 180, 0), iron).reparent(hinge, false)
		_quad("DoorEdge", Vector2(0.05, DOOR_SIZE.y), Vector3(-side * (half - 0.025), DOOR_SIZE.y * 0.5, -0.02), Vector3(0, 180, 0), iron).reparent(hinge, false)
	# 窗：受光的那一側亮（早上東邊、傍晚西邊），另一側是背光的天色
	for side: float in [-1.0, 1.0]:
		var lit: bool = (side > 0.0) != evening
		for z: float in WINDOW_Z:
			var mat := ShaderMaterial.new()
			mat.shader = WINDOW_SHADER
			mat.set_shader_parameter("light", _sun_color() if lit else _shade_color())
			mat.set_shader_parameter("energy", 2.6 if lit else 0.9)
			mat.set_shader_parameter("seed", float(windows.size()) * 1.37 + side)
			mat.set_shader_parameter("house_glow", 0.09 if lit else 0.42)
			var w: MeshInstance3D = _quad("Window", WINDOW_SIZE, Vector3(side * (HALF_W - 0.03), WINDOW_SILL + WINDOW_SIZE.y * 0.5, z), Vector3(0, -90.0 * side, 0), mat)
			windows.append(w)


## 門外那條街：石板路、街對面的房子與天（guild_street.gdshader，不受光、照白天的顏色亮）、門邊的招牌與一盞照著它的燈。
## 只從門洞看得到（牆的背面不畫，鏡頭退到牆外的時候也只是看到地面）；擋人的碰撞照舊是整面南牆。
func _build_street() -> void:
	var street := Node3D.new()
	street.name = "Street"
	_root.add_child(street)
	var day: Color = Color(0.95, 0.66, 0.46) if evening else Color(0.9, 0.86, 0.78)
	var ground := ShaderMaterial.new()
	ground.shader = STREET_SHADER
	ground.set_shader_parameter("part", 0)
	ground.set_shader_parameter("daylight", day * (0.85 if evening else 1.0))
	_quad("StreetGround", Vector2(STREET_HALF_W * 2.0, STREET_DEPTH), Vector3(0, 0.0, HALF_L + STREET_DEPTH * 0.5), Vector3(-90, 0, 0), ground).reparent(street)
	var front := ShaderMaterial.new()
	front.shader = STREET_SHADER
	front.set_shader_parameter("part", 1)
	front.set_shader_parameter("daylight", day)
	if evening:
		front.set_shader_parameter("sky_top", Color(0.45, 0.42, 0.7))
		front.set_shader_parameter("sky_low", Color(1.0, 0.7, 0.45))
	_quad("StreetHouses", Vector2(STREET_HALF_W * 2.0, 14.0), Vector3(0, 7.0, HALF_L + STREET_DEPTH), Vector3(0, 180, 0), front).reparent(street)
	var sign_post: Node3D = _prop(SIGN_MODEL, SIGN_POS, -90.0)
	if sign_post != null:
		sign_post.name = "Signboard"
		sign_post.reparent(street)
	var sun := OmniLight3D.new()
	sun.name = "StreetLight"
	sun.light_color = day
	sun.light_energy = 2.2
	sun.omni_range = 6.0
	sun.shadow_enabled = false
	sun.position = Vector3(0.8, 3.0, HALF_L + 2.6)
	street.add_child(sun)


func _sun_color() -> Color:
	return Color(1.0, 0.5, 0.22) if evening else Color(1.0, 0.9, 0.68)


func _shade_color() -> Color:
	return Color(0.34, 0.3, 0.55) if evening else Color(0.6, 0.74, 0.95)


## 二樓的迴廊（櫃檯上面那一段）：樓板、欄杆、撐著它的柱子，東牆邊一道上去的樓梯（上不去：整道樓梯是一塊擋人的碰撞）
func _build_loft() -> void:
	var loft := Node3D.new()
	loft.name = "Loft"
	_root.add_child(loft)
	var plank_x: ShaderMaterial = wood(BEAM_WOOD, Vector3(1, 0, 0), 0.3)
	var depth: float = LOFT_EDGE_Z + HALF_L
	_box(loft, Vector3(HALF_W * 2.0, 0.22, depth), Vector3(0, LOFT_Y - 0.11, -HALF_L + depth * 0.5), plank_x)
	# 樓板前緣的橫樑、欄杆的扶手與一根一根的欄杆
	_box(loft, Vector3(HALF_W * 2.0, 0.34, 0.24), Vector3(0, LOFT_Y - 0.17, LOFT_EDGE_Z), wood(DARK_WOOD, Vector3(1, 0, 0), 0.4))
	_box(loft, Vector3(HALF_W * 2.0, 0.09, 0.14), Vector3(0, LOFT_Y + 1.0, LOFT_EDGE_Z), wood(DARK_WOOD, Vector3(1, 0, 0), 0.4))
	var baluster_mat: ShaderMaterial = wood(BEAM_WOOD, Vector3(0, 1, 0), 0.2)
	var x: float = -HALF_W + 0.25
	while x < HALF_W:
		_box(loft, Vector3(0.07, 1.0, 0.07), Vector3(x, LOFT_Y + 0.5, LOFT_EDGE_Z), baluster_mat)
		x += 0.5
	var post_mat: ShaderMaterial = wood(DARK_WOOD, Vector3(0, 1, 0), 0.3)
	for px: float in [-7.75, -4.6, 4.6, 7.75]:
		_box(loft, Vector3(0.3, LOFT_Y - 0.2, 0.3), Vector3(px, (LOFT_Y - 0.2) * 0.5, LOFT_EDGE_Z), post_mat)
	# 二樓靠牆的地方很暗：一扇關著的門，看得出上面還有房間
	_quad("LoftDoor", Vector2(1.2, 2.2), Vector3(-3.2, LOFT_Y + 1.1, -HALF_L + 0.03), Vector3.ZERO, wood(DARK_WOOD * 0.8, Vector3(0, 1, 0), 0.3)).reparent(loft)
	# 樓梯：東牆邊，從 z=-2.2 往北走上去
	var steps: int = 14
	var run: float = (LOFT_EDGE_Z + 2.2) / float(steps)
	var rise: float = LOFT_Y / float(steps)
	var stair_mat: ShaderMaterial = wood(BEAM_WOOD, Vector3(1, 0, 0), 0.3)
	for i: int in steps:
		var h: float = rise * float(i + 1)
		_box(loft, Vector3(1.4, h, absf(run)), Vector3(HALF_W - 0.75, h * 0.5, -2.2 + run * (float(i) + 0.5)), stair_mat)
	_block("StairBlock", Vector3(1.5, LOFT_Y, absf(LOFT_EDGE_Z + 2.2)), Vector3(HALF_W - 0.75, LOFT_Y * 0.5, (LOFT_EDGE_Z - 2.2) * 0.5))


func _prop(model: String, at: Vector3, yaw_deg: float = 0.0, size: float = 1.0) -> Node3D:
	var n: Node3D = PropModels.instance(model)
	if n == null:
		return null
	n.position = at
	n.rotation_degrees.y = yaw_deg
	n.scale = Vector3.ONE * size
	_root.add_child(n)
	return n


## 櫃檯那一排、水晶、櫃檯後面的架子
func _build_counter() -> void:
	# 模型長 1.78 m、長邊順著它自己的 Z：轉 90 度橫在走道前面，長邊拉長到剛好接上兩邊的矮櫃
	var counter: Node3D = _prop(COUNTER_MODEL, COUNTER_POS, 90.0)
	if counter != null:
		counter.scale = Vector3(1.0, 1.0, COUNTER_STRETCH)
	else:
		# 模型檔不在：一張木頭長桌
		counter = _box(_root, Vector3(2.6, 1.15, 0.9), COUNTER_POS + Vector3(0, 0.575, 0), wood(FLOOR_WOOD, Vector3(1, 0, 0)))
	counter.name = "Counter"
	for side: float in [-1.0, 1.0]:
		for k: int in 2:
			var at := Vector3(side * (2.0 + 1.38 * float(k)), 0, COUNTER_POS.z)
			if _prop("quaternius/Cabinet", at, 0.0) == null:
				_box(_root, Vector3(1.36, 1.0, 0.5), at + Vector3(0, 0.5, 0), wood(FLOOR_WOOD, Vector3(1, 0, 0)))
	# 這條線以北進不去（整排一塊碰撞，連到兩邊的牆）
	_block("StaffLine", Vector3(HALF_W * 2.0, 2.2, 1.0), Vector3(0, 1.1, STAFF_LINE_Z - 0.5))
	# 水晶：模型外面包一個節點（關卡的目標指引、互動都對著它）；發光的那一層另外蓋一顆球，警報時換顏色
	crystal = Node3D.new()
	crystal.name = "CrystalLook"
	crystal.position = CRYSTAL_POS
	_root.add_child(crystal)
	var look: Node3D = PropModels.instance(CRYSTAL_MODEL)
	_crystal_tint = ShaderMaterial.new()
	_crystal_tint.shader = CRYSTAL_TINT_SHADER
	if look != null:
		crystal.add_child(look)
		for g: Node in look.find_children("*", "GeometryInstance3D", true, false):
			(g as GeometryInstance3D).material_overlay = _crystal_tint
	_crystal_glow = ShaderMaterial.new()
	_crystal_glow.shader = CRYSTAL_GLOW_SHADER
	var orb := MeshInstance3D.new()
	orb.name = "Glow"
	var ball := SphereMesh.new()
	ball.radius = 0.2 if look != null else 0.24
	ball.height = ball.radius * 2.0
	ball.material = _crystal_glow
	orb.mesh = ball
	orb.position = Vector3(0, 0.36, 0)
	orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	crystal.add_child(orb)
	crystal_light = OmniLight3D.new()
	crystal_light.name = "CrystalLight"
	crystal_light.omni_range = 4.5
	crystal_light.shadow_enabled = false
	crystal_light.position = Vector3(0, 0.5, 0.3)
	crystal.add_child(crystal_light)
	set_crystal(0.0, false)
	# 櫃檯後面靠牆：書櫃、木桶；牆上兩盞燈
	for bx: float in [-5.6, -2.2, 2.2, 5.6]:
		_prop("quaternius/Bookcase_2", Vector3(bx, 0, -HALF_L + 0.32), 0.0)
	_prop("quaternius/Barrel", Vector3(-7.2, 0, -10.2))
	_prop("quaternius/Barrel", Vector3(-6.4, 0, -10.3))
	_prop("quaternius/Crate_Wooden", Vector3(7.1, 0.06, -10.1), 12.0)
	var lamp_i: int = 0
	for lx: float in [-3.9, 0.0, 3.9]:
		_add_flames(_prop("quaternius/Lantern_Wall", Vector3(lx, 1.55, -HALF_L + 0.02)), false, lamp_i)
		lamp_i += 1
	# 綠色委託單：攤開、平放在櫃檯上（莉莉絲拿出來之後才出現；她手上那一張也是 QuestSlip）
	slip = QuestSlip.create(0.0, 1.0)
	slip.position = SLIP_ON_COUNTER
	slip.rotation_degrees = Vector3(0, SLIP_ON_COUNTER_YAW, 0)
	slip.visible = false
	_root.add_child(slip)
	_prop("quaternius/Book_Stack_1", COUNTER_POS + Vector3(-1.7, 1.0, 0.05), 20.0)
	_prop("quaternius/Bottle_1", COUNTER_POS + Vector3(3.3, 1.0, 0.0))
	_prop("quaternius/Bottle_1", COUNTER_POS + Vector3(3.5, 1.0, 0.08))


## 佈告欄、招牌、桌椅、木桶、武器架、旗子、吊燈
func _build_furniture() -> void:
	var board: Node3D = _prop(BOARD_MODEL, BOARD_POS, -90.0)
	if board != null:
		board.name = "QuestBoard"
	_block("BoardBlock", Vector3(0.9, 2.3, 1.8), BOARD_POS + Vector3(0, 1.15, 0))
	for i: int in TABLES.size():
		var t: Vector2 = TABLES[i]
		var at := Vector3(t.x, 0, t.y)
		if _prop("quaternius/Table_Large", at, 90.0) == null:
			_box(_root, Vector3(1.1, 0.8, 2.85), at + Vector3(0, 0.4, 0), wood(FLOOR_WOOD, Vector3(0, 0, 1)))
		for side: float in [-1.0, 1.0]:
			_prop("quaternius/Bench", at + Vector3(side * 0.92, 0, 0), 90.0)
		_block("TableBlock%d" % i, Vector3(2.5, 1.0, 2.95), at + Vector3(0, 0.5, 0))
		# 桌上的杯盤（每張桌子擺得不一樣）
		_prop("quaternius/Mug", at + Vector3(0.2, 0.81, -0.7 + 0.5 * float(i % 2)), 40.0 * float(i))
		_prop("quaternius/Mug", at + Vector3(-0.22, 0.81, 0.4 - 0.3 * float(i % 3)), 130.0)
		_prop("quaternius/Table_Plate", at + Vector3(0.05, 0.81, 0.95 - 0.4 * float(i % 2)))
	# 門邊與角落
	_prop("quaternius/Barrel", Vector3(-7.2, 0, 10.1))
	_prop("quaternius/Barrel", Vector3(-6.35, 0, 10.25))
	_prop("quaternius/Crate_Wooden", Vector3(-7.15, 0.06, 9.0), 8.0)
	_block("CornerBlockSW", Vector3(1.9, 1.2, 2.2), Vector3(-6.9, 0.6, 9.7))
	_prop("quaternius/Crate_Wooden", Vector3(7.1, 0.06, 9.9), -10.0)
	_prop("quaternius/Barrel", Vector3(6.2, 0, 10.2))
	_block("CornerBlockSE", Vector3(1.9, 1.2, 1.6), Vector3(6.8, 0.6, 10.0))
	_prop("quaternius/WeaponStand", Vector3(-7.25, 0, -5.0), 90.0)
	_block("StandBlock", Vector3(1.1, 1.2, 1.5), Vector3(-7.3, 0.6, -5.0))
	_prop("quaternius/Stool", STOOL_POS, 20.0)
	_prop("quaternius/Shield_Wooden", Vector3(-HALF_W + 0.02, 2.5, 5.0), 90.0, 1.4)
	_prop("quaternius/Shield_Wooden", Vector3(HALF_W - 0.02, 2.5, 5.0), -90.0, 1.4)
	# 門兩邊的旗子（桿子從牆上伸進屋裡）
	for side: float in [-1.0, 1.0]:
		_prop("quaternius/Banner_1", Vector3(side * 4.4, 4.9, HALF_L - 0.05), 90.0)
	var ci: int = 0
	for z: float in CHANDELIER_Z:
		_add_flames(_prop("quaternius/Chandelier", Vector3(0, HEIGHT - 0.75, z), 0.0, 1.7), true, ci)
		ci += 1


func _light(node_name: String, at: Vector3, color: Color, energy: float, reach: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.name = node_name
	l.light_color = color
	l.light_energy = energy
	l.omni_range = reach
	l.shadow_enabled = false
	l.position = at
	_root.add_child(l)
	return l


## 窗照進來的光（受光的那一側每扇窗一道光柱＋地上的窗影，WindowLight）、吊燈、壁燈（火苗＋會閃的小燈）、櫃檯的燈
func _build_lights() -> void:
	var side: float = -1.0 if evening else 1.0
	var dir: Vector3 = SUN_DIR_EVENING if evening else SUN_DIR_MORNING
	for z: float in WINDOW_Z:
		var center := Vector3(side * (HALF_W - 0.03), WINDOW_SILL + WINDOW_SIZE.y * 0.5, z)
		var wl: WindowLight = WindowLight.create(center, Vector3(-side, 0, 0), WINDOW_SIZE, dir, _sun_color(),
			SHAFT_ENERGY_EVENING if evening else SHAFT_ENERGY, PATCH_ENERGY_EVENING if evening else PATCH_ENERGY)
		_root.add_child(wl)
		window_lights.append(wl)
	var warm := Color(1.0, 0.7, 0.4)
	for z: float in CHANDELIER_Z:
		_light("ChandelierLight", Vector3(0, HEIGHT - 2.6, z), warm, 2.7 if evening else 1.5, 10.0)
	# 櫃檯上面一盞：莉莉絲的臉要看得清楚（她站在迴廊底下）
	_light("CounterFill", Vector3(0, 2.7, COUNTER_POS.z + 0.2), Color(1.0, 0.82, 0.6), 1.5, 5.5)
	# 二樓：傍晚的那一段巡察官站在這裡——只有一點冷色的光，看得出輪廓
	_light("LoftGloom", Vector3(0.6, LOFT_Y + 2.2, LOFT_EDGE_Z + 0.6), Color(0.55, 0.6, 0.9), 0.7 if evening else 0.25, 5.0)


## 吊燈的八根蠟燭與北牆的壁燈各一朵火苗；壁燈的火帶一盞會閃的小燈（櫃檯後面那一片牆是暖的）
func _add_flames(lamp: Node3D, is_chandelier: bool, index: int) -> void:
	if lamp == null:
		return
	if is_chandelier:
		for k: int in CANDLE_TOPS.size():
			var a: float = deg_to_rad(45.0 * float(k))
			var f: CandleFlame = CandleFlame.create(Vector2(0.045, 0.085), float(index * 8 + k) * 0.37, 0.12)
			f.position = Vector3(CANDLE_RADIUS * cos(a), CANDLE_TOPS[k], CANDLE_RADIUS * sin(a))
			lamp.add_child(f)
		return
	var lf: CandleFlame = CandleFlame.create(Vector2(0.13, 0.24), float(index) * 1.9 + 0.4, 0.45, LANTERN_PULL, 1.4 if evening else 1.1, 4.5)
	lf.position = LANTERN_FLAME
	lamp.add_child(lf)
	flames.append(lf)
