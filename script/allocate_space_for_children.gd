@tool
extends Node

@export_node_path("Control") var parent_node_path:
	set(v):
		parent_node_path = v
		parent_node = get_node(v)
@export var percentage: SubNodePercentage:
	set(v):
		percentage = v
		adjust_sub_control_node()
func percent(id: int) -> float:
		return percentage.percentage[id] / 100.0


var parent_node: HBoxContainer
var sub_control_count: int:
	get:
		var res := 0
		for i: Node in parent_node.get_children():
			if i is Control:
				res += 1
		return res
var parent_size_x: float:
	get:
		return parent_node.get_minimum_size().x
var parent_disposable_size: float:
	get:
		# For HBoxContainer.
		return parent_size_x - (sub_control_count - 1) * parent_node.get_theme_constant("separation")


func _get_configuration_warnings() -> PackedStringArray:
	if not parent_node_path:
		return ["Variable not initialized: parent_node_path."]
	if not parent_node:
		return ["Target node is null."]
	if not percentage:
		return ["Resource not initialized: percentage."]
	return []


func get_sub_control(id: int) -> Control:
	var i := 0
	var sub_nodes: Array[Node] = parent_node.get_children()
	if id < 0:
		sub_nodes.reverse()
		id = -id - 1
	for child: Node in sub_nodes:
		if not child is Control:
			return
		
		# Consider only Control among sub nodes.
		if i == id:
			return child
		i += 1
	print_debug("Error: sub control not found.")
	return null


## Suppose the percentage is clamped adequately.
func adjust_sub_control_node() -> void:
	# Set to zero first to prevent overflow(prevent parent size changing) in assignment.
	for i: int in sub_control_count:
		var child := get_sub_control(i)
		child.custom_minimum_size.x = 0
	
	for i: int in sub_control_count:
		var child := get_sub_control(i)
		child.custom_minimum_size.x = parent_disposable_size * percent(i)


## Ceil the scale.
func get_min_scale(id: int) -> int:
	return ceilf(get_sub_control(id).get_minimum_size().x / parent_disposable_size) * 100 as int
