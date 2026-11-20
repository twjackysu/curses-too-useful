class_name ForestExplore
extends Node
## 腐敗之森的自由探索（docs/story/chapter-1.md 時段 B）：採夜光毒蕈、三種陷阱、野外的敵人、營火、毒沼與詛咒寶箱、通往祭壇的路。
## CorruptForest 生出它、給它諾恩、HUD 與席菈；它把東西放進關卡（目標指引要從關卡底下找節點）。位置照 ForestMap。
## 劇情旗標：ch1.mushrooms（採了幾朵）、ch1.mushroom_<n>（第 n 朵採過了）、ch1.altar_gate_reached（走到祭壇路口）、
## ch1.campfire_talked（營火那段話講過了）、sera.duo_unlocked（連攜解鎖）、ch1.chest_opened（詛咒寶箱開了）、noen.weapon（手上是哪一把）、
## ch1.pack.<名字>（那一群敵人打倒了）、ch1.respawn（讀檔、倒下重來從哪裡開始："glade"／"camp"）。任務 data/quests/ch1_main.json 的 gather、to_altar 兩個階段看前兩個。
## 走到祭壇路口就換到下一關（scenes/levels/ruined_altar.gd）。

const QUEST: String = "ch1_main"
const STAGE_GATHER: String = "gather"
const STAGE_ALTAR: String = "to_altar"
## 還不能往北逛的階段（""＝沒有開主線）
const LOCKED_STAGES: PackedStringArray = ["", "meet_sera", "enter_miasma", "slimes", "after_fight"]
const FLAG_MUSHROOMS: String = "ch1.mushrooms"
const FLAG_ALTAR: String = "ch1.altar_gate_reached"
const FLAG_RESPAWN: String = "ch1.respawn"
const MUSHROOM_NEED: int = 5
## 可以採的夜光毒蕈（比路邊當擺設的大一號、會冒光點）：七朵，採五朵就夠——不一定要進毒沼
const MUSHROOM_SPOTS: Array[Vector3] = [
	Vector3(3.4, 0, -26.0), Vector3(-5.0, 0, -39.5), Vector3(-27.5, 0, -43.0), Vector3(27.5, 0, -48.5),
	Vector3(33.0, 0, -53.5), Vector3(36.0, 0, -67.0), Vector3(-5.5, 0, -63.0),
]
const MUSHROOM_SIZE: float = 1.3
## 可以採的毒蕈、可以吃的野果腳下那一圈光（ForestScenery.pickup_ring）多大：路邊當擺設的沒有
const PICKUP_RING_RADIUS: float = 1.1
## 三種陷阱（劇本：一般遊戲要閃，這裡要故意踩進去）。毒氣噴發口：一小團比瘴氣濃的毒（PoisonMist）；
## 麻痺蜘蛛網（WebTrap）：x、z、網張開的方向（度）；腐敗野果：走近按鍵吃一顆，過一下子才再長
const VENT_SPOTS: Array[Vector3] = [Vector3(-3.6, 0, -31.5), Vector3(4.6, 0, -40.5), Vector3(18.5, 0, -39.0), Vector3(5.5, 0, -55.5)]
const VENT_RADIUS: float = 2.3
const VENT_MODEL: String = "tripo/prop_poison_vent"
## 底座只留模型最下面那一截（gen_props 的 --keep-below）：放大到從霧盤裡露出來（2.2 倍時幾乎整個被霧蓋住）
const VENT_SCALE: float = 3.2
const WEB_SPOTS: Array[Vector3] = [Vector3(-0.9, -28.5, 90.0), Vector3(11.5, -39.8, 20.0), Vector3(-1.0, -51.0, 90.0), Vector3(31.5, -53.5, 130.0)]
const BUSH_SPOTS: Array[Vector3] = [Vector3(5.6, 0, -33.0), Vector3(-20.0, 0, -50.0), Vector3(27.0, 0, -37.5), Vector3(-4.5, 0, -55.0)]
const FRUIT_SOURCE: String = "rotten_fruit"
const FRUIT_REGROW_SEC: float = 8.0
## 灌木上一顆一顆的果子（建置時從模型拆出來的節點 Fruit1、Fruit2…；模型不在就是程式做的兩顆紫球）：吃一顆少一顆，
## 長回來的時候從小彈到原本的大小。咬下去噴的紫色汁
const FRUIT_NODE: String = "Fruit"
const FRUIT_JUICE: Color = Color(0.6, 0.28, 0.82)
const FRUIT_GROW_SEC: float = 0.6
## 野外的敵人，一群一群放（每一隻：種類、x、z）。整群打倒就記一個旗標（ch1.pack.<名字>）並存檔，讀檔不會再生。
## 種類：slime＝劇毒史萊姆、mold＝黴菌史萊姆、wolf＝瘴氣狼、treant＝孢子樹人
const PACKS: Dictionary = {
	"traps": [["mold", -2.6, -41.5], ["mold", 3.2, -42.5]],
	"wolves": [["wolf", 21.0, -45.0], ["wolf", 27.0, -41.5], ["wolf", 25.5, -48.0]],
	"swamp": [["mold", 36.5, -61.0], ["mold", 43.5, -62.5], ["slime", 40.5, -68.0]],
	"hollow": [["treant", 0.0, -63.0], ["slime", -4.5, -58.5], ["slime", 4.5, -60.0]],
}
## 營火（劇本的營火休息事件）：休息＝補滿血、存檔、之後從這裡重來；第一次休息席菈講她的過去（對話 ch1_campfire），
## 講完解鎖連攜（旗標 sera.duo_unlocked）：向她要的煙霧彈換成多調一份麻痺的 DUO_SOURCE
const CAMPFIRE_MODEL: String = "tripo/prop_campfire_v2"
const CAMPFIRE_SCALE: float = 1.3
## 從東西發出來的循環聲（Ambience.play_at）：營火的劈啪、噴發口的嘶聲、毒沼的咕嘟。[音檔, dB, unit_size（這麼近以內是原音量）]
const FIRE_SOUND: Array = ["campfire_crackle", -4.0, 4.0]
const VENT_SOUND: Array = ["vent_hiss", -10.0, 2.5]
const SWAMP_SOUND: Array = ["swamp_bubble", -6.0, 6.0]
## 採毒蕈、吃野果、開寶箱的聲音；採滿五朵時祭壇那邊傳來的慘叫（遠，不分位置）
const PICK_SFX: String = "mushroom_pick"
const FRUIT_SFX: String = "fruit_bite"
const CHEST_SFX: String = "chest_open"
const SCREAM_SFX: String = "distant_scream"
const SCREAM_DB: float = -5.0
const FIRE_ENERGY: float = 4.5
const CAMP_DIALOGUE: String = "ch1_campfire"
const FLAG_CAMP_TALK: String = "ch1.campfire_talked"
const FLAG_DUO: String = "sera.duo_unlocked"
const DUO_SOURCE: String = "sera_duo_smoke"
## 探索的時候席菈自己輪流射這幾種（第二種是【劇毒大紅水】：衰弱＋中毒）
const SERA_VIALS: PackedStringArray = ["sera_paralysis_vial", "sera_weak_vial"]
## 毒沼：一大片比森林口濃的瘴氣；最深處的詛咒寶箱打開中【衰弱詛咒】、拿到【不祥的裂刃】
const SWAMP_MIASMA_RADIUS: float = 8.5
## 範圍大，霧調淡（PoisonMist.thickness）：站在裡面還看得到人、怪與地上的黑泥、發綠的水（0.22 時地面整片是紫的、敵人發白）
const SWAMP_MIASMA_THICKNESS: float = 0.12
const CHEST_POS: Vector3 = Vector3(45.5, 0, -69.5)
const CHEST_MODEL: String = "tripo/prop_cursed_chest"
const CHEST_SOURCE: String = "curse_weakness"
const CHEST_WEAPON: String = "split_blade"
const FLAG_CHEST: String = "ch1.chest_opened"
## 教學戰打完、講完話之前，往北走到這條線就過不去（不然可以拖著史萊姆跑進後面的森林）
const NORTH_GATE_Z: float = -24.5
const GATE_BARK_EVERY: float = 6.0
## 走到離祭壇路口這麼近就算到了
const ALTAR_REACH: float = 4.5
## 讀檔、倒下重來的位置
const RESPAWNS: Dictionary = {"glade": Vector3(0, 0.05, -11.0), "camp": Vector3(-20.5, 0.05, -43.5)}

