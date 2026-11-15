class_name Inventory
extends RefCounted
signal changed
var capacity: int = 6
var items: Array[String] = []

func add(item_id: String) -> bool:
 if item_id.is_empty() or items.has(item_id) or items.size() >= capacity: return false
 items.append(item_id)
 changed.emit()
 return true

func has_item(item_id: String) -> bool:
 return items.has(item_id)
