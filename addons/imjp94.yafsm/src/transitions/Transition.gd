tool
extends Resource

signal condition_added(condition)
signal condition_removed(condition)


export(String) var from # Name of state transiting from
export(String) var to # Name of state transiting to
export(Dictionary) var conditions setget ,get_conditions # Conditions to transit successfuly, keyed by Condition.name
export(int) var priority = 0 # Higher the number, higher the priority


export(Resource) var function_condition setget _set_fcond_res
onready var _fcond_resource = null

const FunctionConditionTrigger = preload('../conditions/FunctionConditionTrigger.gd')


func _init(p_from="", p_to="", p_conditions={}):
	from = p_from
	to = p_to
	conditions = p_conditions

# Attempt to transit with parameters given, return name of next state if succeeded else null
func transit(params={}, local_params={}):
	var can_transit = conditions.size() > 0
	
	for condition in conditions.values():
		var has_param = params.has(condition.name)
		var has_local_param = local_params.has(condition.name)
		if has_param or has_local_param:
			# local_params > params
			var value = local_params.get(condition.name) if has_local_param else params.get(condition.name)
			if value == null: # null value is treated as trigger
				can_transit = can_transit and true
			elif "value" in condition:
				can_transit = can_transit and condition.compare(value)
			else:
				print('Invalid condition encountered in transition ', condition.name)
		elif _is_FunctionCondition(condition):
			can_transit = can_transit and funcref(_fcond_resource, 'condition').call_func()
		else:
			can_transit = false
	
	if can_transit or conditions.size() == 0:
		return to
	return null

func _set_fcond_res(val):
	function_condition = val
	if val != null:
		_fcond_resource = val.new()
	else:
		_fcond_resource = null

func _is_FunctionCondition(condition):
	return condition.get_class() == 'FunctionConditionTrigger'

func has_FunctionCondition():
	for c in conditions.values():
		if _is_FunctionCondition(c):
			return true
	return false

# Add condition, return true if succeeded
func add_condition(condition):
	if condition.name in conditions:
		return false
	conditions[condition.name] = condition
	emit_signal("condition_added", condition)
	return true

# Remove condition by name of condition
func remove_condition(name):
	var condition = conditions.get(name)
	if condition:
		conditions.erase(name)
		emit_signal("condition_removed", condition)
		return true
	return false

# Change condition name, return true if succeeded
func change_condition_name(from, to):
	if not (from in conditions) or to in conditions:
		return false

	var condition = conditions[from]
	condition.name = to
	conditions.erase(from)
	conditions[to] = condition
	return true

func get_unique_name(name):
	var new_name = name
	var i = 1
	while new_name in conditions:
		new_name = name + str(i)
		i += 1
	return new_name

func equals(obj):
	if obj == null:
		return false
	if not ("from" in obj and "to" in obj):
		return false

	return from == obj.from and to == obj.to

# Get duplicate of conditions dictionary
func get_conditions():
	return conditions.duplicate()

static func sort(a, b):
	if a.priority > b.priority:
		return true
	return false
