extends Node
## 遊戲流程外殼：持有 GameSession，負責新遊戲／繼續／切換關卡。
## 邏輯都在 GameSession（res://src/core/game_session.gd），這裡只做場景切換。
##
## 開發用：`godot --path game -- --level=guild_hall`（或 corrupt_forest、ruined_altar）直接開新遊戲進關卡（截圖驗證用，存檔寫到 DEV_SAVE_DIR）；
## `-- --benchmark` 跑效能測試後結束（結果在 user://benchmark/）。

signal level_loaded(level_id: String)
signal dialogue_started(runner: DialogueRunner)
signal dialogue_ended(dialogue_id: String)
signal player_died

## 倒下到自動重試的時間（真實時間）
const RETRY_DELAY_SEC: float = 2.2
## 遊戲時間一幀最多加幾秒
const PLAYTIME_MAX_STEP: float = 0.25

## 關卡 id -> 場景
const LEVELS: Dictionary = {
	"corrupt_forest": "res://scenes/levels/corrupt_forest.tscn",
	"ruined_altar": "res://scenes/levels/ruined_altar.tscn",
	"guild_hall": "res://scenes/levels/guild_hall.tscn",
	"town_street": "res://scenes/levels/town_street.tscn",
	"benchmark": "res://scenes/bench/benchmark.tscn",
}
## 檢查點 -> 關卡 id（沒列的都在 DEFAULT_LEVEL）
const CHECKPOINT_LEVELS: Dictionary = {
	"ch1_guild": "guild_hall",
	"ch1_guild_quest": "guild_hall",
	"ch1_guild_leave": "guild_hall",
	"ch1_town": "town_street",
	"ch1_town_gate": "town_street",
	"ch1_forest_gate": "corrupt_forest",
	"ch1_with_sera": "corrupt_forest",
	"ch1_slimes": "corrupt_forest",
	"ch1_after_slimes": "corrupt_forest",
	"ch1_explore": "corrupt_forest",
	"ch1_scream": "corrupt_forest",
	"ch1_altar": "ruined_altar",
	"ch1_boss": "ruined_altar",
	"ch1_boss_down": "ruined_altar",
	"ch1_guild_return": "guild_hall",
}
const DEFAULT_LEVEL: String = "corrupt_forest"
## `--level=…` 開發旗標用的存檔資料夾：不會蓋掉玩家真正的進度
const DEV_SAVE_DIR: String = "user://saves_dev"
const TITLE_SCENE: String = "res://scenes/boot/boot.tscn"
const TITLE_REQUEST: String = "title"
## 在這個群組裡的節點還在場上時玩家不能動（`in_cutscene()`）
const CUTSCENE_GROUP: StringName = &"cutscene"

var session: GameSession
## false＝go_to_level 只記下要去哪、不真的換場景（測試把關卡直接掛在 root 底下：真的換會多出一個沒人管的關卡）
var change_scenes: bool = true
## 最近一次要去的關卡（測試看這個；回標題記成 TITLE_REQUEST）
var last_level_request: String = ""
var dialogues: DialogueDB
## 進行中的對話（沒有則為 null）
var dialogue: DialogueRunner
## 換關卡的黑幕（換之前淡成黑、新的一關從黑淡進來）
var fade: ScreenFade
## 這一次開遊戲換過幾次關卡（`level_args()` 只給第一個關卡開發旗標）
var levels_loaded: int = 0
## 黑幕淡完要換過去的場景（淡出的那幾幀再要求換關卡就不理）
var _pending_scene: String = ""


func _ready() -> void:
	fade = ScreenFade.new()
	add_child(fade)
	session = GameSession.new(QuestDB.load_default())
	dialogues = DialogueDB.load_default()
	for e: String in dialogues.errors:
		push_error("Game: 對話資料錯誤 " + e)
	var args: Dictionary = App.parse_user_args(OS.get_cmdline_user_args())
	var level: String = str(args.get("level", ""))
	if args.has("benchmark"):
		level = "benchmark"
	if level != "":
		# benchmark 不開新遊戲（只飛過關卡，也不會寫存檔）
		if not args.has("benchmark"):
			session.save_dir = DEV_SAVE_DIR
			session.new_game.call_deferred()
		# 開發旗標直接進關卡：不淡出淡入（截圖照幀數拍，第一幀就要看得到）
		go_to_level.call_deferred(level, true)


