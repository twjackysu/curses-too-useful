class_name SeraVial
extends Node3D
## 席菈射出來的藥瓶：一道拋物線飛向諾恩的背（她瞄的就是他，一定會中），落在身上就套用那個來源的狀態
## （data/status/statuses.json 的 sources）——反轉的回饋由 StatusEffects.changed 自己觸發，這裡不用管。
## launch_at 的那一瓶不射人、射一個地方（斷軌的車扣）：同一個瓶子、同樣的光尾與濺開，不上狀態，打中發 shattered。
## 來源寫了 "vial": "forbidden" 的那一瓶（Boss 戰的【混沌大災難藥劑】，D-306）長得不一樣：圓底的大燒瓶、藥水在桃紅／紫／金之間一直變、
## 三顆光點繞著它轉、拖著一條變色的光尾，拋得比較高、飛得比較慢；砸中時一圈往外擴的光環＋一下強光＋更大一團藥水。

## 打中了（launch_at 的那一瓶：後面的事關卡自己接）
signal shattered

const ARC_HEIGHT: float = 1.1
const CHEST_Y: float = 1.15
const LIQUID: Color = Color(0.75, 0.35, 1.0)
## 煙霧彈砸開的那一圈煙：貼著地面從諾恩腳邊往外滾（不往上冒：他站在中間，煙不能蓋住他），滾到 SMOKE_REACH 公尺左右就散掉。
## 每一團邊滾邊從 SMOKE_GROW.x 倍長到 .y 倍；頭 SMOKE_FADE_IN 的壽命是透明的（剛冒出來還貼在他腳邊的那幾幀不蓋到小腿）。
## SMOKE_Y＝最小的那一團剛好不插進地面；長大之後插進去的部分靠 proximity fade 淡掉（看不到一條平的邊）
const SMOKE_SEC: float = 1.1
const SMOKE_PUFFS: int = 22
const SMOKE_REACH: float = 1.9
const SMOKE_SIZE: float = 0.85
const SMOKE_GROW: Vector2 = Vector2(0.6, 1.25)
const SMOKE_FADE_IN: float = 0.2
## 離地面（或任何東西）這麼近的部分就淡掉
const SMOKE_FADE_GROUND: float = 0.35
const SMOKE_Y: float = SMOKE_SIZE * 0.6 * 0.5 + 0.02
## 禁藥：藥水輪流變的顏色、變一輪要幾秒；拋多高、飛的時間是平常的幾倍；繞著轉的光點幾顆、多遠、一秒轉幾圈；砸中的光環擴到多大
const FORBIDDEN: String = "forbidden"
const FORBIDDEN_COLORS: Array[Color] = [Color(1.0, 0.3, 0.8), Color(0.62, 0.36, 1.0), Color(1.0, 0.8, 0.32)]
const FORBIDDEN_CYCLE_SEC: float = 0.6
const FORBIDDEN_ARC: float = 2.6
const FORBIDDEN_SLOW: float = 1.7
const ORBIT_COUNT: int = 3
const ORBIT_RADIUS: float = 0.32
const ORBIT_TURNS: float = 2.2
const BURST_RING: float = 3.2

var target: PlayerController
## 不射人、射這個地方（Vector3.INF＝射 target）
var aim_point: Vector3 = Vector3.INF
var source: String = ""
var flight: float = 0.55
var landed: bool = false
## 這一瓶的顏色：資料表的來源有寫 color 就用它（致盲煙霧彈是螢光黃），沒寫是紫的
var liquid: Color = LIQUID
## 砸開會冒一圈煙（資料表的來源寫 "smoke": true：致盲煙霧彈）
var smoky: bool = false
var smoke: CPUParticles3D
## "forbidden"＝Boss 戰的禁藥（長得不一樣）；空的＝平常的藥瓶
var style: String = ""
var _from: Vector3
var _arc: float = ARC_HEIGHT
var _liquid_mat: StandardMaterial3D
var _glow: OmniLight3D
var _orbits: Array[MeshInstance3D] = []
var _age: float = 0.0
var _t: float = 0.0
var _bottle: MeshInstance3D
var _trail: CPUParticles3D


