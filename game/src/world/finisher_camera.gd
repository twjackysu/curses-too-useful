class_name FinisherCamera
extends Camera3D
## 收尾那一刀的鏡頭（粉碎魔像核心）：從玩家的鏡頭直接切到兩人的側面——那一刻諾恩貼在魔像面前，過肩鏡頭裡只看得到一片石頭——
## 停一下，再滑回玩家的鏡頭、把自己收掉。那一刻有打擊停頓與慢動作，所以用真實時間算。
## 對話開始就馬上讓開（TalkCamera 要從玩家的鏡頭接手）。
## 停著的那幾秒是過場（Game.CUTSCENE_GROUP）：玩家不能動——鏡頭不在他背後，動了也看不到自己面前；HUD 由關卡收起來（Hud.cinematic）。
## 切過去的那一下鏡頭自己晃一下（玩家鏡頭的晃動在這個鏡頭上看不到）。

const SHOT_FOV: float = 50.0
const BACK_SEC: float = 0.6
## 鏡位被場景擋住（斷柱）就往兩人拉近；角色不算（呼叫的人給 exclude）
const WORLD_MASK: int = 1 | 2
const WALL_MARGIN: float = 0.3
## 停著的時候慢慢往前推這麼多（比例）
const PUSH_IN: float = 0.08
## 切過去的那一下晃多大（公尺）、晃多久（真實時間）
const SHAKE: float = 0.09
const SHAKE_SEC: float = 0.5

var hold_sec: float = 1.8
## 切過去的那一下晃多大（0＝不晃：戰後等卡的那個鏡頭）
var shake: float = SHAKE
var _home: Camera3D
var _shot: Transform3D
var _aim: Vector3
var _t: float = 0.0
## 換到另一邊了嗎（玩家那一側被斷柱擋住；測試用）
var flipped: bool = false
var _rng := RandomNumberGenerator.new()


## 側面的鏡位。attacker、victim＝兩人腳下的位置，home＝玩家鏡頭的位置（鏡頭留在它那一側，切過去不會左右顛倒）。
## 鏡頭在兩人連線的旁邊 dist 公尺、往出手的人後面退一點（看得到他的背與對方的正面）、離地 height；看著兩人之間 aim_height 高的地方。
## side＝1／−1 指定站在出手的人的右邊／左邊（0＝照玩家的鏡頭在哪一邊）。
static func shot(attacker: Vector3, victim: Vector3, home: Vector3, dist: float, height: float, aim_height: float, side: float = 0.0) -> Transform3D:
	var flat := Vector3(victim.x - attacker.x, 0.0, victim.z - attacker.z)
	var fwd: Vector3 = flat.normalized() if flat.length() > 0.05 else Vector3.FORWARD
	var right: Vector3 = fwd.cross(Vector3.UP)
	var mid: Vector3 = attacker.lerp(victim, 0.5)
	mid.y = attacker.y
	if side == 0.0:
		side = 1.0 if (home - mid).dot(right) >= 0.0 else -1.0
	var eye: Vector3 = mid + right * side * dist - fwd * dist * 0.45 + Vector3.UP * height
	return Transform3D(Basis.looking_at(mid + Vector3.UP * aim_height - eye, Vector3.UP), eye)


## 切過去。seconds＝停多久（真實時間）才開始滑回去。場上沒有鏡頭（測試）就不做，回傳 null。
## 玩家那一側被場景擋住（斷柱）就換到另一側；兩側都擋住才往兩人拉近（拉近到柱子前面，常常只剩一片石頭）。
## home＝停完之後還給哪一個鏡頭（沒給＝現在在用的那一個；對話剛講完時現在在用的是對話的鏡頭，要直接給玩家的）。
static func play(parent: Node3D, attacker: Vector3, victim: Vector3, seconds: float, dist: float, height: float,
		aim_height: float, exclude: Array[RID] = [], home_cam: Camera3D = null) -> FinisherCamera:
	var home: Camera3D = home_cam
	if home == null:
		home = parent.get_viewport().get_camera_3d() if parent.is_inside_tree() else null
	if home == null:
		return null
	var cam := FinisherCamera.new()
	cam.name = "FinisherCamera"
	cam.hold_sec = seconds
	cam._home = home
	var aim: Vector3 = attacker.lerp(victim, 0.5) + Vector3.UP * aim_height
	var space: PhysicsDirectSpaceState3D = parent.get_world_3d().direct_space_state
	var first: Transform3D = shot(attacker, victim, home.global_position, dist, height, aim_height)
	var first_hit: Dictionary = _blocked(space, aim, first.origin, exclude)
	cam._shot = first
	if not first_hit.is_empty():
		var mid: Vector3 = attacker.lerp(victim, 0.5)
		var fwd: Vector3 = Vector3(victim.x - attacker.x, 0.0, victim.z - attacker.z).normalized()
		var was_right: bool = (first.origin - mid).dot(fwd.cross(Vector3.UP)) >= 0.0
		var other: Transform3D = shot(attacker, victim, home.global_position, dist, height, aim_height, -1.0 if was_right else 1.0)
		if _blocked(space, aim, other.origin, exclude).is_empty():
			cam._shot = other
			cam.flipped = true
		else:
			var at: Vector3 = first_hit["position"] as Vector3
			var eye: Vector3 = at + (aim - at).normalized() * WALL_MARGIN
			cam._shot = Transform3D(Basis.looking_at(aim - eye, Vector3.UP), eye)
	cam._aim = cam._shot.origin - cam._shot.basis.z * cam._shot.origin.distance_to(aim)
	parent.add_child(cam)
	cam.global_transform = cam._shot
	cam.fov = SHOT_FOV
	cam.current = true
	cam.add_to_group(Game.CUTSCENE_GROUP)
	return cam


static func _blocked(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3, exclude: Array[RID]) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, WORLD_MASK)
	query.exclude = exclude
	return space.intersect_ray(query)


func is_holding() -> bool:
	return _t <= hold_sec


func _process(delta: float) -> void:
	_t += delta / maxf(Engine.time_scale, 0.01)
	if not is_instance_valid(_home) or Game.is_in_dialogue():
		_finish()
		return
	var pushed: Transform3D = _shot
	pushed.origin = _shot.origin.lerp(_aim, PUSH_IN * clampf(_t / maxf(hold_sec, 0.01), 0.0, 1.0))
	if _t <= hold_sec:
		global_transform = pushed
		# 停著的時候畫面一直是這個鏡頭（對話的鏡頭剛講完、把畫面還給玩家的鏡頭的那一下，再拿回來）
		if not current:
			current = true
		var a: float = shake * pow(1.0 - clampf(_t / SHAKE_SEC, 0.0, 1.0), 2.0)
		h_offset = _rng.randf_range(-1.0, 1.0) * a
		v_offset = _rng.randf_range(-1.0, 1.0) * a
		return
	h_offset = 0.0
	v_offset = 0.0
	if is_in_group(Game.CUTSCENE_GROUP):
		remove_from_group(Game.CUTSCENE_GROUP)
	var k: float = smoothstep(0.0, 1.0, (_t - hold_sec) / BACK_SEC)
	global_transform = pushed.interpolate_with(_home.global_transform, k)
	fov = lerpf(SHOT_FOV, _home.fov, k)
	if k >= 1.0:
		_finish()


func _finish() -> void:
	if is_instance_valid(_home):
		_home.current = true
	set_process(false)
	queue_free()
