class_name NpcProfile
extends Resource

@export var identity: String = "Unnamed"
@export_enum("civilian", "employee", "security", "manager", "special") var occupation: String = "employee"
@export_range(0.0, 1.0) var alertness: float = 0.5
@export_range(0.0, 1.0) var curiosity: float = 0.5
@export_range(0.0, 1.0) var sociability: float = 0.5
@export_range(0.0, 1.0) var patience: float = 0.5
@export_range(0.0, 1.0) var confidence: float = 0.5
@export var schedule: Array[ScheduleEntry] = []
