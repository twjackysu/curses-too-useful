class_name RailSite
extends Node3D
## 森林裡的斷軌（docs/story/chapter-1-expanded.md「自由時段 B｜森林裡那台沒煞車的車」；第一章 ⑥）看得到的東西：
## 阿展坐的木軌盡頭、斷口、往東爬上去的棧橋、卡在棧橋上的手推車、坡頂的絞盤與纏著它的三股藤、掛在桅杆上的繩、
## 棧橋北邊的枯木與泥灘。規則在 RailRescue（純邏輯）與 RailEvent（劇情）。
## 軌道沿著 x 軸（往東＝+x 是上坡），z 固定在 TRACK_Z。森林的地面沒有高度（碰撞是平的）：棧橋底下是一道牆、人上不去，
## 要站到車頭旁邊由 RailEvent 把諾恩擺上去（PlayerController.stand_at）。全部是程式拼的（木頭、鐵、繩），小東西用 Quaternius 的 CC0。

const TRACK_Z: float = -43.0
## 地面上的主軌、斷口、棧橋各從哪裡到哪裡（x）
const STUB_X: Vector2 = Vector2(43.0, 50.0)
const GAP_X: Vector2 = Vector2(50.0, 52.0)
const TRESTLE_X: Vector2 = Vector2(52.0, 66.0)
## 棧橋的橋面：最低多高、每往東一公尺高多少
const DECK_LOW: float = 1.2
const DECK_SLOPE: float = 0.25
const GAUGE: float = 0.8
## 手推車卡在棧橋上的位置、救下來之後停在主軌上的位置（x）
const CART_X: float = 54.6
const CART_HOME_X: float = 46.4
const CART_LEN: float = 1.7
## 阿展坐的地方（木軌盡頭旁邊的一截圓木上，面向車）、他站起來拉煞車的地方
const AZHAN_SEAT: Vector3 = Vector3(49.0, 0.0, -41.2)
const AZHAN_BRAKE: Vector3 = Vector3(47.6, 0.0, -42.0)
## 伸手搆拉桿的地方（斷口邊上）
const REACH_SPOT: Vector3 = Vector3(49.8, 0.0, -43.0)
## 坡頂：絞盤、掛繩的桅杆（頂上的滑輪多高）
const WINCH: Vector3 = Vector3(64.5, 0.0, -38.6)
const MAST: Vector3 = Vector3(60.5, 0.0, -41.4)
const MAST_HEIGHT: float = 7.2
## 坡底：有裂紋的枯木（倒下去會搭在棧橋上）、頂住車頭時站的地方（橋面上）
const DEAD_TREE: Vector3 = Vector3(53.3, 0.0, -46.4)
const DEAD_TREE_HEIGHT: float = 4.4
const STAND_X: float = 53.3
## 把盾架上去的地方（斷掉垂下來的窄軌中間）
const SHIELD_SPOT: Vector3 = Vector3(51.2, 0.72, -43.0)
## 最後那一下席菈站的地方（阿展這一邊，看得到車扣）
const SERA_SHOT: Vector3 = Vector3(50.4, 0.0, -40.4)

var cart: Node3D
var buckle: Node3D
var lever: Node3D
var vines: Array[MeshInstance3D] = []
var rope_knot: Node3D
var rope_down: Node3D
var dead_tree: Node3D
var tree_blocker: StaticBody3D
var shield_step: Node3D
var _wood: StandardMaterial3D
var _dark: StandardMaterial3D
var _iron: StandardMaterial3D
var _rope: StandardMaterial3D
var _rock_t: float = 0.0
## 車還卡在坡上（會輕輕晃）
var cart_stuck: bool = true


## 橋面在 x 的地方多高
static func deck_y(x: float) -> float:
	return DECK_LOW + (clampf(x, TRESTLE_X.x, TRESTLE_X.y) - TRESTLE_X.x) * DECK_SLOPE


## 頂住車頭時站的地方（橋面上、車頭的下坡那一邊）
static func stand_spot() -> Vector3:
	return Vector3(STAND_X, deck_y(STAND_X), TRACK_Z)


## 車卡著的位置／救下來停在主軌上的位置
static func cart_spot(home: bool) -> Vector3:
	return Vector3(CART_HOME_X, 0.16, TRACK_Z) if home else Vector3(CART_X, deck_y(CART_X) + 0.06, TRACK_Z)


