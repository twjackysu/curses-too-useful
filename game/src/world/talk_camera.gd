class_name TalkCamera
extends Camera3D
## 對話時的鏡頭：看著正在講話的人的臉（上半身的近景），換人講就切到另一邊；講完滑回玩家的鏡頭。
## 兩邊的鏡位都留在玩家鏡頭的那一側（不跨過兩人之間的那條線），切過去不會左右顛倒。
## 滑過去、滑回來走的是一個弧：直線會擦過誰的頭就往外繞開（`detour`）。
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
## 滑過去的路上離每個人的頭至少這麼遠（水平）：直線會擦過誰的頭就往外繞一個弧（相遇那一段，諾恩的頭髮蓋掉過四分之一個畫面）
const HEAD_CLEAR: float = 1.3
const MAX_DETOUR: float = 1.6
## 鏡位被場景擋住（樹、岩石）就往講話的人拉近；角色不算
const WORLD_MASK: int = 1 | 2
const WALL_MARGIN: float = 0.25
const DROP_META: String = "talk_drop"

var cast: Dictionary[String, Node3D] = {}

var _home: Camera3D
var _speaker: String = ""
var _shot: Transform3D
## 滑過去／滑回來的路上往旁邊繞多少（弧的最高點；兩端是 0）
var _detour: Vector3 = Vector3.ZERO
## 0＝玩家的鏡頭，1＝對話的鏡位
var _blend: float = 0.0


## 這一句的鏡位。`speaker`、`listener` 是兩人腳下的位置，`home` 是玩家鏡頭的位置（決定站在兩人連線的哪一側）。
## `drop`＝講話的人比站著矮多少（倒在地上的人：鏡頭與對準的地方一起放低）。
static func shot(speaker: Vector3, listener: Vector3, home: Vector3, drop: float = 0.0) -> Transform3D:
	var flat := Vector3(listener.x - speaker.x, 0.0, listener.z - speaker.z)
	var fwd: Vector3 = flat.normalized() if flat.length() > 0.05 else Vector3.BACK
	var right: Vector3 = fwd.cross(Vector3.UP)
	var side: float = 1.0 if (home - speaker).dot(right) >= 0.0 else -1.0
	var eye: Vector3 = speaker + fwd * DIST + right * side * SIDE + Vector3.UP * (EYE_HEIGHT - drop * 0.8)
	return Transform3D(Basis.looking_at(aim_point(speaker, drop) - eye, Vector3.UP), eye)


static func aim_point(speaker: Vector3, drop: float = 0.0) -> Vector3:
	return speaker + Vector3.UP * (AIM_HEIGHT - drop)


## 這個人比站著矮多少（關卡在倒地的人身上設 meta "talk_drop"）
static func drop_of(who: Node3D) -> float:
	return float(who.get_meta(DROP_META, 0.0))


## 從 from 滑到 to 的路上要往旁邊繞多少（水平的向量）：加在位置上的是「它 × sin(π × 走了幾成)」，所以兩端不動、中間鼓出去。
## heads＝場上每個人站的地方。直線離誰不到 HEAD_CLEAR，就朝離開他的方向鼓到剛好夠遠；都夠遠就是零。
static func detour(from: Vector3, to: Vector3, heads: Array[Vector3]) -> Vector3:
	var a := Vector2(from.x, from.z)
	var ab := Vector2(to.x, to.z) - a
	if ab.length() < 0.1:
		return Vector3.ZERO
	var best := Vector3.ZERO
	for h: Vector3 in heads:
		var u: float = (Vector2(h.x, h.z) - a).dot(ab) / ab.length_squared()
		# 最靠近他的地方就是起點或終點（例：席菈站在玩家的鏡頭旁邊）：兩端不能動，路上只會離他越來越遠，不用繞
		if u <= 0.02 or u >= 0.98:
			continue
		var gap: Vector2 = a + ab * u - Vector2(h.x, h.z)
		var d: float = gap.length()
		if d >= HEAD_CLEAR:
			continue
		var out: Vector2 = gap / d if d > 0.01 else ab.orthogonal().normalized()
		# 最靠近的那一點在路上的第 u 成：那裡只鼓出 sin(πu)，所以最高點要多鼓一些（太靠近兩端就鼓不到，有上限）
		var need: float = minf((HEAD_CLEAR - d) / maxf(sin(PI * u), 0.35), MAX_DETOUR)
		if need > best.length():
			best = Vector3(out.x, 0.0, out.y) * need
	return best


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
			_detour = _clear_detour()
		_blend = minf(_blend + delta / BLEND_SEC, 1.0)
	else:
		_blend = maxf(_blend - delta / BLEND_SEC, 0.0)
		if _blend <= 0.0:
			_leave()
			return
	var t: float = smoothstep(0.0, 1.0, _blend)
	global_transform = _home.global_transform.interpolate_with(_shot, t)
	global_position += _detour * sin(PI * t)
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
	_detour = Vector3.ZERO


## 聽的人：登記的人裡第一個不是講話的那個
func _listener(who: Node3D) -> Node3D:
	for key: String in cast:
		var n: Node3D = _member(key)
		if n != null and n != who:
			return n
	return null


## 這個鏡位跟玩家的鏡頭之間要繞多少；繞出去的地方被場景擋住就少繞一點
func _clear_detour() -> Vector3:
	var heads: Array[Vector3] = []
	for key: String in cast:
		var n: Node3D = _member(key)
		if n != null:
			heads.append(n.global_position)
	var d: Vector3 = detour(_home.global_position, _shot.origin, heads)
	if d == Vector3.ZERO:
		return d
	var mid: Vector3 = _home.global_position.lerp(_shot.origin, 0.5)
	var query := PhysicsRayQueryParameters3D.create(mid, mid + d + d.normalized() * WALL_MARGIN, WORLD_MASK)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		d = d.normalized() * maxf(mid.distance_to(hit["position"] as Vector3) - WALL_MARGIN, 0.0)
	return d


func _frame(who: Node3D) -> Transform3D:
	var other: Node3D = _listener(who)
	var home: Vector3 = _home.global_position
	var from: Vector3 = who.global_position
	var drop: float = drop_of(who)
	var s: Transform3D = shot(from, other.global_position if other != null else home, home, drop)
	var aim: Vector3 = aim_point(from, drop)
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
