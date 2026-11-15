class_name Mission
extends RefCounted
signal changed
signal completed
var clues: Array[String] = []
var extracted: bool = false

func record_clue(id: String) -> void:
 if id.is_empty() or clues.has(id): return
 clues.append(id)
 changed.emit()

func can_extract() -> bool:
 return clues.size() >= 2

func extract() -> bool:
 if extracted or not can_extract(): return false
 extracted = true
 changed.emit()
 completed.emit()
 return true
