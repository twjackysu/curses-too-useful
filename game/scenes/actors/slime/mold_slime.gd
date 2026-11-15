class_name MoldSlime
extends Slime
## 黴菌史萊姆（docs/story/chapter-1.md 時段 B）：灰綠色、長滿黴菌的史萊姆，比劇毒史萊姆慢、耐打。
## 撞到人上一層衰弱（data/status/statuses.json 的 mold_touch）——對諾恩是砍得更重。動作跟劇毒史萊姆同一套。


func tuning_id() -> String:
	return "mold_slime"


func model_name() -> String:
	return "tripo/enemy_mold_slime"


func touch_source() -> String:
	return "mold_touch"
