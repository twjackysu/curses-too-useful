class_name GlintWolf
extends Node3D
## 「會走的金光」（docs/story/chapter-1-expanded.md，阿展說的那一個）：齒間卡著一截發光金屬的瘴氣狼。不打人——
## 諾恩走近（NOTICE 公尺內）牠就沿著路線小跑；離太遠（WAIT 公尺外）停下來回頭等；經過野果灌木（sniff_at 的那幾個點）
## 停下來聞幾秒，讓人跟得上；走到最後一點（詛咒寶箱前面）把金屬吐在地上、鑽進霧裡不見。
## 路上被砍到一下：哀叫、金屬掉在原地、跑掉。金屬要怎麼處理由關卡接 dropped（ForestExplore）。
## 外型跟 MiasmaWolf 同一個模型（走路那一段照速度播），嘴邊多一點金光；模型不在就是一個長方的替身。

signal dropped(at: Vector3)

const SPEED: float = 3.4
const NOTICE: float = 11.0
const WAIT: float = 15.0
const SNIFF_SEC: float = 3.0
## 吐下金屬之後跑掉、縮小不見要多久
const FLEE_SEC: float = 0.9
const FLEE_SPEED: float = 9.0
const TURN_SPEED: float = 8.0
const ARRIVE: float = 0.35
const GLINT_COLOR: Color = Color(1.0, 0.8, 0.3)

## 路線（地面上的點；第一個是牠一開始待的地方）與在哪幾個點停下來聞
var route: Array[Vector3] = []
var sniff_at: PackedInt32Array = []
var target: Node3D
## 下一個要去的點
var leg: int = 1
var started: bool = false
var gone: bool = false
var health: Health
var _sniff_left: float = 0.0
var _flee_left: float = 0.0
var _anim: AnimationPlayer


static func create(p_route: Array[Vector3], p_sniff_at: PackedInt32Array, p_target: Node3D) -> GlintWolf:
	var w := GlintWolf.new()
	w.name = "GlintWolf"
	w.route = p_route
	w.sniff_at = p_sniff_at
	w.target = p_target
	w.position = p_route[0]
	return w


func _ready() -> void:
	var look: Node3D = PropModels.instance(MiasmaWolf.MODEL)
	if look == null:
		look = _stand_in()
	look.name = "Look"
	add_child(look)
	var players: Array[Node] = look.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		_anim = players[0] as AnimationPlayer
		if _anim.has_animation(MiasmaWolf.WALK_ANIM):
			_anim.get_animation(MiasmaWolf.WALK_ANIM).loop_mode = Animation.LOOP_LINEAR
			_anim.play(MiasmaWolf.WALK_ANIM)
			_anim.speed_scale = 0.0
	ContactShadow.attach(self, 1.0, 0.5)
	var glint := OmniLight3D.new()
	glint.name = "Glint"
	glint.light_color = GLINT_COLOR
	glint.light_energy = 3.0
	glint.omni_range = 5.5
	glint.shadow_enabled = false
	glint.light_volumetric_fog_energy = 4.0
	glint.position = Vector3(0, 0.75, -0.8)
	add_child(glint)
	glint.add_child(metal_mesh(0.08))
	health = Health.new(1.0)
	health.name = "Health"
	add_child(health)
	health.damaged.connect(func(_amount: float, _info: Dictionary) -> void: _drop(true))
	add_to_group("damageable")
	if route.size() > 1:
		_face(route[1] - route[0], 1.0)


## 那一截發光的金屬（狼嘴邊的、掉在地上的都用它）
static func metal_mesh(size: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "Metal"
	var box := BoxMesh.new()
	box.size = Vector3(size * 3.2, size, size)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = GLINT_COLOR
	mat.emission_enabled = true
	mat.emission = GLINT_COLOR
	mat.emission_energy_multiplier = 3.0
	box.material = mat
	mi.mesh = box
	mi.rotation = Vector3(0.2, 0.5, 0.3)
	return mi


func is_sniffing() -> bool:
	return _sniff_left > 0.0


func _physics_process(delta: float) -> void:
	if gone:
		_flee_left -= delta
		global_position += -global_basis.z * FLEE_SPEED * delta
		scale = Vector3.ONE * clampf(_flee_left / FLEE_SEC, 0.02, 1.0)
		_trot(FLEE_SPEED)
		if _flee_left <= 0.0:
			queue_free()
		return
	if target == null or not is_instance_valid(target) or leg >= route.size():
		_trot(0.0)
		return
	var to_player: Vector3 = target.global_position - global_position
	to_player.y = 0.0
	var dist: float = to_player.length()
	if not started:
		started = dist < NOTICE
		_trot(0.0)
		return
	if _sniff_left > 0.0:
		_sniff_left -= delta
		_trot(0.0)
		return
	if dist > WAIT:
		# 跟丟了：停下來回頭等
		_face(to_player, delta * TURN_SPEED)
		_trot(0.0)
		return
	var step: Vector3 = route[leg] - global_position
	step.y = 0.0
	if step.length() <= ARRIVE:
		if sniff_at.has(leg):
			_sniff_left = SNIFF_SEC
		leg += 1
		if leg >= route.size():
			_drop(false)
		return
	_face(step, delta * TURN_SPEED)
	global_position += step.normalized() * minf(SPEED * delta, step.length())
	_trot(SPEED)


func _face(dir: Vector3, k: float) -> void:
	if Vector2(dir.x, dir.z).length() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), minf(k, 1.0))


func _trot(speed: float) -> void:
	if _anim != null:
		_anim.speed_scale = speed / MiasmaWolf.WALK_CLIP_SPEED


## 金屬掉下來（走到終點吐掉，或被砍到）；牠往前衝、縮小不見
func _drop(hit: bool) -> void:
	if gone:
		return
	gone = true
	_flee_left = FLEE_SEC
	remove_from_group("damageable")
	(get_node("Glint") as OmniLight3D).visible = false
	if hit:
		Sfx.play_at(get_parent(), MiasmaWolf.YELP_SFX, global_position + Vector3.UP * 0.6, -4.0)
	dropped.emit(Vector3(global_position.x, 0.0, global_position.z))


static func _stand_in() -> Node3D:
	var root := Node3D.new()
	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.45, 0.5, 1.3)
	var fur := StandardMaterial3D.new()
	fur.albedo_color = Color(0.2, 0.22, 0.5)
	box.material = fur
	body.mesh = box
	body.position = Vector3(0, 0.55, 0)
	root.add_child(body)
	return root
