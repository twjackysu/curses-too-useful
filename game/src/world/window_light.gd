class_name WindowLight
extends Node3D
## 太陽從一扇窗照進來（公會大廳）：①看得到的光柱——從窗口沿著太陽的方向一路掃到地上的薄面片（light_shaft.gdshader），
## 直的一組（窗的高度上一格一格）、橫的一組（窗的寬度上一格一格），從哪個方向看都有東西；
## ②地上一格一格的窗影——窗落在地上的那個平行四邊形，貼在地板上的一片加法面（window_patch.gdshader）。
##   試過聚光燈＋投影貼圖（走過去的人也會被照亮），但雲端的軟體算圖底下有投影貼圖的燈整盞不亮、沒辦法驗收，先用面片；
## ③光柱裡飄的灰塵（dust_mote.gdshader，一個 MultiMesh）。
## 窗與光的形狀都只看參數：窗在哪（中心、朝屋裡的方向）、多大、太陽往哪裡照。

const SHAFT_SHADER: Shader = preload("res://src/world/light_shaft.gdshader")
## 窗的木框與窗櫺（跟 guild_window.gdshader 一樣的比例）：兩邊的框佔寬的 6%、上下佔高的 4.5%，3 欄 × 4 列
const FRAME_SIDE: float = 0.06
const FRAME_TOP: float = 0.045
const COLS: int = 3
const ROWS: int = 4
## 一格玻璃裡直的、橫的面片各幾片
const SHEETS_PER_CELL: int = 3
## 地上的窗影離地板多高（蓋在地板上面）
const PATCH_LIFT: float = 0.012
const PATCH_SHADER: Shader = preload("res://src/world/window_patch.gdshader")
const DUST_SHADER: Shader = preload("res://src/world/dust_mote.gdshader")
## 一道光柱裡幾顆灰塵、一顆多大；灰塵只擺在光柱從窗口算起的這一段（後面淡掉了）
const DUST_COUNT: int = 36
const DUST_SIZE: float = 0.03
const DUST_REACH: float = 0.55

var shafts: MeshInstance3D
var patch: MeshInstance3D
var dust: MultiMeshInstance3D
## 光柱掃到地上的範圍（世界座標的 x、z；測試與擺東西用）
var floor_patch: Rect2


## center＝窗（玻璃）的中心；inward＝窗朝屋裡的方向（水平）；size＝窗的寬、高；dir＝太陽光往哪裡走（往下）
static func create(center: Vector3, inward: Vector3, size: Vector2, dir: Vector3, color: Color,
		shaft_energy: float, patch_energy: float) -> WindowLight:
	var w := WindowLight.new()
	w.name = "WindowLight"
	w._build(center, inward.normalized(), size, dir.normalized(), color, shaft_energy, patch_energy)
	return w


