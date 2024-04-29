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
	if size == 0:
		return res
	
	percentage.resize(size)
	infimum.resize(size)
	var sum := 0
	var infimum_sum := 0
	
	for id: int in size:
		var d := {
			name="percentage/%s" % [id],
			type=TYPE_INT,
			usage=PROPERTY_USAGE_EDITOR,
			hint=PROPERTY_HINT_RANGE,
			#hint_string="%s,%s" % [infimum[id], 100 - sum],
			hint_string="%s,%s" % [0, 100],
		}
		sum += percentage[id]
		res.append(d)
		
		d = {
			name="infimum/%s" % [id],
			type=TYPE_INT,
			usage=PROPERTY_USAGE_EDITOR,
			hint=PROPERTY_HINT_RANGE,
			hint_string="%s,%s" % [0, 100],
			#hint_string="%s,%s" % [0, 100 - infimum_sum],
		}
		infimum_sum += infimum[id]
		res.append(d)
	return res


func _get(property: StringName):
	if property.begins_with("percentage/"):
		property = property.trim_prefix("percentage/")
		var id := int(property as String)
		#if percentage[id] < infimum[id]:
			#percentage[id] = infimum[id]
		return percentage[id]
	if property.begins_with("infimum/"):
		property = property.trim_prefix("infimum/")
		var id := int(property as String)
		return infimum[id]
	
	# No use if get() and set() behave the same.
	# (See comments at _set())
	#match property:
		#"size":
			#return size
		#"infimum":
			#return infimum
		#"percentage":
			#return percentage
	
	return null


# Seems that only undeclared variables will trigger set().
# Otherwise the setter will be triggered.
func _set(property: StringName, value: Variant) -> bool:
	print_debug("accessing _set: ", property)
	if property.begins_with("percentage/"):
		property = property.trim_prefix("percentage/")
		var id := int(property as String)
		
		# 可自由分配的空间余量.
		var upper_bound := disposable
		
		# 减去 id 前每一项额外占用的部分.
		for i: int in id:
			upper_bound -= percentage[i] - infimum[i]
		
		# 这一行为了不去单独处理 id 这个下标
		percentage[id] = value
		
		# 重新分配 id 及之后的每一项
		for i: int in range(id, size):
			# Is it necessary when the editor's hint existed?
			
			# 需要判断的是额外申请的空间是否足够
			# TODO: 这样写是有点绕, 可考虑percentage 分解成 infimum + addition
			if percentage[i] - infimum[i] <= upper_bound:
				upper_bound -= percentage[i] - infimum[i]
			else:
				percentage[i] = infimum[i]
				upper_bound = 0
			assert(upper_bound >= 0)
		
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
		
		print_debug("upper_bound in infimum:", upper_bound)
		# 为了不去单独处理 id 这个下标
		infimum[id] = value
		
		# Is it necessary when the editor's hint existed?
		# 奇怪, 如果把 size 改成 id + 1(即, 只修改 id 这一个下标, 目的是测试检查器
		# 是否能自动更新限制范围(通过 hint string))
		# 但是发现如果这样做, percentage 不会完全跟着自动更新, 并且 id 之外的 infimum
		# 似乎有了 "记忆性". e.g. 初始: percentage: 10, 55. infi: 3, 55.
		# 修改 infi: 3 -> 90, 得到: per: 90, 55. infi: 90, 10.
		# 再次修改: infi: 90 -> 6, 得到: per: 10, 55. infi: 6, 55.
		# upd: 发现原因: 数据记录在 percentage[id], 但是 get 得到的 percentage/id
		# 会被 hint_string 限制范围.
		for i: int in range(id, size):
			infimum[i] = clampi(infimum[i], 0, upper_bound)
			upper_bound -= infimum[i]
		notify_property_list_changed()
		emit_changed()
		# Percentage will adapt automatically.
		_set("percentage/0", percentage[0])
		return true

	return false
