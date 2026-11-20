extends Node3D
## Benchmark：載入一關，鏡頭沿固定路徑飛過去，結束後把統計寫到 user://benchmark/*.json。
## 用法：CursesTooUseful.exe ++ --benchmark [--bench-route=entrance|deep|altar|guild] [--bench-seconds=30]
##（`++` 與 `--` 相同，但 PowerShell 不會吃掉）。entrance＝森林口到空地（預設）、deep＝自由探索的森林（營火、窪地、狼徑、毒沼）、
## altar＝祭壇、guild＝公會大廳。`--bench-frames=N` 改成照幀數跑（雲端只有軟體算圖，一幀一兩秒）。
## 結果檔路徑會印在主控台與畫面上；Windows 在 %APPDATA%\CursesTooUseful\benchmark\。
## 每一幀畫了幾次（draw calls）、幾個東西、幾個三角面也記下來（render）：跟機器快慢無關，雲端量的也能比改前改後。

const LEVEL: String = "res://scenes/levels/corrupt_forest.tscn"
const OUT_DIR: String = "user://benchmark"
## 鏡頭路徑（世界座標）：沿著路從出生點到空地後面
const PATH_POINTS: Array[Vector3] = [
	Vector3(0.0, 1.8, 18.0), Vector3(-2.0, 1.7, 9.0), Vector3(1.5, 2.2, 0.0),
	Vector3(-1.0, 2.4, -8.0), Vector3(0.8, 2.8, -16.0), Vector3(0.0, 3.5, -24.0),
]
## 其他路線：關卡、路徑、最後看哪裡
const ROUTES: Dictionary = {
	"entrance": {"level": LEVEL, "path": PATH_POINTS, "end_look": Vector3(0.0, 8.0, -50.0)},
	"deep": {"level": LEVEL, "path": [
		Vector3(0.0, 2.0, -20.0), Vector3(-10.0, 2.4, -33.0), Vector3(-20.0, 2.2, -45.0), Vector3(-8.0, 2.6, -55.0),
		Vector3(2.0, 2.4, -58.0), Vector3(14.0, 2.4, -48.0), Vector3(24.0, 2.2, -38.0), Vector3(36.0, 2.4, -56.0),
		Vector3(43.0, 2.6, -64.0),
	], "end_look": Vector3(46.0, 1.0, -75.0)},
	"altar": {"level": "res://scenes/levels/ruined_altar.tscn", "path": [
		Vector3(0.0, 1.8, 30.0), Vector3(-2.0, 2.0, 18.0), Vector3(6.0, 2.6, 6.0), Vector3(-6.0, 2.6, -2.0),
		Vector3(0.0, 3.2, 4.0),
	], "end_look": Vector3(0.0, 2.0, -11.5)},
	"guild": {"level": "res://scenes/levels/guild_hall.tscn", "path": [
		Vector3(0.0, 1.7, 9.5), Vector3(-4.0, 1.8, 4.0), Vector3(3.0, 2.0, -1.0), Vector3(5.0, 2.2, -6.0),
		Vector3(-5.0, 2.4, -7.0), Vector3(0.0, 3.0, -2.0),
	], "end_look": Vector3(0.0, 2.0, 11.0)},
}
const LOOK_AHEAD: float = 0.06

var run: BenchmarkRun
var route: String = "entrance"
var result_path: String = ""
var quit_when_done: bool = true
var _camera: Camera3D
var _label: Label


func _ready() -> void:
	var args: Dictionary = App.parse_user_args(OS.get_cmdline_user_args())
	route = str(args.get("bench-route", "entrance"))
	if not ROUTES.has(route):
		push_error("Benchmark: 沒有這條路線 %s（%s）" % [route, ", ".join(ROUTES.keys())])
		route = "entrance"
	if args.has("bench-frames"):
		run = BenchmarkRun.by_frames(int(str(args["bench-frames"])))
	else:
		run = BenchmarkRun.new(float(args.get("bench-seconds", 30.0)))
	var level: Node = (load(str(ROUTES[route]["level"])) as PackedScene).instantiate()
	add_child(level)
	var player: Node = level.get_node_or_null("Player")
	if player != null:
		player.process_mode = Node.PROCESS_MODE_DISABLED
	_camera = Camera3D.new()
	_camera.fov = 70.0
	add_child(_camera)
	_camera.make_current.call_deferred()
	var layer := CanvasLayer.new()
	_label = Label.new()
	_label.position = Vector2(24, 980)
	_label.add_theme_font_size_override("font_size", 18)
	layer.add_child(_label)
	add_child(layer)
	_place_camera(0.0)


static func sample_path(t: float, points: Array = PATH_POINTS) -> Vector3:
	var n: int = points.size() - 1
	var f: float = clampf(t, 0.0, 1.0) * float(n)
	var i: int = mini(int(floor(f)), n - 1)
	var local: float = f - float(i)
	var a: Vector3 = points[maxi(i - 1, 0)]
	var b: Vector3 = points[i]
	var c: Vector3 = points[i + 1]
	var d: Vector3 = points[mini(i + 2, n)]
	return b.cubic_interpolate(c, a, d, local)


func _place_camera(t: float) -> void:
	var points: Array = ROUTES[route]["path"]
	var pos: Vector3 = sample_path(t, points)
	var ahead: Vector3 = sample_path(minf(t + LOOK_AHEAD, 1.0), points)
	if t + LOOK_AHEAD >= 1.0:
		ahead = ROUTES[route]["end_look"]  # 最後看一個地方（森林口：抬頭看樹梢）
	_camera.global_position = pos
	if not pos.is_equal_approx(ahead):
		_camera.look_at(ahead, Vector3.UP)


func _process(delta: float) -> void:
	if result_path != "":
		return
	var done: bool = run.push(delta)
	run.push_render(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
	_place_camera(run.progress())
	_label.text = "BENCHMARK %d%%" % int(run.progress() * 100.0)
	if done:
		_finish()


func _finish() -> void:
	var perf: Node = get_node_or_null("/root/Perf")
	var meta: Dictionary = {
		"game_version": str(ProjectSettings.get_setting("application/config/version", "")),
		"date": Time.get_datetime_string_from_system(),
		"os": OS.get_name(),
		"cpu": OS.get_processor_name(),
		"route": route,
	}
	if perf != null:
		var snap: Dictionary = perf.call("snapshot")
		for key: String in ["driver", "method", "adapter", "resolution", "vram_mb", "draw_calls"]:
			meta[key] = snap.get(key)
	var report: Dictionary = run.to_dict(meta)
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var stamp: String = Time.get_datetime_string_from_system().replace(":", "").replace("-", "")
	result_path = OUT_DIR.path_join("bench-%s-%s.json" % [route, stamp])
	var f := FileAccess.open(result_path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(report, "  "))
		f.close()
	var abs_path: String = ProjectSettings.globalize_path(result_path)
	var s: Dictionary = report["stats"]
	var r: Dictionary = report["render"]
	_label.text = "BENCHMARK DONE  avg %.1f fps  1%% low %.1f fps  draw calls %.0f\n%s" % [float(s["avg_fps"]), float(s["low1_fps"]), float(r["draw_calls_avg"]), abs_path]
	print("[Benchmark] %s" % JSON.stringify(s))
	print("[Benchmark] render %s" % JSON.stringify(r))
	print("[Benchmark] -> %s" % abs_path)
	if quit_when_done:
		await get_tree().create_timer(2.0).timeout
		get_tree().quit(0)
