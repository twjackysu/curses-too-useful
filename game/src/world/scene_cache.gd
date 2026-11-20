class_name SceneCache
extends RefCounted
## 模型場景（PropModels、CharacterModels）載過一次就留著，到換關卡才放掉（Game.go_to_level → forget()）。
## 以前每次 load() 拿到的場景沒有人留著就被釋放，下一次又從硬碟重讀：森林種一百六十棵樹、十幾個陷阱與敵人，
## 同一個模型讀好幾次，一關的 _ready 要 1.6 秒（留著之後同一關第二次載入 0.14 秒；測試一個檔載入關卡幾十次）。

static var _scenes: Dictionary = {}


## 照路徑讀一個場景（呼叫的地方先確定檔案在：ResourceLoader.exists）。
static func scene(path: String) -> PackedScene:
	var kept: PackedScene = _scenes.get(path) as PackedScene
	if kept == null:
		kept = load(path) as PackedScene
		if kept != null:
			_scenes[path] = kept
	return kept


## 放掉留著的場景（換關卡時：上一關用的模型不一直佔著記憶體）。正在場景裡的節點照舊能用。
static func forget() -> void:
	_scenes.clear()


static func size() -> int:
	return _scenes.size()
