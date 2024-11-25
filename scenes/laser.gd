extends Area2D

@export var speed: int = 500  # The speed at which the laser moves.
@export var direction: Vector2 = Vector2(0, -1)  # The direction of the laser's movement, default is upwards.
@export var damage: int = 1  # The amount of damage the laser deals upon impact.

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Create a tween to animate the scaling of the laser sprite for a smooth appearance effect.
	var tween = create_tween()
	# Animate the 'scale' property of $Sprite2D from (0, 0) to (1, 1) over 0.2 seconds.
	tween.tween_property($Sprite2D, 'scale', Vector2(1, 1), 0.2).from(Vector2(0, 0))

# Called every frame. 'delta' is the time elapsed since the previous frame.
func _process(delta: float) -> void:
	# Move the laser in the specified direction, scaled by its speed and delta time for frame rate independence.
	position += direction * speed * delta
	# Check if the laser has moved outside the visible screen area.
	if position.y < -50 or position.y > get_viewport().get_visible_rect().size.y + 50:  
		# Remove the laser from the scene to free up resources and avoid unnecessary processing.
		queue_free()