static func launch(parent: Node, from: Vector3, p_target: PlayerController, p_source: String) -> SeraVial:
	var v := SeraVial.new()
	v.name = "SeraVial"
	v.target = p_target
	v.source = p_source
	var src: Dictionary = StatusRules.load_default().source(p_source)
	var tint: String = str(src.get("color", ""))
	if Color.html_is_valid(tint):
		v.liquid = Color.html(tint)
	v.smoky = bool(src.get("smoke", false))
	v.style = str(src.get("vial", ""))
	v.flight = maxf(CombatTuning.num("sera.vial_flight", 0.55), 0.05)
	if v.style == FORBIDDEN:
		v.flight *= FORBIDDEN_SLOW
		v._arc = FORBIDDEN_ARC
	v._from = from
	parent.add_child(v)
	v.global_position = from
	return v


## 從 from 射向一個地方（不是人）：飛 flight_sec 秒、拋 arc 公尺高
static func launch_at(parent: Node, from: Vector3, point: Vector3, flight_sec: float, arc: float = ARC_HEIGHT) -> SeraVial:
	var v := SeraVial.new()
	v.name = "SeraVial"
	v.aim_point = point
	v.flight = maxf(flight_sec, 0.05)
	v._arc = arc
	v._from = from
	parent.add_child(v)
	v.global_position = from
	return v


func is_forbidden() -> bool:
	return style == FORBIDDEN


func _ready() -> void:
	if is_forbidden():
		_build_forbidden()
		return
	_bottle = MeshInstance3D.new()
	var glass := CapsuleMesh.new()
	glass.radius = 0.05
	glass.height = 0.2
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = liquid
	glass.material = mat
	_bottle.mesh = glass
	_bottle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_bottle)
	var glow := OmniLight3D.new()
	glow.light_color = liquid
	glow.light_energy = 1.6
	glow.omni_range = 3.0
	glow.light_specular = 0.0
	_bottle.add_child(glow)
	_trail = _particles(26, 0.45, 0.4, 0.09)
	_trail.spread = 180.0
	add_child(_trail)


func _physics_process(delta: float) -> void:
	if landed:
		return
	var at_point: bool = aim_point.is_finite()
	if not at_point and (target == null or not is_instance_valid(target)):
		queue_free()
		return
	_t = minf(_t + delta / flight, 1.0)
	_age += delta
	var to: Vector3 = aim_point if at_point else target.global_position + Vector3.UP * CHEST_Y
	var p: Vector3 = _from.lerp(to, _t)
	p.y += sin(_t * PI) * _arc
	global_position = p
	_bottle.rotation.x += delta * (6.0 if is_forbidden() else 14.0)
	if is_forbidden():
		_tick_forbidden()
	if _t >= 1.0:
		_land()


## 砸在諾恩身上：上狀態、玻璃碎掉潑開的聲音、一團藥水往外濺；煙霧彈再加一圈貼地的煙。
func _land() -> void:
	landed = true
	if aim_point.is_finite():
		Sfx.play_at(get_parent(), "vial_shatter", global_position, -2.0, 0.04)
		shattered.emit()
	else:
		target.status_effects.apply_source(source)
		Sfx.play_at(target, "vial_shatter", global_position, -3.0)
	_bottle.visible = false
	_trail.emitting = false
	if is_forbidden():
		_burst_forbidden()
	var splash: CPUParticles3D = _particles(90 if is_forbidden() else 40, 0.7 if is_forbidden() else 0.5, 4.5 if is_forbidden() else 3.2, 0.18 if is_forbidden() else 0.14)
	splash.one_shot = true
	splash.explosiveness = 1.0
	splash.spread = 180.0
	splash.gravity = Vector3(0, -6.0, 0)
	add_child(splash)
	if smoky:
		smoke = _smoke_ring()
		# 藥瓶的節點不轉、不縮放：位置差直接當本地座標（先擺好再加進場景，跟濺開的藥水同一種掛法）
		smoke.position = target.global_position + Vector3.UP * SMOKE_Y - global_position
		add_child(smoke)
	get_tree().create_timer(maxf(1.0, SMOKE_SEC + 0.1) if smoky else 1.0).timeout.connect(queue_free)


