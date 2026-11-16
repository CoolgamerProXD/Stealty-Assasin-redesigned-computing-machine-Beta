class_name MissionEquipment
extends RefCounted
## Per-deployment state; campaign decides which optional item is permitted.
var available: Array[String] = ["training_sidearm"]
var selected: String = "training_sidearm"
var charges: int = 5
var coins_remaining: int = 0

func configure(progress: CampaignProgress, mission_id: String) -> void:
 available = ["training_sidearm"]
 if progress.selected != "training_sidearm" and progress.item_allowed(progress.selected, mission_id):
  available.append(progress.selected)
 selected = progress.selected if available.has(progress.selected) else "training_sidearm"
 charges = 5
 coins_remaining = progress.equipped_coins if mission_id != "initiation" else 0

func select_slot(slot: int) -> bool:
 if slot < 0 or slot >= available.size(): return false
 selected = available[slot]
 return true

func snapshot() -> Dictionary:
 return {"available": available.duplicate(), "selected": selected, "charges": charges, "coins_remaining": coins_remaining}

func restore(data: Variant, progress: CampaignProgress, mission_id: String) -> void:
 if not data is Dictionary: return # Old checkpoints retain freshly provisioned loadout.
 available = ["training_sidearm"]
 var raw: Variant = data.get("available", [])
 if raw is Array and "quiet_line" in raw and progress.item_allowed("quiet_line", mission_id):
  available.append("quiet_line")
 var desired: Variant = data.get("selected", "training_sidearm")
 selected = desired if desired is String and available.has(desired) else "training_sidearm"
 var amount: Variant = data.get("charges", 5)
 charges = clampi(int(amount), 0, 5) if (amount is int or amount is float) and is_finite(float(amount)) else 5

 # Old checkpoints had no coin field: retain the freshly provisioned loadout.
 var coins: Variant = data.get("coins_remaining", coins_remaining)
 var max_coins: int = progress.equipped_coins if mission_id != "initiation" else 0
 coins_remaining = clampi(int(coins), 0, max_coins) if (coins is int or coins is float) and is_finite(float(coins)) else max_coins
