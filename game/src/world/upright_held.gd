class_name UprightHeld
extends Node3D
## 拿在手上、但一直保持直立的小東西（坐著喝酒的客人手上的杯子）：跟著手的位置走，方向不跟手轉——
## 手骨頭的軸在舉杯的時候會翻過去，直接掛在手上杯子會倒過來。轉向只跟著拿的人（yaw）。

var hand: Node3D
var holder: Node3D
## 杯子的底離手腕多遠（拿的人的座標：往前、往上）
var offset: Vector3 = Vector3.ZERO


## 把 model 拿在 who 的 hand 上（hand＝Puppet.hand("R")，who＝那個人）
static func attach(model: Node3D, p_hand: Node3D, who: Node3D, p_offset: Vector3) -> UprightHeld:
	var h := UprightHeld.new()
	h.name = "Held"
	h.hand = p_hand
	h.holder = who
	h.offset = p_offset
	h.top_level = true
	h.add_child(model)
	who.add_child(h)
	h._follow()
	return h


func _process(_delta: float) -> void:
	_follow()


func _follow() -> void:
	if hand == null or holder == null or not is_instance_valid(hand) or not hand.is_inside_tree():
		return
	var yaw := Basis(Vector3.UP, holder.global_rotation.y)
	global_transform = Transform3D(yaw, hand.global_position + yaw * offset)
