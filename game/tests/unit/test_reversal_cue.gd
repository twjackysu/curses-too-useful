extends TestCase
## 反轉的回饋：時間軸（ReversalCue，純邏輯）、畫面那一層（ReversalOverlay）、狀態圖示翻面（StatusHud）、諾恩身上的接線。


func test_cue_goes_curse_then_shatter_once_then_gold() -> void:
	var cue := ReversalCue.new()
	var count: Array[int] = [0]
	cue.shattered.connect(func() -> void: count[0] += 1)
	assert_false(cue.is_playing(), "沒開始＝沒在播")
	assert_eq(cue.curse(), 0.0)
	cue.start()
	cue.step(ReversalCue.CURSE_RISE_SEC)
	assert_eq(cue.curse(), 1.0, "紫紅很快亮滿")
	assert_eq(cue.gold(), 0.0, "還沒碎之前沒有金光")
	assert_eq(count[0], 0)
	cue.step(ReversalCue.CURSE_SEC - ReversalCue.CURSE_RISE_SEC + 0.01)
	assert_eq(count[0], 1, "過了 %.1f 秒碎裂" % ReversalCue.CURSE_SEC)
	assert_true(cue.gold() > 0.9, "碎裂那一刻金光最亮：%.2f" % cue.gold())
	assert_true(cue.shatter() > 0.0 and cue.shatter() < 0.2)
	cue.step(ReversalCue.SHATTER_SEC)
	assert_eq(cue.shatter(), 1.0, "碎片掉完")
	assert_eq(cue.curse(), 0.0, "紫紅沒了")
	assert_true(cue.gold() > 0.0 and cue.gold() < 0.6, "金光慢慢退：%.2f" % cue.gold())
	cue.step(ReversalCue.GOLD_SEC)
	assert_false(cue.is_playing(), "播完")
	assert_eq(count[0], 1, "只碎一次")


func test_icon_face_flips_at_the_shatter_moment() -> void:
	assert_eq(ReversalCue.icon_face(0.0), 1.0, "剛上身：紅的那一面")
	assert_eq(ReversalCue.icon_face(ReversalCue.CURSE_SEC - 0.01), 1.0)
	assert_true(absf(ReversalCue.icon_face(ReversalCue.CURSE_SEC + ReversalCue.FLIP_SEC * 0.5)) < 0.01, "翻到一半是一條線")
	assert_eq(ReversalCue.icon_face(ReversalCue.CURSE_SEC + ReversalCue.FLIP_SEC), -1.0, "翻成金的")


func test_overlay_hidden_until_a_cue_plays() -> void:
	var overlay := ReversalOverlay.new()
	tree.root.add_child(overlay)
	var cue := ReversalCue.new()
	overlay.refresh(cue)
	assert_false(overlay.visible, "沒在播就不畫")
	cue.start()
	cue.step(0.2)
	overlay.refresh(cue)
	assert_true(overlay.visible)
	assert_eq(overlay.levels(), Vector3(1.0, 0.0, 0.0), "紫紅滿、還沒碎")
	cue.step(0.2)
	overlay.refresh(cue)
	assert_true(overlay.levels().y > 0.0 and overlay.levels().z > 0.5, "碎裂中＋金光：%s" % overlay.levels())
	overlay.refresh(null)
	assert_false(overlay.visible)
	overlay.queue_free()
	await tree.process_frame


func test_status_icon_already_on_body_when_hud_attaches_is_settled() -> void:
	var hud := StatusHud.new()
	tree.root.add_child(hud)
	var fx := StatusEffects.new(StatusRules.load_default(), true)
	fx.apply_source("miasma")
	hud.refresh(fx)
	assert_true(float(hud.rows[0]["face"]) < 0.0, "讀檔、換關卡接上時身上已經有的：直接是金的，不再演一次翻面")
	hud.queue_free()
	await tree.process_frame


func test_player_starts_the_cue_on_a_new_status_and_bursts_gold_on_shatter() -> void:
	var player: PlayerController = (load("res://scenes/actors/player/player.tscn") as PackedScene).instantiate() as PlayerController
	tree.root.add_child(player)
	await tree.process_frame
	assert_false(player.reversal_cue.is_playing())
	player.status_effects.apply_source("miasma")
	assert_true(player.reversal_cue.is_playing(), "中毒上身就開始播")
	var bursts: int = player.heal_fx.bursts
	player.reversal_cue.step(ReversalCue.CURSE_SEC + 0.01)
	assert_eq(player.heal_fx.bursts, bursts + 1, "碎裂那一刻身上噴一團金光")
	assert_eq(player.heal_fx.light().light_color, PlayerController.REVERSAL_GOLD)
	assert_true(player.shake_amount() > 0.0, "鏡頭輕輕震一下")
	if player.weapon() != null:
		assert_eq(player.sword_glow(), 0.0, "還沒過一幀：劍還沒亮")
		for i: int in 3:
			await tree.physics_frame
		assert_true(player.sword_glow() > PlayerController.SWORD_GLOW, "碎裂之後劍透金光，剛碎的時候最亮：%.2f" % player.sword_glow())
	# 同一種狀態刷新（站在瘴氣裡每 0.25 秒一次）不重播
	player.reversal_cue.step(5.0)
	player.status_effects.apply_source("miasma")
	assert_false(player.reversal_cue.is_playing(), "刷新不重播")
	# 另一種狀態新上身：同一套回饋再播一次，一樣會碎成金光（沒有哪一種要先解鎖）
	bursts = player.heal_fx.bursts
	player.status_effects.apply_source("sera_paralysis_vial")
	assert_true(player.reversal_cue.is_playing(), "麻痺上身也播")
	player.reversal_cue.step(ReversalCue.CURSE_SEC + 0.01)
	assert_eq(player.heal_fx.bursts, bursts + 1, "麻痺一樣碎成金光")
	assert_true(player.status_effects.attack_speed() > 1.0, "而且第一瓶就是出手加速")
	player.queue_free()
	await tree.process_frame


