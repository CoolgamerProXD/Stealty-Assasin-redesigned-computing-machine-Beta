class_name NpcMemory
extends RefCounted
## Local observations only; no globally shared knowledge.
var observations: Array[Dictionary] = []
var retention_seconds: float = 30.0

func observe(kind: String, position: Vector3, importance: float = 1.0) -> void:
 observations.append({"kind": kind, "position": position, "importance": importance, "age": 0.0, "source": "direct"})

func tick(delta: float) -> void:
 for observation: Dictionary in observations:
  observation["age"] = float(observation["age"]) + delta
 observations = observations.filter(func(entry: Dictionary) -> bool: return float(entry["age"]) < retention_seconds * maxf(0.1, float(entry["importance"])))
