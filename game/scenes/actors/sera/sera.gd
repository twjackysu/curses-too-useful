class_name Sera
extends CharacterBody3D
## 席菈（Sera，資產 id sheila）：後排的見習鍊金術師（docs/story/chapter-1.md）。
## 跟在諾恩後面，手上【鍊金藥瓶手弩】；諾恩附近有敵人時每隔幾秒往他背上射一瓶失敗作——對別人是災難，落在諾恩身上就反轉成增益。
## 要做什麼由 SeraBrain 決定（純邏輯、有測試），這裡只管走路、轉身、舉弩、生出藥瓶。
## 不擋路、不會被打（collision_layer＝0）；樹與地形擋得住她。離太遠（被卡住）就直接出現在諾恩後面。
## 她沒有諾恩的體質：瘴氣對她是真的毒，所以走到瘴氣邊上先停下來慌張地找防毒面具、戴上（劇本節點 2），離開一下子才拿下來。
## Boss 戰關卡可以叫她站到後排（hold_at）、指定射哪一瓶（shoot）；凝視打到她會被石化一陣子（petrify）。
## 還沒結伴（joined＝false）的時候等在原地：不跟、不射；關卡給了她在看的東西（hesitate_at＝瘴氣）就在它前面走近幾步又退回來，
## 諾恩走近才停下來、轉過來看他。

