class_name SlopeClutter
extends RefCounted
## 森林外圍土坡上的石頭與倒木（D-311）：坡以前只有草，看起來像畫在背景上的。只是場景——擺在玩家走不到的地方
## （離路網 REACH_MIN 以外；玩家在 ForestMap.STRAY_LIMIT 就被擋回來），沒有碰撞。
## 形狀是程式拼的（一顆壓扁、表面起伏的球；一根粗細不一、兩頭斷得參差的圓木），顏色照形狀算（forest_rock.gdshader）。
## 噴發口的底座（ForestExplore）也用這裡的石頭。

const SHADER: Shader = preload("res://src/world/forest_rock.gdshader")
const ROCK_VARIANTS: int = 4
const ROCKS: int = 44
const LOGS: int = 14
## 離路網多遠開始擺、最遠擺到哪（坡腳在 ForestMap.RELIEF_START）
const REACH_MIN: float = 17.0
const REACH_MAX: float = 30.0
## 擺放的範圍（跟北邊的樹差不多）
const AREA: Rect2 = Rect2(-66.0, -100.0, 136.0, 146.0)
const SEED: int = 20261120


## 一顆石頭（半徑約 1 m、底是平的，原點在底面中心附近）：經緯球每一點照 3D 雜訊推遠推近、壓扁。
static func rock_mesh(seed_value: int, rings: int = 7, segments: int = 11) -> ArrayMesh:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 0.9
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in rings + 1:
		var phi: float = float(i) / float(rings) * PI
		for j: int in segments:
			var th: float = float(j) / float(segments) * TAU
			var dir := Vector3(sin(phi) * cos(th), cos(phi), sin(phi) * sin(th))
			var r: float = 1.0 + 0.3 * noise.get_noise_3dv(dir * 1.2) + 0.1 * noise.get_noise_3dv(dir * 3.0 + Vector3(5.0, 5.0, 5.0))
			var p: Vector3 = dir * r
			p.y = maxf(p.y * 0.62, -0.2) + 0.2
			st.add_vertex(p)
	for i: int in rings:
		for j: int in segments:
			var a: int = i * segments + j
			var b: int = i * segments + (j + 1) % segments
			var c: int = a + segments
			var d: int = b + segments
			st.add_index(a)
			st.add_index(c)
			st.add_index(b)
			st.add_index(b)
			st.add_index(c)
			st.add_index(d)
	st.generate_normals()
	return st.commit()


## 一根倒木：沿 x 軸、長 length、半徑約 radius，粗細沿著長度起伏、一頭細一點；兩頭是斷口（參差的截面，法線順著 x 軸）。
static func log_mesh(seed_value: int, length: float, radius: float, sides: int = 10, rings: int = 7) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ring_r: PackedFloat32Array = []
	for i: int in rings + 1:
		var t: float = float(i) / float(rings)
		ring_r.append(radius * lerpf(1.08, 0.86, t) * rng.randf_range(0.93, 1.07))
	# 兩頭斷口的每一點往裡外錯開一點（參差）；側面最外一圈跟斷口用同一個位置，才不會有縫
	var jag: Array[PackedFloat32Array] = []
	for e: int in 2:
		var row := PackedFloat32Array()
		for j: int in sides:
			row.append(rng.randf_range(-0.12, 0.12) * radius * 2.0)
		jag.append(row)
	var side_start: int = 0
	for i: int in rings + 1:
		var x: float = (float(i) / float(rings) - 0.5) * length
		for j: int in sides:
			var th: float = float(j) / float(sides) * TAU
			var dx: float = 0.0
			if i == 0:
				dx = jag[0][j]
			elif i == rings:
				dx = -jag[1][j]
			st.add_vertex(Vector3(x + dx, cos(th) * ring_r[i], sin(th) * ring_r[i]))
	for i: int in rings:
		for j: int in sides:
			var a: int = side_start + i * sides + j
			var b: int = side_start + i * sides + (j + 1) % sides
			var c: int = a + sides
			var d: int = b + sides
			st.add_index(a)
			st.add_index(c)
			st.add_index(b)
			st.add_index(b)
			st.add_index(c)
			st.add_index(d)
	# 兩頭的截面：中心一點往裡凹一點，扇形連到斷口那一圈（另外一份頂點，法線是硬的）
	for e: int in 2:
		var ring: int = 0 if e == 0 else rings
		var x0: float = (float(ring) / float(rings) - 0.5) * length
		var inward: float = 1.0 if e == 0 else -1.0
		var center_index: int = (rings + 1) * sides + e * (sides + 1)
		st.add_vertex(Vector3(x0 + inward * radius * 0.15, 0.0, 0.0))
		for j: int in sides:
			var th: float = float(j) / float(sides) * TAU
			var dx: float = jag[0][j] if e == 0 else -jag[1][j]
			st.add_vertex(Vector3(x0 + dx, cos(th) * ring_r[ring], sin(th) * ring_r[ring]))
		for j: int in sides:
			var a: int = center_index + 1 + j
			var b: int = center_index + 1 + (j + 1) % sides
			st.add_index(center_index)
			if e == 0:
				st.add_index(b)
				st.add_index(a)
			else:
				st.add_index(a)
				st.add_index(b)
	st.generate_normals()
	return st.commit()


