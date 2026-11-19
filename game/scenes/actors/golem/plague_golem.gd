class_name PlagueGolem
extends EnemyActor
## 【深淵疫病魔像】（第一章 Boss，docs/story/chapter-1.md 節點 3）：很大、很慢、打不斷。兩招輪流——重拳（前方一塊）與震地（身邊一大圈）；
## 身邊一圈是疫病光環（PlagueAura：全能力下降＋失血——對諾恩是全能力提升＋回血）。
## 生命掉到一半狂暴（GolemPhases）：吼一聲 → 出招變快、變痛 → 轉向席菈擺【石化凝視】的前兆（地上一道光從牠連到她）→ 凝視打出去：
## 全場石化（諾恩是霸體無敵）。諾恩站在那道光上＝擋在席菈前面：她沒事、魔像力竭跪下；沒擋到她被石化，過一陣子再來一次。
## 核心（胸口）在席菈的禁藥落到諾恩身上之前打不碎：生命扣到 hp_floor 就扣不下去；之後諾恩的下一刀直接粉碎核心。
## 外型：Tripo 的雙足模型，跟人物走同一條轉檔（scripts/gen_art.sh，Puppet 的 character_id＝plague_golem，3.6 m 高）；模型不在時是放大的程式人偶。
## 動作（tools/blender/common.py 的 monster_actions，D-303）：走路、右手直拳（重拳）、兩手舉過頭砸下去（震地、睡著時舉著的拳頭）、
## 吼、凝視的前兆、單膝跪地（力竭、倒下前）、被砍的那一下。出招舉到頂停住等前兆走完，剩 0.19 秒才打下去。
## 倒下：跪 → 兩膝著地、整個上身垂下去（collapse）→ 崩成一堆碎石（RubblePile，留在關卡上），不再沉進地面消失。
## 演出（都是看得到的回饋，不改規則）：被諾恩砍中整個身體頓一下、掉石屑、身上的光亮一下；胸口的核心一直有一點光，
## 生命扣到底線打不下去的時候閃一圈（「核心還在」），open_core() 之後變成金色、一圈一圈往中心收（「砍這裡」）；
## 凝視的前兆眼睛越來越亮，打出去是一道從眼睛射出去的光＋掃過全場的一圈；粉碎的那一刀核心炸成碎片；倒地之後核心滾出來。

## 開始吼（狂暴）、開始擺凝視的前兆、凝視打出去（blocked＝諾恩擋住了）、核心被粉碎的那一刀、倒地之後核心滾出來（掛在關卡上的那一顆）
signal enraged
signal gaze_started
signal gaze_fired(blocked: bool)
signal core_shattered
signal core_dropped(core: GolemCore)

