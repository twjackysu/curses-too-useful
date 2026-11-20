class_name SeraChatter
extends Node
## 席菈跟 HUD 之間每一關都一樣的那幾句：玩家按鍵向她要藥（答應／還在裝）、裝好了喊一聲、
## 左上多一行「可以向她要哪一瓶（有兩瓶時多寫換的按鍵）」或「她還在裝，還要幾秒」。有她的關卡各掛一個（腐敗之森、廢棄祭壇）；關卡自己的劇情台詞不在這裡。

const ASK_HINT: String = "HINT_ASK_SERA"
## 可以要的有兩瓶：多寫換一瓶的按鍵
const ASK_PICK_HINT: String = "HINT_ASK_SERA_PICK"
const ASK_WAIT_HINT: String = "HINT_ASK_SERA_WAIT"

var sera: Sera
var hud: Hud
## 關卡要用左上那一行寫別的（Boss 戰的「擋在席菈前面」）：設成 true，這裡先不寫
var hint_paused: bool = false


static func attach(level: Node, p_sera: Sera, p_hud: Hud) -> SeraChatter:
	var c := SeraChatter.new()
	c.name = "SeraChatter"
	c.sera = p_sera
	c.hud = p_hud
	p_sera.asked.connect(c._on_asked)
	p_sera.reloaded.connect(c._on_reloaded)
	p_sera.pick_changed.connect(c._on_pick_changed)
	level.add_child(c)
	return c


func _physics_process(_delta: float) -> void:
	if hint_paused or not Game.session.in_story():
		return
	if not sera.ask_enabled:
		hud.set_extra_hint("")
	elif sera.brain.ask_left > 0.0:
		hud.set_extra_hint(ASK_WAIT_HINT, {"sec": ceili(sera.brain.ask_left)})
	else:
		hud.set_extra_hint(ASK_PICK_HINT if sera.ask_extra != "" else ASK_HINT, {"vial": tr(vial_name(sera.ask_choice()))})


## 這一瓶的藥名（翻譯 key；statuses.json 的來源寫的 name，沒寫就是空的）
static func vial_name(source_id: String) -> String:
	return str(StatusRules.load_default().source(source_id).get("name", ""))


## 玩家按鍵向她要藥：答應了喊一句（要的是哪一瓶就回那一瓶的話），還在裝上一瓶也回一句（不然按了沒反應像壞掉）。
func _on_asked(ok: bool) -> void:
	var line: String = str(StatusRules.load_default().source(sera.ask_choice()).get("ask_bark", "BARK_SERA_ASK"))
	hud.show_bark(sera, line if ok else "BARK_SERA_RELOADING", 2.2, Sera.NAME_KEY)


## 換了要哪一瓶：左上那一行下一幀就改；這裡響一聲小小的「喀」（按了有感覺）。
## 弩上裝著東西的時候她撥一下藥匣、喊出換成哪一瓶（來源的 swap_bark）；正在裝下一瓶就不喊（左上寫著還要幾秒）
func _on_pick_changed(source: String) -> void:
	Sfx.play_flat(self, "ui_tick", -8.0)
	var line: String = str(StatusRules.load_default().source(source).get("swap_bark", ""))
	if line != "" and sera.slot_full and sera.brain.ask_left <= 0.0:
		hud.show_bark(sera, line, 1.6, Sera.NAME_KEY)


## 下一瓶裝好了：她喊一聲（打架的時候不會去看左上那一行）。
func _on_reloaded() -> void:
	hud.show_bark(sera, "BARK_SERA_READY", 1.8, Sera.NAME_KEY)