var level: Node3D
var player: PlayerController
var hud: Hud
var sera: Sera
var mushrooms: Array[Interactable] = []
var vents: Array[PoisonMist] = []
var webs: Array[WebTrap] = []
var bushes: Array[Interactable] = []
var campfire: Interactable
var chest: Interactable
var swamp_miasma: PoisonMist
var _fire_light: OmniLight3D
var _fire_t: float = 0.0
var _burst_on: String = ""
## 等營火那段話講完要跳「解鎖連攜」
var _duo_pending: bool = false
## 還沒打倒的每一群：名字 → 那一群的敵人
var packs: Dictionary = {}
## 每一叢野果還要幾秒才再長出來（0＝可以吃）
var _regrow: PackedFloat32Array = []
## 每一叢被吃掉的那一顆果子（長回來之前看不到；null＝都還在）
var _eaten: Array[Node3D] = []
var _gate_bark_in: float = 0.0
## 走到祭壇路口之後的地點卡（播完換到祭壇那一關；測試叫 card.finish()）
var card: ChapterCard


## 自由探索開放了沒（教學戰與戰後那段話都過了；之後的階段——祭壇那一關——也算）
static func unlocked(state: GameState) -> bool:
	return not str(state.quests.get(QUEST, "")) in LOCKED_STAGES


