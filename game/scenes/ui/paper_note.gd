class_name PaperNote
extends Control
## 畫面右邊一張紙（公會的綠色委託單、佈告欄上的委託）：場景裡的紙在玩的距離只看得到一小片顏色，
## 要讀的時候把它「拿到眼前」——標題＋幾行字，紙稍微歪一點；要的話再蓋一個紅色的章（stamp）。
## 字都是翻譯 key。開的時候從右邊滑進來，close() 淡出後自己拿掉。
## 紙上的字可以當場改：strike(第幾行) 劃掉一行、add_line(key, 墨色) 在最下面補寫一行（阿展改辭工單）。

const WIDTH: float = 420.0
const MARGIN_RIGHT: float = 56.0
## 紙的中心在畫面高度的這個比例（對話框在下面，紙放在右邊偏上）
const CENTER_Y: float = 0.4
const SLIDE: float = 60.0
const TILT_DEG: float = -2.5
## 劃掉一行：橫線從左畫到右要多久；補寫的一行淡進來要多久
const STRIKE_SEC: float = 0.35
const WRITE_SEC: float = 0.45

var title_key: String = ""
var line_keys: PackedStringArray = []
var stamp_key: String = ""
var _ink: Color
var _paper: PanelContainer
var _lines: VBoxContainer
var _stamp: Label
## 標題以外的每一行（照順序；strike 用）、被劃掉的是哪幾行
var _line_labels: Array[Label] = []
var struck: PackedInt32Array = []


## paper＝紙的顏色、ink＝字的顏色
static func create(p_title_key: String, p_line_keys: PackedStringArray, paper: Color, ink: Color) -> PaperNote:
	var n := PaperNote.new()
	n.name = "PaperNote"
	n.title_key = p_title_key
	n.line_keys = p_line_keys.duplicate()
	n._ink = ink
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = paper
	box.border_color = paper.darkened(0.35)
	box.set_border_width_all(2)
	box.set_corner_radius_all(3)
	box.shadow_color = Color(0, 0, 0, 0.35)
	box.shadow_size = 10
	box.shadow_offset = Vector2(4, 6)
	box.content_margin_left = 26
	box.content_margin_right = 26
	box.content_margin_top = 20
	box.content_margin_bottom = 24
	# 紙是一個 PanelContainer（排字），章是另外擺在上面的（容器會把子節點撐滿，章不能放在紙裡面）
	n._paper = PanelContainer.new()
	n._paper.name = "Paper"
	n._paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	n._paper.add_theme_stylebox_override("panel", box)
	n.add_child(n._paper)
	n._lines = VBoxContainer.new()
	n._lines.add_theme_constant_override("separation", 8)
	n._paper.add_child(n._lines)
	n._add_label(p_title_key, 24, true)
	var rule := ColorRect.new()
	rule.color = Color(ink, 0.45)
	rule.custom_minimum_size = Vector2(WIDTH - 52.0, 2)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	n._lines.add_child(rule)
	for k: String in p_line_keys:
		n._add_label(k, 19, false)
	return n


func _add_label(key: String, size: int, centered: bool) -> Label:
	var l := Label.new()
	l.text = key
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(WIDTH - 52.0, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", _ink)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lines.add_child(l)
	if not centered:
		_line_labels.append(l)
	return l


## 把第 index 行（從 0 算，不含標題）劃掉：一道橫線壓在字上，從左畫到右
func strike(index: int) -> void:
	if index < 0 or index >= _line_labels.size() or index in struck:
		return
	struck.append(index)
	var l: Label = _line_labels[index]
	var font_size: int = l.get_theme_font_size("font_size")
	var text_w: float = minf(l.get_theme_font("font").get_string_size(tr(l.text), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x, WIDTH - 52.0)
	var bar := ColorRect.new()
	bar.name = "Strike"
	bar.color = _ink
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.position = Vector2(-3.0, float(font_size) * 0.72)
	bar.size = Vector2(0.0, 3.0)
	l.add_child(bar)
	l.create_tween().tween_property(bar, "size:x", text_w + 6.0, STRIKE_SEC)


## 在最下面補寫一行（另一種墨色，淡進來）：紙跟著長高
func add_line(key: String, ink: Color) -> void:
	line_keys.append(key)
	var l: Label = _add_label(key, 19, false)
	l.add_theme_color_override("font_color", ink)
	l.modulate.a = 0.0
	l.create_tween().tween_property(l, "modulate:a", 1.0, WRITE_SEC)
	_refit.call_deferred()


func _refit() -> void:
	_paper.reset_size()
	size = _paper.size


func _ready() -> void:
	modulate.a = 0.0
	_place.call_deferred()


func _place() -> void:
	_paper.reset_size()
	size = _paper.size
	var vp: Vector2 = get_viewport_rect().size
	pivot_offset = size * 0.5
	rotation_degrees = TILT_DEG
	var to := Vector2(vp.x - size.x - MARGIN_RIGHT, vp.y * CENTER_Y - size.y * 0.5)
	position = to + Vector2(SLIDE, 0)
	var t := create_tween().set_parallel(true)
	t.tween_property(self, "modulate:a", 1.0, 0.25)
	t.tween_property(self, "position", to, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## 蓋章：紅色的字斜斜地壓在紙的右下角，從大縮到原來的大小（像一下蓋下去）
func stamp(key: String) -> void:
	if _stamp != null:
		return
	stamp_key = key
	_stamp = Label.new()
	_stamp.name = "Stamp"
	_stamp.text = key
	_stamp.add_theme_font_size_override("font_size", 34)
	_stamp.add_theme_color_override("font_color", Color(0.78, 0.08, 0.06, 0.92))
	_stamp.add_theme_color_override("font_outline_color", Color(0.78, 0.08, 0.06, 0.92))
	_stamp.add_theme_constant_override("outline_size", 2)
	_stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stamp)
	_place_stamp.call_deferred()


func _place_stamp() -> void:
	_stamp.reset_size()
	_stamp.position = Vector2(size.x - _stamp.size.x - 30.0, size.y - _stamp.size.y - 18.0)
	_stamp.pivot_offset = _stamp.size * 0.5
	_stamp.rotation_degrees = -14.0
	_stamp.scale = Vector2.ONE * 2.2
	_stamp.modulate.a = 0.0
	var t := create_tween().set_parallel(true)
	t.tween_property(_stamp, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(_stamp, "modulate:a", 1.0, 0.1)


func close(after: float = 0.0) -> void:
	var t := create_tween()
	if after > 0.0:
		t.tween_interval(after)
	t.tween_property(self, "modulate:a", 0.0, 0.35)
	t.tween_callback(queue_free)
