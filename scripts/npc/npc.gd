class_name HotelNpc
extends CharacterBody3D
signal state_changed(npc: HotelNpc, new_state: String)

const SPEED: float = 1.45
var profile: NpcProfile
var player: HotelPlayer
var memory: NpcMemory = NpcMemory.new()
var state: String = "idle"
var suspicion: float = 0.0
var schedule_index: int = 0
var activity_time: float = 0.0
var investigation_target: Vector3
var investigation_time: float = 0.0
var perception_clock: float = 0.0
var agent: NavigationAgent3D
var facing: Vector3 = Vector3.FORWARD
var stunned_time: float = 0.0
var person: StylizedPerson

func _ready() -> void:
 if profile == null: profile = NpcProfile.new()
 var collision := CollisionShape3D.new()
 var shape := CapsuleShape3D.new()
 shape.radius = 0.3
 shape.height = 1.7
 collision.shape = shape
 collision.position.y = 0.85
 add_child(collision)
 person = StylizedPerson.new()
 person.role = profile.occupation
 person.appearance_seed = profile.identity.hash()
 add_child(person)
 agent = NavigationAgent3D.new()
 agent.path_desired_distance = 0.35
 agent.target_desired_distance = 0.45
 add_child(agent)
 if not profile.schedule.is_empty():
  set_state("walking")
  agent.target_position = profile.schedule[0].destination

func set_state(next: String) -> void:
 if state == next: return
 state = next
 state_changed.emit(self, state)

func observe_trespass(point: Vector3) -> void:
 # Repeated sightings update awareness, but only the first creates a memory.
 if state != "investigating" and state != "suspicious":
  memory.observe("trespass", point, 1.0)
 investigation_target = point
 suspicion = minf(100.0, suspicion + 18.0 + profile.alertness * 12.0)
 investigation_time = 0.0
 set_state("suspicious")
 if agent: agent.target_position = point

func advance_simulation(delta: float) -> void:
 memory.tick(delta)
 if state == "suspicious":
  set_state("investigating")
 elif state == "investigating":
  investigation_time += delta
  if investigation_time >= 6.0 + profile.curiosity * 4.0:
   suspicion = maxf(0.0, suspicion - 40.0)
   set_state("returning")
   if agent and not profile.schedule.is_empty(): agent.target_position = profile.schedule[schedule_index].destination
 elif state == "returning":
  if agent == null or agent.is_navigation_finished(): set_state("walking")
 elif state != "walking" and not profile.schedule.is_empty():
  activity_time += delta
  if activity_time >= profile.schedule[schedule_index].duration:
   activity_time = 0.0
   schedule_index = (schedule_index + 1) % profile.schedule.size()
   set_state("walking")
   if agent: agent.target_position = profile.schedule[schedule_index].destination
 if state not in ["suspicious", "investigating"]:
  suspicion = maxf(0.0, suspicion - delta * 3.0)

func can_see(target: Vector3, unobstructed: bool = true) -> bool:
 var offset := target - global_position
 offset.y = 0.0
 if offset.length() > 7.0 or offset.length() < 0.01: return false
 return unobstructed and facing.normalized().dot(offset.normalized()) >= 0.5

func observe_disturbance(point: Vector3) -> void:
 if state in ["suspicious", "investigating", "disabled"]: return
 memory.observe("disturbance", point, 1.0)
 investigation_target = point
 suspicion = minf(100.0, suspicion + 35.0)
 investigation_time = 0.0
 set_state("suspicious")
 if agent: agent.target_position = point

func _physics_process(delta: float) -> void:
 if profile == null: return
 if stunned_time > 0.0:
  stunned_time = maxf(0.0, stunned_time - delta)
  if person: person.rotation.z = move_toward(person.rotation.z, 1.0, delta * 3.0)
  velocity = Vector3.ZERO
  if stunned_time == 0.0:
   set_state("returning")
   if agent and not profile.schedule.is_empty(): agent.target_position = profile.schedule[schedule_index].destination
  return
 if person: person.rotation.z = move_toward(person.rotation.z, 0.0, delta * 3.0)
 advance_simulation(delta)
 # Perception is throttled by the physics clock, not checked every frame.
 perception_clock += delta
 if perception_clock >= 0.4:
  perception_clock = 0.0
  if player and not AccessRules.can_enter(player.role, AccessRules.area_at(player.global_position)) and can_see(player.global_position):
   var ray_start := global_position + Vector3.UP * 1.3
   # Target the actual stance, so cover geometry, not a magic crouch bonus,
   # determines whether the player is visible.
   var ray_end := player.global_position + Vector3.UP * (player.stance_height * 0.65)
   var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end)
   query.exclude = [get_rid(), player.get_rid()]
   var clear := get_world_3d().direct_space_state.intersect_ray(query).is_empty()
   if can_see(player.global_position, clear): observe_trespass(player.global_position)
 if agent and state in ["walking", "returning", "investigating"]:
  if agent.is_navigation_finished():
   if state == "walking" and not profile.schedule.is_empty():
    activity_time = 0.0
    set_state(profile.schedule[schedule_index].activity)
   velocity.x = 0.0
   velocity.z = 0.0
  else:
   var direction := agent.get_next_path_position() - global_position
   direction.y = 0.0
   direction = direction.normalized()
   facing = direction if direction.length_squared() > 0.0 else facing
   velocity.x = direction.x * SPEED
   velocity.z = direction.z * SPEED
 else:
  velocity.x = 0.0
  velocity.z = 0.0
 if not is_on_floor(): velocity.y -= 9.8 * delta
 else: velocity.y = -0.1
 move_and_slide()
 if person:
  person.idle_activity = state
  person.animate_motion(delta, Vector2(velocity.x, velocity.z).length())
  if velocity.length_squared() > 0.1:
   person.rotation.y = lerp_angle(person.rotation.y, atan2(-velocity.x, -velocity.z), 1.0 - exp(-delta * 8.0))
