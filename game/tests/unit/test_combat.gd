extends TestCase
## 戰鬥起步：數值檔與覆寫、生命值、命中扇形、揮擊命中、打擊停頓、鏡頭震動。


func after_each() -> void:
	CombatTuning.load_tuning()
	Engine.time_scale = 1.0


func test_tuning_override_merges_deep() -> void:
	var path: String = "user://test_tuning_%d.json" % Time.get_ticks_usec()
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"noen": {"blunt_damage": 9}}))
	f.close()
	CombatTuning.load_tuning(CombatTuning.DEFAULT_PATH, path)
	assert_eq(CombatTuning.num("noen.blunt_damage"), 9.0, "覆寫生效")
	assert_eq(CombatTuning.num("noen.max_hp"), 100.0, "沒覆寫的 key 保留")
	DirAccess.remove_absolute(path)


## 戰鬥場的那一套數值：只蓋掉寫出來的 key；換回去之後劇情流程的數字跟原本一樣。
func test_health_damage_invuln_death_reset() -> void:
	var h := Health.new(20.0)
	var died: Array[int] = [0]
	h.died.connect(func() -> void: died[0] += 1)
	var invuln: Array[bool] = [true]
	h.invulnerable_check = func() -> bool: return invuln[0]
	assert_false(h.apply_damage(5.0), "無敵不扣")
	invuln[0] = false
	assert_true(h.apply_damage(5.0))
	assert_eq(h.hp, 15.0)
	assert_true(h.apply_damage(50.0))
	assert_true(h.is_dead())
	assert_eq(h.hp, 0.0, "不會變負")
	assert_false(h.apply_damage(1.0), "死了不再扣")
	assert_eq(died[0], 1, "died 只發一次")
	h.reset()
	assert_eq(h.hp, 20.0)
	h.free()


func test_strike_arc() -> void:
	var fwd := Vector3(0, 0, -1)
	assert_true(PlayerController.in_strike_arc(Vector3.ZERO, fwd, Vector3(0, 0, -1.5), 1.9, 110.0), "正前方")
	assert_true(PlayerController.in_strike_arc(Vector3.ZERO, fwd, Vector3(1.0, 0.8, -1.0), 1.9, 110.0), "斜前 45° 不看高度")
	assert_false(PlayerController.in_strike_arc(Vector3.ZERO, fwd, Vector3(0, 0, 1.0), 1.9, 110.0), "背後")
	assert_false(PlayerController.in_strike_arc(Vector3.ZERO, fwd, Vector3(0, 0, -2.5), 1.9, 110.0), "太遠")
	assert_false(PlayerController.in_strike_arc(Vector3.ZERO, fwd, Vector3(1.5, 0, -0.2), 1.9, 110.0), "側邊超出扇形")


## 最小的靶：在 damageable 群組、底下有一個叫 Health 的節點（玩家的 strike() 就靠這兩件事找目標）。
func _target(parent: Node3D, at: Vector3, hits: Array[int]) -> Health:
	var body := Node3D.new()
	body.add_to_group("damageable")
	var h := Health.new(60.0)
	h.name = "Health"
	body.add_child(h)
	h.damaged.connect(func(_amount: float, _info: Dictionary) -> void: hits[0] += 1)
	parent.add_child(body)
	body.global_position = at
	return h


func test_player_swing_hits_target_with_hit_stop_and_shake() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var player: PlayerController = (load("res://scenes/actors/player/player.tscn") as PackedScene).instantiate() as PlayerController
	root.add_child(player)
	var forward: Vector3 = -player.get_node("Body").global_basis.z as Vector3
	var front_hits: Array[int] = [0]
	var behind_hits: Array[int] = [0]
	var front: Health = _target(root, player.global_position + forward * 1.2, front_hits)
	var behind: Health = _target(root, player.global_position - forward * 1.2, behind_hits)
	await tree.physics_frame
	player.start_attack()
	for i: int in 60:
		await tree.physics_frame
		if front_hits[0] > 0:
			break
	assert_eq(front_hits[0], 1, "前方的靶被打中一次")
	assert_eq(behind_hits[0], 0, "背後的不會中")
	assert_eq(behind.hp, 60.0, "背後的沒有扣血")
	assert_eq(front.hp, 60.0 - CombatTuning.num("noen.blunt_damage"), "一刀的傷害照數值檔")
	assert_true(player.shake_amount() > 0.0, "命中有鏡頭震動")
	for i: int in 30:
		await tree.physics_frame
	assert_eq(front_hits[0], 1, "一次揮擊只判定一次")
	assert_eq(Engine.time_scale, 1.0, "打擊停頓結束後恢復")
	# 閃避無敵
	player.invulnerable = true
	assert_false(player.health.apply_damage(10.0), "閃避無敵不扣血")
	player.invulnerable = false
	assert_true(player.health.apply_damage(10.0))
	root.queue_free()
	await tree.process_frame


