extends Control

# Exported variable to assign a new scene (level) from the editor.
# This will be the scene the game switches to when the player restarts the game.
@export var level_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Update the text of the ScoreLabel to include the player's final score from the Global singleton.
	# This displays the player's score at the end of the game.
	$CenterContainer/VBoxContainer/ScoreLabel.text = $CenterContainer/VBoxContainer/ScoreLabel.text + str(Global.score)

# Called when an input event occurs (e.g., key press or mouse event).
func _input(event: InputEvent) -> void:
	# If the player presses the "shoot" action (e.g., a key or button bound to "shoot"),
	if event.is_action_pressed("shoot"):
		# Restart the game by changing to the assigned level scene.
		get_tree().change_scene_to_packed(level_scene)
