class_name FarCull
extends RefCounted
## 森林很大（200 m 見方），夜裡又有霧：遠處的小東西看不到也照樣畫、小燈照樣算。關卡蓋好之後走一遍（ForestScenery.build_environment
## 之後、關卡的 _ready 最後）：
## ①小的擺設（外框最長邊 SMALL 公尺以內：石頭、倒木、毒蕈、灌木、陷阱、營火的行李）離鏡頭 FAR 公尺以外不畫；
## ②小燈（照的範圍 SMALL_LIGHT 公尺以內的 OmniLight3D：毒蕈、噴發口、寶箱……）離鏡頭 LIGHT_BEGIN 公尺開始淡、再 LIGHT_FADE 公尺關掉；
##   大的燈是遠遠就要看到的地標（祭壇路口的紅光 16 m、營火 13 m），不動；
## 人物（CharacterBody3D 底下：諾恩、席菈、敵人）不動，自己已經設了距離的不動。
## 樹不在這裡：TreeStand 一塊一塊的 MultiMesh 本來就照塊裁掉看不到的。月光的影子只算到 MOON_SHADOW_FAR 公尺（以前 100 m）。

const SMALL: float = 4.5
const FAR: float = 65.0
const SMALL_LIGHT: float = 8.0
const LIGHT_BEGIN: float = 45.0
const LIGHT_FADE: float = 15.0
const MOON_SHADOW_FAR: float = 60.0


## 回傳 [設了距離的擺設數, 設了淡出的燈數]
static func apply(root: Node) -> Vector2i:
	return _walk(root, Vector2i.ZERO)


static func _walk(node: Node, counts: Vector2i) -> Vector2i:
	if node is CharacterBody3D:
		return counts
	if node is DirectionalLight3D:
		(node as DirectionalLight3D).directional_shadow_max_distance = MOON_SHADOW_FAR
	elif node is OmniLight3D:
		var lamp := node as OmniLight3D
		if not lamp.distance_fade_enabled and lamp.omni_range <= SMALL_LIGHT:
			lamp.distance_fade_enabled = true
			lamp.distance_fade_begin = LIGHT_BEGIN
			lamp.distance_fade_length = LIGHT_FADE
			lamp.distance_fade_shadow = LIGHT_BEGIN
			counts.y += 1
	elif node is GeometryInstance3D and not node is MultiMeshInstance3D:
		var g := node as GeometryInstance3D
		if g.visibility_range_end <= 0.0 and _size(g) <= SMALL:
			g.visibility_range_end = FAR
			counts.x += 1
	for child: Node in node.get_children():
		counts = _walk(child, counts)
	return counts


## 外框最長的一邊（世界座標的大小：算上縮放）
static func _size(g: GeometryInstance3D) -> float:
	var box: AABB = g.get_aabb()
	var s: Vector3 = g.global_basis.get_scale() if g.is_inside_tree() else g.basis.get_scale()
	return maxf(maxf(box.size.x * s.x, box.size.y * s.y), box.size.z * s.z)
