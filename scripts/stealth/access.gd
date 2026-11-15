class_name AccessRules
extends RefCounted

static func can_enter(role: String, area: String) -> bool:
 match area:
  "public": return true
  "staff": return role in ["staff", "security", "manager"]
  "secure": return role in ["security", "manager"]
  _: return false

static func area_at(position: Vector3) -> String:
 if position.x > 7.0: return "secure"
 if position.x > 2.0: return "staff"
 return "public"
