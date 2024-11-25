extends CanvasLayer

# Static variable to store the player life image. 
# This image will be used for displaying the player's health (lives).
static var image = load("res://graphics/lives/playerLife1_red.png")
var time_elapsed := 0 # Variable to track the amount of time elapsed during gameplay.

# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	# Access the Level node directly from the root and connect its level-up signal to the UI.
	$"/root/Level".connect('level_up_signal', _on_level_up)
	
# Function to set the player's health and update the health UI.
# This function dynamically adjusts the health icons based on the player's current health.
func set_health(amount):
	# Remove all existing health icons (children) from the HBoxContainer.
	for child in $MarginContainer2/HBoxContainer.get_children():
		child.queue_free()
	# Create and add new health icons based on the current health amount.
	for i in amount:
		# Create a new TextureRect node to represent a life icon.
		var text_rect = TextureRect.new()
		# Set the texture of the life icon to the player's life image.
		text_rect.texture = image
		# Add the new life icon to the HBoxContainer in the UI.
		$MarginContainer2/HBoxContainer.add_child(text_rect)
		# Ensure the life icon maintains its aspect ratio when resized.
		text_rect.stretch_mode = TextureRect.STRETCH_KEEP

# Function to handle the level-up signal from the Level node.
# Updates the displayed level in the UI.
func _on_level_up(level: int) -> void:
	# Update the LevelLabel text to reflect the current level.
	$MarginContainer3/LevelLabel.text = "Level: " + str(level)

# Called when the score timer times out (typically every second or at a defined interval).
# Updates the elapsed time and the displayed score in the UI.).
func _on_score_timer_timeout() -> void:
	# Increment the elapsed time by one second.
	time_elapsed += 1
	# Update the ScoreLabel text in the MarginContainer with the new elapsed time.
	$MarginContainer/ScoreLabel.text = str(time_elapsed)
	# Synchronize the global score with the elapsed time.
	Global.score = time_elapsed
