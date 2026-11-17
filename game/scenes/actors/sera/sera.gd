class_name Sera
extends CharacterBody3D
## 席菈（Sera，資產 id sheila）：後排的見習鍊金術師（docs/story/chapter-1.md）。
## 跟在諾恩後面，手上【鍊金藥瓶手弩】；諾恩附近有敵人時每隔幾秒往他背上射一瓶失敗作——對別人是災難，落在諾恩身上就反轉成增益。
## 要做什麼由 SeraBrain 決定（純邏輯、有測試），這裡只管走路、轉身、舉弩、生出藥瓶。
## 不擋路、不會被打（collision_layer＝0）；樹與地形擋得住她。離太遠（被卡住）就直接出現在諾恩後面。
## 她沒有諾恩的體質：瘴氣對她是真的毒，所以靠近瘴氣就把防毒面具戴上（劇本節點 2），離開一下子才拿下來。
## Boss 戰關卡可以叫她站到後排（hold_at）、指定射哪一瓶（shoot）；凝視打到她會被石化一陣子（petrify）。
## 還沒結伴（joined＝false）的時候等在原地：不跟、不射；關卡給了她在看的東西（hesitate_at＝瘴氣）就在它前面走近幾步又退回來，
## 諾恩走近才停下來、轉過來看他。

## 她的名字（翻譯 key；對話資料裡也是這個）
const NAME_KEY: String = "SPK_SHEILA"
const CROSSBOW_MODEL: String = "tripo/weapon_alchemy_crossbow"
const VIAL_SOURCE: String = "sera_paralysis_vial"
## 玩家按鍵向她要的那一瓶：【致盲煙霧彈】（劇本節點 3；落在諾恩身上＝鷹眼）
const ASK_SOURCE: String = "sera_blind_smoke"
const ASK_ACTION: String = "ask_sera"
const TURN_SPEED: float = 8.0
const GRAVITY: float = 18.0
const SNAP_DIST: float = 18.0
## 手弩在手上的擺法（模型的長邊是 +Y、握的地方在原點：scripts/gen_props.sh）
const CROSSBOW_ROT: Vector3 = Vector3(0, 0, 180)
const CROSSBOW_OFFSET: Vector3 = Vector3(0.0, 0.02, 0.0)
## 離瘴氣的邊緣還有這麼遠就先戴上面具；離開之後過這麼久才拿下來（在邊緣走來走去不會一直戴戴脫脫）
const MASK_MARGIN: float = 1.0
const MASK_OFF_DELAY: float = 1.5
## 面具掛在頭的骨頭上：往上、往臉的前面移這麼多（公尺）
const MASK_OFFSET: Vector3 = Vector3(0.0, -0.005, -0.115)
## 還沒結伴時，諾恩走到這麼近她才轉過來
const NOTICE_DIST: float = 9.0
## 猶豫時轉身的速度（比平常慢：看得出她轉過去、又回頭）；還沒轉到這個程度（面向與要走的方向的內積）先不邁步
const HESITATE_TURN_SPEED: float = 5.0
const HESITATE_FACING: float = 0.6
## 被石化時蓋在身上的灰、掉下來的碎屑的顏色
const STONE_COLOR: Color = Color(0.56, 0.57, 0.62)

## 面具戴上／拿下來的那一刻（關卡接這個讓她喊一句）
signal mask_changed(on: bool)
## 玩家向她要一瓶的那一刻。ok＝她答應了（馬上舉弩）；false＝還在裝上一瓶（關卡接這個讓她回一句）
signal asked(ok: bool)
## 要過一瓶之後，她把下一瓶裝好、又可以要了的那一刻
signal reloaded
## 射出一瓶的那一刻（關卡接這個：第一次射某一種的時候讓她喊一句）
signal fired(vial: SeraVial)
## 石化解除的那一刻
signal unpetrified

