extends Node3D
var terrain: Terrain
var player: Miner
var mining: Mining
var inventory := Inventory.new()
var canvas := CanvasLayer.new()
var hud: Label
var target_label: Label
var progress: ProgressBar
var menu: PanelContainer
var menu_box: VBoxContainer
var started := false
var paused := true
var terminal := Vector3(5,0,5)
func _ready() -> void:
	for key in {"forward":KEY_W,"back":KEY_S,"left":KEY_A,"right":KEY_D,"jump":KEY_SPACE,"sprint":KEY_SHIFT,"pause":KEY_ESCAPE,"inventory":KEY_TAB,"sell":KEY_E,"upgrade":KEY_U,"recover":KEY_R,"save":KEY_F5}:
		InputMap.add_action(key)
		var event := InputEventKey.new()
		event.physical_keycode = {"forward":KEY_W,"back":KEY_S,"left":KEY_A,"right":KEY_D,"jump":KEY_SPACE,"sprint":KEY_SHIFT,"pause":KEY_ESCAPE,"inventory":KEY_TAB,"sell":KEY_E,"upgrade":KEY_U,"recover":KEY_R,"save":KEY_F5}[key]
		InputMap.action_add_event(key,event)
	InputMap.add_action("mine")
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("mine",mouse)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55,-25,0)
	sun.light_energy = 1.4
	add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("#203b50")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("#a5c8e5")
	env.environment.ambient_light_energy = 0.7
	add_child(env)
	add_child(canvas)
	var theme := Theme.new()
	theme.default_font_size = 24
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("#14232f")
	panel.border_color = Color("#45d6c3")
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(14)
	panel.content_margin_left = 32
	panel.content_margin_right = 32
	panel.content_margin_top = 24
	panel.content_margin_bottom = 24
	theme.set_stylebox("panel","PanelContainer",panel)
	menu = PanelContainer.new()
	menu.theme = theme
	menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	menu.position = Vector2(-280,-230)
	menu.custom_minimum_size = Vector2(560,460)
	canvas.add_child(menu)
	menu_box = VBoxContainer.new()
	menu_box.add_theme_constant_override("separation",16)
	menu.add_child(menu_box)
	show_menu("DEEP CORE","A little pickaxe. A world beneath your feet.")
func clear_menu() -> void:
	for c in menu_box.get_children():
		menu_box.remove_child(c)
		c.queue_free()