## 自動攻擊（設定，預設開；Jacky 11/16：「一直點滑鼠感覺會點壞」）：身邊有活著的敵人諾恩就自己出手、轉向最近的那一隻（在背後也一樣），
## 一刀接一刀砍到牠倒下；敵人離得遠、倒下了、設定關掉都不出手。按住出手鍵也是接著砍，不用一下一下點。
func test_auto_attack_swings_at_the_nearest_enemy_and_holding_the_button_keeps_swinging() -> void:
	var settings: Node = tree.root.get_node("Settings")
	var root := Node3D.new()
	tree.root.add_child(root)
	var player: PlayerController = (load("res://scenes/actors/player/player.tscn") as PackedScene).instantiate() as PlayerController
	root.add_child(player)
	var slime := Slime.new()
	root.add_child(slime)
	slime.set_physics_process(false)
	var forward: Vector3 = -player.get_node("Body").global_basis.z as Vector3
	var reach: float = CombatTuning.num("noen.auto_attack_range")
	assert_true(reach > CombatTuning.num("noen.strike_range") and reach < CombatTuning.num("noen.strike_range") + CombatTuning.num("noen.lunge_dist"), "出手的距離：往前滑一步剛好夠得到")
	settings.set("auto_attack", true)
	# 離得遠：不出手
	slime.global_position = player.global_position + forward * 6.0
	var swings: int = await _count_swings(player, 40)
	assert_eq(swings, 0, "敵人離得遠不出手")
	assert_true(player.auto_target() == null)
	# 在背後、夠近：自己轉過去砍，一刀接一刀砍到牠倒下
	slime.global_position = player.global_position - forward * 1.8
	assert_true(player.auto_target() == slime, "挑到身邊最近的那一隻")
	swings = 0
	var faced: float = -1.0
	for i: int in 240:
		var was: bool = player.puppet().action == "attack"
		await tree.physics_frame
		if player.puppet().action == "attack" and not was:
			swings += 1
			var to: Vector3 = (slime.global_position - player.global_position).normalized()
			faced = maxf(faced, (-(player.get_node("Body") as Node3D).global_basis.z).dot(to))
		if slime.health.is_dead():
			break
	assert_true(slime.health.is_dead(), "不用按：自己把牠砍倒（%d 刀）" % swings)
	assert_true(swings >= 2, "一刀接一刀")
	assert_true(faced > 0.9, "出手的時候轉過去面向牠（%.2f）" % faced)
	Engine.time_scale = 1.0
	swings = await _count_swings(player, 50)
	assert_eq(swings, 0, "倒下的不再砍")
	# 設定關掉：站在敵人旁邊也不會自己出手
	settings.set("auto_attack", false)
	var second := Slime.new()
	root.add_child(second)
	second.set_physics_process(false)
	second.global_position = player.global_position + forward * 1.6
	swings = await _count_swings(player, 50)
	assert_eq(swings, 0, "設定關掉就不自己出手")
	assert_true(second.health.is_full())
	# 按住出手鍵：接著砍
	Input.action_press("attack")
	swings = await _count_swings(player, 110)
	Input.action_release("attack")
	assert_true(swings >= 2, "按住出手鍵接著砍（%d 刀）" % swings)
	assert_false(second.health.is_full(), "砍得到面前的敵人")
	Engine.time_scale = 1.0
	root.queue_free()
	await tree.process_frame


## 接下來 frames 幀裡諾恩出手了幾次（動作從別的變成出手算一次）
func _count_swings(player: PlayerController, frames: int) -> int:
	var n: int = 0
	for i: int in frames:
		var was: bool = player.puppet().action == "attack"
		await tree.physics_frame
		if player.puppet().action == "attack" and not was:
			n += 1
	return n