func _build(center: Vector3, inward: Vector3, size: Vector2, dir: Vector3, color: Color, shaft_energy: float, patch_energy: float) -> void:
	# 窗的兩個方向：across＝寬（水平、跟牆平行），up＝高
	var across: Vector3 = Vector3.UP.cross(inward).normalized()
	var top_left: Vector3 = center - across * size.x * 0.5 + Vector3.UP * size.y * 0.5
	# ①光柱：直的面片（固定在窗寬的某一點，從窗頂到窗底掃到地上）與橫的面片（固定在窗高的某一點，整個窗寬掃到地上）
	var upright := SurfaceTool.new()
	upright.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lying := SurfaceTool.new()
	lying.begin(Mesh.PRIMITIVE_TRIANGLES)
	for col: int in COLS:
		for k: int in SHEETS_PER_CELL:
			var s: float = FRAME_SIDE + (1.0 - 2.0 * FRAME_SIDE) * (float(col) + (float(k) + 0.5) / float(SHEETS_PER_CELL)) / float(COLS)
			var a: Vector3 = top_left + across * size.x * s
			var b: Vector3 = a - Vector3.UP * size.y
			_quad(upright, a, b, _to_floor(b, dir), _to_floor(a, dir))
	for row: int in ROWS:
		for k: int in SHEETS_PER_CELL - 1:
			var t: float = FRAME_TOP + (1.0 - 2.0 * FRAME_TOP) * (float(row) + (float(k) + 1.0) / float(SHEETS_PER_CELL)) / float(ROWS)
			var a: Vector3 = top_left - Vector3.UP * size.y * t
			var b: Vector3 = a + across * size.x
			_quad(lying, a, b, _to_floor(b, dir), _to_floor(a, dir))
	var mesh := ArrayMesh.new()
	upright.commit(mesh)
	lying.commit(mesh)
	mesh.surface_set_material(0, _shaft_material(color, shaft_energy, float(ROWS), FRAME_TOP))
	mesh.surface_set_material(1, _shaft_material(color, shaft_energy, float(COLS), FRAME_SIDE))
	shafts = MeshInstance3D.new()
	shafts.name = "Shafts"
	shafts.mesh = mesh
	shafts.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shafts)
	var corners: Array[Vector3] = [top_left, top_left + across * size.x, top_left - Vector3.UP * size.y, top_left + across * size.x - Vector3.UP * size.y]
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for c: Vector3 in corners:
		var f: Vector3 = _to_floor(c, dir)
		lo = Vector2(minf(lo.x, f.x), minf(lo.y, f.z))
		hi = Vector2(maxf(hi.x, f.x), maxf(hi.y, f.z))
	floor_patch = Rect2(lo, hi - lo)
	# ②地上的窗影：窗的四個角沿著太陽的方向落到地上，是一個平行四邊形；UV 直接用窗上的位置（平行投影＝線性，內插剛好對），
	#   shader 照同一個窗櫺的樣子畫亮的格子。貼在地板上面一點點（加法、不寫深度）
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lift := Vector3(0, PATCH_LIFT, 0)
	var f00: Vector3 = _to_floor(corners[0], dir) + lift
	var f10: Vector3 = _to_floor(corners[1], dir) + lift
	var f01: Vector3 = _to_floor(corners[2], dir) + lift
	var f11: Vector3 = _to_floor(corners[3], dir) + lift
	for v: Array in [[f00, Vector2(0, 0)], [f01, Vector2(0, 1)], [f11, Vector2(1, 1)], [f00, Vector2(0, 0)], [f11, Vector2(1, 1)], [f10, Vector2(1, 0)]]:
		st.set_normal(Vector3.UP)
		st.set_uv(v[1] as Vector2)
		st.add_vertex(v[0] as Vector3)
	patch = MeshInstance3D.new()
	patch.name = "FloorPatch"
	patch.mesh = st.commit()
	var pm := ShaderMaterial.new()
	pm.shader = PATCH_SHADER
	pm.set_shader_parameter("color", color)
	pm.set_shader_parameter("energy", patch_energy)
	patch.material_override = pm
	patch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(patch)
	_build_dust(top_left, across, size, dir, color)


## 灰塵：在窗上隨便挑一點、沿著光走一段（窗口到地上那一段的前 DUST_REACH），每次建出來的位置一樣（固定的亂數種子）
func _build_dust(top_left: Vector3, across: Vector3, size: Vector2, dir: Vector3, color: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(top_left)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var q := QuadMesh.new()
	q.size = Vector2.ONE * DUST_SIZE
	var m := ShaderMaterial.new()
	m.shader = DUST_SHADER
	m.set_shader_parameter("color", color)
	q.material = m
	mm.mesh = q
	mm.instance_count = DUST_COUNT
	for i: int in DUST_COUNT:
		var on_glass: Vector3 = top_left + across * size.x * rng.randf_range(0.1, 0.9) - Vector3.UP * size.y * rng.randf_range(0.1, 0.9)
		var reach: float = on_glass.y / -dir.y
		var at: Vector3 = on_glass + dir * reach * rng.randf_range(0.08, DUST_REACH)
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * rng.randf_range(0.6, 1.4)), at))
	dust = MultiMeshInstance3D.new()
	dust.name = "Dust"
	dust.multimesh = mm
	dust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(dust)


## p 沿著 dir 走到地上（y＝0）的那一點
static func _to_floor(p: Vector3, dir: Vector3) -> Vector3:
	return p + dir * (p.y / -dir.y)


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	# a＝窗上那一頭的起點（UV 0,0）、b＝窗上那一頭的終點（0,1）、c＝b 掃到地上（1,1）、d＝a 掃到地上（1,0）
	var n: Vector3 = (b - a).cross(d - a).normalized()
	for v: Array in [[a, Vector2(0, 0)], [b, Vector2(0, 1)], [c, Vector2(1, 1)], [a, Vector2(0, 0)], [c, Vector2(1, 1)], [d, Vector2(1, 0)]]:
		st.set_normal(n)
		st.set_uv(v[1] as Vector2)
		st.add_vertex(v[0] as Vector3)


func _shaft_material(color: Color, energy: float, cells: float, frame: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHAFT_SHADER
	m.set_shader_parameter("color", color)
	m.set_shader_parameter("energy", energy)
	m.set_shader_parameter("cells", cells)
	m.set_shader_parameter("frame", frame)
	return m
