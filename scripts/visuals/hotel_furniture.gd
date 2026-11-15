extends Node3D
## Shared, authored low-poly furniture with a Meridian-specific material palette.
## Meshes: Kenney Furniture Kit (CC0); see assets/kenney_furniture/LICENSE.txt.
## Collision is authored separately in hotel.gd, so mission paths remain explicit.
const SOFA := preload("res://assets/kenney_furniture/loungeSofaLong.glb")
const ARMCHAIR := preload("res://assets/kenney_furniture/loungeChair.glb")
const DINING_CHAIR := preload("res://assets/kenney_furniture/chairCushion.glb")
const COFFEE_TABLE := preload("res://assets/kenney_furniture/tableCoffeeGlass.glb")
const FLOOR_LAMP := preload("res://assets/kenney_furniture/lampRoundFloor.glb")
const PLANT := preload("res://assets/kenney_furniture/pottedPlant.glb")
const BOOKS := preload("res://assets/kenney_furniture/books.glb")
const LAPTOP := preload("res://assets/kenney_furniture/laptop.glb")
var palette: Dictionary = {}

func build() -> void:
 name = "HotelFurniture"
 # Replaces decorative block sofas in the lobby; no new lobby collision is
 # introduced on the pre-existing civilian route or old checkpoint locations.
 _place(SOFA, Vector3(-7.8,0,2.1), Vector3(0.49,0,0), Vector3(2.05,1.9,1.0), 0.0)
 _place(SOFA, Vector3(-4.8,0,3.7), Vector3(0.49,0,0), Vector3(2.05,1.9,1.0), 0.0)
 _place(COFFEE_TABLE, Vector3(-7,0,3.25), Vector3(-0.13,0,-0.1), Vector3(1.9,1.75,1.7), 0.0)
 _place(LAPTOP, Vector3(-5.8,1.12,-4.8), Vector3(0.132,0,-0.12), Vector3(1.2,1.2,1.2), 0.0)
 # Wing sofas reuse existing collision envelopes; furniture stays clear of the
 # ground-floor local navigation strip and the ramp.
 for x: float in [-38.0,-30.0,-22.0,-15.0]:
  _place(SOFA, Vector3(x,0,11), Vector3(0.49,0,0), Vector3(2.25,1.9,1.0), PI)
  _place(COFFEE_TABLE, Vector3(x,0,9.2), Vector3(-0.13,0,-0.1), Vector3(2.5,2.0,2.1), 0.0)
  for z: float in [-11.55,-8.45]:
   _place(DINING_CHAIR, Vector3(x,0,z), Vector3(0.10,0,-0.10), Vector3(2.2,1.9,1.9), 0.0 if z < -10.0 else PI)
 for x: float in [-40.3,-34.0,-26.0,-18.0,-13.5]:
  _place(PLANT, Vector3(x,0,13.7), Vector3(0,0,0), Vector3(2.5,2.5,2.5), 0.0)
 for x: float in [-35.0,-19.0]:
  _place(FLOOR_LAMP, Vector3(x,0,14.5), Vector3(0.06,0,-0.06), Vector3(1.8,1.8,1.8), 0.0)
 # Suite reading area uses the open wall, with no added obstacles near Locke.
 _place(ARMCHAIR, Vector3(-40.6,3.6,-7.1), Vector3(0.245,0,-0.205), Vector3(1.7,1.8,1.7), -PI / 2.0)
 _place(BOOKS, Vector3(-40.0,4.53,-11.2), Vector3(0.075,0,-0.047), Vector3(1.2,1.2,1.2), 0.0)

func _place(scene: PackedScene, position_at_floor: Vector3, center: Vector3, size: Vector3, yaw: float) -> void:
 var holder := Node3D.new()
 holder.position = position_at_floor
 holder.rotation.y = yaw
 add_child(holder)
 var model := scene.instantiate() as Node3D
 holder.add_child(model)
 model.scale = size
 model.position = -center * size
 _apply_palette(model)

func _apply_palette(node: Node) -> void:
 if node is MeshInstance3D:
  var mesh_node := node as MeshInstance3D
  mesh_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  for i: int in range(mesh_node.mesh.get_surface_count()):
   var original := mesh_node.get_active_material(i)
   if not original is StandardMaterial3D: continue
   var key := original.resource_name.to_lower()
   if not palette.has(key):
    var material := original.duplicate() as StandardMaterial3D
    if key == "carpet": material.albedo_color = Color(0.20,0.34,0.33)
    elif key == "wood": material.albedo_color = Color(0.30,0.18,0.12)
    elif key == "wooddark": material.albedo_color = Color(0.23,0.16,0.11)
    elif key == "plant": material.albedo_color = Color(0.24,0.43,0.24)
    elif key == "metal": material.albedo_color = Color(0.55,0.45,0.32)
    material.roughness = 0.75 if key != "glass" else 0.18
    palette[key] = material
   mesh_node.set_surface_override_material(i, palette[key])
 for child: Node in node.get_children(): _apply_palette(child)
