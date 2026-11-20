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
## 棧橋底下那塊斜的擋板多厚（往地面下伸）
const WEDGE_THICK: float = 6.0
## 手推車卡在棧橋上的位置、救下來之後停在主軌上的位置（x）
const CART_X: float = 54.6
const CART_HOME_X: float = 46.4
const CART_LEN: float = 1.7
## 阿展坐的地方（木軌盡頭旁邊的一截圓木上，面向車）、車救下來之後他站的地方
const AZHAN_SEAT: Vector3 = Vector3(49.0, 0.0, -41.2)
const AZHAN_BRAKE: Vector3 = Vector3(49.2, 0.0, -42.3)
## 最後那一下他站在斷口邊上、車的正下坡（煞車繩彈下來落在他手上；手還沒舉起來之前繩先飛向 CORD_CATCH）
const AZHAN_PULL: Vector3 = Vector3(50.2, 0.0, -42.55)
const CORD_CATCH: Vector3 = Vector3(50.55, 2.0, -42.5)
## 煞車的拉桿：鬆了一半／拉到底（繞 z 軸的弧度；往下坡＝往阿展那一邊倒）
const LEVER_LOOSE: float = 0.5
const LEVER_SET: float = 1.0
## 伸手搆拉桿的地方（斷口邊上）
const REACH_SPOT: Vector3 = Vector3(49.8, 0.0, -43.0)
## 坡頂：絞盤、掛繩的桅杆（頂上的滑輪多高）
const WINCH: Vector3 = Vector3(64.5, 0.0, -38.6)
const MAST: Vector3 = Vector3(60.5, 0.0, -41.4)
const MAST_HEIGHT: float = 7.2
## 坡底：有裂紋的枯木（倒下去會搭在棧橋上）、頂住車頭時站的地方（橋面上）
const DEAD_TREE: Vector3 = Vector3(53.3, 0.0, -46.4)
const DEAD_TREE_HEIGHT: float = 4.4
const DEAD_BARK: Color = Color(0.47, 0.42, 0.38)
const STAND_X: float = 52.9
## 他站在軌道中線偏北一點（拉桿在車頭的南側，手臂不跟它疊在一起）
const STAND_Z: float = -43.12
## 絞盤的搖把：軸離地多高、轉的半徑、搖的人站在軸的東邊多遠（這三個跟 tools/blender/common.py 的 CRANK_* 要一樣）、
## 握把在絞盤的哪一側（z）、搖一圈幾秒（模型的 crank 動作 30 格、24 fps）
const CRANK_AXLE: float = 0.9
const CRANK_RADIUS: float = 0.26
const CRANK_AHEAD: float = 0.45
const CRANK_Z: float = 0.73
const CRANK_SEC: float = 1.25
## 把盾架上去的地方（斷掉垂下來的窄軌中間）
const SHIELD_SPOT: Vector3 = Vector3(51.2, 0.72, -43.0)
## 最後那一下席菈站的地方（阿展這一邊、棧橋低的那一頭的南邊，看得到車扣；離鏡頭夠遠，整個人都在畫面裡）
const SERA_SHOT: Vector3 = Vector3(51.6, 0.0, -41.0)
## 最後那一下的鏡頭（從阿展這一邊看過去：左邊斷口邊上的阿展、中間的車與頂著它的諾恩、右邊舉弩的席菈）：鏡頭在哪、看著哪
const FINAL_EYE: Vector3 = Vector3(47.0, 2.6, -39.4)
const FINAL_AIM: Vector3 = Vector3(53.2, 2.0, -42.9)
## 坡頂那一條的第一個鏡頭（從南邊看：右邊搖絞盤的諾恩、左邊遠處繩吊著的車）
const CRANK_EYE: Vector3 = Vector3(66.0, 1.7, -34.9)
const CRANK_AIM: Vector3 = Vector3(62.6, 1.25, -39.6)
## 自己放一朵毒蕈到車架上試（斷口邊上、伸手的地方旁邊）
const WEIGH_SPOT: Vector3 = Vector3(49.0, 0.0, -43.0)
## 泥灘那一片黑泥多大（空地本身比它大：樹人站在遠端）
const MUD_RADIUS: float = 4.6

