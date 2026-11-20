class_name GearPanel
extends Control
## 裝備面板（按「裝備」鍵開關；劇本「裝備與技能面板教學」）：右半邊一張深色的板子——
## 銅幣、武器那一格（名字、說明、拿著時給自己什麼）、飾品那一格（戴著的、詛咒寫什麼、實際每秒回多少血）、
## 下面一列身上的狀態圖示（StatusHud：剛戴上的詛咒先是紅的、0.3 秒後翻成金的），最下面一行操作提示。
## 開著的時候遊戲不暫停（詛咒的回血看得到在跑），但玩家不能動（Game.CUTSCENE_GROUP）。互動鍵＝戴上／拿下飾品。
## 資料都從 Gear（GameState 的旗標）讀；戴上／拿下也寫回 Gear。對話中、沒有劇情時打不開。

signal closed

const ACTION: String = "gear"
const COL_TITLE: Color = Color(1.0, 0.86, 0.5)
const COL_TEXT: Color = Color(0.92, 0.9, 0.85)
const COL_DIM: Color = Color(0.66, 0.64, 0.6)
const COL_CURSE: Color = Color(0.95, 0.45, 0.4)
const COL_GOLD: Color = Color(1.0, 0.82, 0.36)
const PANEL_W: float = 520.0

## 誰的狀態（Hud 每幀給）
var player: PlayerController
var _open: bool = false
var _labels: Dictionary = {}
var _status: StatusHud
var _panel: PanelContainer


