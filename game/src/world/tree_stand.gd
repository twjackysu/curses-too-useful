class_name TreeStand
extends Node3D
## 一片樹（森林、祭壇外圍）。以前一棵樹一個 StaticBody3D＋一份模型：森林一百六十棵＝一百六十個要畫的東西，影子每一層再各畫一次。
## 現在碰撞是一個 StaticBody3D（Trunks）底下一棵一根樹幹；外型照「哪一種樹 × 哪一塊地（CHUNK 公尺見方）」各一個
## MultiMeshInstance3D——分成一塊一塊，鏡頭看不到的那幾塊照舊整塊不畫、遠的那幾塊整塊選面數少的 LOD。
## 每棵的高矮胖瘦、朝向、顏色偏移（ForestScenery.variation、tree_tint）跟以前一棵一個節點時一樣；隨風擺照舊
## （wind_sway.gdshader 的 per_instance：顏色偏移放在每一棵的 INSTANCE_CUSTOM，擺動的相位照每一棵自己的位置）。
## 用法：add(腳下的位置, 大小, 朝向) 種完之後 build()——之前什麼都不會出現。

## 一塊地幾公尺見方：太大就裁不掉看不到的樹，太小又變回很多個要畫的東西（森林 200 m 見方、樹長在路兩邊）
const CHUNK: float = 32.0
## 樹幹的碰撞（以前每棵 StaticBody3D 的那一根）：半徑 × 大小、高
const TRUNK_RADIUS: float = 0.45
const TRUNK_HEIGHT: float = 4.0

## 每一棵：腳下的位置、大小、朝向（測試看這幾個——沒有算圖的時候讀不回 MultiMesh 裡的位置）
var positions := PackedVector3Array()
var sizes := PackedFloat32Array()
var yaws := PackedFloat32Array()


func _init() -> void:
	name = "Trees"


func add(at: Vector3, size: float, yaw: float) -> void:
	positions.append(at)
	sizes.append(size)
	yaws.append(yaw)


func count() -> int:
	return positions.size()


## 這一棵實際種哪一種（TREE_MODELS 的第幾個）：那一種的模型不在就種第一種
static func kind_at(at: Vector3) -> int:
	var k: int = ForestScenery.tree_kind(at)
	if k != 0 and PropModels.scene_for(ForestScenery.TREE_MODELS[k]) == null:
		return 0
	return k


func build() -> void:
	var trunks := StaticBody3D.new()
	trunks.name = "Trunks"
	add_child(trunks)
	var parts_of: Dictionary = {}  # 種類 → _parts()
	var groups: Dictionary = {}  # Vector3i(種類, 塊 x, 塊 z) → 這一塊的第幾棵
	for i: int in count():
		var at: Vector3 = positions[i]
		var shape := CollisionShape3D.new()
		var trunk := CylinderShape3D.new()
		trunk.radius = TRUNK_RADIUS * sizes[i]
		trunk.height = TRUNK_HEIGHT
		shape.shape = trunk
		shape.position = at + Vector3(0, TRUNK_HEIGHT * 0.5, 0)
		trunks.add_child(shape)
		var key := Vector3i(kind_at(at), floori(at.x / CHUNK), floori(at.z / CHUNK))
		if not groups.has(key):
			groups[key] = PackedInt32Array()
		var list: PackedInt32Array = groups[key]
		list.append(i)
		groups[key] = list
	for key: Vector3i in groups:
		if not parts_of.has(key.x):
			parts_of[key.x] = _parts(key.x)
		for part: Dictionary in parts_of[key.x]:
			add_child(_chunk(part, groups[key], "Kind%d_%d_%d" % [key.x, key.y, key.z]))


## 一棵樹的第 i 個網格要擺在哪裡（相對於這片樹）
func instance_transform(i: int, part_xform: Transform3D, varied: bool) -> Transform3D:
	var at: Vector3 = positions[i]
	var v: Vector3 = ForestScenery.variation(at) if varied else Vector3.ONE
	var scale := Vector3(sizes[i] * v.x, sizes[i] * v.y, sizes[i] * v.x)
	return Transform3D(Basis(Vector3.UP, yaws[i]) * Basis.from_scale(scale), at) * part_xform


## 第 i 棵的顏色偏移（乘在模型的顏色上；放在 MultiMesh 每一棵的 INSTANCE_CUSTOM）
func tint(i: int) -> Color:
	var c: Color = ForestScenery.tree_tint(ForestScenery.variation(positions[i]).z)
	return Color(c.r, c.g, c.b, 0.0)


func _chunk(part: Dictionary, trees: PackedInt32Array, chunk_name: String) -> MultiMeshInstance3D:
	var varied: bool = bool(part["varied"])
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = varied
	mm.mesh = part["mesh"]
	mm.instance_count = trees.size()
	for j: int in trees.size():
		var i: int = trees[j]
		mm.set_instance_transform(j, instance_transform(i, part["xform"], varied))
		if varied:
			mm.set_instance_custom_data(j, tint(i))
	var node := MultiMeshInstance3D.new()
	node.name = chunk_name
	node.multimesh = mm
	if part["material"] != null:
		node.material_override = part["material"]
	if varied:
		node.set_instance_shader_parameter("base_y", (part["xform"] as Transform3D).origin.y)
	return node


## 一種樹拆成的網格：[{mesh, xform（相對於模型的原點）, material（會隨風擺的；沒有＝用網格自己的）, varied（照位置變高矮胖瘦與顏色）}]。
## 模型不在：一根程式做的樹幹（以前檔案不在時的那一根）。
static func _parts(kind: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var look: Node3D = PropModels.instance(ForestScenery.TREE_MODELS[kind])
	if look == null:
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.2
		cyl.bottom_radius = 0.45
		cyl.height = 6.0
		var bark := StandardMaterial3D.new()
		bark.albedo_color = Color(0.2, 0.15, 0.2)
		cyl.material = bark
		out.append({"mesh": cyl, "xform": Transform3D(Basis.IDENTITY, Vector3(0, 3.0, 0)), "material": null, "varied": false})
		return out
	var meshes: Array[Node] = look.find_children("*", "MeshInstance3D", true, false)
	if look is MeshInstance3D:
		meshes.append(look)
	for n: Node in meshes:
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		var xform: Transform3D = mi.transform if mi != look else Transform3D.IDENTITY
		var up: Node = mi.get_parent()
		while mi != look and up != look and up is Node3D:
			xform = (up as Node3D).transform * xform
			up = up.get_parent()
		# MultiMesh 沒有每一面各自的材質：一面的網格整個換成會擺的；好幾面的（目前的樹都是一面）複製一份網格各自換
		var mesh: Mesh = mi.mesh
		var material: Material = null
		if mesh.get_surface_count() == 1:
			material = _sway_material(mi.get_active_material(0))
		elif mesh is ArrayMesh:
			var copy := mesh.duplicate() as ArrayMesh
			for s: int in copy.get_surface_count():
				copy.surface_set_material(s, _sway_material(mi.get_active_material(s)))
			mesh = copy
		out.append({"mesh": mesh, "xform": xform, "material": material, "varied": true})
	look.free()
	return out


static func _sway_material(src: Material) -> Material:
	var base := src as BaseMaterial3D
	if base == null:
		return src
	return ForestScenery.sway_material(base, ForestScenery.TREE_SWAY, true)
