class_name PlagueGolem
extends EnemyActor
## 【深淵疫病魔像】（第一章 Boss，docs/story/chapter-1.md 節點 3）：很大、很慢、打不斷。兩招輪流——重拳（前方一塊）與震地（身邊一大圈）；
## 身邊一圈是疫病光環（PlagueAura：全能力下降＋失血——對諾恩是全能力提升＋回血）。
## 生命掉到一半狂暴（GolemPhases）：吼一聲 → 出招變快、變痛 → 轉向席菈擺【石化凝視】的前兆（地上一道光從牠連到她）→ 凝視打出去：
## 全場石化（諾恩是霸體無敵）。諾恩站在那道光上＝擋在席菈前面：她沒事、魔像力竭跪下；沒擋到她被石化，過一陣子再來一次。
## 核心（胸口）在席菈的禁藥落到諾恩身上之前打不碎：生命扣到 hp_floor 就扣不下去；之後諾恩的下一刀直接粉碎核心。
## 外型：Tripo 的雙足模型，跟人物走同一條轉檔（scripts/gen_art.sh，Puppet 的 character_id＝plague_golem，3.6 m 高）；模型不在時是放大的程式人偶。
## 動作用 Puppet 現成的：走路、出手的第一段（重拳）與第三段（震地）；吼、凝視、跪下是整個人前後仰。

## 開始吼（狂暴）、開始擺凝視的前兆、凝視打出去（blocked＝諾恩擋住了）、核心被粉碎的那一刀
signal enraged
signal gaze_started
signal gaze_fired(blocked: bool)
signal core_shattered

const CHARACTER_ID: String = "plague_golem"
const NAME_KEY: String = "BOSS_PLAGUE_GOLEM"
const GAZE_SOURCE: String = "petrify_gaze"
const STAND_IN_SCALE: float = 2.0
## Puppet 的出手動作開始之後這麼久才「打到」
const SWING_LEAD: float = 0.19
## 還沒醒：舉著拳頭停在出手動作的這一刻
const LOOM_AT: float = 0.1
const LEAN_BACK: float = 0.16
const LEAN_SLAM: float = -0.24
const LEAN_ROAR: float = 0.3
const LEAN_GAZE: float = -0.18
## 平常是毒的螢光綠，狂暴之後變成橘紅
const RAGE_COLOR: Color = Color(1.0, 0.32, 0.12)
const GAZE_COLOR: Color = Color(0.74, 0.5, 1.0)
const BLOCKED_COLOR: Color = Color(1.0, 0.82, 0.36)
const EYE_HEIGHT: float = 3.25
const BEAM_WIDTH: float = 2.2
const BEAM_Y: float = 0.07
const BEAM_SHADER: Shader = preload("res://src/world/gaze_beam.gdshader")

var phases: GolemPhases
## false＝還沒醒（抵達的那段話講完之前）：舉著拳頭站在原地，不追人、不出招、不扣血
var awake: bool = false
## 凝視瞄的人（席菈）；關卡設
var gaze_target: Node3D
## 光環（關卡生出來掛在牠身上）
var aura: PlagueAura
var _puppet: Puppet
var _swung: bool = false
var _eye: OmniLight3D
var _beam: MeshInstance3D
var _beam_mat: ShaderMaterial
var _raged: bool = false


func tuning_id() -> String:
	return "plague_golem"


func camera_fade_range() -> Vector2:
	return Vector2(1.4, 2.6)


func _head_height() -> float:
	return 3.7


func _hit_height() -> float:
	return 1.7


func _hit_radius() -> float:
	return 1.0


func puppet() -> Puppet:
	return _puppet


func _ready() -> void:
	super._ready()
	add_to_group("boss")
	phases = GolemPhases.new().configure(tuning_id())
	focus_player = true


func _build_body() -> void:
	super._build_body()
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 1.0
	capsule.height = 3.2
	shape.shape = capsule
	shape.position = Vector3(0, 1.6, 0)
	add_child(shape)
	ContactShadow.attach(self, 2.2, 0.6)
	_puppet = Puppet.new()
	_puppet.name = "Puppet"
	_puppet.character_id = CHARACTER_ID
	_body.add_child(_puppet)
	if not _puppet.uses_model():
		_puppet.scale = Vector3.ONE * STAND_IN_SCALE
	_puppet.footfall.connect(func() -> void: Sfx.play_at(self, "step_heavy", global_position, -4.0))
	add_toxic_glow(_puppet, 7.0)
	_eye = OmniLight3D.new()
	_eye.name = "Eye"
	_eye.light_color = GAZE_COLOR
	_eye.light_energy = 0.0
	_eye.omni_range = 9.0
	_eye.shadow_enabled = false
	_eye.light_volumetric_fog_energy = 2.0
	_eye.position = Vector3(0, EYE_HEIGHT, -0.9)
	_body.add_child(_eye)
	_build_beam()


