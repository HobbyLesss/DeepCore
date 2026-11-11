class_name Terrain
extends Node3D
var chunks: Dictionary = {}
var changes: Dictionary = {}
var generator := Generation.new()
var material := StandardMaterial3D.new()
var rebuilds := 0
func _init() -> void:
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.95
func chunk_coord(p: Vector3i) -> Vector3i:
	return Vector3i(floori(p.x/16.0),floori(p.y/16.0),floori(p.z/16.0))
func generate() -> void:
	for x in range(-1,1):
		for z in range(-1,1):
			for y in range(-3,0):
				var c := VoxelChunk.new()
				c.coord = Vector3i(x,y,z)
				c.terrain = self
				c.position = Vector3(c.coord*16)
				chunks[c.coord] = c
				add_child(c)
				for lz in 16:
					for ly in 16:
						for lx in 16:
							var local := Vector3i(lx,ly,lz)
							c.data[c.index(local)] = generator.block_at(c.coord*16+local)
	for c in chunks.values(): c.rebuild()
func get_block(p: Vector3i) -> int:
	var cc := chunk_coord(p)
	if not chunks.has(cc): return 0
	var c: VoxelChunk = chunks[cc]
	return c.data[c.index(p-cc*16)]
func remove_block(p: Vector3i) -> int:
	var id := get_block(p)
	if id == 0: return 0
	var cc := chunk_coord(p)
	var c: VoxelChunk = chunks[cc]
	c.data[c.index(p-cc*16)] = 0
	changes["%d,%d,%d" % [p.x,p.y,p.z]] = true
	var dirty := {cc:true}
	for d in VoxelChunk.DIRS:
		var neighbor := chunk_coord(p+d)
		if chunks.has(neighbor): dirty[neighbor] = true
	for key in dirty: chunks[key].rebuild()
	return id
func restore(edits: Dictionary) -> void:
	var dirty := {}
	for key in edits:
		var a: PackedStringArray = key.split(",")
		if a.size()!=3: continue
		var p := Vector3i(int(a[0]),int(a[1]),int(a[2]))
		var cc := chunk_coord(p)
		if not chunks.has(cc): continue
		var c: VoxelChunk = chunks[cc]
		c.data[c.index(p-cc*16)] = 0
		changes[key] = true
		dirty[cc] = true
		for d in VoxelChunk.DIRS:
			var neighbor := chunk_coord(p+d)
			if chunks.has(neighbor): dirty[neighbor] = true
	for key in dirty: chunks[key].rebuild()
