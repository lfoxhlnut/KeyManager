@tool
extends Node

@export var percentage: SubNodePercentage:
	set(v):
		var to_call := adjust_sub_control_node
		# Disconnect previous signal link.
		if percentage:	# Only if it is not null.
			percentage.percentage_changed.disconnect(to_call)
		
		percentage = v
		# Initalize if v is not null.
		if not v:
			return
		
		if parent_node:
			initialize()
		
		# Extablish new signal link.
		if not percentage.is_connected("percentage_changed", to_call):
			percentage.percentage_changed.connect(to_call)
@export var fill_last_child := false


## Will occur an error once TargetHbox or Percentage is null.
@export var initialize_manually := false:
	set(v):
		if v:
			initialize()


func percent(id: int) -> float:
		return percentage.percentage(id) / 100.0


var parent_node: HBoxContainer = null:
	set(v):
		var to_call := set_percentage_infimum_by_id
		# Disconnect previous signal link.
		if parent_node:	# Only if it is not null.
			for i: int in sub_control_count:
				var child := get_sub_control(i)
				var arr := child.minimum_size_changed.get_connections()
				for d: Dictionary in arr:
					if d.callable == to_call:
						child.minimum_size_changed.disconnect(to_call)
		
		parent_node = v
		# Initalize if v is not null.
		if not v:
			return
		
		if percentage:
			initialize()
		
		# Extablish new signal link.
		for i: int in sub_control_count:
			var child := get_sub_control(i)
			if not child.is_connected("minimum_size_changed", to_call):
				child.minimum_size_changed.connect(to_call.bind(i))
		
var sub_control_count: int:
	get:
		var res := 0
		for i: Node in parent_node.get_children():
			if i is Control:
				res += 1
		return res
var parent_size_x: float:
	get:
		return parent_node.size.x
var parent_disposable_size: float:
	get:
		# For HBoxContainer.
		return parent_size_x - (sub_control_count - 1) * parent_node.get_theme_constant("separation")


func _get_configuration_warnings() -> PackedStringArray:
	if not parent_node:
		return ["Target Hbox Container is null."]
	if not percentage:
		return ["Resource not initialized: percentage."]
	return []


func initialize() -> void:
	#print_debug("parent_disposable_size is ", parent_disposable_size)
	percentage.size = sub_control_count
	
	percentage.use_custom_name = true
	var sub_control_name: Array[String] = []
	for id: int in sub_control_count:
		var child := get_sub_control(id)
		sub_control_name.append(child.name)
	percentage.set_custom_name(sub_control_name)
	
	set_percentage_infimum()
	adjust_sub_control_node()


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
			#print_debug("Control node ", child.name, " found.")
			return child
		i += 1
	print_debug("Error: sub control not found.")
	return null


## Suppose the percentage is clamped adequately.
func adjust_sub_control_node(_i: int = 1) -> void:
	# Set to zero first to prevent overflow(prevent parent size changing) in assignment.
	for i: int in sub_control_count:
		var child := get_sub_control(i)
		child.set_deferred("custom_minimum_size:x", 0)
		#child.custom_minimum_size.x = 0
	
	for i: int in sub_control_count:
		var child := get_sub_control(i)
		child.set_deferred("custom_minimum_size:x", parent_disposable_size * percent(i))
		#child.custom_minimum_size.x = parent_disposable_size * percent(i)


## Ceil the scale.
func get_min_scale(id: int) -> int:
	return ceili(get_sub_control(id).get_minimum_size().x / parent_disposable_size * 100)


func set_percentage_infimum() -> void:
	print_debug("setting percentage infimum")
	var res: Array[int] = []
	for i: int in sub_control_count:
		res.append(get_min_scale(i))
	percentage.set_infimum(res)


func set_percentage_infimum_by_id(id: int) -> void:
	percentage.set_infimum_by_id(id, get_min_scale(id))


func _get_property_list() -> Array[Dictionary]:
	var res: Array[Dictionary] = [
		{
			name="Target HboxContainer",
			type=TYPE_OBJECT,
			# Whether it should be storage? And what type if will be storage?
			usage=PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
			hint=PROPERTY_HINT_NODE_TYPE,
			hint_string="HBoxContainer",
		},
	]
	
	return res


func _get(property: StringName):
	if property == "Target HboxContainer":
		return parent_node
	
	return null


func _set(property: StringName, value) -> bool:
	if property == "Target HboxContainer":
		if value is HBoxContainer:
			parent_node = value
			return true
	
	return false