## 醒過來，開始追諾恩（關卡在抵達的那段話講完時叫）
func wake() -> void:
	if awake:
		return
	awake = true
	_puppet.release_hold()
	if aura != null:
		aura.active = true


## 還沒醒、吼、擺凝視的時候不跑狀態機（不追人、不出招）。階段也在這裡往前走——每個物理幀都會被叫到。
func _held(delta: float) -> bool:
	if not awake:
		return true
	_tick_phases(delta)
	if phases.phase == GolemPhases.Phase.GAZE and gaze_target != null and is_instance_valid(gaze_target):
		var d: Vector3 = gaze_target.global_position - global_position
		_body.rotation.y = lerp_angle(_body.rotation.y, atan2(-d.x, -d.z), clampf(4.0 * delta, 0.0, 1.0))
	return phases.phase in [GolemPhases.Phase.ROAR, GolemPhases.Phase.GAZE]


func _tick_phases(delta: float) -> void:
	health.min_hp = health.max_hp * phases.floor_ratio()
	match phases.tick(delta, health.ratio()):
		"enrage":
			_enrage()
		"gaze":
			brain.break_off()
			Sfx.play_at(self, "brace_warn", global_position + Vector3.UP * EYE_HEIGHT, 0.0, 0.03, 12.0)
			gaze_started.emit()
		"fire":
			_fire_gaze()


## 狂暴：手上的招停下來、吼一聲，之後每一招的前兆與破綻變短、傷害變高，身上的光從綠變橘紅。
func _enrage() -> void:
	brain.break_off()
	_raged = true
	var k: float = CombatTuning.num("plague_golem.rage_speed", 0.75)
	for id: Variant in brain.moves:
		var m: Dictionary = brain.moves[id] as Dictionary
		m["telegraph"] = float(m.get("telegraph", 0.9)) * k
		m["recover"] = float(m.get("recover", 1.2)) * k
	if _rim != null:
		_rim.set_shader_parameter("glow_color", RAGE_COLOR)
		_glow.light_color = RAGE_COLOR
	Sfx.play_at(self, "brace_warn", global_position + Vector3.UP * 2.0, 2.0, 0.03, 14.0)
	if _player != null and is_instance_valid(_player):
		_player.shake(0.5)
	enraged.emit()


## 凝視打出去：全場石化——諾恩一定中（對他是霸體無敵）；席菈中不中看諾恩有沒有擋在中間（關卡接 gaze_fired 處理她）。
func _fire_gaze() -> void:
	var blocked: bool = is_gaze_blocked()
	phases.resolve_gaze(blocked)
	_flash(GAZE_COLOR, 14.0, 0.5)
	Sfx.play_at(self, "curse_sting", global_position + Vector3.UP * EYE_HEIGHT, 3.0, 0.03, 14.0)
	if _player != null and is_instance_valid(_player) and not _player.health.is_dead():
		_player.status_effects.apply_source(GAZE_SOURCE)
		_player.shake(0.45)
	if blocked:
		# 被擋下來：力竭跪下（這段時間砍牠算砍在破綻上）
		brain.force_kneel(phases.spent_sec)
	gaze_fired.emit(blocked)


## 這一刻諾恩有沒有擋在牠跟凝視的目標中間
func is_gaze_blocked() -> bool:
	if gaze_target == null or not is_instance_valid(gaze_target) or _player == null or not is_instance_valid(_player):
		return false
	return GolemPhases.blocks(global_position, gaze_target.global_position, _player.global_position, phases.block_width)


## 核心可以粉碎了（席菈的禁藥落在諾恩身上；關卡叫）
func open_core() -> void:
	phases.core_open = true
	health.min_hp = 0.0


## 諾恩的劍砍在開了的核心上：這一刀直接粉碎（不管原本多痛）。其他照共用的算（Boss 不會硬撐）。
func _damage_scale(info: Dictionary) -> float:
	if not awake:
		return 0.0
	if phases.core_open and info.get("source") is PlayerController and info.has("cut"):
		info["shatter"] = true
		return 100000.0
	return super._damage_scale(info)


