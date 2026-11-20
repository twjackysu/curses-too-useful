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
## 扛著走路：每一步踩下去肩上的核心往下頓多少（m）、多久彈回來（秒）——重
const STEP_DIP: float = 0.035
const STEP_DIP_SEC: float = 0.26

var ball: MeshInstance3D
## 扛著時在骨頭座標裡的位置（頓一下是從這裡往下）；沒有在扛＝INF
var _rest: Vector3 = Vector3.INF
## 現在往下頓了多少（m；測試看這個）
var dip: float = 0.0
var _dip_t: float = 1.0


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
		if not puppet.footfall.is_connected(_on_step):
			puppet.footfall.connect(_on_step)
	if get_parent() != null:
		get_parent().remove_child(self)
	parent.add_child(self)
	rotation = Vector3.ZERO
	_rest = Vector3.INF
	if not flying:
		position = to
		scale = Vector3.ONE * CARRY_SCALE
		_rest = to
		return
	global_position = from
	var t: Tween = create_tween().set_parallel()
	t.tween_property(self, "position", to, fly_sec).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "scale", Vector3.ONE * CARRY_SCALE, fly_sec)
	t.chain().tween_callback(func() -> void: _rest = to)


## 從肩上放下來、「咚」一聲擱在地上的 at（腳下的位置；球的底貼地）。parent＝掛到哪（關卡）；puppet＝扛著他的人的外型（換回平常的動作）。
## 結尾回到公會：一走到大家面前就把核心放到地上（D-309）——之後的對話鏡頭裡核心在地上發光，不會蓋住他的頭與畫面的一邊
func set_down(parent: Node, at: Vector3, fly_sec: float = 0.45, puppet: Puppet = null) -> void:
	if puppet != null:
		puppet.carry = false
		if puppet.footfall.is_connected(_on_step):
			puppet.footfall.disconnect(_on_step)
	_rest = Vector3.INF
	dip = 0.0
	var from: Vector3 = global_position if is_inside_tree() else at
	if get_parent() != null:
		get_parent().remove_child(self)
	parent.add_child(self)
	rotation = Vector3.ZERO
	scale = Vector3.ONE * CARRY_SCALE
	var floor_at: Vector3 = at + Vector3.UP * RADIUS * CARRY_SCALE
	if fly_sec <= 0.0 or not is_inside_tree():
		global_position = floor_at
		return
	global_position = from
	var t: Tween = create_tween()
	t.tween_property(self, "global_position", floor_at, fly_sec).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	t.parallel().tween_callback(func() -> void:
		Sfx.play_at(parent, LAND_SFX, floor_at, LAND_DB, 0.05, 10.0)).set_delay(fly_sec * 0.36)


## 放到地上的聲音：跟魔像倒下時核心滾出來落地同一聲（小一點）
const LAND_SFX: String = "core_land"
const LAND_DB: float = -6.0


## 扛著的人一腳踩下去：肩上的核心往下頓一下再彈回來
func _on_step() -> void:
	if _rest.is_finite():
		_dip_t = 0.0


func _process(delta: float) -> void:
	if not _rest.is_finite():
		return
	_dip_t = minf(_dip_t + delta / STEP_DIP_SEC, 1.0)
	# 很快壓下去（前 25%）、慢慢彈回來
	dip = STEP_DIP * (smoothstep(0.0, 0.25, _dip_t) if _dip_t < 0.25 else 1.0 - smoothstep(0.25, 1.0, _dip_t))
	position = _rest
	global_position += Vector3.DOWN * dip


## 扛在 who（他的 Body）身上嗎（直接掛在 Body 上或掛在他的骨頭上）
func is_carried_by(who: Node3D) -> bool:
	return who != null and who.is_ancestor_of(self)
