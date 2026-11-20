class_name Hud
extends CanvasLayer
## 關卡 HUD：左上目前目標＋下面一行操作提示（一直在畫面上），右上角的目標清單（任務階段有 checklist 的時候），右下存檔提示，目標指引（ObjectiveGuide）。
## 目標換了會淡入。主線做完（目前的內容到底了）：中央跳「未完待續」，左上改寫「目前的內容到這裡」。
## 以前目標 8 秒後會淡掉、要按鍵才再出現——Jacky 2026-11-14 玩過：「不知道要幹嘛，畫面也沒有什麼指引」。
## 進入檢查點（自動存檔）時右下閃一下「已存檔」（失敗則顯示「存檔失敗」）。

const OBJECTIVE_FADE_SEC: float = 0.6
## 主線做完之後左上那一行、中央那兩行
const STORY_END_KEY: String = "HUD_STORY_END"
const STORY_END_LINES: PackedStringArray = ["HUD_STORY_END_LINE1", "HUD_STORY_END_LINE2"]
## 做完最後一個目標之後隔多久才跳「未完待續」（先讓關卡自己的橫幅講完）
const STORY_END_DELAY: float = 4.5
const CENTER_LINE1_COLOR: Color = Color(0.95, 0.42, 0.38)
## 左上目標後面的暗底比字多出多少（背景很花：樹、草、孢子）
const OBJECTIVE_BACK_PAD: Vector2 = Vector2(18.0, 10.0)
## 橫幅（畫面上方中間的一行字）平常離上緣多遠；會碰到目標框的時候跟框隔多遠
const BANNER_TOP: int = 110
const BANNER_GAP: float = 16.0
const SAVED_SHOW_SEC: float = 2.2
## 狀態列後面的「可以釋放」提示
const RELEASE_HINT_KEY: String = "HUD_RELEASE_HINT"

var _objective: Label
## true＝左上的目標先收起來（關卡在演的時候：水晶的警報響著，「把手放到水晶上」已經做了，下一個目標還沒出來）
var objective_held: bool = false
var _objective_box: VBoxContainer
## 目標下面那一行操作提示（任務階段的 hint；裡面的 {attack} 這類動作名換成現在裝置的按鍵）
var _hint: Label
var _hint_key: String = ""
var _extra_hint_key: String = ""
var _extra_hint_args: Dictionary = {}
var _hint_device: int = -1
## 右上角的目標清單（任務階段的 checklist：`[2/5] 採集夜光毒蕈`、`[可選] …`）
const LIST_COLOR: Color = Color(0.93, 0.92, 0.88)
const LIST_OPTIONAL_COLOR: Color = Color(0.8, 0.78, 0.7)
const LIST_DONE_COLOR: Color = Color(1.0, 0.84, 0.4)
const LIST_MARGIN: Vector2 = Vector2(56.0, 44.0)
var _list_box: VBoxContainer
var _list_labels: Array[Label] = []
var _saved: Label
var _died: Label
var _saved_tween: Tween
var _objective_tween: Tween
var _banner: Label
## 戰鬥 HUD（生命、體力、指令）
var combat: CombatHud
## 目標指引（指向目前目標的小菱形＋距離）
var guide: ObjectiveGuide
## 互動提示（下方中央：拿藥瓶、拉起席菈）
var interact: InteractPrompt
## 狀態圖示（左下、諾恩生命條上方）
var status: StatusHud
## 反轉的畫面回饋（整個畫面邊緣：紫紅 → 碎裂 → 金光），墊在所有 HUD 文字下面
var reversal: ReversalOverlay
## 新版：可攜藥劑的數量（生命條右上方）與滿血時的確認框
var potion: PotionHud
var potion_confirm: PotionConfirm
## 裝備面板（按「裝備」鍵開關）
var gear_panel: GearPanel
var _potion_player: PlayerController
var _banner_tween: Tween
## 畫面中間的兩行字（第一次反轉：「中毒 → 回血」「落在你身上的異常狀態，全都會反轉成增益。」）
var _center: VBoxContainer
## 中間那兩行現在是哪兩個翻譯 key（Label 上放的是翻好、折好行的字）
var _center_keys: PackedStringArray = []
## 中間那兩行字平常的高度（show_center_lines 算的）；對話中改放在 CENTER_TALK_Y
const CENTER_TALK_Y: float = 44.0
const CENTER_SLIDE_SPEED: float = 1400.0
## 對話中左下的狀態列與生命條往上讓：離對話框上緣多遠、滑多快（像素／秒）
const TALK_LIFT_GAP: float = 18.0
const TALK_LIFT_SPEED: float = 1200.0
var _center_y: float = 0.0
var _center_tween: Tween
var _text_back: StyleBoxFlat  # 中央兩行字與左上目標共用的暗底
## 第二行比第一行晚出現幾秒
const CENTER_LINE_GAP: float = 0.9
## 中央兩行字的暗底比字多出多少（左右、上下）
const CENTER_BACK_PAD: Vector2 = Vector2(30.0, 12.0)
const CENTER_LINE2_COLOR: Color = Color(1.0, 0.84, 0.4)
## 中央那兩行字一行最寬多少（px，畫面寬 1920）：超過就折行
const CENTER_MAX_WIDTH: float = 1500.0
## 角色頭上的一句話（諾恩的碎念、旁人的反應）：跟著角色走、不停住遊戲、不是對話框。同一個角色同時只有一句
const BARK_FADE_IN: float = 0.12
const BARK_FADE_OUT: float = 0.45
const BARK_RISE_PX: float = 16.0
const BARK_MAX: int = 3
const BARK_EDGE: float = 14.0
## 頭頂的那一點超出畫面這麼多（px）以內還算在畫面裡
const BARK_OFFSCREEN: float = 40.0
const BARK_STACK_GAP: float = 4.0
## 講的人看不到的時候，那一句改放在畫面下方中間（「名字：台詞」）：離畫面底邊多遠（px）、用哪個翻譯 key 把名字與台詞接起來
const BARK_NAMED_BOTTOM: float = 176.0
const BARK_NAMED_KEY: String = "BARK_NAMED"
## 講的人的臉被比較靠近鏡頭的另一個角色擋住就不顯示：第 99 輪的過肩連拍上，站在後面 8 m 的人講的話
## 畫在前面那個人的頭上，看起來像前面那個人講的。臉＝腳上面 head × BARK_FACE；擋人的身體＝腳到 BARK_BODY_HEIGHT、左右各 BARK_BODY_HALF 公尺。
const BARK_FACE: float = 0.76
const BARK_BODY_HEIGHT: float = 1.8
const BARK_BODY_HALF: float = 0.3
const BARK_BLOCKER_GROUPS: PackedStringArray = ["player", "heartbeat", "enemies"]
## 第一次連拍 24 px 的字在 1280×720 上只有 16 px 高、看不清楚（第 98 輪）——放大到跟中央提示差不多
const BARK_FONT_SIZE: int = 32
const BARK_COLOR: Color = Color(0.97, 0.94, 0.84)
var _bark_root: Control
## 畫面下方「名字：台詞」那一行後面的暗底（頭上的話沒有：字小、跟著人動，加了底反而擋人）
var _bark_back: StyleBoxFlat
const DIM_COLOR: Color = Color(0.012, 0.01, 0.02)
var _dim: ColorRect
var _dim_tween: Tween
## Boss 的生命條（畫面上方中間；場上有醒著的 Boss 才出現）
var boss_bar: BossBar
## 過場的鏡頭切走的那幾秒（粉碎核心的那一刀，FinisherCamera）：整個 HUD 收起來（生命條、狀態列、Boss 的生命條、目標、頭上的字）
var cinematic: bool = false:
	set(v):
		if v == cinematic:
			return
		cinematic = v
		if not _nohud:
			visible = not v
