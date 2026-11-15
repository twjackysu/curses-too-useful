class_name WebTrap
extends Node3D
## 麻痺蜘蛛網（docs/story/chapter-1.md 時段 B 的陷阱）：兩根枯枝中間掛一張網。諾恩碰到網的那一刻套用來源
## （data/status/statuses.json 的 web_snare：麻痺＋緩速——對他是出手加速＋跑得更快）；走開一段距離之後才會再黏一次，
## 站在網裡不會一直疊。模型是 Tripo 的（網沿著自己的 Z 軸張開）；檔案不在就用兩根木樁＋一片半透明的網。

signal snared(by: PlayerController)

const MODEL: String = "tripo/prop_paralysis_web_v2"
## 網從中心往兩邊各張開多寬、離網多近算碰到、走開多遠才會再黏一次（公尺）
const HALF_SPAN: float = 1.15
const TOUCH: float = 0.5
const REARM: float = 1.6

var source_id: String = "web_snare"
## 黏到過幾次（測試用）
var snares: int = 0
var _armed: bool = true
var _look: Node3D


## yaw＝網張開的方向（弧度；0＝沿著 Z 軸，橫跨一條東西向的路）
static func create(node_name: String, at: Vector3, yaw: float) -> WebTrap:
	var w := WebTrap.new()
	w.name = node_name
	w.position = at
	w.rotation.y = yaw
	return w


func _ready() -> void:
	_look = PropModels.instance(MODEL)
	if _look == null:
		_look = _stand_in()
	_look.name = "Look"
	add_child(_look)


func _physics_process(_delta: float) -> void:
	var p: PlayerController = get_tree().get_first_node_in_group("player") as PlayerController
	if p == null or p.health.is_dead() or Game.is_player_locked():
		return
	var dist: float = distance_to_web(p.global_position)
	if _armed and dist < TOUCH:
		_armed = false
		snares += 1
		p.status_effects.apply_source(source_id)
		Sfx.play_at(self, "interrupt", global_position + Vector3.UP, -5.0)
		# 網被扯了一下
		var t: Tween = create_tween()
		t.tween_property(_look, "scale", Vector3(1.0, 0.94, 1.12), 0.07)
		t.tween_property(_look, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		snared.emit(p)
	elif not _armed and dist > REARM:
		_armed = true


## 這個位置離網多遠（水平；網是一條線段）
func distance_to_web(p: Vector3) -> float:
	var along: Vector3 = global_basis.z * HALF_SPAN
	var a := Vector2(global_position.x - along.x, global_position.z - along.z)
	var b := Vector2(global_position.x + along.x, global_position.z + along.z)
	var here := Vector2(p.x, p.z)
	return here.distance_to(Geometry2D.get_closest_point_to_segment(here, a, b))


static func _stand_in() -> Node3D:
	var root := Node3D.new()
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.28, 0.2, 0.2)
	for side: float in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.05
		cyl.bottom_radius = 0.09
		cyl.height = 2.6
		cyl.material = wood
		post.mesh = cyl
		post.position = Vector3(0.0, 1.3, side * HALF_SPAN)
		root.add_child(post)
	var web := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(HALF_SPAN * 2.0, 2.0)
	var silk := StandardMaterial3D.new()
	silk.albedo_color = Color(0.9, 0.92, 1.0, 0.35)
	silk.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	silk.cull_mode = BaseMaterial3D.CULL_DISABLED
	quad.material = silk
	web.mesh = quad
	web.position = Vector3(0.0, 1.3, 0.0)
	web.rotation.y = PI * 0.5
	root.add_child(web)
	return root
