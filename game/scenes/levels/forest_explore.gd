class_name ForestExplore
extends Node
## 腐敗之森的自由探索（docs/story/chapter-1.md 時段 B）：採夜光毒蕈、通往祭壇的路。
## CorruptForest 生出它、給它諾恩、HUD 與席菈；它把東西放進關卡（目標指引要從關卡底下找節點）。位置照 ForestMap。
## 劇情旗標：ch1.mushrooms（採了幾朵）、ch1.mushroom_<n>（第 n 朵採過了）、ch1.altar_gate_reached（走到祭壇路口）、
## ch1.respawn（讀檔、倒下重來從哪裡開始："glade"／"camp"）。任務 data/quests/ch1_main.json 的 gather、to_altar 兩個階段看前兩個。

const QUEST: String = "ch1_main"
const STAGE_GATHER: String = "gather"
const STAGE_ALTAR: String = "to_altar"
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
var _gate_bark_in: float = 0.0


## 自由探索開放了沒（教學戰與戰後那段話都過了）
static func unlocked(state: GameState) -> bool:
	return str(state.quests.get(QUEST, "")) in [STAGE_GATHER, STAGE_ALTAR, StoryLogic.QUEST_DONE]


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
	_spawn_mushrooms()
	Game.session.stage_changed.connect(_on_stage_changed)


func _physics_process(delta: float) -> void:
	if not Game.session.in_story():
		return
	var st: GameState = Game.session.state
	var open: bool = unlocked(st)
	for m: Interactable in mushrooms:
		if is_instance_valid(m) and not m.is_queued_for_deletion():
			m.enabled = open and not bool(st.get_flag(_mushroom_flag(mushrooms.find(m)), false))
	_gate_bark_in = maxf(_gate_bark_in - delta, 0.0)
	if not open and player.global_position.z < NORTH_GATE_Z:
		player.global_position.z = NORTH_GATE_Z
		if _gate_bark_in <= 0.0 and sera.joined:
			_gate_bark_in = GATE_BARK_EVERY
			hud.show_bark(sera, "BARK_SERA_NOT_YET", 2.6, Sera.NAME_KEY)
	if stage() == STAGE_ALTAR and ForestMap.flat(player.global_position).distance_to(Vector2(ForestMap.ALTAR_GATE.x, ForestMap.ALTAR_GATE.y)) < ALTAR_REACH:
		Game.session.set_flag(FLAG_ALTAR, true)


func stage() -> String:
	return Game.session.quests.stage_of(QUEST)


## 還沒採的有幾朵（測試用）
func mushrooms_left() -> int:
	var n: int = 0
	for m: Interactable in mushrooms:
		if is_instance_valid(m) and not m.is_queued_for_deletion():
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
	m.enabled = false
	Game.session.state.set_flag(_mushroom_flag(i), true)
	Game.session.add_flag(FLAG_MUSHROOMS, 1)
	var have: int = int(Game.session.state.get_flag(FLAG_MUSHROOMS, 0))
	hud.show_banner(tr("CH1_MUSHROOM_PICKED").format({"have": mini(have, MUSHROOM_NEED), "need": MUSHROOM_NEED}), 2.0)
	Sfx.play_at(level, "glass_clink", m.global_position + Vector3.UP * 0.5, -6.0)
	Game.session.autosave()
	var t: Tween = m.create_tween()
	t.tween_property(m, "scale", Vector3.ONE * 0.05, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_callback(m.queue_free)


func _on_stage_changed(quest_id: String, _from: String, to: String) -> void:
	if quest_id != QUEST or not is_inside_tree():
		return
	if to == STAGE_GATHER:
		# 劇本的系統提示：自由探索開始
		hud.show_center_lines("CH1_EXPLORE_LINE1", "CH1_EXPLORE_LINE2", 7.0, Hud.CENTER_LINE2_COLOR)
	elif to == STAGE_ALTAR:
		# 採完準備回去的時候，祭壇那邊傳來慘叫（劇本節點 3 的開頭）
		hud.show_center_lines("CH1_SCREAM_LINE1", "CH1_SCREAM_LINE2", 6.0)
		hud.show_bark(sera, "BARK_SERA_SCREAM", 3.4, Sera.NAME_KEY)
