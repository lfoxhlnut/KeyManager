@tool
class_name SubNodePercentage
extends Resource

# Node 的方法: _get_configuration_warnings
# Object's method: notify_property_list_changed()
# ↑ 可用于实现动态修改 hint string
# TODO: 恢复默认值. 最小值的设置.
#		最后一个部分可以设置为自动占据剩下的部分, 也可以手动设置成一个更小的数值


var size: int = 3:
	set(v):
			size = clampi(v, 0, 100)
			infimum.resize(size)
			percentage.resize(size)
			print_debug("in custom setter")
			
			notify_property_list_changed()
			emit_changed()
var percentage: Array[int] = []
var infimum: Array[int] = []

## What is left after subtracting the sum of infimum.
var disposable: int:
	get:	# Slow but safe.
		return 100 - infimum.reduce(func(sum: int, num: int):
			return sum + num
		)


func _get_property_list() -> Array[Dictionary]:
	var res: Array[Dictionary] = [
		{
			name="size",
			type=TYPE_INT,
			usage=PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
			hint=PROPERTY_HINT_RANGE,
			hint_string="0,100",	# Should be sufficient.
		},
		{
			name="percentage",
			type=TYPE_ARRAY,
			usage=PROPERTY_USAGE_STORAGE,
		},
		{
			name="infimum",
			type=TYPE_ARRAY,
			usage=PROPERTY_USAGE_STORAGE,
		},
	]
	
	percentage.resize(size)
	infimum.resize(size)
	
	for id: int in size:
		var d := {
			name="percentage/%s" % [id],
			type=TYPE_INT,
			usage=PROPERTY_USAGE_EDITOR,
			hint=PROPERTY_HINT_RANGE,
			hint_string="0, 100",
		}
		res.append(d)
		
		d = {
			name="infimum/%s" % [id],
			type=TYPE_INT,
			usage=PROPERTY_USAGE_EDITOR,
			hint=PROPERTY_HINT_RANGE,
			hint_string="0, 100",
		}
		res.append(d)
	return res


func _get(property: StringName):
	if property.begins_with("percentage/"):
		property = property.trim_prefix("percentage/")
		var id := int(property as String)
		return percentage[id]
	if property.begins_with("infimum/"):
		property = property.trim_prefix("infimum/")
		var id := int(property as String)
		return infimum[id]
	
	return null


# Seems that only undeclared variables will trigger set().
# Otherwise the setter will be triggered.
func _set(property: StringName, value: Variant) -> bool:
	print_debug("accessing _set: ", property)
	if property.begins_with("percentage/"):
		property = property.trim_prefix("percentage/")
		var id := int(property as String)
		
		# 这一行为了不去单独处理 id 这个下标
		percentage[id] = value
		adjust_percentage()
		
		notify_property_list_changed()
		emit_changed()
		return true
	
	if property.begins_with("infimum/"):
		property = property.trim_prefix("infimum/")
		var id := int(property as String)
		
		# 其实理论上赋值者应保证 infimum 各项之和不超过 100.
		# NOTE: 以后如果想允许赋值过程中临时的和超过 100, 这里得重写,
		# 让用户自己保证他赋的值没问题.
		var upper_bound := 100
		
		for i: int in id:
			upper_bound -= infimum[i]
		
		# 为了不去单独处理 id 这个下标
		infimum[id] = value
		
		for i: int in range(id, size):
			infimum[i] = clampi(infimum[i], 0, upper_bound)
			upper_bound -= infimum[i]
		
		# 需要在此处手动调节. 在 _get() 里调节有些浪费性能.
		adjust_percentage()
		
		notify_property_list_changed()
		emit_changed()
		return true

	return false


func adjust_percentage() -> void:
	print_debug("adjusting percentage")
	# 可自由分配的空间余量.
	var upper_bound := disposable
	
	# Reallocate for each element. Give priority to smaller index elements.
	for i: int in size:
		# TODO: 这样写是有点绕, 可考虑把 percentage 分解成 infimum + addition
		# 保证 percentage[i] 至少分配到 infimum[i] 大小的空间.
		if percentage[i] < infimum[i]:
			percentage[i] = infimum[i]
		# 如果额外申请的空间在允许范围内.
		elif percentage[i] - infimum[i] <= upper_bound:
			upper_bound -= percentage[i] - infimum[i]
		# 申请超过允许范围, 最多把所有剩余空间都分配给它.
		else:
			percentage[i] = upper_bound + infimum[i]
			upper_bound = 0
		assert(upper_bound >= 0)
