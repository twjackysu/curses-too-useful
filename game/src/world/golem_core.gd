class_name GolemCore
extends Node3D
## 魔像核心（拿得走的那一顆）：暗色的石球，裂縫透出病綠色的光，旁邊一盞小燈。
## 魔像倒下時從胸口滾出來（PlagueGolem）、戰後飛到諾恩的左肩上（RuinedAltar）、結尾扛回公會（GuildHall）都是這一顆。

const SHADER: Shader = preload("res://src/world/golem_core.gdshader")
const GLOW_COLOR: Color = Color(0.35, 1.0, 0.55)
const RADIUS: float = 0.24
## 程式人偶（沒有模型）時掛在他的 Body 的這個位置：左肩旁邊
const CARRY_POS: Vector3 = Vector3(-0.3, 1.6, 0.1)
## 有模型時：扛在左肩上——離左肩的骨頭往上、往後、往裡多少（他的身體座標，公尺）。
## 扛東西的動作（Puppet.carry）左手腕在肩膀上面約 19 cm、往前 6 cm，剛好扶在球的前面
const SHOULDER_OFFSET: Vector3 = Vector3(0.02, 0.2, 0.08)
## 扛著的時候縮小一點（在地上滾的時候跟魔像比是剛好的，扛在人的肩上偏大）
const CARRY_SCALE: float = 0.72

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


## 扛到諾恩的左肩上。who＝他的 Body；puppet＝他的外型：有模型就掛在胸口的骨頭上、他換成扛東西的動作（左手扶著），
## 沒有（程式人偶、測試）就掛在 Body 的 CARRY_POS。已經在場景裡的話從現在的位置飛過去。
func carry_on(who: Node3D, fly_sec: float = 0.0, puppet: Puppet = null) -> void:
	var from: Vector3 = global_position if is_inside_tree() else Vector3.ZERO
	var flying: bool = is_inside_tree() and fly_sec > 0.0
	var parent: Node3D = who
	var to: Vector3 = CARRY_POS
	var chest: Node3D = puppet.joint("chest") if puppet != null and puppet.uses_model() else null
	var shoulder: Node3D = puppet.joint("shoulder_L") if chest != null else null
	if shoulder != null:
		var b: Basis = who.global_basis.orthonormalized()
		var at: Vector3 = puppet.joint_now("shoulder_L").origin + b * SHOULDER_OFFSET
		parent = chest
		to = puppet.joint_now("chest").affine_inverse() * at
		puppet.carry = true
	if get_parent() != null:
		get_parent().remove_child(self)
	parent.add_child(self)
	rotation = Vector3.ZERO
	if not flying:
		position = to
		scale = Vector3.ONE * CARRY_SCALE
		return
	global_position = from
	var t: Tween = create_tween().set_parallel()
	t.tween_property(self, "position", to, fly_sec).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "scale", Vector3.ONE * CARRY_SCALE, fly_sec)


## 扛在 who（他的 Body）身上嗎（直接掛在 Body 上或掛在他的骨頭上）
func is_carried_by(who: Node3D) -> bool:
	return who != null and who.is_ancestor_of(self)