## 現在的藥水顏色（禁藥一直在變；平常的那一瓶就是 liquid）
func current_color() -> Color:
	if not is_forbidden():
		return liquid
	var k: float = fposmod(_age / FORBIDDEN_CYCLE_SEC, 1.0) * float(FORBIDDEN_COLORS.size())
	var i: int = int(k)
	return FORBIDDEN_COLORS[i].lerp(FORBIDDEN_COLORS[(i + 1) % FORBIDDEN_COLORS.size()], k - float(i))


## 禁藥的樣子：圓底燒瓶（瓶身＋瓶頸＋軟木塞）、一盞會變色的燈、三顆繞著轉的光點、一條變色的光尾
func _build_forbidden() -> void:
	_bottle = MeshInstance3D.new()
	_bottle.name = "Flask"
	var bulb := SphereMesh.new()
	bulb.radius = 0.12
	bulb.height = 0.24
	_liquid_mat = StandardMaterial3D.new()
	_liquid_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_liquid_mat.albedo_color = FORBIDDEN_COLORS[0]
	bulb.material = _liquid_mat
	_bottle.mesh = bulb
	_bottle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_bottle)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.85, 0.9, 1.0, 0.5)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.1
	var neck := MeshInstance3D.new()
	var tube := CylinderMesh.new()
	tube.top_radius = 0.035
	tube.bottom_radius = 0.045
	tube.height = 0.12
	tube.material = glass
	neck.mesh = tube
	neck.position = Vector3(0, 0.15, 0)
	_bottle.add_child(neck)
	var cork := MeshInstance3D.new()
	var plug := CylinderMesh.new()
	plug.top_radius = 0.04
	plug.bottom_radius = 0.034
	plug.height = 0.05
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.55, 0.38, 0.22)
	plug.material = wood
	cork.mesh = plug
	cork.position = Vector3(0, 0.23, 0)
	_bottle.add_child(cork)
	_glow = OmniLight3D.new()
	_glow.light_color = FORBIDDEN_COLORS[0]
	_glow.light_energy = 3.2
	_glow.omni_range = 5.0
	_glow.light_specular = 0.0
	_glow.light_volumetric_fog_energy = 2.0
	add_child(_glow)
	for i: int in ORBIT_COUNT:
		var mote := MeshInstance3D.new()
		mote.name = "Orbit%d" % i
		var ball := SphereMesh.new()
		ball.radius = 0.035
		ball.height = 0.07
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = FORBIDDEN_COLORS[i % FORBIDDEN_COLORS.size()].lerp(Color.WHITE, 0.35)
		ball.material = m
		mote.mesh = ball
		mote.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mote)
		_orbits.append(mote)
	_trail = _particles(70, 0.8, 0.6, 0.14)
	_trail.spread = 180.0
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.35, 0.7, 1.0])
	ramp.colors = PackedColorArray([Color(FORBIDDEN_COLORS[0], 1.0), Color(FORBIDDEN_COLORS[1], 0.85), Color(FORBIDDEN_COLORS[2], 0.6), Color(FORBIDDEN_COLORS[2], 0.0)])
	_trail.color_ramp = ramp
	(_trail.mesh as QuadMesh).material = ParticleLook.material(Color.WHITE, true)
	add_child(_trail)
	_tick_forbidden()


## 每幀：藥水與燈換顏色、光點繞著瓶子轉（繞的平面跟著飛的方向斜一點，看起來是螺旋）
func _tick_forbidden() -> void:
	var c: Color = current_color()
	_liquid_mat.albedo_color = c
	_glow.light_color = c
	for i: int in _orbits.size():
		var a: float = _age * TAU * ORBIT_TURNS + TAU * float(i) / float(_orbits.size())
		_orbits[i].position = Vector3(cos(a), sin(a * 0.5) * 0.4, sin(a)) * ORBIT_RADIUS


