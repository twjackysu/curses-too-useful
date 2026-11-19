extends TestCase
## 諾恩身上的黑氣（DarkAura）：纏著身體的三條螺旋從腳邊繞到頭頂、下面寬上面窄；跟著 emitting 淡進淡出。


func test_wisp_mesh_spirals_from_the_feet_to_the_head() -> void:
	var mesh: ArrayMesh = DarkAura.wisp_mesh()
	var verts: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array
	assert_eq(verts.size(), DarkAura.WISPS * DarkAura.WISP_SEGMENTS * 6, "每條每段兩個三角形")
	var low: Vector3 = DarkAura.wisp_point(0.0, 0.0)
	var high: Vector3 = DarkAura.wisp_point(1.0, 0.0)
	assert_true(low.y < -0.7 and high.y > 0.9, "從腳邊到頭頂（%.2f → %.2f）" % [low.y, high.y])
	assert_true(Vector2(low.x, low.z).length() > Vector2(high.x, high.z).length(), "下面寬、上面窄")
	for t: float in [0.0, 0.25, 0.5, 0.75, 1.0]:
		var r: float = Vector2(DarkAura.wisp_point(t, 1.0).x, DarkAura.wisp_point(t, 1.0).z).length()
		assert_true(r > 0.22 and r < 0.6, "繞在身體外面、不會離太遠（t=%.2f r=%.2f）" % [t, r])


func test_wisps_fade_in_with_the_smoke_and_out_after() -> void:
	var who := Node3D.new()
	tree.root.add_child(who)
	var a: DarkAura = DarkAura.attach(who)
	await tree.process_frame
	assert_false(a.wisps.visible, "平常看不到")
	a.emitting = true
	for i: int in 3000:
		await tree.process_frame
		if a.wisp_fade >= 1.0:
			break
	assert_eq(a.wisp_fade, 1.0, "冒黑氣的時候纏上來")
	assert_true(a.wisps.visible)
	var yaw: float = a.wisps.rotation.y
	await tree.process_frame
	await tree.process_frame
	assert_ne(a.wisps.rotation.y, yaw, "慢慢繞")
	a.emitting = false
	for i: int in 3000:
		await tree.process_frame
		if a.wisp_fade <= 0.0:
			break
	assert_eq(a.wisp_fade, 0.0)
	assert_false(a.wisps.visible, "收掉")
	who.free()
