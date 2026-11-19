class_name MiasmaWolf
extends EnemyActor
## 瘴氣狼（docs/story/chapter-1.md 時段 B）：跑得快，到面前壓低身體、撲上來咬一口。
## 咬到除了傷害還上一層流血（data/status/statuses.json 的 wolf_bite）——對諾恩是出手加速。
## 外型：Tripo 的四足模型（scripts/gen_props.sh 用 tools/blender/tripo_quadruped.py 轉好，帶骨架與一段原地走路 walk）；
## 跑的時候把走路播快；蹲低要撲、騰空、被砍、失衡趴下、倒地的腿與脖子是 WolfPose 疊上去的（D-303），整隻壓低、騰起來、
## 側躺還是程式擺整個身體。檔案不在就用程式拼的替身（只有整個身體會動）。

const MODEL: String = "tripo/enemy_miasma_wolf"
const BITE_SOURCE: String = "wolf_bite"
## 撲出去咬：短短的低吼＋牙齒合起來的「喀」；發現諾恩時低吼、倒下時哀叫
const BITE_SFX: String = "wolf_bite"
const GROWL_SFX: String = "wolf_growl"
const YELP_SFX: String = "wolf_yelp"
const BODY_RADIUS: float = 0.45
## 走路那一段原地踏步，播一倍速大約等於每秒走這麼遠（公尺）：跑的時候照速度播快
const WALK_CLIP_SPEED: float = 1.5
const WALK_ANIM: String = "walk"

## 姿勢的權重往目標跟上去多快（每秒）
const POSE_EASE: float = 14.0
## 倒地：腿軟掉要多久
const DEAD_POSE_SEC: float = 0.3

var _lunge_dir: Vector3 = Vector3.ZERO
var _look: Node3D
var _anim: AnimationPlayer
var _pose: WolfPose


func tuning_id() -> String:
	return "miasma_wolf"


func _head_height() -> float:
	return 1.15


func _hit_height() -> float:
	return 0.55


func _hit_radius() -> float:
	return 0.5


func _build_body() -> void:
	super._build_body()
	var shape := CollisionShape3D.new()
	var ball := SphereShape3D.new()
	ball.radius = BODY_RADIUS
	shape.shape = ball
	shape.position = Vector3(0, BODY_RADIUS, 0)
	add_child(shape)
	ContactShadow.attach(self, 1.0, 0.5)
	_look = PropModels.instance(MODEL)
	if _look == null:
		_look = _stand_in()
	_look.name = "Look"
	_body.add_child(_look)
	var players: Array[Node] = _look.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		_anim = players[0] as AnimationPlayer
		if _anim.has_animation(WALK_ANIM):
			_anim.get_animation(WALK_ANIM).loop_mode = Animation.LOOP_LINEAR
			_anim.play(WALK_ANIM)
			_anim.speed_scale = 0.0
	var skels: Array[Node] = _look.find_children("*", "Skeleton3D", true, false)
	if not skels.is_empty():
		_pose = WolfPose.new()
		_pose.name = "WolfPose"
		var sk: Skeleton3D = skels[0] as Skeleton3D
		sk.add_child(_pose)
		_pose.setup(sk)
	add_toxic_glow(_look, 2.6)


## 腿與脖子的姿勢（沒有模型時是 null）
func pose() -> WolfPose:
	return _pose


## 有沒有在播走路的動作（測試用；沒有模型時是 false）
func is_trotting() -> bool:
	return _anim != null and _anim.is_playing() and _anim.speed_scale > 0.0


func notice_sfx() -> String:
	return GROWL_SFX


func fall_sfx() -> String:
	return YELP_SFX


## 撲出去的那一刻：記下往哪撲、判定前方的人；咬到就流血。
func _on_strike() -> void:
	_lunge_dir = forward()
	Sfx.play_at(self, BITE_SFX, global_position + Vector3.UP * 0.6, -4.0)
	var origin: Vector3 = global_position
	var fwd: Vector3 = _lunge_dir
	var reach: float = brain.attack_range + 0.6
	var hit: int = hit_heartbeats(CombatTuning.num("miasma_wolf.bite_damage", 12.0), "bite",
		func(p: Vector3) -> bool: return PlayerController.in_strike_arc(origin, fwd, p, reach, 100.0))
	if hit > 0 and _player != null and is_instance_valid(_player) and PlayerController.in_strike_arc(origin, fwd, _player.global_position, reach, 100.0):
		_player.status_effects.apply_source(BITE_SOURCE)


