class_name DarkAura
extends CPUParticles3D
## 諾恩身上的黑氣（docs/story/chapter-1.md 章節結尾：二樓的巡察官「盯著諾恩身上的黑氣」）：
## 從身體四周冒出來、慢慢往上飄散的暗紫色煙，加上纏著身體慢慢繞的三條螺旋（`Wisps`：dark_wisp.gdshader）。
## 平常不冒（emitting＝false），關卡在要讓人看到的那一刻打開；螺旋跟著淡進淡出（`wisp_fade`）。

const COLOR: Color = Color(0.1, 0.03, 0.16, 0.7)
const LIFETIME: float = 1.8
## 纏著身體的螺旋：幾條、繞幾圈、從腳邊到頭頂（相對發射器）、半徑（下面寬、上面窄）、帶子寬
const WISPS: int = 3
const WISP_TURNS: float = 1.3
const WISP_Y: Vector2 = Vector2(-0.8, 0.95)
const WISP_RADIUS: Vector2 = Vector2(0.52, 0.32)
const WISP_WIDTH: float = 0.26
const WISP_SEGMENTS: int = 56
## 螺旋每秒轉多少（弧度）；淡進淡出多快（每秒）
const WISP_SPIN: float = 0.7
const WISP_FADE_PER_SEC: float = 1.6

## 螺旋現在多濃（0～1，跟著 emitting 淡進淡出）
var wisp_fade: float = 0.0
var wisps: MeshInstance3D
var _wisp_mat: ShaderMaterial


## 掛到 who（諾恩）身上，一開始不冒
static func attach(who: Node3D) -> DarkAura:
	var a := DarkAura.new()
	a.name = "DarkAura"
	a.position = Vector3(0, 0.95, 0)
	a.emitting = false
	a.amount = 48
	a.lifetime = LIFETIME
	# 一開始就當成已經冒了一輪：連續冒的粒子在第一輪還沒發射出來的時候會在發射器的位置畫成一顆黑點（NEXT 的「小事」）
	a.preprocess = LIFETIME
	a.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE_SURFACE
	a.emission_sphere_radius = 0.42
	a.direction = Vector3.UP
	a.spread = 25.0
	a.initial_velocity_min = 0.15
	a.initial_velocity_max = 0.4
	a.gravity = Vector3(0, 0.35, 0)
	a.damping_min = 0.2
	a.damping_max = 0.4
	var quad := QuadMesh.new()
	quad.size = Vector2(0.34, 0.34)
	quad.material = ParticleLook.material(Color.WHITE)
	a.mesh = quad
	var ramp := Gradient.new()
	ramp.set_color(0, Color(COLOR, 0.0))
	ramp.set_color(1, Color(COLOR, 0.0))
	ramp.add_point(0.2, COLOR)
	ramp.add_point(0.65, Color(COLOR, COLOR.a * 0.6))
	a.color_ramp = ramp
	a._build_wisps()
	who.add_child(a)
	return a


## 螺旋的網格（純函式，測試用）：每條一段三角帶，UV.x 沿著帶子 0→1、UV.y 橫過帶子，COLOR.r＝第幾條
static func wisp_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k: int in WISPS:
		var phase: float = TAU * float(k) / float(WISPS)
		var c := Color(float(k) / float(WISPS), 0.0, 0.0, 1.0)
		for i: int in WISP_SEGMENTS:
			var quad: Array[Vector3] = []
			var uvs: Array[Vector2] = []
			for j: int in 2:
				var t: float = float(i + j) / float(WISP_SEGMENTS)
				var p: Vector3 = wisp_point(t, phase)
				# 帶子橫過去的方向：往上又往外斜（從上面往下看的過肩鏡頭也看得到帶子的面，不會只剩一條線）
				var across: Vector3 = (Vector3(p.x, 0, p.z).normalized() * 0.75 + Vector3.UP * 0.66).normalized() * WISP_WIDTH * 0.5
				quad.append(p - across)
				quad.append(p + across)
				uvs.append(Vector2(t, 0.0))
				uvs.append(Vector2(t, 1.0))
			for idx: int in [0, 1, 2, 2, 1, 3]:
				st.set_color(c)
				st.set_uv(uvs[idx])
				st.add_vertex(quad[idx])
	return st.commit()


## 第 phase 條螺旋走到 t（0＝腳邊、1＝頭頂）的位置
static func wisp_point(t: float, phase: float) -> Vector3:
	var ang: float = phase + t * WISP_TURNS * TAU
	var r: float = lerpf(WISP_RADIUS.x, WISP_RADIUS.y, t) + 0.05 * sin(t * 9.0 + phase * 2.0)
	return Vector3(cos(ang) * r, lerpf(WISP_Y.x, WISP_Y.y, t), sin(ang) * r)


func _build_wisps() -> void:
	wisps = MeshInstance3D.new()
	wisps.name = "Wisps"
	wisps.mesh = wisp_mesh()
	wisps.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_wisp_mat = ShaderMaterial.new()
	_wisp_mat.shader = load("res://src/world/dark_wisp.gdshader") as Shader
	_wisp_mat.set_shader_parameter("fade", 0.0)
	wisps.material_override = _wisp_mat
	wisps.visible = false
	add_child(wisps)


func _process(delta: float) -> void:
	if wisps == null:
		return
	wisp_fade = move_toward(wisp_fade, 1.0 if emitting else 0.0, delta * WISP_FADE_PER_SEC)
	wisps.visible = wisp_fade > 0.001
	if wisps.visible:
		wisps.rotate_y(delta * WISP_SPIN)
		_wisp_mat.set_shader_parameter("fade", wisp_fade)