var cart: Node3D
var buckle: Node3D
var lever: Node3D
var vines: Array[MeshInstance3D] = []
var rope_knot: Node3D
var rope_down: Node3D
## 絞盤的搖把（set_crank 轉它）
var crank: Node3D
## 煞車繩：平常捲著被車扣壓在車邊（cord_coil）；車扣彈開之後是一條從拉桿頂拉到 cord_end 的繩（cord）
var cord: MeshInstance3D
var cord_coil: Node3D
var cord_end: Vector3 = Vector3.INF
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
## 車從卡住的地方往下坡滑了多遠（公尺；最後那一下：繩放一段、車扣彈開滑一小步）
var cart_slide: float = 0.0
## 車身被壓得往下沉多少（公尺；放一朵毒蕈上去試的那一下）
var cart_dip: float = 0.0
## 掛繩放下來多少（0＝還吊在桅杆上、1＝鉤在車上）
var _rope_k: float = 1.0
var _rope_line: MeshInstance3D
var _rope_hook: MeshInstance3D
var _rope_top: Vector3


## 橋面在 x 的地方多高
static func deck_y(x: float) -> float:
	return DECK_LOW + (clampf(x, TRESTLE_X.x, TRESTLE_X.y) - TRESTLE_X.x) * DECK_SLOPE


## 頂住車頭時站的地方（橋面上、車頭的下坡那一邊）；slide＝車往下滑了多遠（他跟著退）
static func stand_spot(slide: float = 0.0) -> Vector3:
	return Vector3(STAND_X - slide, deck_y(STAND_X - slide), STAND_Z)


## 搖絞盤時站的地方（握把的東邊，面向西：看得到繩與坡下的車）
static func crank_spot() -> Vector3:
	return WINCH + Vector3(CRANK_AHEAD, 0.0, CRANK_Z)


## 車在棧橋上 x 的地方時的位置
static func cart_on_deck(x: float) -> Vector3:
	return Vector3(x, deck_y(x) + 0.06, TRACK_Z)


## 車卡著的位置／救下來停在主軌上的位置
static func cart_spot(home: bool) -> Vector3:
	return Vector3(CART_HOME_X, 0.16, TRACK_Z) if home else cart_on_deck(CART_X)


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
	if cart == null:
		return
	# 卡在坡上的車：煞車鬆了一半，輕輕前後晃
	if cart_stuck:
		_rock_t += delta
		cart.position = cart_on_deck(CART_X - cart_slide + 0.035 * sin(_rock_t * 2.1)) - Vector3(0, cart_dip, 0)
	elif cart.rotation.z != 0.0:
		cart.position = cart_on_deck(CART_X - cart_slide)
	# 掛繩跟著車走（放下來的那一下從桅杆上的繩結落到車上）
	if rope_down.visible:
		var hook: Vector3 = (rope_knot.position - Vector3(0, 0.8, 0)).lerp(cart.position + Vector3(0.2, 1.05, 0), _rope_k)
		_stretch(_rope_line, _rope_top, hook)
		_rope_hook.position = hook - Vector3(0, 0.08, 0)
	if cord.visible and cord_end.is_finite():
		_stretch(cord, lever_tip(), cord_end)


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


