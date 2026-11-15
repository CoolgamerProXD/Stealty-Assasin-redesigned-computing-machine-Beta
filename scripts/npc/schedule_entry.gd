class_name ScheduleEntry
extends Resource

@export var destination: Vector3 = Vector3.ZERO
@export var activity: String = "working"
@export_range(0.1, 300.0) var duration: float = 5.0

func _init(point: Vector3 = Vector3.ZERO, action: String = "working", seconds: float = 5.0) -> void:
 destination = point
 activity = action
 duration = seconds