var _nohud: bool = false
var _barks: Array[Dictionary] = []


func _ready() -> void:
	layer = 10
	add_to_group(PauseMenu.HIDE_GROUP)  # 暫停時藏起來
	_build()
	var s: GameSession = Game.session
	s.stage_changed.connect(_on_stage_changed)
	s.quest_completed.connect(_on_quest_completed)
	s.checkpoint_reached.connect(_on_checkpoint)
	_refresh_objective(false)
	_saved.modulate.a = 0.0
	Game.player_died.connect(_on_player_died)
	# 設定改了（自動攻擊開／關）：操作提示跟著換
	Settings.changed.connect(_refresh_hint)
	# 截圖用：`--nohud` 整個 HUD 不顯示（Steam 膠囊圖替代版的背景、宣傳截圖）
	if App.parse_user_args(OS.get_cmdline_user_args()).has("nohud"):
		_nohud = true
		visible = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _hint != null:
		_refresh_hint()


## 橫幅離畫面上緣多遠：平常 BANNER_TOP；字長到會伸進左上角的目標框（探索時操作提示那一行很長）就放到框的下面，不疊在一起
func banner_top(banner_width: float) -> int:
	var left: float = (get_viewport().get_visible_rect().size.x - banner_width) * 0.5
	var box_right: float = _objective_box.position.x + _objective_box.size.x + OBJECTIVE_BACK_PAD.x
	if _objective_box.visible and left < box_right + BANNER_GAP:
		return maxi(BANNER_TOP, int(_objective_box.position.y + _objective_box.size.y + OBJECTIVE_BACK_PAD.y + BANNER_GAP))
	return BANNER_TOP


## 畫面暗一下（營火休息）：out_sec 秒暗到全黑 → 黑著 hold_sec 秒（黑下去的那一刻叫 at_dark：關卡在這時候把人擺好）→ in_sec 秒亮回來
func dim_blink(out_sec: float, hold_sec: float, in_sec: float, at_dark: Callable = Callable()) -> void:
	if _dim_tween != null:
		_dim_tween.kill()
	_dim.visible = true
	_dim_tween = create_tween()
	_dim_tween.tween_property(_dim, "color:a", 1.0, out_sec)
	if at_dark.is_valid():
		_dim_tween.tween_callback(at_dark)
	_dim_tween.tween_interval(hold_sec)
	_dim_tween.tween_property(_dim, "color:a", 0.0, in_sec)
	_dim_tween.tween_callback(func() -> void: _dim.visible = false)