## 【瘴氣生鏽鐵劍】的三下連段：接著砍是 第一下 → 第二下 → 收尾（比較痛、側面也掃得到），再來從第一下重來；
## 停手超過 combo_window 就重來。每砍中一刀身上多一層流血（對諾恩＝出手變快，出手越快砍得越重）＋微弱中毒。
func test_three_hit_combo_ends_in_a_wide_finisher_and_each_cut_stacks_bleed() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var player: PlayerController = (load("res://scenes/actors/player/player.tscn") as PackedScene).instantiate() as PlayerController
	root.add_child(player)
	var body: Node3D = player.get_node("Body") as Node3D
	var forward: Vector3 = -body.global_basis.z
	var front_hits: Array[int] = [0]
	var side_hits: Array[int] = [0]
	var front: Health = _target(root, player.global_position + forward * 1.2, front_hits)
	front.max_hp = 500.0
	front.hp = 500.0
	# 正側面偏前一點（80 度）：平常的一刀（左右各 55 度）掃不到，收尾（左右各 85 度）掃得到
	var side: Health = _target(root, player.global_position + (forward.rotated(Vector3.UP, deg_to_rad(80.0))) * 1.2, side_hits)
	await tree.physics_frame
	var dmg: float = CombatTuning.num("noen.blunt_damage")
	var steps: Array[int] = []
	var took: Array[float] = []
	var sounds: Array[String] = []
	for swing: int in 4:
		var before: float = front.hp
		player.start_attack()
		steps.append(player.combo_step)
		for i: int in 90:
			await tree.physics_frame
			if player.puppet().action != "attack":
				break
		took.append(before - front.hp)
		sounds.append(player.last_hit_sfx)
	assert_eq(steps, [0, 1, 2, 0] as Array[int], "三下一輪")
	# 劍砍中是劍的聲音（不再借鐘錘的 blunt）：收尾那一刀是重的那一聲
	assert_eq(sounds, ["cut_hit", "cut_hit", "cut_heavy", "cut_hit"] as Array[String], "砍中的聲音")
	for n: String in sounds:
		assert_not_null(Sfx.stream(n), "%s 有產生" % n)
	# 出手越快砍得越重：砍中第 n 刀的時候身上已經有 n 層流血（每層出手快 12%，傷害也多 12%）
	assert_eq(took[0], dmg)
	assert_true(absf(took[1] - dmg * 1.12) < 0.01, "第二刀：一層流血（%s）" % took[1])
	assert_true(absf(took[2] - dmg * 1.24 * CombatTuning.num("noen.finisher_damage_mult")) < 0.01, "收尾比較痛（%s）" % took[2])
	assert_true(absf(took[3] - dmg * 1.36) < 0.01, "第四下從頭來，三層流血（%s）" % took[3])
	assert_eq(side_hits[0], 1, "側面的只有收尾那一刀掃得到")
	assert_true(side.hp < 60.0)
	assert_eq(player.on_hit_applied, 4, "每砍中一刀給自己一次")
	assert_eq(player.status_effects.rate("bleed"), 4.0, "四刀四層流血")
	assert_true(player.status_effects.has("poison"), "還有微弱中毒")
	assert_true(player.puppet().attack_speed > 1.3, "越砍越快（%s）" % player.puppet().attack_speed)
	# 停手超過 combo_window：下一刀從第一下開始
	player.start_attack()
	assert_eq(player.combo_step, 1)
	for i: int in ceili((float(Puppet.ACTION_TIME["attack"]) + CombatTuning.num("noen.combo_window")) * 60.0) + 12:
		await tree.physics_frame
	player.start_attack()
	assert_eq(player.combo_step, 0, "停手太久，從第一下重來")
	root.queue_free()
	await tree.process_frame


func test_hit_stop_restores_time_scale() -> void:
	var game: Node = tree.root.get_node("Game")
	game.call("hit_stop", 0.05)
	assert_true(Engine.time_scale < 1.0, "停頓中時間變慢")
	await tree.create_timer(0.2, true, false, true).timeout
	assert_eq(Engine.time_scale, 1.0, "用真實時間計時並恢復")


## 粉碎魔像核心的那一刀：先定格，再用慢動作演一段，最後才恢復；倒下重來／換關卡會把還沒演完的取消
func test_hit_stop_can_trail_into_slow_motion_and_be_cancelled() -> void:
	var game: Node = tree.root.get_node("Game")
	game.call("hit_stop", 0.05, 0.15, 0.25)
	assert_true(Engine.time_scale < 0.2, "先定格")
	await tree.create_timer(0.1, true, false, true).timeout
	assert_eq(Engine.time_scale, 0.25, "定格完：慢動作")
	await tree.create_timer(0.2, true, false, true).timeout
	assert_eq(Engine.time_scale, 1.0, "慢動作演完恢復")
	game.call("hit_stop", 0.05, 0.3, 0.25)
	game.call("cancel_hit_stop")
	assert_eq(Engine.time_scale, 1.0, "取消：馬上恢復")
	await tree.create_timer(0.15, true, false, true).timeout
	assert_eq(Engine.time_scale, 1.0, "取消之後後面那一段慢動作不會再冒出來")


