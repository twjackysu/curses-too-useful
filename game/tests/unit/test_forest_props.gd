extends TestCase
## 森林的小東西：土坡上的石頭與倒木（SlopeClutter）、噴發口的底座、三種樹怎麼混著種。


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


## 噴發口的底座：外面一圈裂縫發綠光的石頭、地上一圈綠縫（畫在最底那一層霧盤上面）。
func test_vent_rim_has_glowing_stones_and_ground_cracks() -> void:
	var rim: Node3D = ForestExplore.vent_rim(2)
	var stones: int = 0
	for n: Node in rim.get_children():
		if n.name == "Cracks":
			continue
		stones += 1
		var mat := (n as MeshInstance3D).material_override as ShaderMaterial
		assert_eq(float(mat.get_shader_parameter("crack_glow")), 1.0, "石頭的裂縫發光")
		var d: float = Vector2((n as Node3D).position.x, (n as Node3D).position.z).length()
		assert_true(d > 0.6 and d < 1.1, "圍在洞口外面（%.2f m）" % d)
	assert_eq(stones, ForestExplore.VENT_RIM_STONES)
	var cracks := rim.get_node("Cracks") as MeshInstance3D
	assert_true(cracks.position.y > 0.06, "綠縫在最底那一層霧盤（0.06 m）上面")
	assert_eq((cracks.mesh.surface_get_material(0) as ShaderMaterial).shader, ForestExplore.VENT_CRACK_SHADER)
	rim.free()


## 三種樹照位置混著種（另外兩種還在 Tripo 佇列裡：檔案不在就種第一種）。
func test_tree_kind_mixes_three_models_by_spot() -> void:
	var seen: Dictionary = {}
	for i: int in 60:
		var at := Vector3(float(i) * 4.3 - 120.0, 0.0, float(i * 11 % 37) * 3.1 - 50.0)
		var k: int = ForestScenery.tree_kind(at)
		assert_true(k >= 0 and k < ForestScenery.TREE_MODELS.size())
		assert_eq(ForestScenery.tree_kind(at), k, "同一個位置每次都一樣")
		seen[k] = int(seen.get(k, 0)) + 1
	assert_eq(seen.size(), 3, "三種都有")
	assert_true(int(seen[0]) > 20, "第一種最多（%d）" % int(seen[0]))
	var stand := TreeStand.new()
	for i: int in 40:
		stand.add(Vector3(float(i) * 4.3 - 80.0, 0.0, float(i * 11 % 37) * 3.1 - 50.0), 1.0, 0.0)
	stand.build()
	var drawn: int = 0
	for c: Node in stand.find_children("*", "MultiMeshInstance3D", false, false):
		drawn += (c as MultiMeshInstance3D).multimesh.instance_count
	assert_eq(drawn, stand.count(), "檔案不在的那一種也種得出樹（種成第一種）")
	assert_eq(stand.get_node("Trunks").get_child_count(), stand.count(), "每一棵一根擋人的樹幹")
	stand.free()


## 一片樹畫成一塊一塊的 MultiMesh：位置、大小、朝向照種下去的那樣（跟以前一棵一個節點時一樣），樹幹的碰撞在腳下。
func test_tree_stand_places_each_tree_where_it_was_planted() -> void:
	var stand := TreeStand.new()
	stand.add(Vector3(5.0, -0.3, 7.0), 1.2, 0.6)
	stand.add(Vector3(-40.0, 0.0, 33.0), 0.9, 2.0)
	stand.build()
	var chunks: Array[Node] = stand.find_children("*", "MultiMeshInstance3D", false, false)
	assert_true(chunks.size() >= 2, "離 %d m 以上的兩棵在不同塊" % int(TreeStand.CHUNK))
	for c: Node in chunks:
		assert_eq((c as MultiMeshInstance3D).multimesh.instance_count, 1, "一塊一棵（%s）" % c.name)
	var v: Vector3 = ForestScenery.variation(Vector3(5.0, -0.3, 7.0))
	var t0: Transform3D = stand.instance_transform(0, Transform3D.IDENTITY, true)
	assert_true(t0.origin.distance_to(Vector3(5.0, -0.3, 7.0)) < 0.001, "種在種下去的地方（模型的原點在樹腳下）")
	assert_true(absf(t0.basis.get_scale().y - 1.2 * v.y) < 0.001 and absf(t0.basis.get_scale().x - 1.2 * v.x) < 0.001, "高矮胖瘦照位置變")
	assert_true(t0.basis.z.normalized().dot(Vector3(sin(0.6), 0.0, cos(0.6))) > 0.99, "朝向照種的時候給的")
	assert_ne(stand.tint(0), stand.tint(1), "兩棵的顏色偏得不一樣")
	var trunk := stand.get_node("Trunks").get_child(0) as CollisionShape3D
	assert_true(trunk.position.distance_to(Vector3(5.0, -0.3 + TreeStand.TRUNK_HEIGHT * 0.5, 7.0)) < 0.01, "樹幹立在樹腳下")
	assert_true(absf((trunk.shape as CylinderShape3D).radius - TreeStand.TRUNK_RADIUS * 1.2) < 0.001, "樹幹粗細照大小")
	stand.free()


## 遠處的小東西不畫、小燈淡掉（FarCull）：人物不動、大的東西不動、已經設了的不動
func test_far_cull_skips_people_and_big_things() -> void:
	var root := Node3D.new()
	var rock := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.0, 0.6, 1.2)
	rock.mesh = box
	root.add_child(rock)
	var hill := MeshInstance3D.new()
	var big := BoxMesh.new()
	big.size = Vector3(20.0, 3.0, 20.0)
	hill.mesh = big
	root.add_child(hill)
	var scaled := MeshInstance3D.new()
	scaled.mesh = box
	scaled.scale = Vector3.ONE * 6.0
	root.add_child(scaled)
	var lamp := OmniLight3D.new()
	root.add_child(lamp)
	var near_lamp := OmniLight3D.new()
	near_lamp.distance_fade_enabled = true
	near_lamp.distance_fade_begin = 10.0
	root.add_child(near_lamp)
	var person := CharacterBody3D.new()
	var face := MeshInstance3D.new()
	face.mesh = box
	person.add_child(face)
	var glow := OmniLight3D.new()
	person.add_child(glow)
	root.add_child(person)
	var moon := DirectionalLight3D.new()
	root.add_child(moon)
	var counts: Vector2i = FarCull.apply(root)
	assert_eq(rock.visibility_range_end, FarCull.FAR, "小石頭遠了不畫")
	assert_eq(hill.visibility_range_end, 0.0, "大的東西照畫")
	assert_eq(scaled.visibility_range_end, 0.0, "放大過的照放大後的大小算")
	assert_true(lamp.distance_fade_enabled and is_equal_approx(lamp.distance_fade_begin, FarCull.LIGHT_BEGIN), "小燈遠了淡掉")
	assert_eq(near_lamp.distance_fade_begin, 10.0, "自己設了的不動")
	assert_eq(face.visibility_range_end, 0.0, "人物不動")
	assert_false(glow.distance_fade_enabled, "人物身上的光不動")
	assert_eq(moon.directional_shadow_max_distance, FarCull.MOON_SHADOW_FAR, "月光的影子只算到近的")
	assert_eq(counts, Vector2i(1, 1))
	root.free()
