extends TestCase
## 「第一章　完」之後的製作名單與下一章的預告（EndCredits）：資料的 key 都有翻譯、從畫面下面捲上來停在「感謝遊玩」、
## 長按跳過、整段播完呼叫一次（回標題）。

func test_data_roles_and_preview_keys_are_translated() -> void:
	var d: Dictionary = EndCredits.load_data()
	var sections: Array = d.get("sections", []) as Array
	assert_true(sections.size() >= 6, "名單有幾段（%d）" % sections.size())
	for sec: Variant in sections:
		var role: String = str((sec as Dictionary).get("role", ""))
		assert_ne(tr(role), role, "%s 有翻譯" % role)
		for n: Variant in (sec as Dictionary).get("names", []) as Array:
			var name_text: String = str(n)
			if name_text == name_text.to_upper() and name_text.contains("_"):
				assert_ne(tr(name_text), name_text, "%s 有翻譯" % name_text)
	var p: Dictionary = d.get("preview", {}) as Dictionary
	for k: String in ["small", "title", "foot"]:
		assert_ne(tr(str(p.get(k, ""))), str(p.get(k, "")), "預告的 %s 有翻譯" % k)
	assert_eq((p.get("lines", []) as Array).size(), 2)


func test_roll_starts_below_the_screen_and_stops_with_thanks_in_the_middle() -> void:
	assert_eq(EndCredits.roll_top(0.0, 1080.0, 2000.0), 1080.0, "一開始在畫面最下面")
	var mid: float = EndCredits.roll_top(10.0, 1080.0, 2000.0)
	assert_true(mid < 1080.0 and mid > -2000.0, "捲上去（%.0f）" % mid)
	assert_eq(EndCredits.roll_top(999.0, 1080.0, 2000.0), 540.0 - 2000.0, "最多捲到「感謝遊玩」在畫面中間")


func test_plays_through_roll_thanks_and_preview_then_calls_back_once() -> void:
	var host := Node.new()
	tree.root.add_child(host)
	var calls: Array[int] = [0]
	var c := EndCredits.play(host, func() -> void: calls[0] += 1, 0.004)
	await tree.process_frame
	assert_eq(c.part, EndCredits.Part.ROLL)
	assert_true(c.roll_sec() > 15.0, "捲十幾秒以上（%.1f 秒）" % c.roll_sec())
	var seen: Dictionary = {}
	for i: int in 5000:
		await tree.process_frame
		seen[c.part] = true
		if calls[0] > 0:
			break
	assert_eq(calls[0], 1, "播完呼叫一次")
	assert_true(seen.has(EndCredits.Part.THANKS) and seen.has(EndCredits.Part.PREVIEW), "捲完停在「感謝遊玩」、再出預告")
	assert_eq(c.part, EndCredits.Part.DONE)
	c.finish()
	assert_eq(calls[0], 1, "再叫一次不會重複")
	host.free()
	(tree.root.get_node("Game").get("fade") as ScreenFade).clear()


func test_holding_interact_skips_to_the_preview_then_ends() -> void:
	var host := Node.new()
	tree.root.add_child(host)
	var calls: Array[int] = [0]
	var c := EndCredits.play(host, func() -> void: calls[0] += 1)
	c.elapsed = EndCredits.SKIP_AFTER_SEC + 0.1
	Input.action_press("interact")
	for i: int in 3000:
		await tree.process_frame
		if c.part != EndCredits.Part.ROLL:
			break
	Input.action_release("interact")
	assert_eq(c.part, EndCredits.Part.PREVIEW, "長按：跳到預告")
	assert_eq(calls[0], 0)
	await tree.process_frame
	Input.action_press("interact")
	for i: int in 3000:
		await tree.process_frame
		if calls[0] > 0:
			break
	Input.action_release("interact")
	assert_eq(calls[0], 1, "預告的時候再長按：結束")
	host.free()
	(tree.root.get_node("Game").get("fade") as ScreenFade).clear()
