class_name Mission
extends RefCounted
signal changed
signal completed

# Records and the objective threshold are configured together and validated before use.
var available_records: Array[Dictionary] = []
var required_records: int = 0
var clues: Array[String] = []
var extracted: bool = false
var configured: bool = false
var required_action: String = ""
var action_complete: bool = false
var primary_target: Dictionary = {}
var target_complete: bool = false
var target_discovered: bool = false

func configure(data: Variant) -> bool:
 configured = false
 available_records.clear()
 required_records = 0
 clues.clear()
 extracted = false
 required_action = ""
 action_complete = false
 primary_target = {}
 target_complete = false
 target_discovered = false
 if not data is Dictionary: return false
 var raw_records: Variant = data.get("records")
 var raw_required: Variant = data.get("required_records")
 var action: Variant = data.get("required_action", "")
 var primary: Variant = data.get("primary_target", {})
 if not primary is Dictionary: return false
 if not primary.is_empty():
  for key: String in ["id", "name", "description"]:
   if not primary.get(key) is String or str(primary[key]).strip_edges().is_empty(): return false
  if primary["id"] == "adrian_locke":
   if not _valid_point(primary.get("start")) or not primary.get("schedule") is Array or primary["schedule"].is_empty(): return false
   for entry: Variant in primary["schedule"]:
    if not entry is Dictionary or not _valid_point(entry.get("destination")): return false
    if not entry.get("activity") is String or entry["activity"] not in ["working", "waiting", "conversing", "idle"]: return false
    var duration: Variant = entry.get("duration")
    if not (duration is float or duration is int) or not is_finite(float(duration)) or float(duration) <= 0.0: return false
 if not action is String: return false
 if not raw_records is Array or raw_records.is_empty(): return false
 if not (raw_required is int or raw_required is float): return false
 var threshold := float(raw_required)
 if not is_finite(threshold) or threshold != floorf(threshold) or threshold < 1.0 or threshold > raw_records.size(): return false
 var seen: Array[String] = []
 var checked: Array[Dictionary] = []
 for record: Variant in raw_records:
  if not record is Dictionary: return false
  var id: Variant = record.get("id")
  var label: Variant = record.get("label")
  var text: Variant = record.get("message")
  var point: Variant = record.get("position")
  if not id is String or id.strip_edges().is_empty() or id != id.strip_edges() or seen.has(id): return false
  if not label is String or label.strip_edges().is_empty() or not text is String: return false
  if not point is Array or point.size() != 3: return false
  for component: Variant in point:
   if not (component is int or component is float) or not is_finite(float(component)): return false
  seen.append(id)
  checked.append(record.duplicate(true))
 available_records = checked
 required_records = int(threshold)
 required_action = action
 primary_target = primary.duplicate(true)
 configured = true
 return true

func has_record(id: String) -> bool:
 for record: Dictionary in available_records:
  if record["id"] == id: return true
 return false

func record_clue(id: String) -> bool:
 if not configured or not has_record(id) or clues.has(id): return false
 clues.append(id)
 changed.emit()
 return true

func mark_action(id: String) -> bool:
 if not configured or required_action.is_empty() or id != required_action or action_complete: return false
 action_complete = true
 if id == "disable_assessment_unit": target_discovered = true
 changed.emit()
 return true

func mark_target(id: String) -> bool:
 if not configured or id != primary_target.get("id", "") or id.is_empty() or target_complete: return false
 target_complete = true
 target_discovered = true
 changed.emit()
 return true

func can_extract() -> bool:
 var primary_done: bool = primary_target.is_empty() or primary_target.get("id") == "assessment_unit" or target_complete
 return configured and clues.size() >= required_records and (required_action.is_empty() or action_complete) and primary_done

func extract() -> bool:
 if extracted or not can_extract(): return false
 extracted = true
 changed.emit()
 completed.emit()
 return true

func progress_text() -> String:
 if not configured: return "Mission configuration error"
 var status := "complete" if can_extract() else "needed"
 return "Records collected: %d / %d available  |  Required: %d (%s)" % [clues.size(), available_records.size(), required_records, status]

func objective_text() -> String:
 if not configured: return "Mission unavailable: invalid record configuration."
 if extracted: return "Investigation complete."
 if can_extract(): return "Evidence secured. Return to the exit."
 if primary_target.get("id") == "adrian_locke" and not target_complete:
  return "Confront Adrian Locke about the transfer."
 if not required_action.is_empty() and not action_complete:
  if required_action == "disable_assessment_unit": return "Disable the assessment unit and collect %d different records." % required_records
  if required_action == "interview_ivo": return "Question Ivo Chen and collect %d different records." % required_records
  return "Complete the target objective and collect %d different records." % required_records
 return "Collect %d different records, then leave." % required_records

func _valid_point(value: Variant) -> bool:
 if not value is Array or value.size() != 3: return false
 for component: Variant in value:
  if not (component is int or component is float) or not is_finite(float(component)): return false
 return true
