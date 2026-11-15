class_name SeraVial
extends Node3D
## 席菈射出來的藥瓶：一道拋物線飛向諾恩的背（她瞄的就是他，一定會中），落在身上就套用那個來源的狀態
## （data/status/statuses.json 的 sources）——反轉的回饋由 StatusEffects.changed 自己觸發，這裡不用管。

const ARC_HEIGHT: float = 1.1
const CHEST_Y: float = 1.15
const LIQUID: Color = Color(0.75, 0.35, 1.0)
## 煙霧彈砸開的那一圈煙：貼著地面從諾恩腳邊往外滾（不往上冒：他站在中間，煙不能蓋住他），滾到 SMOKE_REACH 公尺左右就散掉
const SMOKE_SEC: float = 1.1
const SMOKE_PUFFS: int = 22
const SMOKE_REACH: float = 1.9
const SMOKE_Y: float = 0.3

var target: PlayerController
var source: String = ""
var flight: float = 0.55
var landed: bool = false
## 這一瓶的顏色：資料表的來源有寫 color 就用它（致盲煙霧彈是螢光黃），沒寫是紫的
var liquid: Color = LIQUID
## 砸開會冒一圈煙（資料表的來源寫 "smoke": true：致盲煙霧彈）
var smoky: bool = false
var smoke: CPUParticles3D
var _from: Vector3
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
	v.flight = maxf(CombatTuning.num("sera.vial_flight", 0.55), 0.05)
	v._from = from
	parent.add_child(v)
	v.global_position = from
	return v


func _ready() -> void:
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
	if target == null or not is_instance_valid(target):
		queue_free()
		return
	_t = minf(_t + delta / flight, 1.0)
	var to: Vector3 = target.global_position + Vector3.UP * CHEST_Y
	var p: Vector3 = _from.lerp(to, _t)
	p.y += sin(_t * PI) * ARC_HEIGHT
	global_position = p
	_bottle.rotation.x += delta * 14.0
	if _t >= 1.0:
		_land()


## 砸在諾恩身上：上狀態、玻璃聲、一團藥水往外濺；煙霧彈再加一圈貼地的煙。
func _land() -> void:
	landed = true
	target.status_effects.apply_source(source)
	Sfx.play_at(target, "glass_clink", global_position, -2.0)
	_bottle.visible = false
	_trail.emitting = false
	var splash: CPUParticles3D = _particles(40, 0.5, 3.2, 0.14)
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


## 一圈貼著地面往外滾的煙：一開始衝得快、馬上被拖慢（停在 SMOKE_REACH 附近），邊滾邊變淡。每一團一樣大
## （ParticleLook 的看板材質不看粒子的縮放：scale_amount 設了也沒用）。
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
	fade.offsets = PackedFloat32Array([0.0, 0.12, 0.55, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0.2), Color(1, 1, 1, 0.42), Color(1, 1, 1, 0.26), Color(1, 1, 1, 0)])
	p.color_ramp = fade
	var quad := QuadMesh.new()
	quad.size = Vector2(0.85, 0.85)
	quad.material = ParticleLook.material(liquid.lerp(Color.WHITE, 0.35))
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