## 現在暗到多少（0＝沒有暗、1＝全黑）
func dim_amount() -> float:
	return _dim.color.a if _dim.visible else 0.0


func is_objective_shown() -> bool:
	return _objective_box.visible


func objective_text_key() -> String:
	return _objective.text


## 操作提示現在寫的字（已經換好按鍵；沒有提示是空的）
func hint_text() -> String:
	return _hint.text if _hint.visible else ""


func saved_label() -> Label:
	return _saved


func _build() -> void:
	# 畫面暗一下（dim_blink）的黑幕：排在最前面＝畫在 HUD 的字與條的底下，只蓋住場景
	_dim = ColorRect.new()
	_dim.name = "Dim"
	_dim.color = Color(DIM_COLOR, 0.0)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.visible = false
	add_child(_dim)
	reversal = ReversalOverlay.new()
	add_child(reversal)
	_objective_box = VBoxContainer.new()
	_objective_box.name = "Objective"
	_objective_box.position = Vector2(56, 44)
	_objective_box.add_theme_constant_override("separation", 3)
	_objective_box.draw.connect(func() -> void:
		_objective_box.draw_style_box(_text_back, Rect2(-OBJECTIVE_BACK_PAD, _objective_box.size + OBJECTIVE_BACK_PAD * 2.0)))
	add_child(_objective_box)
	var header := Label.new()
	header.name = "Header"
	header.text = "HUD_OBJECTIVE"
	header.add_theme_font_size_override("font_size", 17)
	header.add_theme_color_override("font_color", Color(0.75, 0.66, 0.48, 0.9))
	_objective_box.add_child(header)
	_objective = Label.new()
	_objective.name = "Text"
	_objective.add_theme_font_size_override("font_size", 28)
	_objective.add_theme_color_override("font_color", Color(0.93, 0.92, 0.88))
	_objective.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	_objective.add_theme_constant_override("shadow_offset_y", 2)
	_objective_box.add_child(_objective)
	_hint = Label.new()
	_hint.name = "Hint"
	_hint.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_hint.set_meta("glyph", true)  # 組好的字（不是翻譯 key）：UI 測試的「寫死文字」檢查跳過
	_hint.add_theme_font_size_override("font_size", 21)
	_hint.add_theme_color_override("font_color", Color(0.86, 0.82, 0.7))
	_hint.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	_hint.add_theme_constant_override("shadow_offset_y", 2)
	_objective_box.add_child(_hint)

	_list_box = VBoxContainer.new()
	_list_box.name = "Checklist"
	_list_box.add_theme_constant_override("separation", 3)
	_list_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_list_box.draw.connect(func() -> void:
		_list_box.draw_style_box(_text_back, Rect2(-OBJECTIVE_BACK_PAD, _list_box.size + OBJECTIVE_BACK_PAD * 2.0)))
	add_child(_list_box)
	var list_header := Label.new()
	list_header.name = "Header"
	list_header.text = "HUD_LIST_TITLE"
	list_header.add_theme_font_size_override("font_size", 17)
	list_header.add_theme_color_override("font_color", Color(0.75, 0.66, 0.48, 0.9))
	_list_box.add_child(list_header)

	_died = Label.new()
	_died.name = "Died"
	_died.text = "HUD_DIED"
	_died.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_died.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_died.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_died.add_theme_font_size_override("font_size", 44)
	_died.add_theme_color_override("font_color", Color(0.85, 0.78, 0.66))
	_died.hide()
	add_child(_died)
	_saved = Label.new()
	_saved.name = "Saved"
	_saved.text = "HUD_SAVED"
	_saved.add_theme_font_size_override("font_size", 18)
	_saved.add_theme_color_override("font_color", Color(0.85, 0.8, 0.68))
	_saved.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var anchor := Control.new()
	anchor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(anchor)
	anchor.add_child(_saved)
	_saved.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 40)
	# 戰鬥中的劇情提示（鐵架拋擲等）：畫面上方置中，淡入淡出
	_banner = Label.new()
	_banner.name = "Banner"
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 28)
	_banner.add_theme_color_override("font_color", Color(0.9, 0.93, 0.98))
	_banner.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_banner.add_theme_constant_override("shadow_offset_y", 2)
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor.add_child(_banner)
	_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, BANNER_TOP)
	_banner.modulate.a = 0.0
	_bark_root = Control.new()
	_bark_root.name = "Barks"
	_bark_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor.add_child(_bark_root)
	_center = VBoxContainer.new()
	_center.name = "CenterLines"
	_center.alignment = BoxContainer.ALIGNMENT_CENTER
	_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor.add_child(_center)
	# 兩行字後面一塊邊緣柔和的暗底：背景很亮、很花的時候（藥店那一排發光的瓶子）字才讀得出來
	_text_back = StyleBoxFlat.new()
	_text_back.bg_color = Color(0.02, 0.03, 0.04, 0.5)
	_text_back.set_corner_radius_all(20)
	_text_back.shadow_color = Color(0.02, 0.03, 0.04, 0.26)
	_text_back.shadow_size = 30
	_center.draw.connect(_draw_text_back)
	for i: int in 2:
		var l := Label.new()
		l.name = "Line%d" % (i + 1)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 34 if i == 0 else 30)
		l.add_theme_color_override("font_color", CENTER_LINE1_COLOR if i == 0 else CENTER_LINE2_COLOR)
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
		l.add_theme_constant_override("shadow_offset_y", 2)
		l.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.04, 0.9))
		l.add_theme_constant_override("outline_size", 6)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		l.set_meta("glyph", true)  # 翻好、折好行的字（不是翻譯 key）
		_center.add_child(l)
	_center.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	_center.modulate.a = 0.0
	combat = CombatHud.new()
	add_child(combat)
	boss_bar = BossBar.new()
	add_child(boss_bar)
	guide = ObjectiveGuide.new()
	add_child(guide)
	interact = InteractPrompt.new()
	add_child(interact)
	status = StatusHud.new()
	add_child(status)
	potion = PotionHud.new()
	add_child(potion)
	potion_confirm = PotionConfirm.new()
	add_child(potion_confirm)
	potion_confirm.decided.connect(_on_potion_decided)
	gear_panel = GearPanel.new()
	add_child(gear_panel)


