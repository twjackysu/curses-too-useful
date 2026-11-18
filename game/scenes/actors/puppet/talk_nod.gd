class_name TalkNod
extends SkeletonModifier3D
## 講話時頭會動：疊在動作上面（動作先擺好姿勢，這裡再把頭點一點、晃一晃）。`Puppet.talk_weight()` 是 0 就什麼都不做。
## 動作的時間軸不用改：Skeleton3D 套完動畫才跑 modifier，掛在骨頭上的東西（劍、手弩）照樣跟著。
## 頭怎麼動照 `Puppet.nod_angles()`（程式人偶也用同一套，轉在脖子上）。

var puppet: Puppet
var bone: int = -1


func _process_modification_with_delta(_delta: float) -> void:
	var sk: Skeleton3D = get_skeleton()
	if sk == null or puppet == null or bone < 0:
		return
	var w: float = puppet.talk_weight()
	if w <= 0.001:
		return
	var a: Vector3 = puppet.nod_angles_skeleton() * w
	# 在骨架座標裡轉（X＝左右、Y＝上、Z＝前後），換回這根骨頭自己的座標：L' = P⁻¹ · R · P · L
	var parent: int = sk.get_bone_parent(bone)
	var p: Basis = sk.get_bone_global_pose(parent).basis.orthonormalized() if parent >= 0 else Basis.IDENTITY
	var r := Basis.from_euler(a)
	var local: Basis = Basis(sk.get_bone_pose_rotation(bone))
	sk.set_bone_pose_rotation(bone, (p.inverse() * r * p * local).get_rotation_quaternion())
