class_name Rumble
extends RefCounted
## 手把震動：砍中、反轉碎裂、挨打、毒爆。只在玩家最後用的是手把（`App.last_device`）而且設定的「手把震動」開著時才震。
## weak＝高頻的小馬達（細細的「嗡」）、strong＝低頻的大馬達（重的「咚」），0～1；sec＝震多久。

## 最後一次要震的強度與秒數（測試用；沒有手把、設定關掉也會記，`fired` 才是真的有沒有送出去）
static var last: Vector3 = Vector3.ZERO
static var fired: bool = false

const HIT: Vector3 = Vector3(0.35, 0.0, 0.06)
const HIT_HEAVY: Vector3 = Vector3(0.45, 0.55, 0.12)
const KILL: Vector3 = Vector3(0.4, 0.7, 0.14)
const SHATTER: Vector3 = Vector3(0.25, 0.4, 0.16)
const HURT: Vector3 = Vector3(0.7, 0.35, 0.12)
const BURST: Vector3 = Vector3(0.6, 0.9, 0.28)


## 震一下。kind＝上面其中一個（weak, strong, sec）。回傳有沒有真的送給手把。
static func pulse(tree: SceneTree, kind: Vector3) -> bool:
	last = kind
	fired = false
	if tree == null:
		return false
	var settings: Node = tree.root.get_node_or_null("Settings")
	var app: Node = tree.root.get_node_or_null("App")
	if settings == null or app == null or not bool(settings.get("pad_rumble")):
		return false
	if int(app.get("last_device")) != InputGlyphs.Device.PAD:
		return false
	Input.start_joy_vibration(int(app.get("last_pad")), kind.x, kind.y, kind.z)
	fired = true
	return true
