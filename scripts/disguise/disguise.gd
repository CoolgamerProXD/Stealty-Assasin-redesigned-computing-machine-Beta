class_name DisguiseDefinition
extends Resource

@export var display_name: String = "Visitor"
@export_enum("visitor", "staff", "security", "manager") var role: String = "visitor"
@export var color: Color = Color(0.16, 0.23, 0.3)
