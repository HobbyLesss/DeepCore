class_name Generation
extends RefCounted
var seed_value: int = 73291
func block_at(p: Vector3i) -> int:
	if p.y >= 0 or p.y < -48: return 0
	var depth := -p.y
	var base := 1 if depth < 12 else 2
	# Coarse deterministic cells form multi-block ore deposits.
	var cell := Vector3i(floori(p.x/3.0),floori(p.y/3.0),floori(p.z/3.0))
	var h := absi(hash(str(cell)+str(seed_value))) % 100
	if depth < 15:
		if h < 18: return 3
		if h < 32: return 2
	elif depth < 35:
		if h < 15: return 4
		if h < 22: return 5
	else:
		if h < 12: return 6
		if h < 20: return 7
	return base