## 她的名字（翻譯 key；對話資料裡也是這個）
## 石化解除：身上的石殼裂開、剝落
const UNSTONE_SFX: String = "stone_peel"
const NAME_KEY: String = "SPK_SHEILA"
const CROSSBOW_MODEL: String = "tripo/weapon_alchemy_crossbow"
const VIAL_SOURCE: String = "sera_paralysis_vial"
## 玩家按鍵向她要的那一瓶：【致盲煙霧彈】（劇本節點 3；落在諾恩身上＝鷹眼）
const ASK_SOURCE: String = "sera_blind_smoke"
const ASK_ACTION: String = "ask_sera"
## 換要哪一瓶（可以要的有第二瓶的時候）
const SWITCH_ACTION: String = "switch_sera_vial"
const TURN_SPEED: float = 8.0
const GRAVITY: float = 18.0
const SNAP_DIST: float = 18.0
## 手弩在手上的擺法。模型（scripts/gen_props.sh）：弩身沿 +Y、前端的金色弓臂在 −Y、木頭的槍托往 −X 斜伸出去，
## 原點在弩身中段（不是槍托）。手的掛點：−Y＝往指尖、−Z＝大拇指那一側。
## 照拿手槍的樣子擺：弩身順著前臂、弓臂朝指尖那一頭（往前），槍托從大拇指那一側往小指那一側穿過手心（模型 −X → 手 +Z）＝繞 Y 轉 90°；
## 再把槍托靠上面那一段（模型 (−0.13, 0.13)）移到手心。在 Blender 裡從側面算圖量的（11/19）。
const CROSSBOW_ROT: Vector3 = Vector3(0, 90, 0)
const CROSSBOW_OFFSET: Vector3 = Vector3(0.0, -0.13, -0.13)
## 離瘴氣的邊緣還有這麼遠就先戴上面具；離開之後過這麼久才拿下來（在邊緣走來走去不會一直戴戴脫脫）
const MASK_MARGIN: float = 1.0
const MASK_OFF_DELAY: float = 1.5
## 走到瘴氣邊上（還沒走進去）時先停下來慌張地找面具（劇本節點 2）：低頭在腰間拍兩下、左手摀到嘴前面——
## 動作播到這個比例的時候面具戴上；頭上冒一滴汗。已經站在毒裡（被拉過去、Boss 的光環）就沒空找，直接戴上
const FUMBLE_MASK_AT: float = 0.68
## 面具掛在頭的骨頭上：往上、往臉的前面移這麼多（公尺）
const MASK_OFFSET: Vector3 = Vector3(0.0, -0.005, -0.115)
## 還沒結伴時，諾恩走到這麼近她才轉過來（9 m 的時候玩家從森林口走三秒多她就停了，很多人只看得到她往前走的那一段）
const NOTICE_DIST: float = 7.0
## 猶豫時轉身的速度（比平常慢：看得出她轉過去、又回頭）；還沒轉到這個程度（面向與要走的方向的內積）先不邁步
const HESITATE_TURN_SPEED: float = 5.0
const HESITATE_FACING: float = 0.6
## 腳步聲（比諾恩小聲：她在後面，聽得到但不搶）
const STEP_DB: float = -18.0
const RUN_STEP_DB: float = -15.0
## 被石化時蓋在身上的灰、掉下來的碎屑的顏色
const STONE_COLOR: Color = Color(0.56, 0.57, 0.62)
## 裝填禁藥（Boss 戰狂暴之後；D-306）：跪著的動作（Puppet.pose "brew"）、手弩上那一管越來越亮的桃紅色、從手上冒的光點、
## 每隔一下「喀」一聲。顏色＝禁藥的顏色（statuses.json 的 sera_chaos）；光的強弱照裝到幾成
const BREW_POSE: String = "brew"
const BREW_COLOR: Color = Color(1.0, 0.35, 0.82)
const BREW_CLICK_SEC: float = 1.0
const BREW_CLICK_DB: float = -14.0
const BREW_LIGHT: Vector2 = Vector2(0.4, 2.6)
## 向她要過一瓶之後裝下一瓶（D-309）：冷卻（brain.ask_left）剩這麼多秒時停下來、播站著裝填的動作（Puppet "reload"，1.6 秒）——
## 左手從腰上的小袋子拿一瓶、塞到弩上、往胸口一拉扳緊弓弦。扳緊的那一刻（動作的 RELOAD_CLICK_AT）剛好是冷卻結束、「喀」一聲、她喊「裝好了」。
## 塞進去的那一刻（RELOAD_INSERT_AT）弩上那一瓶亮起來（之前是空的）
const RELOAD_CLICK_AT: float = 0.78
const RELOAD_INSERT_AT: float = 0.54
## 弩上裝著的那一瓶（玩家按鍵會要到的那一瓶）：在手掛點的座標裡擺在哪（−Y＝往指尖、−Z＝大拇指那一側＝弩身的上面）、多大
const SLOT_OFFSET: Vector3 = Vector3(0.0, -0.1, -0.075)
const SLOT_RADIUS: float = 0.034
## 換一瓶（玩家按換的按鍵）：站著或走著都停下來撥一下藥匣（Puppet "swap"，0.8 秒）；撥到這個比例的時候弩上那一瓶換顏色、彈一下
const SWAP_AT: float = 0.45
## 對話中跟諾恩保持講話的距離（D-309）：比 TALK_NEAR 近（戰後跑到他肩膀旁邊，同框時兩人的肩膀疊在一起）就往後退到 TALK_NEAR＋TALK_BACK_EXTRA，
## 比 TALK_FAR 遠（跟在後面 4 m）就走近到 TALK_GAP。退的時候面向他、不邁步（只有半步）；走近用走的
const TALK_NEAR: float = 1.2
const TALK_BACK_EXTRA: float = 0.3
const TALK_FAR: float = 3.0
const TALK_GAP: float = 2.2
const TALK_BACK_SPEED: float = 1.3
const TALK_WALK_SPEED: float = 2.0

