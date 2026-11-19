class_name MoldSlime
extends Slime
## 黴菌史萊姆（docs/story/chapter-1.md 時段 B）：灰綠色、長滿黴菌的史萊姆，比劇毒史萊姆慢、耐打。
## 撞到人上一層衰弱（data/status/statuses.json 的 mold_touch）——對諾恩是砍得更重。
## 跟劇毒史萊姆分得開（D-303）：平常慢慢一脹一縮地蠕動、爬過的地方冒出一小團孢子；要撲之前不是壓扁、是吸飽氣整顆脹起來；
## 被砍噴一小團孢子，倒下整顆炸成一大團灰綠的孢子雲（不是「啪嘰」一攤）。

const SPORE_COLOR: Color = Color(0.62, 0.72, 0.5, 0.6)
## 平常蠕動：一秒脹縮幾下、脹多少
const CREEP_HZ: float = 0.7
const CREEP_AMP: float = 0.08
## 蓄力蓄滿脹到幾倍
const INFLATE: float = 1.35
## 爬的時候每隔幾秒冒一團孢子
const TRAIL_SEC: float = 0.9

## 冒過幾團孢子（爬、被砍、倒下；測試用）
var spore_puffs: int = 0
var _creep_t: float = 0.0
var _trail_t: float = 0.0


func tuning_id() -> String:
	return "mold_slime"


func model_name() -> String:
	return "tripo/enemy_mold_slime"


func touch_source() -> String:
	return "mold_touch"


func _shape() -> Vector3:
	var dt: float = get_physics_process_delta_time()
	_creep_t += dt
	var creep: float = 1.0 + CREEP_AMP * sin(_creep_t * TAU * CREEP_HZ)
	var swell: float = lerpf(1.0, INFLATE, brain.telegraph_progress())
	match brain.state:
		EnemyBrain.State.STRIKE:
			# 撲出去：往前拉長、扁一點
			return Vector3(0.9, 0.85, 1.3)
		EnemyBrain.State.STAGGERED:
			return Vector3(1.4, 0.45, 1.4)
		EnemyBrain.State.TELEGRAPH:
			return Vector3.ONE * swell
	return Vector3(1.0 / sqrt(creep), creep, 1.0 / sqrt(creep))


func _after_move() -> void:
	if not brain.is_moving() or Vector2(velocity.x, velocity.z).length() < 0.2:
		return
	_trail_t += get_physics_process_delta_time()
	if _trail_t >= TRAIL_SEC:
		_trail_t = 0.0
		spore_puff(global_position + Vector3.UP * 0.15, 0.3, 6)


func _on_damaged(amount: float, info: Dictionary) -> void:
	super._on_damaged(amount, info)
	spore_puff(global_position + Vector3.UP * BODY_RADIUS, 0.25, 10)


func _on_fall_impact() -> void:
	super._on_fall_impact()
	var cloud: CPUParticles3D = spore_puff(global_position + Vector3.UP * 0.4, 0.6, 46)
	if cloud != null:
		cloud.lifetime = 2.0
		cloud.initial_velocity_max = 2.2
		cloud.scale_amount_max = 2.8


## 一團孢子：灰綠色、慢慢往上飄、散開。掛在關卡上（史萊姆沉下去、被釋放之後還要飄完），噴完自己收掉。
func spore_puff(at: Vector3, spread: float, amount: int) -> CPUParticles3D:
	if not is_inside_tree():
		return null
	var ps: CPUParticles3D = puff_build(Vector3(spread, spread * 0.5, spread), amount, SPORE_COLOR)
	ps.name = "SporePuff"
	ps.gravity = Vector3(0, 0.35, 0)
	ps.initial_velocity_min = 0.3
	ps.initial_velocity_max = 1.1
	ps.lifetime = 1.4
	var parent: Node = get_parent() if get_parent() != null else self
	parent.add_child(ps, true)
	ps.global_position = at
	ps.emitting = true
	ps.finished.connect(ps.queue_free)
	spore_puffs += 1
	return ps