## 對話中左下那一組要往上讓多少：生命條（在畫面底下往上 142 px）的下緣到對話框上緣之間留 TALK_LIFT_GAP
func _talk_lift() -> float:
	var box: DialogueBox = get_tree().get_first_node_in_group(DialogueBox.GROUP) as DialogueBox
	if box == null or not box.is_open():
		return 0.0
	var view_h: float = get_viewport().get_visible_rect().size.y
	return maxf(view_h - 142.0 + TALK_LIFT_GAP - box.panel_top(), 0.0)


func _process(delta: float) -> void:
	if App.last_device != _hint_device:
		_refresh_hint()
	# 對話中鏡頭在講話的人臉上（TalkCamera）：左上的目標與操作提示先收起來，講完再回來
	var talking: bool = Game.is_in_dialogue()
	_objective_box.visible = _objective.text != "" and not talking and not objective_held
	_refresh_checklist(talking)
	# 同一個階段裡目標也會換（objective_if：蕈採滿了，目標換成「把車停穩」）
	if Game.session.in_story() and not Game.session.story_finished() and Game.session.objective_key() != _objective.text:
		_refresh_objective(true)
	# 左下的狀態列與生命條：對話框會蓋到它們的右半邊，所以對話中整組往上讓到對話框上面
	# （瘴氣裡那一段講的就是「你的血在回」：邊聽邊看得到生命往上爬）
	combat.lift = move_toward(combat.lift, _talk_lift() if talking else 0.0, TALK_LIFT_SPEED * delta)
	# 中間那兩行字（第一次反轉的說明）還亮著就開始對話時：移到畫面最上面，不蓋住講話的人的臉
	_center.position.y = move_toward(_center.position.y, CENTER_TALK_Y if talking else _center_y, CENTER_SLIDE_SPEED * delta)
	var player: Node3D = get_tree().get_first_node_in_group("player") as Node3D
	var pc: PlayerController = player as PlayerController
	# 身上的毒可以放出去的時候（戰鬥場），那一列後面寫按哪個鍵、會扣多少
	var power: float = pc.release_power() if pc != null else 0.0
	var hint: String = ""
	if power > 0.0:
		hint = tr(RELEASE_HINT_KEY).format({"key": InputGlyphs.label_for_action("release", App.last_device), "dmg": int(power)})
	status.refresh(pc.status_effects if pc != null else null, PlayerController.RELEASE_STATUS, hint)
	gear_panel.player = pc
	reversal.refresh(pc.reversal_cue if pc != null else null)
	# 戰鬥 HUD 的諾恩名字在 size.y-174；狀態一列 34，往上長
	var view_h: float = get_viewport().get_visible_rect().size.y
	status.position = Vector2(56.0, view_h - 182.0 - status.custom_minimum_size.y - combat.lift)
	_refresh_potion(pc, view_h, delta)
	if talking:
		potion.visible = false
	# 畫面中間那兩行字還在的時候先不畫指引的菱形（一進公會時菱形正好疊在字的中間）
	guide.refresh(get_parent(), player, get_viewport().get_camera_3d(), combat.in_combat or not center_lines().is_empty(), delta)
	_update_barks(delta)


