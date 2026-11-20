class_name WebTrap
extends Node3D
## 麻痺蜘蛛網（docs/story/chapter-1.md 時段 B 的陷阱）：兩根枯枝中間掛一張網。諾恩碰到網的那一刻套用來源
## （data/status/statuses.json 的 web_snare：麻痺＋緩速——對他是出手加速＋跑得更快），網被他撞破：絲往他衝過去的方向
## 扯開、散成一把碎絲，只剩兩根枯枝；MEND_SEC 秒後網重新長回來，他走開了才會再黏一次（站在原地不會一直疊）。
## 破掉的網不算擋路（席菈繞開的是還完整的網：`is_intact()`，群組 GROUP）。
## 模型是 Tripo 的（網沿著自己的 Z 軸張開；建置時把淡黃綠的絲拆成節點 "Silk"，scripts/gen_props.sh）；
## 檔案不在就用兩根木樁＋一片半透明的網（也叫 "Silk"）。

signal snared(by: PlayerController)

const MODEL: String = "tripo/prop_paralysis_web_v2"
## 網從中心往兩邊各張開多寬、離網多近算碰到、走開多遠才會再黏一次（公尺）
const HALF_SPAN: float = 1.15
const TOUCH: float = 0.5
const REARM: float = 1.6
## 撞進網裡：黏黏的絲被扯開＋網被拉長又彈回來
const SNARE_SFX: String = "web_stick"
## 撞破之後幾秒長回來；扯開（被拉長再縮掉）要多久、長回來要多久
const MEND_SEC: float = 6.0
const TEAR_SEC: float = 0.22
const GROW_SEC: float = 0.7
const GROUP: String = "webs"
const SILK_NODE: String = "Silk"
const SHRED_COLOR: Color = Color(0.86, 0.9, 0.7)

var source_id: String = "web_snare"
## 黏到過幾次（測試用）
var snares: int = 0
## 撞破了還要幾秒長回來（0＝網是完整的）
var mend_in: float = 0.0
var _armed: bool = true
var _look: Node3D
var _silk: Node3D
var _shreds: CPUParticles3D
var _tween: Tween


## yaw＝網張開的方向（弧度；0＝沿著 Z 軸，橫跨一條東西向的路）
static func create(node_name: String, at: Vector3, yaw: float) -> WebTrap:
	var w := WebTrap.new()
	w.name = node_name
	w.position = at
	w.rotation.y = yaw
	return w


func _ready() -> void:
	add_to_group(GROUP)
	_look = PropModels.instance(MODEL)
	if _look == null:
		_look = _stand_in()
	_look.name = "Look"
	add_child(_look)
	_silk = _look.find_child(SILK_NODE, true, false) as Node3D
	if _silk == null:
		_silk = _look  # 舊的模型（絲沒拆開）：整個一起扯
	_shreds = _shred_burst()
	add_child(_shreds)


func _physics_process(delta: float) -> void:
	if mend_in > 0.0:
		mend_in = maxf(mend_in - delta, 0.0)
		if mend_in <= 0.0:
			_grow_back()
	var p: PlayerController = get_tree().get_first_node_in_group("player") as PlayerController
	if p == null or p.health.is_dead() or Game.is_player_locked():
		return
	var dist: float = distance_to_web(p.global_position)
	if _armed and is_intact() and dist < TOUCH:
		_armed = false
		snares += 1
		p.status_effects.apply_source(source_id)
		Sfx.play_at(self, SNARE_SFX, p.global_position + Vector3.UP, -4.0)
		_tear(p)
		snared.emit(p)
	elif not _armed and dist > REARM:
		_armed = true


## 網還完整（沒被撞破、已經長回來）
func is_intact() -> bool:
	return mend_in <= 0.0