## 禁藥砸中：一圈往外擴的光環（貼著地面）＋一下強光；光點收掉
func _burst_forbidden() -> void:
	for o: MeshInstance3D in _orbits:
		o.visible = false
	var ring := MeshInstance3D.new()
	ring.name = "BurstRing"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.42
	torus.outer_radius = 0.5
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = FORBIDDEN_COLORS[0]
	torus.material = m
	ring.mesh = torus
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.position = target.global_position + Vector3.UP * 0.15 - global_position
	add_child(ring)
	var t: Tween = ring.create_tween().set_parallel()
	t.tween_property(ring, "scale", Vector3(BURST_RING, 1.0, BURST_RING) / 0.5, 0.6).from(Vector3.ONE * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(m, "albedo_color", Color(FORBIDDEN_COLORS[2], 0.0), 0.6)
	_glow.light_energy = 7.0
	_glow.omni_range = 7.0
	var f: Tween = _glow.create_tween()
	f.tween_property(_glow, "light_energy", 0.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## 一圈貼著地面往外滾的煙：一開始衝得快、馬上被拖慢（停在 SMOKE_REACH 附近），邊滾邊變大、變淡。
## ParticleLook 的看板材質預設不看粒子的縮放：這裡打開 billboard_keep_scale，scale_amount_curve 才有作用。
## 顏色是藥水的顏色加白；半透明、不發光（跟濺開的藥水點分得出來）。
func _smoke_ring() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = "Smoke"
	p.amount = SMOKE_PUFFS
	p.lifetime = SMOKE_SEC
	p.one_shot = true
	# 一定要一次全部出來：還沒出來的粒子會被畫成原點的一顆黑點（看板材質不看粒子的縮放，藏不掉）——
	# 0.92 的時候砸中後頭幾幀腳邊有一團黑的
	p.explosiveness = 1.0
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.2
	# 水平往四面八方：direction 在 X、flatness＝1 把散開的方向壓在水平面上
	p.direction = Vector3.RIGHT
	p.spread = 180.0
	p.flatness = 1.0
	p.gravity = Vector3(0, 0.25, 0)
	# 等減速：v0 = 2 × 距離 ÷ 時間、damping = v0 ÷ 時間 → 壽命結束時剛好停在 SMOKE_REACH
	var v0: float = 2.0 * SMOKE_REACH / SMOKE_SEC
	p.initial_velocity_min = v0 * 0.7
	p.initial_velocity_max = v0
	p.damping_min = v0 / SMOKE_SEC
	p.damping_max = v0 / SMOKE_SEC
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, SMOKE_FADE_IN, SMOKE_FADE_IN + 0.12, 0.6, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0.08), Color(1, 1, 1, 0.42), Color(1, 1, 1, 0.26), Color(1, 1, 1, 0)])
	p.color_ramp = fade
	var grow := Curve.new()
	grow.min_value = 0.0
	grow.max_value = SMOKE_GROW.y
	grow.add_point(Vector2(0.0, SMOKE_GROW.x), 0.0, 1.6)
	grow.add_point(Vector2(1.0, SMOKE_GROW.y), 0.4, 0.0)
	p.scale_amount_curve = grow
	var quad := QuadMesh.new()
	quad.size = Vector2(SMOKE_SIZE, SMOKE_SIZE)
	var mat: StandardMaterial3D = ParticleLook.material(liquid.lerp(Color.WHITE, 0.35))
	mat.billboard_keep_scale = true
	# 長大之後下半團會插進地面：碰到地面的地方淡掉（soft particles），不然看得到一條平的邊
	mat.proximity_fade_enabled = true
	mat.proximity_fade_distance = SMOKE_FADE_GROUND
	quad.material = mat
	p.mesh = quad
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return p


func _particles(amount: int, life: float, speed: float, size: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.local_coords = false
	p.direction = Vector3.UP
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.2
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	p.color_ramp = fade
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	quad.material = ParticleLook.material(liquid, true)
	p.mesh = quad
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return p
