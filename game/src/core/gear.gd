class_name Gear
extends RefCounted
## 諾恩的裝備與錢（裝備面板 GearPanel、街尾的商人）。純資料：只讀寫 GameState 的旗標與道具，資料在 data/items/gear.json。
## - 錢：旗標 noen.coins（還沒有時是 start_coins）。
## - 飾品：擁有＝GameState.items[id] > 0；戴著的記在 noen.accessory；試戴（還沒買）時 noen.accessory_trial＝true。
## - 武器：拿哪一把是 PlayerController 的 WEAPON_FLAG（noen.weapon），這裡只讀。

const DEFAULT_PATH: String = "res://data/items/gear.json"
const COINS_FLAG: String = "noen.coins"
const ACCESSORY_FLAG: String = "noen.accessory"
const TRIAL_FLAG: String = "noen.accessory_trial"
const WEAPON_FLAG: String = "noen.weapon"
const DEFAULT_WEAPON: String = "rusty_sword"
## 戴著的詛咒飾品多久再給自己一次它的狀態（秒；狀態本身持續得比這個久，所以一直都在）
const CURSE_REFRESH_SEC: float = 1.0

static var _cache: Dictionary = {}

var state: GameState
var data: Dictionary


func _init(p_state: GameState, p_data: Dictionary = {}) -> void:
	state = p_state
	data = p_data if not p_data.is_empty() else load_data()


static func load_data(path: String = DEFAULT_PATH) -> Dictionary:
	if _cache.has(path):
		return _cache[path] as Dictionary
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Gear: 讀不到 %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	var d: Dictionary = parsed as Dictionary if parsed is Dictionary else {}
	_cache[path] = d
	return d


## 資料格式檢查（測試用）：回傳錯誤訊息的清單
static func validate(d: Dictionary, rules: StatusRules) -> PackedStringArray:
	var errors: PackedStringArray = []
	for section: String in ["weapons", "accessories"]:
		var items: Dictionary = d.get(section, {}) as Dictionary
		for id: String in items:
			var it: Dictionary = items[id] as Dictionary
			for key: String in ["name_key", "desc_key"]:
				if str(it.get(key, "")) == "":
					errors.append("%s.%s 沒有 %s" % [section, id, key])
			var curse: String = str(it.get("curse", ""))
			if curse != "" and not rules.sources.has(curse):
				errors.append("%s.%s 的 curse %s 不在 statuses.json 的 sources" % [section, id, curse])
			if section == "accessories" and int(it.get("price", -1)) < 0:
				errors.append("accessories.%s 沒有 price" % id)
	return errors


func coins() -> int:
	return int(state.get_flag(COINS_FLAG, int(data.get("start_coins", 0))))


func add_coins(amount: int) -> void:
	state.set_flag(COINS_FLAG, maxi(coins() + amount, 0))


func accessory_def(id: String) -> Dictionary:
	return (data.get("accessories", {}) as Dictionary).get(id, {}) as Dictionary


func weapon_def(id: String) -> Dictionary:
	return (data.get("weapons", {}) as Dictionary).get(id, {}) as Dictionary


func owns(id: String) -> bool:
	return int(state.items.get(id, 0)) > 0


func weapon() -> String:
	return str(state.get_flag(WEAPON_FLAG, DEFAULT_WEAPON))


## 戴著的飾品（沒有是空字串）
func accessory() -> String:
	return str(state.get_flag(ACCESSORY_FLAG, ""))


func is_trial() -> bool:
	return accessory() != "" and bool(state.get_flag(TRIAL_FLAG, false))


## 戴上（自己的，或 trial＝試戴商人的）。不認得、沒有又不是試戴：回傳 false
func equip_accessory(id: String, trial: bool = false) -> bool:
	if accessory_def(id).is_empty() or (not trial and not owns(id)):
		return false
	state.set_flag(ACCESSORY_FLAG, id)
	state.set_flag(TRIAL_FLAG, trial and not owns(id))
	return true


func unequip_accessory() -> void:
	state.set_flag(ACCESSORY_FLAG, "")
	state.set_flag(TRIAL_FLAG, false)


## 買下來：回傳 "bought"／"owned"／"poor"（錢不夠）／"unknown"。正在試戴的買了就是自己的、繼續戴著
func buy(id: String) -> String:
	var def: Dictionary = accessory_def(id)
	if def.is_empty():
		return "unknown"
	if owns(id):
		return "owned"
	var price: int = int(def.get("price", 0))
	if coins() < price:
		return "poor"
	add_coins(-price)
	state.items[id] = 1
	if accessory() == id:
		state.set_flag(TRIAL_FLAG, false)
	return "bought"


## 戴著的飾品給自己的狀態來源（沒有是空字串）
func accessory_curse() -> String:
	var id: String = accessory()
	return str(accessory_def(id).get("curse", "")) if id != "" else ""


func weapon_curse() -> String:
	return str(weapon_def(weapon()).get("curse", ""))