## 探索開放之後，讀檔、倒下重來從哪裡開始
static func spawn_point(state: GameState) -> Vector3:
	return RESPAWNS.get(str(state.get_flag(FLAG_RESPAWN, "glade")), RESPAWNS["glade"]) as Vector3


static func create(p_level: Node3D, p_player: PlayerController, p_hud: Hud, p_sera: Sera) -> ForestExplore:
	var e := ForestExplore.new()
	e.name = "Explore"
	e.level = p_level
	e.player = p_player
	e.hud = p_hud
	e.sera = p_sera
	return e


func _ready() -> void:
	var gate := Marker3D.new()
	gate.name = "AltarGate"
	gate.position = ForestMap.at(ForestMap.ALTAR_GATE)
	level.add_child(gate)
	# 祭壇在更北邊（下一段）：路的盡頭透過來一片不祥的紅光，遠遠看得出那邊有東西
	var omen := OmniLight3D.new()
	omen.name = "Omen"
	omen.light_color = Color(1.0, 0.25, 0.3)
	omen.light_energy = 5.0
	omen.omni_range = 16.0
	omen.shadow_enabled = false
	omen.light_volumetric_fog_energy = 4.0
	omen.position = Vector3(0, 3.0, -7.0)
	gate.add_child(omen)
	_spawn_mushrooms()
	_spawn_traps()
	_spawn_packs()
	_build_campfire()
	_build_swamp()
	sera.fired.connect(_on_sera_fired)
	# 連拍用（scripts/burst.sh，配 `--explore --at=x,z`）：`--burst-on=wolf|treant|mold` 那一種敵人第一次擺前兆的那一刻開始拍；
	# `--burst-on=chest` 進場 1.2 秒後打開詛咒寶箱、`--burst-on=camp` 在營火休息（第一次會開始對話）、
	# `--burst-on=fruit` 吃最近的那一叢野果、`--burst-on=web` 諾恩被放到最近的那一張網上（撞破），從那一刻開始拍
	_burst_on = str(Game.level_args().get("burst-on", ""))
	if _burst_on in ["chest", "camp", "fruit", "web"]:
		get_tree().create_timer(1.2).timeout.connect(_burst_demo)
	Game.dialogue_ended.connect(_on_dialogue_ended)
	Game.session.stage_changed.connect(_on_stage_changed)


func _burst_demo() -> void:
	App.burst_start_in(1)
	match _burst_on:
		"chest":
			chest.use(player)
		"camp":
			campfire.use(player)
		"fruit":
			_nearest(bushes).use(player)
		"web":
			var web: WebTrap = _nearest(webs) as WebTrap
			var side: float = signf(web.global_basis.x.dot(player.global_position - web.global_position))
			player.global_position = web.global_position + web.global_basis.x * 0.3 * (side if side != 0.0 else 1.0) + Vector3.UP * 0.05


func _nearest(nodes: Array) -> Node3D:
	var best: Node3D = null
	for n: Node3D in nodes:
		if best == null or n.global_position.distance_to(player.global_position) < best.global_position.distance_to(player.global_position):
			best = n
	return best


func _physics_process(delta: float) -> void:
	if not Game.session.in_story():
		return
	var st: GameState = Game.session.state
	var open: bool = unlocked(st)
	for m: Interactable in mushrooms:
		if m != null:
			m.enabled = open
	_tick_traps(delta)
	_tick_packs()
	_tick_sera(st, open)
	_fire_t += delta
	_fire_light.light_energy = FIRE_ENERGY + 0.6 * sin(_fire_t * 9.0) + 0.35 * sin(_fire_t * 23.0)
	if swamp_miasma.contains(sera.global_position) and sera.joined and st.grant_once("ch1.swamp_bark"):
		hud.show_bark(sera, "BARK_SERA_SWAMP", 3.2, Sera.NAME_KEY)
	_gate_bark_in = maxf(_gate_bark_in - delta, 0.0)
	if not open and player.global_position.z < NORTH_GATE_Z:
		player.global_position.z = NORTH_GATE_Z
		if _gate_bark_in <= 0.0 and sera.joined:
			_gate_bark_in = GATE_BARK_EVERY
			hud.show_bark(sera, "BARK_SERA_NOT_YET", 2.6, Sera.NAME_KEY)
	if stage() == STAGE_ALTAR and ForestMap.flat(player.global_position).distance_to(Vector2(ForestMap.ALTAR_GATE.x, ForestMap.ALTAR_GATE.y)) < ALTAR_REACH:
		# 下一個階段的檢查點在廢棄祭壇那一關：這裡存檔（生命、狀態、武器跟著走），一張地點卡、換關卡
		Game.session.set_flag(FLAG_ALTAR, true)
		card = ChapterCard.play(level, "CARD_ALTAR_SMALL", "CARD_ALTAR_TITLE", Game.go_to_checkpoint_level)


