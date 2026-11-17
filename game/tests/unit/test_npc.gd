extends TestCase
## 站在場景裡的人（Npc）：走路時從諾恩旁邊繞過去，不穿過他；坐、笑、累垮（pose）交給外型。


func test_walking_npc_steps_around_norn_instead_of_through_him() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var norn := Node3D.new()
	norn.add_to_group("player")
	norn.position = Vector3(0, 0, -3)
	root.add_child(norn)
	var who: Npc = Npc.create("Walker", "", Vector3(0.05, 0, 0), 0.0)
	root.add_child(who)
	await tree.process_frame
	who.walk_to(Vector3(0, 0, -6), 2.0)
	var closest: float = INF
	for i: int in 240:
		await tree.physics_frame
		closest = minf(closest, Vector2(who.global_position.x, who.global_position.z).distance_to(Vector2(0, -3)))
		if not who.is_walking():
			break
	assert_false(who.is_walking(), "走到了")
	assert_true(who.global_position.distance_to(Vector3(0, 0, -6)) < 0.2, "停在目的地")
	assert_true(closest > 0.45, "從他旁邊繞過去（最近 %.2f m）" % closest)
	assert_true(who.footsteps.count > 0, "走路有腳步聲")
	# 樣子交給外型
	who.pose = "sit"
	assert_eq(who.puppet.pose, "sit")
	root.queue_free()
	await tree.process_frame
