class_name HotelNpc
extends CharacterBody3D
signal state_changed(npc: HotelNpc, new_state: String)
signal trespass_notice(npc: HotelNpc, text: String, exit_point: Vector3)

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
# Terminal mission state is independent of temporary incapacitation.
var objective_completed: bool = false
var completed_incapacitated: bool = false
var warning_remaining: float = 0.0
var alert_remaining: float = 0.0
var warning_cooldown: float = 0.0
var alert_pulse_clock: float = 0.0
var alert_audio: AudioStreamPlayer3D
var exit_hint: Vector3 = Vector3.ZERO
var help_target: HotelNpc
var help_incident: Vector3 = Vector3.ZERO
var help_reported: bool = false

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
 if profile.occupation == "security":
  person.add_sidearm()
  alert_audio = AudioStreamPlayer3D.new()
  alert_audio.stream = ProceduralSound.tone(165.0, 0.10, 0.10)
  alert_audio.max_distance = 9.0
  add_child(alert_audio)
 agent = NavigationAgent3D.new()
 agent.path_desired_distance = 0.35
 agent.target_desired_distance = 0.45
 add_child(agent)
 if not profile.schedule.is_empty():
  set_state("walking")
  agent.target_position = profile.schedule[0].destination

func set_state(next: String) -> void:
 if objective_completed and next != "objective_completed": return
 if state == next: return
 state = next
 state_changed.emit(self, state)

func complete_objective(incapacitated: bool) -> void:
 if objective_completed: return
 objective_completed = true
 completed_incapacitated = incapacitated
 stunned_time = 0.0
 velocity = Vector3.ZERO
 set_state("objective_completed")
 if person: person.rotation.z = 1.0 if incapacitated else 0.0

func restore_objective(completed: bool, incapacitated: bool) -> void:
 # Loading an earlier checkpoint deliberately restores its earlier state.
 objective_completed = false
 completed_incapacitated = false
 stunned_time = 0.0
 if completed:
  complete_objective(incapacitated)
 else:
  set_state("returning")
  if person: person.rotation.z = 0.0
  if agent and not profile.schedule.is_empty(): agent.target_position = profile.schedule[schedule_index].destination

func incapacitate(seconds: float) -> bool:
 if objective_completed or stunned_time > 0.0: return false
 stunned_time = maxf(0.0, seconds)
 if stunned_time <= 0.0: return false
 set_state("disabled")
 return true

func observe_trespass(point: Vector3) -> void:
 if objective_completed or stunned_time > 0.0: return
 # Repeated sightings update awareness, but only the first creates a memory.
 if state != "investigating" and state != "suspicious":
  memory.observe("trespass", point, 1.0)
 investigation_target = point
 suspicion = minf(100.0, suspicion + 18.0 + profile.alertness * 12.0)
 investigation_time = 0.0
 set_state("suspicious")
 if agent: agent.target_position = point

# Perception invokes this once per incident, not once per sighting. The same
# local suspicion/memory remains in use; visitors seek help rather than enforce.
func warn_trespass(point: Vector3, permitted_exit: Vector3, area: String = "staff") -> void:
 if objective_completed or stunned_time > 0.0 or warning_cooldown > 0.0 or state in ["warning", "alerted", "seeking_help"]: return
 memory.observe("trespass", point, 1.0)
 suspicion = minf(100.0, suspicion + 18.0 + profile.alertness * 12.0)
 exit_hint = permitted_exit
 var permission_role := "staff" if profile.occupation == "employee" else profile.occupation
 if profile.occupation == "civilian" or not AccessRules.can_enter(permission_role, area):
  alert_remaining = 4.0
  set_state("seeking_help")
  _seek_help(point)
  trespass_notice.emit(self, profile.identity + ": Someone is in a restricted area. I should find staff.", exit_hint)
 else:
  warning_remaining = 3.0
  set_state("warning")
  trespass_notice.emit(self, profile.identity + ": This area is restricted. Please leave now.", exit_hint)