## 標題畫面的「新遊戲／繼續」。load_level=false 給測試用（只改狀態、不換場景）。
func has_continue() -> bool:
	return session.has_save(GameSession.AUTO_SLOT)


func new_game(load_level: bool = true) -> void:
	session.new_game()
	if load_level:
		go_to_checkpoint_level()


func continue_game(load_level: bool = true) -> bool:
	if session.load_slot(GameSession.AUTO_SLOT) != SaveCodec.Status.OK:
		return false
	if load_level:
		go_to_checkpoint_level()
	return true


static func level_for_checkpoint(checkpoint_id: String) -> String:
	return str(CHECKPOINT_LEVELS.get(checkpoint_id, DEFAULT_LEVEL))


## 去「現在的檢查點」所在的關卡：新遊戲、繼續、倒下重來，還有劇情走到下一個關卡的時候（森林的祭壇路口 → 廢棄祭壇）。
func go_to_checkpoint_level() -> void:
	go_to_level(level_for_checkpoint(session.state.checkpoint))


## instant＝不淡出淡入（開發旗標 `--level` 第一次進關卡）
func go_to_level(level_id: String, instant: bool = false) -> void:
	var path: String = str(LEVELS.get(level_id, ""))
	if path == "":
		push_error("Game: 沒有關卡 %s" % level_id)
		return
	last_level_request = level_id
	cancel_hit_stop()
	if not change_scenes:
		fade.clear()
		return
	# 上一關用的模型場景不一直留著（同一關裡的第二棵樹、第二隻史萊姆照舊共用：SceneCache）
	SceneCache.forget()
	if instant:
		fade.clear()
		if get_tree().change_scene_to_file(path) != OK:
			push_error("Game: 載入 %s 失敗" % path)
			return
		levels_loaded += 1
		level_loaded.emit(level_id)
		return
	_change_after_fade(path, level_id)


## 先淡成黑（已經是黑的就馬上）再換場景，新的場景從黑淡進來
func _change_after_fade(path: String, request: String) -> void:
	if _pending_scene != "" and fade.covering():
		return
	_pending_scene = path
	fade.fade_out(func() -> void:
		_pending_scene = ""
		cancel_hit_stop()
		var err: Error = get_tree().change_scene_to_file(path)
		if err != OK:
			push_error("Game: 載入 %s 失敗：%s" % [path, error_string(err)])
			fade.clear()
			return
		fade.fade_in()
		if request != TITLE_REQUEST:
			levels_loaded += 1
			level_loaded.emit(request))


## 關卡讀的開發旗標（`--at`、`--demo`、`--burst-on`……）：只給這一次開遊戲第一個載入的關卡。
## 劇情換到下一關、倒下重來、回標題再進來都不套（從森林走到祭壇時 `--at` 不會把諾恩放到石板外面）。
func level_args() -> Dictionary:
	if levels_loaded > 1:
		return {}
	return App.parse_user_args(OS.get_cmdline_user_args())


## 開始一段對話；效果套用後讓任務推進。已有對話進行中時回傳 false。
func start_dialogue(dialogue_id: String) -> bool:
	if is_in_dialogue():
		return false
	var r := DialogueRunner.new(dialogues, session.state)
	r.state_changed.connect(_on_dialogue_state_changed)
	r.finished.connect(_on_dialogue_finished)
	dialogue = r
	if not r.start(dialogue_id):
		dialogue = null
		return false
	dialogue_started.emit(r)
	return true


func is_in_dialogue() -> bool:
	return dialogue != null and dialogue.is_running()


var _hit_stop_token: int = 0
var _player_dead: bool = false


