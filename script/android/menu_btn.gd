@tool
extends HBoxContainer

@export var percentage: SubNodePercentage:
	set(v):
		percentage = v
		set_sub_node_size()
@export var reset_sub_node_min_size := false:
	set(v):
		if not v:
			return
		save_op.custom_minimum_size = Vector2.ZERO
		item_op.custom_minimum_size = Vector2.ZERO
		class_op.custom_minimum_size = Vector2.ZERO

@onready var save_op: Button = $SaveOp
@onready var item_op: Button = $ItemOp
@onready var class_op: Button = $ClassOp


func _ready() -> void:
	print_debug('ready')
	percentage.changed.connect(set_sub_node_size)
	if percentage:
		set_sub_node_size()


func set_sub_node_size() -> void:
	if not is_node_ready():
		await ready
	print_debug("adjusting")
	# 如果是 get_...("...", "BoxContainer"), 就是获得 box container 这个类默认定义的属性
	var separation: int = get_theme_constant("separation")
	# 这里的 disposable 不能写 Global.WIN_WIDTH(无法识别到 width, 但是 global 不是 null)
	# 也不能把变量定义在函数外(变量值就是零, 不知道为啥, 肯定和工具脚本的规则有关)
	var disposable := size.x - separation * (get_child_count() - 1)
	
	# 各个比例不能设置得太小, 本来这个功能应由 SubNodePercentage 来限制,
	# 只是最小比例可能是动态的, 那可能就需要依赖注入/控制反转的写法
	# 这里暂时这样凑活
	# 假设最小占比之和不超过 100%
	# 先确保所有部分的最小比例
	var first := save_op.get_minimum_size().x / disposable * 100
	var second := item_op.get_minimum_size().x / disposable * 100
	var third := class_op.get_minimum_size().x / disposable * 100
	
	# 还需要注意他们的和不能超过 100
	var remaining := 100 - first - second - third
	# 按顺序把可用空间分配出去.
	if first >= percentage.first_part:
		# 留出最小空间
		pass
	elif first + remaining >= percentage.first_part:
		remaining -= percentage.first_part - first
		first = percentage.first_part
	else:
		# Insufficient space.
		first += remaining
		remaining = 0
	
	
	if second >= percentage.second_part:
		pass
	elif second + remaining >= percentage.second_part:
		remaining -= percentage.second_part - second
		second = percentage.second_part
	else:
		# Insufficient space.
		second += remaining
		remaining = 0
	# 最后一个直接取用剩下的所有空间
	third += remaining
	
	# 重构要换成数组写法, 即使只有三个也是数组写起来更好
	percentage.first_part = int(first)
	percentage.second_part = int(second)
	percentage.third_part = int(third)
	# custom min size 设置到最小
	save_op.custom_minimum_size.x = 0
	item_op.custom_minimum_size.x = 0
	class_op.custom_minimum_size.x = 0
	
	# 以上任何一点不做到, 都会在调整过程中让父级的 size.x 变大.
	# (然后就变不回去了, 单调不减, 子节点也相应的会变大, 大家都越来越大)
	save_op.custom_minimum_size.x = disposable * first / 100.0
	item_op.custom_minimum_size.x = disposable * second / 100.0
	class_op.custom_minimum_size.x = disposable * third / 100.0
	
	


func _on_resized() -> void:
	print_debug("size changed to ", size)
	pass # Replace with function body.
