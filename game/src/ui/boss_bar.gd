class_name BossBar
extends Control
## Boss 的生命條（畫面上方中間）：名字＋一條長的，剛被扣掉的那一段是紅的。場上有醒著、還活著的 Boss（"boss" 群組：PlagueGolem）才出現，
## 對話中收起來。狂暴之後整條變成橘紅色。核心還在（生命扣不到底線以下）的時候，底線那裡有一道紫色的刻痕——砍到那裡就停住不是壞掉；
## 核心可以粉碎了：刻痕拿掉、剩下的那一段變成金色。純顯示：每幀從場景讀。

const BAR_W: float = 560.0
const BAR_H: float = 12.0
const TOP: float = 58.0
const COL_BG: Color = Color(0.05, 0.06, 0.08, 0.7)
const COL_HP: Color = Color(0.56, 0.86, 0.42)
const COL_RAGE: Color = Color(1.0, 0.42, 0.2)
const COL_LOSS: Color = Color(0.86, 0.3, 0.26, 0.9)
const COL_CORE: Color = Color(0.78, 0.5, 1.0)
const COL_OPEN: Color = Color(1.0, 0.82, 0.36)
const COL_FRAME: Color = Color(0.9, 0.88, 0.8, 0.85)

var ratio: float = 1.0
var shown: bool = false
var enraged: bool = false
## 生命最低只能扣到幾成（0＝沒有底線）；核心可以粉碎了沒
var floor_ratio: float = 0.0
var core_open: bool = false
var trail: BarTrail = BarTrail.new()
var _name: Label
var _alpha: float = 0.0


func _ready() -> void:
	name = "BossBar"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_name = Label.new()
	_name.name = "Name"
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.add_theme_font_size_override("font_size", 22)
	_name.add_theme_color_override("font_color", COL_FRAME)
	_name.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	_name.add_theme_constant_override("shadow_offset_y", 2)
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name)
	modulate.a = 0.0


func boss_name_key() -> String:
	return _name.text


func _process(delta: float) -> void:
	refresh(get_tree().get_first_node_in_group("boss") as PlagueGolem)
	trail.step(ratio, delta)
	_alpha = move_toward(_alpha, 1.0 if shown else 0.0, delta * 3.0)
	modulate.a = _alpha
	_name.size = Vector2(BAR_W, 30.0)
	_name.position = Vector2((size.x - BAR_W) * 0.5, TOP - 34.0)
	queue_redraw()


## 從場景讀（測試直接呼叫）
func refresh(boss: PlagueGolem) -> void:
	shown = boss != null and boss.awake and not boss.health.is_dead() and not Game.is_in_dialogue()
	if boss == null:
		return
	ratio = boss.health.ratio()
	enraged = boss.phases.is_enraged()
	floor_ratio = boss.phases.floor_ratio()
	core_open = boss.phases.core_open
	_name.text = PlagueGolem.NAME_KEY


func _draw() -> void:
	var o := Vector2((size.x - BAR_W) * 0.5, TOP)
	draw_rect(Rect2(o - Vector2(2, 2), Vector2(BAR_W + 4.0, BAR_H + 4.0)), COL_BG)
	draw_rect(Rect2(o, Vector2(BAR_W * clampf(trail.base_ratio(), 0.0, 1.0), BAR_H)), COL_OPEN if core_open else (COL_RAGE if enraged else COL_HP))
	var loss: float = trail.loss_span()
	if loss > 0.0:
		draw_rect(Rect2(o + Vector2(BAR_W * clampf(trail.ratio, 0.0, 1.0), 0.0), Vector2(BAR_W * loss, BAR_H)), COL_LOSS)
	if floor_ratio > 0.0:
		draw_rect(Rect2(o + Vector2(BAR_W * floor_ratio - 1.5, -4.0), Vector2(3.0, BAR_H + 8.0)), COL_CORE)
	draw_rect(Rect2(o - Vector2(2, 2), Vector2(BAR_W + 4.0, BAR_H + 4.0)), COL_FRAME, false, 1.5)
