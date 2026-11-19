class_name EndCredits
extends CanvasLayer
## 「第一章　完」之後：製作名單從下往上捲（`data/credits.json`＋Godot 的授權全文），停在「感謝遊玩」，
## 再淡出、出下一章的預告（章名＋兩行＋「製作中」），播完呼叫 on_done（回標題）。
## 長按互動鍵（或確認鍵）跳過這一段：捲的時候跳到預告、預告的時候直接結束。
## 掛在關卡底下、在 Game 的黑幕（ScreenFade）上面一層；在場上的時候玩家不能動（Game.CUTSCENE_GROUP）。

const DATA_PATH: String = "res://data/credits.json"
const LAYER: int = 46
const INK: Color = Color(0.95, 0.92, 0.86)
const WARM: Color = Color(0.98, 0.8, 0.52)
const GREY: Color = Color(0.56, 0.58, 0.62)
## 捲的速度：每秒捲過畫面高度的幾分之幾（1080 高約 80 px/s）
const SCROLL_PER_SEC: float = 0.075
## 「感謝遊玩」停在畫面中間多久
const THANKS_HOLD_SEC: float = 3.0
const FADE_SEC: float = 1.0
const PREVIEW_IN_SEC: float = 1.2
const PREVIEW_HOLD_SEC: float = 6.5
## 開始後多久才接受跳過（「第一章　完」那張卡是按一下跳過：按著的那一下不要連這一段一起跳掉）
const SKIP_AFTER_SEC: float = 0.8
const SKIP_HOLD_SEC: float = 0.6

enum Part { ROLL, THANKS, PREVIEW, DONE }

var on_done: Callable = Callable()
var part: Part = Part.ROLL
var elapsed: float = 0.0
## 這一段（捲、停、預告）過了幾秒
var part_t: float = 0.0
var data: Dictionary = {}
var _black: ColorRect
var _roll: VBoxContainer
var _thanks: Label
var _preview: VBoxContainer
var _preview_title: Label
var _hint: GlyphLine
var _hold := HoldToSkip.new(SKIP_HOLD_SEC)
var _scale: float = 1.0


## 建立加到 parent 底下開始捲。time_scale：測試用（< 1 整段變短）。
static func play(parent: Node, done: Callable, time_scale: float = 1.0) -> EndCredits:
	var c := EndCredits.new()
	c.on_done = done
	c._scale = maxf(time_scale, 0.01)
	parent.add_child(c)
	return c


static func load_data() -> Dictionary:
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	if f == null:
		push_error("EndCredits: 讀不到 %s" % DATA_PATH)
		return {}
	var v: Variant = JSON.parse_string(f.get_as_text())
	return v as Dictionary if v is Dictionary else {}


func _init() -> void:
	name = "EndCredits"
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(Game.CUTSCENE_GROUP)
	data = load_data()
	_black = ColorRect.new()
	_black.name = "Black"
	_black.color = ScreenFade.COLOR
	_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	_black.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_black)
	_build_roll()
	_build_preview()
	_hint = GlyphLine.new().configure(16, Color(GREY, 0.75))
	_hint.name = "SkipHint"
	_hint.fit_content = false
	_hint.alignment = BoxContainer.ALIGNMENT_END
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_hint.offset_left = -520.0
	_hint.offset_top = -56.0
	_hint.offset_right = -36.0
	_hint.offset_bottom = -24.0
	add_child(_hint)


func _ready() -> void:
	_hint.set_line(tr("CREDITS_SKIP"), "interact", int(App.last_device))
	_place_roll(0.0)


func _label(text: String, font_size: int, color: Color, font_path: String, wrap_width: float = 0.0) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	var font: Font = UiFonts.load_font(font_path)
	if font != null:
		l.add_theme_font_override("font", font)
	if wrap_width > 0.0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(wrap_width, 0.0)
		l.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return l


