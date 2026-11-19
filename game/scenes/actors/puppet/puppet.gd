class_name Puppet
extends Node3D
## 程序人偶：在正式角色模型（docs/ART_REQUESTS.md 第 1、2 項）到位前頂替，用程式動畫。
## 關節是 Node3D 樞紐（不是 Skeleton3D），膠囊肢體掛在樞紐上；角色面向 -Z。
##
## 對外介面固定，之後換成有骨架的模型＋AnimationTree 時，外部（PlayerController 等）不用改：
##   set_move_speed(m/s)、play_action("dodge"|"attack"|"shoot"|"reach"|"give")、current_state() ∈ STATES、hand("L"|"R")
##   公會大廳的人：pose（站著不動的時候換成坐、笑、累垮）、carry（扛著東西：左手扶在左肩上，腳照常走）
## STATES 也就是將來 AnimationTree 狀態機的狀態名。
##
## 正式模型：設 character_id（"noen"、"sheila"…），CharacterModels 找得到匯入過的 GLB 就用模型＋AnimationPlayer，
## 找不到（或模型沒有骨架）就用程序人偶。模型缺的動作：閃避退回整個人前滾、其他退回 idle。
## 碰撞、AI、弱點判定都不跟模型走（04-architecture「角色模型接入點」）。

## 走路或跑步時，每隻腳落地的那一刻發一次（腳步聲照這個播）
signal footfall

const STATES: PackedStringArray = ["idle", "walk", "run", "dodge", "attack", "shoot", "reach", "give", "nod", "bow", "point", "chest", "shrug", "fist", "wave", "fumble",
	"roar", "gaze", "kneel", "flinch", "punch", "hammer", "collapse"]
const WALK_MIN_SPEED: float = 0.3
## 這個速度以上用跑的動作。諾恩平常移動 3.4 m/s 是小跑：以前用「走路」的動作加速到 1.6 倍，腿還是跟不上，
## 看起來在地上滑（Jacky 2026-11-14：「走路的音效跟走路速度差很多」）。
const RUN_MIN_SPEED: float = 2.6
const RUN_SPEED: float = 5.8
## 模型的動作原速播放時，腳不滑的移動速度（m/s）：步幅 × 每秒幾步，從 tools/blender/common.py 的 gait() 算的
## （走路：大腿擺 ±27°、一圈 1.25 秒；跑步：±42°、一圈 0.75 秒；腿長約 0.88 m）
const WALK_CLIP_SPEED: float = 1.3
const RUN_CLIP_SPEED: float = 3.2
## 一圈步態（0～1）裡腳落地的兩個時間點：大腿擺到最前面的那一刻
const FOOT_CONTACTS: PackedFloat32Array = [0.25, 0.75]
const ACTION_TIME: Dictionary = {"dodge": 0.35, "attack": 0.55, "shoot": 0.9, "reach": 1.0, "give": 1.25,
	# 對話的手勢（DialogueDB.ACTS；模型的動作在 social_actions）
	"nod": 0.9, "bow": 1.4, "point": 1.3, "chest": 1.4, "shrug": 1.3, "fist": 1.1, "wave": 1.5,
	# 席菈走到瘴氣邊上慌張地找防毒面具（social_actions 的 fumble）
	"fumble": 1.2,
	# 怪物（魔像、樹人）自己的動作（tools/blender/common.py 的 monster_actions）：吼、凝視、跪照那一段要多久縮放播（play_action 的 seconds），
	# 直拳與兩手砸停在舉到頂（MONSTER_APEX）等前兆走完（pause_at）
	"roar": 2.2, "gaze": 2.0, "kneel": 2.0, "flinch": 0.5, "punch": 1.25, "hammer": 1.5,
	# 倒下：從跪著垮下去（0.9 秒垮到底，之後停著）
	"collapse": 2.0}
## 怪物出招的兩段動作「舉到頂」在第幾秒（tools/blender/common.py 的 MONSTER_APEX 要一樣）；舉到頂之後 STRIKE_LEAD 秒打到
const MONSTER_APEX: Dictionary = {"punch": 0.42, "hammer": 0.55}
const STRIKE_LEAD: float = 0.19
## 對話的手勢（站著才做：坐著、躺著、走著的人不做）
const GESTURES: PackedStringArray = ["nod", "bow", "point", "chest", "shrug", "fist", "wave"]
## 講話時頭動多少（弧度；點頭、左右轉、歪頭）與動起來／停下來多快（每秒）
const NOD_AMP: Vector3 = Vector3(0.075, 0.05, 0.04)
const TALK_EASE: float = 5.0
## 低頭／抬頭多少（弧度）與轉過去多快（每秒）
const HEAD_TILT: Dictionary = {"": 0.0, "down": -0.38, "up": 0.16}
const TILT_SPEED: float = 1.6
## 站著不動的時候可以換成的樣子（模型的循環動作；程式人偶只會坐）
const POSES: PackedStringArray = ["", "sit", "sit_hunch", "sit_drink", "laugh", "slump", "down_back", "down_front", "brew"]
## 「釋放」的姿勢播多久。它不是 action：疊在站姿／走路／出手上面，不佔出手與閃避（放完同一幀照樣能出手）
const RELEASE_POSE_TIME: float = 0.36
## 模型的手骨頭在手腕：手上的掛點往指尖移這麼多（掌心）
const MODEL_PALM_OFFSET: float = 0.07
const HIP_HEIGHT: float = 0.92
const THIGH_LEN: float = 0.44
const SHIN_LEN: float = 0.44
const UPPER_ARM_LEN: float = 0.3
const FOREARM_LEN: float = 0.28
## 坐姿的骨盆高度（座面約 0.44 m）
const SIT_HIP_HEIGHT: float = 0.5

