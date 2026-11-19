class_name SporeTreant
extends EnemyActor
## 孢子樹人（docs/story/chapter-1.md 時段 B，樹人窪地）：慢、耐打，往後一仰再一記很重的下砸。
## 砸到除了傷害還上緩速＋致盲（data/status/statuses.json 的 treant_slam）——對諾恩是跑得更快＋刀刀砍中要害。
## 不會後仰（打不斷）；失衡滿了跪很久，那是砍牠的時候。
## 外型：Tripo 的雙足模型，跟人物走同一條轉檔（scripts/gen_art.sh，Puppet 的 character_id＝spore_treant，2.6 m 高）；
## 模型不在時是放大的程式人偶。動作（tools/blender/common.py 的 monster_actions，D-303）：走路、兩手舉過頭一起砸下去
## （前兆＝舉到頂停著，越撐越亮；剩 0.19 秒砸下去）、失衡滿了單膝跪地。以前借人的重劈＋整棵往後仰。

const CHARACTER_ID: String = "spore_treant"
const SLAM_SOURCE: String = "treant_slam"
## 一步：很重的木頭「咚」＋樹幹的吱嘎＋葉子沙沙；醒來時整棵樹被扭的低沉一聲、倒下時樹幹裂開砸地
const STEP_SFX: String = "treant_step"
const GROAN_SFX: String = "treant_groan"
const FALL_SFX: String = "treant_fall"
const STAND_IN_SCALE: float = 1.5

## 被砍的那一下（flinch 動作）最少隔幾秒才再演一次
const FLINCH_GAP: float = 0.9

var _puppet: Puppet
var _swung: bool = false
var _since_flinch: float = 99.0


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
	_puppet.footfall.connect(func() -> void: Sfx.play_at(self, STEP_SFX, global_position, -6.0))
	add_toxic_glow(_puppet, 3.4)


## 被諾恩砍中：手上沒在出招、沒在跪，演一下往後一抽（不改狀態機——樹人打不斷）
func _on_damaged(amount: float, info: Dictionary) -> void:
	super._on_damaged(amount, info)
	if info.get("source") is PlayerController and not health.is_dead() and _since_flinch >= FLINCH_GAP \
			and _puppet.action in ["", "flinch"] and brain.state in [EnemyBrain.State.CHASE, EnemyBrain.State.RECOVER, EnemyBrain.State.IDLE]:
		_since_flinch = 0.0
		_puppet.play_action("flinch")


## 失衡滿了：單膝跪地，照跪多久整段縮放播
func _on_kneel() -> void:
	super._on_kneel()
	if not health.is_dead():
		_puppet.play_action("kneel", brain.kneel_sec())


func notice_sfx() -> String:
	return GROAN_SFX


func fall_sfx() -> String:
	return FALL_SFX


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


## 走路照速度播；前兆＝兩手舉到頂停著（越撐越亮），剩 0.19 秒砸下去；跪（失衡）＝單膝跪地（_on_kneel）。
func _update_look() -> void:
	if _puppet == null:
		return
	_puppet.set_move_speed(Vector2(velocity.x, velocity.z).length())
	_since_flinch += get_physics_process_delta_time()
	var windup: float = brain.telegraph_progress()
	if brain.state == EnemyBrain.State.TELEGRAPH:
		if not _swung:
			_swung = true
			_puppet.wind_up("hammer", brain.telegraph_sec)
		elif _puppet.is_holding() and brain.telegraph_sec - brain.time_in_state <= Puppet.STRIKE_LEAD:
			_puppet.release_hold()
	elif brain.state != EnemyBrain.State.STRIKE:
		_swung = false
		if _puppet.is_holding():
			_puppet.stop_action()
	if not health.is_dead():
		_set_glow(lerpf(1.0, GLOW_WINDUP, windup))
