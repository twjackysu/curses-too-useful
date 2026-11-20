extends TestCase
## 模型場景載過一次就留著（SceneCache），換關卡才放掉。


func after_each() -> void:
	SceneCache.forget()


func test_a_scene_is_read_once_and_kept_until_forget() -> void:
	SceneCache.forget()
	var path: String = "res://scenes/levels/guild_hall.tscn"
	var a: PackedScene = SceneCache.scene(path)
	assert_not_null(a)
	assert_eq(SceneCache.size(), 1)
	assert_true(SceneCache.scene(path) == a, "第二次拿到同一份（不從硬碟重讀）")
	SceneCache.forget()
	assert_eq(SceneCache.size(), 0, "換關卡時放掉")


func test_prop_and_character_models_go_through_the_cache() -> void:
	SceneCache.forget()
	var tree_scene: PackedScene = PropModels.scene_for(ForestScenery.TREE_MODEL)
	if tree_scene != null:
		assert_true(PropModels.scene_for(ForestScenery.TREE_MODEL) == tree_scene, "樹的模型只讀一次")
	var noen: PackedScene = CharacterModels.scene_for("noen")
	if noen != null:
		assert_true(CharacterModels.scene_for("noen") == noen, "人物的模型只讀一次")
	assert_true(PropModels.scene_for("tripo/no_such_prop") == null, "沒有的模型照舊回傳 null")
	assert_eq(SceneCache.size(), int(tree_scene != null) + int(noen != null), "沒有的模型不留")


func test_changing_levels_lets_go_of_the_last_levels_models() -> void:
	var game: Node = tree.root.get_node("Game")
	SceneCache.scene("res://scenes/levels/guild_hall.tscn")
	game.set("change_scenes", false)
	game.call("go_to_level", "corrupt_forest")
	assert_eq(SceneCache.size(), 1, "測試裡不真的換場景：留著（下一個測試載入同一關不用重讀）")
	game.set("change_scenes", true)
