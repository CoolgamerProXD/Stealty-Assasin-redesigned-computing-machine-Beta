class_name AccessRules
extends RefCounted

static func can_enter(role: String, area: String) -> bool:
 if area == "public": return true
 # Preserve old scene/checkpoint role labels while new operations use exact role
 # permissions for each market, office, security and facility zone.
 if area == "staff" and role in ["staff", "employee", "office", "security", "manager"]: return true
 if area == "secure" and role in ["security", "manager", "corporate_security", "facility_security", "facility_director"]: return true
 return DisguiseSystem.can_access(role, area)

static func area_at(position: Vector3) -> String:
 if position.x > 7.0: return "secure"
 if position.x > 2.0: return "staff"
 return "public"
