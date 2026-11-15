class_name SessionSnapshot
extends RefCounted
## Persistence for the current greybox mission. Unknown or malformed values are ignored.
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
 player.inventory.clear()
 var raw_clues: Variant = data.get("clues", [])
 if raw_clues is Array:
  for clue: Variant in raw_clues:
   if clue is String and mission.has_record(clue) and not clues.has(clue) and player.inventory.add(clue):
    clues.append(clue)
 mission.clues = clues
 mission.extracted = data.get("extracted", false) == true and mission.can_extract()
 for object: Interactable in objects:
  if object.kind == "clue": object.used = clues.has(object.identifier)
  elif object.kind == "disguise": object.used = player.role == "staff"
  else: continue
  object.visible = not object.used
 var position_data: Variant = data.get("position", [])
 if position_data is Array and position_data.size() == 3:
  if _number(position_data[0]) and _number(position_data[1]) and _number(position_data[2]):
   var p := Vector3(float(position_data[0]), float(position_data[1]), float(position_data[2]))
   if HotelLayout.is_safe_player_position(p):
    player.global_position = p
    player.velocity = Vector3.ZERO
 mission.changed.emit()

static func _number(value: Variant) -> bool:
 return value is int or value is float
