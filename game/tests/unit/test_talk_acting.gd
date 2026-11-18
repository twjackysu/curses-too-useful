extends TestCase
## 對話的演出（TalkActing）：每一句照資料冒漫符、做手勢，講話的人字還在浮現時頭會動；漫符（MangaMark）的樣子。


func _dialogue_db() -> DialogueDB:
	var db := DialogueDB.new()
	db.add_dialogue({"id": "t_act", "start": "a", "nodes": {
		"a": {"speaker": "SPK_A", "text": "DLG_CH1_ASK_001", "emote": "sweat", "act": "bow", "next": "b"},
		"b": {"speaker": "SPK_B", "text": "DLG_CH1_ASK_002", "emote": "blush", "next": "c"},
		"c": {"speaker": "SPK_A", "text": "DLG_CH1_ASK_003"}}})
	assert_eq(db.errors, PackedStringArray())
	return db


func test_each_line_pops_its_mark_plays_its_gesture_and_moves_the_head() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var home := Camera3D.new()
	home.position = Vector3(2, 2, 4)
	root.add_child(home)
	home.current = true
	var a: Npc = Npc.create("A", "", Vector3(0, 0, 0), 0.0)
	var b: Npc = Npc.create("B", "", Vector3(0, 0, -2), 180.0)
	root.add_child(a)
	root.add_child(b)
	var cam := TalkCamera.new()
	root.add_child(cam)
	cam.cast["SPK_A"] = a
	cam.cast["SPK_B"] = b
	await tree.process_frame
	var before: DialogueRunner = Game.dialogue
	var r := DialogueRunner.new(_dialogue_db(), GameState.new())
	Game.dialogue = r
	assert_true(r.start("t_act"))
	await tree.physics_frame
	await tree.physics_frame
	var marks: Array[MangaMark] = cam.acting.marks()
	assert_eq(marks.size(), 1, "第一句冒一個漫符")
	assert_eq(marks[0].kind, "sweat")
	assert_true(marks[0].get_parent() == a, "冒在講話的人身上")
	assert_eq(a.puppet.action, "bow", "做這一句的手勢")
	assert_true(a.puppet.talking, "講話的人頭會動")
	assert_false(b.puppet.talking, "聽的人不動")
	# 字浮現完（這一句最多二十幾個字，對話框每秒 38 個字）頭就停
	for i: int in 50:
		await tree.physics_frame
	assert_false(a.puppet.talking, "字都出來了就停")
	r.advance()
	await tree.physics_frame
	await tree.physics_frame
	marks = cam.acting.marks()
	assert_eq(marks.size(), 1, "換句子：上一個收起來、這一句的冒出來")
	assert_eq(marks[0].kind, "blush")
	assert_true(marks[0].get_parent() == b)
	assert_true(b.puppet.talking and not a.puppet.talking, "換人講")
	# 坐著的人不做手勢
	a.pose = "sit"
	r.advance()
	await tree.physics_frame
	await tree.physics_frame
	assert_eq(cam.acting.marks().size(), 0, "沒有漫符的那一句什麼都不冒")
	r.advance()
	await tree.physics_frame
	assert_false(r.is_running())
	for i: int in 3:
		await tree.physics_frame
	assert_false(a.puppet.talking or b.puppet.talking, "講完都停")
	Game.dialogue = before
	root.queue_free()
	await tree.process_frame


func test_sitting_or_walking_people_skip_the_gesture() -> void:
	var p := Puppet.new()
	tree.root.add_child(p)
	assert_true(p.can_gesture(), "站著可以")
	p.pose = "sit_hunch"
	assert_false(p.can_gesture(), "坐著不行")
	p.pose = ""
	p.set_move_speed(1.5)
	assert_false(p.can_gesture(), "走著不行")
	p.set_move_speed(0.0)
	p.play_action("point")
	assert_false(p.can_gesture(), "正在做別的動作不行")
	p.queue_free()
	await tree.process_frame


## 頭動多少：講話時從 0 慢慢到 1，停下來慢慢回 0；角度不大（幾度）
func test_talking_head_eases_in_and_out() -> void:
	var p := Puppet.new()
	tree.root.add_child(p)
	assert_eq(p.talk_weight(), 0.0)
	p.talking = true
	p.advance(0.1)
	var w1: float = p.talk_weight()
	p.advance(0.5)
	assert_true(w1 > 0.0 and w1 < 1.0 and p.talk_weight() > 0.99, "慢慢動起來（%.2f → %.2f）" % [w1, p.talk_weight()])
	var biggest: float = 0.0
	for i: int in 60:
		p.advance(1.0 / 30.0)
		var n: Vector3 = p.nod_angles()
		biggest = maxf(biggest, maxf(absf(n.x), maxf(absf(n.y), absf(n.z))))
	assert_true(biggest > deg_to_rad(2.0) and biggest < deg_to_rad(9.0), "頭動幾度（最多 %.1f°）" % rad_to_deg(biggest))
	p.talking = false
	p.advance(0.5)
	assert_eq(p.talk_weight(), 0.0, "停下來")
	p.queue_free()
	await tree.process_frame