func stage() -> String:
	return Game.session.quests.stage_of(QUEST)


## 還沒採的有幾朵（測試用）
func mushrooms_left() -> int:
	var n: int = 0
	for m: Interactable in mushrooms:
		if m != null:
			n += 1
	return n


static func _mushroom_flag(i: int) -> String:
	return "ch1.mushroom_%d" % (i + 1)


func _spawn_mushrooms() -> void:
	for i: int in MUSHROOM_SPOTS.size():
		if bool(Game.session.state.get_flag(_mushroom_flag(i), false)):
			mushrooms.append(null)
			continue
		var m: Interactable = Interactable.create("Mushroom%d" % (i + 1), MUSHROOM_SPOTS[i], "HINT_PICK_MUSHROOM")
		var look: Node3D = ForestScenery.small_prop(ForestScenery.MUSHROOM_MODEL, Vector3.ZERO, float(i) * 1.7, true)
		look.name = "Look"
		look.scale = Vector3.ONE * MUSHROOM_SIZE
		m.add_child(look)
		m.add_child(_sparkles(Color(0.5, 0.95, 1.0)))
		m.add_child(ForestScenery.pickup_ring(PICKUP_RING_RADIUS, Color(0.45, 0.95, 1.0)))
		m.used.connect(_on_mushroom_used.bind(i))
		level.add_child(m)
		mushrooms.append(m)


## 可以採、可以用的東西頭上慢慢往上飄的幾顆亮點：跟路邊的擺設分得出來
static func _sparkles(color: Color) -> CPUParticles3D:
	var ps := CPUParticles3D.new()
	ps.name = "Sparkles"
	ps.amount = 9
	ps.lifetime = 1.8
	ps.preprocess = 1.8  # 還沒發射出來的粒子會在原點畫成一顆黑的：先跑完一輪
	ps.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	ps.emission_box_extents = Vector3(0.45, 0.2, 0.45)
	ps.position = Vector3(0.0, 0.9, 0.0)
	ps.direction = Vector3.UP
	ps.spread = 12.0
	ps.gravity = Vector3.ZERO
	ps.initial_velocity_min = 0.35
	ps.initial_velocity_max = 0.7
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color.WHITE, Color(1, 1, 1, 0)])
	ps.color_ramp = fade
	var quad := QuadMesh.new()
	quad.size = Vector2(0.09, 0.09)
	quad.material = ParticleLook.material(color, true)
	ps.mesh = quad
	ps.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return ps


