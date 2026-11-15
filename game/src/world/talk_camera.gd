class_name TalkCamera
extends Camera3D
## 對話時的鏡頭：看著正在講話的人的臉（上半身的近景），換人講就切到另一邊；講完滑回玩家的鏡頭。
## 兩邊的鏡位都留在玩家鏡頭的那一側（不跨過兩人之間的那條線），切過去不會左右顛倒。
## 誰是誰由關卡登記：`cast[說話者的 key] = 那個角色`；沒登記的說話者（旁白）就停在上一個鏡位。
## 只看 `Game.dialogue`，不接訊號：倒下重來、回標題把對話直接清掉的時候也會自己回去。
## 有 `talk_to(位置)` 的角色（諾恩）在對話開始時會被叫去面向對方——跟在後面的席菈開口時他才不會背對著她講話。

## 鏡頭離講話的人多遠（沿著「講話的人 → 聽的人」的方向）、往旁邊偏多少、多高
const DIST: float = 2.2
const SIDE: float = 0.7
const EYE_HEIGHT: float = 1.5
## 對準胸口而不是臉：臉落在畫面上面三分之一，下面留給對話框
const AIM_HEIGHT: float = 1.2
const TALK_FOV: float = 38.0
## 從玩家的鏡頭滑過來／滑回去要多久
const BLEND_SEC: float = 0.45
## 鏡位被場景擋住（樹、岩石）就往講話的人拉近；角色不算
const WORLD_MASK: int = 1 | 2
const WALL_MARGIN: float = 0.25

var cast: Dictionary[String, Node3D] = {}

var _home: Camera3D
var _speaker: String = ""
var _shot: Transform3D
## 0＝玩家的鏡頭，1＝對話的鏡位
var _blend: float = 0.0


## 這一句的鏡位。`speaker`、`listener` 是兩人腳下的位置，`home` 是玩家鏡頭的位置（決定站在兩人連線的哪一側）。
static func shot(speaker: Vector3, listener: Vector3, home: Vector3) -> Transform3D:
	var flat := Vector3(listener.x - speaker.x, 0.0, listener.z - speaker.z)
	var fwd: Vector3 = flat.normalized() if flat.length() > 0.05 else Vector3.BACK
	var right: Vector3 = fwd.cross(Vector3.UP)
	var side: float = 1.0 if (home - speaker).dot(right) >= 0.0 else -1.0
	var eye: Vector3 = speaker + fwd * DIST + right * side * SIDE + Vector3.UP * EYE_HEIGHT
	return Transform3D(Basis.looking_at(aim_point(speaker) - eye, Vector3.UP), eye)


static func aim_point(speaker: Vector3) -> Vector3:
	return speaker + Vector3.UP * AIM_HEIGHT


func is_talking() -> bool:
	return _home != null


func speaker() -> Node3D:
	return _member(_speaker)


## 跟玩家的鏡頭一樣在物理幀更新（PlayerController._follow_rig）：兩邊同一拍，滑過去不會抖
func _physics_process(delta: float) -> void:
	var r: DialogueRunner = Game.dialogue
	var running: bool = r != null and r.is_running()
	var key: String = str(r.current().get("speaker", "")) if running else ""
	if running and _home == null and _member(key) != null:
		_enter()
	if _home == null:
		return
	if not is_instance_valid(_home):
		_leave()
		return
	if running:
		var who: Node3D = _member(key)
		if who != null and key != _speaker:
			_speaker = key
			_shot = _frame(who)
		_blend = minf(_blend + delta / BLEND_SEC, 1.0)
	else:
		_blend = maxf(_blend - delta / BLEND_SEC, 0.0)
		if _blend <= 0.0:
			_leave()
			return
	var t: float = smoothstep(0.0, 1.0, _blend)
	global_transform = _home.global_transform.interpolate_with(_shot, t)
	fov = lerpf(_home.fov, TALK_FOV, t)


func _member(key: String) -> Node3D:
	if not cast.has(key):
		return null
	var n: Node3D = cast[key]
	return n if is_instance_valid(n) and n.is_inside_tree() else null


## 對話開始：記住玩家的鏡頭、從它現在的位置接手，讓兩個人面對面。
func _enter() -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null or cam == self:
		return
	_home = cam
	_speaker = ""
	_blend = 0.0
	global_transform = cam.global_transform
	fov = cam.fov
	current = true
	for key: String in cast:
		var who: Node3D = _member(key)
		var other: Node3D = _listener(who)
		if who != null and other != null and who.has_method("talk_to"):
			who.call("talk_to", other.global_position)


func _leave() -> void:
	if _home != null and is_instance_valid(_home):
		_home.current = true
	current = false
	_home = null
	_speaker = ""
	_blend = 0.0


## 聽的人：登記的人裡第一個不是講話的那個
func _listener(who: Node3D) -> Node3D:
	for key: String in cast:
		var n: Node3D = _member(key)
		if n != null and n != who:
			return n
	return null


func _frame(who: Node3D) -> Transform3D:
	var other: Node3D = _listener(who)
	var home: Vector3 = _home.global_position
	var from: Vector3 = who.global_position
	var s: Transform3D = shot(from, other.global_position if other != null else home, home)
	var aim: Vector3 = aim_point(from)
	var query := PhysicsRayQueryParameters3D.create(aim, s.origin, WORLD_MASK)
	var skip: Array[RID] = []
	for key: String in cast:
		var body := _member(key) as CollisionObject3D
		if body != null:
			skip.append(body.get_rid())
	query.exclude = skip
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var at: Vector3 = hit["position"] as Vector3
		var eye: Vector3 = at + (aim - at).normalized() * WALL_MARGIN
		s = Transform3D(Basis.looking_at(aim - eye, Vector3.UP), eye)
	return s