func _on_strike_tick(_delta: float) -> Vector3:
	return _lunge_dir * CombatTuning.num("miasma_wolf.lunge_speed", 9.0)


## 跑＝走路播快；前兆＝前半身壓低；撲＝整隻騰起來；跪（失衡）＝趴在地上。
func _update_look() -> void:
	if _look == null:
		return
	var speed: float = Vector2(velocity.x, velocity.z).length()
	if _anim != null:
		_anim.speed_scale = speed / WALK_CLIP_SPEED if brain.is_moving() and speed > 0.2 else 0.0
	var crouch: float = brain.telegraph_progress()
	# 繞 X 軸轉正的角度是前半身抬起來（模型面向 −Z）
	var pitch: float = -0.25 * crouch
	var lift: float = -0.1 * crouch
	if brain.state == EnemyBrain.State.STRIKE:
		pitch = 0.3
		lift = 0.3
	elif brain.state == EnemyBrain.State.STAGGERED:
		pitch = 0.0
		lift = -0.3
	_look.rotation.x = lerp_angle(_look.rotation.x, pitch, 0.3)
	_look.position.y = lerpf(_look.position.y, lift, 0.3)
	if not health.is_dead():
		_set_glow(lerpf(1.0, GLOW_WINDUP, crouch))
	if _pose != null:
		var want: Dictionary = {"crouch": crouch, "leap": 0.0, "hurt": 0.0, "lie": 0.0}
		match brain.state:
			EnemyBrain.State.STRIKE:
				want["leap"] = 1.0
			EnemyBrain.State.RECOVER:
				# 落地之後腿慢慢收回來
				want["leap"] = clampf(1.0 - brain.time_in_state / 0.25, 0.0, 1.0)
			EnemyBrain.State.FLINCH:
				want["hurt"] = sin(clampf(brain.time_in_state / maxf(brain.flinch_sec, 0.01), 0.0, 1.0) * PI)
			EnemyBrain.State.STAGGERED:
				want["lie"] = 1.0
		var k: float = clampf(POSE_EASE * get_physics_process_delta_time(), 0.0, 1.0)
		for key: String in want:
			_pose.weights[key] = lerpf(float(_pose.weights.get(key, 0.0)), float(want[key]), k)


## 倒下：往旁邊一歪、側躺（共用的「向前撲倒」是給站著的人的，四隻腳的會變成倒栽蔥）
func _on_died() -> void:
	_begin_death()
	if _anim != null:
		_anim.speed_scale = 0.0
	if _pose != null:
		# 腿軟掉、頭垂下去（_update_look 不跑了，這裡自己轉過去）
		var from: Dictionary = _pose.weights.duplicate()
		create_tween().tween_method(func(k: float) -> void:
			for key: String in from:
				_pose.weights[key] = float(from[key]) * (1.0 - k)
			_pose.weights["dead"] = k, 0.0, 1.0, DEAD_POSE_SEC)
	var t := create_tween()
	_fall_tween = t
	t.tween_property(_body, "rotation:z", deg_to_rad(86.0), DIE_DROP_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(_body, "position:y", 0.22, DIE_DROP_SEC)
	t.tween_callback(_on_fall_impact)
	t.tween_interval(DIE_LIE_SEC)
	t.tween_property(_body, "position:y", -1.2, DIE_SINK_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_callback(queue_free)


static func _stand_in() -> Node3D:
	var root := Node3D.new()
	var fur := StandardMaterial3D.new()
	fur.albedo_color = Color(0.2, 0.18, 0.45)
	for part: Array in [[Vector3(0.45, 0.5, 1.2), Vector3(0, 0.6, 0.1)], [Vector3(0.36, 0.36, 0.45), Vector3(0, 0.8, -0.65)], [Vector3(0.12, 0.12, 0.5), Vector3(0, 0.7, 0.9)]]:
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = part[0] as Vector3
		box.material = fur
		mesh.mesh = box
		mesh.position = part[1] as Vector3
		root.add_child(mesh)
	return root
