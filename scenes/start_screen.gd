extends Control

# Exported variable to assign the main game scene (level) from the editor.
# This scene will be loaded when the player starts the game.
@export var level_scene: PackedScene

# Called when an input event occurs (e.g., key press or mouse event).
func _input(event: InputEvent) -> void:
	# Check if the player pressed the action defined as "shoot" in the Input Map.
	if event.is_action_pressed("shoot"):
		# Change the current scene to the level scene specified in 'level_scene'.
		get_tree().change_scene_to_packed(level_scene)