@export var coat_color: Color = Color(0.16, 0.15, 0.17)
@export var trim_color: Color = Color(0.3, 0.24, 0.18)
@export var skin_color: Color = Color(0.62, 0.52, 0.45)

## 躺姿：""＝站著、"back"＝仰躺（車上的傷者，頭朝 +Z）、"front"＝趴著（第 3 章趴在水溝裡，頭朝 -Z＝面向的方向、臉朝下）。
## 只在程序人偶上；中心在骨盆。
@export var lying: String = ""
## 坐姿（第 2 章黎歐坐在主椅上）：骨盆降到 SIT_HIP_HEIGHT、大腿往前平放、小腿垂直、手放在膝上。只在程序人偶上。
@export var sitting: bool = false
## 正式模型 id（CharacterModels.path_for）；空字串＝程序人偶
@export var character_id: String = ""
## 沒在走、沒在做一次性動作的時候的樣子（POSES）：""＝平常站著。模型沒有那段動作就照平常站
var pose: String = ""
## 扛著東西（魔像核心）：站、走、跑都換成左手舉到左肩上扶著的版本；模型沒有就照平常
var carry: bool = false
## 直接指定模型場景（測試、工具）；優先於 character_id
var model_scene: PackedScene = null
## 用模型時：模型根節點、動畫播放器、骨架；用程序人偶時都是 null
var model: Node3D = null
var anim: AnimationPlayer = null
var skeleton: Skeleton3D = null
## 模型目前播的動作（測試用）
var model_animation: String = ""

var move_speed: float = 0.0
var action: String = ""
var action_time: float = 0.0
## 出手動作播多快（1＝原速）。只影響 "attack"；麻痺被反轉時玩家把它調快
var attack_speed: float = 1.0
## 連段的第幾下（0、1、2）：模型有 attack2／attack3 那兩段動作就播（橫掃、收尾的斜劈），沒有就都播第一下。
## 程式人偶三下都是同一個姿勢。出手的人在 play_action("attack") 之前寫。
var attack_variant: int = 0
## 「釋放」的姿勢還剩幾秒（0＝沒有在播）
var release_left: float = 0.0
## 一次性動作停在第幾秒（< 0＝沒有停；hold_action）
var _hold_at: float = -1.0
## 一次性動作播到第幾秒就停住（< 0＝不停；pause_at），release_hold() 放開
var _pause_at: float = -1.0
## 一次性動作播多快（play_action 的 seconds 算的；出手另外看 attack_speed）
var _rate: float = 1.0
## play_action 之後下一次套姿勢要從頭播（同一段動作還在播的時候又叫一次）
var _restart: bool = false
var phase: float = 0.0
## 上一幀的 gait_cycle()（-1＝那時候不在走）
var _last_cycle: float = -1.0
var breath: float = 0.0
## 正在講話（對話時 TalkActing 設）：頭會點、會晃。停下來的時候慢慢回到原本的樣子
var talking: bool = false
var _talk_w: float = 0.0
## 講這一句時頭低著還是抬著（HEAD_TILT 的 key；TalkActing 設）
var head: String = ""
var _tilt: float = 0.0

## true＝模型吃場景的光、平塗（toon 漫射）——Jacky 2026-11-13 看了兩種的圖選的（「會受環境光影響比較好」）。
## false＝照原檔（VRoid 範例角色是「不受光」：暗的地方人還是亮的）；只剩開發旗標 `-- --char-unlit` 會關（Game 讀）。
static var lit_models: bool = true

## 關節名 -> Node3D
var joints: Dictionary = {}
var _roll: Node3D
## 骨架座標裡角色的背後是哪邊：正常 +Z；模型臉朝 +Z、被轉了半圈的話是 −Z
var _model_back: Vector3 = Vector3.BACK
var _coat: MeshInstance3D


func _ready() -> void:
	if model_scene == null:
		model_scene = CharacterModels.scene_for(character_id)
	if model_scene != null and _build_model():
		return
	_build()


func uses_model() -> bool:
	return model != null


## 這一刻頭動了多少（0～1）：講話時 1，講完慢慢回到 0
func talk_weight() -> float:
	return smoothstep(0.0, 1.0, _talk_w)


## 頭現在低著（負）或抬著（正）多少弧度
func head_tilt() -> float:
	return _tilt


## 疊在動作上面的頭的角度（角色自己的座標）：講話時的點頭晃頭 × talk_weight ＋ 低頭／抬頭
func head_offset() -> Vector3:
	return nod_angles() * talk_weight() + Vector3(_tilt, 0.0, 0.0)


## 講話時頭的角度（點頭、左右轉、歪頭；角色自己的座標，乘上 talk_weight 才是真的轉多少）：
## 幾個不同快慢的波疊起來，不會一直同一個節奏
func nod_angles() -> Vector3:
	var t: float = breath
	return Vector3(
		NOD_AMP.x * (0.6 * sin(t * TAU * 2.1) + 0.4 * sin(t * TAU * 3.4 + 1.0)) - NOD_AMP.x * 0.3,
		NOD_AMP.y * sin(t * TAU * 0.7 + 0.5),
		NOD_AMP.z * sin(t * TAU * 1.1 + 2.0))


## head_offset() 換到骨架的座標（模型被轉了半圈的話左右、前後反過來）
func head_offset_skeleton() -> Vector3:
	var a: Vector3 = head_offset()
	return a if _model_back.z > 0.0 else Vector3(-a.x, a.y, -a.z)


## 這個人現在能不能做對話的手勢：站著、沒在走、沒在做別的動作
func can_gesture() -> bool:
	return pose == "" and lying == "" and not sitting and current_state() == "idle"


func _process(delta: float) -> void:
	advance(delta)


