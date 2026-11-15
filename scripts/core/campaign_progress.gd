class_name CampaignProgress
extends RefCounted
## The ordered mission list is the single authority for unlocks and replay.
var missions: Array[Dictionary] = []
var equipment: Array[Dictionary] = []
var completed: Array[String] = []
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
 for index: int in range(missions.size()):
  var entry: Dictionary = missions[index]
  if entry["id"] == id:
   if str(entry["scene"]).is_empty(): return false
   return index == 0 or completed.has(str(missions[index - 1]["id"]))
 return false

func next_mission() -> String:
 for entry: Dictionary in missions:
  if not entry.get("optional", false) and not completed.has(entry["id"]) and is_unlocked(entry["id"]): return entry["id"]
 return ""

func mark_complete(id: String) -> bool:
 if not is_unlocked(id): return false
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

func restore(data: Dictionary) -> void:
 completed.clear()
 var raw: Variant = data.get("completed", [])
 if raw is Array:
  for entry: Dictionary in missions:
   var id := str(entry["id"])
   if id in raw and is_unlocked(id): completed.append(id)
   else: break
 var desired: Variant = data.get("selected", "training_sidearm")
 selected = "training_sidearm"
 if desired is String: select_item(desired)
 var last: Variant = data.get("last_mission", "")
 last_mission = last if last is String and is_unlocked(last) else ""

func snapshot() -> Dictionary:
 return {"completed": completed.duplicate(), "selected": selected, "last_mission": last_mission}
