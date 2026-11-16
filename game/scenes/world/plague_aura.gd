class_name PlagueAura
extends Node3D
## 【深淵疫病魔像】的疫病光環（docs/story/chapter-1.md 節點 3）：以魔像為中心（掛在牠身上），半徑內的人每 0.25 秒刷新一次來源
## （data/status/statuses.json 的 plague_aura：全能力下降＋持續失血——落在諾恩身上是全能力提升＋每秒回血）。規則用 MistZone 現成的。
## 看得到的部分：腳邊一圈一圈往外擴的病綠色波紋（擴到光環的邊）＋光環裡慢慢往上飄的綠色光點。
## active＝false（魔像還沒醒、倒下了）的時候不上狀態，波紋與光點停掉。

const SOURCE: String = "plague_aura"
const COLOR: Color = Color(0.45, 1.0, 0.4)
## 幾道波紋輪流、一道從腳邊擴到邊緣要幾秒
const RIPPLES: int = 3
const RIPPLE_SEC: float = 3.3

var zone: MistZone
var radius: float = 13.0
var active: bool = false:
	set(on):
		active = on
		if _motes != null:
			_motes.emitting = on
var _rings: Array[MeshInstance3D] = []
var _mats: Array[StandardMaterial3D] = []
var _motes: CPUParticles3D
var _t: float = 0.0


static func create(p_radius: float) -> PlagueAura:
	var a := PlagueAura.new()
	a.name = "PlagueAura"
	a.radius = p_radius
	return a


func _ready() -> void:
	zone = MistZone.new(global_position, radius, SOURCE)
	zone.height = 6.0
	for i: int in RIPPLES:
		var ring := MeshInstance3D.new()
		ring.name = "Ripple%d" % i
		var torus := TorusMesh.new()
		torus.inner_radius = 0.985
		torus.outer_radius = 1.0
		torus.rings = 72
		torus.ring_segments = 4
		ring.mesh = torus
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.albedo_color = Color(COLOR.r * 1.6, COLOR.g * 1.6, COLOR.b * 1.6, 0.0)
		ring.material_override = mat
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ring.position = Vector3(0, 0.09, 0)
		add_child(ring)
		_rings.append(ring)
		_mats.append(mat)
	_motes = CPUParticles3D.new()
	_motes.name = "Motes"
	_motes.amount = 90
	_motes.lifetime = 3.0
	_motes.preprocess = 3.0
	_motes.local_coords = false
	_motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_motes.emission_box_extents = Vector3(radius * 0.7, 0.2, radius * 0.7)
	_motes.position = Vector3(0, 0.3, 0)
	_motes.direction = Vector3.UP
	_motes.spread = 10.0
	_motes.gravity = Vector3.ZERO
	_motes.initial_velocity_min = 0.3
	_motes.initial_velocity_max = 0.8
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.2, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color.WHITE, Color(1, 1, 1, 0)])
	_motes.color_ramp = fade
	var quad := QuadMesh.new()
	quad.size = Vector2(0.1, 0.1)
	quad.material = ParticleLook.material(COLOR, true)
	_motes.mesh = quad
	_motes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_motes.emitting = active
	add_child(_motes)


func contains(pos: Vector3) -> bool:
	return active and zone != null and zone.contains(pos)


func _physics_process(delta: float) -> void:
	zone.center = Vector3(global_position.x, 0.0, global_position.z)
	_t += delta
	for i: int in RIPPLES:
		var k: float = fposmod(_t / RIPPLE_SEC + float(i) / float(RIPPLES), 1.0)
		var r: float = lerpf(1.2, radius, k)
		_rings[i].scale = Vector3(r, 1.0, r)
		_rings[i].visible = active
		# 剛冒出來淡入、到邊緣淡出
		_mats[i].albedo_color.a = smoothstep(0.0, 0.12, k) * (1.0 - smoothstep(0.75, 1.0, k)) * 0.8
	if not active or Game.is_player_locked():
		return
	for n: Node in get_tree().get_nodes_in_group("player"):
		var p: PlayerController = n as PlayerController
		if p != null and not p.health.is_dead():
			zone.expose(p.get_instance_id(), p.global_position, p.status_effects, delta)
