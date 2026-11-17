class_name DarkAura
extends CPUParticles3D
## 諾恩身上的黑氣（docs/story/chapter-1.md 章節結尾：二樓的巡察官「盯著諾恩身上的黑氣」）：
## 從身體四周冒出來、慢慢往上飄散的暗紫色煙。平常不冒（emitting＝false），關卡在要讓人看到的那一刻打開。

const COLOR: Color = Color(0.1, 0.03, 0.16, 0.7)
const LIFETIME: float = 1.8


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
	who.add_child(a)
	return a
