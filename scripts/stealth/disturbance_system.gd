class_name DisturbanceSystem
extends Node
## Local, throttled visual discovery of incapacitated people. No shared knowledge.
var npcs: Array[HotelNpc] = []
var clock := 0.0

func _physics_process(delta: float) -> void:
 clock -= delta
 if clock > 0.0: return
 clock = 0.8
 for observer: HotelNpc in npcs:
  if not is_instance_valid(observer) or observer.stunned_time > 0.0 or observer.state in ["suspicious", "investigating"]: continue
  for subject: HotelNpc in npcs:
   if not is_instance_valid(subject) or subject == observer or subject.stunned_time <= 0.0: continue
   if observer.global_position.distance_to(subject.global_position) > 6.0: continue
   if not observer.can_see(subject.global_position): continue
   var start := observer.global_position + Vector3.UP * 1.3
   var end := subject.global_position + Vector3.UP * 0.6
   var query := PhysicsRayQueryParameters3D.create(start, end)
   query.exclude = [observer.get_rid(), subject.get_rid()]
   if observer.get_world_3d().direct_space_state.intersect_ray(query).is_empty():
    observer.observe_disturbance(subject.global_position)
    break
