class_name ForestMap
extends RefCounted
## 腐敗之森的地圖（純資料＋純函式；docs/story/chapter-1.md 節點 2 與時段 B）：空地、路、哪裡是毒沼。
## 森林口在南邊（+z），往北（−z）走：史萊姆空地 → 陷阱林 → 岔路（西邊營火、東邊狼徑 → 東北角的毒沼）→ 樹人窪地 → 祭壇路口。
## 關卡照這張表放東西（CorruptForest）、種樹與草（ForestScenery）、畫地面（forest_ground.gdshader 讀 trail_mask()）。
## 空地寫成 Vector3(x, z, 半徑)，路寫成 Vector4(x1, z1, x2, z2)。

## 地面一邊多長（公尺，中心在原點）
const SIZE: float = 200.0
const MASK_SIZE: int = 256
## 路的中線兩邊這麼寬不種樹；畫出來的土路比它窄
const PATH_HALF_WIDTH: float = 4.0
const PATH_DIRT_HALF: float = 2.6
## 遮罩上，離邊界這麼遠（公尺）從 0.5 變到 0 或 1（shader 用雜訊把邊緣咬成不規則的）
const MASK_FALLOFF: float = 3.0
## 離路與空地超過這麼遠就是走丟了（關卡把人擋回來）
const STRAY_LIMIT: float = 15.0
## 外圍的土坡（只是看的，碰撞還是平的）：離路網這麼遠開始隆起、這麼遠到最高——坡腳就在走丟的界線外面一點，
## 玩家被擋回來的地方看得到前面是一道坡
const RELIEF_START: float = 16.0
const RELIEF_FULL: float = 36.0
## 坡最高幾公尺（再乘上 0.55～1 的起伏）
const RELIEF_MAX: float = 8.0
const HEIGHT_MASK_SIZE: int = 128

const ENTRANCE: Vector2 = Vector2(0, 34)
const GLADE: Vector3 = Vector3(0, -15, 8.0)
const TRAPS: Vector3 = Vector3(0, -36, 7.5)
const CAMP: Vector3 = Vector3(-24, -46, 6.5)
const WOLVES: Vector3 = Vector3(24, -44, 8.0)
const SWAMP: Vector3 = Vector3(40, -64, 10.0)
const HOLLOW: Vector3 = Vector3(0, -60, 9.0)
const ALTAR_GATE: Vector3 = Vector3(0, -80, 4.5)
const CLEARINGS: Array[Vector3] = [GLADE, TRAPS, CAMP, WOLVES, SWAMP, HOLLOW, ALTAR_GATE]
const PATHS: Array[Vector4] = [
	Vector4(0, 34, 0, -15),
	Vector4(0, -15, 0, -36),
	Vector4(0, -36, -24, -46),
	Vector4(0, -36, 24, -44),
	Vector4(24, -44, 40, -64),
	Vector4(0, -36, 0, -60),
	Vector4(-24, -46, 0, -60),
	Vector4(0, -60, 0, -80),
]

static var _mask: Image
static var _heights: Image
static var _relief_noise: FastNoiseLite


## 空地的中心（世界座標，地面上）
static func at(clearing: Vector3) -> Vector3:
	return Vector3(clearing.x, 0.0, clearing.y)


static func flat(p: Vector3) -> Vector2:
	return Vector2(p.x, p.z)


## 離最近一條路的中線多遠
static func path_distance(p: Vector2) -> float:
	var best: float = INF
	for seg: Vector4 in PATHS:
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, Vector2(seg.x, seg.y), Vector2(seg.z, seg.w))))
	return best


## 離最近一塊空地的邊多遠（在裡面是負的）
static func clearing_distance(p: Vector2) -> float:
	var best: float = INF
	for c: Vector3 in CLEARINGS:
		best = minf(best, p.distance_to(Vector2(c.x, c.y)) - c.z)
	return best


## 離「光禿禿的土」（路與空地）的邊多遠（在土上是負的）
static func trail_distance(p: Vector2) -> float:
	return minf(path_distance(p) - PATH_DIRT_HALF, clearing_distance(p))


## 可不可以種樹：不擋路、不在空地裡
static func tree_ok(p: Vector2) -> bool:
	return path_distance(p) > PATH_HALF_WIDTH and clearing_distance(p) > 1.5


## 可不可以長草：路的中間與空地（打架的地方）不長
static func grass_ok(p: Vector2) -> bool:
	return path_distance(p) > PATH_HALF_WIDTH * 0.6 and clearing_distance(p) > -1.0


## 路網上離 p 最近的一點（路的中線或空地的中心往 p 的方向）
static func nearest_on_trail(p: Vector2) -> Vector2:
	var best: Vector2 = p
	var best_d: float = INF
	for seg: Vector4 in PATHS:
		var q: Vector2 = Geometry2D.get_closest_point_to_segment(p, Vector2(seg.x, seg.y), Vector2(seg.z, seg.w))
		if p.distance_to(q) < best_d:
			best_d = p.distance_to(q)
			best = q
	for c: Vector3 in CLEARINGS:
		var center := Vector2(c.x, c.y)
		var q: Vector2 = center + (p - center).limit_length(c.z)
		if p.distance_to(q) < best_d:
			best_d = p.distance_to(q)
			best = q
	return best


## 走太遠就拉回來：離路網超過 STRAY_LIMIT 的位置，移回剛好 STRAY_LIMIT 的地方。沒走丟就原樣回傳。
static func keep_inside(p: Vector3) -> Vector3:
	var here: Vector2 = flat(p)
	var anchor: Vector2 = nearest_on_trail(here)
	if here.distance_to(anchor) <= STRAY_LIMIT:
		return p
	var back: Vector2 = anchor + (here - anchor).normalized() * STRAY_LIMIT
	return Vector3(back.x, p.y, back.y)