## 角色頭上跳一句話（翻譯 key 或已經翻好的字），seconds 秒後淡掉。head＝字浮在腳上面幾公尺。
## 同一個角色的上一句直接換掉；同時最多 BARK_MAX 句（最舊的先拿掉）。
## who＝講的人的名字（翻譯 key）：有給的話，講的人不在畫面裡、或臉被別人擋住時，這一句改成畫面下方的「名字：台詞」
## （席菈平常跟在鏡頭後面——她喊的話不這樣放，玩家根本看不到）；沒給就照舊不顯示。
func show_bark(speaker: Node3D, key: String, seconds: float = 2.4, who: String = "", color: Color = BARK_COLOR, head: float = 2.1) -> void:
	if speaker == null or key == "":
		return
	var i: int = _barks.size() - 1
	while i >= 0:
		if _barks[i]["speaker"] == speaker:
			(_barks[i]["label"] as Label).queue_free()
			_barks.remove_at(i)
		i -= 1
	while _barks.size() >= BARK_MAX:
		(_barks[0]["label"] as Label).queue_free()
		_barks.remove_at(0)
	var l := Label.new()
	l.text = key
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", BARK_FONT_SIZE)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.04, 0.95))
	l.add_theme_constant_override("outline_size", 6)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.modulate.a = 0.0
	_bark_root.add_child(l)
	_barks.append({"speaker": speaker, "label": l, "key": key, "age": 0.0, "life": maxf(seconds, 0.2), "head": head, "who": who, "backed": false})
	_update_barks(0.0)


## 現在畫面上有哪幾句（key；測試用）
func bark_keys() -> PackedStringArray:
	var out := PackedStringArray()
	for b: Dictionary in _barks:
		out.append(str(b["key"]))
	return out


func _update_barks(delta: float) -> void:
	if _barks.is_empty():
		return
	var i: int = _barks.size() - 1
	while i >= 0:
		var old: Dictionary = _barks[i]
		old["age"] = float(old["age"]) + delta
		if float(old["age"]) >= float(old["life"]) or not is_instance_valid(old["speaker"]):
			(old["label"] as Label).queue_free()
			_barks.remove_at(i)
		i -= 1
	var cam: Camera3D = get_viewport().get_camera_3d()
	var view: Vector2 = get_viewport().get_visible_rect().size
	var placed: Array[Rect2] = []
	# 中間那兩行字亮著的時候，頭上的話讓開它（教學戰：席菈的道歉跟「反轉成什麼」同時出現，疊在一起兩邊都看不懂）
	if not center_lines().is_empty():
		placed.append(_center.get_global_rect())
	for b: Dictionary in _barks:
		var l: Label = b["label"] as Label
		var age: float = float(b["age"])
		var life: float = float(b["life"])
		l.modulate.a = clampf(minf(age / BARK_FADE_IN, (life - age) / BARK_FADE_OUT), 0.0, 1.0)
		if cam == null:
			continue
		var at: Vector3 = (b["speaker"] as Node3D).global_position + Vector3.UP * float(b["head"])
		var on: Vector2 = cam.unproject_position(at)
		var seen: bool = not cam.is_position_behind(at) and Rect2(Vector2.ZERO, view).grow(BARK_OFFSCREEN).has_point(on) \
			and not bark_speaker_hidden(cam, b["speaker"] as Node3D, float(b["head"]))
		# 講話的人看不到（不在畫面裡、在鏡頭後面、臉被別人擋住）：知道名字就改成畫面下方的「名字：台詞」；
		# 不知道名字就不顯示——貼在畫面邊上的一句話看不出是誰講的（第 98 輪的連拍）
		var who: String = str(b["who"])
		# 對話中不顯示：畫面下方那一行會壓在對話框底下，頭上的那一句在近景裡飄到畫面外
		l.visible = (seen or who != "") and not Game.is_in_dialogue()
		if not l.visible:
			continue
		var words: String = str(b["key"]) if seen else tr(BARK_NAMED_KEY).format({"who": tr(who), "line": tr(str(b["key"]))})
		if l.text != words:
			l.text = words
		# 放在畫面下方的那一行墊一塊暗底：地面是亮的苔與落葉時，光靠描邊看不清楚
		if bool(b["backed"]) == seen:
			b["backed"] = not seen
			if seen:
				l.remove_theme_stylebox_override("normal")
			else:
				l.add_theme_stylebox_override("normal", _named_bark_back())
		var size: Vector2 = l.get_minimum_size()
		var p: Vector2 = on - Vector2(size.x * 0.5, size.y + BARK_RISE_PX * age / life)
		if not seen:
			p = Vector2((view.x - size.x) * 0.5, view.y - BARK_NAMED_BOTTOM - size.y)
		var rect := Rect2(Vector2(clampf(p.x, BARK_EDGE, maxf(view.x - size.x - BARK_EDGE, BARK_EDGE)), clampf(p.y, BARK_EDGE, maxf(view.y - size.y - BARK_EDGE, BARK_EDGE))), size)
		# 幾個人站得近（或離鏡頭遠）的時候字會疊在一起看不懂（第 98 輪的連拍）：後講的往上讓，上面沒位置就往下
		var step: float = -(size.y + BARK_STACK_GAP)
		var tries: int = 0
		while tries < BARK_MAX * 2 and _bark_blocked(rect, placed):
			if rect.position.y + step < BARK_EDGE:
				step = size.y + BARK_STACK_GAP
			rect.position.y += step
			tries += 1
		l.position = rect.position
		placed.append(rect)


