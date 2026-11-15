class_name Interactable
extends Node3D
## 走近按鍵就能做的東西（採毒蕈、吃野果、營火、寶箱）：諾恩進到 reach 公尺內，畫面下方出現提示（InteractPrompt），按「互動」就發 used。
## 同時有好幾個在範圍內：只有離他最近的那一個有反應。要做什麼由關卡接 used 決定；這裡不認得毒蕈或寶箱。

signal used(by: PlayerController)

const GROUP: String = "interact_prompts"
const ACTION: String = "interact"

## 提示的字（翻譯 key；字裡的 {key} 換成按鍵）
var hint_key: String = ""
var reach: float = 2.2
## false＝現在不能用（採過了、還沒輪到）：沒有提示、按了沒反應，目標指引也不指它
var enabled: bool = true


static func create(node_name: String, at: Vector3, p_hint_key: String, p_reach: float = 2.2) -> Interactable:
	var it := Interactable.new()
	it.name = node_name
	it.position = at
	it.hint_key = p_hint_key
	it.reach = p_reach
	return it


func _ready() -> void:
	add_to_group(GROUP)


## 目標指引（"nearest:<前綴>"）問的：還能不能用
func is_available() -> bool:
	return enabled


## InteractPrompt 問的：現在要不要顯示提示
func interact_hint() -> Dictionary:
	if _user() == null:
		return {}
	return {"fmt": tr(hint_key), "action": ACTION, "progress": -1.0}


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed(ACTION):
		var p: PlayerController = _user()
		if p != null:
			use(p)


## 用一次（按鍵，或測試直接叫）
func use(by: PlayerController) -> void:
	used.emit(by)


## 現在可以用它的那個人：能用、沒在對話、諾恩在範圍內，而且範圍內沒有別的更近。沒有回傳 null。
func _user() -> PlayerController:
	if not enabled or not is_inside_tree() or Game.is_player_locked():
		return null
	var p: PlayerController = get_tree().get_first_node_in_group("player") as PlayerController
	if p == null or p.health.is_dead():
		return null
	var dist: float = _flat_distance(p)
	if dist > reach:
		return null
	for n: Node in get_tree().get_nodes_in_group(GROUP):
		var other := n as Interactable
		if other != null and other != self and other.enabled and other._flat_distance(p) < minf(dist, other.reach):
			return null
	return p


func _flat_distance(p: Node3D) -> float:
	return Vector2(p.global_position.x - global_position.x, p.global_position.z - global_position.z).length()
