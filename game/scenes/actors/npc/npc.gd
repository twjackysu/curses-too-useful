class_name Npc
extends StaticBody3D
## 站在場景裡的人（公會大廳的櫃檯小姐、冒險者、雷歐小隊、二樓的巡察官）：站著、轉過去看某個地方、走到某個地方，
## 坐著、笑、累垮（pose）、伸手或遞東西（gesture）。走路時會從諾恩旁邊繞過去（不穿過他），腳落地有腳步聲。
## 不會被打、不做決定——要他做什麼由關卡叫（walk_to、face、pose）。站著的時候擋路（一個膠囊，只在 GuildScenery.PEOPLE_LAYER：
## 擋人不擋鏡頭）；走路的時候不擋（不會把諾恩推開或卡住）。外型用 Puppet（有模型用模型，沒有就是程式人偶）。

const TURN_SPEED: float = 7.0
const ARRIVE_DIST: float = 0.12
## 走路的路上諾恩在這個距離內、又在前面，就往旁邊偏開
const AVOID_DIST: float = 1.2
## 腳步聲（比諾恩自己的小一點）
const STEP_DB: float = -16.0

var character_id: String = ""
var puppet: Puppet
## 走到之後要不要消失（走出大門的人）
var leave_on_arrival: bool = false
var _goal: Vector3 = Vector3.INF
## walk_path 還沒走到的那幾個點
var _path: Array[Vector3] = []
var _speed: float = 0.0
var _look: Vector3 = Vector3.INF
var _shape: CollisionShape3D
var footsteps: Footsteps = Footsteps.new(STEP_DB, STEP_DB)
## 站著不動時的樣子（Puppet.POSES：""、sit、sit_hunch、sit_drink、sit_laugh、laugh、slump）
var pose: String = "":
	set(value):
		pose = value
		if puppet != null:
			puppet.pose = value


## facing_deg：0＝面向 −Z（北），180＝面向南邊的大門
static func create(node_name: String, p_character_id: String, at: Vector3, facing_deg: float = 0.0) -> Npc:
	var n := Npc.new()
	n.name = node_name
	n.character_id = p_character_id
	n.position = at
	n.rotation.y = deg_to_rad(facing_deg)
	return n


func _ready() -> void:
	collision_layer = GuildScenery.PEOPLE_LAYER
	collision_mask = 0
	_shape = CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.6
	_shape.shape = capsule
	_shape.position = Vector3(0, 0.8, 0)
	add_child(_shape)
	puppet = Puppet.new()
	puppet.name = "Puppet"
	puppet.character_id = character_id
	puppet.pose = pose
	add_child(puppet)
	puppet.footfall.connect(func() -> void: footsteps.stomp(self))
	ContactShadow.attach(self, 0.5, 0.5)


## 走到 point（直線，不繞路：關卡給的路線自己避開桌子）。speed 公尺／秒。
func walk_to(point: Vector3, speed: float = 1.5) -> void:
	_goal = Vector3(point.x, global_position.y, point.z)
	_speed = speed
	_look = Vector3.INF
	_shape.set_deferred("disabled", true)


## 照順序走過這幾個點（繞過桌子用）
func walk_path(points: Array[Vector3], speed: float = 1.5) -> void:
	_path = points.duplicate()
	if not _path.is_empty():
		walk_to(_path.pop_front() as Vector3, speed)


func is_walking() -> bool:
	return _goal.is_finite()


## 一次性的手勢（Puppet.ACTION_TIME 的 reach、give），做完回到原本的樣子
func gesture(action_name: String) -> void:
	puppet.play_action(action_name)


## 轉過去看 point：站著的人整個人轉過去；坐著的人（身體不能離開座位）只轉頭（最多 Puppet.LOOK_YAW_MAX）。
## Vector3.INF＝不看了（坐著的人頭轉回正前方）
func face(point: Vector3) -> void:
	_look = point
	if not point.is_finite() and puppet != null:
		puppet.look_yaw = 0.0


## 坐著的樣子（身體不轉，轉頭）
func is_seated() -> bool:
	return pose.begins_with("sit")


## 對話開始時 TalkCamera 會叫：面向對方
func talk_to(point: Vector3) -> void:
	if not is_walking():
		face(point)


func _physics_process(delta: float) -> void:
	var dir := Vector3.ZERO
	if _goal.is_finite():
		var step: Vector3 = _goal - global_position
		step.y = 0.0
		if step.length() <= maxf(ARRIVE_DIST, _speed * delta):
			global_position = _goal
			if not _path.is_empty():
				_goal = _path.pop_front() as Vector3
				_goal.y = global_position.y
				return
			_goal = Vector3.INF
			puppet.set_move_speed(0.0)
			_shape.set_deferred("disabled", false)
			if leave_on_arrival:
				queue_free()
			return
		dir = _steer_around_player(step.normalized())
		global_position += dir * _speed * delta
		puppet.set_move_speed(_speed)
	elif _look.is_finite():
		dir = _look - global_position
		dir.y = 0.0
		if dir.length() < 0.05:
			return
		dir = dir.normalized()
		if is_seated():
			# 往左轉是正的：身體的正前方轉到 dir 要轉多少
			var fwd: Vector3 = -global_basis.z
			puppet.look_yaw = atan2(fwd.cross(dir).y, fwd.dot(dir))
			return
	if dir != Vector3.ZERO:
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), minf(delta * TURN_SPEED, 1.0))


## 諾恩擋在前面就往旁邊偏（離他越近偏越多），走過去之後自己會轉回去朝著目的地
func _steer_around_player(dir: Vector3) -> Vector3:
	var player: Node3D = get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return dir
	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0
	var d: float = to_player.length()
	if d >= AVOID_DIST or d < 0.01 or to_player.dot(dir) <= 0.0:
		return dir
	var right: Vector3 = dir.cross(Vector3.UP)
	var away: float = -1.0 if right.dot(to_player) > 0.0 else 1.0
	return (dir + right * away * 2.5 * (1.0 - d / AVOID_DIST)).normalized()