func _named_bark_back() -> StyleBoxFlat:
	if _bark_back == null:
		_bark_back = StyleBoxFlat.new()
		_bark_back.bg_color = Color(0.02, 0.03, 0.04, 0.58)
		_bark_back.set_corner_radius_all(16)
		_bark_back.content_margin_left = 22.0
		_bark_back.content_margin_right = 22.0
		_bark_back.content_margin_top = 6.0
		_bark_back.content_margin_bottom = 8.0
	return _bark_back


## 那一句現在有沒有墊暗底（測試用）
func bark_backed(key: String) -> bool:
	for b: Dictionary in _barks:
		if str(b["key"]) == key:
			return bool(b["backed"])
	return false


## 講的人的臉在畫面上是不是被另一個比較靠近鏡頭的角色（諾恩、席菈、還站著的敵人）的身體蓋住。
func bark_speaker_hidden(cam: Camera3D, speaker: Node3D, head: float) -> bool:
	if cam == null or speaker == null or not is_inside_tree():
		return false
	var face: Vector3 = speaker.global_position + Vector3.UP * head * BARK_FACE
	var on: Vector2 = cam.unproject_position(face)
	var far: float = cam.global_position.distance_to(face)
	var seen: Array[Node] = []
	for group: String in BARK_BLOCKER_GROUPS:
		for n: Node in get_tree().get_nodes_in_group(group):
			var other: Node3D = n as Node3D
			if other == null or other == speaker or seen.has(other):
				continue
			seen.append(other)
			var foe: EnemyActor = other as EnemyActor
			if foe != null and (foe.health == null or foe.health.is_dead()):
				continue
			var feet: Vector3 = other.global_position
			var top: Vector3 = feet + Vector3.UP * BARK_BODY_HEIGHT
			if cam.is_position_behind(feet) or cam.is_position_behind(top) or cam.global_position.distance_to(feet) > far - 0.5:
				continue
			var a: Vector2 = cam.unproject_position(top)
			var b: Vector2 = cam.unproject_position(feet)
			var half: float = absf(b.y - a.y) * BARK_BODY_HALF / BARK_BODY_HEIGHT
			if on.y >= minf(a.y, b.y) and on.y <= maxf(a.y, b.y) and absf(on.x - (a.x + b.x) * 0.5) <= half:
				return true
	return false


func _bark_blocked(rect: Rect2, placed: Array[Rect2]) -> bool:
	for r: Rect2 in placed:
		if r.intersects(rect):
			return true
	return false


## 畫面上看得到的那幾句現在寫的字（頭上的是翻譯 key，畫面下方的是接好名字的字；測試用）
func bark_texts() -> PackedStringArray:
	var out := PackedStringArray()
	for b: Dictionary in _barks:
		var l: Label = b["label"] as Label
		if l.visible:
			out.append(l.text)
	return out


## 畫面上看得到的那幾句各佔哪一塊（測試用）
func bark_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for b: Dictionary in _barks:
		var l: Label = b["label"] as Label
		if l.visible:
			out.append(Rect2(l.position, l.get_minimum_size()))
	return out


## 可攜藥劑（新版）：數量一格在諾恩生命條的右上方；釘住時生命條也跟著亮（看得到現在滿不滿血）。
func _refresh_potion(pc: PlayerController, view_h: float, delta: float) -> void:
	var in_story: bool = Game.session != null and Game.session.in_story()
	var count: int = int(Game.session.state.items.get(PlayerController.PORTABLE_ITEM, 0)) if in_story else 0
	combat.force_bars = potion.pinned and count > 0
	potion.refresh(count, combat.bars_shown, delta)
	potion.position = Vector2(56.0 + CombatHud.BAR_W - PotionHud.WIDTH, view_h - 150.0 - 34.0)
	if pc != _potion_player:
		_potion_player = pc
		if pc != null and not pc.potion_needs_confirm.is_connected(_on_potion_needs_confirm):
			pc.potion_needs_confirm.connect(_on_potion_needs_confirm)


func _on_potion_needs_confirm(_item_id: String) -> void:
	potion_confirm.open()


## 確認框選完：喝＝帶 confirmed 再喝一次；先收著＝什麼都不做
func _on_potion_decided(drink: bool) -> void:
	if drink:
		if _potion_player != null and is_instance_valid(_potion_player):
			_potion_player.use_potion(true)


## 左上的目標照現在的主線階段重寫（主線做完＝「目前的內容到這裡」）；fade_in＝淡入，不然直接出現。之後一直留在畫面上。
func _refresh_objective(fade_in: bool) -> void:
	var s: GameSession = Game.session
	var key: String = STORY_END_KEY if s.story_finished() else s.objective_key()
	_objective.text = key
	_objective_box.visible = key != ""
	_hint_key = s.hint_key()
	_refresh_hint()
	if _objective_tween != null:
		_objective_tween.kill()
	_objective_box.modulate.a = 1.0
	if fade_in and is_inside_tree():
		_objective_box.modulate.a = 0.0
		_objective_tween = create_tween()
		_objective_tween.tween_property(_objective_box, "modulate:a", 1.0, OBJECTIVE_FADE_SEC)