func set_move_speed(speed: float) -> void:
	move_speed = maxf(speed, 0.0)


## 播放一次性動作（閃避、攻擊）；播完回到移動狀態。seconds＞0＝整段縮放成這麼久（魔像吼多久、跪多久照那一段的時間）。
func play_action(action_name: String, seconds: float = -1.0) -> void:
	if not ACTION_TIME.has(action_name):
		push_error("Puppet: 沒有動作 %s" % action_name)
		return
	action = action_name
	action_time = 0.0
	_hold_at = -1.0
	_pause_at = -1.0
	_rate = float(ACTION_TIME[action_name]) / seconds if seconds > 0.0 else 1.0
	_restart = true


## 怪物出招（punch、hammer）：從舉起來開始播、舉到頂停住，前兆剩 STRIKE_LEAD 秒時 release_hold() 打下去；
## 前兆比「舉到頂＋STRIKE_LEAD」還短（狂暴、難度高）就整段播快、不停。
func wind_up(action_name: String, telegraph_sec: float) -> void:
	var apex: float = float(MONSTER_APEX[action_name])
	var need: float = apex + STRIKE_LEAD
	if telegraph_sec >= need:
		play_action(action_name)
		pause_at(apex)
	else:
		play_action(action_name, float(ACTION_TIME[action_name]) * telegraph_sec / need)


## 正在播的一次性動作播到第 at_sec 秒（動作自己的秒數，不管縮放）就停住，等 release_hold()（怪物舉到頂等前兆走完）。
func pause_at(at_sec: float) -> void:
	_pause_at = at_sec


## 一次性動作停下來、回到移動狀態（吼到一半被打倒之類）。
func stop_action() -> void:
	action = ""
	action_time = 0.0
	_hold_at = -1.0
	_pause_at = -1.0


## 把一次性動作停在某一刻不動（魔像舉著拳頭等在那裡）：at_sec＝動作開始後第幾秒的姿勢。release_hold() 放開，從那一刻接著播完。
func hold_action(action_name: String, at_sec: float) -> void:
	play_action(action_name)
	action_time = at_sec
	_hold_at = at_sec


func release_hold() -> void:
	_hold_at = -1.0
	_pause_at = -1.0


## 停在某一刻等著（hold_action、pause_at 停住了）
func is_holding() -> bool:
	return action != "" and _hold_at >= 0.0


## 釋放的那一下：先縮、再把兩手往兩邊甩開。滾到一半不擺（看不出來）。
## 程序人偶＝疊在目前姿勢上；模型＝有 `release` 這段動作就播它（這 0.36 秒蓋過其他動作），沒有就沒有姿勢。
func play_release() -> void:
	release_left = RELEASE_POSE_TIME


func is_releasing() -> bool:
	return release_left > 0.0


func current_state() -> String:
	if action != "":
		return action
	if move_speed >= RUN_MIN_SPEED:
		return "run"
	if move_speed >= WALK_MIN_SPEED:
		return "walk"
	return "idle"


func hand(side: String) -> Node3D:
	return joints.get("hand_" + side) as Node3D


## 人偶的關節；用模型時是對應骨頭上的掛點（第一次有人要的時候才做），模型沒有那根骨頭回傳 null。
func joint(joint_name: String) -> Node3D:
	var j: Node3D = joints.get(joint_name) as Node3D
	if j == null and model != null:
		j = _model_joint(joint_name)
	return j


## 關節這一幀在世界的哪裡。模型的掛點（BoneAttachment3D）要等這一幀全部的 _process 跑完才跟上骨架，
## 在 _process 裡讀它的位置會慢一幀；要貼著這一幀的姿勢的東西（劍光）用這個，從骨架現算。
func joint_now(joint_name: String) -> Transform3D:
	var j: Node3D = joint(joint_name)
	if j == null:
		return global_transform
	var att: BoneAttachment3D = j.get_parent() as BoneAttachment3D
	if att == null or skeleton == null or att.bone_idx < 0:
		return j.global_transform
	return skeleton.global_transform * skeleton.get_bone_global_pose(att.bone_idx) * j.transform


## 模型上對應人偶關節的掛點：骨頭上的 BoneAttachment3D 底下再一層 Node3D，轉成跟人偶的關節同一個方向——
## 手臂、腿、手：−Y 沿著骨頭往下一節（手＝往指尖）、−Z 朝角色的前面；其他（骨盆、胸、頭）跟模型同方向。
## 這樣掛在上面的東西（劍、手弩）不用分人偶還是模型。
## 每個模型骨頭自己的軸不一樣（自製的 +Y 沿著骨頭；VRM 轉來的不是），所以從休息姿勢算，不假設。
func _model_joint(joint_name: String) -> Node3D:
	var bone: int = CharacterModels.find_joint_bone(skeleton, joint_name)
	if bone < 0:
		return null
	var rest: Transform3D = skeleton.get_bone_global_rest(bone)
	var to_bone: Basis = rest.basis.orthonormalized().inverse()
	# 模型被轉了半圈（_build_model）的話，骨架座標裡角色的背後是 −Z
	var want: Basis = Basis.IDENTITY if _model_back.z > 0.0 else Basis(Vector3.UP, PI)
	var offset := Vector3.ZERO
	var axis: Array = CharacterModels.JOINT_AXIS.get(joint_name, []) as Array
	if axis.size() == 2:
		var a: int = CharacterModels.find_joint_bone(skeleton, str(axis[0]))
		var b: int = CharacterModels.find_joint_bone(skeleton, str(axis[1]))
		if a >= 0 and b >= 0:
			var dir: Vector3 = skeleton.get_bone_global_rest(b).origin - skeleton.get_bone_global_rest(a).origin
			if dir.length() > 0.001:
				dir = dir.normalized()
				var y: Vector3 = -dir
				var z: Vector3 = _model_back - y * y.dot(_model_back)
				if z.length() < 0.01:
					var right: Vector3 = Vector3.UP.cross(_model_back)
					z = right - y * y.dot(right)
				z = z.normalized()
				want = Basis(y.cross(z), y, z)
				if joint_name.begins_with("hand_"):
					offset = dir * MODEL_PALM_OFFSET  # 手骨頭在手腕：往指尖移到掌心
	var att := BoneAttachment3D.new()
	att.name = "Attach_" + joint_name
	att.bone_name = skeleton.get_bone_name(bone)
	skeleton.add_child(att)
	var j := Node3D.new()
	j.name = joint_name
	j.transform = Transform3D(to_bone * want, to_bone * offset)
	att.add_child(j)
	joints[joint_name] = j
	return j