## 玩家倒下：發訊號（HUD 顯示「你倒下了」），稍後從最近的檢查點重來。
func on_player_died() -> void:
	if _player_dead:
		return
	_player_dead = true
	player_died.emit()
	await get_tree().create_timer(RETRY_DELAY_SEC, true, false, true).timeout
	if _player_dead:
		retry()


func is_player_dead() -> bool:
	return _player_dead


## 遊戲時間這一幀加多少：用真實時間（打擊停頓的慢動作不少算）；一幀最多 PLAYTIME_MAX_STEP（換場景卡住的那一幀不算進去）。
## 暫停時 Game 跟著暫停、_process 不跑，標題畫面不在關卡裡，都不算。
static func playtime_step(delta: float, time_scale: float) -> float:
	return clampf(delta / maxf(time_scale, 0.01), 0.0, PLAYTIME_MAX_STEP)


## 從最近的自動存檔重來；沒有存檔時重新開始。reload_level=false 給測試用（只重設狀態）。
## 遊戲時間不跟著退回檢查點（倒下重來的那幾分鐘也是玩的時間）。
func retry(reload_level: bool = true) -> void:
	_player_dead = false
	cancel_hit_stop()
	dialogue = null
	var played: float = session.state.playtime_sec
	if session.retry_from_checkpoint() != SaveCodec.Status.OK:
		session.new_game()
	session.state.playtime_sec = maxf(session.state.playtime_sec, played)
	if reload_level:
		go_to_checkpoint_level()


## 打擊停頓：短暫把時間放慢，用真實時間計時後恢復（重疊時以最後一次為準）。
## 給了 tail_sec：停完之後再用 tail_scale 的慢動作演這麼久才恢復（粉碎魔像核心的那一刀：先定格、碎片再慢慢飛出來）。
func hit_stop(seconds: float, tail_sec: float = 0.0, tail_scale: float = 1.0) -> void:
	if seconds <= 0.0:
		return
	_hit_stop_token += 1
	var token: int = _hit_stop_token
	Engine.time_scale = CombatTuning.num("feel.hit_stop_time_scale", 0.05)
	await get_tree().create_timer(seconds, true, false, true).timeout
	if token != _hit_stop_token:
		return
	if tail_sec > 0.0:
		Engine.time_scale = tail_scale
		await get_tree().create_timer(tail_sec, true, false, true).timeout
		if token != _hit_stop_token:
			return
	Engine.time_scale = 1.0


## 還沒演完的打擊停頓／慢動作不要了（倒下重來、回標題、換關卡：不然新的一關開頭會被它放慢）
func cancel_hit_stop() -> void:
	_hit_stop_token += 1
	Engine.time_scale = 1.0


func is_hit_stopped() -> bool:
	return Engine.time_scale < 1.0


## 玩家角色不能移動（對話中、倒下、換關卡的黑幕與章節卡、關卡自己的過場）。
func is_player_locked() -> bool:
	return is_in_dialogue() or _player_dead or in_cutscene()


## 過場中：黑幕正在變黑，或場上有加進 CUTSCENE_GROUP 的節點（章節卡、製作名單；關卡 `StoryLevel.lock_for_cutscene()`）
func in_cutscene() -> bool:
	if fade != null and fade.covering():
		return true
	return is_inside_tree() and get_tree().get_first_node_in_group(CUTSCENE_GROUP) != null


func _process(delta: float) -> void:
	if session != null and get_tree().current_scene is StoryLevel:
		session.state.playtime_sec += playtime_step(delta, Engine.time_scale)


func _on_dialogue_state_changed() -> void:
	session.advance()


func _on_dialogue_finished(dialogue_id: String) -> void:
	dialogue = null
	dialogue_ended.emit(dialogue_id)


func back_to_title() -> void:
	cancel_hit_stop()
	_player_dead = false
	dialogue = null
	last_level_request = TITLE_REQUEST
	if change_scenes:
		SceneCache.forget()
		_change_after_fade(TITLE_SCENE, TITLE_REQUEST)
	else:
		fade.clear()
