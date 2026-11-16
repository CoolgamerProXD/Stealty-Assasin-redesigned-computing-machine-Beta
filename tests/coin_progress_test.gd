extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void:
 call_deferred("run")
func check(ok: bool, description: String) -> void:
 checks += 1
 if ok: print("COIN PASS: ", description)
 else:
  failures += 1
  printerr("COIN FAIL: ", description)
func run() -> void:
 var service := root.get_node("Campaign")
 var old_progress: Dictionary = service.progress.snapshot()
 var old_path: String = service.campaign_path
 var old_active: String = service.active_mission
 var temp := "user://coin_regression_%d.json" % Time.get_ticks_usec()
 service.campaign_path = temp
 service.progress.restore({})
 service.active_mission = "initiation"
 var world: Node3D = load("res://scenes/initiation.tscn").instantiate()
 root.add_child(world)
 await process_frame
 # Use the actual existing record interactions as the three assessment milestones.
 var records: Array[Interactable] = world.get("interactables")
 for i: int in range(3):
  var item: Interactable = records[i]
  world.call("_on_interaction", item)
  check(service.progress.completed_lessons.size() == i + 1, "lesson %d awards one permanent coin" % (i + 1))
  world.call("_on_interaction", item)
  check(service.progress.completed_lessons.size() == i + 1, "replaying lesson %d cannot duplicate its coin" % (i + 1))
  var restarted := CampaignProgress.new()
  restarted.configure(JSON.parse_string(FileAccess.get_file_as_string("res://resources/campaign.json")))
  restarted.restore(SaveStore.read(temp))
  check(restarted.completed_lessons.size() == i + 1, "lesson %d survives campaign reload" % (i + 1))
 check(not service.progress.award_lesson("unknown") and not service.progress.set_equipped_coins(4), "invalid lesson and over-equipping are rejected")
 check(service.progress.set_equipped_coins(2) and service.persist(), "equip two earned coins and persist loadout")
 var loaded := CampaignProgress.new()
 loaded.configure(JSON.parse_string(FileAccess.get_file_as_string("res://resources/campaign.json")))
 loaded.restore(SaveStore.read(temp))
 check(loaded.equipped_coins == 2 and loaded.completed_lessons.size() == 3, "equipped and earned coins persist separately")
 var equipment := MissionEquipment.new()
 equipment.configure(loaded, "the_streets")
 check(equipment.coins_remaining == 2, "later deployment receives equipped coins")
 equipment.coins_remaining -= 1
 var checkpoint := equipment.snapshot()
 equipment.configure(loaded, "the_streets")
 equipment.restore(checkpoint, loaded, "the_streets")
 check(equipment.coins_remaining == 1 and loaded.completed_lessons.size() == 3 and loaded.equipped_coins == 2, "checkpoint preserves temporary use without consuming permanent coins")
 equipment.configure(loaded, "the_streets")
 check(equipment.coins_remaining == 2, "new deployment replenishes equipped coins")
 equipment.configure(loaded, "initiation")
 check(equipment.coins_remaining == 0, "coins cannot be used during Initiation")
 loaded.restore({"completed": ["initiation"]})
 check(loaded.completed_lessons.size() == 3 and loaded.equipped_coins == 0, "completed legacy Initiation safely migrates all three rewards")
 loaded.restore({"completed_lessons": ["evaluation", "evaluation", "fake"], "equipped_coins": 3})
 check(loaded.completed_lessons.size() == 1 and loaded.equipped_coins == 1, "malformed duplicate rewards and loadout are bounded")
 # Exercise a real toss, not only the inventory counters.
 var player: HotelPlayer = world.get("player")
 var npcs: Array[HotelNpc] = world.get("npcs")
 for npc: HotelNpc in npcs: npc.set_physics_process(false)
 player.set_physics_process(false)
 player.global_position = Vector3(-10,0.05,4)
 player.rotation.y = 0.0
 player.equipment.configure(service.progress, "meridian")
 npcs[0].global_position = Vector3(-10,0.05,0)
 npcs[0].set_state("idle")
 await physics_frame
 var text := CoinDistraction.use(player, npcs, world)
 check(text.begins_with("Coin tossed") and player.equipment.coins_remaining == 1 and npcs[0].state == "suspicious", "a thrown coin spends mission stock and creates a local investigation")
 check(service.progress.completed_lessons.size() == 3 and service.progress.equipped_coins == 2, "throwing never spends permanent campaign rewards")
 world.queue_free()
 await process_frame
 service.progress.restore(old_progress)
 service.campaign_path = old_path
 service.active_mission = old_active
 for suffix: String in ["", ".bak", ".tmp"]:
  if FileAccess.file_exists(temp + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(temp + suffix))
 print("COIN RESULT: %d checks, %d failures" % [checks, failures])
 quit(0 if failures == 0 else 1)