var brain: SeraBrain = SeraBrain.new()
## 下一瓶射什麼（statuses.json 的來源）；關卡可以換（教學戰的第一瓶是她慌了拿錯的那一瓶）
var vial_source: String = VIAL_SOURCE
## 她自己射的藥照這個順序輪流（空的＝一直射 vial_source）。自由探索的時候關卡給兩種以上：每一瓶反轉成不一樣的增益
var vial_cycle: PackedStringArray = []
var _cycle_i: int = 0
## 玩家按鍵向她要的是哪一瓶（營火那段話之後關卡換成多調一份麻痺的那一瓶）
var ask_source: String = ASK_SOURCE
## 玩家可不可以按鍵向她要藥（關卡照劇情開：教學戰那一瓶拿錯的演完才開）
var ask_enabled: bool = false
var _asked: bool = false
## 結伴了沒（關卡照劇情旗標設）
var joined: bool = true
## 還沒結伴時她想進去又不敢進去的地方（關卡設成瘴氣的位置）；沒設就站著不動
var hesitate_at: Vector3 = Vector3.INF
var _wait_home: Vector3 = Vector3.INF
var _wait_t: float = 0.0
var masked: bool = false
var _mask: Node3D
var _mask_off_in: float = 0.0
## 關卡叫她去某個地方站著、不跟諾恩（Boss 戰她退到後排裝禁藥）。Vector3.INF＝照平常跟著
var hold_at: Vector3 = Vector3.INF
## 去 hold_at 的速度（公尺／秒）；0＝用跑的（Boss 戰）。公會大廳她鼓起勇氣走過來，關卡設得慢一點
var hold_speed: float = 0.0
## true＝手上在忙別的（裝禁藥）：不射平常的藥，玩家也要不到
var hands_full: bool = false
## 站在看不到邊的毒裡（Boss 的疫病光環）：關卡設成 true，她就戴著面具
var force_mask: bool = false
## 被石化還要幾秒（> 0＝整個人不動、身上蓋一層石頭的灰）
var stoned_left: float = 0.0
## 關卡指定要射的那一瓶（shoot）：還要舉弩瞄幾秒（< 0＝沒有）
var _special_in: float = -1.0
var _special_source: String = ""
var _stone_mat: StandardMaterial3D
var target: PlayerController
var vials_fired: int = 0
var last_vial: SeraVial
var _puppet: Puppet
var _crossbow: Node3D
## 手弩收在右腰上（公會大廳：不打架的地方）；false＝拿在右手
var holstered: bool = false:
	set(value):
		holstered = value
		_holster(value)


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.6
	shape.shape = capsule
	shape.position = Vector3(0, 0.8, 0)
	add_child(shape)
	_puppet = Puppet.new()
	_puppet.name = "Puppet"
	_puppet.character_id = "sheila"
	add_child(_puppet)
	ContactShadow.attach(self, 0.5, 0.5)
	_build_crossbow()
	_build_mask()


func puppet() -> Puppet:
	return _puppet


func crossbow() -> Node3D:
	return _crossbow


func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	var to: Vector3 = target.global_position - global_position
	to.y = 0.0
	var dist: float = to.length()
	_update_mask(delta)
	if stoned_left > 0.0:
		stoned_left -= delta
		velocity = Vector3.ZERO
		if stoned_left <= 0.0:
			_set_stoned(false)
			_stone_bits(18, Vector2(1.5, 4.5))
			Sfx.play_at(get_parent(), "rubble_scrape", global_position + Vector3.UP, -4.0, 0.08, 6.0)
			unpetrified.emit()
		return
	if hold_at.is_finite():
		_go_hold(delta, to, dist)
		return
	if joined and dist > SNAP_DIST:
		global_position = target.global_position + Vector3.BACK.rotated(Vector3.UP, target.yaw) * CombatTuning.num("sera.follow_near", 4.5)
		return
	if not joined and dist >= NOTICE_DIST and hesitate_at.is_finite():
		_hesitate(delta)
		return
	var locked: bool = Game.is_player_locked() or not joined
	var speed: float = 0.0 if locked else brain.follow_speed(dist)
	var dir: Vector3 = to / dist if dist > 0.01 else Vector3.ZERO
	velocity = Vector3(dir.x * speed, 0.0 if is_on_floor() else velocity.y - GRAVITY * delta, dir.z * speed)
	move_and_slide()
	_puppet.set_move_speed(speed)
	if dist > 0.3 and (joined or dist < NOTICE_DIST):
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), minf(delta * TURN_SPEED, 1.0))
	if locked:
		return
	_tick_special(delta)
	if hands_full or _special_in >= 0.0:
		return
	if Input.is_action_just_pressed(ASK_ACTION):
		ask()
	var was_aiming: bool = brain.is_aiming()
	var was_loading: bool = brain.ask_left > 0.0
	if brain.tick(delta, threat_near()):
		fire()
	elif brain.is_aiming() and not was_aiming:
		_puppet.play_action("shoot")
	if was_loading and brain.ask_left <= 0.0:
		reloaded.emit()


