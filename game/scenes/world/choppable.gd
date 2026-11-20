class_name Choppable
extends Node3D
## 可以用劍砍、但不是敵人的東西（纏住絞盤的藤、有裂紋的枯木）：諾恩的 strike() 掃到它就發 chopped，要做什麼由關卡接。
## 做法：底下掛一個砍不死的 Health（PlayerController.strike 找的是 damageable 群組裡有 Health 的節點）；
## 自動攻擊旁邊沒有敵人時也會砍它（PlayerController.auto_target 看 GROUP）。active＝false 就砍不到。

signal chopped(info: Dictionary)

const GROUP: String = "choppable"

var health: Health
var active: bool = true:
	set(value):
		active = value
		_sync()


static func create(node_name: String, at: Vector3) -> Choppable:
	var c := Choppable.new()
	c.name = node_name
	c.position = at
	return c


func _ready() -> void:
	health = Health.new(1.0)
	health.name = "Health"
	health.min_hp = 1.0
	add_child(health)
	health.damaged.connect(func(_amount: float, info: Dictionary) -> void: chopped.emit(info))
	_sync()


func _sync() -> void:
	if not is_inside_tree():
		return
	for g: String in ["damageable", GROUP]:
		if active and not is_in_group(g):
			add_to_group(g)
		elif not active and is_in_group(g):
			remove_from_group(g)
