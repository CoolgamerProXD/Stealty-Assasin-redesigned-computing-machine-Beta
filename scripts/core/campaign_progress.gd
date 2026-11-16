class_name CampaignProgress
extends RefCounted
## The ordered mission list is the single authority for unlocks and replay.
var missions: Array[Dictionary] = []
var equipment: Array[Dictionary] = []
# The existing Initiation records are the three assessment lesson milestones.
const LESSON_RECORDS := ["evaluation", "sensor_log", "dispatch"]
var completed_lessons: Array[String] = []
var equipped_coins: int = 0
var completed: Array[String] = []
var recovered_keys: Array[String] = []
var usb_decryption_seen: bool = false
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

func award_lesson(record_id: String) -> bool:
 if record_id not in LESSON_RECORDS: return false
 if not completed_lessons.has(record_id): completed_lessons.append(record_id)
 return true

func set_equipped_coins(amount: int) -> bool:
 if amount < 0 or amount > completed_lessons.size(): return false
 equipped_coins = amount
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
 completed_lessons.clear()
 equipped_coins = 0
 usb_decryption_seen = false
 var raw_keys: Variant = data.get("recovered_keys", [])
 var raw: Variant = data.get("completed", [])
 if not raw_keys is Array: raw_keys = []
 if not raw is Array: raw = []
 # Restore in chronological order. A malformed future key cannot satisfy a
 # mission that had not yet been unlocked in the persisted campaign.
 for entry: Dictionary in missions:
  var id := str(entry["id"])
  if not is_unlocked(id): continue
  var key_id := str(entry.get("key_id", ""))
  if not key_id.is_empty() and key_id in raw_keys and not recovered_keys.has(key_id): recovered_keys.append(key_id)
  if id in raw and (key_id.is_empty() or recovered_keys.has(key_id)): completed.append(id)
 # Completed legacy Initiation necessarily required all three records.
 # For new or partial saves, only explicitly recognized lesson IDs count.
 var raw_lessons: Variant = data.get("completed_lessons", [])
 if raw_lessons is Array:
  for lesson: String in LESSON_RECORDS:
   if lesson in raw_lessons: completed_lessons.append(lesson)
 if completed.has("initiation"):
  for lesson: String in LESSON_RECORDS:
   if not completed_lessons.has(lesson): completed_lessons.append(lesson)
 var raw_coins: Variant = data.get("equipped_coins", 0)
 if (raw_coins is int or raw_coins is float) and is_finite(float(raw_coins)):
  equipped_coins = clampi(int(raw_coins), 0, completed_lessons.size())
 usb_decryption_seen = data.get("usb_decryption_seen", false) == true and usb_ready() and completed.has("ngong_ping")
 var desired: Variant = data.get("selected", "training_sidearm")
 selected = "training_sidearm"
 if desired is String: select_item(desired)
 var last: Variant = data.get("last_mission", "")
 last_mission = last if last is String and is_unlocked(last) else ""

func snapshot() -> Dictionary:
 return {"completed_lessons": completed_lessons.duplicate(), "equipped_coins": equipped_coins, "completed": completed.duplicate(), "recovered_keys": recovered_keys.duplicate(), "usb_decryption_seen": usb_decryption_seen, "selected": selected, "last_mission": last_mission}