func tick_trespass(delta: float, still_restricted: bool) -> void:
 warning_cooldown = maxf(0.0, warning_cooldown - delta)
 if state not in ["warning", "alerted", "seeking_help"]: return
 if not still_restricted:
  warning_remaining = 0.0
  alert_remaining = 0.0
  help_target = null
  warning_cooldown = 3.0
  suspicion = maxf(0.0, suspicion - 20.0)
  set_state("returning")
  if agent and not profile.schedule.is_empty(): agent.target_position = profile.schedule[schedule_index].destination
  trespass_notice.emit(self, profile.identity + ": Thank you for leaving.", exit_hint)
  return
 if state == "warning":
  warning_remaining = maxf(0.0, warning_remaining - delta)
  if warning_remaining <= 0.0:
   alert_remaining = 6.0
   if profile.occupation == "security":
    suspicion = maxf(suspicion, 80.0)
    set_state("alerted")
    alert_pulse_clock = 1.2
    trespass_notice.emit(self, profile.identity + ": Security alert. Leave the restricted area.", exit_hint)
   else:
    set_state("seeking_help")
    _seek_help(player.global_position if player else investigation_target)
    trespass_notice.emit(self, profile.identity + ": I am seeking security.", exit_hint)
 else:
  alert_remaining -= delta
  if alert_remaining <= 0.0:
   warning_cooldown = 5.0
   set_state("returning")
   if agent and not profile.schedule.is_empty(): agent.target_position = profile.schedule[schedule_index].destination

func _seek_help(incident: Vector3) -> void:
 if not agent: return
 help_incident = incident
 help_reported = false
 help_target = null
 var best := 14.0
 # Local witnesses look for an available guard in the same scene, not a
 # global radio broadcast. If none is nearby they return to a safe route.
 for candidate: Node in get_parent().get_children():
  if candidate is HotelNpc and candidate != self:
   var officer := candidate as HotelNpc
   var distance := global_position.distance_to(officer.global_position)
   if officer.profile.occupation == "security" and not officer.objective_completed and officer.stunned_time <= 0.0 and distance < best:
    best = distance
    help_target = officer
 if help_target:
  agent.target_position = help_target.global_position
 elif not profile.schedule.is_empty(): agent.target_position = profile.schedule[schedule_index].destination
 else:
  var away := global_position - incident
  away.y = 0.0
  if away.length_squared() < 0.01: away = Vector3.FORWARD
  agent.target_position = global_position + away.normalized() * 3.0

func _try_deliver_report() -> bool:
 if state != "seeking_help" or help_reported or not is_instance_valid(help_target): return false
 if help_target.objective_completed or help_target.stunned_time > 0.0 or global_position.distance_to(help_target.global_position) > 2.5: return false
 var ray := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, help_target.global_position + Vector3.UP)
 ray.exclude = [get_rid(), help_target.get_rid()]
 if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): return false
 help_target.observe_disturbance(help_incident)
 help_reported = true
 trespass_notice.emit(self, profile.identity + ": Security, please check that area.", exit_hint)
 return true

# A fictional short-range assessment pulse. Solid geometry blocks it; there is
# no health, graphic harm, permanent damage or open-ended pursuit.
func _fire_alert_pulse() -> bool:
 if state != "alerted" or not player or global_position.distance_to(player.global_position) > 7.0: return false
 var start_point := global_position + Vector3.UP * 1.3
 var end_point := player.global_position + Vector3.UP * (player.stance_height * 0.65)
 var ray := PhysicsRayQueryParameters3D.create(start_point, end_point)
 ray.exclude = [get_rid(), player.get_rid()]
 if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): return false
 player.receive_alert_pulse()
 if person: person.fire_weapon()
 if alert_audio: alert_audio.play()
 trespass_notice.emit(self, profile.identity + ": Security pulse. Leave the restricted area.", exit_hint)
 return true

func _player_access_area() -> String:
 if not player: return "public"
 var world := player.get_parent()
 if world and world.has_method("player_access_area"): return str(world.call("player_access_area", player.global_position))
 return AccessRules.area_at(player.global_position)

