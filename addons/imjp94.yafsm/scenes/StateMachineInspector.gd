extends EditorInspectorPlugin

func can_handle(object):
	return object.get_class() == 'StateMachine'

func parse_property(object, type, path, hint, hint_text, usage):
	# Hide all property
	return true