## 採一朵：記下這一朵採過了、數量加一（任務看數量）、存檔；毒蕈縮小不見。
func _on_mushroom_used(_by: PlayerController, i: int) -> void:
	var m: Interactable = mushrooms[i]
	if m == null or not m.enabled:
		return
	# 採過的從清單拿掉（節點自己縮小、釋放）
	mushrooms[i] = null
	m.enabled = false
	Game.session.state.set_flag(_mushroom_flag(i), true)
	Game.session.add_flag(FLAG_MUSHROOMS, 1)
	var have: int = int(Game.session.state.get_flag(FLAG_MUSHROOMS, 0))
	hud.show_banner(tr("CH1_MUSHROOM_PICKED").format({"have": mini(have, MUSHROOM_NEED), "need": MUSHROOM_NEED}), 2.0)
	Sfx.play_at(level, PICK_SFX, m.global_position + Vector3.UP * 0.5, -4.0, 0.05)
	Game.session.autosave()
	var t: Tween = m.create_tween()
	t.tween_property(m, "scale", Vector3.ONE * 0.05, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_callback(m.queue_free)


# ---------------------------------------------------------------- 席菈

## 探索開放之後她自己輪流射兩種藥，向她要的也多一瓶（紅的那一瓶，換的按鍵）；營火那段話講過，向她要的煙霧彈換成連攜的
func _tick_sera(st: GameState, open: bool) -> void:
	if open and sera.vial_cycle.is_empty() and sera.vial_source == Sera.VIAL_SOURCE:
		sera.vial_cycle = SERA_VIALS
	if open:
		sera.ask_extra = SERA_VIALS[1]
	if bool(st.get_flag(FLAG_DUO, false)):
		sera.ask_source = DUO_SOURCE


func _on_sera_fired(vial: SeraVial) -> void:
	if vial.source == SERA_VIALS[1] and Game.session.state.grant_once("ch1.red_vial_bark"):
		hud.show_bark(sera, "BARK_SERA_RED", 3.0, Sera.NAME_KEY)


# ---------------------------------------------------------------- 營火

func _loop_sound(on: Node3D, sound: Array, at: Vector3, node_name: String) -> void:
	Ambience.play_at(on, str(sound[0]), at, float(sound[1]), float(sound[2]), node_name)


func _build_campfire() -> void:
	campfire = Interactable.create("Campfire", ForestMap.at(ForestMap.CAMP), "HINT_CAMPFIRE", 3.0)
	var look: Node3D = PropModels.instance(CAMPFIRE_MODEL)
	if look == null:
		look = _stand_in_campfire()
	look.name = "Look"
	look.scale = Vector3.ONE * CAMPFIRE_SCALE
	campfire.add_child(look)
	campfire.add_child(_blocker(0.7, 1.0))
	_fire_light = OmniLight3D.new()
	_fire_light.name = "FireLight"
	_fire_light.light_color = Color(1.0, 0.62, 0.3)
	_fire_light.light_energy = FIRE_ENERGY
	_fire_light.omni_range = 13.0
	_fire_light.omni_attenuation = 1.2
	_fire_light.shadow_enabled = true
	_fire_light.position = Vector3(0, 0.9, 0)
	campfire.add_child(_fire_light)
	campfire.add_child(_embers())
	_loop_sound(campfire, FIRE_SOUND, Vector3(0, 0.5, 0), "FireSound")
	campfire.used.connect(_on_campfire_used)
	level.add_child(campfire)


## 在營火旁休息：補滿血、之後從這裡重來、存檔。第一次：席菈講她的過去。
func _on_campfire_used(by: PlayerController) -> void:
	by.health.heal(by.health.max_hp, {"source": "campfire"})
	Game.session.set_flag(FLAG_RESPAWN, "camp")
	if not bool(Game.session.state.get_flag(FLAG_CAMP_TALK, false)) and sera.joined and Game.start_dialogue(CAMP_DIALOGUE):
		_duo_pending = true
	else:
		hud.show_banner("CH1_RESTED", 3.0)
	Game.session.autosave()


func _on_dialogue_ended(dialogue_id: String) -> void:
	if dialogue_id != CAMP_DIALOGUE or not _duo_pending:
		return
	_duo_pending = false
	# 劇本：「解鎖雙人合體技雛形」
	hud.show_center_lines("CH1_DUO_LINE1", "CH1_DUO_LINE2", 7.0, Hud.CENTER_LINE2_COLOR)
	Game.session.autosave()


## 擋路的圓柱（營火、寶箱：人不會穿過去）
static func _blocker(radius: float, height: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Blocker"
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = height
	shape.shape = cyl
	shape.position = Vector3(0, height * 0.5, 0)
	body.add_child(shape)
	return body


## 火堆上往上飄的火星
static func _embers() -> CPUParticles3D:
	var ps := CPUParticles3D.new()
	ps.name = "Embers"
	ps.amount = 14
	ps.lifetime = 1.6
	ps.preprocess = 1.6
	ps.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	ps.emission_sphere_radius = 0.25
	ps.position = Vector3(0, 0.5, 0)
	ps.direction = Vector3.UP
	ps.spread = 18.0
	ps.gravity = Vector3(0, 0.8, 0)
	ps.initial_velocity_min = 0.6
	ps.initial_velocity_max = 1.4
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.2, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color.WHITE, Color(1, 1, 1, 0)])
	ps.color_ramp = fade
	var quad := QuadMesh.new()
	quad.size = Vector2(0.06, 0.06)
	quad.material = ParticleLook.material(Color(1.0, 0.7, 0.3), true)
	ps.mesh = quad
	ps.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return ps


static func _stand_in_campfire() -> Node3D:
	var root := Node3D.new()
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.35, 0.22, 0.14)
	for i: int in 3:
		var log_mesh := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.07
		cyl.bottom_radius = 0.07
		cyl.height = 0.9
		cyl.material = wood
		log_mesh.mesh = cyl
		log_mesh.position = Vector3(0, 0.12, 0)
		log_mesh.rotation = Vector3(PI * 0.5, float(i) * PI / 3.0, 0)
		root.add_child(log_mesh)
	var flame := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.22
	cone.height = 0.6
	var fire := StandardMaterial3D.new()
	fire.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fire.albedo_color = Color(1.0, 0.6, 0.2)
	cone.material = fire
	flame.mesh = cone
	flame.position = Vector3(0, 0.45, 0)
	root.add_child(flame)
	return root


# ---------------------------------------------------------------- 毒沼與詛咒寶箱

