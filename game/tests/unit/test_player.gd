extends TestCase
## 玩家移動的純函式部分。


func _approx(a: Vector3, b: Vector3) -> bool:
	return a.distance_to(b) < 0.001


func test_move_direction_follows_camera_yaw() -> void:
	assert_true(_approx(PlayerController.move_direction(Vector2(0, -1), 0.0), Vector3(0, 0, -1)), "鏡頭朝 -Z 時按前進往 -Z")
	assert_true(_approx(PlayerController.move_direction(Vector2(1, 0), 0.0), Vector3(1, 0, 0)), "右")
	# 鏡頭左轉 90°（yaw = +PI/2）時，前進變成往 -X
	assert_true(_approx(PlayerController.move_direction(Vector2(0, -1), PI / 2.0), Vector3(-1, 0, 0)), "轉向後前進")


func test_diagonal_is_not_faster() -> void:
	var d: Vector3 = PlayerController.move_direction(Vector2(1, -1), 0.3)
	assert_true(d.length() <= 1.0001, "斜走不會比直走快")


## 鷹眼（致盲被反轉）：同一刀砍在站著的史萊姆身上，傷害照「砍在破綻上」的倍率加倍，而且算一次破綻命中（比較大的閃光與停頓）。
func test_eagle_eye_makes_a_plain_cut_count_as_a_weak_spot_hit() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var player: PlayerController = (load("res://scenes/actors/player/player.tscn") as PackedScene).instantiate() as PlayerController
	root.add_child(player)
	var slime := Slime.new()
	slime.position = Vector3(0, 0, -1.0)
	root.add_child(slime)
	await tree.physics_frame
	slime.set_physics_process(false)
	player.on_hit_source = ""  # 只量致盲：不要劍自己給的流血把傷害往上帶
	var base: float = CombatTuning.num("noen.blunt_damage")
	var hp0: float = slime.health.hp
	assert_eq(player.strike(), 1)
	assert_true(absf(hp0 - slime.health.hp - base) < 0.01, "平常的一刀扣 %.0f" % base)
	assert_eq(player.last_weak_hits, 0)
	player.status_effects.apply_source(Sera.ASK_SOURCE)
	slime.health.hp = hp0  # 補滿：加倍的那一刀不要被「剩下的血」截掉
	var hp1: float = slime.health.hp
	assert_eq(player.strike(), 1)
	var dealt: float = hp1 - slime.health.hp
	assert_true(absf(dealt - base * CombatTuning.num("noen.weak_damage_mult")) < 0.01, "鷹眼的一刀扣 %.0f（平常的 %.1f 倍）" % [dealt, dealt / base])
	assert_eq(player.last_weak_hits, 1, "算一次砍在破綻上")
	root.queue_free()
	await tree.process_frame
