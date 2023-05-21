extends EditorInspectorPlugin

func _can_handle(object):
	return object.get_class() == 'State'

func _parse_property(object, type, path, hint, hint_text, usage, wide) -> bool:
	return false
	# Hide all property
	return true
	# TODO: in godot4 port here now "return false". Why show everything in inspector? I had:
	#if path in ['Global_Function_Condition']:
	#	return false
	#return true
