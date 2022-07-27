tool
extends "ConditionEditor.gd"

const Utils = preload("../../scripts/Utils.gd")


# https://godotengine.org/qa/57137/how-to-browse-files-using-a-editorplugin

onready var SelectCondition = $SelectCondition
onready var SelectCondition_popup_menu = $SelectCondition/FileDialog

func _ready():
	SelectCondition.connect("pressed", self, "_on_SelectCondition_pressed")
	SelectCondition_popup_menu.connect("file_selected", self, "_on_FileDialog_file_selected")
	SelectCondition_popup_menu.mode = FileDialog.MODE_OPEN_ANY
	SelectCondition_popup_menu.access = FileDialog.ACCESS_FILESYSTEM

func _on_FileDialog_file_selected(file):
	self.condition.condition_fpath = file
	$LineEdit.text = file
	

func _on_SelectCondition_pressed():
	Utils.popup_on_target(SelectCondition_popup_menu, SelectCondition)

func _on_condition_changed(new_condition):
	if new_condition:
		#TODO: how to keep path displayed in editor after leaving view and returning
		name_edit.text = new_condition.name
		name_edit.hint_tooltip = name_edit.text
