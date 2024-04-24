@tool
class_name SubNodePercentage
extends Resource

# Node 的方法: _get_configuration_warnings
# Object's method: notify_property_list_changed()
# ↑ 可用于实现动态修改 hint string
# TODO: 恢复默认值. 最小值的设置.
#		最后一个部分可以设置为自动占据剩下的部分, 也可以手动设置成一个更小的数值

var first_part := 0
var second_part := 0
var third_part: int:
	get:
		return 100 - first_part - second_part



# Consider adapting for any count.
func _get_property_list() -> Array[Dictionary]:
	var res: Array[Dictionary] = [
		{
			name="percentage/first_part",
			type=TYPE_INT,
			usage=PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
			hint=PROPERTY_HINT_RANGE,
			hint_string="0,100",
		},
		{
			name="percentage/second_part",
			type=TYPE_INT,
			usage=PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
			hint=PROPERTY_HINT_RANGE,
			hint_string="0,%s" % [100 - first_part],
		},
		{
			name="percentage/third_part",
			type=TYPE_INT,
			usage=PROPERTY_USAGE_EDITOR,
			hint=PROPERTY_HINT_NONE,
		},
	]
	
	return res


func _get(property: StringName):
	if property.begins_with("percentage/"):
		property = property.trim_prefix("percentage/")
		if property == "first_part":
			return first_part
		elif property == "second_part":
			return second_part
		else:
			return 100 - first_part - second_part
	
	return null


func _set(property: StringName, value: Variant) -> bool:
	if property.begins_with("percentage/"):
		print_debug("accessing ", property)
		property = property.trim_prefix("percentage/")
		if property == "first_part":
			first_part = value
			#second_part = min(100 - value, second_part)
			notify_property_list_changed()
			emit_changed()
		elif property == "second_part":
			second_part = min(100 - first_part, value)
			emit_changed()
		
		return true
	
	return false
