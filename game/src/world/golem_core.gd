class_name GolemCore
extends Node3D
## 魔像核心（拿得走的那一顆）：暗色的石球，裂縫透出病綠色的光，旁邊一盞小燈。
## 魔像倒下時從胸口滾出來（PlagueGolem）、戰後飛到諾恩的左肩上（RuinedAltar）、結尾扛回公會（GuildHall）都是這一顆。

const SHADER: Shader = preload("res://src/world/golem_core.gdshader")
const GLOW_COLOR: Color = Color(0.35, 1.0, 0.55)
const RADIUS: float = 0.24
## 扛在諾恩左肩旁邊的位置（他的 Body 的座標）
const CARRY_POS: Vector3 = Vector3(-0.3, 1.6, 0.1)

var ball: MeshInstance3D


static func create() -> GolemCore:
	var core := GolemCore.new()
	core.name = "GolemCore"
	core.ball = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = RADIUS
	sphere.height = RADIUS * 2.0
	sphere.radial_segments = 20
	sphere.rings = 10
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	sphere.material = mat
	core.ball.mesh = sphere
	core.add_child(core.ball)
	var glow := OmniLight3D.new()
	glow.light_color = GLOW_COLOR
	glow.light_energy = 0.5
	glow.omni_range = 2.2
	glow.shadow_enabled = false
	core.add_child(glow)
	return core


## 掛到諾恩的左肩旁邊（who＝他的 Body）。已經在場景裡的話從現在的位置飛過去。
func carry_on(who: Node3D, fly_sec: float = 0.0) -> void:
	var from: Vector3 = global_position if is_inside_tree() else Vector3.ZERO
	var flying: bool = is_inside_tree() and fly_sec > 0.0
	if get_parent() != null:
		get_parent().remove_child(self)
	who.add_child(self)
	rotation = Vector3.ZERO
	if not flying:
		position = CARRY_POS
		return
	global_position = from
	var t: Tween = create_tween()
	t.tween_property(self, "position", CARRY_POS, fly_sec).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