const CHARACTER_ID: String = "plague_golem"
const NAME_KEY: String = "BOSS_PLAGUE_GOLEM"
const GAZE_SOURCE: String = "petrify_gaze"
const STAND_IN_SCALE: float = 2.0
## 被砍的那一下（flinch 動作）最少隔幾秒才再演一次：連砍的時候一直從頭演會抖
const FLINCH_GAP: float = 0.9
## 倒下：跪下去停在跪著的那一刻（kneel 動作的第幾秒）、跪多久才垮下去、垮到底（collapse 動作的第幾秒：兩手與頭垂到地上的那一聲）、
## 垮完停在哪一刻、垮完之後停多久才崩成碎石、崩多久
const DOWN_KNEEL_AT: float = 0.5
const DOWN_KNEEL_SEC: float = 1.2
const DOWN_SLUMP_SEC: float = 0.9
const DOWN_REST_AT: float = 1.95
const DOWN_LIE_SEC: float = 1.6
const DOWN_CRUMBLE_SEC: float = 1.4
## 平常是毒的螢光綠，狂暴之後變成橘紅
const RAGE_COLOR: Color = Color(1.0, 0.32, 0.12)
const GAZE_COLOR: Color = Color(0.74, 0.5, 1.0)
const BLOCKED_COLOR: Color = Color(1.0, 0.82, 0.36)
const EYE_HEIGHT: float = 3.25
## 魔像的聲音（scripts/gen_sfx.py）：醒來與狂暴的吼、凝視的前兆與打出去、重拳與震地（倒地也是）、腳步、
## 核心亮起來、打不下去、粉碎核心、核心落地
const ROAR_SFX: String = "golem_roar"
const GAZE_CHARGE_SFX: String = "gaze_charge"
const GAZE_BEAM_SFX: String = "gaze_beam"
const SLAM_SFX: String = "golem_slam"
const STEP_SFX: String = "golem_step"
const CORE_GLOW_SFX: String = "core_glow"
const DEFLECT_SFX: String = "stone_deflect"
const CORE_SHATTER_SFX: String = "core_shatter"
const CORE_LAND_SFX: String = "core_land"
## 最近發出的聲音（測試用；最多留這麼多個）
const HEARD_MAX: int = 24
const BEAM_WIDTH: float = 2.2
const BEAM_Y: float = 0.07
const BEAM_SHADER: Shader = preload("res://src/world/gaze_beam.gdshader")
const FLARE_SHADER: Shader = preload("res://src/world/core_flare.gdshader")
## 眼睛在頭的骨頭前面多遠、上面多高
const EYE_OFFSET: Vector3 = Vector3(0.0, 0.15, -0.55)
## 凝視打出去的那道光：多粗、多久收掉；掃過全場的那一圈擴到多大
const RAY_WIDTH: float = 1.3
const RAY_SEC: float = 0.4
const GAZE_WAVE_RADIUS: float = 30.0
## 胸口的核心（模型上那顆紫色的晶石）：在胸口的骨頭前面多遠（剛好在晶石的表面：再往前，從側面看那團光會浮在胸口前面的半空中）；
## 沒有模型時離地多高
const CORE_FORWARD: float = 0.6
const CORE_HEIGHT: float = 2.35
## 那片光多大（公尺）：平常、可以粉碎了
const CORE_SIZE: float = 1.6
const CORE_OPEN_SIZE: float = 2.4
const CORE_COLOR: Color = Color(0.72, 0.42, 1.0)
const CORE_OPEN_COLOR: Color = Color(1.0, 0.8, 0.35)
const STONE_COLOR: Color = Color(0.4, 0.43, 0.4)
## 石堆從牠腳下往後多遠開始鋪（往前鋪 RubblePile.LENGTH：垮下去的上身與兩手在前面）
const RUBBLE_BACK: float = 1.4
## 被諾恩砍中的那一下（不是後仰——牠打不斷）：整個身體往後頓多遠、仰多少、身上的光多亮幾倍，多久退掉
const JOLT_SEC: float = 0.22
const JOLT_PUSH: float = 0.2
const JOLT_LEAN: float = 0.08
const JOLT_GLOW: float = 2.4
## 被砍掉的石屑：幾塊、多大（公尺）——0.18 m 的八塊在玩的距離只是幾顆灰點
const CHIP_COUNT: int = 12
const CHIP_SIZE: float = 0.3

## 最近發出的聲音（_sound 記的；測試用）
var heard: Array[String] = []
var phases: GolemPhases
## false＝還沒醒（抵達的那段話講完之前）：舉著拳頭站在原地，不追人、不出招、不扣血
var awake: bool = false
## 凝視瞄的人（席菈）；關卡設
var gaze_target: Node3D
## 光環（關卡生出來掛在牠身上）
var aura: PlagueAura
## 滾出來的核心可以停在哪裡（關卡給：func(p: Vector3) -> bool；不在柱子上、不在石板外、不壓到躺著的人）。沒給＝哪裡都可以
var core_clear: Callable = Callable()
var _puppet: Puppet
var _swung: bool = false
## 上一次演被砍的動作之後過了幾秒
var _since_flinch: float = 99.0
## 倒下之後崩成的那一堆碎石（掛在關卡上；測試用）
var rubble: RubblePile
var _eye: OmniLight3D
var _beam: MeshInstance3D
var _beam_mat: ShaderMaterial
var _raged: bool = false
var _eye_flare: MeshInstance3D
var _eye_mat: ShaderMaterial
var _core: MeshInstance3D
var _core_mat: ShaderMaterial
var _core_light: OmniLight3D
var _core_t: float = 0.0
## 核心閃一下（打不下去、剛開）：1 → 0 很快退掉
var _core_kick: float = 0.0
## 被砍的那一下：1 → 0；往哪邊頓（世界座標，水平）
var _jolt: float = 0.0
var _jolt_dir: Vector3 = Vector3.ZERO
## 打不下去的那一圈閃過幾次、被砍頓過幾次（測試用）
var ward_count: int = 0
var jolt_count: int = 0
## 倒下那一刻面向哪裡（水平）：垮下去的那一聲、核心、石堆都照這個方向擺
var _fall_fwd: Vector3 = Vector3.FORWARD


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
	_puppet.footfall.connect(func() -> void: _sound(STEP_SFX, global_position, -3.0, 8.0, self))
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
	_build_flares()