## 右上角的目標清單：照現在主線階段的 checklist 重寫（沒有清單、對話中、主線做完了就收起來）。
## 要數的寫 [幾/幾]、可選的寫 [可選]、做完的寫 [完成]（金色）。
func _refresh_checklist(talking: bool) -> void:
	var lines: PackedStringArray = checklist_lines()
	_list_box.visible = not lines.is_empty() and not talking
	if not _list_box.visible:
		return
	var items: Array[Dictionary] = Game.session.checklist()
	while _list_labels.size() < lines.size():
		var l := Label.new()
		l.add_theme_font_size_override("font_size", 23)
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
		l.add_theme_constant_override("shadow_offset_y", 2)
		l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		l.set_meta("glyph", true)  # 組好的字（不是翻譯 key）
		_list_box.add_child(l)
		_list_labels.append(l)
	for i: int in _list_labels.size():
		var l: Label = _list_labels[i]
		l.visible = i < lines.size()
		if not l.visible:
			continue
		if l.text != lines[i]:
			l.text = lines[i]
		var color: Color = LIST_DONE_COLOR if bool(items[i]["done"]) else (LIST_OPTIONAL_COLOR if bool(items[i]["optional"]) else LIST_COLOR)
		l.add_theme_color_override("font_color", color)
	_list_box.reset_size()
	_list_box.position = Vector2(get_viewport().get_visible_rect().size.x - _list_box.size.x - LIST_MARGIN.x, LIST_MARGIN.y)


## 目標清單現在寫的每一行（已經組好的字；沒有清單是空的）
func checklist_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	if Game.session == null or not Game.session.in_story() or Game.session.story_finished():
		return lines
	for it: Dictionary in Game.session.checklist():
		var text: String = tr(str(it["text"]))
		if bool(it["done"]):
			lines.append(tr("HUD_LIST_DONE").format({"text": text}))
		elif int(it["need"]) > 0:
			lines.append(tr("HUD_LIST_COUNT").format({"have": int(it["have"]), "need": int(it["need"]), "text": text}))
		elif bool(it["optional"]):
			lines.append(tr("HUD_LIST_OPTIONAL").format({"text": text}))
		else:
			lines.append(text)
	return lines


## 關卡加的第二行操作提示（翻譯 key；空的＝拿掉）：任務階段的提示寫不到的——劇情演到某一拍才開放的操作（向席菈要藥）。
## args＝字裡除了按鍵以外要填的東西（例：{sec} 還要等幾秒）。
func set_extra_hint(key: String, args: Dictionary = {}) -> void:
	if key == _extra_hint_key and args == _extra_hint_args:
		return
	_extra_hint_key = key
	_extra_hint_args = args
	_refresh_hint()


## 這個階段的操作提示現在用哪一句：自動攻擊開著、而且這一句有「_AUTO」的版本就用它（不寫「按哪個鍵攻擊」，改寫「靠近敵人會自己砍」）。
func hint_key_now() -> String:
	var auto_key: String = _hint_key + "_AUTO"
	return auto_key if Settings.auto_attack and tr(auto_key) != auto_key else _hint_key


## 操作提示：翻譯好的字裡 {attack}、{dodge} 這類動作名換成現在裝置的按鍵；{move}、{look} 是移動與轉視角。
func _refresh_hint() -> void:
	_hint_device = App.last_device
	_hint.visible = _hint_key != "" or _extra_hint_key != ""
	if not _hint.visible:
		return
	var pad: bool = _hint_device == InputGlyphs.Device.PAD
	var keys: Dictionary = {"move": "[%s]" % tr("HUD_MOVE_PAD"), "look": "[%s]" % tr("HUD_LOOK_PAD" if pad else "HUD_LOOK_KBM")}
	if not pad:
		var wasd: String = ""
		for action: String in ["move_forward", "move_left", "move_back", "move_right"]:
			wasd += InputGlyphs.label_for_action(action, _hint_device).trim_prefix("[").trim_suffix("]")
		keys["move"] = "[%s]" % wasd
	for action: String in InputSetup.ACTION_KEYS:
		keys[action] = InputGlyphs.label_for_action(action, _hint_device)
	var lines: PackedStringArray = []
	if _hint_key != "":
		lines.append(tr(hint_key_now()).format(keys))
	if _extra_hint_key != "":
		keys.merge(_extra_hint_args)
		lines.append(tr(_extra_hint_key).format(keys))
	_hint.text = "\n".join(lines)


func _on_stage_changed(quest_id: String, _from: String, _to: String) -> void:
	if quest_id == Game.session.main_quest():
		_refresh_objective(true)


## 主線做完：左上改寫，隔一下中央跳「未完待續」。
func _on_quest_completed(_quest_id: String) -> void:
	if not Game.session.story_finished():
		return
	_refresh_objective(true)
	if is_inside_tree():
		create_tween().tween_callback(show_center_lines.bind(STORY_END_LINES[0], STORY_END_LINES[1], 8.0, CENTER_LINE2_COLOR)).set_delay(STORY_END_DELAY)


