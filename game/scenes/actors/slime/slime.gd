class_name Slime
extends EnemyActor
## 劇毒史萊姆（第一章教學戰，docs/story/chapter-1.md 節點 2）：慢慢靠近、蓄力壓扁、往前撲撞。
## 撞到人除了傷害還上中毒（data/status/statuses.json 的 slime_touch）——對諾恩來說那是回血。
## 外型：Tripo 的模型（建置時 scripts/gen_props.sh 擺正成 0.8 m 高）；檔案不在就用一顆半透明的球。
## 牠是紫的、森林的霧也是紫的，所以身上有「毒的螢光綠」（EnemyActor.add_toxic_glow）；蓄力要撲的時候變亮。

## 撲過來的濕濕一聲、被砍爛的「啪嘰」（黴菌史萊姆也一樣）
const HOP_SFX: String = "slime_hop"
const SPLAT_SFX: String = "slime_splat"
const BODY_RADIUS: float = 0.45
const LUNGE_SPEED: float = 5.0

## 被砍的那一下：多久彈回來、最多壓扁幾成
const SQUISH_SEC: float = 0.28
const SQUISH: float = 0.35

var _lunge_dir: Vector3 = Vector3.ZERO
var _look: Node3D
var _squish: float = 0.0


func tuning_id() -> String:
	return "poison_slime"


## 哪個模型、撞到人上什麼狀態（statuses.json 的來源）：別種史萊姆（MoldSlime）覆寫這兩個與 tuning_id()
func model_name() -> String:
	return "tripo/enemy_poison_slime"


func touch_source() -> String:
	return "slime_touch"


func _head_height() -> float:
	return 1.0


## 命中點在身體中間（預設是人的胸口 1.05 m，比史萊姆整隻還高：閃光與刀痕會飄在牠頭上）
func _hit_height() -> float:
	return BODY_RADIUS


func _hit_radius() -> float:
	return BODY_RADIUS


func _build_body() -> void:
	super._build_body()
	var shape := CollisionShape3D.new()
	var ball := SphereShape3D.new()
	ball.radius = BODY_RADIUS
	shape.shape = ball
	shape.position = Vector3(0, BODY_RADIUS, 0)
	add_child(shape)
	ContactShadow.attach(self, 0.7, 0.5)
	_look = PropModels.instance(model_name())
	if _look == null:
		var mesh := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = BODY_RADIUS
		sphere.height = BODY_RADIUS * 1.6
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.55, 0.3, 0.85, 0.85)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = Color(0.3, 0.9, 0.2)
		mat.emission_energy_multiplier = 0.3
		sphere.material = mat
		mesh.mesh = sphere
		mesh.position = Vector3(0, BODY_RADIUS * 0.8, 0)
		_look = mesh
	_look.name = "Look"
	_body.add_child(_look)
	add_toxic_glow(_look)


func _on_damaged(amount: float, info: Dictionary) -> void:
	super._on_damaged(amount, info)
	_squish = 1.0


func fall_sfx() -> String:
	return SPLAT_SFX


## 出招的那一刻：記下往哪撲、判定前方的人。
func _on_strike() -> void:
	_lunge_dir = forward()
	Sfx.play_at(self, HOP_SFX, global_position + Vector3.UP * 0.4, -7.0, 0.1)
	var origin: Vector3 = global_position
	var fwd: Vector3 = _lunge_dir
	var reach: float = brain.attack_range + 0.5
	var hit: int = hit_heartbeats(CombatTuning.num(tuning_id() + ".bump_damage", 10.0), "bump",
		func(p: Vector3) -> bool: return PlayerController.in_strike_arc(origin, fwd, p, reach, 120.0))
	if hit > 0 and _player != null and is_instance_valid(_player) and PlayerController.in_strike_arc(origin, fwd, _player.global_position, reach, 120.0):
		_player.status_effects.apply_source(touch_source())


func _on_strike_tick(_delta: float) -> Vector3:
	return _lunge_dir * LUNGE_SPEED


## 蓄力時壓扁、出招時拉長；跪著（失衡）時攤平。
func _update_look() -> void:
	if _look == null:
		return
	var shape: Vector3 = _shape()
	# 被砍的那一下疊在上面（不經過慢慢跟上的 lerp）：往下一壓、往兩邊鼓，再彈回來
	_squish = move_toward(_squish, 0.0, get_physics_process_delta_time() / SQUISH_SEC)
	if _squish > 0.0:
		var k: float = sin((1.0 - _squish) * PI) * SQUISH
		shape = Vector3(shape.x * (1.0 + k * 0.5), shape.y * (1.0 - k), shape.z * (1.0 + k * 0.5))
		_look.scale = shape
		return
	_look.scale = _look.scale.lerp(shape, 0.25)
	if not health.is_dead():
		_set_glow(lerpf(1.0, GLOW_WINDUP, brain.telegraph_progress()))


## 這一刻要變成什麼形狀（外型的縮放）：劇毒史萊姆蓄力壓扁、撲出去拉長、跪著攤平。
## 別種覆寫（MoldSlime 是吸飽氣脹起來）
func _shape() -> Vector3:
	var squash: float = 1.0 - 0.35 * brain.telegraph_progress()
	if brain.state == EnemyBrain.State.STRIKE:
		squash = 1.2
	elif brain.state == EnemyBrain.State.STAGGERED:
		squash = 0.5
	var wide: float = 1.0 / sqrt(maxf(squash, 0.1))
	return Vector3(wide, squash, wide)
