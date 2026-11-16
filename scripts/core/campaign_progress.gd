class_name CampaignProgress
extends RefCounted
## The ordered mission list is the single authority for unlocks and replay.
var missions: Array[Dictionary] = []
var equipment: Array[Dictionary] = []
var completed: Array[String] = []
var recovered_keys: Array[String] = []
var selected: String = "training_sidearm"
var last_mission: String = ""

func configure(data: Variant) -> bool:
 missions.clear()
 equipment.clear()
 if not data is Dictionary or not data.get("missions") is Array or not data.get("equipment") is Array: return false
 var seen: Array[String] = []
 for item: Variant in data["missions"]:
  if not item is Dictionary or not item.get("id") is String or item["id"].is_empty() or seen.has(item["id"]): return false
  if not item.get("scene") is String: return false
  seen.append(item["id"])
  missions.append(item.duplicate(true))
 for item: Variant in data["equipment"]:
  if not item is Dictionary or not item.get("id") is String or not item.get("missions") is Array: return false
  equipment.append(item.duplicate(true))
 return not missions.is_empty()

func mission(id: String) -> Dictionary:
 for entry: Dictionary in missions:
  if entry["id"] == id: return entry
 return {}

func is_unlocked(id: String) -> bool:
 var previous_required := ""
 for entry: Dictionary in missions:
  if entry["id"] == id:
   if str(entry["scene"]).is_empty(): return false
   return previous_required.is_empty() or completed.has(previous_required)
  if not entry.get("optional", false): previous_required = str(entry["id"])
 return false

func next_mission() -> String:
 for entry: Dictionary in missions:
  if not entry.get("optional", false) and not completed.has(entry["id"]) and is_unlocked(entry["id"]): return entry["id"]
 return ""

func mark_complete(id: String) -> bool:
 if not is_unlocked(id): return false
 var key_id := str(mission(id).get("key_id", ""))
 if not key_id.is_empty() and not recovered_keys.has(key_id): return false
 if not completed.has(id): completed.append(id)
 return true

func item_unlocked(id: String) -> bool:
 for entry: Dictionary in equipment:
  if entry["id"] == id:
   var dependency := str(entry.get("unlock_after", ""))
   return dependency.is_empty() or completed.has(dependency)
 return false

func item_allowed(id: String, mission_id: String) -> bool:
 for entry: Dictionary in equipment:
  if entry["id"] == id: return item_unlocked(id) and mission_id in entry["missions"]
 return false

func select_item(id: String) -> bool:
 if not item_unlocked(id): return false
 selected = id
 return true

# Only a mission's own configured key can be added, never another mission's.
func secure_key(mission_id: String, key_id: String) -> bool:
 var entry := mission(mission_id)
 if not is_unlocked(mission_id) or key_id.is_empty() or entry.get("key_id", "") != key_id: return false
 if not recovered_keys.has(key_id): recovered_keys.append(key_id)
 return true

func usb_ready() -> bool:
 var count := 0
 for entry: Dictionary in missions:
  var key_id := str(entry.get("key_id", ""))
  if not key_id.is_empty():
   count += 1
   if not recovered_keys.has(key_id): return false
 return count == 5

func restore(data: Dictionary) -> void:
 completed.clear()
 recovered_keys.clear()
 var raw_keys: Variant = data.get("recovered_keys", [])
 if raw_keys is Array:
  for entry: Dictionary in missions:
   var key_id := str(entry.get("key_id", ""))
   if not key_id.is_empty() and key_id in raw_keys and not recovered_keys.has(key_id): recovered_keys.append(key_id)
 var raw: Variant = data.get("completed", [])
 if raw is Array:
  for entry: Dictionary in missions:
   var id := str(entry["id"])
   if id in raw and is_unlocked(id):
    var key_id := str(entry.get("key_id", ""))
    if key_id.is_empty() or recovered_keys.has(key_id): completed.append(id)
 var desired: Variant = data.get("selected", "training_sidearm")
 selected = "training_sidearm"
 if desired is String: select_item(desired)
 var last: Variant = data.get("last_mission", "")
 last_mission = last if last is String and is_unlocked(last) else ""

func snapshot() -> Dictionary:
 return {"completed": completed.duplicate(), "recovered_keys": recovered_keys.duplicate(), "selected": selected, "last_mission": last_mission}
