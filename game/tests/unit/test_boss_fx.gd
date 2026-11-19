extends TestCase
## Boss 演出用的小東西（不用載關卡的部分）：收尾那一刀的側面鏡位、飛出去的碎塊、拿得走的魔像核心、魔像崩成的碎石、
## 怪物出招「舉到頂停住」的動作播法。
## 魔像身上的（被砍的反應、核心的光、凝視的那道光、核心滾出來）在 flow/test_altar.gd。


func test_finisher_shot_stands_beside_the_pair_on_the_players_side() -> void:
	var attacker := Vector3(0, 0, 2)
	var victim := Vector3(0, 0, 0)
	# 出手的人朝 −Z 砍：他的右手邊是 +X。玩家的鏡頭在右邊 → 鏡位也在右邊
	var right: Transform3D = FinisherCamera.shot(attacker, victim, Vector3(1.0, 2.0, 5.0), 6.0, 1.3, 2.0)
	assert_true(right.origin.x > 5.0, "在兩人連線的右邊 6 m（x=%.1f）" % right.origin.x)
	assert_true(right.origin.z > 2.0, "往出手的人後面退一點：看得到他的背與對方的正面")
	assert_true(absf(right.origin.y - 1.3) < 0.001)
	var aim := Vector3(0, 2.0, 1.0)
	assert_true((-right.basis.z).dot((aim - right.origin).normalized()) > 0.999, "看著兩人之間 2 m 高的地方")
	var left: Transform3D = FinisherCamera.shot(attacker, victim, Vector3(-1.0, 2.0, 5.0), 6.0, 1.3, 2.0)
	assert_true(left.origin.x < -5.0, "玩家的鏡頭在左邊就站左邊（切過去不會左右顛倒）")


func test_finisher_camera_takes_over_then_hands_the_view_back() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var home := Camera3D.new()
	home.position = Vector3(0.8, 2.0, 5.0)
	root.add_child(home)
	home.current = true
	await tree.process_frame
	var cam: FinisherCamera = FinisherCamera.play(root, Vector3(0, 0, 2), Vector3.ZERO, 0.1, 6.0, 1.3, 2.0)
	assert_not_null(cam)
	assert_true(cam.current and not home.current, "切到側面的鏡頭")
	assert_true(cam.is_holding())
	await tree.create_timer(0.3, true, false, true).timeout
	assert_true(cam.is_inside_tree() and not cam.is_holding(), "停完了，正在滑回去")
	await tree.create_timer(FinisherCamera.BACK_SEC + 0.2, true, false, true).timeout
	await tree.process_frame
	assert_false(is_instance_valid(cam), "演完自己收掉")
	assert_true(home.current, "還給玩家的鏡頭")
	root.queue_free()
	await tree.process_frame


func test_finisher_camera_moves_to_the_other_side_when_a_pillar_blocks_and_is_a_cutscene_while_holding() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var home := Camera3D.new()
	home.position = Vector3(0.8, 2.0, 5.0)
	root.add_child(home)
	home.current = true
	# 玩家那一側（右邊）的鏡位上立一根柱子
	var right: Transform3D = FinisherCamera.shot(Vector3(0, 0, 2), Vector3.ZERO, home.position, 6.0, 1.3, 2.0)
	var pillar := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.4, 6.0, 1.4)
	shape.shape = box
	pillar.add_child(shape)
	pillar.position = Vector3(right.origin.x * 0.6, 1.0, right.origin.z * 0.6 + 0.4)
	root.add_child(pillar)
	await tree.physics_frame
	await tree.physics_frame
	var cam: FinisherCamera = FinisherCamera.play(root, Vector3(0, 0, 2), Vector3.ZERO, 0.15, 6.0, 1.3, 2.0)
	assert_not_null(cam)
	if cam != null:
		assert_true(cam.flipped and cam.global_position.x < -4.0, "右邊被柱子擋住：換到左邊、照樣離 6 m（x=%.1f）" % cam.global_position.x)
		assert_true(Game.in_cutscene(), "停著的那幾秒是過場：玩家不能動")
		await tree.process_frame
		await tree.process_frame
		assert_true(absf(cam.h_offset) + absf(cam.v_offset) > 0.0, "切過去的那一下鏡頭晃一下")
		await tree.create_timer(0.3, true, false, true).timeout
		assert_false(cam.is_holding())
		assert_false(Game.in_cutscene(), "開始滑回去：玩家可以動了")
	root.queue_free()
	await tree.process_frame