## 面具戴上／拿下來的那一刻（關卡接這個讓她喊一句）
signal mask_changed(on: bool)
## 玩家向她要一瓶的那一刻。ok＝她答應了（馬上舉弩）；false＝還在裝上一瓶（關卡接這個讓她回一句）
signal asked(ok: bool)
## 要過一瓶之後，她把下一瓶裝好、又可以要了的那一刻
signal reloaded
## 玩家換了要哪一瓶（source＝現在要的那一瓶）
signal pick_changed(source: String)
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
## 可以要的第二瓶（關卡照劇情開：自由探索之後是【劇毒大紅水】）；空的＝只有 ask_source 那一瓶、換的按鍵沒作用
var ask_extra: String = ""
## 現在要哪一瓶：0＝ask_source（煙霧彈）、1＝ask_extra
var ask_pick: int = 0
## 玩家可不可以按鍵向她要藥（關卡照劇情開：教學戰那一瓶拿錯的演完才開）
var ask_enabled: bool = false
var _asked: bool = false
## 答應的那一瓶（按下去的那一刻決定；舉弩的時候換也不會變）
var _asked_source: String = ""
## 結伴了沒（關卡照劇情旗標設）
var joined: bool = true
## 還沒結伴時她想進去又不敢進去的地方（關卡設成瘴氣的位置）；沒設就站著不動
var hesitate_at: Vector3 = Vector3.INF
var _wait_home: Vector3 = Vector3.INF
var _wait_t: float = 0.0
var masked: bool = false
## 正在找面具還要幾秒（> 0＝停在原地、不跟不射）
var fumble_left: float = 0.0
var _sweat: MangaMark
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
## 對話中要面向的地方（TalkCamera 照那一句的 to／look 叫 talk_to；沒有在對話就清掉、照平常面向諾恩）
var _talk_point: Vector3 = Vector3.INF
var _stone_mat: StandardMaterial3D
## 禁藥裝到幾成（關卡每幀設：GolemPhases.brew_progress；-1＝沒有在裝）
var brew: float = -1.0
var _brewing: bool = false
var _brew_click: float = 0.0
var _brew_glow: Node3D
var _brew_light: OmniLight3D
var _brew_vial: MeshInstance3D
var _brew_sparks: CPUParticles3D
## 弩上裝著的那一瓶（顏色＝ask_choice()）；射出去之後是空的，裝填的動作塞進去才又滿
var _slot: MeshInstance3D
var _slot_mat: StandardMaterial3D
var _slot_source: String = ""
var slot_full: bool = true
var _reload_started: bool = false
var _swap_pending: bool = false
## 對話中正在調整跟諾恩的距離：-1＝往後退、1＝走近、0＝站著
var _talk_step: int = 0
var target: PlayerController
var vials_fired: int = 0
var last_vial: SeraVial
var _puppet: Puppet
var footsteps: Footsteps = Footsteps.new(STEP_DB, RUN_STEP_DB)
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
	_puppet.footfall.connect(func() -> void:
		if is_on_floor():
			footsteps.stomp(self, _puppet.move_speed >= Puppet.RUN_MIN_SPEED))
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
	_update_brew(delta)
	_update_slot()
	if fumble_left > 0.0 and stoned_left <= 0.0:
		velocity = Vector3(0.0, 0.0 if is_on_floor() else velocity.y - GRAVITY * delta, 0.0)
		move_and_slide()
		_puppet.set_move_speed(0.0)
		return
	if stoned_left > 0.0:
		stoned_left -= delta
		velocity = Vector3.ZERO
		if stoned_left <= 0.0:
			_set_stoned(false)
			_stone_bits(18, Vector2(1.5, 4.5))
			Sfx.play_at(get_parent(), UNSTONE_SFX, global_position + Vector3.UP, -3.0, 0.06, 6.0)
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
	# 裝填、換一瓶的時候站著不動（動作是整個人的：走著播會在地上滑）
	var speed: float = 0.0 if locked or is_handling() else brain.follow_speed(dist)
	var dir: Vector3 = to / dist if dist > 0.01 else Vector3.ZERO
	var anim_speed: float = speed
	match _talk_spacing(dist):
		-1:
			speed = -TALK_BACK_SPEED
			anim_speed = 0.0
		1:
			speed = TALK_WALK_SPEED
			anim_speed = speed
	velocity = Vector3(dir.x * speed, 0.0 if is_on_floor() else velocity.y - GRAVITY * delta, dir.z * speed)
	move_and_slide()
	_puppet.set_move_speed(anim_speed)
	# 平常離他 0.3 m 以內就不轉（貼在旁邊時不要一直打轉）；對話中再近也轉過去面向他（戰後那段話她跑到他肩膀旁邊）
	var talking: bool = Game.is_in_dialogue()
	if not talking:
		_talk_point = Vector3.INF
	var facing_dist: float = 0.05 if talking else 0.3
	var to_talk: Vector3 = _talk_point - global_position if _talk_point.is_finite() else Vector3.ZERO
	if Vector2(to_talk.x, to_talk.z).length() > 0.05:
		rotation.y = lerp_angle(rotation.y, atan2(-to_talk.x, -to_talk.z), minf(delta * TURN_SPEED, 1.0))
	elif dist > facing_dist and (joined or dist < NOTICE_DIST):
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), minf(delta * TURN_SPEED, 1.0))
	if locked:
		return
	_tick_special(delta)
	if hands_full or _special_in >= 0.0:
		return
	if Input.is_action_just_pressed(SWITCH_ACTION):
		switch_pick()
	if Input.is_action_just_pressed(ASK_ACTION):
		ask()
	var was_aiming: bool = brain.is_aiming()
	var was_loading: bool = brain.ask_left > 0.0
	if brain.tick(delta, threat_near()):
		fire()
	elif brain.is_aiming() and not was_aiming:
		_puppet.play_action("shoot")
	_tick_reload()
	if was_loading and brain.ask_left <= 0.0:
		Sfx.play_at(self, "vial_load", global_position + Vector3.UP * 1.1, -6.0, 0.04)
		slot_full = true
		reloaded.emit()


