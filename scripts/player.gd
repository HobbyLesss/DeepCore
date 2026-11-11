class_name Miner
extends CharacterBody3D
var yaw := 0.0
var pitch := -0.45
var sensitivity := 0.0025
var pivot := Node3D.new()
var arm := SpringArm3D.new()
var camera := Camera3D.new()
var model := Node3D.new()
var active := false
var walk_time := 0.0
func _ready() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.6
	shape.shape = capsule
	shape.position.y = 0.8
	add_child(shape)
	add_child(model)
	part(Vector3(0,0.9,0),Vector3(0.65,0.85,0.4),Color("#eaa33d"))
	part(Vector3(0,1.55,0),Vector3(0.55,0.35,0.5),Color("#ffd477"))
	part(Vector3(0,1.55,-0.26),Vector3(0.42,0.17,0.04),Color("#49dcd0"))
	part(Vector3(-0.2,0.25,0),Vector3(0.22,0.5,0.3),Color("#263847"))
	part(Vector3(0.2,0.25,0),Vector3(0.22,0.5,0.3),Color("#263847"))
	part(Vector3(0.48,0.75,-0.15),Vector3(0.08,0.8,0.08),Color("#865c40"))
	part(Vector3(0.48,1.12,-0.15),Vector3(0.5,0.1,0.14),Color("#afc5cd"))
	add_child(pivot)
	pivot.position.y = 1.4
	pivot.add_child(arm)
	arm.spring_length = 3.4
	arm.margin = 0.15
	arm.add_excluded_object(get_rid())
	arm.add_child(camera)
	camera.current = true
	camera.fov = 72
func part(pos: Vector3, size: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	model.add_child(mesh)
func _unhandled_input(event: InputEvent) -> void:
	if active and event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x*sensitivity
		pitch = clampf(pitch-event.relative.y*sensitivity,-1.35,0.65)
func _physics_process(dt: float) -> void:
	if not active: return
	pivot.rotation.y = lerp_angle(pivot.rotation.y,yaw,1-exp(-20*dt))
	arm.rotation.x = lerp_angle(arm.rotation.x,pitch,1-exp(-20*dt))
	var input := Input.get_vector("left","right","forward","back")
	var direction := Basis(Vector3.UP,yaw)*Vector3(input.x,0,input.y)
	var speed := 7.0 if Input.is_action_pressed("sprint") else 4.0
	velocity.x = move_toward(velocity.x,direction.x*speed,22*dt)
	velocity.z = move_toward(velocity.z,direction.z*speed,22*dt)
	if not is_on_floor(): velocity.y -= 22*dt
	elif Input.is_action_just_pressed("jump"): velocity.y = 7
	move_and_slide()
	if direction.length()>0.1: model.rotation.y = lerp_angle(model.rotation.y,atan2(-direction.x,-direction.z),dt*12)
	walk_time += dt*speed
	model.position.y = sin(walk_time*9)*0.035*input.length()
	if position.y < -52: position = Vector3(0,3,5)