## 發出一個聲音、記下來（測試看 heard）。on：掛在誰底下（預設關卡——魔像沉下去之後還聽得完）。
func _sound(sfx_name: String, at: Vector3, volume_db: float, unit_size: float, on: Node = null) -> void:
	heard.append(sfx_name)
	if heard.size() > HEARD_MAX:
		heard.remove_at(0)
	Sfx.play_at(on if on != null else get_parent(), sfx_name, at, volume_db, 0.03, unit_size)


## 醒過來，開始追諾恩（關卡在抵達的那段話講完時叫）
func wake() -> void:
	if awake:
		return
	awake = true
	_puppet.release_hold()
	_sound(ROAR_SFX, global_position + Vector3.UP * EYE_HEIGHT, 2.0, 14.0, self)
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
			_puppet.play_action("gaze", phases.gaze_sec)
			_sound(GAZE_CHARGE_SFX, global_position + Vector3.UP * EYE_HEIGHT, 0.0, 12.0, self)
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
	_sound(ROAR_SFX, global_position + Vector3.UP * EYE_HEIGHT, 4.0, 14.0, self)
	_puppet.play_action("roar", phases.roar_sec)
	if _player != null and is_instance_valid(_player):
		_player.shake(0.5)
	enraged.emit()


## 凝視打出去：全場石化——諾恩一定中（對他是霸體無敵）；席菈中不中看諾恩有沒有擋在中間（關卡接 gaze_fired 處理她）。
func _fire_gaze() -> void:
	var blocked: bool = is_gaze_blocked()
	phases.resolve_gaze(blocked)
	_flash(GAZE_COLOR, 14.0, 0.5)
	_gaze_fx(blocked)
	_sound(GAZE_BEAM_SFX, global_position + Vector3.UP * EYE_HEIGHT, 3.0, 14.0, self)
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
	_core_mat.set_shader_parameter("flare_color", CORE_OPEN_COLOR)
	_core_mat.set_shader_parameter("open", 1.0)
	_core.scale = Vector3.ONE * CORE_OPEN_SIZE
	_core_light.light_color = CORE_OPEN_COLOR
	_core_kick = 1.0
	if is_inside_tree():
		_ring(core_point(), _toward_viewer(core_point()), CORE_OPEN_COLOR, 0.4, 3.0, 0.45, 0.04)
		_sound(CORE_GLOW_SFX, core_point(), 2.0, 12.0)


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
	var src: Node3D = info.get("source") as Node3D
	if src is PlayerController and is_inside_tree():
		_on_cut(src.global_position)
	if bool(info.get("shatter", false)):
		_flash(BLOCKED_COLOR, 10.0, 0.8, 0.5)
		_shatter_fx(src.global_position if src != null and is_instance_valid(src) else global_position + forward())
		core_shattered.emit()


## 被諾恩砍中的那一下：身體頓一下、掉幾塊石屑。生命已經在底線（核心還在、扣不下去）：胸口的核心閃一圈、一聲鐵響——「這樣打不死」。
func _on_cut(from: Vector3) -> void:
	jolt_count += 1
	_jolt = 1.0
	# 手上沒在出招、沒在吼／凝視／跪：演一下被砍往後一抽（不改狀態機——牠還是打不斷）
	if _since_flinch >= FLINCH_GAP and _puppet.action in ["", "flinch"] and brain.state in [EnemyBrain.State.CHASE, EnemyBrain.State.RECOVER] \
			and phases.phase not in [GolemPhases.Phase.ROAR, GolemPhases.Phase.GAZE]:
		_since_flinch = 0.0
		_puppet.play_action("flinch")
	_jolt_dir = -hit_dir(from)
	RockDebris.burst(get_parent(), hit_point(from), hit_dir(from) + Vector3.UP * 0.7, CHIP_COUNT, CHIP_SIZE, STONE_COLOR, Vector2(3.0, 6.5))
	if not phases.core_open and health.min_hp > 0.0 and health.hp <= health.min_hp + 0.5:
		ward_count += 1
		_core_kick = 1.0
		_ring(core_point(), _toward_viewer(core_point()), CORE_COLOR, 0.3, 1.9, 0.3, 0.05)
		_sound(DEFLECT_SFX, core_point(), -2.0, 8.0)


