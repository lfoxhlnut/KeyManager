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
			_infimum.resize(size)
			_percentage.resize(size)
			print_debug("in custom setter")
			
			notify_property_list_changed()
			emit_changed()

## Use set_percentage() to assign for percentage.
## Or use set_percentage_by_id() to modify value on specific index.
## It can be accessed by percentage() or get_percentage().
var _percentage: Array[int] = []

## See also _percentage.
## Setter: set_infimum(), set_infimum_by_id().
## Getter: infimum(), get_infimum().
var _infimum: Array[int] = []

## What is left after subtracting the sum of infimum.
var disposable: int:
	get:	# Slow but safe.
		return 100 - _infimum.reduce(func(sum: int, num: int):
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
			name="_percentage",
			type=TYPE_ARRAY,
			usage=PROPERTY_USAGE_STORAGE,
		},
		{
			name="_infimum",
			type=TYPE_ARRAY,
			usage=PROPERTY_USAGE_STORAGE,
		},
	]
	
	_percentage.resize(size)
	_infimum.resize(size)
	
	for id: int in size:
		var d := {
			name="percentage/%s" % [id],
			type=TYPE_INT,
			usage=PROPERTY_USAGE_EDITOR,
			hint=PROPERTY_HINT_RANGE,
			hint_string="0,100",
		}
		res.append(d)
		
		d = {
			name="infimum/%s" % [id],
			type=TYPE_INT,
			usage=PROPERTY_USAGE_EDITOR,
			hint=PROPERTY_HINT_RANGE,
			hint_string="0,100",
		}
		res.append(d)
	return res


func _get(property: StringName):
	if property.begins_with("percentage/"):
		property = property.trim_prefix("percentage/")
		var id := int(property as String)
		return percentage(id)
	if property.begins_with("infimum/"):
		property = property.trim_prefix("infimum/")
		var id := int(property as String)
		return infimum(id)
	
	return null


# Seems that only undeclared variables will trigger set().
# Otherwise the setter will be triggered.
func _set(property: StringName, value: Variant) -> bool:
	print_debug("accessing _set: ", property)
	if property.begins_with("percentage/"):
		property = property.trim_prefix("percentage/")
		var id := int(property as String)
		
		set_percentage_by_id(id, value)
		
		notify_property_list_changed()
		emit_changed()
		return true
	
	if property.begins_with("infimum/"):
		property = property.trim_prefix("infimum/")
		var id := int(property as String)
		
		set_infimum_by_id(id, value)
		
		# 需要在此处手动调节. 在 _get() 里调节有些浪费性能.
		set_percentage()
		
		notify_property_list_changed()
		emit_changed()
		return true

	return false


func set_infimum_by_id(id: int, val: int) -> void:
	_infimum[id] = val
	set_infimum()


func set_infimum(arr: Array[int] = _infimum) -> void:
	assert(arr.size() == size)
	
	# 其实理论上赋值者应保证 infimum 各项之和不超过 100.
	# NOTE: 以后如果想允许赋值过程中临时的和超过 100, 这里得重写,
	# 让用户自己保证他赋的值没问题.
	var upper_bound := 100
	for i: int in size:
		_infimum[i] = clampi(arr[i], 0, upper_bound)
		upper_bound -= _infimum[i]


func infimum(id: int) -> int:
	return _infimum[id]


func get_infimum() -> Array[int]:
	return _infimum.duplicate()


func set_percentage_by_id(id: int, val: int) -> void:
	_percentage[id] = val
	set_percentage()


func set_percentage(arr: Array[int] = _percentage) -> void:
	var upper_bound := disposable
	
	# Reallocate for each element. Give priority to smaller index elements.
	for i: int in size:
		# TODO: 这样写是有点绕, 可考虑把 _percentage 分解成 _infimum + addition
		# 保证 _percentage[i] 至少分配到 _infimum[i] 大小的空间.
		if arr[i] < infimum(i):
			_percentage[i] = infimum(i)
		# 如果额外申请的空间在允许范围内.
		elif arr[i] - infimum(i) <= upper_bound:
			upper_bound -= arr[i] - infimum(i)
			_percentage[i] = arr[i]
		# 申请超过允许范围, 最多把所有剩余空间都分配给它.
		else:
			_percentage[i] = upper_bound + infimum(i)
			upper_bound = 0
		assert(upper_bound >= 0)


func percentage(id: int) -> int:
	return _percentage[id]


func get_percentage() -> Array[int]:
	return _percentage.duplicate()