## 一樣東西同時帶兩種狀態（劍的第一刀：中毒＋流血；拿錯的那一瓶）：紫紅的那一聲只響一次，不會疊成兩倍大聲。
func test_two_statuses_in_the_same_moment_sting_once() -> void:
	var player: PlayerController = (load("res://scenes/actors/player/player.tscn") as PackedScene).instantiate() as PlayerController
	tree.root.add_child(player)
	await tree.process_frame
	var sting: AudioStream = Sfx.stream("curse_sting")
	assert_not_null(sting, "音效有產出來")
	var count: Callable = func() -> int:
		var n: int = 0
		for c: Node in player.get_children():
			if c is AudioStreamPlayer3D and (c as AudioStreamPlayer3D).stream == sting:
				n += 1
		return n
	player.status_effects.apply_source("rusty_sword_cut")
	assert_true(player.status_effects.has("poison") and player.status_effects.has("bleed"), "一刀兩種狀態")
	assert_true(player.reversal_cue.is_playing())
	assert_eq(int(count.call()), 1, "同一下只響一聲")
	# 過了幾幀才上身的另一種狀態是另一件事：再響一次
	for i: int in 3:
		await tree.physics_frame
	player.status_effects.apply_source("sera_paralysis_vial")
	assert_eq(int(count.call()), 2, "之後新上身的狀態照樣響")
	player.queue_free()
	await tree.process_frame


## 演過整套的狀態再上身：自己的劍給的（停手幾秒又砍）、或離上一次整套不到 QUIET_REPEAT_SEC 秒（被史萊姆連續撞），演小的——
## 不畫整個畫面、碎裂聲小、光點少、鏡頭與手把不震；狀態列的圖示照樣翻面（看 age，不看這裡）、劍照樣亮。第一次見到的狀態一定演整套。
func test_repeats_play_a_quiet_cue_without_the_full_screen() -> void:
	assert_false(PlayerController.cue_is_quiet(false, true, 0.0), "沒演過整套：整套")
	assert_true(PlayerController.cue_is_quiet(true, true, 99.0), "自己的劍、演過了：小的")
	assert_true(PlayerController.cue_is_quiet(true, false, 0.5), "別的來源、剛演過：小的")
	assert_false(PlayerController.cue_is_quiet(true, false, PlayerController.QUIET_REPEAT_SEC + 0.1), "別的來源、隔了一陣子：整套")
	var cue := ReversalCue.new()
	cue.start()
	cue.step(0.05)
	cue.start(true)
	assert_false(cue.quiet, "整套正在演又來一個小的：不降級")
	cue.step(5.0)
	cue.start(true)
	assert_true(cue.quiet)
	var overlay := ReversalOverlay.new()
	tree.root.add_child(overlay)
	cue.step(0.1)
	overlay.refresh(cue)
	assert_false(overlay.visible, "小的：整個畫面那一層不畫")
	overlay.queue_free()

	var player: PlayerController = (load("res://scenes/actors/player/player.tscn") as PackedScene).instantiate() as PlayerController
	tree.root.add_child(player)
	await tree.process_frame
	# 第一次砍中：流血第一次上身，整套
	player._apply_on_hit_source()
	assert_true(player.reversal_cue.is_playing() and not player.reversal_cue.quiet, "劍的第一刀：整套")
	player.reversal_cue.step(5.0)
	# 停手太久、狀態都退了，再砍中：小的
	for id: String in player.status_effects.ids():
		player.status_effects.clear(id)
	var bursts: int = player.heal_fx.bursts
	player._apply_on_hit_source()
	assert_true(player.reversal_cue.is_playing() and player.reversal_cue.quiet, "停手之後又砍：小的")
	var shake_before: float = player.shake_amount()
	player.reversal_cue.step(ReversalCue.CURSE_SEC + 0.01)
	assert_eq(player.heal_fx.bursts, bursts + 1, "小的也碎成一小團金光")
	assert_true(player.shake_amount() <= shake_before, "小的：鏡頭不再震（%.2f → %.2f）" % [shake_before, player.shake_amount()])
	# 別的東西帶來的新狀態（麻痺）：第一次，整套
	player.reversal_cue.step(5.0)
	player.status_effects.apply_source("sera_paralysis_vial")
	assert_false(player.reversal_cue.quiet, "第一次見到的狀態：整套")
	player.queue_free()
	await tree.process_frame