## 關卡叫她站到 hold_at：跑過去、到了就面向諾恩站著。不跟、不射平常的藥；關卡指定的那一瓶（shoot）照樣舉弩射。
func _go_hold(delta: float, to_target: Vector3, target_dist: float) -> void:
	var step: Vector3 = hold_at - global_position
	step.y = 0.0
	var moving: bool = step.length() > 0.35 and _special_in < 0.0 and not Game.is_player_locked()
	var dir: Vector3 = step.normalized() if moving else (to_target / target_dist if target_dist > 0.01 else Vector3.ZERO)
	var speed: float = (hold_speed if hold_speed > 0.0 else CombatTuning.num("sera.run_speed", 5.6)) if moving else 0.0
	velocity = Vector3(dir.x * speed, 0.0 if is_on_floor() else velocity.y - GRAVITY * delta, dir.z * speed) if moving else Vector3(0.0, 0.0 if is_on_floor() else velocity.y - GRAVITY * delta, 0.0)
	move_and_slide()
	_puppet.set_move_speed(speed)
	if dir.length() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), minf(delta * TURN_SPEED, 1.0))
	_tick_special(delta)


## 關卡指定的那一瓶：舉弩瞄 aim_time 秒後擊發
func _tick_special(delta: float) -> void:
	if _special_in < 0.0 or Game.is_player_locked():
		return
	_special_in -= delta
	if _special_in < 0.0:
		_launch(_special_source)


## 馬上舉弩射一瓶指定的藥（劇情用：Boss 戰的禁藥）。舉弩 aim_time 秒後擊發，一樣發 fired。被石化的時候不射。
func shoot(source: String) -> void:
	if stoned_left > 0.0:
		return
	_special_source = source
	_special_in = CombatTuning.num("sera.aim_time", 0.6)
	_puppet.play_action("shoot")


## 石化（Boss 的凝視打到她）：seconds 秒內整個人不動，手上的事也停了。
func petrify(seconds: float) -> void:
	stoned_left = maxf(seconds, 0.0)
	_special_in = -1.0
	_set_stoned(stoned_left > 0.0)
	if stoned_left > 0.0:
		_stone_bits(8, Vector2(0.6, 1.8))


## 石頭的碎屑從身上掉下來：變成石頭的那一刻掉幾塊、解除的時候整層殼剝落
func _stone_bits(amount: int, speed: Vector2) -> void:
	if is_inside_tree():
		RockDebris.burst(get_parent(), global_position + Vector3.UP * 1.1, Vector3.UP, amount, 0.1, STONE_COLOR, speed)


func is_petrified() -> bool:
	return stoned_left > 0.0


func _exit_tree() -> void:
	# 蓋著石頭的灰被釋放的話，材質會比身上的網格先沒（引擎報「material is null」）：先拿掉
	if _stone_mat != null:
		_set_stoned(false)


## 石頭的灰蓋在身上、動作停在那一格
func _set_stoned(on: bool) -> void:
	if _stone_mat == null:
		_stone_mat = StandardMaterial3D.new()
		_stone_mat.albedo_color = STONE_COLOR
		_stone_mat.roughness = 1.0
	for n: Node in find_children("*", "GeometryInstance3D", true, false):
		(n as GeometryInstance3D).material_overlay = _stone_mat if on else null
	_puppet.set_move_speed(0.0)
	_puppet.set_process(not on)
	if _puppet.anim != null:
		_puppet.anim.speed_scale = 0.0 if on else 1.0


