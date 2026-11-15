class_name SaveStore
extends RefCounted
const VERSION: int = 1

static func write(path: String, payload: Dictionary) -> bool:
 var temporary := path + ".tmp"
 var backup := path + ".bak"
 var file := FileAccess.open(temporary, FileAccess.WRITE)
 if file == null: return false
 file.store_string(JSON.stringify({"version": VERSION, "data": payload}))
 file.flush()
 var error := file.get_error()
 file.close()
 if error != OK:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
  return false
 var absolute := ProjectSettings.globalize_path(path)
 var temp_absolute := ProjectSettings.globalize_path(temporary)
 var backup_absolute := ProjectSettings.globalize_path(backup)
 if FileAccess.file_exists(path):
  if not _read_one(path).is_empty():
   if FileAccess.file_exists(backup) and DirAccess.remove_absolute(backup_absolute) != OK:
    DirAccess.remove_absolute(temp_absolute)
    return false
   if DirAccess.rename_absolute(absolute, backup_absolute) != OK:
    DirAccess.remove_absolute(temp_absolute)
    return false
  elif DirAccess.remove_absolute(absolute) != OK:
   # Preserve a valid backup if the current primary was already damaged.
   DirAccess.remove_absolute(temp_absolute)
   return false
 if DirAccess.rename_absolute(temp_absolute, absolute) != OK:
  if FileAccess.file_exists(backup): DirAccess.rename_absolute(backup_absolute, absolute)
  DirAccess.remove_absolute(temp_absolute)
  return false
 return true

static func read(path: String) -> Dictionary:
 var result := _read_one(path)
 if not result.is_empty(): return result
 return _read_one(path + ".bak")

static func _read_one(path: String) -> Dictionary:
 if not FileAccess.file_exists(path): return {}
 var file := FileAccess.open(path, FileAccess.READ)
 if file == null: return {}
 var parsed: Variant = JSON.parse_string(file.get_as_text())
 if not parsed is Dictionary: return {}
 if parsed.get("version", -1) != VERSION or not parsed.get("data") is Dictionary: return {}
 return parsed["data"]
