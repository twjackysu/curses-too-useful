extends TestCase
## Benchmark 計時與報告。

const BenchScript: GDScript = preload("res://scenes/bench/benchmark.gd")


func test_warmup_not_counted_and_spikes_recorded() -> void:
	var run := BenchmarkRun.new(2.0, 1.0)
	run.push(0.1)  # 暖機中的 100ms 尖峰：記為尖峰，但不計入統計
	var finished: bool = false
	var frames: int = 1
	while not finished and frames < 10000:
		finished = run.push(1.0 / 60.0)
		frames += 1
	assert_true(finished, "跑完會結束")
	assert_eq(run.spikes.size(), 1, "尖峰紀錄")
	assert_true(absf(run.stats.average_fps() - 60.0) < 0.5, "暖機不計入：平均 %.2f" % run.stats.average_fps())
	var d: Dictionary = run.to_dict({"adapter": "test"})
	assert_eq(d["adapter"], "test", "保留 meta")
	assert_true(d["meets_target"] as bool, "60 fps 達標")
	assert_true(run.push(0.016), "結束後再 push 仍回傳 true")


func test_progress_goes_zero_to_one() -> void:
	var run := BenchmarkRun.new(1.0, 0.0)
	assert_eq(run.progress(), 0.0)
	run.push(0.5)
	assert_true(is_equal_approx(run.progress(), 0.5))
	run.push(1.0)
	assert_eq(run.progress(), 1.0)


func test_camera_path_endpoints() -> void:
	var first: Vector3 = BenchScript.call("sample_path", 0.0)
	var last: Vector3 = BenchScript.call("sample_path", 1.0)
	var pts: Array[Vector3] = BenchScript.get("PATH_POINTS")
	assert_true(first.is_equal_approx(pts[0]), "起點")
	assert_true(last.is_equal_approx(pts[pts.size() - 1]), "終點")


## 雲端只有軟體算圖（一幀一兩秒）：照幀數跑，前幾幀暖機不算；每一幀畫了多少東西也記下來
func test_frame_count_run_and_render_counts() -> void:
	var run := BenchmarkRun.by_frames(4, 2)
	var pushed: int = 0
	while not run.is_finished() and pushed < 100:
		run.push(1.5)  # 一幀 1.5 秒也照樣跑完
		run.push_render(100 + pushed * 10, 50, 300000)
		pushed += 1
	assert_eq(pushed, 6, "4 幀＋暖機 2 幀")
	assert_eq(run.stats.count(), 4, "暖機不計入")
	var r: Dictionary = run.to_dict()["render"]
	assert_eq(int(r["frames"]), 4)
	assert_eq(int(r["draw_calls_max"]), 150, "最多那一幀")
	assert_true(is_equal_approx(float(r["draw_calls_avg"]), 135.0), "平均（暖機的兩幀不算）：%s" % str(r["draw_calls_avg"]))
	assert_true(is_equal_approx(float(r["primitives_avg_k"]), 300.0), "三角面以千為單位")


func test_every_route_has_a_level_and_a_path() -> void:
	var routes: Dictionary = BenchScript.get("ROUTES")
	for key: String in ["entrance", "deep", "altar", "guild"]:
		assert_true(routes.has(key), "有 %s 這條路線" % key)
		var r: Dictionary = routes[key]
		assert_true(ResourceLoader.exists(str(r["level"])), "關卡在：%s" % str(r["level"]))
		var pts: Array = r["path"]
		assert_true(pts.size() >= 3, "路徑至少三點")
		var last: Vector3 = BenchScript.call("sample_path", 1.0, pts)
		assert_true(last.is_equal_approx(pts[pts.size() - 1]), "%s 的終點" % key)
