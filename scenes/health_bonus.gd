extends Area2D

@export var fall_speed: int = 200  # The speed at which the health bonus falls.
@export var health_value: int = 1  # The amount of health this bonus provides when picked up.

signal picked_up(health_value: int)  # Signal emitted when the health bonus is picked up, passing the health value.

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Scale the sprite and collision area by 1.5x.
	$Sprite2D.scale *= 1.2  # Increase the size of the sprite by 1.5x.
	$CollisionShape2D.scale *= 1.2  # Increase the collision area by 1.5x.
	# Enable the processing of this node, allowing the _process function to run.
	set_process(true)

# Called every frame. 'delta' is the time elapsed since the previous frame.
func _process(delta: float) -> void:
	# Move the health bonus downwards at a constant speed.
	position.y += fall_speed * delta
	# If the health bonus moves out of the visible viewport, remove it from the scene.
	var screen_rect = get_viewport().get_visible_rect()
	if position.y > screen_rect.size.y:
		queue_free()

# Called when the health bonus collides with another body (e.g., the player).
func _on_body_entered(body):
	# If the health bonus collides with the player, emit the picked_up signal with its health value and remove it.
	if body.name == "Player":
		picked_up.emit(health_value)  # Notify listeners that the health bonus has been collected.
		queue_free()  # Remove the health bonus from the scene.
