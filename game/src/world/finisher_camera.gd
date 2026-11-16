class_name FinisherCamera
extends Camera3D
## 收尾那一刀的鏡頭（粉碎魔像核心）：從玩家的鏡頭直接切到兩人的側面——那一刻諾恩貼在魔像面前，過肩鏡頭裡只看得到一片石頭——
## 停一下，再滑回玩家的鏡頭、把自己收掉。那一刻有打擊停頓與慢動作，所以用真實時間算。
## 對話開始就馬上讓開（TalkCamera 要從玩家的鏡頭接手）。

const SHOT_FOV: float = 50.0
const BACK_SEC: float = 0.6
## 鏡位被場景擋住（斷柱）就往兩人拉近；角色不算（呼叫的人給 exclude）
const WORLD_MASK: int = 1 | 2
const WALL_MARGIN: float = 0.3
## 停著的時候慢慢往前推這麼多（比例）
const PUSH_IN: float = 0.08

var hold_sec: float = 1.8
var _home: Camera3D
var _shot: Transform3D
var _aim: Vector3
var _t: float = 0.0


## 側面的鏡位。attacker、victim＝兩人腳下的位置，home＝玩家鏡頭的位置（鏡頭留在它那一側，切過去不會左右顛倒）。
## 鏡頭在兩人連線的旁邊 dist 公尺、往出手的人後面退一點（看得到他的背與對方的正面）、離地 height；看著兩人之間 aim_height 高的地方。
static func shot(attacker: Vector3, victim: Vector3, home: Vector3, dist: float, height: float, aim_height: float) -> Transform3D:
	var flat := Vector3(victim.x - attacker.x, 0.0, victim.z - attacker.z)
	var fwd: Vector3 = flat.normalized() if flat.length() > 0.05 else Vector3.FORWARD
	var right: Vector3 = fwd.cross(Vector3.UP)
	var mid: Vector3 = attacker.lerp(victim, 0.5)
	mid.y = attacker.y
	var side: float = 1.0 if (home - mid).dot(right) >= 0.0 else -1.0
	var eye: Vector3 = mid + right * side * dist - fwd * dist * 0.45 + Vector3.UP * height
	return Transform3D(Basis.looking_at(mid + Vector3.UP * aim_height - eye, Vector3.UP), eye)


## 切過去。seconds＝停多久（真實時間）才開始滑回去。場上沒有鏡頭（測試）就不做，回傳 null。
static func play(parent: Node3D, attacker: Vector3, victim: Vector3, seconds: float, dist: float, height: float,
		aim_height: float, exclude: Array[RID] = []) -> FinisherCamera:
	var home: Camera3D = parent.get_viewport().get_camera_3d() if parent.is_inside_tree() else null
	if home == null:
		return null
	var cam := FinisherCamera.new()
	cam.name = "FinisherCamera"
	cam.hold_sec = seconds
	cam._home = home
	cam._shot = shot(attacker, victim, home.global_position, dist, height, aim_height)
	cam._aim = cam._shot.origin - cam._shot.basis.z * cam._shot.origin.distance_to(attacker.lerp(victim, 0.5) + Vector3.UP * aim_height)
	parent.add_child(cam)
	var query := PhysicsRayQueryParameters3D.create(cam._aim, cam._shot.origin, WORLD_MASK)
	query.exclude = exclude
	var hit: Dictionary = parent.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var at: Vector3 = hit["position"] as Vector3
		var eye: Vector3 = at + (cam._aim - at).normalized() * WALL_MARGIN
		cam._shot = Transform3D(Basis.looking_at(cam._aim - eye, Vector3.UP), eye)
	cam.global_transform = cam._shot
	cam.fov = SHOT_FOV
	cam.current = true
	return cam


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
		return
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