## 在不在毒沼裡（那一塊空地整片是濕的）
static func in_swamp(p: Vector2) -> bool:
	return p.distance_to(Vector2(SWAMP.x, SWAMP.y)) < SWAMP.z


## 地面的遮罩（蓋住整片地面，算一次就留著）：R＝土路與空地（邊界是 0.5，往裡往外各 MASK_FALLOFF 公尺漸變），G＝毒沼。
static func trail_mask() -> Image:
	if _mask != null:
		return _mask
	var img := Image.create_empty(MASK_SIZE, MASK_SIZE, false, Image.FORMAT_RG8)
	var per_meter: float = float(MASK_SIZE) / SIZE
	var half: float = float(MASK_SIZE) * 0.5
	var reach: float = MASK_FALLOFF + 1.0
	# 只算每一塊空地、每一條路附近的格子（整張圖一格一格算太慢：測試會載入關卡十幾次）
	var boxes: Array[Rect2] = []
	for c: Vector3 in CLEARINGS:
		boxes.append(Rect2(c.x - c.z, c.y - c.z, c.z * 2.0, c.z * 2.0).grow(reach))
	for seg: Vector4 in PATHS:
		boxes.append(Rect2(Vector2(seg.x, seg.y), Vector2.ZERO).expand(Vector2(seg.z, seg.w)).grow(PATH_DIRT_HALF + reach))
	var swamp_center := Vector2(SWAMP.x, SWAMP.y)
	for box: Rect2 in boxes:
		for y: int in range(maxi(int(box.position.y * per_meter + half), 0), mini(int(box.end.y * per_meter + half) + 1, MASK_SIZE)):
			for x: int in range(maxi(int(box.position.x * per_meter + half), 0), mini(int(box.end.x * per_meter + half) + 1, MASK_SIZE)):
				var p := Vector2((float(x) + 0.5 - half) / per_meter, (float(y) + 0.5 - half) / per_meter)
				var bare: float = clampf(0.5 - trail_distance(p) / (MASK_FALLOFF * 2.0), 0.0, 1.0)
				var wet: float = clampf(0.5 - (p.distance_to(swamp_center) - SWAMP.z) / (MASK_FALLOFF * 2.0), 0.0, 1.0)
				img.set_pixel(x, y, Color(bare, wet, 0.0))
	_mask = img
	return _mask


## 離路網多遠（路的中線、空地的邊；跟走丟的判定是同一個距離）
static func trail_reach(p: Vector2) -> float:
	return p.distance_to(nearest_on_trail(p))


## 地面多高（公尺）：路網附近是平的，走不到的外圍慢慢隆起成一道一道的土坡，坡上照雜訊有高有低。純函式（照算的，不是照圖）。
static func height(p: Vector2) -> float:
	var rise: float = smoothstep(RELIEF_START, RELIEF_FULL, trail_reach(p))
	if rise <= 0.0:
		return 0.0
	if _relief_noise == null:
		_relief_noise = FastNoiseLite.new()
		_relief_noise.seed = 20261118
		_relief_noise.frequency = 0.035
	return rise * RELIEF_MAX * (0.55 + 0.45 * (_relief_noise.get_noise_2d(p.x, p.y) * 0.5 + 0.5))


## 整片地面的高度圖（算一次就留著）：一格 SIZE / HEIGHT_MASK_SIZE 公尺，值是公尺。forest_ground.gdshader 照它把地面往上推。
static func height_mask() -> Image:
	if _heights != null:
		return _heights
	var img := Image.create_empty(HEIGHT_MASK_SIZE, HEIGHT_MASK_SIZE, false, Image.FORMAT_RF)
	var per_meter: float = float(HEIGHT_MASK_SIZE) / SIZE
	var half: float = SIZE * 0.5
	for y: int in HEIGHT_MASK_SIZE:
		for x: int in HEIGHT_MASK_SIZE:
			img.set_pixel(x, y, Color(height(Vector2((float(x) + 0.5) / per_meter - half, (float(y) + 0.5) / per_meter - half)), 0.0, 0.0))
	_heights = img
	return _heights


## 地面在這一點的高度——照高度圖做雙線性內插（跟 shader 裡 GPU 讀圖一樣），種在坡上的樹與草才會剛好貼著畫出來的地面。
static func ground_y(p: Vector2) -> float:
	var img: Image = height_mask()
	var u: float = (p.x / SIZE + 0.5) * float(HEIGHT_MASK_SIZE) - 0.5
	var v: float = (p.y / SIZE + 0.5) * float(HEIGHT_MASK_SIZE) - 0.5
	var x0: int = floori(u)
	var y0: int = floori(v)
	var fx: float = u - float(x0)
	var fy: float = v - float(y0)
	var last: int = HEIGHT_MASK_SIZE - 1
	var a: float = img.get_pixel(clampi(x0, 0, last), clampi(y0, 0, last)).r
	var b: float = img.get_pixel(clampi(x0 + 1, 0, last), clampi(y0, 0, last)).r
	var c: float = img.get_pixel(clampi(x0, 0, last), clampi(y0 + 1, 0, last)).r
	var d: float = img.get_pixel(clampi(x0 + 1, 0, last), clampi(y0 + 1, 0, last)).r
	return lerpf(lerpf(a, b, fx), lerpf(c, d, fx), fy)
