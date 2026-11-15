class_name NpcMemory
extends RefCounted
## Local observations only; no globally shared knowledge.
var observations: Array[Dictionary] = []
var retention_seconds: float = 30.0

func observe(kind: String, position: Vector3, importance: float = 1.0) -> void:
 observations.append({"kind": kind, "position": position, "importance": importance, "age": 0.0, "source": "direct"})

func tick(delta: float) -> void:
 # Expire in place rather than allocating a filtered array every physics frame.
 for index: int in range(observations.size() - 1, -1, -1):
  var observation: Dictionary = observations[index]
  observation["age"] = float(observation["age"]) + delta
  if float(observation["age"]) >= retention_seconds * maxf(0.1, float(observation["importance"])):
   observations.remove_at(index)