func _on_checkpoint(_checkpoint_id: String) -> void:
	# 存檔在訊號之後才寫入，下一幀再看結果
	_show_saved.call_deferred()


func _on_player_died() -> void:
	if not is_inside_tree():
		return
	_died.show()
	_died.modulate.a = 0.0
	create_tween().tween_property(_died, "modulate:a", 1.0, 0.8)


func is_death_shown() -> bool:
	return _died.visible


## 「你倒下了」收掉（戰鬥場原地重來）
func hide_death() -> void:
	_died.hide()


## 畫面上方的一行提示（翻譯 key），停留 seconds 秒後淡出。
func show_banner(key: String, seconds: float = 3.0) -> void:
	_banner.text = key
	_banner.reset_size()
	_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, banner_top(_banner.size.x))
	if _banner_tween != null:
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner, "modulate:a", 1.0, 0.2)
	_banner_tween.tween_interval(seconds)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.6)


## 中央兩行字的暗底（畫在字的後面，跟著字一起淡入淡出）
func _draw_text_back() -> void:
	_center.draw_style_box(_text_back, Rect2(-CENTER_BACK_PAD, _center.size + CENTER_BACK_PAD * 2.0))


## 畫面中間的兩行字（不暫停遊戲）：第一行先出現，第二行晚 CENTER_LINE_GAP 秒，一起停留 seconds 秒後淡出。
## 第一行預設是紅的（壞東西上身）；不是壞消息的時候給別的顏色。
func show_center_lines(key1: String, key2: String, seconds: float = 4.0, line1_color: Color = CENTER_LINE1_COLOR) -> void:
	var l1: Label = _center.get_child(0) as Label
	var l2: Label = _center.get_child(1) as Label
	l1.add_theme_color_override("font_color", line1_color)
	_center_keys = PackedStringArray([key1, key2])
	l2.modulate.a = 0.0
	# 太長的一行（英文的說明常常比中文長一倍）從中間的空白折成兩行，不衝出畫面。
	# 不用 Label 的自動換行：放在容器裡的自動換行會把整塊的高度算得很高（後面的暗底跟著變成一大片）
	for i: int in 2:
		var l: Label = _center.get_child(i) as Label
		var text: String = tr(_center_keys[i])
		if l.get_theme_font("font").get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, l.get_theme_font_size("font_size")).x > CENTER_MAX_WIDTH:
			text = wrap_in_two(text)
		l.text = text
	_center.reset_size()
	_center.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	_center.position.y -= 150.0
	_center_y = _center.position.y
	_center.queue_redraw()
	if _center_tween != null:
		_center_tween.kill()
	_center_tween = create_tween()
	_center_tween.tween_property(_center, "modulate:a", 1.0, 0.25)
	_center_tween.tween_property(l2, "modulate:a", 1.0, 0.35).set_delay(CENTER_LINE_GAP)
	_center_tween.tween_interval(seconds)
	_center_tween.tween_property(_center, "modulate:a", 0.0, 0.8)


## 中間兩行字現在的內容（測試用；沒顯示時是空的）
## 中間那兩行字馬上收掉（收尾的鏡頭：畫面中間要乾淨）
func hide_center_lines() -> void:
	if _center_tween != null:
		_center_tween.kill()
	_center.modulate.a = 0.0


func center_lines() -> PackedStringArray:
	if _center.modulate.a <= 0.0 and (_center_tween == null or not _center_tween.is_running()):
		return PackedStringArray()
	return _center_keys


## 一行字從最靠近中間的空白折成兩行（沒有空白就不折）。純函式。
static func wrap_in_two(text: String) -> String:
	var mid: int = text.length() / 2
	var best: int = -1
	for i: int in text.length():
		if text[i] == " " and (best < 0 or absi(i - mid) < absi(best - mid)):
			best = i
	return text if best < 0 else text.substr(0, best) + "\n" + text.substr(best + 1)


## 立刻收掉上方的提示（截圖旗標直接跳段落時用：前一段的提示不該留到下一段的對話上）
func hide_banner() -> void:
	if _banner_tween != null:
		_banner_tween.kill()
	_banner.modulate.a = 0.0


func banner_text() -> String:
	return _banner.text if _banner.modulate.a > 0.0 or (_banner_tween != null and _banner_tween.is_running()) else ""


func _show_saved() -> void:
	if not is_inside_tree():
		return
	_saved.text = "HUD_SAVED" if Game.session.last_autosave_error == OK else "HUD_SAVE_FAILED"
	if _saved_tween != null:
		_saved_tween.kill()
	_saved.modulate.a = 0.0
	_saved_tween = create_tween()
	_saved_tween.tween_property(_saved, "modulate:a", 1.0, 0.25)
	_saved_tween.tween_interval(SAVED_SHOW_SEC)
	_saved_tween.tween_property(_saved, "modulate:a", 0.0, 0.6)