func button(text: String, callback: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = 48
	b.pressed.connect(callback)
	menu_box.add_child(b)
func show_menu(title: String, subtitle: String) -> void:
	clear_menu()
	menu.show()
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size",42)
	menu_box.add_child(label)
	var sub := Label.new()
	sub.text = subtitle
	sub.add_theme_font_size_override("font_size",18)
	menu_box.add_child(sub)
	button("Resume" if started else "Play / Continue",resume if started else begin)
	if started:
		button("Save expedition",save_game)
		button("Return to surface",func(): player.position=Vector3(0,3,5); resume())
	button("Quit",func():
		if started: save_game()
		get_tree().quit())
func begin() -> void:
	menu.hide()
	terrain = Terrain.new()
	add_child(terrain)
	var saved := SaveStore.read_save()
	terrain.generator.seed_value = int(saved.get("seed",73291))
	terrain.generate()
	terrain.restore(saved.get("mined",{}))
	inventory.quantities = saved.get("inventory",{})
	inventory.currency = int(saved.get("currency",0))
	inventory.power = float(saved.get("power",10))
	player = Miner.new()
	add_child(player)
	var pos: Array = saved.get("position",[0,3,5])
	player.position = Vector3(float(pos[0]),float(pos[1]),float(pos[2]))
	var lamp := OmniLight3D.new()
	lamp.light_color = Color("#ffe5b3")
	lamp.light_energy = 2
	lamp.omni_range = 9
	lamp.position.y = 1.8
	player.add_child(lamp)
	mining = Mining.new()
	mining.player = player
	mining.terrain = terrain
	mining.inventory = inventory
	add_child(mining)
	# Permanent floor and retaining walls enclose the finite prototype.
	prop(Vector3(0,-49,0),Vector3(34,2,34),Color("#293b48"),true)
	for x in [-17,17]: prop(Vector3(x,-24,0),Vector3(2,50,36),Color("#344b59"),true)
	for z in [-17,17]: prop(Vector3(0,-24,z),Vector3(36,50,2),Color("#344b59"),true)
	prop(terminal+Vector3(0,0.8,0),Vector3(1.5,1.6,1),Color("#efab40"),true)
	prop(terminal+Vector3(0,1.1,-0.52),Vector3(1.1,0.6,0.05),Color("#4ce0d3"))
	var sign := Label3D.new()
	sign.text = "OUTPOST 01\nE • SELL    U • UPGRADE (30)"
	sign.position = terminal+Vector3(0,2.4,0)
	sign.font_size = 40
	sign.pixel_size = 0.008
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(sign)
	for x in [-12,12]:
		for z in [-12,12]:
			prop(Vector3(x,1,z),Vector3(0.4,2,0.4),Color("#e4a64b"))
			prop(Vector3(x,2.1,z),Vector3(0.7,0.25,0.7),Color("#56ead9"))
	hud = Label.new()
	hud.position = Vector2(28,24)
	hud.add_theme_font_size_override("font_size",26)
	canvas.add_child(hud)
	target_label = Label.new()
	target_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	target_label.position = Vector2(-170,30)
	target_label.custom_minimum_size.x = 340
	target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	canvas.add_child(target_label)
	progress = ProgressBar.new()
	progress.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	progress.position = Vector2(-120,65)
	progress.size = Vector2(240,12)
	progress.show_percentage = false
	canvas.add_child(progress)
	var hints := Label.new()
	hints.text = "WASD Move • Mouse Look • Space Jump • Shift Sprint • Hold LMB Mine\nTab Inventory • E Sell nearby • U Upgrade nearby • R Surface • F5 Save • Esc Pause"
	hints.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	hints.position = Vector2(28,-85)
	hints.add_theme_font_size_override("font_size",22)
	canvas.add_child(hints)
	var cross := Label.new()
	cross.text = "+"
	cross.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	cross.position = Vector2(-8,-16)
	canvas.add_child(cross)
	started = true
	resume()
func prop(pos: Vector3,size: Vector3,color: Color,solid := false) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		body.position = pos
		body.add_child(shape)
		add_child(body)
func resume() -> void:
	paused = false
	menu.hide()
	player.active = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
func pause_game() -> void:
	paused = true
	player.active = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	show_menu("EXPEDITION PAUSED","Your mine is waiting.")
func _unhandled_input(event: InputEvent) -> void:
	if not started: return
	if event.is_action_pressed("pause"):
		if paused: resume()
		else: pause_game()
	if event.is_action_pressed("inventory"):
		if paused: resume()
		else:
			pause_game()
			var lines := "STORAGE  %d / %d\n" % [inventory.used(),inventory.capacity]
			for key in inventory.quantities: lines += "%s: %d\n" % [Blocks.NAMES[int(key)],inventory.quantities[key]]
			show_menu("BACKPACK",lines)
	if paused: return
	if event.is_action_pressed("recover"): player.position = Vector3(0,3,5)
	if event.is_action_pressed("save"): save_game()
	if player.position.distance_to(terminal)<4:
		if event.is_action_pressed("sell"): inventory.sell(); save_game()
		if event.is_action_pressed("upgrade"): inventory.upgrade()
func _process(_dt: float) -> void:
	if not started: return
	var depth := maxi(0,floori(-player.position.y))
	var layer := "Surface Soil" if depth<15 else ("Iron Ridge" if depth<35 else "Crystal Depths")
	hud.text = "DEEP CORE   /   OUTPOST 01\n%d m • %s\nCredits %d   |   Cargo %d / %d\nRusty Pickaxe • %.0f damage/s\nFPS %d • Chunk rebuilds %d" % [depth,layer,inventory.currency,inventory.used(),inventory.capacity,inventory.power,Engine.get_frames_per_second(),terrain.rebuilds]
	target_label.text = Blocks.NAMES[mining.target_id] if mining.target_id>0 else "Aim at terrain"
	if inventory.used()>=inventory.capacity: target_label.text = "Storage full • Return and sell"
	progress.value = mining.damage/float(Blocks.HARDNESS[mining.target_id])*100 if mining.target_id>0 else 0
func save_game() -> void:
	var p := player.position
	var ok := SaveStore.write({"seed":terrain.generator.seed_value,"position":[p.x,p.y,p.z],"inventory":inventory.quantities,"currency":inventory.currency,"power":inventory.power,"tool":"rusty_pickaxe","mined":terrain.changes})
	if not ok: push_error("Could not save expedition")
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and started: save_game()