## 把一根單位長的圓柱（_beam 做的）拉到 a、b 兩點之間（世界座標；每一幀在動的繩）
static func _stretch(mi: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var d: Vector3 = b - a
	var length: float = maxf(d.length(), 0.01)
	var up: Vector3 = d / length
	var basis := Basis.IDENTITY
	if absf(up.dot(Vector3.UP)) < 0.999:
		basis = Basis(Quaternion(Vector3.UP, up))
	mi.global_transform = Transform3D(Basis(basis.x, basis.y * length, basis.z), (a + b) * 0.5)


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
	_wall(self, "GapWall", Vector3(0.4, 1.3, GAUGE + 0.9), Vector3(GAP_X.x + 0.75, 0.65, TRACK_Z))


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
	# 棧橋底下整條擋住：一塊斜的厚板，頂面就是橋面（不是一路 5 m 高的牆——低的那一頭鏡頭不會被看不見的東西推開）
	var angle: float = atan(DECK_SLOPE)
	var wedge: StaticBody3D = _wall(self, "TrestleWall", Vector3(a.distance_to(b), WEDGE_THICK, GAUGE + 0.5), a.lerp(b, 0.5) - Vector3(-sin(angle), cos(angle), 0.0) * WEDGE_THICK * 0.5)
	wedge.rotation.z = angle
	_lantern(trestle, "CartLantern", Vector3(CART_X - 1.5, deck_y(CART_X) + 1.9, TRACK_Z - 0.75), 6.5, 9.0)
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
	lever.rotation.z = LEVER_LOOSE
	cart.add_child(lever)
	_box(lever, "Bar", Vector3(0.05, 0.75, 0.05), Vector3(0, 0.37, 0), _iron)
	_cyl(lever, "Knob", Vector2(0.06, 0.06), 0.12, Vector3(0, 0.78, 0), _glow(Color(0.9, 0.25, 0.2), 0.8))
	# 煞車繩：一頭綁在拉桿頂，其餘捲成一圈被車扣壓在車邊；車扣彈開（pop_buckle）它才甩得下來
	cord_coil = Node3D.new()
	cord_coil.name = "CordCoil"
	cord_coil.position = Vector3(-0.6, 0.72, 0.5)
	cart.add_child(cord_coil)
	for i: int in 3:
		var loop := MeshInstance3D.new()
		loop.name = "Loop"
		var ring := TorusMesh.new()
		ring.inner_radius = 0.085
		ring.outer_radius = 0.12
		ring.rings = 12
		ring.ring_segments = 5
		ring.material = _rope
		loop.mesh = ring
		loop.position = Vector3(0.012 * float(i - 1), -0.02 * float(i), 0.012 * float(i))
		loop.rotation = Vector3(PI * 0.5 + 0.18 * float(i - 1), 0, 0.12 * float(i))
		cord_coil.add_child(loop)
	_beam(cord_coil, "Tail", Vector3(0, 0.1, 0), Vector3(0, 0.18, -0.26), 0.018, _rope)
	cord = _cyl(self, "BrakeCord", Vector2(0.02, 0.02), 1.0, Vector3.ZERO, _rope)
	cord.visible = false


## 拉桿頂在哪（世界座標：煞車繩綁在這裡）
func lever_tip() -> Vector3:
	return lever.global_transform * Vector3(0, 0.78, 0)


## 車扣被打開：扣子往上彈開、不見；捲著的煞車繩甩出去，繩頭 fly_sec 秒飛到 to（之後 cord_end 由 RailEvent 每一幀跟著阿展的手）
func pop_buckle(to: Vector3, fly_sec: float) -> void:
	var from: Vector3 = cord_coil.global_position
	cord_coil.visible = false
	cord.visible = true
	cord_end = from
	var fly: Tween = create_tween()
	fly.tween_method(func(k: float) -> void: cord_end = from.lerp(to, k) + Vector3.UP * sin(k * PI) * 0.7, 0.0, 1.0, fly_sec)
	var pop: Tween = buckle.create_tween().set_parallel(true)
	pop.tween_property(buckle, "position", buckle.position + Vector3(-0.15, 0.7, 0.5), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	pop.tween_property(buckle, "rotation", Vector3(5.0, 3.0, 4.0), 0.3)
	pop.chain().tween_callback(func() -> void: buckle.visible = false)


## 車往下坡再滑 by 公尺（sec 秒）。預設滑到底彈一下（車扣彈開的那一下）；放繩慢慢放下去給 TRANS_SINE
func slide_cart(by: float, sec: float, trans: Tween.TransitionType = Tween.TRANS_BACK) -> void:
	create_tween().tween_property(self, "cart_slide", cart_slide + by, sec).set_trans(trans).set_ease(Tween.EASE_OUT if trans == Tween.TRANS_BACK else Tween.EASE_IN_OUT)


## 拉桿拉到底（煞車咬住）
func set_brake(sec: float, delay: float = 0.0) -> void:
	lever.create_tween().tween_property(lever, "rotation:z", LEVER_SET, sec).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


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
	crank = Node3D.new()
	crank.name = "Crank"
	crank.position = Vector3(0, CRANK_AXLE, 0.5)
	winch.add_child(crank)
	_beam(crank, "Arm", Vector3.ZERO, Vector3(0, CRANK_RADIUS, CRANK_Z - 0.5 - 0.11), 0.03, _iron)
	_beam(crank, "Handle", Vector3(0, CRANK_RADIUS, CRANK_Z - 0.5 - 0.11), Vector3(0, CRANK_RADIUS, CRANK_Z - 0.5 + 0.11), 0.035, _wood)
	set_crank(1.1)
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
	_lantern(winch, "WinchLantern", Vector3(-0.7, 1.5, -0.6), 5.0, 8.0)
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
	# 放下來的那一段每一幀照車的位置拉（_process）
	_rope_top = top - Vector3(0, 0.2, 0)
	_rope_line = _cyl(rope_down, "Line", Vector2(0.025, 0.025), 1.0, Vector3.ZERO, _rope)
	_rope_hook = _cyl(rope_down, "Hook", Vector2(0.05, 0.02), 0.18, Vector3.ZERO, _iron)


## 搖把轉到 phase（弧度；跟模型的 crank 動作同一圈：0＝握把離搖的人最遠，再往上、往他那邊、往下）
func set_crank(phase: float) -> void:
	crank.rotation.z = PI * 0.5 - phase


## 棧橋北邊有裂紋的枯木：根部一圈發橘光的裂縫；倒下去（topple）搭在棧橋上、變成能踩上去的斜坡
func _build_dead_tree() -> void:
	dead_tree = Node3D.new()
	dead_tree.name = "DeadTree"
	dead_tree.position = DEAD_TREE
	add_child(dead_tree)
	# 樹幹跟路邊的倒木同一套（粗細起伏、樹皮紋、斷口的年輪），顏色調成枯掉的灰白；立起來（木頭的長軸轉成往上，細的那一頭在上面）
	var bark: StandardMaterial3D = _mat(DEAD_BARK, 0.95)
	var trunk := MeshInstance3D.new()
	trunk.name = "Trunk"
	trunk.mesh = SlopeClutter.log_mesh(91, DEAD_TREE_HEIGHT, 0.25, 9, 8)
	var trunk_mat: ShaderMaterial = SlopeClutter.log_material(0.25)
	trunk_mat.set_shader_parameter("bark", DEAD_BARK)
	trunk_mat.set_shader_parameter("bark_dark", DEAD_BARK * 0.45)
	trunk.material_override = trunk_mat
	trunk.position = Vector3(0, DEAD_TREE_HEIGHT * 0.5, 0)
	trunk.rotation.z = PI * 0.5
	dead_tree.add_child(trunk)
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


## 藤：砍掉幾股（0＝都還在）。原本砍掉、現在又在的那幾股是長回來的：從小長到原本的大小
func show_vines(cut: int) -> void:
	for i: int in vines.size():
		var back: bool = i >= cut and not vines[i].visible
		vines[i].visible = i >= cut
		if back and is_inside_tree():
			vines[i].scale = Vector3.ONE * 0.3
			vines[i].create_tween().tween_property(vines[i], "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## 繩放下來了（掛到車上）。animate＝true：從桅杆上的繩結落下來、晃一下才鉤住（砍開藤的那一刻）
func show_rope_free(free: bool, animate: bool = false) -> void:
	rope_knot.visible = not free
	rope_down.visible = free and cart_stuck
	_rope_k = 1.0
	if free and animate:
		_rope_k = 0.0
		create_tween().tween_property(self, "_rope_k", 1.0, 0.8).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


## 車停回主軌上（救下來了）。animate＝false 直接擺好
func park_cart() -> void:
	cart_stuck = false
	cart.position = cart_spot(true)
	cart.rotation.z = 0.0
	lever.rotation.z = LEVER_SET
	buckle.visible = false
	rope_down.visible = false
	cord.visible = false
	cord_coil.visible = false


## 坡底的泥灘：一灘發亮的黑泥（邊緣凹凸不齊，不是正圓）與幾個大小形狀不一樣的綠水窪
func _build_mud() -> void:
	var center: Vector3 = ForestMap.at(ForestMap.RAIL_MUD)
	var mud := MeshInstance3D.new()
	mud.name = "Mud"
	mud.mesh = _blob_mesh(MUD_RADIUS, 40, 7)
	mud.material_override = _mat(Color(0.07, 0.065, 0.06), 0.12, 0.25)
	mud.position = center + Vector3(0, 0.03, 0)
	add_child(mud)
	var water: StandardMaterial3D = _glow(Color(0.2, 0.42, 0.24), 0.25)
	for i: int in 5:
		var a: float = float(i) * 1.9
		var puddle := MeshInstance3D.new()
		puddle.name = "Puddle"
		puddle.mesh = _blob_mesh(0.4 + 0.13 * float(i % 3), 16, 11 + i)
		puddle.material_override = water
		puddle.position = center + Vector3(cos(a) * 2.2, 0.05, sin(a) * 2.0)
		puddle.scale = Vector3(1.0 + 0.45 * float(i % 2), 1.0, 1.0)
		puddle.rotation.y = a * 1.7
		add_child(puddle, true)


## 貼地的一灘（從中心拉出去的扇形）：半徑照角度起伏，seed_value 換一個形狀
static func _blob_mesh(radius: float, points: int, seed_value: int) -> ArrayMesh:
	var k: float = float(seed_value)
	var rim := PackedVector3Array()
	for i: int in points:
		var a: float = TAU * float(i) / float(points)
		var r: float = radius * (1.0 + 0.13 * sin(a * 3.0 + k) + 0.08 * sin(a * 5.0 + k * 2.3) + 0.05 * sin(a * 9.0 + k * 0.7))
		rim.append(Vector3(cos(a) * r, 0.0, sin(a) * r))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in points:
		for v: Vector3 in [Vector3.ZERO, rim[i], rim[(i + 1) % points]]:
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
	return st.commit()


## 阿展這一邊：他坐的圓木、提燈、杯架的木箱與繩
func _build_camp() -> void:
	var seat := MeshInstance3D.new()
	seat.name = "Seat"
	seat.mesh = SlopeClutter.log_mesh(57, 1.5, ForestScenery.CAMP_LOG_RADIUS, 12, 5)
	seat.material_override = SlopeClutter.log_material(ForestScenery.CAMP_LOG_RADIUS)
	seat.position = AZHAN_SEAT + Vector3(0, 0.25, 0)
	add_child(seat)
	# 提燈立在軌道的另一邊（最後那一下的鏡頭在阿展這一邊：立在這邊會擋在鏡頭前面）
	_lantern(self, "CampLantern", Vector3(47.8, 2.3, -44.7), 7.5, 11.0)
	_beam(self, "CampLanternPost", Vector3(47.8, 0, -44.7), Vector3(47.8, 2.2, -44.7), 0.05, _dark)
	var props: Array = [["quaternius/Crate_Wooden", Vector3(46.2, 0, -40.2), 0.4], ["quaternius/Rope_1", Vector3(47.3, 0, -39.8), 1.2],
		["quaternius/Bucket_Wooden_1", Vector3(50.6, 0, -41.0), 0.0], ["quaternius/Barrel", Vector3(45.2, 0, -40.6), 0.0]]
	for spec: Array in props:
		var prop: Node3D = PropModels.instance(str(spec[0]))
		if prop == null:
			continue
		prop.position = spec[1]
		prop.rotation.y = float(spec[2])
		add_child(prop, true)
