@tool
class_name SubNodePercentage
extends Resource

signal percentage_changed()

# Node 的方法: _get_configuration_warnings
# Object's method: notify_property_list_changed()
# ↑ 可用于实现动态修改 hint string
# TODO: 恢复默认值. 最小值的设置.
#		最后一个部分可以设置为自动占据剩下的部分, 也可以手动设置成一个更小的数值
#		percentage 和 infimum 的下标 0, 1, 2... 可以改名字


var size: int = 3:
	set(v):
			size = clampi(v, 0, 100)
			_infimum_setter()
			_percentage_setter()
			_custom_name_setter()
			print_debug("in custom setter of 'size'")
			
			notify_property_list_changed()
			emit_changed()

var use_custom_name := false

## Activated only if use_custom_name is true.
## Ignore parts whose index is greater than size.
var _custom_name: Array[String] = []: set = _custom_name_setter

func set_custom_name(v: Array[String]) -> void:
	_custom_name_setter(v)
	notify_property_list_changed()
	emit_changed()


func _custom_name_setter(v: Array[String] = _custom_name) -> void:
	_custom_name.resize(size)
	# 或许我应假定传入的参数都是合法的, 这样可以节省很多精力.
	var s := mini(v.size(), size)
	for i: int in s:
		_custom_name[i] = v[i]
	# Fill vacancy with default.
	for i: int in range(s, size):
		_custom_name[i] = i as String
	
	# Mapping.
	_custom_name_map.clear()
	for id: int in size:
		_custom_name_map[_custom_name[id]] = id


func set_custom_name_by_id(id: int, val: String) -> void:
	# TODO
	pass


func get_custom_name() -> Array[String]:
	return _custom_name.duplicate()


func custom_name(id: int) -> String:
	return _custom_name[id]


# Map: custom_name(string) -> index(int).
var _custom_name_map: Dictionary = {}

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
		# FIXME: custome..
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
		if should_use_custom_name():
			d.name = "percentage/%s" % [custom_name(id)]
		res.append(d)
		
		d = {
			name="infimum/%s" % [id],
			type=TYPE_INT,
			usage=PROPERTY_USAGE_EDITOR,
			hint=PROPERTY_HINT_RANGE,
			hint_string="0,100",
		}
		
		if should_use_custom_name():
			d.name = "infimum/%s" % [custom_name(id)]
		res.append(d)
	return res


func should_use_custom_name() -> bool:
	return use_custom_name and not _custom_name.is_empty()


func get_id(property: String) -> int:
	if should_use_custom_name():
		return _custom_name_map[property as String] as int
	else:
		return int(property as String)


func _get(property: StringName):
	if property.begins_with("percentage/"):
		property = property.trim_prefix("percentage/")
		return percentage(get_id(property))
	if property.begins_with("infimum/"):
		property = property.trim_prefix("infimum/")
		return infimum(get_id(property))
	
	return null


# Seems that only undeclared variables will trigger set().
# Otherwise the setter will be triggered.
func _set(property: StringName, value: Variant) -> bool:
	print_debug("accessing _set: ", property)
	if property.begins_with("percentage/"):
		property = property.trim_prefix("percentage/")
		var id := get_id(property)
		
		set_percentage_by_id(id, value)
		
		notify_property_list_changed()
		emit_changed()
		return true
	
	if property.begins_with("infimum/"):
		property = property.trim_prefix("infimum/")
		var id := get_id(property)
		
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


## NOTE: Function set_percentage() will be called automatically.
## Param "arr" will be standardized by standardize_arr().
func set_infimum(arr: Array[int] = _infimum) -> void:
	_infimum_setter(arr)
	_percentage_setter()
	notify_property_list_changed()
	emit_changed()


# Function set_percentage() will not be called automatically.
func _infimum_setter(arr: Array[int] = _infimum) -> void:
	_infimum = standardize_arr(arr.duplicate())
	
	# 其实理论上赋值者应保证 infimum 各项之和不超过 100.
	# NOTE: 以后如果想允许赋值过程中临时的和超过 100, 这里得重写,
	# 让用户自己保证他赋的值没问题.
	var upper_bound := 100
	for i: int in size:
		_infimum[i] = clampi(_infimum[i], 0, upper_bound)
		upper_bound -= _infimum[i]


func infimum(id: int) -> int:
	return _infimum[id]


## NOTE: What returned is the copy of infimum.
## Changing this will NOT affect the infimum of original resource.
## To change the infimum entirely, use set_infimum().
func get_infimum() -> Array[int]:
	return _infimum.duplicate()


func set_percentage_by_id(id: int, val: int) -> void:
	_percentage[id] = val
	set_percentage()


## Signal "percentage_signal" will emit if whethet_emit is true.
## Param "arr" will be standardized by standardize_arr().
func set_percentage(arr: Array[int] = _percentage) -> void:
	_percentage_setter(arr)
	notify_property_list_changed()
	emit_changed()


func _percentage_setter(arr: Array[int] = _percentage) -> void:
	arr = standardize_arr(arr.duplicate())
	_percentage.resize(size)
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
	percentage_changed.emit()


func percentage(id: int) -> int:
	return _percentage[id]


## NOTE: What returned is the copy of percentage.
## See also set_percentage() and comments of get_infimum()
func get_percentage() -> Array[int]:
	return _percentage.duplicate()


## Fill with 0 if arr.size() < size.
## Ignore parts whose index is greater than size.
func standardize_arr(arr: Array[int], s: int = size) -> Array[int]:
	var ori_size := arr.size()
	arr.resize(s)
	for id: int in range(ori_size, s):
		arr[id] = 0
	return arr