## 推進動畫並套用姿勢（_process 會呼叫；測試直接呼叫）。
func advance(delta: float) -> void:
	breath += delta
	# 步頻跟速度走：走路約 1.8 步／秒，跑步約 2.8 步／秒（一個 phase 週期＝兩步）
	var speed_t: float = clampf(move_speed / RUN_SPEED, 0.0, 1.0)
	if move_speed >= WALK_MIN_SPEED:
		phase = fmod(phase + delta * TAU * lerpf(0.9, 1.4, speed_t), TAU)
	if action != "" and _hold_at >= 0.0:
		action_time = _hold_at
	elif action != "":
		action_time += delta * (attack_speed if action == "attack" else _rate)
		if _pause_at >= 0.0 and action_time >= _pause_at:
			action_time = _pause_at
			_hold_at = _pause_at
		elif action_time >= float(ACTION_TIME[action]):
			action = ""
			action_time = 0.0
	_talk_w = move_toward(_talk_w, 1.0 if talking else 0.0, delta * TALK_EASE)
	_tilt = move_toward(_tilt, float(HEAD_TILT.get(head, 0.0)), delta * TILT_SPEED)
	var release_t: float = 1.0 - release_left / RELEASE_POSE_TIME
	release_left = maxf(release_left - delta, 0.0)
	if model != null:
		_animate_model()
	else:
		_pose(speed_t)
		if release_t < 1.0 and action != "dodge" and lying == "" and not sitting:
			_pose_release(release_t)
	_emit_footfalls()


## 步態走到一圈的哪裡（0～1，一圈＝左右腳各一步）；不是在走路或跑步就回傳 -1。
func gait_cycle() -> float:
	var state: String = current_state()
	if state != "walk" and state != "run":
		return -1.0
	if model == null:
		return phase / TAU
	if anim == null or not anim.is_playing() or anim.current_animation_length <= 0.0 \
			or model_animation != CharacterModels.find_animation(anim, state):
		return -1.0
	return fposmod(anim.current_animation_position / anim.current_animation_length, 1.0)


## 這一幀步態跨過落地的時間點就發 footfall。剛開始走、剛換動作的那一幀不算（位置是跳過去的，不是走過去的）。
func _emit_footfalls() -> void:
	var cycle: float = gait_cycle()
	var before: float = _last_cycle
	_last_cycle = cycle
	if cycle < 0.0 or before < 0.0:
		return
	var moved: float = fposmod(cycle - before, 1.0)
	if moved <= 0.0 or moved > 0.5:
		return
	for contact: float in FOOT_CONTACTS:
		if fposmod(contact - before, 1.0) <= moved and fposmod(contact - before, 1.0) > 0.0:
			footfall.emit()


## 模型：依狀態換動作；缺的動作退回（閃避＝整個人前滾，其他＝idle）。
func _animate_model() -> void:
	var state: String = current_state()
	var name_found: String = CharacterModels.find_animation(anim, state)
	if state == "idle" and pose != "":
		var posed: String = CharacterModels.find_animation(anim, pose)
		name_found = posed if posed != "" else name_found
	elif carry and state in ["idle", "walk", "run"]:
		var carried: String = CharacterModels.find_animation(anim, state + "_carry")
		name_found = carried if carried != "" else name_found
	if state == "attack" and attack_variant > 0:
		var variant: String = CharacterModels.find_animation(anim, "attack%d" % (attack_variant + 1))
		name_found = variant if variant != "" else name_found
	if release_left > 0.0 and state != "dodge":
		var release_name: String = CharacterModels.find_animation(anim, "release")
		if release_name != "":
			name_found = release_name
			state = "release"
	_roll.rotation.x = 0.0
	_roll.position = Vector3.ZERO
	if name_found == "" and state == "dodge":
		var t: float = clampf(action_time / float(ACTION_TIME["dodge"]), 0.0, 1.0)
		_roll.position = Vector3(0, 0.5 - 0.35 * sin(t * PI), 0)
		_roll.rotation.x = -TAU * ease(t, -1.8)
	if name_found == "":
		name_found = CharacterModels.find_animation(anim, "idle")
	if name_found == "":
		return
	if model_animation != name_found:
		model_animation = name_found
		anim.play(name_found, blend_for(state))
	elif _restart and state == action:
		# 同一段動作再播一次（連著被砍兩下）：從頭開始
		anim.seek(0.0, true)
	_restart = false
	# 步頻跟速度走：腳踩在地上的那一段，腳往後的速度要跟人往前的速度差不多
	match state:
		"walk":
			anim.speed_scale = clampf(move_speed / WALK_CLIP_SPEED, 0.6, 1.8)
		"run":
			anim.speed_scale = clampf(move_speed / RUN_CLIP_SPEED, 0.85, 1.45)
		"attack":
			# 出手變快（麻痺、流血被反轉）動作也要跟著快，不然只播得到舉劍的前半段、看不到劈下去
			anim.speed_scale = attack_speed
		_:
			anim.speed_scale = _rate if state == action else 1.0
	if _hold_at >= 0.0 and state == action:
		# 停在那一刻：不混合、不往前播
		anim.play(name_found, 0.0)
		anim.speed_scale = 0.0
		anim.seek(_hold_at, true)


