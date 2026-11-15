class_name HotelLayout
extends RefCounted
## A manually authored navigation grid. The two narrow bands correspond to
## physical partitions; only the two doorway cells in each band are walkable.
const X_EDGES := [-11.5, 1.5, 2.5, 6.5, 7.5, 11.5]
const Z_EDGES := [-7.5, -3.65, -2.35, 2.35, 3.65, 7.5]

static func navigation_mesh() -> NavigationMesh:
 var mesh := NavigationMesh.new()
 var vertices := PackedVector3Array()
 for z: float in Z_EDGES:
  for x: float in X_EDGES:
   vertices.append(Vector3(x, 0.0, z))
 mesh.vertices = vertices
 var width: int = X_EDGES.size()
 for row: int in range(Z_EDGES.size() - 1):
  for col: int in range(X_EDGES.size() - 1):
   if col in [1, 3] and row not in [1, 3]: continue
   var a: int = row * width + col
   # Counter-clockwise when viewed from above; normals point upward.
   mesh.add_polygon(PackedInt32Array([a, a + width, a + width + 1, a + 1]))
 return mesh

static func is_safe_player_position(point: Vector3) -> bool:
 if not point.is_finite() or point.y < 0.0 or point.y > 6.0: return false
 if point.x < -11.0:
  return point.x >= -41.0 and absf(point.z) <= 15.0
 if absf(point.x) > 11.0 or absf(point.z) > 7.0: return false
 # Upstairs spans the original hotel too; its lower partitions do not continue.
 if point.y >= 3.3: return true
 for boundary: float in [2.0, 7.0]:
  if absf(point.x - boundary) < 0.44 and not (absf(point.z) >= 2.35 and absf(point.z) <= 3.65):
   return false
 return true