## 模型的頭真的會動（TalkNod 疊在動作上面），手上的掛點不受影響
func test_model_head_nods_on_top_of_the_animation() -> void:
	if CharacterModels.scene_for("sheila") == null:
		return  # 沒有轉好的模型（沒有 bpy 的機器）：程式人偶的頭在 test_talking_head_eases_in_and_out
	var p := Puppet.new()
	p.character_id = "sheila"
	tree.root.add_child(p)
	await tree.process_frame
	assert_true(p.uses_model())
	var nod: TalkNod = p.skeleton.get_node_or_null("TalkNod") as TalkNod
	assert_true(nod != null and nod.bone >= 0, "模型的骨架上有 TalkNod")
	var head: Node3D = p.joint("head")
	var still: Array[Basis] = []
	var moving: Array[Basis] = []
	for i: int in 12:
		await tree.process_frame
		still.append(head.global_basis)
	p.talking = true
	for i: int in 30:
		await tree.process_frame
	for i: int in 12:
		await tree.process_frame
		moving.append(head.global_basis)
	var diff_still: float = 0.0
	var diff_moving: float = 0.0
	for i: int in 11:
		diff_still = maxf(diff_still, still[i].get_rotation_quaternion().angle_to(still[i + 1].get_rotation_quaternion()))
		diff_moving = maxf(diff_moving, moving[i].get_rotation_quaternion().angle_to(moving[i + 1].get_rotation_quaternion()))
	assert_true(diff_moving > diff_still + 0.004, "講話時頭動得比平常多（%.4f vs %.4f rad／幀）" % [diff_moving, diff_still])
	p.queue_free()
	await tree.process_frame


func test_marks_pop_follow_the_head_and_fade_away() -> void:
	for k: String in DialogueDB.EMOTES:
		assert_true(MangaMark.KINDS.has(k) and MangaMark.LOOK.has(k), "對話資料用得到的漫符都畫得出來：%s" % k)
	var nobody := Node3D.new()
	assert_eq(MangaMark.pop("dance", nobody), null, "不認得的不冒")
	nobody.free()
	assert_true(MangaMark.pop_scale(0.0) < 0.05 and MangaMark.pop_scale(MangaMark.POP_SEC * 0.6) > 1.0, "彈出來：從 0 長到比原本大一點")
	assert_eq(MangaMark.pop_scale(MangaMark.POP_SEC + 0.1), 1.0)
	var root := Node3D.new()
	tree.root.add_child(root)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.6, 3)
	root.add_child(cam)
	cam.current = true
	var who := Node3D.new()
	who.position = Vector3(1, 0, 0)
	root.add_child(who)
	var m: MangaMark = MangaMark.pop("question", who)
	await tree.process_frame
	await tree.process_frame
	assert_true(m.global_position.y > MangaMark.HEAD_FALLBACK + 0.1, "在頭的上面（%s）" % str(m.global_position))
	assert_true(m.global_position.x > who.global_position.x + 0.1, "偏到鏡頭的右邊")
	who.position = Vector3(-2, 0, 0)
	await tree.process_frame
	assert_true(m.global_position.x < -1.5, "跟著人走")
	# 臉紅貼在臉的前面：臉朝鏡頭看得到、背對鏡頭就淡掉
	var blush: MangaMark = MangaMark.pop("blush", who)
	who.rotation.y = PI  # 臉朝 +Z＝朝鏡頭
	await tree.process_frame
	assert_true(float(blush._mat.get_shader_parameter("alpha")) > 0.9, "臉朝鏡頭：看得到")
	who.rotation.y = 0.0
	await tree.process_frame
	assert_true(float(blush._mat.get_shader_parameter("alpha")) < 0.05, "背對鏡頭：淡掉")
	m.dismiss()
	await tree.create_timer(MangaMark.FADE_SEC + 0.15).timeout
	await tree.process_frame
	assert_false(is_instance_valid(m), "收起來之後自己消失")
	root.queue_free()
	await tree.process_frame
