extends Area2D

@export var ship_laser_scene: PackedScene  # Scene for the ship's laser.
@export var speed: float = 100  # The ship's movement speed in pixels per second.
@export var health: int = 1  # The health points of the ship, adjustable based on type.
@export var damage: int = 1  # The damage the ship deals to the player upon collision.
var is_destroyed: bool = false  # Tracks whether the ship has already been destroyed to prevent repeated events.

signal destroyed(position: Vector2) # Signal emitted when the ship is destroyed, passing its position.
signal player_collided() # Signal to notify when the ship collides with the player.

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Enable the collision shape to ensure the ship is ready for interactions.
	$CollisionShape2D.disabled = false
	# Rotate the ship's sprite to face downward (default movement direction).
	$Sprite2D.rotation_degrees = 180
	# Start the LaserTimer for firing lasers.
	$LaserTimer.timeout.connect(_on_laser_timer_timeout)
	$LaserTimer.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Move the ship downward at a constant speed, scaled by delta for frame independence.
	position.y += speed * delta
	# If the ship moves out of the viewport (below the screen), remove it from the scene.
	if position.y > get_viewport().get_visible_rect().size.y + 100:
		queue_free()

# Called when a collision occurs (e.g., hit by a laser).
func _on_body_entered(body: Node2D) -> void:
	if is_destroyed:
		print("Collision ignored, ship is already destroyed.")
		return  # Prevent handling multiple hits after destruction.
	if body.name == "Player":
		print("Player collided with ship.")
		player_collided.emit(self) # Emit the 'player_collided' signal to notify that the player and ship collided.

# Called when an area (e.g., a laser) enters the ship’s collision area.
func _on_area_entered(area: Area2D) -> void:
	if is_destroyed:
		return  # Prevent handling multiple hits after destruction.
	if area.name == "Laser":
		health -= area.damage # Reduce the ship's health by the laser's damage value.
		print("Ship health after hit: ", health)
		if health <= 0:
			destroy_ship()
		else:
			$DamageSound.play() # Play a sound effect to indicate the ship took damage.
		# Remove the laser from the scene after it hits the ship.
		area.queue_free()

# Handles the destruction of the ship.
func destroy_ship() -> void:
	if is_destroyed:
		print("Destroy ship called but ship is already destroyed.")
		return  # Ensure destruction happens only once.
	is_destroyed = true
	print("Ship destroyed at position: ", position)
	# Disable the ship's collision shape to prevent further interactions.y.
	$CollisionShape2D.set_deferred("disabled", true)
	# Disable the ship's collision shape to prevent further interactions.
	$ExplosionSound.play()
	# Emit the 'destroyed' signal with the ship's position for effects or scoring.
	destroyed.emit(position)
	# Hide the ship's sprite to simulate destruction visually.
	$Sprite2D.hide()
	# Wait for a short delay (e.g., for the explosion effect) before removing the ship from the scene.
	await get_tree().create_timer(1).timeout
	queue_free() # Remove the ship from the scene.

# Fires a laser when the timer times out.
func _on_laser_timer_timeout() -> void:
	if is_destroyed:
		return  # Stop firing if the ship is destroyed.
	# Create an instance of the ship laser.
	var laser = ship_laser_scene.instantiate()
	laser.position = $LaserStartPosition.global_position  # Set laser position to the start position.
	laser.direction = Vector2(0, 1)  # Move downward.
	# Add the laser to the game world.
	get_parent().add_child(laser)
	# Play the laser firing sound.
	$LaserSound.play()