func _ready() -> void:
	name = "RailSite"
	_wood = _mat(Color(0.44, 0.31, 0.2), 0.9)
	_dark = _mat(Color(0.28, 0.2, 0.15), 0.95)
	_iron = _mat(Color(0.3, 0.3, 0.34), 0.55, 0.6)
	_rope = _mat(Color(0.74, 0.62, 0.4), 0.95)
	_build_track()
	_build_trestle()
	_build_cart()
	_build_winch()
	_build_dead_tree()
	_build_mud()
	_build_camp()


func _process(delta: float) -> void:
	# 卡在坡上的車：煞車鬆了一半，輕輕前後晃
	if cart_stuck and cart != null:
		_rock_t += delta
		cart.position.x = CART_X + 0.035 * sin(_rock_t * 2.1)


static func _mat(color: Color, rough: float, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	return m


static func _glow(color: Color, energy: float) -> StandardMaterial3D:
	var m := _mat(color, 0.6)
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m


static func _box(on: Node3D, node_name: String, size: Vector3, at: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var b := BoxMesh.new()
	b.size = size
	b.material = mat
	mi.mesh = b
	mi.position = at
	mi.rotation = rot
	on.add_child(mi, true)
	return mi


static func _cyl(on: Node3D, node_name: String, radius: Vector2, height: float, at: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var c := CylinderMesh.new()
	c.top_radius = radius.x
	c.bottom_radius = radius.y
	c.height = height
	c.radial_segments = 12
	c.rings = 1
	c.material = mat
	mi.mesh = c
	mi.position = at
	mi.rotation = rot
	on.add_child(mi, true)
	return mi


## 從 a 到 b 的一根圓木／繩（本地座標）
static func _beam(on: Node3D, node_name: String, a: Vector3, b: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var mi: MeshInstance3D = _cyl(on, node_name, Vector2(radius, radius), a.distance_to(b), (a + b) * 0.5, mat)
	var dir: Vector3 = (b - a).normalized()
	if absf(dir.dot(Vector3.UP)) < 0.999:
		mi.basis = Basis(Quaternion(Vector3.UP, dir))
	return mi


static func _wall(on: Node3D, node_name: String, size: Vector3, at: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.position = at
	body.add_child(shape)
	on.add_child(body)
	return body


static func _lantern(on: Node3D, node_name: String, at: Vector3, energy: float, reach: float) -> void:
	var root := Node3D.new()
	root.name = node_name
	root.position = at
	_box(root, "Cage", Vector3(0.16, 0.22, 0.16), Vector3.ZERO, _glow(Color(1.0, 0.72, 0.36), 2.4))
	_box(root, "Cap", Vector3(0.22, 0.04, 0.22), Vector3(0, 0.13, 0), _mat(Color(0.2, 0.2, 0.22), 0.6, 0.5))
	var light := OmniLight3D.new()
	light.name = "Light"
	light.light_color = Color(1.0, 0.72, 0.4)
	light.light_energy = energy
	light.omni_range = reach
	light.omni_attenuation = 1.3
	light.shadow_enabled = false
	root.add_child(light)
	on.add_child(root)


## 地面上的主軌（阿展這一邊）：兩條軌、枕木，東邊的一頭斷了——斷掉的窄軌從棧橋那一頭垂下來
func _build_track() -> void:
	var track := Node3D.new()
	track.name = "Track"
	add_child(track)
	var mid: float = (STUB_X.x + STUB_X.y) * 0.5
	var length: float = STUB_X.y - STUB_X.x
	for side: float in [-1.0, 1.0]:
		_box(track, "Rail", Vector3(length, 0.09, 0.09), Vector3(mid, 0.14, TRACK_Z + side * GAUGE * 0.5), _dark)
		# 垂下來的斷軌：從棧橋的低頭往下、往西
		_beam(track, "Snapped", Vector3(TRESTLE_X.x, DECK_LOW, TRACK_Z + side * GAUGE * 0.5), Vector3(GAP_X.x + 0.5, 0.18, TRACK_Z + side * (GAUGE * 0.5 + 0.12)), 0.05, _dark)
	var x: float = STUB_X.x + 0.4
	while x < STUB_X.y:
		_box(track, "Sleeper", Vector3(0.22, 0.08, GAUGE + 0.5), Vector3(x, 0.06, TRACK_Z), _wood, Vector3(0, sin(x * 3.1) * 0.06, 0))
		x += 0.9
	# 斷口：折斷的樁、掉在地上的枕木
	for i: int in 3:
		var px: float = GAP_X.x + 0.5 + 0.6 * float(i)
		_box(track, "Stump", Vector3(0.16, 0.35 + 0.2 * float(i % 2), 0.16), Vector3(px, 0.2, TRACK_Z + (0.5 if i % 2 == 0 else -0.55)), _dark, Vector3(0.2, 0.3 * float(i), 0.25))
	_box(track, "Fallen", Vector3(0.2, 0.08, 1.2), Vector3(GAP_X.x + 1.1, 0.05, TRACK_Z + 0.2), _wood, Vector3(0, 0.7, 0))
	# 斷口擋著（人走不進棧橋底下）
	_wall(self, "GapWall", Vector3(0.4, 2.4, GAUGE + 0.9), Vector3(GAP_X.x + 0.75, 1.2, TRACK_Z))


## 往東爬上去的棧橋：兩條軌、枕木、一對一對的樁與斜撐；底下整條是牆
func _build_trestle() -> void:
	var trestle := Node3D.new()
	trestle.name = "Trestle"
	add_child(trestle)
	var a := Vector3(TRESTLE_X.x, deck_y(TRESTLE_X.x), TRACK_Z)
	var b := Vector3(TRESTLE_X.y, deck_y(TRESTLE_X.y), TRACK_Z)
	for side: float in [-1.0, 1.0]:
		var off := Vector3(0, 0, side * GAUGE * 0.5)
		_beam(trestle, "Rail", a + off, b + off, 0.055, _dark)
		_beam(trestle, "Stringer", a + off * 1.5 - Vector3(0, 0.14, 0), b + off * 1.5 - Vector3(0, 0.14, 0), 0.09, _wood)
	var x: float = TRESTLE_X.x
	var slope_rot := Vector3(0, 0, atan(DECK_SLOPE))
	while x <= TRESTLE_X.y:
		var y: float = deck_y(x)
		_box(trestle, "Sleeper", Vector3(0.2, 0.07, GAUGE + 0.55), Vector3(x, y - 0.06, TRACK_Z), _wood, slope_rot)
		if int(roundf((x - TRESTLE_X.x) / 0.7)) % 3 == 0:
			for side: float in [-1.0, 1.0]:
				_beam(trestle, "Post", Vector3(x, 0.0, TRACK_Z + side * (GAUGE * 0.5 + 0.28)), Vector3(x, y - 0.1, TRACK_Z + side * (GAUGE * 0.5 + 0.12)), 0.09, _dark)
			_beam(trestle, "Brace", Vector3(x, 0.15, TRACK_Z - GAUGE * 0.5 - 0.25), Vector3(x, y - 0.25, TRACK_Z + GAUGE * 0.5 + 0.15), 0.045, _wood)
		x += 0.7
	var mid_x: float = (TRESTLE_X.x + TRESTLE_X.y) * 0.5
	_wall(self, "TrestleWall", Vector3(TRESTLE_X.y - TRESTLE_X.x, 5.0, GAUGE + 0.5), Vector3(mid_x, 2.5, TRACK_Z))
	_lantern(trestle, "CartLantern", Vector3(CART_X - 1.5, deck_y(CART_X) + 1.9, TRACK_Z - 0.75), 3.2, 8.0)
	_beam(trestle, "LanternPost", Vector3(CART_X - 1.5, 0.0, TRACK_Z - 0.75), Vector3(CART_X - 1.5, deck_y(CART_X) + 1.75, TRACK_Z - 0.75), 0.05, _dark)


## 手推車：木板車斗、四個鐵輪、五個凹槽的杯架（四個扣子解開了垂著，第五個跟煞車接在一起）、車頭的煞車拉桿
func _build_cart() -> void:
	cart = Node3D.new()
	cart.name = "Cart"
	cart.position = cart_spot(false)
	cart.rotation.z = atan(DECK_SLOPE)
	add_child(cart)
	_box(cart, "Floor", Vector3(CART_LEN, 0.08, 0.9), Vector3(0, 0.3, 0), _wood)
	for side: float in [-1.0, 1.0]:
		_box(cart, "Side", Vector3(CART_LEN, 0.46, 0.06), Vector3(0, 0.57, side * 0.45), _wood)
		_box(cart, "End", Vector3(0.06, 0.46, 0.9), Vector3(side * CART_LEN * 0.5, 0.57, 0), _wood)
		_box(cart, "Band", Vector3(CART_LEN + 0.04, 0.05, 0.94), Vector3(0, 0.5 + 0.14 * side, 0), _iron)
		for ax: float in [-0.52, 0.52]:
			_cyl(cart, "Wheel", Vector2(0.2, 0.2), 0.08, Vector3(ax, 0.16, side * 0.52), _iron, Vector3(PI * 0.5, 0, 0))
	# 杯架：一塊板、五個凹槽
	_box(cart, "Rack", Vector3(CART_LEN - 0.2, 0.05, 0.4), Vector3(0, 0.82, 0), _dark)
	var strap: StandardMaterial3D = _mat(Color(0.55, 0.36, 0.2), 0.8)
	for i: int in 5:
		var sx: float = -0.6 + 0.3 * float(i)
		_cyl(cart, "Slot", Vector2(0.09, 0.09), 0.06, Vector3(sx, 0.83, 0), _mat(Color(0.08, 0.07, 0.06), 0.9))
		if i > 0:
			# 解開的扣子垂在車斗外面
			_box(cart, "LooseStrap", Vector3(0.05, 0.3, 0.02), Vector3(sx, 0.66, 0.49), strap, Vector3(0.0, 0.0, 0.25 * sin(float(i) * 2.0)))
	# 第五個扣子（最靠車頭）：金色的車扣，跟煞車的拉桿用一條皮帶接著
	buckle = _box(cart, "Buckle", Vector3(0.1, 0.1, 0.05), Vector3(-0.6, 0.9, 0.24), _glow(Color(1.0, 0.8, 0.3), 1.2))
	_beam(cart, "BrakeStrap", Vector3(-0.6, 0.9, 0.24), Vector3(-0.92, 0.85, 0.3), 0.018, strap)
	lever = Node3D.new()
	lever.name = "Lever"
	lever.position = Vector3(-0.92, 0.3, 0.3)
	lever.rotation.z = 0.5
	cart.add_child(lever)
	_box(lever, "Bar", Vector3(0.05, 0.75, 0.05), Vector3(0, 0.37, 0), _iron)
	_cyl(lever, "Knob", Vector2(0.06, 0.06), 0.12, Vector3(0, 0.78, 0), _glow(Color(0.9, 0.25, 0.2), 0.8))


## 坡頂的絞盤：兩個木架、橫著的轉筒、搖把；三股藤纏在轉筒上（Vine1～3）；繩往上到桅杆頂的滑輪，打結吊在那裡
func _build_winch() -> void:
	var winch := Node3D.new()
	winch.name = "Winch"
	winch.position = WINCH
	add_child(winch)
	for side: float in [-1.0, 1.0]:
		_beam(winch, "Leg", Vector3(-0.4, 0, side * 0.55), Vector3(0, 1.05, side * 0.5), 0.06, _wood)
		_beam(winch, "Leg", Vector3(0.4, 0, side * 0.55), Vector3(0, 1.05, side * 0.5), 0.06, _wood)
	_cyl(winch, "Drum", Vector2(0.2, 0.2), 0.95, Vector3(0, 0.9, 0), _dark, Vector3(PI * 0.5, 0, 0))
	_cyl(winch, "Coil", Vector2(0.24, 0.24), 0.4, Vector3(0, 0.9, 0), _rope, Vector3(PI * 0.5, 0, 0))
	_beam(winch, "Crank", Vector3(0, 0.9, 0.5), Vector3(0.05, 1.25, 0.62), 0.03, _iron)
	_beam(winch, "Handle", Vector3(0.05, 1.25, 0.62), Vector3(0.05, 1.25, 0.84), 0.03, _iron)
	var vine_mat: StandardMaterial3D = _glow(Color(0.3, 0.62, 0.26), 0.35)
	var leaf_mat: StandardMaterial3D = _glow(Color(0.62, 0.3, 0.75), 0.6)
	for i: int in RailRescue.VINES:
		var v := MeshInstance3D.new()
		v.name = "Vine%d" % (i + 1)
		var torus := TorusMesh.new()
		torus.inner_radius = 0.27
		torus.outer_radius = 0.36
		torus.rings = 14
		torus.ring_segments = 6
		torus.material = vine_mat
		v.mesh = torus
		v.position = Vector3(0, 0.9, -0.3 + 0.3 * float(i))
		v.rotation = Vector3(PI * 0.5 + 0.22 * (float(i) - 1.0), 0, 0.3 * (float(i) - 1.0))
		winch.add_child(v)
		_cyl(v, "Bud", Vector2(0.0, 0.07), 0.16, Vector3(0.33, 0.04, 0.0), leaf_mat)
		_beam(v, "Tendril", Vector3(-0.3, 0, 0), Vector3(-0.42, 0.0, 0.3 - 0.9 * float(i % 2)), 0.03, vine_mat)
		vines.append(v)
	var blocker := StaticBody3D.new()
	blocker.name = "Blocker"
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.6
	cyl.height = 1.2
	shape.shape = cyl
	shape.position = Vector3(0, 0.6, 0)
	blocker.add_child(shape)
	winch.add_child(blocker)
	_lantern(winch, "WinchLantern", Vector3(-0.7, 1.5, -0.6), 2.4, 7.0)
	_beam(winch, "LanternPost", Vector3(-0.7, 0, -0.6), Vector3(-0.7, 1.4, -0.6), 0.04, _dark)
	# 桅杆與繩
	var mast := Node3D.new()
	mast.name = "Mast"
	add_child(mast)
	var top: Vector3 = MAST + Vector3(-1.2, MAST_HEIGHT, -0.9)
	_beam(mast, "Pole", MAST, top, 0.11, _dark)
	_beam(mast, "Stay", MAST + Vector3(1.6, 0, 1.2), MAST.lerp(top, 0.7), 0.05, _wood)
	_cyl(mast, "Pulley", Vector2(0.16, 0.16), 0.08, top - Vector3(0, 0.2, 0), _iron, Vector3(PI * 0.5, 0, 0))
	_beam(mast, "RopeUp", WINCH + Vector3(0, 1.0, 0), top - Vector3(0, 0.2, 0), 0.025, _rope)
	rope_knot = Node3D.new()
	rope_knot.name = "RopeKnot"
	rope_knot.position = top - Vector3(0, 0.75, 0)
	mast.add_child(rope_knot)
	_cyl(rope_knot, "Bundle", Vector2(0.2, 0.26), 0.5, Vector3.ZERO, _rope)
	_beam(rope_knot, "Loop", Vector3(0, -0.25, 0), Vector3(0.15, -0.8, 0.1), 0.025, _rope)
	rope_down = Node3D.new()
	rope_down.name = "RopeDown"
	rope_down.visible = false
	mast.add_child(rope_down)
	var hook_at: Vector3 = cart_spot(false) + Vector3(0.2, 1.05, 0)
	_beam(rope_down, "Line", top - Vector3(0, 0.2, 0), hook_at, 0.025, _rope)
	_cyl(rope_down, "Hook", Vector2(0.05, 0.02), 0.18, hook_at - Vector3(0, 0.08, 0), _iron)


## 棧橋北邊有裂紋的枯木：根部一圈發橘光的裂縫；倒下去（topple）搭在棧橋上、變成能踩上去的斜坡
func _build_dead_tree() -> void:
	dead_tree = Node3D.new()
	dead_tree.name = "DeadTree"
	dead_tree.position = DEAD_TREE
	add_child(dead_tree)
	var bark: StandardMaterial3D = _mat(Color(0.56, 0.5, 0.44), 0.95)
	_cyl(dead_tree, "Trunk", Vector2(0.15, 0.3), DEAD_TREE_HEIGHT, Vector3(0, DEAD_TREE_HEIGHT * 0.5, 0), bark)
	_beam(dead_tree, "Branch", Vector3(0, 2.6, 0), Vector3(0.9, 3.4, 0.2), 0.06, bark)
	_beam(dead_tree, "Branch", Vector3(0, 3.3, 0), Vector3(-0.7, 4.0, -0.3), 0.05, bark)
	_beam(dead_tree, "Branch", Vector3(0, 1.9, 0), Vector3(-0.5, 2.4, 0.5), 0.05, bark)
	var crack := MeshInstance3D.new()
	crack.name = "Crack"
	var ring := TorusMesh.new()
	ring.inner_radius = 0.26
	ring.outer_radius = 0.31
	ring.material = _glow(Color(1.0, 0.55, 0.2), 2.2)
	crack.mesh = ring
	crack.position = Vector3(0, 0.38, 0)
	crack.rotation = Vector3(0.25, 0, 0.12)
	dead_tree.add_child(crack)
	tree_blocker = StaticBody3D.new()
	tree_blocker.name = "TreeBlocker"
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.36
	cyl.height = 2.0
	shape.shape = cyl
	shape.position = Vector3(0, 1.0, 0)
	tree_blocker.add_child(shape)
	tree_blocker.position = DEAD_TREE
	add_child(tree_blocker)
	# 盾架在垂下來的窄軌上（place_shield 才看得到）
	shield_step = Node3D.new()
	shield_step.name = "ShieldStep"
	shield_step.position = SHIELD_SPOT
	shield_step.rotation = Vector3(0, PI * 0.5, 0)
	shield_step.visible = false
	add_child(shield_step)
	_box(shield_step, "Plate", Vector3(0.74, 0.05, 0.62), Vector3.ZERO, _mat(Color(0.5, 0.33, 0.24), 0.85, 0.4), Vector3(-atan(DECK_SLOPE) * 1.6, 0, 0))


## 枯木倒下去多斜（繞 x 軸，往 +z 倒向棧橋）：樹幹剛好搭在橋面的邊上
static func tree_fall_angle() -> float:
	var run: float = absf(TRACK_Z - GAUGE * 0.5 - 0.2 - DEAD_TREE.z)
	return PI * 0.5 - atan2(deck_y(DEAD_TREE.x), run)


## 枯木倒下。animate＝false 直接擺好（讀檔）
func topple(animate: bool = true) -> void:
	tree_blocker.process_mode = Node.PROCESS_MODE_DISABLED
	(tree_blocker.get_child(0) as CollisionShape3D).disabled = true
	(dead_tree.get_node("Crack") as MeshInstance3D).visible = false
	if not animate:
		dead_tree.rotation.x = tree_fall_angle()
		return
	var t: Tween = dead_tree.create_tween()
	t.tween_property(dead_tree, "rotation:x", tree_fall_angle(), 0.9).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func is_toppled() -> bool:
	return dead_tree.rotation.x > 0.5 or not (dead_tree.get_node("Crack") as MeshInstance3D).visible


func place_shield() -> void:
	shield_step.visible = true


## 藤：砍掉幾股（0＝都還在）
func show_vines(cut: int) -> void:
	for i: int in vines.size():
		vines[i].visible = i >= cut


## 繩放下來了（掛到車上）
func show_rope_free(free: bool) -> void:
	rope_knot.visible = not free
	rope_down.visible = free and cart_stuck


## 車停回主軌上（救下來了）。animate＝false 直接擺好
func park_cart() -> void:
	cart_stuck = false
	cart.position = cart_spot(true)
	cart.rotation.z = 0.0
	lever.rotation.z = -0.35
	buckle.visible = false
	rope_down.visible = false


## 坡底的泥灘：一片發亮的黑泥
func _build_mud() -> void:
	var mud: MeshInstance3D = _cyl(self, "Mud", Vector2(ForestMap.RAIL_MUD.z - 0.3, ForestMap.RAIL_MUD.z), 0.05, ForestMap.at(ForestMap.RAIL_MUD) + Vector3(0, 0.02, 0), _mat(Color(0.07, 0.065, 0.06), 0.12, 0.25))
	(mud.mesh as CylinderMesh).radial_segments = 28
	for i: int in 5:
		var a: float = float(i) * 1.9
		_cyl(self, "Puddle", Vector2(0.5, 0.55), 0.02, ForestMap.at(ForestMap.RAIL_MUD) + Vector3(cos(a) * 2.2, 0.05, sin(a) * 2.0), _glow(Color(0.2, 0.42, 0.24), 0.25))


## 阿展這一邊：他坐的圓木、提燈、杯架的木箱與繩
func _build_camp() -> void:
	var seat := MeshInstance3D.new()
	seat.name = "Seat"
	seat.mesh = SlopeClutter.log_mesh(57, 1.5, ForestScenery.CAMP_LOG_RADIUS, 12, 5)
	seat.material_override = SlopeClutter.log_material(ForestScenery.CAMP_LOG_RADIUS)
	seat.position = AZHAN_SEAT + Vector3(0, 0.25, 0)
	add_child(seat)
	_lantern(self, "CampLantern", Vector3(48.2, 2.3, -40.3), 3.6, 10.0)
	_beam(self, "CampLanternPost", Vector3(48.2, 0, -40.3), Vector3(48.2, 2.2, -40.3), 0.05, _dark)
	var props: Array = [["quaternius/Crate_Wooden", Vector3(46.2, 0, -40.2), 0.4], ["quaternius/Rope_1", Vector3(47.3, 0, -39.8), 1.2],
		["quaternius/Bucket_Wooden_1", Vector3(50.6, 0, -41.0), 0.0], ["quaternius/Barrel", Vector3(45.2, 0, -40.6), 0.0]]
	for spec: Array in props:
		var prop: Node3D = PropModels.instance(str(spec[0]))
		if prop == null:
			continue
		prop.position = spec[1]
		prop.rotation.y = float(spec[2])
		add_child(prop, true)
