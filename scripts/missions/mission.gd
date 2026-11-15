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

func configure(data: Variant) -> bool:
 configured = false
 available_records.clear()
 required_records = 0
 clues.clear()
 extracted = false
 if not data is Dictionary: return false
 var raw_records: Variant = data.get("records")
 var raw_required: Variant = data.get("required_records")
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

func can_extract() -> bool:
 return configured and clues.size() >= required_records

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
 return "Collect %d different records, then leave." % required_records