func _on_damaged(amount: float, info: Dictionary) -> void:
	super._on_damaged(amount, info)
	if bool(info.get("shatter", false)):
		_flash(BLOCKED_COLOR, 18.0, 0.8)
		core_shattered.emit()


func _on_strike() -> void:
	var origin: Vector3 = global_position
	var fwd: Vector3 = forward()
	var id: String = brain.move_id
	var damage: float = brain.move_num(id, "damage", 26.0) * (CombatTuning.num("plague_golem.rage_damage", 1.3) if _raged else 1.0)
	if id == "slam":
		var radius: float = brain.move_num(id, "radius", 5.4)
		Sfx.play_at(self, "blunt_weak", origin + fwd * 1.5 + Vector3.UP * 0.3, 2.0)
		_ground_puff(origin + fwd * 1.6, Vector3(1.6, 0.05, 1.6), 40, Color(0.6, 0.62, 0.66, 0.6))
		_shockwave(radius)
		hit_heartbeats(damage, "slam", func(p: Vector3) -> bool: return Vector2(p.x - origin.x, p.z - origin.z).length() <= radius)
	else:
		var reach: float = brain.move_num(id, "reach", 4.6)
		var arc: float = brain.move_num(id, "arc_deg", 80.0)
		Sfx.play_at(self, "blunt_weak", origin + fwd * 2.4 + Vector3.UP * 0.3, 0.0)
		_ground_puff(origin + fwd * 3.0, Vector3(0.7, 0.05, 0.7), 22, Color(0.6, 0.62, 0.66, 0.6))
		hit_heartbeats(damage, "punch", func(p: Vector3) -> bool: return PlayerController.in_strike_arc(origin, fwd, p, reach, arc))
	if _player != null and is_instance_valid(_player) and _player.global_position.distance_to(origin) < 12.0:
		_player.shake(0.3 if id == "slam" else 0.18)


## 走路照速度播；前兆往後仰、快打到的時候開始揮；吼＝往後仰、凝視＝往前探（眼睛越來越亮）；跪（失衡、力竭）＝整個人矮下去往前垂。
func _update_look() -> void:
	if _puppet == null:
		return
	if not awake:
		# 舉著拳頭等在那裡（劇本：雷歐等人絕望地看著魔像舉起巨拳）
		if _puppet.action == "":
			_puppet.attack_variant = 2
			_puppet.hold_action("attack", LOOM_AT)
		return
	_puppet.set_move_speed(Vector2(velocity.x, velocity.z).length())
	var windup: float = brain.telegraph_progress()
	var lean: float = LEAN_BACK * windup
	var drop: float = 0.0
	var glow: float = lerpf(1.0, GLOW_WINDUP, windup)
	match brain.state:
		EnemyBrain.State.TELEGRAPH:
			if not _swung and brain.telegraph_sec - brain.time_in_state <= SWING_LEAD:
				_swung = true
				_puppet.attack_variant = 2 if brain.move_id == "slam" else 0
				_puppet.play_action("attack")
		EnemyBrain.State.STRIKE, EnemyBrain.State.RECOVER:
			lean = LEAN_SLAM if brain.state == EnemyBrain.State.STRIKE or brain.time_in_state < 0.4 else 0.0
		EnemyBrain.State.STAGGERED:
			lean = -0.45
			drop = -0.8
			glow = 0.5
	if brain.state not in [EnemyBrain.State.TELEGRAPH, EnemyBrain.State.STRIKE]:
		_swung = false
	var gaze: float = phases.gaze_progress()
	match phases.phase:
		GolemPhases.Phase.ROAR:
			lean = LEAN_ROAR * sin(clampf(phases.time_in_phase / phases.roar_sec, 0.0, 1.0) * PI)
			glow = GLOW_WINDUP
		GolemPhases.Phase.GAZE:
			lean = LEAN_GAZE * gaze
			glow = GLOW_WINDUP
	_eye.light_energy = 9.0 * gaze
	_update_beam(gaze)
	_puppet.rotation.x = lerp_angle(_puppet.rotation.x, lean, 0.16)
	_puppet.position.y = lerpf(_puppet.position.y, drop, 0.16)
	if not health.is_dead():
		_set_glow(glow)


