extends TestCase
## 換關卡的黑幕（ScreenFade）與過場鎖：換之前淡成黑、新的一關從黑淡進來；載入卡住的那一幀不會把淡入吃掉；
## 黑幕變黑、章節卡在場上、關卡自己的過場時玩家不能動；開發旗標只給第一個載入的關卡。

var _game: Node


func before_each() -> void:
	_game = tree.root.get_node("Game")


func after_each() -> void:
	(_game.get("fade") as ScreenFade).clear()
	_game.set("levels_loaded", 0)


func test_step_caps_a_long_frame() -> void:
	var a: float = ScreenFade.step(1.0, 0.0, 1.0 / 60.0, 0.9)
	assert_true(absf(a - (1.0 - 1.0 / 54.0)) < 0.0001, "一般的一幀：0.9 秒淡完的 1/54（%.4f）" % a)
	a = ScreenFade.step(1.0, 0.0, 2.5, 0.9)
	assert_true(a > 0.9, "載入卡住 2.5 秒的那一幀只算 1/30 秒：還幾乎全黑（%.3f）" % a)
	assert_eq(ScreenFade.step(0.2, 1.0, -1.0, 0.45), 0.2, "不會倒退")
	assert_eq(ScreenFade.step(0.99, 1.0, 0.1, 0.45), 1.0, "到了就停在 1")


func test_fade_out_calls_back_once_when_black_and_fade_in_waits_a_few_frames() -> void:
	var f := ScreenFade.new()
	tree.root.add_child(f)
	var calls: Array[int] = [0]
	f.fade_out(func() -> void: calls[0] += 1)
	assert_true(f.covering(), "正在變黑")
	assert_eq(calls[0], 0, "還沒黑")
	for i: int in 3000:
		await tree.process_frame
		if calls[0] > 0:
			break
	assert_eq(f.alpha, 1.0, "全黑")
	assert_eq(calls[0], 1, "黑了呼叫一次")
	for i: int in 3000:
		if f.duck >= 1.0:
			break
		await tree.process_frame
	assert_eq(f.duck, 1.0, "聲音跟著收掉")
	assert_true(f.duck_db() <= -79.0, "Master 上那一層聽不到（%.1f dB）" % f.duck_db())
	f.fade_in()
	assert_false(f.covering())
	await tree.process_frame
	await tree.process_frame
	assert_eq(f.alpha, 1.0, "新的一關載入後先黑著幾幀")
	for i: int in 3000:
		await tree.process_frame
		if f.alpha <= 0.0:
			break
	assert_eq(f.alpha, 0.0, "淡進來")
	assert_false(f.visible, "淡完就不畫")
	for i: int in 3000:
		if f.duck <= 0.0:
			break
		await tree.process_frame
	assert_eq(f.duck, 0.0, "聲音一起回來")
	assert_true(absf(f.duck_db()) < 0.01, "回到原本的音量")
	# 已經是黑的（章節卡播完）：馬上呼叫
	f.cover()
	f.fade_out(func() -> void: calls[0] += 1)
	assert_eq(calls[0], 2, "已經是黑的：不用再等")
	f.queue_free()


func test_cards_and_level_cutscenes_lock_the_player() -> void:
	assert_false(bool(_game.call("is_player_locked")))
	var host := Node3D.new()
	tree.root.add_child(host)
	var card := ChapterCard.play(host, "CARD_ALTAR_SMALL", "CARD_ALTAR_TITLE", Callable(), 0.05)
	assert_true(bool(_game.call("is_player_locked")), "章節卡在場上：不能動")
	card.queue_free()
	await tree.process_frame
	assert_false(bool(_game.call("is_player_locked")))
	var level := StoryLevel.new()
	tree.root.add_child(level)
	level.lock_for_cutscene()
	assert_true(bool(_game.call("is_player_locked")), "關卡自己的過場：不能動")
	level.lock_for_cutscene(false)
	assert_false(bool(_game.call("is_player_locked")))
	level.lock_for_cutscene()
	level.free()
	assert_false(bool(_game.call("is_player_locked")), "關卡被釋放就解開")
	(_game.get("fade") as ScreenFade).fade_out()
	assert_true(bool(_game.call("is_player_locked")), "黑幕正在變黑：不能動")
	host.free()


func test_card_hands_its_black_to_the_fade() -> void:
	var host := Node3D.new()
	tree.root.add_child(host)
	var done: Array[bool] = [false]
	var card := ChapterCard.play(host, "CARD_ALTAR_SMALL", "CARD_ALTAR_TITLE", func() -> void: done[0] = true)
	var fade0: ScreenFade = _game.get("fade") as ScreenFade
	assert_eq(fade0.get("_duck_target"), 1.0, "換關卡的卡：這一關的聲音慢慢收掉")
	card.finish()
	assert_true(done[0])
	var fade: ScreenFade = _game.get("fade") as ScreenFade
	assert_eq(fade.alpha, 1.0, "卡播完：Game 的黑幕直接全黑接手（新的一關從黑淡進來，不會跳出來）")
	host.free()


func test_dev_flags_only_go_to_the_first_level() -> void:
	_game.set("levels_loaded", 1)
	var first: Dictionary = _game.call("level_args")
	assert_eq(first, App.parse_user_args(OS.get_cmdline_user_args()), "第一個關卡：照命令列")
	_game.set("levels_loaded", 2)
	assert_true((_game.call("level_args") as Dictionary).is_empty(), "劇情換到下一關之後：開發旗標不再套用")
