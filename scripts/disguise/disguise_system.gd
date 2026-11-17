class_name DisguiseSystem
extends RefCounted
## Role-aware outfit definitions shared by NPCs, campaign saves, access checks,
## and the field inventory. All outfits are original procedural wardrobe sets.
const OUTFITS := {
	"civilian": {"name": "Civilian clothes", "category": "Civilian", "role": "visitor", "color": Color(0.20, 0.21, 0.25), "permissions": ["public"]},
	"market_vendor": {"name": "Market vendor apron", "category": "Market", "role": "vendor", "color": Color(0.56, 0.29, 0.18), "permissions": ["public", "market_staff", "service_corridor"]},
	"hospitality": {"name": "Restaurant service uniform", "category": "Hospitality", "role": "hospitality", "color": Color(0.31, 0.35, 0.39), "permissions": ["public", "hospitality_staff", "service_corridor"]},
	"office_employee": {"name": "Office employee clothes", "category": "Office", "role": "office", "color": Color(0.25, 0.37, 0.45), "permissions": ["public", "office_staff"]},
	"maintenance": {"name": "Maintenance coveralls", "category": "Maintenance", "role": "maintenance", "color": Color(0.26, 0.40, 0.36), "permissions": ["public", "service_corridor", "maintenance_bay"]},
	"hotel_staff": {"name": "Hotel staff uniform", "category": "Hotel", "role": "hotel_staff", "color": Color(0.26, 0.36, 0.42), "permissions": ["public", "hotel_staff", "service_corridor"]},
	"private_security": {"name": "Private security uniform", "category": "Security", "role": "private_security", "color": Color(0.15, 0.24, 0.34), "permissions": ["public", "security_post"]},
	"corporate_security": {"name": "Corporate security uniform", "category": "Security", "role": "corporate_security", "color": Color(0.12, 0.25, 0.35), "permissions": ["public", "security_post", "corporate_staff"]},
	"executive": {"name": "Executive suit", "category": "Management", "role": "executive", "color": Color(0.25, 0.22, 0.31), "permissions": ["public", "corporate_staff", "executive_suite"]},
	"facility_technician": {"name": "Facility technician coveralls", "category": "Special facility", "role": "facility_technician", "color": Color(0.18, 0.39, 0.39), "permissions": ["public", "service_corridor", "facility_staff", "facility_maintenance"]},
	"facility_security": {"name": "Facility security uniform", "category": "Special facility", "role": "facility_security", "color": Color(0.15, 0.22, 0.33), "permissions": ["public", "security_post", "facility_staff", "facility_checkpoint"]},
	"facility_research": {"name": "Research staff uniform", "category": "Special facility", "role": "facility_research", "color": Color(0.35, 0.43, 0.44), "permissions": ["public", "facility_staff", "facility_research", "buddha_interior"]},
	"facility_director": {"name": "Facility director suit", "category": "Special facility", "role": "facility_director", "color": Color(0.31, 0.24, 0.18), "permissions": ["public", "facility_staff", "facility_checkpoint", "facility_research", "facility_ops", "buddha_interior"]}
}

static func has_outfit(id: String) -> bool:
	return OUTFITS.has(id)

static func outfit(id: String) -> Dictionary:
	return OUTFITS.get(id, OUTFITS["civilian"]).duplicate(true)

static func all_ids() -> Array[String]:
	var ids: Array[String] = []
	for key: Variant in OUTFITS.keys(): ids.append(str(key))
	ids.sort()
	return ids

static func default_for_occupation(occupation: String) -> String:
	match occupation:
		"vendor": return "market_vendor"
		"hospitality": return "hospitality"
		"security": return "private_security"
		"corporate_security": return "corporate_security"
		"manager", "executive": return "executive"
		"technician", "maintenance": return "maintenance"
		"facility_technician": return "facility_technician"
		"facility_security": return "facility_security"
		"facility_research": return "facility_research"
		"facility_director": return "facility_director"
		"hotel_staff": return "hotel_staff"
		"employee", "office": return "office_employee"
		_: return "civilian"

static func can_access(outfit_id_or_role: String, area: String) -> bool:
	if area == "public": return true
	if OUTFITS.has(outfit_id_or_role): return area in OUTFITS[outfit_id_or_role]["permissions"]
	for id: String in all_ids():
		if str(OUTFITS[id]["role"]) == outfit_id_or_role and area in OUTFITS[id]["permissions"]: return true
	return false

static func role_for_outfit(outfit_id: String) -> String:
	return str(outfit(outfit_id).get("role", "visitor"))

static func title_for_role(role: String) -> String:
	for id: String in all_ids():
		if role_for_outfit(id) == role: return str(OUTFITS[id]["name"])
	return "Civilian clothes"