func _ready() -> void:
	name = "GearPanel"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.05, 0.07, 0.9)
	sb.border_color = Color(0.85, 0.68, 0.32, 0.7)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 22
	sb.content_margin_bottom = 20
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.custom_minimum_size = Vector2(PANEL_W, 0)
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.anchor_top = 0.17
	_panel.offset_left = -PANEL_W - 48.0
	_panel.offset_right = -48.0
	add_child(_panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	_panel.add_child(col)
	for spec: Array in [
		["Title", 28, COL_TITLE], ["Coins", 20, COL_GOLD], ["Gap1", 6, COL_DIM],
		["WeaponSlot", 16, COL_DIM], ["WeaponName", 22, COL_TEXT], ["WeaponDesc", 17, COL_DIM], ["WeaponCurse", 17, COL_GOLD], ["Gap2", 6, COL_DIM],
		["AccessorySlot", 16, COL_DIM], ["AccessoryName", 22, COL_TEXT], ["AccessoryDesc", 17, COL_DIM], ["AccessoryCurse", 17, COL_GOLD],
		["AccessoryActual", 18, COL_GOLD], ["Gap3", 6, COL_DIM],
	]:
		var l := Label.new()
		l.name = str(spec[0])
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(PANEL_W - 56.0, 0)
		l.add_theme_font_size_override("font_size", int(spec[1]))
		l.add_theme_color_override("font_color", spec[2] as Color)
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
		l.add_theme_constant_override("shadow_offset_y", 2)
		# 動態組字（翻譯＋數字）：UI 測試的「寫死文字」檢查會跳過
		l.set_meta("glyph", true)
		col.add_child(l)
		_labels[str(spec[0])] = l
	_status = StatusHud.new()
	col.add_child(_status)
	var hint := Label.new()
	hint.name = "Hint"
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", COL_DIM)
	hint.set_meta("glyph", true)
	col.add_child(hint)
	_labels["Hint"] = hint
	visible = false


func is_open() -> bool:
	return _open


func open() -> void:
	if _open or not is_inside_tree():
		return
	_open = true
	visible = true
	add_to_group(Game.CUTSCENE_GROUP)
	refresh()


func close() -> void:
	if not _open:
		return
	_open = false
	visible = false
	if is_in_group(Game.CUTSCENE_GROUP):
		remove_from_group(Game.CUTSCENE_GROUP)
	closed.emit()


func gear() -> Gear:
	return Gear.new(Game.session.state)


## 戴上／拿下飾品（互動鍵；測試也直接叫）。現在戴著就拿下；沒戴、身上有一只就戴上。回傳現在戴著的
func toggle_accessory() -> String:
	var g: Gear = gear()
	if g.accessory() != "":
		g.unequip_accessory()
	else:
		for id: String in (g.data.get("accessories", {}) as Dictionary):
			if g.owns(id):
				g.equip_accessory(id)
				break
	if player != null:
		player.refresh_accessory_curse()
	refresh()
	return g.accessory()


func _process(_delta: float) -> void:
	if not _open:
		if Input.is_action_just_pressed(ACTION) and _can_open():
			open()
		return
	if Input.is_action_just_pressed(ACTION) or Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("ui_cancel"):
		close()
		return
	if Input.is_action_just_pressed(Interactable.ACTION):
		toggle_accessory()
	refresh()


func _can_open() -> bool:
	return Game.session != null and Game.session.in_story() and not Game.is_in_dialogue() and not Game.is_player_locked() and player != null


## 把板子上的字照現在的裝備重寫一次
func refresh() -> void:
	if Game.session == null:
		return
	var g: Gear = gear()
	var rules: StatusRules = player.status_effects.rules if player != null else StatusRules.load_default()
	_put("Title", tr("GEAR_TITLE"))
	_put("Coins", tr("GEAR_COINS").format({"n": g.coins()}))
	_put("WeaponSlot", tr("GEAR_SLOT_WEAPON"))
	var w: Dictionary = g.weapon_def(g.weapon())
	_put("WeaponName", tr(str(w.get("name_key", ""))))
	_put("WeaponDesc", tr(str(w.get("desc_key", ""))))
	_put("WeaponCurse", _curse_line(rules, str(w.get("curse", "")), "GEAR_ON_HIT"))
	_put("AccessorySlot", tr("GEAR_SLOT_ACCESSORY"))
	var a_id: String = g.accessory()
	if a_id == "":
		_put("AccessoryName", tr("GEAR_EMPTY"))
		_put("AccessoryDesc", "")
		_put("AccessoryCurse", "")
		_put("AccessoryActual", "")
	else:
		var a: Dictionary = g.accessory_def(a_id)
		_put("AccessoryName", tr(str(a.get("name_key", ""))) + ("　" + tr("GEAR_TRIAL") if g.is_trial() else ""))
		_put("AccessoryDesc", tr(str(a.get("desc_key", ""))))
		_put("AccessoryCurse", _curse_line(rules, str(a.get("curse", "")), "GEAR_WORN"))
		_put("AccessoryActual", _actual_line(rules, str(a.get("curse", ""))))
	var can_toggle: bool = a_id != "" or _owns_any(g)
	var hint: String = tr("GEAR_HINT_CLOSE").format({"key": InputGlyphs.label_for_action(ACTION, App.last_device)})
	if can_toggle:
		hint = tr("GEAR_HINT_TOGGLE").format({"key": InputGlyphs.label_for_action(Interactable.ACTION, App.last_device)}) + "　" + hint
	_put("Hint", hint)
	if player != null:
		_status.refresh(player.status_effects)


func text_of(label: String) -> String:
	return (_labels[label] as Label).text if _labels.has(label) else ""


func _put(label: String, text: String) -> void:
	var l: Label = _labels.get(label) as Label
	if l != null:
		l.text = text
		l.visible = text != "" or label.begins_with("Gap")


func _owns_any(g: Gear) -> bool:
	for id: String in (g.data.get("accessories", {}) as Dictionary):
		if g.owns(id):
			return true
	return false


## 「戴著的時候：刺痛 → 回血」：每一種狀態反轉之後的寫法（諾恩身上一律反轉；reversed_key 本身就寫成「原本 → 變成」）
func _curse_line(rules: StatusRules, source_id: String, prefix_key: String) -> String:
	var names: PackedStringArray = []
	var flipped: PackedStringArray = []
	var src: String = source_id
	var guard: int = 0
	while src != "" and guard < 4:
		guard += 1
		var s: Dictionary = rules.sources.get(src, {}) as Dictionary
		var st: Dictionary = rules.statuses.get(str(s.get("status", "")), {}) as Dictionary
		if st.is_empty():
			break
		names.append(tr(str(st.get("name_key", ""))))
		flipped.append(tr(str(st.get("reversed_key", ""))))
		src = str(s.get("also", ""))
	if names.is_empty():
		return ""
	return tr(prefix_key).format({"boon": "、".join(flipped)})


## 戴著的飾品實際上每秒回多少血（身上那個狀態現在的強度；諾恩沒有反轉時是扣血）
func _actual_line(rules: StatusRules, source_id: String) -> String:
	var s: Dictionary = rules.sources.get(source_id, {}) as Dictionary
	var status_id: String = str(s.get("status", ""))
	if player == null or status_id == "" or not player.status_effects.has(status_id):
		return tr("GEAR_ACTUAL_WAIT")
	var rate: float = player.status_effects.rate(status_id)
	return tr("GEAR_ACTUAL_HEAL" if player.status_effects.reverses else "GEAR_ACTUAL_HURT").format({"n": snappedf(rate, 0.1)})


func _exit_tree() -> void:
	if is_in_group(Game.CUTSCENE_GROUP):
		remove_from_group(Game.CUTSCENE_GROUP)