func _permitted_exit() -> Vector3:
 if not player: return global_position
 var world := player.get_parent()
 if world and world.has_method("permitted_exit"): return world.call("permitted_exit", player.global_position)
 return Vector3(1.5, player.global_position.y, player.global_position.z)

func advance_simulation(delta: float) -> void:
 if objective_completed or stunned_time > 0.0: return
 memory.tick(delta)
 if state in ["warning", "alerted", "seeking_help"]: return
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
 if objective_completed or stunned_time > 0.0 or state in ["suspicious", "investigating", "disabled", "warning", "alerted", "seeking_help"]: return
 memory.observe("disturbance", point, 1.0)
 investigation_target = point
 suspicion = minf(100.0, suspicion + 35.0)
 investigation_time = 0.0
 set_state("suspicious")
 if agent: agent.target_position = point

func _physics_process(delta: float) -> void:
 if profile == null: return
 if objective_completed:
  velocity = Vector3.ZERO
  if person: person.rotation.z = 1.0 if completed_incapacitated else 0.0
  return
 if stunned_time > 0.0:
  stunned_time = maxf(0.0, stunned_time - delta)
  if person: person.rotation.z = move_toward(person.rotation.z, 1.0, delta * 3.0)
  velocity = Vector3.ZERO
  if stunned_time == 0.0:
   set_state("returning")
   if agent and not profile.schedule.is_empty(): agent.target_position = profile.schedule[schedule_index].destination
  return
 if person: person.rotation.z = move_toward(person.rotation.z, 0.0, delta * 3.0)
 if player: tick_trespass(delta, not AccessRules.can_enter(player.role, _player_access_area()))
 advance_simulation(delta)
 if state == "seeking_help": _try_deliver_report()
 # Perception is throttled by the physics clock, not checked every frame.
 perception_clock += delta
 if perception_clock >= 0.4:
  perception_clock = 0.0
  if player and not AccessRules.can_enter(player.role, _player_access_area()) and can_see(player.global_position):
   var ray_start := global_position + Vector3.UP * 1.3
   # Target the actual stance, so cover geometry, not a magic crouch bonus,
   # determines whether the player is visible.
   var ray_end := player.global_position + Vector3.UP * (player.stance_height * 0.65)
   var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end)
   query.exclude = [get_rid(), player.get_rid()]
   var clear := get_world_3d().direct_space_state.intersect_ray(query).is_empty()
   if can_see(player.global_position, clear): warn_trespass(player.global_position, _permitted_exit(), _player_access_area())
 if agent and state in ["walking", "returning", "investigating", "seeking_help"]:
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
 if state == "alerted" and player:
  var to_player := player.global_position - global_position
  to_player.y = 0.0
  if to_player.length_squared() > 0.01: facing = to_player.normalized()
  alert_pulse_clock -= delta
  if alert_pulse_clock <= 0.0:
   # Alert animations may be used elsewhere, but security only fires at a
   # currently known trespasser and only while the player is still inside.
   if alert_remaining > 0.0 and warning_remaining <= 0.0 and not AccessRules.can_enter(player.role, _player_access_area()):
    _fire_alert_pulse()
   alert_pulse_clock = 1.4
 if person:
  person.idle_activity = state
  if profile.occupation == "security":
   person.weapon_equipped = state == "alerted"
   person.weapon_aiming = state == "alerted"
  var previous_heading := person.rotation.y
  if velocity.length_squared() > 0.1:
   person.rotation.y = lerp_angle(person.rotation.y, atan2(-velocity.x, -velocity.z), 1.0 - exp(-delta * 8.0))
  elif state == "alerted" and facing.length_squared() > 0.01:
   person.rotation.y = lerp_angle(person.rotation.y, atan2(-facing.x, -facing.z), 1.0 - exp(-delta * 8.0))
  var turn_rate := angle_difference(previous_heading, person.rotation.y) / maxf(delta, 0.001)
  person.animate_motion(delta, Vector2(velocity.x, velocity.z).length(), turn_rate)
