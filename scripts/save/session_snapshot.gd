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
  "action_complete": mission.action_complete,
  "action_id": mission.required_action,
  "target_id": mission.primary_target.get("id", ""),
  "target_complete": mission.target_complete,
  "target_incapacitated": mission.target_incapacitated,
  "target_discovered": mission.target_discovered,
  "equipment": player.equipment.snapshot(),
 }

static func restore(data: Dictionary, player: HotelPlayer, mission: Mission, objects: Array[Interactable], position_validator: Callable = Callable(), progress: CampaignProgress = null) -> void:
 var mission_id := "initiation" if mission.required_action == "disable_assessment_unit" else "meridian"
 if progress: player.equipment.restore(data.get("equipment"), progress, mission_id)
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
 # Old Initiation saves did not contain an action ID. Preserve those, but
 # never apply an explicitly different mission's objective to this mission.
 var compatible_action: bool = not data.has("action_id") or data.get("action_id") == mission.required_action
 mission.action_complete = not mission.required_action.is_empty() and compatible_action and data.get("action_complete", false) == true
 # A completed legacy Meridian checkpoint pre-dates the new witness objective.
 if mission.required_action == "interview_ivo" and not data.has("action_id") and data.get("extracted", false) == true:
  mission.action_complete = true
 var same_target: bool = data.get("target_id", "") == mission.primary_target.get("id", "")
 mission.target_complete = same_target and data.get("target_complete", false) == true
 mission.target_incapacitated = mission.target_complete and data.get("target_incapacitated", false) == true
 # The briefing already identifies the mission primary, including old saves.
 mission.target_discovered = not mission.primary_target.is_empty() or (same_target and data.get("target_discovered", false) == true)
 # A previously completed Meridian save must not become incomplete after adding Locke.
 if mission.primary_target.get("id") == "adrian_locke" and not data.has("target_id") and data.get("extracted", false) == true:
  mission.target_complete = true
  mission.target_discovered = true
 mission.extracted = data.get("extracted", false) == true and mission.can_extract()
 for object: Interactable in objects:
  if object.kind == "clue": object.used = clues.has(object.identifier)
  elif object.kind == "disguise": object.used = player.role == "staff"
  elif object.kind == "target": object.used = mission.action_complete
  elif object.kind == "primary":
   object.used = mission.target_complete
   if object.get_parent() is HotelNpc:
    (object.get_parent() as HotelNpc).restore_objective(mission.target_complete, mission.target_incapacitated)
  elif object.kind == "robot":
   object.used = mission.action_complete
   continue # The disabled training unit remains visible.
  else: continue
  object.visible = not object.used
 var position_data: Variant = data.get("position", [])
 if position_data is Array and position_data.size() == 3:
  if _number(position_data[0]) and _number(position_data[1]) and _number(position_data[2]):
   var p := Vector3(float(position_data[0]), float(position_data[1]), float(position_data[2]))
   var safe: bool = bool(position_validator.call(p)) if position_validator.is_valid() else HotelLayout.is_safe_player_position(p)
   if safe:
    player.global_position = p
    player.velocity = Vector3.ZERO
 mission.changed.emit()

static func _number(value: Variant) -> bool:
 return value is int or value is float