## 粉碎核心的那一刀：胸口那片光炸掉——紫色與金色的晶片、石塊往出手的人那一側噴，一圈金色的環往外擴。
func _shatter_fx(from: Vector3) -> void:
	var at: Vector3 = core_point()
	var out: Vector3 = hit_dir(from)
	var parent: Node = get_parent()
	RockDebris.burst(parent, at, out + Vector3.UP * 0.5, 30, 0.2, CORE_COLOR, Vector2(4.0, 11.0), 3.0)
	RockDebris.burst(parent, at, out + Vector3.UP * 0.8, 16, 0.14, CORE_OPEN_COLOR, Vector2(5.0, 12.0), 4.0)
	RockDebris.burst(parent, at, out * 0.4 + Vector3.UP, 22, 0.34, STONE_COLOR, Vector2(3.0, 8.0))
	_ring(at, out, CORE_OPEN_COLOR, 0.5, 6.0, 0.55, 0.04)
	_ring(global_position + Vector3.UP * 0.12, Vector3.UP, CORE_OPEN_COLOR, 1.0, 9.0, 0.6)
	_sound(CORE_SHATTER_SFX, at, 4.0, 16.0)


func _on_strike() -> void:
	var origin: Vector3 = global_position
	var fwd: Vector3 = forward()
	var id: String = brain.move_id
	var damage: float = brain.move_num(id, "damage", 26.0) * (CombatTuning.num("plague_golem.rage_damage", 1.3) if _raged else 1.0)
	if id == "slam":
		var radius: float = brain.move_num(id, "radius", 5.4)
		_sound(SLAM_SFX, origin + fwd * 1.5 + Vector3.UP * 0.3, 3.0, 10.0, self)
		_ground_puff(origin + fwd * 1.6, Vector3(1.6, 0.05, 1.6), 40, Color(0.6, 0.62, 0.66, 0.6))
		_ring(origin + Vector3.UP * 0.1, Vector3.UP, RAGE_COLOR if _raged else RIM_COLOR, 1.0, radius, 0.35)
		hit_heartbeats(damage, "slam", func(p: Vector3) -> bool: return Vector2(p.x - origin.x, p.z - origin.z).length() <= radius)
	else:
		var reach: float = brain.move_num(id, "reach", 4.6)
		var arc: float = brain.move_num(id, "arc_deg", 80.0)
		_sound(SLAM_SFX, origin + fwd * 2.4 + Vector3.UP * 0.3, 0.0, 8.0, self)
		_ground_puff(origin + fwd * 3.0, Vector3(0.7, 0.05, 0.7), 22, Color(0.6, 0.62, 0.66, 0.6))
		hit_heartbeats(damage, "punch", func(p: Vector3) -> bool: return PlayerController.in_strike_arc(origin, fwd, p, reach, arc))
	if _player != null and is_instance_valid(_player) and _player.global_position.distance_to(origin) < 12.0:
		_player.shake(0.3 if id == "slam" else 0.18)


## 走路照速度播；前兆往後仰、快打到的時候開始揮；吼＝往後仰、凝視＝往前探（眼睛越來越亮）；跪（失衡、力竭）＝整個人矮下去往前垂。
func _update_look() -> void:
	if _puppet == null:
		return
	var dt: float = get_physics_process_delta_time()
	_update_flares(dt)
	if not awake:
		# 兩手舉過頭等在那裡（劇本：雷歐等人絕望地看著魔像舉起巨拳）；醒來就砸下去
		if _puppet.action == "":
			_puppet.hold_action("hammer", float(Puppet.MONSTER_APEX["hammer"]))
		return
	_since_flinch += dt
	_puppet.set_move_speed(Vector2(velocity.x, velocity.z).length())
	var windup: float = brain.telegraph_progress()
	var glow: float = lerpf(1.0, GLOW_WINDUP, windup)
	match brain.state:
		EnemyBrain.State.TELEGRAPH:
			if not _swung:
				_swung = true
				_puppet.wind_up("hammer" if brain.move_id == "slam" else "punch", brain.telegraph_sec)
			elif _puppet.is_holding() and brain.telegraph_sec - brain.time_in_state <= Puppet.STRIKE_LEAD:
				_puppet.release_hold()
		EnemyBrain.State.STAGGERED:
			glow = 0.5
	if brain.state not in [EnemyBrain.State.TELEGRAPH, EnemyBrain.State.STRIKE]:
		_swung = false
		if _puppet.is_holding():
			# 舉到頂等著的時候前兆被取消了（又沒有別的動作接手）：放下來
			_puppet.stop_action()
	var gaze: float = phases.gaze_progress()
	if phases.phase in [GolemPhases.Phase.ROAR, GolemPhases.Phase.GAZE]:
		glow = GLOW_WINDUP
	_eye.light_energy = 9.0 * gaze
	_update_beam(gaze)
	# 被砍的那一下疊在上面（不經過下面那個慢慢跟上的 lerp，不然看不出來）：往後頓、仰一點、身上的光亮一下
	_jolt = move_toward(_jolt, 0.0, dt / JOLT_SEC)
	var jolt: float = _jolt * _jolt
	var push: Vector3 = _body.global_basis.inverse() * _jolt_dir * (JOLT_PUSH * jolt)
	_puppet.rotation.x = JOLT_LEAN * jolt
	_puppet.position = Vector3(push.x, 0.0, push.z)
	if not health.is_dead():
		_set_glow(glow + JOLT_GLOW * jolt)