## 換動作時跟前一個動作混多久（秒）。出手的拉開只有 0.09 秒（0.55 秒的 16%），混 0.15 秒的話拉開還沒到頂就被往下劈蓋掉，
## 看起來像劍直接從腰間劈出去；釋放也是一下子的。
const BLEND_SEC: float = 0.15
const QUICK_BLEND_SEC: float = 0.05


static func blend_for(state_name: String) -> float:
	return QUICK_BLEND_SEC if state_name in ["attack", "release"] else BLEND_SEC


## 換成正式模型；沒有骨架就放棄（回傳 false，用程序人偶）。
func _build_model() -> bool:
	var inst: Node3D = model_scene.instantiate() as Node3D
	if inst == null:
		return false
	var skels: Array[Node] = inst.find_children("*", "Skeleton3D", true, false)
	if skels.is_empty():
		push_warning("Puppet: 模型 %s 沒有骨架，改用程序人偶" % character_id)
		inst.free()
		return false
	_roll = Node3D.new()
	_roll.name = "Roll"
	add_child(_roll)
	model = inst
	model.name = "Model"
	_roll.add_child(model)
	skeleton = skels[0] as Skeleton3D
	# 模型自己臉朝 +Z（glTF 的慣例；Godot 與人偶的正面是 −Z）就轉半圈：不然往前走看到的是臉、往後走看到的是背
	_model_back = Vector3.BACK
	if CharacterModels.facing(skeleton, inst).z > 0.3:
		model.rotation.y = PI
		_model_back = Vector3.FORWARD
	if lit_models:
		make_lit(model)
	var head_bone: int = CharacterModels.find_joint_bone(skeleton, "head")
	if head_bone >= 0:
		var nodder := TalkNod.new()
		nodder.name = "TalkNod"
		nodder.puppet = self
		nodder.bone = head_bone
		skeleton.add_child(nodder)
	var players: Array[Node] = inst.find_children("*", "AnimationPlayer", true, false)
	anim = players[0] as AnimationPlayer if not players.is_empty() else null
	if anim != null:
		for st: String in CharacterModels.LOOPING:
			var n: String = CharacterModels.find_animation(anim, st)
			if n != "":
				anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
	# 掛點：手骨骼上的掛點（方向跟人偶的手一樣，見 _model_joint）；找不到骨骼就放在大約的位置
	for side: String in ["L", "R"]:
		if _model_joint("hand_" + side) == null:
			push_warning("Puppet: 模型 %s 找不到 %s 手骨骼，掛點用估計位置" % [character_id, side])
			var holder := Node3D.new()
			holder.position = Vector3(-0.3 if side == "L" else 0.3, 0.95, 0.0)
			model.add_child(holder)
			holder.name = "Hand" + side
			joints["hand_" + side] = holder
	_animate_model()
	return true


## 把模型每個 surface 的材質換成一份「吃場景的光、平塗」的複本（原本的資源不動，別的角色不受影響）。
## 回傳換了幾個 surface。光澤、法線、AO 都關掉：漫畫風的人物只要亮面與暗面兩階。
static func make_lit(root: Node) -> int:
	var count: int = 0
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = node as MeshInstance3D
		if mi.mesh == null:
			continue
		for s: int in mi.mesh.get_surface_count():
			var src: BaseMaterial3D = mi.get_active_material(s) as BaseMaterial3D
			if src == null:
				continue
			var m: BaseMaterial3D = src.duplicate() as BaseMaterial3D
			m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
			m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
			m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
			m.metallic = 0.0
			m.roughness = 1.0
			m.normal_enabled = false
			m.ao_enabled = false
			mi.set_surface_override_material(s, m)
			count += 1
	return count


