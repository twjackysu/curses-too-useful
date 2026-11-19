class_name TalkActing
extends Node
## 對話的演出（TalkCamera 底下的子節點，用它登記的 `cast`）：每一句開頭照對話資料讓講話的人
## 冒漫符（`emote`，MangaMark）、做手勢（`act`，Puppet 的一次性動作；坐著、躺著、走著的人不做），
## 字還在浮現的那段時間講話的人頭會點、會晃（`Puppet.talking`）；寫了 `head` 的那一句低著頭／抬起頭（`Puppet.head`）。
## 換下一句前一句的漫符就收起來、頭回到原本的樣子。
## 跟 TalkCamera 一樣只看 `Game.dialogue`，不接訊號。

## 講話的時間＝這一句的字數 ÷ 對話框浮現的速度，最短這麼久
const MIN_TALK_SEC: float = 0.5

var camera: TalkCamera
var _line: String = ""
var _marks: Array[MangaMark] = []
## 最近一個漫符的聲音（測試用）
var last_sound: String = ""
var _speaking: Puppet = null
var _talk_left: float = 0.0
## 角色 → 他的 Puppet（找一次就記住）
var _puppets: Dictionary = {}


## 這個角色身上的 Puppet（諾恩、席菈、Npc、躺在地上的人的外框都包著一個）
func puppet_of(who: Node3D) -> Puppet:
	if who == null:
		return null
	if _puppets.has(who) and is_instance_valid(_puppets[who] as Object):
		return _puppets[who] as Puppet
	var found: Puppet = _find_puppet(who)
	_puppets[who] = found
	return found


static func _find_puppet(n: Node) -> Puppet:
	if n is Puppet:
		return n as Puppet
	for c: Node in n.get_children():
		var p: Puppet = _find_puppet(c)
		if p != null:
			return p
	return null


func marks() -> Array[MangaMark]:
	var out: Array[MangaMark] = []
	for m: MangaMark in _marks:
		if is_instance_valid(m) and not m.is_leaving():
			out.append(m)
	return out


func _physics_process(delta: float) -> void:
	var r: DialogueRunner = Game.dialogue
	var running: bool = r != null and r.is_running()
	var key: String = "%s/%s" % [r.dialogue_id, r.node_id] if running else ""
	if key != _line:
		_line = key
		_on_line(r if running else null)
	_talk_left -= delta
	if _speaking != null and is_instance_valid(_speaking):
		_speaking.talking = _talk_left > 0.0


func _on_line(r: DialogueRunner) -> void:
	for m: MangaMark in _marks:
		if is_instance_valid(m):
			m.dismiss()
	_marks.clear()
	if _speaking != null and is_instance_valid(_speaking):
		_speaking.talking = false
		_speaking.head = ""
	_speaking = null
	_talk_left = 0.0
	if r == null or camera == null:
		return
	var n: Dictionary = r.current()
	var who: Node3D = camera.member(str(n.get("speaker", "")))
	if who == null:
		return
	var puppet: Puppet = puppet_of(who)
	var emote: String = str(n.get("emote", ""))
	if emote != "":
		var m: MangaMark = MangaMark.pop(emote, who, puppet)
		if m != null:
			_marks.append(m)
			last_sound = str(MangaMark.SOUND.get(emote, ""))
			Sfx.play_flat(who, last_sound, MangaMark.SOUND_DB)
	if puppet == null:
		return
	var act: String = str(n.get("act", ""))
	if act != "" and puppet.can_gesture() and not who.has_meta(TalkCamera.DROP_META):
		puppet.play_action(act)
	_speaking = puppet
	puppet.head = str(n.get("head", ""))
	_talk_left = maxf(float(tr(r.current_text()).length()) / DialogueBox.CHARS_PER_SEC, MIN_TALK_SEC)
	puppet.talking = true