## 倒下：先單膝跪下、胸口炸開一團光，再兩膝著地、整個上身往前垂下去（原地垮掉；以前是跪姿整個往後轉 76°，折著的腿翻到半空中，D-306）、
## 停一下，最後崩成一堆碎石（身體沉下去、石堆從牠腳下拱上來；石堆留在關卡上）。比一般敵人久。
## 垮完之前照樣擋路：粉碎核心的那一刀會往前滑一步，不擋的話諾恩會滑進牠的身體裡。
func _on_died() -> void:
	var f: Vector3 = forward()
	_fall_fwd = Vector3(f.x, 0.0, f.z).normalized() if Vector2(f.x, f.z).length() > 0.01 else Vector3.FORWARD
	_begin_death()
	collision_layer = 1
	_beam.visible = false
	_eye.light_energy = 0.0
	_eye_flare.visible = false
	# 胸口那片光：粉碎的那一刀亮一下，很快熄掉（之後 _update_look 不跑了，自己收）
	_core_mat.set_shader_parameter("strength", 2.0)
	var out: Tween = _core.create_tween()
	out.tween_method(func(v: float) -> void:
		_core_mat.set_shader_parameter("strength", v)
		_core_light.light_energy = v * 2.0, 2.0, 0.0, 0.3)
	out.tween_callback(_core.hide)
	if aura != null:
		aura.active = false
	_ground_puff(global_position + Vector3.UP * _hit_height(), Vector3(0.8, 0.8, 0.8), 60, Color(0.75, 1.0, 0.6, 0.8))
	# 單膝跪下去、停在跪著的那一刻（_update_look 不跑了，Puppet 自己播）
	_puppet.play_action("kneel")
	_puppet.pause_at(DOWN_KNEEL_AT)
	var t := create_tween()
	_fall_tween = t
	t.tween_interval(DOWN_KNEEL_SEC)
	t.tween_callback(func() -> void:
		_puppet.play_action("collapse")
		_puppet.pause_at(DOWN_REST_AT))
	t.tween_interval(DOWN_SLUMP_SEC)
	t.tween_callback(_on_fall_impact)
	t.tween_interval(DOWN_LIE_SEC)
	t.tween_callback(_crumble)
	t.tween_property(_body, "position:y", -2.6, DOWN_CRUMBLE_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_callback(queue_free)


## 崩成一堆碎石：身體往下沉（_on_died 的 tween）的同時，石堆從牠垮著的地方拱上來（腳下往前鋪）、揚起一大團灰、石塊往上噴。
## 石堆掛在關卡上（牠被釋放之後還在），擋路的換成石堆。
func _crumble() -> void:
	collision_layer = 0
	if not is_inside_tree():
		return
	rubble = RubblePile.create()
	get_parent().add_child(rubble)
	rubble.global_position = global_position - _fall_fwd * RUBBLE_BACK
	rubble.face_along(_fall_fwd)
	rubble.grow(DOWN_CRUMBLE_SEC * 0.8)
	var mid: Vector3 = global_position + _fall_fwd * 0.3
	_sound(SLAM_SFX, mid, -1.0, 10.0)
	RockDebris.burst(get_parent(), mid + Vector3.UP * 0.5, Vector3.UP, 26, 0.32, STONE_COLOR, Vector2(1.5, 4.5))
	var dust: CPUParticles3D = puff_build(Vector3(1.2, 0.3, 1.9), 60, Color(0.62, 0.64, 0.66, 0.7))
	dust.lifetime = 2.2
	dust.initial_velocity_max = 1.6
	dust.scale_amount_max = 2.6
	# 灰掛在關卡上（牠沉下去、被釋放之後還要飄完）
	get_parent().add_child(dust)
	dust.global_position = mid
	dust.emitting = true
	dust.finished.connect(dust.queue_free)


## 跪下（失衡滿了、凝視被擋下來力竭）：單膝跪地的動作照跪多久整段縮放播
func _on_kneel() -> void:
	super._on_kneel()
	if awake and not health.is_dead():
		_puppet.play_action("kneel", brain.kneel_sec())


func _on_fall_impact() -> void:
	has_fallen = true
	if is_inside_tree():
		_sound(SLAM_SFX, global_position, 4.0, 12.0)
		RockDebris.burst(get_parent(), global_position + _fall_fwd * 1.1 + Vector3.UP * 0.6, Vector3.UP, 18, 0.3, STONE_COLOR, Vector2(2.0, 6.0))
		_drop_core()
	_ground_puff(global_position + _fall_fwd * 1.1, Vector3(1.8, 0.05, 1.8), 50, Color(0.6, 0.62, 0.66, 0.65))
	if _player != null and is_instance_valid(_player):
		_player.shake(0.6)


## 倒下那一刻面向哪裡（水平）
func fall_direction() -> Vector3:
	return _fall_fwd


## 核心滾出來可以停的地方（牠的座標：x＝往牠的左手邊、y＝往前，公尺）。依序試、clear 說可以的第一個：
## 先試牠左手邊前面＝站在牠面前的諾恩的右手邊（過肩鏡頭在諾恩右後方，畫面右邊是空的；左邊是狀態列），再試右手邊、正前方偏一點、近一點的
const CORE_SPOTS: Array[Vector2] = [Vector2(2.9, 1.5), Vector2(-2.9, 1.5), Vector2(2.0, 2.7), Vector2(-2.0, 2.7),
	Vector2(2.4, 0.2), Vector2(-2.4, 0.2), Vector2(1.6, 1.2), Vector2(-1.6, 1.2)]
## 落地的那一點在停下來的那一點的這個比例（從牠腳下算）：落地之後再滾剩下的那一段
const CORE_LAND_AT: float = 0.6


## 核心滾出來停在哪裡（牠倒在 at、面向 fwd）。clear＝那裡可不可以停（關卡給）：停的地方、落地的地方、兩者中間都要可以；
## 都不行就照第一個（沒有關卡的測試也是第一個）。讀檔回來也照這個算（同樣的輸入、同樣的答案）
static func core_rest_spot(at: Vector3, fwd: Vector3, clear: Callable = Callable()) -> Vector3:
	var first := Vector3.INF
	for o: Vector2 in CORE_SPOTS:
		var rest: Vector3 = _core_spot(at, fwd, o)
		if not first.is_finite():
			first = rest
		if not clear.is_valid():
			return rest
		var land: Vector3 = core_land_spot(at, rest)
		if bool(clear.call(rest)) and bool(clear.call(land)) and bool(clear.call(land.lerp(rest, 0.5))):
			return rest
	return first


static func _core_spot(at: Vector3, fwd: Vector3, o: Vector2) -> Vector3:
	var side: Vector3 = -fwd.cross(Vector3.UP)
	var rest: Vector3 = at + fwd * o.y + side * o.x
	rest.y = at.y + GolemCore.RADIUS
	return rest


## 從胸口彈出來落在哪裡（停下來的那一點的 CORE_LAND_AT）
static func core_land_spot(at: Vector3, rest: Vector3) -> Vector3:
	var land: Vector3 = at + (rest - at) * CORE_LAND_AT
	land.y = rest.y
	return land


## 垮到底的那一下，核心從胸口彈出來：拋到牠腳邊、滾一小段停住（停在哪裡照 core_rest_spot：避開柱子、石板邊、躺著的人）。
## 掛在關卡上（魔像沉下去之後它還在；關卡接 core_dropped）。
func _drop_core() -> void:
	var core: GolemCore = GolemCore.create()
	var level: Node = get_parent()
	level.add_child(core)
	var from: Vector3 = global_position + _fall_fwd * 0.9 + Vector3.UP * 1.3
	var rest: Vector3 = core_rest_spot(global_position, _fall_fwd, core_clear)
	var land: Vector3 = core_land_spot(global_position, rest)
	core.global_position = from
	var t: Tween = core.create_tween()
	t.tween_method(func(k: float) -> void:
		core.global_position = from.lerp(land, k) + Vector3.UP * (4.0 * 1.6 * k * (1.0 - k)), 0.0, 1.0, 0.6)
	t.tween_callback(func() -> void:
		_sound(CORE_LAND_SFX, land, 2.0, 8.0, level))
	t.tween_property(core, "global_position", rest, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# 滾：繞著跟前進方向垂直的水平軸轉
	var roll_axis: Vector3 = Vector3.UP.cross((rest - land).normalized()).normalized()
	t.parallel().tween_method(func(a: float) -> void:
		core.ball.basis = Basis(roll_axis, a), 0.0, land.distance_to(rest) / GolemCore.RADIUS, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	core_dropped.emit(core)


## 很短的一盞強光（凝視打出去、核心粉碎）：掛在關卡上，自己收掉。fog＝照亮霧的程度（粉碎那一刀調低：整個畫面被霧洗白就看不到碎片了）
func _flash(color: Color, energy: float, seconds: float, fog: float = 3.0) -> void:
	if not is_inside_tree():
		return
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = 26.0
	light.shadow_enabled = false
	light.light_volumetric_fog_energy = fog
	get_parent().add_child(light)
	light.global_position = global_position + Vector3.UP * 2.6
	var t: Tween = light.create_tween()
	t.tween_property(light, "light_energy", 0.0, seconds).set_ease(Tween.EASE_OUT)
	t.tween_callback(light.queue_free)


## 一圈往外擴、邊擴邊淡掉的環（加法混色）：axis＝環面朝哪（Vector3.UP＝平貼地面：震地、掃過全場的凝視；朝鏡頭＝立著的一圈：核心）。
## from、to＝半徑（公尺）；thick＝環有多粗（半徑的幾成：立著的環正對著鏡頭，要細一點）。掛在關卡上，自己收掉。
func _ring(at: Vector3, axis: Vector3, color: Color, from: float, to: float, seconds: float, thick: float = 0.1) -> void:
	if not is_inside_tree():
		return
	var ring := MeshInstance3D.new()
	ring.name = "GolemRing"
	var torus := TorusMesh.new()
	torus.inner_radius = 1.0 - thick
	torus.outer_radius = 1.0
	torus.rings = 48
	torus.ring_segments = 6
	ring.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(color.r * 2.0, color.g * 2.0, color.b * 2.0, 1.0)
	ring.material_override = mat
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# 同名的兄弟節點要引擎編成 GolemRing2、GolemRing3（不要 @MeshInstance3D@123 那種看不懂的名字）
	get_parent().add_child(ring, true)
	# 環的軸（網格的 Y）對著 axis；壓扁成一片
	var y: Vector3 = axis.normalized() if axis.length() > 0.01 else Vector3.UP
	var x: Vector3 = y.cross(Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	ring.global_transform = Transform3D(Basis(x, y, x.cross(y)), at)
	ring.scale = Vector3(from, 0.3, from)
	var t: Tween = ring.create_tween()
	t.tween_property(ring, "scale", Vector3(to, 0.3, to), seconds).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.parallel().tween_property(mat, "albedo_color:a", 0.0, seconds * 1.15).set_ease(Tween.EASE_IN)
	t.tween_callback(ring.queue_free)


## 從 at 指向玩家的鏡頭（立著的環要面向看的人）；沒有鏡頭就朝牠的正面
func _toward_viewer(at: Vector3) -> Vector3:
	var cam: Camera3D = get_viewport().get_camera_3d() if is_inside_tree() else null
	return cam.global_position - at if cam != null else forward()


## 胸口的核心與眼睛：各一片面向鏡頭的光（core_flare.gdshader）。跟著骨頭走（每一幀擺到 core_point()／eye_point()），不掛在骨頭底下——
## 模型有縮放，掛上去大小會跟著變。
func _build_flares() -> void:
	_core = _flare("CoreFlare", CORE_COLOR, CORE_SIZE)
	_core_mat = _core.material_override as ShaderMaterial
	_core_light = OmniLight3D.new()
	_core_light.light_color = CORE_COLOR
	_core_light.light_energy = 0.0
	_core_light.omni_range = 5.0
	_core_light.shadow_enabled = false
	_core.add_child(_core_light)
	_eye_flare = _flare("EyeFlare", GAZE_COLOR, 1.0)
	_eye_mat = _eye_flare.material_override as ShaderMaterial
	_eye_flare.visible = false


func _flare(node_name: String, color: Color, size: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = QuadMesh.new()
	var mat := ShaderMaterial.new()
	mat.shader = FLARE_SHADER
	mat.set_shader_parameter("flare_color", color)
	mat.set_shader_parameter("strength", 0.0)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.top_level = true
	mi.scale = Vector3.ONE * size
	add_child(mi)
	return mi


## 核心這一刻在世界的哪裡（胸口的晶石前面）
func core_point() -> Vector3:
	var chest: Node3D = _puppet.joint("chest") if _puppet != null else null
	# 往前的方向用整個身體的（Puppet 的 −Z）：骨頭掛點自己的軸每個模型不一樣
	if chest != null and chest.is_inside_tree():
		return chest.global_position + _puppet.global_basis.orthonormalized() * Vector3(0.0, 0.0, -CORE_FORWARD)
	return global_transform * (_body.transform * Vector3(0.0, CORE_HEIGHT, -CORE_FORWARD)) if _body != null else global_position


## 眼睛這一刻在世界的哪裡
func eye_point() -> Vector3:
	var head: Node3D = _puppet.joint("head") if _puppet != null else null
	if head != null and head.is_inside_tree():
		return head.global_position + _puppet.global_basis.orthonormalized() * EYE_OFFSET
	return global_transform * (_body.transform * Vector3(0.0, EYE_HEIGHT, -0.9)) if _body != null else global_position


## 核心現在多亮（測試用）；可以粉碎了＝金色、一圈一圈往中心收
func core_strength() -> float:
	return float(_core_mat.get_shader_parameter("strength"))


func is_core_marked() -> bool:
	return _core.visible and phases.core_open


func _update_flares(delta: float) -> void:
	_core_t += delta
	_core_kick = move_toward(_core_kick, 0.0, delta / 0.3)
	var open: bool = phases.core_open
	var pulse: float = 0.5 + 0.5 * sin(_core_t * (10.0 if open else 2.2))
	var level: float = (0.9 + 0.5 * pulse if open else 0.28 + 0.12 * pulse) + _core_kick * 1.2
	_core.global_position = core_point()
	_core_mat.set_shader_parameter("strength", level)
	_core_light.light_energy = level * (2.4 if open else 1.2)
	var gaze: float = phases.gaze_progress()
	_eye_flare.visible = gaze > 0.0
	if gaze > 0.0:
		_eye_flare.global_position = eye_point()
		_eye_flare.scale = Vector3.ONE * lerpf(0.9, 2.6, gaze)
		_eye_mat.set_shader_parameter("strength", lerpf(0.5, 2.2, gaze))


## 凝視打出去：一道光從眼睛射到凝視的人身上——諾恩擋住了就停在他身上、炸一圈金色；沒擋住就打到席菈。
## 同時一圈蒼白的紫從牠腳下掃過全場（「全場石化」）。
func _gaze_fx(blocked: bool) -> void:
	if not is_inside_tree():
		return
	# 掃過全場的那一圈：細、暗一點（擴到 30 m 的環照平常的粗細與亮度，是一條蓋掉半個畫面的白帶子）
	_ring(global_position + Vector3.UP * 0.12, Vector3.UP, GAZE_COLOR * 0.45, 1.5, GAZE_WAVE_RADIUS, 0.7, 0.025)
	var hit: Node3D = _player if blocked else gaze_target
	if hit == null or not is_instance_valid(hit):
		return
	var from: Vector3 = eye_point()
	var to: Vector3 = hit.global_position + Vector3.UP * 1.1
	var along: Vector3 = to - from
	if along.length() < 0.3:
		return
	var ray := MeshInstance3D.new()
	ray.name = "GazeRay"
	var quad := PlaneMesh.new()
	quad.size = Vector2(1.0, 1.0)
	ray.mesh = quad
	var mat := ShaderMaterial.new()
	mat.shader = BEAM_SHADER
	mat.set_shader_parameter("beam_color", GAZE_COLOR)
	mat.set_shader_parameter("charge", 1.0)
	mat.set_shader_parameter("solid", 1.0)
	ray.material_override = mat
	ray.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_parent().add_child(ray, true)
	# 面片的 Z 沿著那道光、X 是寬（跟「往鏡頭」垂直：光帶正對著看的人）
	var z: Vector3 = along.normalized()
	var x: Vector3 = z.cross(_toward_viewer(from.lerp(to, 0.5))).normalized()
	if x.length() < 0.01:
		x = z.cross(Vector3.UP).normalized()
	ray.global_transform = Transform3D(Basis(x, z.cross(x), z), from.lerp(to, 0.5))
	ray.scale = Vector3(RAY_WIDTH, 1.0, along.length())
	var t: Tween = ray.create_tween()
	t.tween_property(ray, "scale:x", 0.05, RAY_SEC).set_ease(Tween.EASE_IN)
	t.tween_callback(ray.queue_free)
	_ring(to, -along, BLOCKED_COLOR if blocked else GAZE_COLOR, 0.3, 2.4 if blocked else 1.6, 0.4, 0.05)


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