func test_slow_mo_sound_muffles_and_slows_the_effects_then_restores_them() -> void:
	assert_true(is_equal_approx(SlowMoSound.depth_at(0.0, 1.0), 0.0) and is_equal_approx(SlowMoSound.depth_at(0.5, 1.0), 1.0), "一下子悶到底")
	assert_true(SlowMoSound.depth_at(SlowMoSound.DIP_SEC + 1.0 + SlowMoSound.BACK_SEC * 0.5, 1.0) < 0.6, "慢慢回來")
	var bus: int = AudioServer.get_bus_index(SlowMoSound.BUS)
	assert_true(bus >= 0, "有音效的匯流排")
	var before: int = AudioServer.get_bus_effect_count(bus)
	var root := Node.new()
	tree.root.add_child(root)
	var s: SlowMoSound = SlowMoSound.play(root, 0.2)
	await tree.create_timer(0.2, true, false, true).timeout
	assert_eq(AudioServer.get_bus_effect_count(bus), before + 1, "音效匯流排上多一個低通")
	assert_true(s.filter.cutoff_hz < 2000.0, "悶下去了（%.0f Hz）" % s.filter.cutoff_hz)
	assert_true(AudioServer.playback_speed_scale < 0.8, "聲音放慢")
	root.queue_free()
	await tree.process_frame
	assert_eq(AudioServer.get_bus_effect_count(bus), before, "收掉：低通拿掉")
	assert_true(is_equal_approx(AudioServer.playback_speed_scale, 1.0), "速度還原")


func test_the_dropped_core_rolls_onto_open_floor_away_from_pillars_and_leos_party() -> void:
	var clear := func(p: Vector3) -> bool: return RuinedAltar.core_spot_clear(p)
	assert_false(bool(clear.call((RuinedAltar.PARTY[0][2] as Vector3) + Vector3(0.5, 0.0, 0.3))), "壓到躺著的雷歐：不行")
	assert_false(bool(clear.call(Vector3(cos(deg_to_rad(22.0)), 0.0, sin(deg_to_rad(22.0))) * AltarScenery.PILLAR_RING)), "斷柱上：不行")
	assert_false(bool(clear.call(Vector3(15.6, 0.0, 0.0))), "石板邊上：不行")
	assert_true(bool(clear.call(Vector3(2.0, 0.0, 4.0))), "空著的石板：可以")
	var moved: int = 0
	var bad: PackedStringArray = []
	var cases: int = 0
	for x: int in range(-12, 13, 2):
		for z: int in range(-7, 14, 2):
			var at := Vector3(float(x), 0.0, float(z))
			# 魔像站得到的地方（不在柱子、躺著的人身上）
			if not AltarScenery.open_floor(at, 1.2) or not bool(clear.call(at)):
				continue
			for k: int in 8:
				var fwd := Vector3(sin(TAU * float(k) / 8.0), 0.0, cos(TAU * float(k) / 8.0))
				cases += 1
				var first: Vector3 = PlagueGolem.core_rest_spot(at, fwd)
				var rest: Vector3 = PlagueGolem.core_rest_spot(at, fwd, clear)
				if not bool(clear.call(first)):
					moved += 1
				if not bool(clear.call(rest)):
					bad.append("%s→%s" % [at, rest])
				var d: float = Vector2(rest.x - at.x, rest.z - at.z).length()
				if d < 1.5 or d > 3.4:
					bad.append("%s 滾了 %.1f m" % [at, d])
	print("    核心停的地方：%d 種倒法，%d 種的第一個位置會壓到東西、換了位置" % [cases, moved])
	assert_true(cases > 300 and moved > 10, "有會壓到東西的倒法（%d／%d）" % [moved, cases])
	assert_eq(bad, PackedStringArray(), "每一種倒法都停在空著的石板上、在牠旁邊")
	# 同樣的輸入同樣的答案（讀檔回來擺在同一個地方）
	var a := PlagueGolem.core_rest_spot(Vector3(-6.5, 0, 0.5), Vector3.LEFT, clear)
	assert_eq(a, PlagueGolem.core_rest_spot(Vector3(-6.5, 0, 0.5), Vector3.LEFT, clear))


