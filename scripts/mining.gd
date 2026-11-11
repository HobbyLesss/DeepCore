class_name Mining
extends Node3D
var player: Miner
var terrain: Terrain
var inventory: Inventory
var target := Vector3i.ZERO
var target_id := 0
var damage := 0.0
var outline := MeshInstance3D.new()
var reach := 4.5
var message := ""
func _ready() -> void:
	var box := BoxMesh.new()
	box.size = Vector3.ONE*1.015
	outline.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2,1,0.85,0.18)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outline.material_override = mat
	add_child(outline)
func _physics_process(dt: float) -> void:
	outline.visible = false
	if not player.active: return
	var origin := player.camera.global_position
	var end := origin-player.camera.global_basis.z*10
	var query := PhysicsRayQueryParameters3D.create(origin,end)
	query.exclude = [player.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or not hit.collider is VoxelChunk:
		target_id = 0
		damage = 0
		return
	var p := Vector3i((hit.position-hit.normal*0.01).floor())
	if (Vector3(p)+Vector3.ONE*0.5-player.global_position-Vector3.UP).length()>reach:
		target_id = 0
		damage = 0
		return
	if p != target: damage = 0
	target = p
	target_id = terrain.get_block(p)
	outline.visible = target_id != 0
	outline.position = Vector3(p)+Vector3.ONE*0.5
	if Input.is_action_pressed("mine") and target_id != 0:
		if inventory.used()>=inventory.capacity:
			message = "Storage full • E at the terminal to sell"
			return
		damage += inventory.power*dt
		outline.scale = Vector3.ONE*(1+sin(damage*8)*0.008)
		if damage >= Blocks.HARDNESS[target_id]:
			var id := terrain.remove_block(target)
			if id != 0:
				inventory.collect(id)
				burst(Vector3(target)+Vector3.ONE*0.5,Blocks.COLORS[id])
			damage = 0
			target_id = 0
func burst(pos: Vector3, color: Color) -> void:
	var particles := CPUParticles3D.new()
	add_child(particles)
	particles.global_position = pos
	particles.amount = 14
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.explosiveness = 1
	particles.direction = Vector3.UP
	particles.spread = 140
	particles.initial_velocity_min = 1
	particles.initial_velocity_max = 3
	particles.gravity = Vector3(0,-8,0)
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE*0.09
	particles.mesh = mesh
	particles.color = color
	particles.emitting = true
	get_tree().create_timer(1).timeout.connect(particles.queue_free)