func _pose(speed_t: float) -> void:
	var moving: float = clampf((move_speed - WALK_MIN_SPEED) / 0.6, 0.0, 1.0)
	var s: float = sin(phase)
	var c: float = cos(phase)
	# 移動：大腿前後擺、膝蓋在後擺時彎、手臂反向擺、骨盆上下
	var thigh_amp: float = lerpf(0.42, 0.75, speed_t) * moving
	var knee_amp: float = lerpf(0.6, 1.3, speed_t) * moving
	var arm_amp: float = lerpf(0.3, 0.7, speed_t) * moving
	var lean: float = lerpf(0.04, 0.2, speed_t) * moving
	var breathe: float = sin(breath * TAU * 0.25) * (1.0 - moving)

	_rot("thigh_L", Vector3(s * thigh_amp, 0, 0))
	_rot("thigh_R", Vector3(-s * thigh_amp, 0, 0))
	_rot("knee_L", Vector3(-maxf(-c, 0.0) * knee_amp - 0.05, 0, 0))
	_rot("knee_R", Vector3(-maxf(c, 0.0) * knee_amp - 0.05, 0, 0))
	_rot("shoulder_L", Vector3(-s * arm_amp, 0, -0.12 - 0.03 * breathe))
	_rot("shoulder_R", Vector3(s * arm_amp, 0, 0.12 + 0.03 * breathe))
	_rot("elbow_L", Vector3(0.25 + arm_amp * 0.6, 0, 0))
	_rot("elbow_R", Vector3(0.25 + arm_amp * 0.6, 0, 0))
	_rot("spine", Vector3(-lean, s * 0.08 * moving, 0))
	_rot("chest", Vector3(0.02 * breathe, -s * 0.1 * moving, 0))
	_rot("neck", Vector3(lean * 0.6, 0, 0) + head_offset())
	var hips: Node3D = joint("hips")
	if hips != null:
		hips.position.y = HIP_HEIGHT - absf(c) * 0.05 * moving + 0.006 * breathe
	if _coat != null:
		_coat.rotation.x = -lean * 0.8 - thigh_amp * 0.15
	if _roll != null:
		_roll.rotation.x = 0.0
		_roll.position = Vector3.ZERO

	if lying != "":
		_pose_lying()
		return
	if sitting or (pose.begins_with("sit") and action == "" and moving <= 0.0):
		_pose_sitting(breathe)
		return
	match action:
		"dodge":
			_pose_dodge(action_time / float(ACTION_TIME["dodge"]))
		"attack":
			_pose_attack(action_time / float(ACTION_TIME["attack"]))
		"shoot":
			_pose_shoot(action_time / float(ACTION_TIME["shoot"]))
		"reach", "give", "point", "wave", "chest", "shrug", "fist":
			_pose_reach(action_time / float(ACTION_TIME[action]), action in ["give", "shrug"])
		"nod", "bow":
			var k: float = sin(PI * action_time / float(ACTION_TIME[action]))
			_rot("spine", Vector3((-0.35 if action == "bow" else -0.05) * k, 0, 0))
			_rot("neck", Vector3(-0.3 * k, 0, 0))
		"punch", "hammer":
			# 怪物的替身：舉到頂之前算拉開、之後算劈下去（借出手的姿勢）
			var apex: float = float(MONSTER_APEX[action])
			_pose_attack(clampf(0.3 * action_time / apex if action_time < apex else 0.3 + (action_time - apex) / 0.6, 0.0, 1.0))
		"roar", "gaze", "kneel", "flinch":
			# 怪物的替身：只有上身往後仰（吼、被砍）或往前垂（凝視、跪）
			var k2: float = sin(PI * clampf(action_time / float(ACTION_TIME[action]), 0.0, 1.0))
			_rot("spine", Vector3({"roar": 0.35, "flinch": 0.2, "gaze": -0.3, "kneel": -0.5}[action] * k2, 0, 0))
		"collapse":
			# 倒下的替身：上身往前垂到底、不收回來
			_rot("spine", Vector3(-0.9 * clampf(action_time / 0.9, 0.0, 1.0), 0, 0))


## 仰躺（車上的傷者）：整個人繞骨盆轉成水平、臉朝上、頭朝 +Z，胸口慢慢起伏。
func _pose_lying() -> void:
	var breathe: float = sin(breath * TAU * 0.3)
	if lying == "front":
		_pose_prone(breathe)
		return
	_roll.basis = Basis(Vector3.RIGHT, PI * 0.5)
	# 骨盆移到原點、背貼地（身體厚度約 0.17）
	_roll.position = Vector3(0, 0.17, 0) - _roll.basis * Vector3(0, HIP_HEIGHT, 0)
	_rot("thigh_L", Vector3(0.05, 0, 0.04))
	_rot("thigh_R", Vector3(0.12, 0, -0.04))
	_rot("knee_L", Vector3(-0.1, 0, 0))
	_rot("knee_R", Vector3(-0.25, 0, 0))
	_rot("spine", Vector3.ZERO)
	_rot("chest", Vector3(0.03 * breathe, 0, 0))
	_rot("neck", Vector3(-0.15, 0, 0))
	_rot("shoulder_L", Vector3(0.05, 0, -0.12))
	_rot("shoulder_R", Vector3(0.05, 0, 0.12))
	_rot("elbow_L", Vector3(0.15, 0, 0))
	_rot("elbow_R", Vector3(0.4, 0, 0))
	if _coat != null:
		_coat.rotation.x = 0.0


## 趴著（第 3 章趴在水溝裡觀察）：整個人往前倒成水平、臉朝下、頭朝 -Z；手肘撐地、頭抬起來往前看。
func _pose_prone(breathe: float) -> void:
	_roll.basis = Basis(Vector3.RIGHT, -PI * 0.5)
	# 骨盆移到原點、肚子貼地（身體厚度約 0.17）
	_roll.position = Vector3(0, 0.17, 0) - _roll.basis * Vector3(0, HIP_HEIGHT, 0)
	_rot("thigh_L", Vector3(0.0, 0, 0.1))
	_rot("thigh_R", Vector3(0.0, 0, -0.1))
	_rot("knee_L", Vector3(-0.15, 0, 0))
	_rot("knee_R", Vector3(-0.1, 0, 0))
	_rot("spine", Vector3(0.12, 0, 0))
	_rot("chest", Vector3(0.18 + 0.02 * breathe, 0, 0))
	# 抬頭往前看
	_rot("neck", Vector3(0.7, 0, 0))
	# 手肘撐在身體前面（正角度＝手臂往身體前面抬：上臂往地面、前臂往頭的方向平放）
	_rot("shoulder_L", Vector3(1.9, 0, -0.25))
	_rot("shoulder_R", Vector3(1.9, 0, 0.25))
	_rot("elbow_L", Vector3(1.25, 0, 0))
	_rot("elbow_R", Vector3(1.25, 0, 0))
	if _coat != null:
		_coat.rotation.x = 0.0