func _build_swamp() -> void:
	swamp_miasma = PoisonMist.create(SWAMP_MIASMA_RADIUS, "swamp_miasma")
	swamp_miasma.name = "SwampMiasma"
	swamp_miasma.thickness = SWAMP_MIASMA_THICKNESS
	swamp_miasma.position = ForestMap.at(ForestMap.SWAMP)
	_loop_sound(swamp_miasma, SWAMP_SOUND, Vector3(0, 0.2, 0), "SwampBubble")
	level.add_child(swamp_miasma)
	chest = Interactable.create("CursedChest", CHEST_POS, "HINT_OPEN_CHEST", 2.4)
	var look: Node3D = PropModels.instance(CHEST_MODEL)
	if look == null:
		look = _stand_in_chest()
	look.name = "Look"
	# 正面朝著沼澤中間（玩家來的方向）
	look.rotation.y = atan2(ForestMap.SWAMP.x - CHEST_POS.x, ForestMap.SWAMP.y - CHEST_POS.z) + PI
	chest.add_child(look)
	chest.add_child(_blocker(0.6, 0.8))
	# 寶箱的光用病黃綠（紫的話整個融進紫霧裡，從沼澤邊看不出那裡有東西）
	var glow := OmniLight3D.new()
	glow.name = "Glow"
	glow.light_color = Color(0.85, 1.0, 0.45)
	glow.light_energy = 2.6
	glow.omni_range = 5.5
	glow.shadow_enabled = false
	glow.light_volumetric_fog_energy = 2.5
	glow.position = Vector3(0, 1.0, 0)
	chest.add_child(glow)
	chest.add_child(_sparkles(Color(0.9, 1.0, 0.55)))
	chest.used.connect(_on_chest_opened)
	chest.enabled = not bool(Game.session.state.get_flag(FLAG_CHEST, false))
	_show_chest_opened(not chest.enabled)
	level.add_child(chest)


## 打開詛咒寶箱（劇本）：中【衰弱詛咒】（對諾恩是砍得更重）、拿到【不祥的裂刃】、右上角可選的那一項完成、存檔。
func _on_chest_opened(by: PlayerController) -> void:
	if not chest.enabled:
		return
	chest.enabled = false
	_show_chest_opened(true)
	by.status_effects.apply_source(CHEST_SOURCE)
	by.equip(CHEST_WEAPON)
	Game.session.set_flag(FLAG_CHEST, true)
	hud.show_center_lines("CH1_CHEST_LINE1", "CH1_CHEST_LINE2", 8.0)
	if sera.joined:
		hud.show_bark(sera, "BARK_SERA_CHEST", 3.4, Sera.NAME_KEY)
	Sfx.play_at(level, CHEST_SFX, chest.global_position + Vector3.UP * 0.5, -2.0, 0.02)
	Game.session.autosave()


## 開過的寶箱：紫光與光點收掉（模型是一整塊，蓋子掀不開）
func _show_chest_opened(opened: bool) -> void:
	(chest.get_node("Glow") as OmniLight3D).visible = not opened
	(chest.get_node("Sparkles") as CPUParticles3D).emitting = not opened


static func _stand_in_chest() -> Node3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.0, 0.7, 0.7)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.4, 0.26, 0.2)
	box.material = wood
	mesh.mesh = box
	mesh.position = Vector3(0, 0.35, 0)
	return mesh


# ---------------------------------------------------------------- 野外的敵人

static func pack_flag(pack_id: String) -> String:
	return "ch1.pack." + pack_id


static func _new_enemy(kind: String) -> EnemyActor:
	match kind:
		"mold":
			return MoldSlime.new()
		"wolf":
			return MiasmaWolf.new()
		"treant":
			return SporeTreant.new()
	return Slime.new()


func _spawn_packs() -> void:
	for pack_id: String in PACKS:
		if bool(Game.session.state.get_flag(pack_flag(pack_id), false)):
			continue
		var members: Array[EnemyActor] = []
		for spec: Array in (PACKS[pack_id] as Array):
			var e: EnemyActor = _new_enemy(str(spec[0]))
			e.name = "%s_%s%d" % [pack_id, str(spec[0]), members.size() + 1]
			e.position = Vector3(float(spec[1]), 0.0, float(spec[2]))
			e.focus_player = true
			level.add_child(e)
			# 一開始面向南邊（玩家來的方向）
			e.set_facing(PI)
			members.append(e)
		packs[pack_id] = members


## 這一群還活著幾隻（打倒了、或讀檔時已經清掉的＝0）
func pack_alive(pack_id: String) -> int:
	var n: int = 0
	# 倒下的敵人過幾秒會被釋放：先確認還在，再當成 EnemyActor 用
	for v: Variant in (packs.get(pack_id, []) as Array):
		if is_instance_valid(v) and not (v as EnemyActor).health.is_dead():
			n += 1
	return n


func _tick_packs() -> void:
	if _burst_on in ["wolf", "treant", "mold"]:
		for e: Node in get_tree().get_nodes_in_group("enemies"):
			if str(e.name).contains("_" + _burst_on) and (e as EnemyActor).brain.state == EnemyBrain.State.TELEGRAPH:
				_burst_on = ""
				App.burst_start_in(1)
				break
	for pack_id: String in packs.keys():
		if pack_alive(pack_id) == 0:
			packs.erase(pack_id)
			Game.session.set_flag(pack_flag(pack_id), true)
			Game.session.autosave()


