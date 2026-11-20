extends TestCase
## 森林外圍土坡上的石頭與倒木（SlopeClutter）：形狀的面朝外、擺在玩家走不到的坡上、貼著地面。


func _outward_ratio(mesh: ArrayMesh, axis_x: bool) -> float:
	var arrays: Array = mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var center: Vector3 = Vector3.ZERO
	for v: Vector3 in verts:
		center += v
	center /= float(verts.size())
	var out: int = 0
	for i: int in verts.size():
		var radial: Vector3 = verts[i] - center
		if axis_x:
			radial.x = 0.0 if absf(normals[i].x) < 0.7 else radial.x
		if radial.dot(normals[i]) > 0.0:
			out += 1
	return float(out) / float(verts.size())


func test_rock_and_log_faces_point_outwards() -> void:
	for k: int in SlopeClutter.ROCK_VARIANTS:
		var rock: ArrayMesh = SlopeClutter.rock_mesh(SlopeClutter.SEED + k)
		assert_true(_outward_ratio(rock, false) > 0.9, "石頭的法線朝外（%.2f）" % _outward_ratio(rock, false))
		var box: AABB = rock.get_aabb()
		assert_true(box.position.y > -0.05 and box.position.y < 0.1, "底是平的、在原點附近（%.2f）" % box.position.y)
		assert_true(box.size.y < box.size.x, "壓扁的（%.2f × %.2f）" % [box.size.x, box.size.y])
	var log: ArrayMesh = SlopeClutter.log_mesh(7, 3.0, 0.3)
	assert_true(_outward_ratio(log, true) > 0.9, "倒木的側面與兩頭的截面都朝外（%.2f）" % _outward_ratio(log, true))
	var lb: AABB = log.get_aabb()
	assert_true(lb.size.x > 2.6 and lb.size.x < 3.6, "長度差不多（%.2f）" % lb.size.x)


func test_rocks_and_logs_sit_on_the_slopes_out_of_reach() -> void:
	var level := Node3D.new()
	var root: Node3D = SlopeClutter.build(level, PackedVector3Array())
	var rocks: int = 0
	var logs: int = 0
	for n: Node in root.get_children():
		var mi := n as MeshInstance3D
		var p := Vector2(mi.position.x, mi.position.z)
		assert_true(ForestMap.trail_reach(p) > ForestMap.STRAY_LIMIT, "擺在玩家走不到的地方：%s 離路網 %.1f m" % [str(p), ForestMap.trail_reach(p)])
		var ground: float = ForestMap.ground_y(p)
		if n.name.begins_with("Log"):
			logs += 1
			assert_true(mi.position.y > ground and mi.position.y < ground + 0.4, "倒木半埋在地上（%.2f / 地面 %.2f）" % [mi.position.y, ground])
			var along: Vector3 = mi.basis.x.normalized()
			var a := p + Vector2(along.x, along.z) * 1.2
			var b := p - Vector2(along.x, along.z) * 1.2
			assert_true(absf(ForestMap.ground_y(a) - ForestMap.ground_y(b)) < 0.6, "順著坡躺、兩頭不懸空（%.2f）" % absf(ForestMap.ground_y(a) - ForestMap.ground_y(b)))
		else:
			rocks += 1
			assert_true(mi.position.y <= ground + 0.01, "石頭的底埋進土裡")
	assert_true(rocks >= SlopeClutter.ROCKS, "石頭夠多（%d）" % rocks)
	assert_eq(logs, SlopeClutter.LOGS, "倒木")
	var high: int = 0
	for n: Node in root.get_children():
		if (n as Node3D).position.y > 1.0:
			high += 1
	assert_true(high > root.get_child_count() / 3, "大多擺在坡上，不是坡腳的平地（%d / %d）" % [high, root.get_child_count()])
	level.free()