## 撞破：網往他衝過來的那一面鼓出去、被拉長，然後縮掉不見，碎絲往那個方向散開
func _tear(by: Node3D) -> void:
	mend_in = MEND_SEC
	var push: float = signf(global_basis.x.dot(by.global_position - global_position))
	var through: Vector3 = -global_basis.x * (push if push != 0.0 else 1.0)
	_shreds.position = to_local(by.global_position + Vector3.UP * 1.1)
	_shreds.direction = global_basis.inverse() * through
	_shreds.restart()
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	if _silk == _look:
		_tween.tween_property(_look, "scale", Vector3(1.0, 0.94, 1.12), 0.07)
		_tween.tween_property(_look, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		return
	var home: Vector3 = _silk.position
	_silk.set_meta("home", home)
	var out: Vector3 = _look.global_basis.inverse() * through * 0.35
	_tween.tween_property(_silk, "position", home + out, TEAR_SEC * 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(_silk, "scale", Vector3(1.25, 0.9, 1.05), TEAR_SEC * 0.4)
	_tween.tween_property(_silk, "scale", Vector3(0.15, 0.05, 0.6), TEAR_SEC * 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.parallel().tween_property(_silk, "position", home + out * 1.6 + Vector3.DOWN * 0.4, TEAR_SEC * 0.6)
	_tween.tween_callback(func() -> void:
		_silk.visible = false
		_silk.position = home
		_silk.scale = Vector3.ONE)


## 長回來：從中間一圈一圈織開（小的彈到原本的大小）
func _grow_back() -> void:
	if _silk == _look:
		return
	if _tween != null:
		_tween.kill()
	_silk.visible = true
	_silk.position = _silk.get_meta("home", _silk.position)
	_silk.scale = Vector3(0.1, 0.1, 0.1)
	_tween = create_tween()
	_tween.tween_property(_silk, "scale", Vector3.ONE, GROW_SEC).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## 撞破的那一刻散開的碎絲：細長的淡黃綠小片，往衝過去的方向飛、慢慢飄落
static func _shred_burst() -> CPUParticles3D:
	var ps := CPUParticles3D.new()
	ps.name = "Shreds"
	ps.emitting = false
	ps.one_shot = true
	ps.explosiveness = 0.95
	ps.amount = 26
	ps.lifetime = 1.1
	ps.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	ps.emission_box_extents = Vector3(0.1, 0.7, HALF_SPAN * 0.7)
	ps.direction = Vector3.LEFT
	ps.spread = 55.0
	ps.gravity = Vector3(0, -2.2, 0)
	ps.damping_min = 2.0
	ps.damping_max = 4.0
	ps.initial_velocity_min = 1.4
	ps.initial_velocity_max = 3.4
	ps.angular_velocity_min = -360.0
	ps.angular_velocity_max = 360.0
	ps.particle_flag_align_y = true
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.7, 1.0])
	fade.colors = PackedColorArray([Color.WHITE, Color.WHITE, Color(1, 1, 1, 0)])
	ps.color_ramp = fade
	var quad := QuadMesh.new()
	quad.size = Vector2(0.025, 0.22)
	quad.material = ParticleLook.material(SHRED_COLOR, false)
	ps.mesh = quad
	ps.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return ps


## 這個位置離網多遠（水平；網是一條線段）
func distance_to_web(p: Vector3) -> float:
	var e: PackedVector2Array = ends()
	var here := Vector2(p.x, p.z)
	return here.distance_to(Geometry2D.get_closest_point_to_segment(here, e[0], e[1]))


## 網的兩頭（水平的 x、z）
func ends() -> PackedVector2Array:
	var along: Vector3 = global_basis.z * HALF_SPAN
	return PackedVector2Array([Vector2(global_position.x - along.x, global_position.z - along.z),
		Vector2(global_position.x + along.x, global_position.z + along.z)])


static func _stand_in() -> Node3D:
	var root := Node3D.new()
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.28, 0.2, 0.2)
	for side: float in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.05
		cyl.bottom_radius = 0.09
		cyl.height = 2.6
		cyl.material = wood
		post.mesh = cyl
		post.position = Vector3(0.0, 1.3, side * HALF_SPAN)
		root.add_child(post)
	var web := MeshInstance3D.new()
	web.name = SILK_NODE
	var quad := QuadMesh.new()
	quad.size = Vector2(HALF_SPAN * 2.0, 2.0)
	var silk := StandardMaterial3D.new()
	silk.albedo_color = Color(0.9, 0.92, 1.0, 0.35)
	silk.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	silk.cull_mode = BaseMaterial3D.CULL_DISABLED
	quad.material = silk
	web.mesh = quad
	web.position = Vector3(0.0, 1.3, 0.0)
	web.rotation.y = PI * 0.5
	root.add_child(web)
	return root