## 對話中這一幀要不要調整跟諾恩的距離（-1 退、1 走近、0 不動）。只在跟著他的時候（關卡叫她站在別的地方 hold_at 就不管）
func _talk_spacing(dist: float) -> int:
	if not joined or not Game.is_in_dialogue() or not _talk_point.is_finite() or stoned_left > 0.0:
		_talk_step = 0
		return 0
	if _talk_step == 0:
		_talk_step = -1 if dist < TALK_NEAR else (1 if dist > TALK_FAR else 0)
	elif _talk_step == -1 and dist >= TALK_NEAR + TALK_BACK_EXTRA:
		_talk_step = 0
	elif _talk_step == 1 and dist <= TALK_GAP:
		_talk_step = 0
	return _talk_step


## 手上正在裝填或換一瓶（站著不動）
func is_handling() -> bool:
	var st: String = _puppet.current_state()
	return st == "reload" or st == "swap"


## 冷卻剩 RELOAD 動作扳緊之前的那一段時開始裝；塞進去的那一刻弩上那一瓶亮起來。換一瓶撥到一半換顏色
func _tick_reload() -> void:
	var reload_lead: float = float(Puppet.ACTION_TIME["reload"]) * RELOAD_CLICK_AT
	if brain.ask_left > 0.3 and not _reload_started and brain.ask_left <= reload_lead and not brain.is_aiming() and _special_in < 0.0 and fumble_left <= 0.0:
		_reload_started = true
		_puppet.play_action("reload", brain.ask_left / RELOAD_CLICK_AT)
	var st: String = _puppet.current_state()
	if st == "reload" and not slot_full and _puppet.action_time >= float(Puppet.ACTION_TIME["reload"]) * RELOAD_INSERT_AT:
		slot_full = true
		_pop_slot()
	if _swap_pending and (st != "swap" or _puppet.action_time >= float(Puppet.ACTION_TIME["swap"]) * SWAP_AT):
		_swap_pending = false
		_pop_slot()


## 裝填禁藥：站定了（跑到後面、沒在舉弩、沒被石化）就跪下去裝；手弩上那一管照裝到幾成越來越亮。
func _update_brew(delta: float) -> void:
	var settled: bool = brew >= 0.0 and stoned_left <= 0.0 and _special_in < 0.0 \
		and Vector2(velocity.x, velocity.z).length() < 0.2 and (not hold_at.is_finite() or Vector2(hold_at.x - global_position.x, hold_at.z - global_position.z).length() < 0.6)
	if settled != _brewing:
		_brewing = settled
		if settled:
			_puppet.pose = BREW_POSE
			_brew_click = BREW_CLICK_SEC * 0.5
		elif _puppet.pose == BREW_POSE:
			_puppet.pose = ""
	if _brew_glow == null:
		_build_brew_glow()
	if _brew_glow == null:
		return
	var k: float = clampf(brew, 0.0, 1.0)
	_brew_glow.visible = brew >= 0.0
	_brew_light.light_energy = lerpf(BREW_LIGHT.x, BREW_LIGHT.y, k * k)
	_brew_vial.scale = Vector3.ONE * lerpf(0.6, 1.15, k)
	_brew_sparks.emitting = _brewing
	if _brewing and stoned_left <= 0.0:
		_brew_click -= delta
		if _brew_click <= 0.0:
			_brew_click = BREW_CLICK_SEC
			Sfx.play_at(self, "vial_load", global_position + Vector3.UP * 0.8, BREW_CLICK_DB, 0.08)