static func rock_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	return mat


static func log_material(radius: float) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("is_log", 1.0)
	mat.set_shader_parameter("log_radius", radius)
	return mat


## 地面在這一點往哪個方向爬升（水平的單位向量；平地回傳零向量）。
static func uphill(p: Vector2) -> Vector2:
	var e: float = 0.8
	var g := Vector2(ForestMap.ground_y(p + Vector2(e, 0.0)) - ForestMap.ground_y(p - Vector2(e, 0.0)),
		ForestMap.ground_y(p + Vector2(0.0, e)) - ForestMap.ground_y(p - Vector2(0.0, e)))
	return g.normalized() if g.length() > 0.001 else Vector2.ZERO


## 在坡上擺石頭（有大有小，一半是一大配一兩顆小的一堆）與倒木（順著等高線躺，才不會一頭懸空）。trees＝樹的位置（x、大小、z），不擺在樹腳下。
static func build(level: Node3D, trees: PackedVector3Array) -> Node3D:
	var root := Node3D.new()
	root.name = "SlopeClutter"
	level.add_child(root)
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var meshes: Array[ArrayMesh] = []
	for k: int in ROCK_VARIANTS:
		meshes.append(rock_mesh(SEED + k))
	var stone: ShaderMaterial = rock_material()
	var taken: PackedVector3Array = trees.duplicate()
	var rocks: int = 0
	var logs: int = 0
	var tries: int = 0
	while (rocks < ROCKS or logs < LOGS) and tries < 6000:
		tries += 1
		var p := Vector2(rng.randf_range(AREA.position.x, AREA.end.x), rng.randf_range(AREA.position.y, AREA.end.y))
		var reach: float = ForestMap.trail_reach(p)
		if reach < REACH_MIN or reach > REACH_MAX or ForestScenery.crowded(taken, Vector3(p.x, 0.0, p.y), 2.8):
			continue
		var up: Vector2 = uphill(p)
		if logs < LOGS and (rocks >= ROCKS or rng.randf() < 0.25):
			var radius: float = rng.randf_range(0.26, 0.4)
			var length: float = rng.randf_range(2.6, 4.4)
			var along: Vector2 = Vector2(-up.y, up.x) if up != Vector2.ZERO else Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU))
			var mi := MeshInstance3D.new()
			mi.name = "Log%d" % (logs + 1)
			mi.mesh = log_mesh(SEED + 100 + logs, length, radius)
			mi.material_override = log_material(radius)
			mi.position = Vector3(p.x, ForestMap.ground_y(p) + radius * 0.55, p.y)
			mi.rotation = Vector3(0.0, atan2(-along.y, along.x), 0.0)
			mi.rotate_object_local(Vector3.RIGHT, rng.randf_range(0.0, TAU))
			root.add_child(mi)
			taken.append(Vector3(p.x, 1.0, p.y))
			logs += 1
			continue
		var pile: int = 1 if rng.randf() < 0.5 else rng.randi_range(2, 3)
		var big: float = rng.randf_range(0.55, 1.35)
		for k: int in pile:
			var at: Vector2 = p if k == 0 else p + Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU)) * big * rng.randf_range(1.1, 1.6)
			var s: float = big if k == 0 else big * rng.randf_range(0.3, 0.55)
			var mi := MeshInstance3D.new()
			mi.name = "Rock%d" % (rocks + 1)
			mi.mesh = meshes[rng.randi_range(0, ROCK_VARIANTS - 1)]
			mi.material_override = stone
			mi.scale = Vector3(s * rng.randf_range(0.9, 1.35), s * rng.randf_range(0.75, 1.1), s * rng.randf_range(0.9, 1.3))
			mi.position = Vector3(at.x, ForestMap.ground_y(at) - 0.25 * s, at.y)
			mi.rotation = Vector3(up.y * 0.25, rng.randf_range(0.0, TAU), -up.x * 0.25)
			root.add_child(mi)
			rocks += 1
		taken.append(Vector3(p.x, 1.0, p.y))
	return root
