class_name Npc
extends StaticBody3D
## 站在場景裡的人（公會大廳的櫃檯小姐、冒險者、雷歐小隊、二樓的巡察官）：站著、轉過去看某個地方、走到某個地方。
## 不會被打、不做決定——要他做什麼由關卡叫（walk_to、face）。站著的時候擋路（一個膠囊，只在 GuildScenery.PEOPLE_LAYER：
## 擋人不擋鏡頭）；走路的時候不擋（不會把諾恩推開或卡住）。外型用 Puppet（有模型用模型，沒有就是程式人偶）。

## 走到 walk_to 指定的地方的那一刻
signal arrived

const TURN_SPEED: float = 7.0
const ARRIVE_DIST: float = 0.12

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
	add_child(puppet)
	ContactShadow.attach(self, 0.5, 0.5)


## 走到 point（直線，不繞路：關卡給的路線自己避開桌子）。speed 公尺／秒。
func walk_to(point: Vector3, speed: float = 1.5) -> void:
	_goal = Vector3(point.x, global_position.y, point.z)
	_speed = speed
	_look = Vector3.INF
	_shape.set_deferred("disabled", true)


## 照順序走過這幾個點（繞過桌子用）；走到最後一個才發 arrived
func walk_path(points: Array[Vector3], speed: float = 1.5) -> void:
	_path = points.duplicate()
	if not _path.is_empty():
		walk_to(_path.pop_front() as Vector3, speed)


func is_walking() -> bool:
	return _goal.is_finite()


## 轉過去看 point（站著的時候）
func face(point: Vector3) -> void:
	_look = point


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
			arrived.emit()
			if leave_on_arrival:
				queue_free()
			return
		dir = step.normalized()
		global_position += dir * _speed * delta
		puppet.set_move_speed(_speed)
	elif _look.is_finite():
		dir = _look - global_position
		dir.y = 0.0
		if dir.length() < 0.05:
			return
		dir = dir.normalized()
	if dir != Vector3.ZERO:
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), minf(delta * TURN_SPEED, 1.0))