func test_lying_party_member_sits_up_around_the_hips() -> void:
	var lie: Transform3D = RuinedAltar.sitting_up(0.0)
	assert_true(lie.origin.is_equal_approx(Vector3(0.0, RuinedAltar.LIE_Y, RuinedAltar.LIE_FEET_Z)), "一開始跟躺著的時候一模一樣")
	assert_true(lie.basis.is_equal_approx(Basis(Vector3.RIGHT, PI * 0.5)), "整個人放倒（頭往 +Z）")
	var sat: Transform3D = RuinedAltar.sitting_up(1.0)
	assert_true(sat.basis.is_equal_approx(Basis.IDENTITY) and absf(sat.origin.y) < 0.001, "坐好：直立、腳底在地上")
	var pivots: Array[float] = []
	for k: float in [0.0, 0.25, 0.5, 0.75, 1.0]:
		var t: Transform3D = RuinedAltar.sitting_up(k)
		var hip: Vector3 = t.origin + t.basis * Vector3(0.0, lerpf(RuinedAltar.SIT_PIVOT, RuinedAltar.SIT_HIP, k), 0.0)
		pivots.append(hip.z)
		assert_true(hip.y > 0.1 and hip.y < 0.2, "骨盆一直貼著地（k=%.2f：%.2f m）" % [k, hip.y])
	assert_true(absf(pivots.max() - pivots.min()) < 0.001, "轉的支點在骨盆：骨盆不會前後滑")


func test_rock_debris_bursts_once_at_the_given_spot_and_cleans_up() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var ps: CPUParticles3D = RockDebris.burst(root, Vector3(3, 1, -2), Vector3.UP, 12, 0.2, Color(0.4, 0.4, 0.4), Vector2(2, 5))
	assert_eq(ps.global_position, Vector3(3, 1, -2), "噴在指定的地方（先擺好位置才開始噴）")
	assert_true(ps.one_shot and ps.emitting and ps.amount == 12)
	assert_true(ps.mesh is SphereMesh and (ps.mesh as SphereMesh).radial_segments <= 6, "是有稜角的石塊，不是面向鏡頭的圓點、也不是方塊")
	var glowing: CPUParticles3D = RockDebris.burst(root, Vector3.ZERO, Vector3.UP, 4, 0.2, Color(0.7, 0.4, 1.0), Vector2(2, 5), 3.0)
	assert_true(glowing.mesh is PrismMesh and ((glowing.mesh as PrismMesh).material as StandardMaterial3D).emission_enabled, "核心的晶片：細長的三角碎片，自己會亮")
	root.queue_free()
	await tree.process_frame


func test_golem_core_can_be_carried_on_norns_shoulder() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var body := Node3D.new()
	body.position = Vector3(4, 0, 4)
	root.add_child(body)
	var core: GolemCore = GolemCore.create()
	core.position = Vector3(1, 0.24, 1)
	root.add_child(core)
	core.carry_on(body, 0.1)
	assert_eq(core.get_parent(), body, "掛到他身上")
	assert_true(core.global_position.distance_to(Vector3(1, 0.24, 1)) < 0.01, "從地上原本的位置飛過去")
	await tree.create_timer(0.25).timeout
	assert_true(core.position.distance_to(GolemCore.CARRY_POS) < 0.01, "停在左肩旁邊")
	# 結尾的公會大廳：直接掛上去
	var carried: GolemCore = GolemCore.create()
	carried.carry_on(body)
	assert_eq(carried.position, GolemCore.CARRY_POS)
	root.queue_free()
	await tree.process_frame