func is_brewing() -> bool:
	return _brewing


func brew_light() -> OmniLight3D:
	return _brew_light


## 手弩上那一管禁藥（平常收著）：一顆自己會亮的桃紅色小瓶＋一盞小燈＋往上飄的光點
func _build_brew_glow() -> void:
	if _crossbow == null:
		return
	_brew_glow = Node3D.new()
	_brew_glow.name = "BrewGlow"
	_brew_glow.visible = false
	_crossbow.add_child(_brew_glow)
	_brew_vial = MeshInstance3D.new()
	var bulb := SphereMesh.new()
	bulb.radius = 0.045
	bulb.height = 0.09
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = BREW_COLOR.lerp(Color.WHITE, 0.3)
	bulb.material = mat
	_brew_vial.mesh = bulb
	_brew_vial.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_brew_glow.add_child(_brew_vial)
	_brew_light = OmniLight3D.new()
	_brew_light.light_color = BREW_COLOR
	_brew_light.omni_range = 2.6
	_brew_light.light_specular = 0.0
	_brew_light.shadow_enabled = false
	_brew_glow.add_child(_brew_light)
	_brew_sparks = CPUParticles3D.new()
	_brew_sparks.amount = 14
	_brew_sparks.lifetime = 0.9
	_brew_sparks.local_coords = false
	_brew_sparks.emitting = false
	_brew_sparks.direction = Vector3.UP
	_brew_sparks.spread = 40.0
	_brew_sparks.gravity = Vector3(0, 0.6, 0)
	_brew_sparks.initial_velocity_min = 0.2
	_brew_sparks.initial_velocity_max = 0.6
	_brew_sparks.scale_amount_min = 0.4
	_brew_sparks.scale_amount_max = 1.0
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	_brew_sparks.color_ramp = fade
	var quad := QuadMesh.new()
	quad.size = Vector2(0.05, 0.05)
	quad.material = ParticleLook.material(BREW_COLOR, true)
	_brew_sparks.mesh = quad
	_brew_sparks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_brew_glow.add_child(_brew_sparks)


## 對話中轉過去面向 point（TalkCamera 叫：對話開始時面向聽她講話的人，之後照每一句的 to／look）
func talk_to(point: Vector3) -> void:
	_talk_point = point


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
	if ok:
		_asked_source = ask_choice()
		_reload_started = false
	_asked = _asked or ok
	asked.emit(ok)
	return ok


## 現在按鍵會要到哪一瓶
func ask_choice() -> String:
	return ask_extra if ask_pick == 1 and ask_extra != "" else ask_source


## 換要另一瓶（按鍵，或測試直接叫）。只有一瓶可以要（ask_extra 是空的）或還不能要的時候不換，回傳 false。
func switch_pick() -> bool:
	if ask_extra == "" or not ask_enabled:
		return false
	ask_pick = 1 - ask_pick
	# 撥一下藥匣：手上空著才撥（正在裝、正在舉弩、剛答應要射就只換左上那一行，裝填塞進去的就是新的那一瓶）
	if not is_handling() and not brain.is_aiming() and not _asked and _special_in < 0.0 and fumble_left <= 0.0 and stoned_left <= 0.0:
		_puppet.play_action("swap")
		_swap_pending = slot_full
	pick_changed.emit(ask_choice())
	return true


## 擊發：從弩口生一瓶藥飛向諾恩。玩家要的那一瓶射按下去時選的那一瓶，她自己射的是 vial_source（有 vial_cycle 就輪到下一種）。
func fire() -> SeraVial:
	var vial: SeraVial = _launch((_asked_source if _asked_source != "" else ask_choice()) if _asked else vial_source)
	if _asked:
		slot_full = false
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
	Sfx.play_at(self, "vial_shot", from, -5.0)
	fired.emit(last_vial)
	return last_vial


## 現在站的地方是不是瘴氣裡面（margin＝邊緣往外再算幾公尺；預設＝就在邊上也算）
func near_miasma(margin: float = MASK_MARGIN) -> bool:
	for n: Node in get_tree().get_nodes_in_group("poison_mist"):
		var mist := n as PoisonMist
		if mist != null and Vector2(mist.global_position.x - global_position.x, mist.global_position.z - global_position.z).length() <= mist.radius + margin:
			return true
	return false


