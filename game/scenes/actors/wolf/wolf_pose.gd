class_name WolfPose
extends SkeletonModifier3D
## 瘴氣狼的身體姿勢（D-303）：Tripo 的四足模型只帶一段原地走路，蹲低要撲、騰空、被打、趴下、倒地都是這裡疊上去的——
## 動畫先擺好走路的那一格，這裡再把四條腿、脖子、背、尾巴照 weights 轉一轉（跟 TalkNod 一樣疊在動作上面）。
## 每個部位只轉「繞身體左右那條軸」的一個角度（正＝往前抬：腿往前伸、頭抬起來、尾巴翹起來），大腿與膝蓋分開給。
## 骨頭的名字是這隻模型的（Tripo 自動綁的：前腳從肩膀那一節開始、後腳左右差一節），找不到的部位就不轉。

## 部位 → [最上面那一節（整條轉）, 膝蓋那一節]（骨頭名的結尾；Godot 匯入時把 "tripo::" 換成 "tripo__"）
const PARTS: Dictionary = {
	"front_l": ["bone_4", "0_Left_Limb_1"],
	"front_r": ["bone_9", "0_Right_Limb_1"],
	"rear_l": ["bone_28", "1_Left_Limb_1"],
	"rear_r": ["1_Right_Limb_0", "1_Right_Limb_2"],
	"neck": ["bone_14", ""],
	"spine": ["Spine_0", ""],
	"tail": ["bone_22", ""],
}
## 姿勢 → 部位 → [整條轉幾弧度, 膝蓋轉幾弧度]。前腳寫一次（左右一樣），後腳也是
const POSES: Dictionary = {
	# 前兆：前腳往後收、膝蓋彎，後腳收到肚子底下，頭壓低、尾巴垂下去（整隻還會用程式往前壓低）
	"crouch": {"front": [-0.35, 0.7], "rear": [0.45, -0.7], "neck": [-0.35, 0.0], "tail": [-0.45, 0.0]},
	# 撲出去：前腳往前伸直、後腳往後蹬直，脖子往前伸、尾巴翹起來
	"leap": {"front": [1.05, -0.25], "rear": [-0.95, 0.35], "neck": [0.2, 0.0], "spine": [0.08, 0.0], "tail": [0.35, 0.0]},
	# 被砍：頭往上一甩、背拱一下、尾巴夾起來
	"hurt": {"front": [-0.2, 0.3], "rear": [0.15, 0.0], "neck": [0.55, 0.0], "spine": [0.18, 0.0], "tail": [-0.6, 0.0]},
	# 失衡趴下：前腳往前平放、後腳折到肚子底下、下巴貼地
	"lie": {"front": [1.25, -0.4], "rear": [1.1, -1.9], "neck": [-0.4, 0.0], "tail": [-0.2, 0.0]},
	# 倒地（整隻側躺）：四條腿軟掉、頭垂下去、尾巴攤平
	"dead": {"front": [0.5, -0.5], "rear": [-0.45, 0.4], "neck": [-0.35, 0.0], "tail": [-0.3, 0.0]},
}

## 姿勢 → 0～1（MiasmaWolf 每一幀設）
var weights: Dictionary = {}
var _bones: Dictionary = {}
var _side: Vector3 = Vector3.RIGHT


## 找骨頭、算身體左右那條軸（骨架座標：從尾巴根到脖子是前、+Y 是上）。回傳找到幾個部位。
func setup(sk: Skeleton3D) -> int:
	_bones.clear()
	for part: String in PARTS:
		var names: Array = PARTS[part] as Array
		var top: int = _find(sk, str(names[0]))
		if top < 0:
			continue
		_bones[part] = [top, _find(sk, str(names[1])) if str(names[1]) != "" else -1]
	if _bones.has("neck") and _bones.has("tail"):
		var front: Vector3 = sk.get_bone_global_rest(int((_bones["neck"] as Array)[0])).origin - sk.get_bone_global_rest(int((_bones["tail"] as Array)[0])).origin
		front.y = 0.0
		if front.length() > 0.001:
			_side = front.normalized().cross(Vector3.UP)
	return _bones.size()


func part_count() -> int:
	return _bones.size()


static func _find(sk: Skeleton3D, suffix: String) -> int:
	if suffix == "":
		return -1
	for i: int in sk.get_bone_count():
		var n: String = sk.get_bone_name(i)
		if n == suffix or n.ends_with("_" + suffix) or n.ends_with(":" + suffix):
			return i
	return -1


## 這個部位這一刻要轉多少（[整條, 膝蓋]，弧度）：各個姿勢照權重加起來
func angles(part: String) -> Vector2:
	var key: String = part.get_slice("_", 0) if part.begins_with("front") or part.begins_with("rear") else part
	var out := Vector2.ZERO
	for pose: String in weights:
		var w: float = float(weights[pose])
		var spec: Dictionary = POSES.get(pose, {}) as Dictionary
		if w > 0.0001 and spec.has(key):
			var a: Array = spec[key] as Array
			out += Vector2(float(a[0]), float(a[1])) * w
	return out


func _process_modification_with_delta(_delta: float) -> void:
	var sk: Skeleton3D = get_skeleton()
	if sk == null or _bones.is_empty():
		return
	# 先轉背（前腳與脖子掛在它底下），再轉其他
	for part: String in ["spine", "neck", "tail", "front_l", "front_r", "rear_l", "rear_r"]:
		if not _bones.has(part):
			continue
		var a: Vector2 = angles(part)
		var ids: Array = _bones[part] as Array
		_turn(sk, int(ids[0]), a.x)
		_turn(sk, int(ids[1]), a.y)


## 在骨架座標裡繞身體的左右軸轉 angle（正＝往前抬），換回這根骨頭自己的座標：L' = P⁻¹ · R · P · L
func _turn(sk: Skeleton3D, bone: int, angle: float) -> void:
	if bone < 0 or absf(angle) < 0.0001:
		return
	var parent: int = sk.get_bone_parent(bone)
	var p: Basis = sk.get_bone_global_pose(parent).basis.orthonormalized() if parent >= 0 else Basis.IDENTITY
	var r := Basis(_side, angle)
	var local := Basis(sk.get_bone_pose_rotation(bone))
	sk.set_bone_pose_rotation(bone, (p.inverse() * r * p * local).get_rotation_quaternion())
