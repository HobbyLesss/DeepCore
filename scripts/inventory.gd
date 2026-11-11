class_name Inventory
extends RefCounted
signal changed
var quantities: Dictionary = {}
var currency := 0
var capacity := 20
var power := 10.0
func used() -> int:
	var total := 0
	for n in quantities.values(): total += int(n)
	return total
func collect(id: int) -> bool:
	if used() >= capacity: return false
	var key := str(id)
	quantities[key] = int(quantities.get(key,0))+1
	changed.emit()
	return true
func sell() -> void:
	for key in quantities: currency += int(quantities[key])*Blocks.VALUE[int(key)]
	quantities.clear()
	changed.emit()
func upgrade() -> bool:
	if currency < 30: return false
	currency -= 30
	power += 10
	changed.emit()
	return true