func _gap(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0.0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _build_roll() -> void:
	_roll = VBoxContainer.new()
	_roll.name = "Roll"
	_roll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_roll.add_theme_constant_override("separation", 6)
	add_child(_roll)
	_roll.add_child(_label("GAME_TITLE", 44, INK, UiFonts.TITLE_SERIF))
	_roll.add_child(_label("CARD_END_SMALL", 24, Color(WARM, 0.9), UiFonts.UI_SANS))
	_roll.add_child(_gap(90.0))
	for sec: Variant in data.get("sections", []) as Array:
		var d: Dictionary = sec as Dictionary
		_roll.add_child(_label(str(d.get("role", "")), 22, Color(WARM, 0.9), UiFonts.UI_SANS))
		for n: Variant in d.get("names", []) as Array:
			_roll.add_child(_label(str(n), 32, INK, UiFonts.UI_SANS))
		_roll.add_child(_gap(54.0))
	# Godot 的授權（MIT：散布時要附上全文）
	var lic := _label(Engine.get_license_text(), 14, GREY, UiFonts.UI_SANS, 860.0)
	lic.name = "License"
	_roll.add_child(lic)
	_roll.add_child(_gap(160.0))
	_thanks = _label("CREDITS_THANKS", 52, INK, UiFonts.TITLE_SERIF)
	_thanks.name = "Thanks"
	_roll.add_child(_thanks)


func _build_preview() -> void:
	var p: Dictionary = data.get("preview", {}) as Dictionary
	_preview = VBoxContainer.new()
	_preview.name = "Preview"
	_preview.set_anchors_preset(Control.PRESET_FULL_RECT)
	_preview.alignment = BoxContainer.ALIGNMENT_CENTER
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview.add_theme_constant_override("separation", 14)
	_preview.modulate.a = 0.0
	add_child(_preview)
	_preview.add_child(_label(str(p.get("small", "")), 24, Color(WARM, 0.9), UiFonts.UI_SANS))
	_preview_title = _label(str(p.get("title", "")), 56, INK, UiFonts.TITLE_SERIF)
	_preview_title.name = "Title"
	_preview.add_child(_preview_title)
	var rule := ColorRect.new()
	rule.color = Color(WARM, 0.55)
	rule.custom_minimum_size = Vector2(140.0, 1.5)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview.add_child(rule)
	_preview.add_child(_gap(10.0))
	for line: Variant in p.get("lines", []) as Array:
		_preview.add_child(_label(str(line), 28, Color(INK, 0.88), UiFonts.TITLE_SERIF))
	_preview.add_child(_gap(26.0))
	_preview.add_child(_label(str(p.get("foot", "")), 20, Color(GREY, 0.9), UiFonts.UI_SANS))


func _screen() -> Vector2:
	return get_viewport().get_visible_rect().size if is_inside_tree() else Vector2(1920, 1080)


## 名單的上緣在哪（捲了 t 秒）：一開始在畫面最下面，「感謝遊玩」的中間捲到畫面中間就停
func _place_roll(t: float) -> void:
	var screen: Vector2 = _screen()
	var w: float = maxf(_roll.get_combined_minimum_size().x, 900.0)
	_roll.size = Vector2(w, _roll.get_combined_minimum_size().y)
	_roll.position = Vector2((screen.x - w) * 0.5, roll_top(t, screen.y, thanks_center()))


## 名單上緣的位置（純函式）：從畫面下緣往上捲，最多捲到 stop_center 那一點在畫面中間
static func roll_top(t: float, screen_h: float, stop_center: float) -> float:
	var top: float = screen_h - t * SCROLL_PER_SEC * screen_h
	return maxf(top, screen_h * 0.5 - stop_center)


## 「感謝遊玩」的中間離名單上緣多遠
func thanks_center() -> float:
	var h: float = _roll.get_combined_minimum_size().y
	return h - _thanks.get_combined_minimum_size().y * 0.5


## 捲到「感謝遊玩」停在中間要幾秒
func roll_sec() -> float:
	var screen_h: float = _screen().y
	return (screen_h - (screen_h * 0.5 - thanks_center())) / (SCROLL_PER_SEC * screen_h)


func _process(delta: float) -> void:
	if part == Part.DONE:
		return
	var dt: float = minf(delta / maxf(Engine.time_scale, 0.01), 0.1) / _scale
	elapsed += dt
	part_t += dt
	if elapsed > SKIP_AFTER_SEC:
		var held: bool = Input.is_action_pressed("interact") or Input.is_action_pressed("ui_accept")
		if _hold.update(held, dt * _scale):
			skip()
			return
	match part:
		Part.ROLL:
			_place_roll(part_t)
			if part_t >= roll_sec():
				_to(Part.THANKS)
		Part.THANKS:
			_place_roll(roll_sec())
			if part_t > THANKS_HOLD_SEC:
				_roll.modulate.a = clampf(1.0 - (part_t - THANKS_HOLD_SEC) / FADE_SEC, 0.0, 1.0)
			if part_t >= THANKS_HOLD_SEC + FADE_SEC:
				_to(Part.PREVIEW)
		Part.PREVIEW:
			var total: float = PREVIEW_IN_SEC * 2.0 + PREVIEW_HOLD_SEC
			var a: float = minf(part_t / PREVIEW_IN_SEC, 1.0)
			if part_t > PREVIEW_IN_SEC + PREVIEW_HOLD_SEC:
				a = clampf((total - part_t) / PREVIEW_IN_SEC, 0.0, 1.0)
			_preview.modulate.a = a
			if part_t > PREVIEW_IN_SEC + PREVIEW_HOLD_SEC:
				# 最後一段：配樂跟著字一起收掉（回到標題再從黑淡進來）
				Game.fade.set_duck(1.0 - a)
			if part_t >= total:
				finish()


func _to(p: Part) -> void:
	part = p
	part_t = 0.0
	if p == Part.PREVIEW:
		_roll.visible = false


## 跳過這一段：捲的時候直接到預告，預告的時候結束
func skip() -> void:
	if part == Part.ROLL or part == Part.THANKS:
		_to(Part.PREVIEW)
	else:
		finish()


## 結束：維持全黑，呼叫 on_done 一次（回標題：Game 的黑幕接手、標題從黑淡進來）
func finish() -> void:
	if part == Part.DONE:
		return
	part = Part.DONE
	_preview.modulate.a = 0.0
	_roll.visible = false
	_hint.visible = false
	Game.fade.cover()
	if on_done.is_valid():
		on_done.call()


## 測試與截圖用：名單上的字（翻譯過的）
func roll_texts() -> PackedStringArray:
	var out: PackedStringArray = []
	for c: Node in _roll.get_children():
		if c is Label:
			out.append(tr((c as Label).text))
	return out


func preview_title() -> String:
	return tr(_preview_title.text)


## 截圖用：停在某一段的某一刻
func hold_at(p: Part, t: float) -> void:
	_to(p)
	part_t = t
	set_process(false)
	if p == Part.PREVIEW:
		_preview.modulate.a = 1.0
	else:
		_place_roll(t if p == Part.ROLL else roll_sec())