func test_reduced_shake() -> void:
	var settings: Node = tree.root.get_node("Settings")
	var before: bool = bool(settings.get("reduce_camera_shake"))
	var player: PlayerController = (load("res://scenes/actors/player/player.tscn") as PackedScene).instantiate() as PlayerController
	tree.root.add_child(player)
	settings.set("reduce_camera_shake", true)
	player.shake(0.4)
	assert_true(absf(player.shake_amount() - 0.1) < 0.001, "減少晃動：25%")
	settings.set("reduce_camera_shake", before)
	player.queue_free()
	await tree.process_frame


## 打擊停頓照出手速度縮：最多只佔一刀的 hit_stop_max_share。平常的速度照數值檔；超頻（×2.5）砍倒一隻不再停掉半刀。
func test_hit_stop_shrinks_when_swings_get_fast() -> void:
	var share: float = CombatTuning.num("feel.hit_stop_max_share")
	var kill: float = CombatTuning.num("feel.hit_stop_kill")
	assert_true(share > 0.0 and share < 0.5, "有上限（%.2f）" % share)
	assert_eq(PlayerController.hit_stop_for(kill, 1.0, share), kill, "平常的速度：照數值檔")
	assert_eq(PlayerController.hit_stop_for(CombatTuning.num("feel.hit_stop"), 1.5, share), CombatTuning.num("feel.hit_stop"), "疊了幾層流血（快 50%）：平常那一刀的停頓不受影響")
	var fast: float = PlayerController.hit_stop_for(kill, 2.5, share)
	var swing: float = float(Puppet.ACTION_TIME["attack"]) / 2.5
	assert_true(fast < kill and fast <= swing * share + 0.0001, "超頻：砍倒一隻最多停一刀的 %d%%（%.3f 秒，一刀 %.2f 秒）" % [roundi(share * 100.0), fast, swing])


## 手把震動：只有最後用手把、設定開著才真的震；砍中、收尾、砍倒各是不同的強度。
func test_rumble_only_on_a_gamepad_and_when_enabled() -> void:
	var app: Node = tree.root.get_node("App")
	var settings: Node = tree.root.get_node("Settings")
	var device_before: int = int(app.get("last_device"))
	var rumble_before: bool = bool(settings.get("pad_rumble"))
	app.call("set_device", InputGlyphs.Device.KBM)
	assert_false(Rumble.pulse(tree, Rumble.HIT), "鍵盤滑鼠不震")
	assert_eq(Rumble.last, Rumble.HIT, "還是記下來要震哪一種")
	app.call("set_device", InputGlyphs.Device.PAD)
	settings.set("pad_rumble", true)
	assert_true(Rumble.pulse(tree, Rumble.HIT), "手把＋設定開著：震")
	settings.set("pad_rumble", false)
	assert_false(Rumble.pulse(tree, Rumble.HIT), "設定關掉：不震")
	assert_true(Rumble.HIT_HEAVY.y > Rumble.HIT.y and Rumble.KILL.y > Rumble.HIT_HEAVY.y, "收尾比平常重、砍倒最重")
	# 砍中一刀：記下來的是平常的那一種
	settings.set("pad_rumble", true)
	var root := Node3D.new()
	tree.root.add_child(root)
	var player: PlayerController = (load("res://scenes/actors/player/player.tscn") as PackedScene).instantiate() as PlayerController
	root.add_child(player)
	var forward: Vector3 = -player.get_node("Body").global_basis.z as Vector3
	var hits: Array[int] = [0]
	var target: Health = _target(root, player.global_position + forward * 1.2, hits)
	target.max_hp = 500.0
	target.hp = 500.0
	await tree.physics_frame
	Rumble.last = Vector3.ZERO
	player.start_attack()
	for i: int in 60:
		await tree.physics_frame
		if hits[0] > 0:
			break
	assert_eq(Rumble.last, Rumble.HIT, "砍中：平常的震動")
	assert_true(Rumble.fired, "用手把玩的時候真的送出去")
	assert_eq(player.last_hit_stop, CombatTuning.num("feel.hit_stop"), "平常的速度：停頓照數值檔")
	app.call("set_device", device_before)
	settings.set("pad_rumble", rumble_before)
	root.queue_free()
	await tree.process_frame