func test_rubble_pile_is_a_long_heap_that_grows_out_of_the_ground() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var pile: RubblePile = RubblePile.create()
	root.add_child(pile)
	pile.face_along(Vector3(1, 0, 0))
	assert_true(pile.rock_count() >= 40, "幾十顆石頭（%d）" % pile.rock_count())
	var far: float = 0.0
	for at: Vector3 in pile.spots:
		far = maxf(far, pile.to_global(at).x)
	assert_true(far > RubblePile.LENGTH * 0.7, "沿著 face_along 的方向鋪出去（最遠 %.1f m）" % far)
	assert_not_null(pile.get_node_or_null("Block"), "擋路")
	# 石塊有稜角（D-306）：一面一面的切面——同一顆石頭上看得到很多不一樣的法線、而且不是圓的（頂點離中心的距離差很多）
	var rock: ArrayMesh = (pile.get_node("Heap/Rocks0") as MultiMeshInstance3D).multimesh.mesh as ArrayMesh
	var arr: Array = rock.surface_get_arrays(0)
	var normals: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var facets: Dictionary = {}
	for n: Vector3 in normals:
		facets[Vector3i((n * 20.0).round())] = true
	assert_true(facets.size() >= 20, "很多切面（%d 個方向）" % facets.size())
	var near: float = 9.0
	var farthest: float = 0.0
	for v: Vector3 in (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array):
		near = minf(near, v.length())
		farthest = maxf(farthest, v.length())
	assert_true(farthest - near > 0.12, "不是圓的（頂點離中心 %.2f～%.2f m）" % [near, farthest])
	var dim: float = 9.0
	var bright: float = 0.0
	var mossy: int = 0
	for c: Color in pile.shades:
		dim = minf(dim, c.get_luminance())
		bright = maxf(bright, c.get_luminance())
		if c.g > c.r * 1.15 and c.g > c.b * 1.15:
			mossy += 1
	assert_true(bright > dim * 2.0, "深淺差很多（%.2f～%.2f）" % [dim, bright])
	assert_true(mossy >= 4, "有幾顆長苔（%d）" % mossy)
	var shards := pile.get_node("Heap/Shards") as MultiMeshInstance3D
	assert_true(shards.multimesh.instance_count >= 5 and (shards.multimesh.mesh.surface_get_material(0) as StandardMaterial3D).emission_enabled, "還亮著的晶片自己發光")
	pile.grow(0.2)
	assert_true((pile.get_node("Heap") as Node3D).scale.y < 0.2, "一開始埋在地裡")
	await tree.create_timer(0.35).timeout
	assert_true((pile.get_node("Heap") as Node3D).scale.is_equal_approx(Vector3.ONE), "長出來了")
	root.queue_free()
	await tree.process_frame


func test_monster_strike_holds_at_the_top_until_released() -> void:
	var p := Puppet.new()
	tree.root.add_child(p)
	p.wind_up("hammer", 1.3)
	var apex: float = float(Puppet.MONSTER_APEX["hammer"])
	for i: int in 60:
		p.advance(1.0 / 60.0)
	assert_eq(p.action, "hammer")
	assert_true(p.is_holding() and is_equal_approx(p.action_time, apex), "舉到頂停住（%.2f 秒）" % p.action_time)
	p.release_hold()
	p.advance(Puppet.STRIKE_LEAD)
	assert_true(p.action_time > apex + Puppet.STRIKE_LEAD * 0.9 and not p.is_holding(), "放開就接著砸下去")
	# 前兆太短擺不完：整段播快、不停
	p.wind_up("punch", 0.4)
	for i: int in 30:
		p.advance(1.0 / 60.0)
	assert_false(p.is_holding(), "前兆太短不停")
	# 照指定的秒數整段縮放播（魔像吼多久、跪多久）
	p.play_action("kneel", 4.0)
	for i: int in 200:
		p.advance(1.0 / 60.0)
	assert_eq(p.action, "kneel", "4 秒的跪還沒跪完")
	for i: int in 50:
		p.advance(1.0 / 60.0)
	assert_eq(p.action, "", "跪完回到平常")
	p.queue_free()
	await tree.process_frame
