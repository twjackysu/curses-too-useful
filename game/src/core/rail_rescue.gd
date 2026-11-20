class_name RailRescue
extends RefCounted
## 斷軌事件的規則（docs/story/chapter-1-expanded.md「斷軌上的第五只杯子」；純邏輯，場景在 RailEvent）。
## 兩條救車的走法共用一台車、一個結果：
##   坡頂放繩（top）：纏住絞盤的三股藤要在 VINE_WINDOW 秒內砍完——照平常的出手速度砍不完（第三刀落在 1.1 秒），
##     要先踩網吃麻痺（反轉成出手加速）；帶著暖泥塞只要砍兩股（最後一股用它把掛繩彈過去）。沒砍完藤會長回來。
##   坡底接車（bottom）：棧橋旁邊要先有能踩上去的東西——樹人在枯木旁砸地把它震倒（tree）、樹人不在了自己砍倒（tree）、
##     或把帶來的鐵盾架在斷掉的窄軌上（shield）。
## 準備好之後最後一步（席菈射車扣、阿展拉煞車）由 RailEvent 演；這裡只管「準備好了沒」。

const VINES: int = 3
const VINE_WINDOW: float = 0.9
## 樹人砸地離枯木這麼近就震倒它；樹人不在了，自己砍這麼多刀也會倒
const SLAM_REACH: float = 4.2
const TREE_CHOPS: int = 3

## 帶著暖泥塞（還沒用掉）
var has_plug: bool = false
var vines_cut: int = 0
var rope_free: bool = false
## 用掉暖泥塞了（RailEvent 看到就從身上拿掉一瓶）
var plug_used: bool = false
## 棧橋旁邊架好的東西：""＝還沒有、"tree"、"shield"
var ramp: String = ""
var tree_chops: int = 0
var _window_left: float = 0.0


## 要砍幾股
func vines_needed() -> int:
	return VINES - 1 if has_plug else VINES


## 砍中一股。回傳這一刀之後繩子放下來了沒
func chop_vine() -> bool:
	if rope_free:
		return true
	if vines_cut == 0:
		_window_left = VINE_WINDOW
	vines_cut += 1
	if vines_cut >= vines_needed():
		rope_free = true
		plug_used = has_plug
	return rope_free


## 每幀叫。回傳 true＝來不及砍完，藤長回來了（從頭來）
func tick(delta: float) -> bool:
	if rope_free or vines_cut == 0:
		return false
	_window_left -= delta
	if _window_left > 0.0:
		return false
	vines_cut = 0
	return true


## 樹人砸地（slam_at）離枯木（tree_at）夠近就震倒。回傳這一下震倒了沒
func slam(slam_at: Vector3, tree_at: Vector3) -> bool:
	if ramp != "" or Vector2(slam_at.x - tree_at.x, slam_at.z - tree_at.z).length() > SLAM_REACH:
		return false
	ramp = "tree"
	return true


## 自己砍枯木（樹人還在的時候砍不倒：can_fell＝false）。回傳這一刀砍倒了沒
func chop_tree(can_fell: bool) -> bool:
	if ramp != "" or not can_fell:
		return false
	tree_chops += 1
	if tree_chops < TREE_CHOPS:
		return false
	ramp = "tree"
	return true


## 把盾架上去。回傳架上去了沒（已經有東西就不用）
func place_shield() -> bool:
	if ramp != "":
		return false
	ramp = "shield"
	return true


## 哪一條走法準備好了（兩條都好了算先好的那一條由 RailEvent 決定）
func top_ready() -> bool:
	return rope_free


func bottom_ready() -> bool:
	return ramp != ""
