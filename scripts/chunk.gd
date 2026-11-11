class_name VoxelChunk
extends StaticBody3D
const SIZE := 16
var data := PackedByteArray()
var coord: Vector3i
var terrain: Node3D
var visual := MeshInstance3D.new()
var collision := CollisionShape3D.new()
const DIRS = [Vector3i.RIGHT,Vector3i.LEFT,Vector3i.UP,Vector3i.DOWN,Vector3i.BACK,Vector3i.FORWARD]
const QUADS = [
	[Vector3(1,0,0),Vector3(1,1,0),Vector3(1,1,1),Vector3(1,0,1)],
	[Vector3(0,0,1),Vector3(0,1,1),Vector3(0,1,0),Vector3(0,0,0)],
	[Vector3(0,1,1),Vector3(1,1,1),Vector3(1,1,0),Vector3(0,1,0)],
	[Vector3(0,0,0),Vector3(1,0,0),Vector3(1,0,1),Vector3(0,0,1)],
	[Vector3(1,0,1),Vector3(1,1,1),Vector3(0,1,1),Vector3(0,0,1)],
	[Vector3(0,0,0),Vector3(0,1,0),Vector3(1,1,0),Vector3(1,0,0)]]
func _init() -> void:
	data.resize(4096)
	add_child(visual)
	add_child(collision)
func index(p: Vector3i) -> int: return p.x + 16*(p.y+16*p.z)
func rebuild() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := 0
	for z in 16:
		for y in 16:
			for x in 16:
				var p := Vector3i(x,y,z)
				var id: int = data[index(p)]
				if id == 0: continue
				for d in 6:
					if terrain.get_block(coord*16+p+DIRS[d]) != 0: continue
					faces += 1
					for i in [0,2,1,0,3,2]:
						st.set_normal(Vector3(DIRS[d]))
						st.set_color(Blocks.COLORS[id])
						st.add_vertex(Vector3(p)+QUADS[d][i])
	if faces == 0:
		visual.mesh = null
		collision.shape = null
		return
	var mesh := st.commit()
	visual.mesh = mesh
	visual.material_override = terrain.material
	collision.shape = mesh.create_trimesh_shape()
	terrain.rebuilds += 1
