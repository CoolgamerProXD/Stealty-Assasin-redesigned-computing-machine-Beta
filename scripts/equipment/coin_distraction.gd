class_name CoinDistraction
extends RefCounted
## Mission stock is temporary; the campaign's earned/equipped count is untouched.
static func use(player: HotelPlayer, npcs: Array[HotelNpc], world: Node3D) -> String:
 if player.equipment.coins_remaining <= 0: return "No equipped coins remain in this deployment."
 var start := player.global_position + Vector3.UP * 0.8
 var direction := -player.global_basis.z
 direction.y = 0.0
 direction = direction.normalized()
 var query := PhysicsRayQueryParameters3D.create(start, start + direction * 4.0)
 query.exclude = [player.get_rid()]
 var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
 var end := (hit["position"] as Vector3) - direction * 0.15 if not hit.is_empty() else start + direction * 4.0
 var down := PhysicsRayQueryParameters3D.create(end, end + Vector3.DOWN * 3.0)
 down.exclude = [player.get_rid()]
 var floor_hit := player.get_world_3d().direct_space_state.intersect_ray(down)
 if not floor_hit.is_empty(): end = floor_hit["position"] + Vector3.UP * 0.04
 player.equipment.coins_remaining -= 1
 player.body_mesh.interact()
 var marker := MeshInstance3D.new()
 var mesh := CylinderMesh.new()
 mesh.top_radius = 0.12
 mesh.bottom_radius = 0.12
 mesh.height = 0.04
 marker.mesh = mesh
 var material := StandardMaterial3D.new()
 material.albedo_color = Color(0.83,0.65,0.30)
 material.metallic = 0.5
 marker.material_override = material
 world.add_child(marker)
 marker.global_position = end
 var chime := AudioStreamPlayer3D.new()
 chime.bus = "SFX"
 chime.stream = ProceduralSound.tone(740.0, 0.12, 0.07)
 chime.max_distance = 8.0
 marker.add_child(chime)
 chime.play()
 var timer := world.get_tree().create_timer(8.0)
 timer.timeout.connect(func() -> void:
  if is_instance_valid(marker): marker.queue_free()
 )
 for npc: HotelNpc in npcs:
  if is_instance_valid(npc) and npc.state not in ["warning", "alerted", "seeking_help", "disabled"] and npc.global_position.distance_to(end) <= 8.0:
   npc.observe_disturbance(end)
 return "Coin tossed. Nearby people may investigate; your permanent reward is retained."
