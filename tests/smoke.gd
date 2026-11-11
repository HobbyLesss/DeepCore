extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		quit(1)
		assert(value,message)
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	# Isolate repeat runs from prior saved progress.
	DirAccess.remove_absolute(SaveStore.PATH)
	DirAccess.remove_absolute(SaveStore.PATH+".bak")
	game.begin()
	await physics_frame
	check(game.terrain.chunks.size()==12,"Chunk count")
	check(game.terrain.chunk_coord(Vector3i(-1,-1,-1))==Vector3i(-1,-1,-1),"Negative coordinates")
	var p := Vector3i(-1,-1,0)
	var before: int = game.terrain.rebuilds
	var id: int = game.terrain.remove_block(p)
	check(id>0 and game.terrain.get_block(p)==0,"Destruction")
	check(game.terrain.rebuilds-before==3,"Boundary rebuilds")
	check(game.terrain.remove_block(p)==0,"No duplicate reward")
	for i in 20: check(game.inventory.collect(1),"Collect")
	check(not game.inventory.collect(1),"Capacity")
	game.inventory.sell()
	check(game.inventory.currency==20 and game.inventory.used()==0,"Selling")
	for i in 90: await physics_frame
	check(game.player.is_on_floor(),"Terrain collision")
	var old: Vector3 = game.player.position
	Input.action_press("forward")
	for i in 30: await physics_frame
	Input.action_release("forward")
	check(game.player.position.distance_to(old)>0.5,"Movement")
	Input.action_press("jump")
	await physics_frame
	await physics_frame
	Input.action_release("jump")
	check(game.player.velocity.y>0,"Jump")
	game.player.position = Vector3(2,0.1,2)
	game.player.camera.global_position = Vector3(2.5,3,3.5)
	game.player.camera.look_at(Vector3(2.5,-0.5,2.5))
	await physics_frame
	game.mining._physics_process(0.01)
	check(game.mining.target_id>0,"Camera targeting")
	var mined: Vector3i = game.mining.target
	Input.action_press("mine")
	game.mining._physics_process(0.1)
	check(game.mining.damage>0,"Mining progress")
	game.mining._physics_process(20)
	Input.action_release("mine")
	check(game.terrain.get_block(mined)==0 and game.inventory.used()==1,"Mining rewards")
	game.save_game()
	var saved := SaveStore.read_save()
	check(saved.get("mined",{}).has("-1,-1,0"),"Save changes")
	check(saved.get("currency",0)==20,"Save inventory")
	var t := Terrain.new()
	root.add_child(t)
	t.generate()
	t.restore(saved.mined)
	check(t.get_block(p)==0,"Restore excavations")
	t.queue_free()
	print("PASS: chunks, negative coordinates, boundary rebuilds, destruction, duplicate prevention, capacity, selling, collision, movement, jump, save/load")
	game.queue_free()
	await process_frame
	quit(0)