## 倒下：先跪、胸口炸開一團光，再往後仰倒（不往前趴——諾恩就站在牠面前）、躺一下、最後沉進地面。比一般敵人久。
## 垮完之前照樣擋路：粉碎核心的那一刀會往前滑一步，不擋的話諾恩會滑進牠的身體裡。
func _on_died() -> void:
	_begin_death()
	collision_layer = 1
	_beam.visible = false
	_eye.light_energy = 0.0
	if aura != null:
		aura.active = false
	_ground_puff(global_position + Vector3.UP * _hit_height(), Vector3(0.8, 0.8, 0.8), 60, Color(0.75, 1.0, 0.6, 0.8))
	var t := create_tween()
	_fall_tween = t
	t.tween_property(_body, "position:y", -0.7, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_interval(0.5)
	t.tween_property(_body, "rotation_degrees:x", -FALL_FORWARD * 76.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(_body, "position:y", 0.35, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(_on_fall_impact)
	t.tween_interval(3.5)
	t.tween_callback(func() -> void: collision_layer = 0)
	t.tween_property(_body, "position:y", -4.5, 2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_callback(queue_free)


func _on_fall_impact() -> void:
	has_fallen = true
	if is_inside_tree():
		Sfx.play_at(get_parent(), "blunt", global_position, 0.0, 0.03)
	_ground_puff(global_position - forward() * 1.6, Vector3(1.8, 0.05, 1.8), 50, Color(0.6, 0.62, 0.66, 0.65))
	if _player != null and is_instance_valid(_player):
		_player.shake(0.6)


## 很短的一盞強光（凝視打出去、核心粉碎）：掛在關卡上，自己收掉
func _flash(color: Color, energy: float, seconds: float) -> void:
	if not is_inside_tree():
		return
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = 26.0
	light.shadow_enabled = false
	light.light_volumetric_fog_energy = 3.0
	get_parent().add_child(light)
	light.global_position = global_position + Vector3.UP * 2.6
	var t: Tween = light.create_tween()
	t.tween_property(light, "light_energy", 0.0, seconds).set_ease(Tween.EASE_OUT)
	t.tween_callback(light.queue_free)


## 震地：腳邊一圈往外擴的環（擴到打得到的那麼大）
func _shockwave(radius: float) -> void:
	if not is_inside_tree():
		return
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.9
	torus.outer_radius = 1.0
	torus.rings = 48
	torus.ring_segments = 6
	ring.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	var c: Color = RAGE_COLOR if _raged else RIM_COLOR
	mat.albedo_color = Color(c.r * 2.0, c.g * 2.0, c.b * 2.0, 1.0)
	ring.material_override = mat
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.scale = Vector3(1.0, 0.3, 1.0)
	get_parent().add_child(ring)
	ring.global_position = global_position + Vector3.UP * 0.1
	var t: Tween = ring.create_tween()
	t.tween_property(ring, "scale", Vector3(radius, 0.3, radius), 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.4).set_ease(Tween.EASE_IN)
	t.tween_callback(ring.queue_free)


## 凝視的前兆：地上一道光從魔像連到席菈（「站到這道光上」）。諾恩擋住的時候變成金色。
func _build_beam() -> void:
	_beam = MeshInstance3D.new()
	_beam.name = "GazeBeam"
	var quad := PlaneMesh.new()
	quad.size = Vector2(1.0, 1.0)
	_beam.mesh = quad
	_beam_mat = ShaderMaterial.new()
	_beam_mat.shader = BEAM_SHADER
	_beam.material_override = _beam_mat
	_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_beam.top_level = true
	_beam.visible = false
	add_child(_beam)


func is_beam_shown() -> bool:
	return _beam.visible


func _update_beam(gaze: float) -> void:
	var on: bool = gaze > 0.0 and gaze_target != null and is_instance_valid(gaze_target)
	_beam.visible = on
	if not on:
		return
	var a: Vector3 = global_position
	var b: Vector3 = gaze_target.global_position
	var d := Vector3(b.x - a.x, 0.0, b.z - a.z)
	if d.length() < 0.2:
		_beam.visible = false
		return
	# 面片的 Z 軸沿著「魔像 → 席菈」，長度＝兩人的距離
	var basis: Basis = Basis(Vector3.UP, atan2(d.x, d.z)) * Basis.from_scale(Vector3(BEAM_WIDTH, 1.0, d.length()))
	_beam.global_transform = Transform3D(basis, Vector3((a.x + b.x) * 0.5, BEAM_Y, (a.z + b.z) * 0.5))
	_beam_mat.set_shader_parameter("beam_color", BLOCKED_COLOR if is_gaze_blocked() else GAZE_COLOR)
	_beam_mat.set_shader_parameter("charge", gaze)
