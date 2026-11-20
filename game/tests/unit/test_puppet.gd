extends TestCase
## 程序人偶：狀態名（將來 AnimationTree 用同一組）、動作播完回到移動、走路時四肢有擺動。


func _make() -> Puppet:
	var p := Puppet.new()
	tree.root.add_child(p)
	return p


func test_states_follow_speed() -> void:
	var p: Puppet = _make()
	assert_eq(Puppet.STATES, PackedStringArray(["idle", "walk", "run", "dodge", "attack", "shoot", "reach", "give",
		"nod", "bow", "point", "chest", "shrug", "fist", "wave", "fumble", "reload", "swap", "lift_blade", "roar", "gaze", "kneel", "flinch", "punch", "hammer", "collapse"]), "狀態名固定")
	assert_eq(Puppet.GESTURES, DialogueDB.ACTS, "對話資料寫得到的手勢都做得出來")
	for g: String in Puppet.GESTURES:
		assert_true(Puppet.ACTION_TIME.has(g) and CharacterModels.ANIM_MAP.has(g), "手勢 %s 有長度、有模型的動作名" % g)
	assert_eq(p.current_state(), "idle")
	p.set_move_speed(1.6)
	assert_eq(p.current_state(), "walk")
	p.set_move_speed(3.4)
	assert_eq(p.current_state(), "run", "諾恩平常的移動速度是小跑，用跑的動作")
	p.set_move_speed(5.8)
	assert_eq(p.current_state(), "run")
	p.set_move_speed(0.0)
	assert_eq(p.current_state(), "idle")
	p.free()


func test_actions_return_to_locomotion() -> void:
	var p: Puppet = _make()
	p.set_move_speed(3.4)
	p.play_action("dodge")
	assert_eq(p.current_state(), "dodge")
	p.advance(0.2)
	assert_eq(p.current_state(), "dodge", "閃避還沒播完")
	assert_true(absf(p.get_node("Roll").rotation.x) > 0.5, "閃避時在翻滾")
	p.advance(0.2)
	assert_eq(p.current_state(), "run", "播完回到跑步")
	p.advance(0.01)
	assert_eq(p.get_node("Roll").rotation.x, 0.0, "翻滾結束身體回正")
	p.play_action("attack")
	p.advance(0.15)
	assert_true(p.joint("shoulder_R").rotation.x > 1.0, "攻擊舉起右手")
	p.advance(0.5)
	assert_eq(p.current_state(), "run")
	p.free()


## 程式人偶的坐姿（公會大廳坐著的人，模型不在時）：骨盆在座面高度、膝蓋往前（人偶面向 -Z）、小腿垂直往下到地面附近。
func test_sitting() -> void:
	var p: Puppet = _make()
	p.pose = "sit"
	p.advance(0.1)
	var hips: Vector3 = p.joint("hips").global_position
	var knee: Vector3 = p.joint("knee_L").global_position
	assert_true(absf(hips.y - Puppet.SIT_HIP_HEIGHT) < 0.02, "骨盆在座面高度（%.2f）" % hips.y)
	assert_true(knee.z < -0.35 and absf(knee.y - hips.y) < 0.1, "大腿往前平放（膝 %s）" % knee)
	var foot: Vector3 = p.joint("knee_L").to_global(Vector3(0, -Puppet.SHIN_LEN, 0))
	assert_true(foot.y < 0.12 and absf(foot.z - knee.z) < 0.1, "小腿垂直往下到地面附近（%s）" % foot)
	p.free()


func test_attack_speed_only_speeds_the_attack() -> void:
	var p: Puppet = _make()
	p.attack_speed = 1.5
	p.play_action("attack")
	var frames: int = 0
	while p.action == "attack" and frames < 200:
		p.advance(1.0 / 60.0)
		frames += 1
	var normal: int = ceili(float(Puppet.ACTION_TIME["attack"]) * 60.0)
	assert_true(frames < normal - 6, "出手播得比較快（%d 幀，原本 %d）" % [frames, normal])
	assert_true(frames >= int(float(normal) / 1.5) - 1, "但只快 1.5 倍")
	p.play_action("dodge")
	frames = 0
	while p.action == "dodge" and frames < 200:
		p.advance(1.0 / 60.0)
		frames += 1
	assert_true(absi(frames - ceili(float(Puppet.ACTION_TIME["dodge"]) * 60.0)) <= 1, "閃避還是原速（%d 幀）" % frames)
	p.free()
