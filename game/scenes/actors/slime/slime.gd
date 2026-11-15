class_name Slime
extends EnemyActor
## 劇毒史萊姆（第一章教學戰，docs/story/chapter-1.md 節點 2）：慢慢靠近、蓄力壓扁、往前撲撞。
## 撞到人除了傷害還上中毒（data/status/statuses.json 的 slime_touch）——對諾恩來說那是回血。
## 外型：Tripo 的模型（建置時 scripts/gen_props.sh 擺正成 0.8 m 高）；檔案不在就用一顆半透明的球。
## 牠是紫的、森林的霧也是紫的，所以身上多一圈螢光綠的邊、腳下一盞綠的小燈（毒的顏色）：
## 從紫霧裡看得出牠在哪；蓄力要撲的時候兩樣一起變亮。

const MODEL: String = "tripo/enemy_poison_slime"
const BODY_RADIUS: float = 0.45
const TOUCH_SOURCE: String = "slime_touch"
const LUNGE_SPEED: float = 5.0
## 輪廓的綠邊：借「硬撐的紅光」那個 shader（邊緣最亮的一層加法光），掛在材質的 next_pass——
## material_overlay 留給硬撐的紅光，兩樣可以同時亮。
const RIM_SHADER: Shader = preload("res://src/world/brace_glow.gdshader")
const RIM_COLOR: Color = Color(0.35, 1.0, 0.2)
## 只留細細的一圈：邊太寬的話綠光疊在紫色上，整隻變成一顆白的泡泡
const RIM_FILL: float = 0.0
const RIM_EDGE: float = 1.3
const RIM_POWER: float = 4.5
## 腳下的綠光（照地面與旁邊的人，不照牠自己：燈在身體裡面）
## 放低、範圍小：染綠的是地面，不是站在旁邊的人的臉
const GLOW_ENERGY: float = 1.1
const GLOW_RANGE: float = 2.2
const GLOW_Y: float = 0.15
## 蓄力蓄滿時亮到平常的幾倍
const GLOW_WINDUP: float = 2.0
const GLOW_OUT_SEC: float = 0.35

var _lunge_dir: Vector3 = Vector3.ZERO
var _look: Node3D
var _rim: ShaderMaterial
var _glow: OmniLight3D
var _glow_level: float = 1.0


func tuning_id() -> String:
	return "poison_slime"


func _head_height() -> float:
	return 1.0


## 命中點在身體中間（預設是人的胸口 1.05 m，比史萊姆整隻還高：閃光與刀痕會飄在牠頭上）
func _hit_height() -> float:
	return BODY_RADIUS


func _hit_radius() -> float:
	return BODY_RADIUS


func _build_body() -> void:
	super._build_body()
	var shape := CollisionShape3D.new()
	var ball := SphereShape3D.new()
	ball.radius = BODY_RADIUS
	shape.shape = ball
	shape.position = Vector3(0, BODY_RADIUS, 0)
	add_child(shape)
	ContactShadow.attach(self, 0.7, 0.5)
	_look = PropModels.instance(MODEL)
	if _look == null:
		var mesh := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = BODY_RADIUS
		sphere.height = BODY_RADIUS * 1.6
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.55, 0.3, 0.85, 0.85)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = Color(0.3, 0.9, 0.2)
		mat.emission_energy_multiplier = 0.3
		sphere.material = mat
		mesh.mesh = sphere
		mesh.position = Vector3(0, BODY_RADIUS * 0.8, 0)
		_look = mesh
	_look.name = "Look"
	_body.add_child(_look)
	_add_glow()


## 身上的綠邊現在多亮（平常 1、蓄滿 GLOW_WINDUP、倒下後 0）、腳下的燈、蓋了幾塊（測試用）。
func glow_level() -> float:
	return _glow_level


func glow_light() -> OmniLight3D:
	return _glow


func rim_surface_count() -> int:
	var n: int = 0
	for mi: MeshInstance3D in _look_meshes():
		for surface: int in mi.mesh.get_surface_count():
			var mat: Material = mi.get_surface_override_material(surface)
			if mat != null and mat.next_pass == _rim:
				n += 1
	return n


func _look_meshes() -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if _look is MeshInstance3D:
		out.append(_look as MeshInstance3D)
	for n: Node in _look.find_children("*", "MeshInstance3D", true, false):
		out.append(n as MeshInstance3D)
	return out


func _add_glow() -> void:
	_rim = ShaderMaterial.new()
	_rim.shader = RIM_SHADER
	_rim.set_shader_parameter("glow_color", RIM_COLOR)
	_rim.set_shader_parameter("fill", RIM_FILL)
	_rim.set_shader_parameter("rim", RIM_EDGE)
	_rim.set_shader_parameter("rim_power", RIM_POWER)
	for mi: MeshInstance3D in _look_meshes():
		for surface: int in mi.mesh.get_surface_count():
			var src: Material = mi.get_active_material(surface)
			if src == null:
				continue
			var mat: Material = src.duplicate()
			mat.next_pass = _rim
			mi.set_surface_override_material(surface, mat)
	_glow = OmniLight3D.new()
	_glow.name = "Glow"
	_glow.light_color = RIM_COLOR
	_glow.light_energy = GLOW_ENERGY
	_glow.omni_range = GLOW_RANGE
	_glow.omni_attenuation = 1.3
	_glow.shadow_enabled = false
	_glow.position = Vector3(0, GLOW_Y, 0)
	add_child(_glow)
	health.died.connect(_glow_out)


func _set_glow(level: float) -> void:
	_glow_level = level
	_rim.set_shader_parameter("strength", level)
	_glow.light_energy = GLOW_ENERGY * level


## 倒下：綠光跟著熄掉（身體還要躺一下才沉下去）
func _glow_out() -> void:
	create_tween().tween_method(_set_glow, _glow_level, 0.0, GLOW_OUT_SEC)


## 出招的那一刻：記下往哪撲、判定前方的人。
func _on_strike() -> void:
	_lunge_dir = forward()
	Sfx.play_at(self, "whoosh", global_position + Vector3.UP * 0.4, -8.0)
	var origin: Vector3 = global_position
	var fwd: Vector3 = _lunge_dir
	var reach: float = brain.attack_range + 0.5
	var hit: int = hit_heartbeats(CombatTuning.num("poison_slime.bump_damage", 10.0), "bump",
		func(p: Vector3) -> bool: return PlayerController.in_strike_arc(origin, fwd, p, reach, 120.0))
	if hit > 0 and _player != null and is_instance_valid(_player) and PlayerController.in_strike_arc(origin, fwd, _player.global_position, reach, 120.0):
		_player.status_effects.apply_source(TOUCH_SOURCE)


func _on_strike_tick(_delta: float) -> Vector3:
	return _lunge_dir * LUNGE_SPEED


## 蓄力時壓扁、出招時拉長；跪著（失衡）時攤平。
func _update_look() -> void:
	if _look == null:
		return
	var squash: float = 1.0 - 0.35 * brain.telegraph_progress()
	if brain.state == EnemyBrain.State.STRIKE:
		squash = 1.2
	elif brain.state == EnemyBrain.State.STAGGERED:
		squash = 0.5
	var wide: float = 1.0 / sqrt(maxf(squash, 0.1))
	_look.scale = _look.scale.lerp(Vector3(wide, squash, wide), 0.25)
	if not health.is_dead():
		_set_glow(lerpf(1.0, GLOW_WINDUP, brain.telegraph_progress()))
