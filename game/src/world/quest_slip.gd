class_name QuestSlip
extends Node3D
## 莉莉絲那張綠色委託單（程式拼的一張紙＋幾行字）。立著的時候上緣在原點、往下垂、字朝 −Z（拿的人的正前方）；
## 對摺成上下兩半，下半張掛在摺線上——`fold`＝1 是往上摺到前面（看到的是下半張的背面）、0 是攤開。
## `lay`＝1 是整張繞上緣往前倒成平放（字朝上）：放到櫃檯上的那一張就是攤開、平放的。
## 莉莉絲拿出來給諾恩看（GuildHall._hand_over_slip：捏著上緣、翻開、放到櫃檯上）與櫃檯上的那一張都是它。

const SIZE: Vector2 = Vector2(0.22, 0.3)
const THICK: float = 0.004
const PAPER: Color = Color(0.36, 0.62, 0.34)
const INK: Color = Color(0.1, 0.2, 0.1)
## 每一行字：寬（比例）、高（m）、離上緣多遠（m）
const ROWS: Array[Vector3] = [Vector3(0.8, 0.03, 0.035), Vector3(0.66, 0.016, 0.09), Vector3(0.66, 0.016, 0.175), Vector3(0.5, 0.016, 0.23)]

var fold: float = 0.0:
	set(v):
		fold = clampf(v, 0.0, 1.0)
		if _crease != null:
			_crease.rotation.x = PI * fold
var lay: float = 0.0:
	set(v):
		lay = clampf(v, 0.0, 1.0)
		if _sheet != null:
			_sheet.rotation.x = PI * 0.5 * lay
var _sheet: Node3D
var _crease: Node3D


static func create(p_fold: float = 0.0, p_lay: float = 0.0) -> QuestSlip:
	var q := QuestSlip.new()
	q.name = "QuestSlip"
	q._build()
	q.fold = p_fold
	q.lay = p_lay
	return q


func _build() -> void:
	var paper := StandardMaterial3D.new()
	paper.albedo_color = PAPER
	paper.roughness = 1.0
	var ink := StandardMaterial3D.new()
	ink.albedo_color = INK
	ink.roughness = 1.0
	_sheet = Node3D.new()
	_sheet.name = "Sheet"
	add_child(_sheet)
	var half: float = SIZE.y * 0.5
	_half(_sheet, Vector3.ZERO, paper, ink, 0.0)
	# 下半張：摺線在一半的地方；往前摺的時候疊在上半張的前面（稍微往前一點，不要跟上半張打架）
	_crease = Node3D.new()
	_crease.name = "Crease"
	_crease.position = Vector3(0, -half, -THICK * 1.2)
	_sheet.add_child(_crease)
	_half(_crease, Vector3.ZERO, paper, ink, half)


## 半張紙：上緣在 at、往下垂 SIZE.y／2；from＝這半張的上緣離整張的上緣多遠（決定畫哪幾行字）
func _half(parent: Node3D, at: Vector3, paper: Material, ink: Material, from: float) -> void:
	var half: float = SIZE.y * 0.5
	_box(parent, Vector3(SIZE.x, half, THICK), at + Vector3(0, -half * 0.5, 0), paper)
	for row: Vector3 in ROWS:
		if row.z >= from and row.z < from + half:
			_box(parent, Vector3(SIZE.x * row.x, row.y, THICK * 0.5), at + Vector3(0, -(row.z - from), -THICK * 0.7), ink)


func _box(parent: Node3D, size: Vector3, at: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	b.material = mat
	mi.mesh = b
	mi.position = at
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
