extends Area2D

@export var speed: int = 500  # The speed at which the laser moves.
@export var damage: int = 1  # The damage the laser deals upon impact.
@export var direction: Vector2 = Vector2(0, 1)  # The laser moves downward by default.

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Create a tween to animate the scaling of the laser sprite for a smooth appearance effect.
	var tween = create_tween()
	# Animate the 'scale' property of $Sprite2D from (0, 0) to (1, 1) over 0.2 seconds.
	tween.tween_property($Sprite2D, 'scale', Vector2(1, 1), 0.2).from(Vector2(0, 0))

# Called every frame. 'delta' is the elapsed time since the previous frame. Moves the laser downward.
func _process(delta: float) -> void:
	# Move the laser in its direction at the given speed.
	position += direction * speed * delta
	# If the laser goes outside the viewport, remove it.
	if position.y < -50 or position.y > get_viewport().get_visible_rect().size.y + 50:  
		queue_free()

# Handles collision detection with other bodies.
func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":  # Check if the laser hit the player.
		body.get_node("DamageSound").play()  # Play the damage sound.
		# Access the Level node to reduce the player's health.
		var level  = get_tree().get_root().get_node("/root/Level")
		level.reduce_player_health(damage, "Ship Laser")
		queue_free() # Remove the laser after hitting the player.