## 還沒結伴、諾恩還沒走近：在原位與瘴氣之間來回（現在想站哪由 SeraBrain.hesitate_goal 決定）。
## 先轉過去再邁步；站著的時候看著瘴氣。
func _hesitate(delta: float) -> void:
	if not _wait_home.is_finite():
		_wait_home = global_position
	_wait_t += delta
	var toward: Vector3 = hesitate_at - _wait_home
	toward.y = 0.0
	toward = toward.normalized()
	var step: Vector3 = _wait_home + toward * SeraBrain.hesitate_goal(_wait_t) - global_position
	step.y = 0.0
	var moving: bool = step.length() > 0.08
	var dir: Vector3 = step.normalized() if moving else toward
	var speed: float = SeraBrain.HESITATE_SPEED if moving and (-global_basis.z).dot(dir) >= HESITATE_FACING else 0.0
	velocity = Vector3(dir.x * speed, 0.0 if is_on_floor() else velocity.y - GRAVITY * delta, dir.z * speed)
	move_and_slide()
	_puppet.set_move_speed(speed)
	rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), minf(delta * HESITATE_TURN_SPEED, 1.0))


## 諾恩附近有沒有活著的敵人
func threat_near() -> bool:
	var reach: float = CombatTuning.num("sera.threat_range", 12.0)
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		var e := n as EnemyActor
		if e != null and not e.health.is_dead() and e.global_position.distance_to(target.global_position) <= reach:
			return true
	return false


## 玩家向她要一瓶（按鍵，或測試直接叫）：她馬上舉弩，這一瓶射的是 ask_source。還沒開放（ask_enabled）就當沒聽到；
## 開放了但她還在裝上一瓶＝不射、回傳 false。
func ask() -> bool:
	if not ask_enabled:
		return false
	var ok: bool = brain.request()
	_asked = _asked or ok
	asked.emit(ok)
	return ok


## 擊發：從弩口生一瓶藥飛向諾恩。玩家要的那一瓶射 ask_source，她自己射的是 vial_source（有 vial_cycle 就輪到下一種）。
func fire() -> SeraVial:
	var vial: SeraVial = _launch(ask_source if _asked else vial_source)
	if not _asked and not vial_cycle.is_empty():
		_cycle_i = (_cycle_i + 1) % vial_cycle.size()
		vial_source = vial_cycle[_cycle_i]
	_asked = false
	return vial


## 從弩口生一瓶 source 飛向諾恩
func _launch(source: String) -> SeraVial:
	vials_fired += 1
	var from: Vector3 = _crossbow.global_position if _crossbow != null else global_position + Vector3.UP * 1.2
	last_vial = SeraVial.launch(get_parent(), from, target, source)
	Sfx.play_at(self, "whoosh", from, -6.0)
	fired.emit(last_vial)
	return last_vial


## 現在站的地方是不是瘴氣裡面（或就在邊上）
func near_miasma() -> bool:
	for n: Node in get_tree().get_nodes_in_group("poison_mist"):
		var mist := n as PoisonMist
		if mist != null and Vector2(mist.global_position.x - global_position.x, mist.global_position.z - global_position.z).length() <= mist.radius + MASK_MARGIN:
			return true
	return false


func _update_mask(delta: float) -> void:
	if force_mask or near_miasma():
		_mask_off_in = MASK_OFF_DELAY
		_set_masked(true)
	elif masked:
		_mask_off_in -= delta
		if _mask_off_in <= 0.0:
			_set_masked(false)


func _set_masked(on: bool) -> void:
	if on == masked:
		return
	masked = on
	if _mask != null:
		_mask.visible = true
		var t: Tween = create_tween()
		t.tween_property(_mask, "scale", Vector3.ONE if on else Vector3.ONE * 0.01, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT if on else Tween.EASE_IN)
		if not on:
			t.tween_callback(_mask.hide)
	mask_changed.emit(on)


func mask() -> Node3D:
	return _mask


