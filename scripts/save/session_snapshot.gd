class_name SessionSnapshot
extends RefCounted
## Persistence for the current greybox mission. Unknown or malformed values are ignored.
const KNOWN_CLUES := ["ledger", "memo", "archive"]
const KNOWN_ROLES := ["visitor", "staff"]

static func capture(player: HotelPlayer, mission: Mission) -> Dictionary:
 var p := player.global_position
 return {
  "position": [p.x, p.y, p.z],
  "role": player.role,
  "clues": mission.clues.duplicate(),
  "extracted": mission.extracted,
 }

static func restore(data: Dictionary, player: HotelPlayer, mission: Mission, objects: Array[Interactable]) -> void:
 var role: Variant = data.get("role", "visitor")
 player.set_disguise(role if role is String and role in KNOWN_ROLES else "visitor")
 var clues: Array[String] = []
 var raw_clues: Variant = data.get("clues", [])
 if raw_clues is Array:
  for clue: Variant in raw_clues:
   if clue is String and clue in KNOWN_CLUES and not clues.has(clue): clues.append(clue)
 mission.clues = clues
 mission.extracted = data.get("extracted", false) == true and mission.can_extract()
 player.inventory.items.clear()
 for clue: String in clues: player.inventory.add(clue)
 for object: Interactable in objects:
  if object.kind == "clue": object.used = clues.has(object.identifier)
  elif object.kind == "disguise": object.used = player.role == "staff"
  else: continue
  object.visible = not object.used
 var position_data: Variant = data.get("position", [])
 if position_data is Array and position_data.size() == 3:
  if _number(position_data[0]) and _number(position_data[1]) and _number(position_data[2]):
   var p := Vector3(float(position_data[0]), float(position_data[1]), float(position_data[2]))
   if p.is_finite() and absf(p.x) <= 11.0 and p.y >= 0.0 and p.y <= 3.0 and absf(p.z) <= 7.0:
    player.global_position = p
    player.velocity = Vector3.ZERO
 mission.changed.emit()

static func _number(value: Variant) -> bool:
 return value is int or value is float
