class_name Interactable
extends Node3D
signal activated(interactable: Interactable)
@export var label: String = "Inspect"
@export var kind: String = "clue"
@export var identifier: String = ""
@export var required_role: String = ""
var used: bool = false

func available(role: String) -> bool:
 return (required_role.is_empty() or role == required_role) and not used

func interact(role: String) -> bool:
 if not available(role): return false
 activated.emit(self)
 return true
