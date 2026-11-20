extends TestCase
## 諾恩的裝備與錢（Gear）與裝備面板（GearPanel）：資料格式、開局的零錢、試戴、買、戴著的詛咒（刺痛 → 回血）、面板上的字。


func _game() -> Node:
	return tree.root.get_node("Game")


func test_gear_data_is_valid() -> void:
	var d: Dictionary = Gear.load_data()
	assert_false(d.is_empty(), "讀得到 gear.json")
	assert_eq(Gear.validate(d, StatusRules.load_default()), PackedStringArray())
	for id: String in (d["weapons"] as Dictionary):
		assert_true(PlayerController.WEAPONS.has(id), "武器 %s 跟 PlayerController.WEAPONS 一樣" % id)
	for id: String in PlayerController.WEAPONS:
		assert_true((d["weapons"] as Dictionary).has(id), "面板認得 %s" % id)


func test_start_coins_and_buying_the_ring() -> void:
	var g := Gear.new(GameState.new())
	assert_eq(g.coins(), int(g.data["start_coins"]), "開局的零錢")
	assert_eq(g.accessory(), "")
	assert_false(g.equip_accessory("pain_ring"), "沒買不能戴")
	assert_true(g.equip_accessory("pain_ring", true), "可以試戴")
	assert_true(g.is_trial())
	assert_eq(g.accessory_curse(), "pain_ring")
	var price: int = int(g.accessory_def("pain_ring")["price"])
	assert_eq(g.buy("pain_ring"), "bought")
	assert_eq(g.coins(), int(g.data["start_coins"]) - price)
	assert_true(g.owns("pain_ring"))
	assert_false(g.is_trial(), "買了就是自己的")
	assert_eq(g.accessory(), "pain_ring", "繼續戴著")
	assert_eq(g.buy("pain_ring"), "owned")
	g.unequip_accessory()
	assert_eq(g.accessory_curse(), "")
	assert_true(g.equip_accessory("pain_ring"))
	assert_eq(g.buy("no_such_thing"), "unknown")


func test_not_enough_coins() -> void:
	var st := GameState.new()
	st.set_flag(Gear.COINS_FLAG, 2)
	var g := Gear.new(st)
	assert_eq(g.buy("pain_ring"), "poor")
	assert_false(g.owns("pain_ring"))
	assert_eq(g.coins(), 2)
	g.add_coins(-9)
	assert_eq(g.coins(), 0, "不會變負的")


func test_ring_curse_flips_into_regeneration_on_noen() -> void:
	var effects := StatusEffects.new(StatusRules.load_default())
	effects.reverses = true
	assert_ne(effects.apply_source("pain_ring"), "ignored")
	assert_true(effects.has("ache"))
	assert_true(effects.rate("ache") > 0.0)
	var hp := Health.new(100.0)
	hp.apply_damage(50.0)
	effects.tick(1.0, hp)
	assert_true(hp.hp > 50.0, "諾恩身上是回血：%s" % hp.hp)
	var other := StatusEffects.new(StatusRules.load_default())
	other.apply_source("pain_ring")
	var hp2 := Health.new(100.0)
	other.tick(1.0, hp2)
	assert_true(hp2.hp < 100.0, "別人戴是扣血")


func test_panel_shows_the_slots_and_toggles_the_ring() -> void:
	var old: GameSession = _game().get("session") as GameSession
	var dir: String = "user://test_gear_%d" % Time.get_ticks_usec()
	var s := GameSession.new(QuestDB.load_default(), dir)
	s.new_game()
	_game().set("session", s)
	var panel := GearPanel.new()
	tree.root.add_child(panel)
	panel.open()
	assert_true(panel.is_open())
	assert_true(bool(_game().call("is_player_locked")), "開著的時候不能動")
	assert_eq(panel.text_of("WeaponName"), tr("GEAR_RUSTY_SWORD"))
	assert_true(panel.text_of("WeaponCurse") != "", "寫著砍中給自己什麼")
	assert_eq(panel.text_of("AccessoryName"), tr("GEAR_EMPTY"))
	assert_eq(panel.toggle_accessory(), "", "沒有戒指：戴不上")
	s.state.items["pain_ring"] = 1
	assert_eq(panel.toggle_accessory(), "pain_ring", "戴上")
	assert_eq(panel.text_of("AccessoryName"), tr("GEAR_PAIN_RING"))
	assert_true(panel.text_of("AccessoryCurse").contains(tr("STATUS_ACHE_REVERSED")), "寫著詛咒反轉成什麼")
	assert_eq(panel.toggle_accessory(), "", "拿下")
	panel.close()
	assert_false(bool(_game().call("is_player_locked")))
	panel.free()
	_game().set("session", old)
	if DirAccess.dir_exists_absolute(dir):
		for f: String in DirAccess.get_files_at(dir):
			DirAccess.remove_absolute(dir.path_join(f))
		DirAccess.remove_absolute(dir)


func test_carried_items_are_listed_by_name() -> void:
	var st := GameState.new()
	var g := Gear.new(st)
	assert_eq(g.carried().size(), 0)
	st.items["noodle_ticket"] = 2
	st.items["sera_poison_vial"] = 3
	st.items["pain_ring"] = 1
	var c: Array[Array] = g.carried()
	assert_eq(c.size(), 2, "飾品不算、認得的道具才列")
	assert_eq(c[0], ["ITEM_SERA_POISON", 3])
	assert_eq(c[1], ["ITEM_NOODLE_TICKET", 2])