## 坐著：大腿往前、小腿垂直、手放在膝上，外套下擺蓋在大腿上；胸口慢慢起伏。
func _pose_sitting(breathe: float) -> void:
	var hips: Node3D = joint("hips")
	if hips != null:
		hips.position.y = SIT_HIP_HEIGHT + 0.004 * breathe
	for side: String in ["L", "R"]:
		_rot("thigh_" + side, Vector3(1.5, 0, 0.06 if side == "L" else -0.06))
		_rot("knee_" + side, Vector3(-1.5, 0, 0))
	_rot("shoulder_L", Vector3(0.55, 0, -0.1))
	_rot("shoulder_R", Vector3(0.55, 0, 0.1))
	_rot("elbow_L", Vector3(0.75, 0, 0))
	_rot("elbow_R", Vector3(0.75, 0, 0))
	_rot("spine", Vector3(0.04, 0, 0))
	_rot("chest", Vector3(0.02 * breathe, 0, 0))
	_rot("neck", Vector3(-0.05, 0, 0))
	if _coat != null:
		_coat.rotation.x = 0.0
		var pivot: Node3D = _coat.get_parent() as Node3D
		pivot.rotation.x = 1.25
		_coat.scale = Vector3(1.0, 0.55, 1.0)


## 前滾：整個人繞腰部高度轉一圈，膝與手臂收起。
func _pose_dodge(t: float) -> void:
	var e: float = ease(clampf(t, 0.0, 1.0), -1.8)
	var tuck: float = sin(clampf(t, 0.0, 1.0) * PI)
	_roll.position = Vector3(0, 0.5, 0)
	_roll.rotation.x = -TAU * e
	_roll.position.y = 0.5 - 0.35 * tuck
	for side: String in ["L", "R"]:
		_rot("thigh_" + side, Vector3(1.5 * tuck, 0, 0))
		_rot("knee_" + side, Vector3(-2.0 * tuck, 0, 0))
		_rot("shoulder_" + side, Vector3(1.2 * tuck, 0, 0))
		_rot("elbow_" + side, Vector3(1.6 * tuck, 0, 0))
	_rot("spine", Vector3(0.6 * tuck, 0, 0))


## 單手舉弩（席菈）：抬手瞄準 → 停著 → 放下。
func _pose_shoot(t: float) -> void:
	var aim: float = smoothstep(0.0, 0.3, t) * (1.0 - smoothstep(0.8, 1.0, t))
	_rot("shoulder_R", Vector3(1.5 * aim, 0, 0.1))
	_rot("elbow_R", Vector3(0.25 * (1.0 - aim), 0, 0))


## 伸手往前（摸水晶）／兩手往前遞（給委託單）：伸出去 → 停著 → 收回。
func _pose_reach(t: float, both: bool) -> void:
	var r: float = smoothstep(0.0, 0.35, t) * (1.0 - smoothstep(0.75, 1.0, t))
	_rot("shoulder_R", Vector3(1.3 * r, 0, 0.12 - 0.1 * r))
	_rot("elbow_R", Vector3(0.25 + 0.2 * r, 0, 0))
	if both:
		_rot("shoulder_L", Vector3(1.3 * r, 0, -0.12 + 0.1 * r))
		_rot("elbow_L", Vector3(0.25 + 0.2 * r, 0, 0))
	_rot("spine", Vector3(-0.12 * r, 0, 0))


## 舉過頭往下劈：舉起（0～35%）→ 劈下（35～60%）→ 收回。
func _pose_attack(t: float) -> void:
	var arm: float
	var twist: float
	if t < 0.35:
		var k: float = ease(t / 0.35, 0.6)
		arm = lerpf(0.0, 2.7, k)
		twist = lerpf(0.0, 0.35, k)
	elif t < 0.6:
		var k2: float = ease((t - 0.35) / 0.25, 2.2)
		arm = lerpf(2.7, 0.55, k2)
		twist = lerpf(0.35, -0.3, k2)
	else:
		var k3: float = ease((t - 0.6) / 0.4, -1.5)
		arm = lerpf(0.55, 0.0, k3)
		twist = lerpf(-0.3, 0.0, k3)
	_rot("shoulder_R", Vector3(arm, 0, 0.1))
	_rot("elbow_R", Vector3(0.3, 0, 0))
	_rot("chest", Vector3(0.1, twist, 0))
	_rot("spine", Vector3(-0.1 + twist * 0.3, 0, 0))
	_rot("thigh_L", Vector3(0.35, 0, 0))
	_rot("knee_L", Vector3(-0.3, 0, 0))
	_rot("thigh_R", Vector3(-0.25, 0, 0))


## 釋放：縮（0～25%：兩手抱到胸前、膝蓋彎、上身往前捲）→ 炸開（25～55%：兩手往兩邊甩到水平、胸口往後挺、頭抬起來、兩腳踩開）→ 收回。
## 肩膀 x 正的＝手往前往上、z（右手正、左手負）＝往外張；脊椎 x 負的＝往前彎。
func _pose_release(t: float) -> void:
	var gather: float = 0.0
	var burst: float = 0.0
	if t < 0.25:
		gather = ease(t / 0.25, 0.5)
	elif t < 0.55:
		burst = ease((t - 0.25) / 0.3, 0.35)
		gather = 1.0 - burst
	else:
		burst = 1.0 - ease((t - 0.55) / 0.45, 1.6)
	var sink: float = maxf(gather, burst * 0.7)
	var arm_x: float = 0.9 * gather - 0.3 * burst
	var arm_z: float = 0.12 - 0.45 * gather + 1.4 * burst
	_rot("shoulder_R", Vector3(arm_x, 0, arm_z))
	_rot("shoulder_L", Vector3(arm_x, 0, -arm_z))
	_rot("elbow_R", Vector3(1.7 * gather + 0.12 * burst, 0, 0))
	_rot("elbow_L", Vector3(1.7 * gather + 0.12 * burst, 0, 0))
	_rot("spine", Vector3(-0.38 * gather + 0.2 * burst, 0, 0))
	_rot("chest", Vector3(-0.2 * gather + 0.22 * burst, 0, 0))
	_rot("neck", Vector3(-0.25 * gather + 0.35 * burst, 0, 0))
	_rot("thigh_L", Vector3(0.6 * sink, 0, -0.3 * burst))
	_rot("thigh_R", Vector3(0.6 * sink, 0, 0.3 * burst))
	_rot("knee_L", Vector3(-1.2 * sink, 0, 0))
	_rot("knee_R", Vector3(-1.2 * sink, 0, 0))
	var hips: Node3D = joint("hips")
	if hips != null:
		hips.position.y = HIP_HEIGHT - 0.16 * sink
	if _coat != null:
		_coat.rotation.x = -0.25 * gather + 0.15 * burst