## 面具：走到瘴氣邊上先停下來找（fumble），找到才戴上；已經在毒裡就直接戴。離開一下子才拿下來。
func _update_mask(delta: float) -> void:
	if fumble_left > 0.0:
		fumble_left -= delta
		var played: float = float(Puppet.ACTION_TIME["fumble"]) - fumble_left
		if not masked and played >= float(Puppet.ACTION_TIME["fumble"]) * FUMBLE_MASK_AT:
			_set_masked(true)
		if fumble_left <= 0.0:
			fumble_left = 0.0
			_set_masked(true)
			if _sweat != null and is_instance_valid(_sweat):
				_sweat.dismiss()
	if force_mask or near_miasma():
		_mask_off_in = MASK_OFF_DELAY
		if masked or fumble_left > 0.0:
			return
		if force_mask or near_miasma(0.0) or stoned_left > 0.0:
			_set_masked(true)
		else:
			_start_fumble()
	elif masked and fumble_left <= 0.0:
		_mask_off_in -= delta
		if _mask_off_in <= 0.0:
			_set_masked(false)


func _start_fumble() -> void:
	fumble_left = float(Puppet.ACTION_TIME["fumble"])
	_puppet.play_action("fumble")
	if _sweat != null and is_instance_valid(_sweat):
		_sweat.queue_free()
	_sweat = MangaMark.pop("sweat", self, _puppet)


## 正在慌張地找面具（還沒戴上之前的那一秒多）
func is_fumbling() -> bool:
	return fumble_left > 0.0


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


## 弩上裝著的那一瓶：一顆小圓瓶（顏色＝現在按鍵會要到的那一瓶，自己微微發光：暗的森林裡看得出顏色）。
## 還不能向她要（ask_enabled 沒開）、手弩收著、正在裝禁藥的時候不畫
func _build_slot() -> void:
	if _crossbow == null:
		return
	_slot = MeshInstance3D.new()
	_slot.name = "LoadedVial"
	var bulb := SphereMesh.new()
	bulb.radius = SLOT_RADIUS
	bulb.height = SLOT_RADIUS * 2.4
	_slot_mat = StandardMaterial3D.new()
	_slot_mat.emission_enabled = true
	_slot_mat.emission_energy_multiplier = 0.9
	_slot_mat.roughness = 0.25
	bulb.material = _slot_mat
	_slot.mesh = bulb
	_slot.position = SLOT_OFFSET
	_slot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_slot.visible = false
	_crossbow.add_child(_slot)


func loaded_vial() -> MeshInstance3D:
	return _slot


func _update_slot() -> void:
	if _slot == null:
		_build_slot()
	if _slot == null:
		return
	# 沒有在冷卻＝弩上裝著（測試、讀檔直接把冷卻歸零也一樣）
	if brain.ask_left <= 0.0:
		slot_full = true
	_slot.visible = ask_enabled and slot_full and not holstered and brew < 0.0 and not _swap_pending
	var want: String = ask_choice()
	if want != _slot_source:
		_slot_source = want
		var c: Color = vial_color(want)
		_slot_mat.albedo_color = c
		_slot_mat.emission = c


## 一瓶藥的顏色（statuses.json 的來源寫的 color；沒寫是 SeraVial 預設的紫）
static func vial_color(source_id: String) -> Color:
	var tint: String = str(StatusRules.load_default().source(source_id).get("color", ""))
	return Color.html(tint) if Color.html_is_valid(tint) else SeraVial.LIQUID


## 弩上那一瓶彈一下（塞進去、換了一瓶）
func _pop_slot() -> void:
	if _slot == null:
		return
	_slot.scale = Vector3.ONE * 0.3
	var t: Tween = create_tween()
	t.tween_property(_slot, "scale", Vector3.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


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


## 收在右腰上的樣子（骨盆的掛點的座標：+X 右、+Y 上、+Z 背後）：弩口朝下掛著、槍托朝後。
## 手上的那一段位移（CROSSBOW_OFFSET）也會跟過來：弩身的中段放在 (0.22, −0.02, 0.04)
const HOLSTER_AT: Vector3 = Vector3(0.22, -0.02, 0.04) - CROSSBOW_OFFSET


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