# ---------------------------------------------------------------- 陷阱

func _spawn_traps() -> void:
	for i: int in VENT_SPOTS.size():
		var vent: PoisonMist = PoisonMist.create(VENT_RADIUS, "vent_gas")
		vent.name = "Vent%d" % (i + 1)
		vent.position = VENT_SPOTS[i]
		var base: Node3D = PropModels.instance(VENT_MODEL)
		if base == null:
			base = _stand_in_vent()
		base.name = "Base"
		base.scale = Vector3.ONE * VENT_SCALE
		base.rotation.y = float(i) * 1.3
		vent.add_child(base)
		vent.add_child(_gas_jet())
		_loop_sound(vent, VENT_SOUND, Vector3(0, 0.4, 0), "VentHiss")
		var glow := OmniLight3D.new()
		glow.name = "Glow"
		glow.light_color = Color(0.6, 1.0, 0.35)
		glow.light_energy = 1.4
		glow.omni_range = 4.0
		glow.shadow_enabled = false
		glow.position = Vector3(0, 0.7, 0)
		vent.add_child(glow)
		level.add_child(vent)
		vents.append(vent)
	for i: int in WEB_SPOTS.size():
		var web: WebTrap = WebTrap.create("Web%d" % (i + 1), Vector3(WEB_SPOTS[i].x, 0.0, WEB_SPOTS[i].y), deg_to_rad(WEB_SPOTS[i].z))
		web.snared.connect(_on_web_snared)
		level.add_child(web)
		webs.append(web)
	for i: int in BUSH_SPOTS.size():
		var bush: Interactable = Interactable.create("FruitBush%d" % (i + 1), BUSH_SPOTS[i], "HINT_EAT_FRUIT", 2.4)
		var look: Node3D = ForestScenery.small_prop(ForestScenery.BUSH_MODEL, Vector3.ZERO, float(i) * 2.1, false)
		look.scale = Vector3.ONE * 1.15
		bush.add_child(look)
		bush.add_child(_sparkles(Color(1.0, 0.45, 0.35)))
		bush.add_child(ForestScenery.pickup_ring(PICKUP_RING_RADIUS, Color(1.0, 0.5, 0.35)))
		bush.used.connect(_on_fruit_eaten.bind(i))
		if fruits_on(bush).is_empty():
			_stand_in_fruits(look)
		level.add_child(bush)
		bushes.append(bush)
		_regrow.append(0.0)
		_eaten.append(null)


## 野果過一下子再長；第一次走進毒氣裡席菈喊一聲
func _tick_traps(delta: float) -> void:
	for i: int in bushes.size():
		if _regrow[i] > 0.0:
			_regrow[i] = maxf(_regrow[i] - delta, 0.0)
			if _regrow[i] <= 0.0:
				_grow_fruit(i)
		bushes[i].enabled = _regrow[i] <= 0.0
		(bushes[i].get_node("Sparkles") as CPUParticles3D).emitting = bushes[i].enabled
		(bushes[i].get_node("PickupRing") as Node3D).visible = bushes[i].enabled
	for vent: PoisonMist in vents:
		if vent.contains(player.global_position) and Game.session.state.grant_once("ch1.vent_bark") and sera.joined:
			hud.show_bark(sera, "BARK_SERA_VENT", 3.2, Sera.NAME_KEY)


func _on_web_snared(_by: PlayerController) -> void:
	if Game.session.state.grant_once("ch1.web_bark") and sera.joined:
		hud.show_bark(sera, "BARK_SERA_WEB", 3.2, Sera.NAME_KEY)


func _on_fruit_eaten(by: PlayerController, i: int) -> void:
	if _regrow[i] > 0.0:
		return
	_regrow[i] = FRUIT_REGROW_SEC
	_pluck_fruit(i, by.global_position)
	by.status_effects.apply_source(FRUIT_SOURCE)
	Sfx.play_at(level, FRUIT_SFX, by.global_position + Vector3.UP * 1.5, -6.0)
	if Game.session.state.grant_once("ch1.fruit_bark") and sera.joined:
		hud.show_bark(sera, "BARK_SERA_FRUIT", 3.2, Sera.NAME_KEY)


## 這一叢灌木上的果子（看不到的＝被吃掉了）
static func fruits_on(bush: Node) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for n: Node in bush.find_children(FRUIT_NODE + "*", "Node3D", true, false):
		out.append(n as Node3D)
	return out