func _rot(joint_name: String, r: Vector3) -> void:
	var j: Node3D = joints.get(joint_name) as Node3D
	if j != null:
		j.rotation = r


# --- 建模 -------------------------------------------------------------------

func _mat(color: Color, roughness: float = 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m


func _joint(joint_name: String, parent: Node3D, pos: Vector3) -> Node3D:
	var j := Node3D.new()
	j.name = joint_name
	j.position = pos
	parent.add_child(j)
	joints[joint_name] = j
	return j


## 在樞紐下方掛一段膠囊肢體（沿 -Y 方向，長度 length）。
func _limb(parent: Node3D, length: float, radius: float, mat: Material) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = length + radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 4
	mesh.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = Vector3(0, -length * 0.5, 0)
	parent.add_child(mi)
	return mi


func _build() -> void:
	var coat: StandardMaterial3D = _mat(coat_color)
	var trim: StandardMaterial3D = _mat(trim_color)
	var skin: StandardMaterial3D = _mat(skin_color, 0.7)
	var dark: StandardMaterial3D = _mat(Color(0.08, 0.08, 0.09))

	_roll = Node3D.new()
	_roll.name = "Roll"
	add_child(_roll)
	var hips: Node3D = _joint("hips", _roll, Vector3(0, HIP_HEIGHT, 0))

	# 長外套下擺：從腰部往下的圓錐，跟著步伐微擺
	var skirt := CylinderMesh.new()
	skirt.top_radius = 0.17
	skirt.bottom_radius = 0.36
	skirt.height = 0.9
	skirt.radial_segments = 14
	skirt.material = coat
	_coat = MeshInstance3D.new()
	_coat.name = "CoatSkirt"
	_coat.mesh = skirt
	var skirt_pivot := Node3D.new()
	skirt_pivot.name = "CoatPivot"
	hips.add_child(skirt_pivot)
	skirt_pivot.add_child(_coat)
	_coat.position = Vector3(0, -0.3, 0)

	var spine: Node3D = _joint("spine", hips, Vector3(0, 0.08, 0))
	var chest: Node3D = _joint("chest", spine, Vector3(0, 0.22, 0))
	var torso := _limb(chest, 0.26, 0.19, coat)
	torso.position = Vector3(0, 0.08, 0)
	torso.scale = Vector3(1.0, 1.0, 0.75)
	# 圍巾（暖色，讓剪影有一點顏色）
	var scarf := MeshInstance3D.new()
	var scarf_mesh := TorusMesh.new()
	scarf_mesh.inner_radius = 0.07
	scarf_mesh.outer_radius = 0.15
	scarf_mesh.material = trim
	scarf.mesh = scarf_mesh
	scarf.position = Vector3(0, 0.3, 0)
	chest.add_child(scarf)

	var neck: Node3D = _joint("neck", chest, Vector3(0, 0.34, 0))
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.125
	head_mesh.height = 0.27
	head_mesh.material = skin
	head.mesh = head_mesh
	head.position = Vector3(0, 0.14, 0)
	neck.add_child(head)
	var hair := MeshInstance3D.new()
	var hair_mesh := SphereMesh.new()
	hair_mesh.radius = 0.132
	hair_mesh.height = 0.27
	hair_mesh.material = dark
	hair.mesh = hair_mesh
	hair.position = Vector3(0, 0.16, 0.025)
	neck.add_child(hair)

	for side: String in ["L", "R"]:
		var x: float = -1.0 if side == "L" else 1.0
		var shoulder: Node3D = _joint("shoulder_" + side, chest, Vector3(0.23 * x, 0.27, 0))
		_limb(shoulder, UPPER_ARM_LEN, 0.065, coat)
		var elbow: Node3D = _joint("elbow_" + side, shoulder, Vector3(0, -UPPER_ARM_LEN, 0))
		_limb(elbow, FOREARM_LEN, 0.055, coat)
		var hand_j: Node3D = _joint("hand_" + side, elbow, Vector3(0, -FOREARM_LEN - 0.04, 0))
		var hand_mesh := SphereMesh.new()
		hand_mesh.radius = 0.05
		hand_mesh.height = 0.1
		hand_mesh.material = skin
		var hand_mi := MeshInstance3D.new()
		hand_mi.mesh = hand_mesh
		hand_j.add_child(hand_mi)

		var thigh: Node3D = _joint("thigh_" + side, hips, Vector3(0.1 * x, -0.04, 0))
		_limb(thigh, THIGH_LEN, 0.08, dark)
		var knee: Node3D = _joint("knee_" + side, thigh, Vector3(0, -THIGH_LEN, 0))
		_limb(knee, SHIN_LEN, 0.065, dark)
		var boot := MeshInstance3D.new()
		var boot_mesh := BoxMesh.new()
		boot_mesh.size = Vector3(0.11, 0.08, 0.24)
		boot_mesh.material = dark
		boot.mesh = boot_mesh
		boot.position = Vector3(0, -SHIN_LEN - 0.02, -0.05)
		knee.add_child(boot)

	_pose(0.0)
