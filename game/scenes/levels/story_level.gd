class_name StoryLevel
extends Node3D
## 關卡的共用基底：地面高度、腳步聲材質。Game 只在 StoryLevel 裡累計遊戲時間。


## 地面高度（平地關卡是 0；有高低差的關卡覆寫）。
func ground_y(_p: Vector3) -> float:
	return 0.0


## 腳下是什麼（腳步聲）：Footsteps.SURFACES 裡的一個。預設石頭。
func footstep_surface(_p: Vector3) -> String:
	return "stone"


## 關卡自己的過場（例：祭壇戰後那段話講完、等卡出來的那幾秒）：玩家不能動。關卡被釋放時自己解開。
func lock_for_cutscene(on: bool = true) -> void:
	if on:
		add_to_group(Game.CUTSCENE_GROUP)
	elif is_in_group(Game.CUTSCENE_GROUP):
		remove_from_group(Game.CUTSCENE_GROUP)


## 開發旗標 `--talk-skip=N` 用的：按掉一句（遇到選項選第一個）
static func skip_line(r: DialogueRunner) -> void:
	if not r.visible_choices.is_empty():
		r.choose(0)
	else:
		r.advance()