## 摘掉離他最近的那一顆：一縮就不見、噴一點紫色的汁
func _pluck_fruit(i: int, near: Vector3) -> void:
	var best: Node3D = null
	for f: Node3D in fruits_on(bushes[i]):
		if f.visible and (best == null or f.global_position.distance_to(near) < best.global_position.distance_to(near)):
			best = f
	if best == null:
		return
	_eaten[i] = best
	if not best.has_meta("home_scale"):
		best.set_meta("home_scale", best.scale)
	var juice: CPUParticles3D = _juice_burst()
	level.add_child(juice)
	juice.global_position = best.global_position
	juice.restart()
	get_tree().create_timer(juice.lifetime + 0.2).timeout.connect(juice.queue_free)
	var t: Tween = best.create_tween()
	t.tween_property(best, "scale", best.scale * 0.05, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_callback(best.hide)


## 吃掉的那一顆長回來
func _grow_fruit(i: int) -> void:
	var f: Node3D = _eaten[i]
	_eaten[i] = null
	if f == null or not is_instance_valid(f):
		return
	var home: Vector3 = f.get_meta("home_scale", Vector3.ONE)
	f.visible = true
	f.scale = home * 0.1
	f.create_tween().tween_property(f, "scale", home, FRUIT_GROW_SEC).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## 模型不在（或是沒拆出果子的舊檔）：掛兩顆紫色的球
static func _stand_in_fruits(on: Node3D) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.22, 0.62)
	mat.roughness = 0.4
	var spots: Array[Vector3] = [Vector3(0.24, 0.82, 0.38), Vector3(0.3, 0.9, -0.3)]
	for k: int in spots.size():
		var mi := MeshInstance3D.new()
		mi.name = "%s%d" % [FRUIT_NODE, k + 1]
		var ball := SphereMesh.new()
		ball.radius = 0.13
		ball.height = 0.26
		ball.material = mat
		mi.mesh = ball
		mi.position = spots[k]
		on.add_child(mi)


## 咬下去噴的紫色汁：一小把往外濺、往下掉的水滴
static func _juice_burst() -> CPUParticles3D:
	var ps := CPUParticles3D.new()
	ps.name = "FruitJuice"
	ps.emitting = false
	ps.one_shot = true
	ps.explosiveness = 1.0
	ps.amount = 14
	ps.lifetime = 0.6
	ps.direction = Vector3.UP
	ps.spread = 80.0
	ps.gravity = Vector3(0, -9.0, 0)
	ps.initial_velocity_min = 1.2
	ps.initial_velocity_max = 2.6
	ps.scale_amount_min = 0.6
	ps.scale_amount_max = 1.2
	var quad := QuadMesh.new()
	quad.size = Vector2(0.07, 0.07)
	quad.material = ParticleLook.material(FRUIT_JUICE)
	ps.mesh = quad
	ps.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return ps


## 噴發口往上噴的毒氣：一股黃綠的煙（底座的模型只留鐵格柵與石頭）
static func _gas_jet() -> CPUParticles3D:
	var ps := CPUParticles3D.new()
	ps.name = "Jet"
	ps.amount = 16
	ps.lifetime = 1.5
	ps.preprocess = 1.5
	ps.direction = Vector3.UP
	ps.spread = 16.0
	ps.gravity = Vector3(0, 0.6, 0)
	ps.initial_velocity_min = 1.3
	ps.initial_velocity_max = 2.4
	ps.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	ps.emission_sphere_radius = 0.25
	ps.position = Vector3(0, 0.15, 0)
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.15, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0.7), Color(1, 1, 1, 0)])
	ps.color_ramp = fade
	var quad := QuadMesh.new()
	quad.size = Vector2(0.75, 0.75)
	quad.material = ParticleLook.material(Color(0.62, 0.95, 0.35, 0.55))
	ps.mesh = quad
	ps.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return ps


static func _stand_in_vent() -> Node3D:
	var mesh := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.18
	ring.outer_radius = 0.34
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.3, 0.28, 0.33)
	ring.material = stone
	mesh.mesh = ring
	mesh.position = Vector3(0, 0.05, 0)
	return mesh


func _on_stage_changed(quest_id: String, _from: String, to: String) -> void:
	if quest_id != QUEST or not is_inside_tree():
		return
	if to == STAGE_GATHER:
		# 劇本的系統提示：自由探索開始
		hud.show_center_lines("CH1_EXPLORE_LINE1", "CH1_EXPLORE_LINE2", 7.0, Hud.CENTER_LINE2_COLOR)
	elif to == STAGE_ALTAR:
		# 採完準備回去的時候，祭壇那邊傳來慘叫（劇本節點 3 的開頭）
		hud.show_center_lines("CH1_SCREAM_LINE1", "CH1_SCREAM_LINE2", 6.0)
		Sfx.play_flat(level, SCREAM_SFX, SCREAM_DB)
		hud.show_bark(sera, "BARK_SERA_SCREAM", 3.4, Sera.NAME_KEY)