## 防毒面具：蓋住口鼻的皮面罩＋兩邊各一個黃銅濾毒罐（中間亮青色的濾芯）。程式拼的；平常收著看不到。
func _build_mask() -> void:
	var head: Node3D = _puppet.joint("head")
	if head == null:
		return
	_mask = Node3D.new()
	_mask.name = "GasMask"
	_mask.position = MASK_OFFSET
	_mask.scale = Vector3.ONE * 0.01
	_mask.visible = false
	head.add_child(_mask)
	var leather := StandardMaterial3D.new()
	leather.albedo_color = Color(0.34, 0.22, 0.15)
	leather.roughness = 0.9
	var brass := StandardMaterial3D.new()
	brass.albedo_color = Color(0.82, 0.63, 0.26)
	brass.metallic = 0.6
	brass.roughness = 0.45
	var core := StandardMaterial3D.new()
	core.albedo_color = Color(0.45, 0.95, 0.85)
	core.emission_enabled = true
	core.emission = Color(0.45, 0.95, 0.85)
	core.emission_energy_multiplier = 1.6
	var muzzle := MeshInstance3D.new()
	var dome := SphereMesh.new()
	dome.radius = 0.07
	dome.height = 0.14
	dome.material = leather
	muzzle.mesh = dome
	muzzle.scale = Vector3(1.0, 0.82, 0.72)
	_mask.add_child(muzzle)
	for side: float in [-1.0, 1.0]:
		var can := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.034
		cyl.bottom_radius = 0.034
		cyl.height = 0.04
		cyl.material = brass
		can.mesh = cyl
		# 罐子的軸朝斜前方（臉頰的方向）
		can.position = Vector3(0.062 * side, -0.012, -0.012)
		can.rotation_degrees = Vector3(90.0, -38.0 * side, 0.0)
		_mask.add_child(can)
		var lens := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 0.022
		disc.bottom_radius = 0.022
		disc.height = 0.006
		disc.material = core
		lens.mesh = disc
		lens.position = Vector3(0.0, -0.022, 0.0)
		can.add_child(lens)
	for n: Node in _mask.find_children("*", "GeometryInstance3D", true, false):
		(n as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## 右手的手弩：有 Tripo 的模型用模型，沒有就用程式拼一把（木頭弩身＋黃銅弓臂＋一管紫色的藥）。
func _build_crossbow() -> void:
	var hand: Node3D = _puppet.hand("R")
	if hand == null:
		return
	_crossbow = Node3D.new()
	_crossbow.name = "Crossbow"
	hand.add_child(_crossbow)
	var model: Node3D = PropModels.instance(CROSSBOW_MODEL)
	if model == null:
		model = _stand_in_crossbow()
	model.name = "Model"
	model.rotation_degrees = CROSSBOW_ROT
	model.position = CROSSBOW_OFFSET
	_crossbow.add_child(model)
	_holster(holstered)


## 收在右腰上的樣子（骨盆的掛點的座標：+X 右、+Y 上、+Z 背後）：弩口朝下掛著
const HOLSTER_AT: Vector3 = Vector3(0.22, -0.02, 0.04)


func _holster(on: bool) -> void:
	if _crossbow == null or _puppet == null:
		return
	var holder: Node3D = _puppet.joint("hips") if on else _puppet.hand("R")
	if holder == null or _crossbow.get_parent() == holder:
		return
	_crossbow.get_parent().remove_child(_crossbow)
	holder.add_child(_crossbow)
	_crossbow.transform = Transform3D(Basis.IDENTITY, HOLSTER_AT) if on else Transform3D.IDENTITY


static func _stand_in_crossbow() -> Node3D:
	var root := Node3D.new()
	for part: Array in [
		[Vector3(0.05, 0.36, 0.06), Vector3(0, 0.12, 0), Color(0.4, 0.26, 0.15)],
		[Vector3(0.34, 0.03, 0.03), Vector3(0, 0.27, 0), Color(0.75, 0.6, 0.25)],
		[Vector3(0.05, 0.12, 0.05), Vector3(0, 0.16, 0.05), Color(0.7, 0.35, 1.0)],
	]:
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = part[0] as Vector3
		var mat := StandardMaterial3D.new()
		mat.albedo_color = part[2] as Color
		box.material = mat
		mesh.mesh = box
		mesh.position = part[1] as Vector3
		root.add_child(mesh)
	return root
