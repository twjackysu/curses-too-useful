class_name SporeTreant
extends EnemyActor
## 孢子樹人（docs/story/chapter-1.md 時段 B，樹人窪地）：慢、耐打，往後一仰再一記很重的下砸。
## 砸到除了傷害還上緩速＋致盲（data/status/statuses.json 的 treant_slam）——對諾恩是跑得更快＋刀刀砍中要害。
## 不會後仰（打不斷）；失衡滿了跪很久，那是砍牠的時候。
## 外型：Tripo 的雙足模型，跟人物走同一條轉檔（scripts/gen_art.sh，Puppet 的 character_id＝spore_treant，2.6 m 高）；
## 模型不在時是放大的程式人偶。動作用 Puppet 現成的：走路、出手的第三段（重劈）當下砸。

const CHARACTER_ID: String = "spore_treant"
const SLAM_SOURCE: String = "treant_slam"
## Puppet 的出手動作開始之後這麼久才「砍到」：前兆剩這麼多秒的時候開始揮，砸下去的那一刻才對得上
const SWING_LEAD: float = 0.19
## 前兆往後仰、砸下去往前傾幾弧度
const LEAN_BACK: float = 0.2
const LEAN_SLAM: float = -0.3
const STAND_IN_SCALE: float = 1.5

var _puppet: Puppet
var _swung: bool = false


func tuning_id() -> String:
	return "spore_treant"


func _head_height() -> float:
	return 2.7


func _hit_height() -> float:
	return 1.4


func _hit_radius() -> float:
	return 0.6


func puppet() -> Puppet:
	return _puppet


func _build_body() -> void:
	super._build_body()
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.6
	capsule.height = 2.4
	shape.shape = capsule
	shape.position = Vector3(0, 1.2, 0)
	add_child(shape)
	ContactShadow.attach(self, 1.3, 0.55)
	_puppet = Puppet.new()
	_puppet.name = "Puppet"
	_puppet.character_id = CHARACTER_ID
	_body.add_child(_puppet)
	if not _puppet.uses_model():
		_puppet.scale = Vector3.ONE * STAND_IN_SCALE
	_puppet.footfall.connect(func() -> void: Sfx.play_at(self, "step_heavy", global_position, -9.0))
	add_toxic_glow(_puppet, 3.4)


## 砸下去的那一刻：前方一大片都算。
func _on_strike() -> void:
	var origin: Vector3 = global_position
	var fwd: Vector3 = forward()
	var reach: float = CombatTuning.num("spore_treant.slam_reach", 3.4)
	var arc: float = CombatTuning.num("spore_treant.slam_arc_deg", 140.0)
	Sfx.play_at(self, "blunt_weak", origin + fwd * 1.6 + Vector3.UP * 0.3, -2.0)
	_ground_puff(origin + fwd * 1.8, Vector3(0.8, 0.05, 0.8), 26, Color(0.55, 0.7, 0.45, 0.6))
	var hit: int = hit_heartbeats(CombatTuning.num("spore_treant.slam_damage", 22.0), "slam",
		func(p: Vector3) -> bool: return PlayerController.in_strike_arc(origin, fwd, p, reach, arc))
	if hit > 0 and _player != null and is_instance_valid(_player) and PlayerController.in_strike_arc(origin, fwd, _player.global_position, reach, arc):
		_player.status_effects.apply_source(SLAM_SOURCE)


## 走路照速度播；前兆往後仰（越仰越亮），快砸的時候開始揮；跪（失衡）＝整個人矮下去往前垂。
func _update_look() -> void:
	if _puppet == null:
		return
	_puppet.set_move_speed(Vector2(velocity.x, velocity.z).length())
	var windup: float = brain.telegraph_progress()
	var lean: float = LEAN_BACK * windup
	var drop: float = 0.0
	match brain.state:
		EnemyBrain.State.TELEGRAPH:
			if not _swung and brain.telegraph_sec - brain.time_in_state <= SWING_LEAD:
				_swung = true
				_puppet.attack_variant = 2
				_puppet.play_action("attack")
		EnemyBrain.State.STRIKE, EnemyBrain.State.RECOVER:
			lean = LEAN_SLAM if brain.state == EnemyBrain.State.STRIKE or brain.time_in_state < 0.4 else 0.0
		EnemyBrain.State.STAGGERED:
			lean = -0.5
			drop = -0.55
	if brain.state not in [EnemyBrain.State.TELEGRAPH, EnemyBrain.State.STRIKE]:
		_swung = false
	_puppet.rotation.x = lerp_angle(_puppet.rotation.x, lean, 0.2)
	_puppet.position.y = lerpf(_puppet.position.y, drop, 0.2)
	if not health.is_dead():
		_set_glow(lerpf(1.0, GLOW_WINDUP, windup))
