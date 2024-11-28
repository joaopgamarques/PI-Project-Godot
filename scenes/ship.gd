extends Area2D

@export var ship_laser_scene: PackedScene  # Scene for the ship's laser.
@export var speed: float = 100  # The ship's movement speed in pixels per second.
@export var health: int = 1  # The health points of the ship, adjustable based on type.
@export var damage: int = 1  # The damage the ship deals to the player upon collision.
var direction: Vector2 = Vector2(0, 1)  # Initial direction, default is downward.
var is_destroyed: bool = false  # Tracks whether the ship has already been destroyed to prevent repeated events..
var movement_pattern: int = -1  # Stores the assigned movement pattern for this ship.
var drift_direction: Vector2 = Vector2(0, 1)  # Default initial direction is downward.
var drift_timer: float = 0.0  # Tracks elapsed time for changing direction.
var is_moving_left: bool = true  # Tracks the current zigzag direction.
var zigzag_timer: float = 0.0  # Tracks elapsed time for changing direction.
var spiral_angle: float = 0.0  # Angle for the circular motion in radians.

signal destroyed(position: Vector2) # Signal emitted when the ship is destroyed, passing its position.
signal player_collided() # Signal to notify when the ship collides with the player.

# Dictionary to map movement pattern numbers to their names.
const PATTERN_NAMES = {
	0: "Zigzag Pattern",
	1: "Homing Pattern",
	2: "Random Drift Pattern",
	3: "Spiral Pattern"
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Enable the collision shape to ensure the ship is ready for interactions.
	$CollisionShape2D.disabled = false
	# Rotate the ship's sprite to face downward (default movement direction).
	$Sprite2D.rotation_degrees = 180
	# Assign a random movement pattern when the ship is created (only once).
	movement_pattern = randi() % 4  # Assign a random pattern between 0 and 3.
	# Get the pattern name from the dictionary.
	print("Assigned movement pattern: ", PATTERN_NAMES.get(movement_pattern, "Default Downward"))
	# Start the LaserTimer for firing lasers.
	$LaserTimer.timeout.connect(_on_laser_timer_timeout)
	$LaserTimer.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:	
	# Determine the direction based on the assigned movement pattern.
	direction = get_direction(movement_pattern, position, get_player_position())
	position += direction * speed * delta
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

# Determines the movement direction for the enemy ship based on a randomly chosen pattern.
# Each pattern represents a unique movement behavior.
func get_direction(pattern: int, current_position: Vector2, player_position: Vector2) -> Vector2:
	# Use a match statement to execute the corresponding movement pattern.
	match pattern:
		0:
			# Zigzag Pattern: The ship moves diagonally, alternating directions at intervals.
			return zigzag_pattern()
		1:
			# Homing Pattern: The ship moves directly toward the player's position.
			return homing_pattern(current_position, player_position)
		2:
			# Random Drift Pattern: The ship drifts in a random direction, changing occasionally.
			return random_drift_pattern()
		3:
			# Spiral Pattern: The ship moves in a spiral-like motion.
			return spiral_pattern()
		_:
			# Fallback Pattern: If no pattern is chosen, move straight downward.
			return Vector2(0, 1)

# Gets the player's position from the scene tree. Assumes the player node is named "Player".
func get_player_position() -> Vector2:
	var player = get_tree().get_root().get_node("/root/Level/Player")
	if player:
		return player.position
	return Vector2()  # Return a zero vector if the player node is not found.

# Moves the ship diagonally left or right alternately.
func zigzag_pattern() -> Vector2:
	var zigzag_interval: float = 3.0  # Time between switching directions.
	# Increment the timer by the delta time.
	zigzag_timer += get_process_delta_time()
	# Switch direction when the timer exceeds the interval.
	if zigzag_timer > zigzag_interval:
		is_moving_left = !is_moving_left  # Toggle direction.
		zigzag_timer = 0.0  # Reset the timer.
	# Set the horizontal direction based on the current state.
	var horizontal = -1 if is_moving_left else 1  # Move left (-1) or right (1).
	# Return the normalized direction vector.
	return Vector2(horizontal, 1).normalized()  # Move diagonally down.
	
# Moves the ship directly toward the player's position.
func homing_pattern(current_position: Vector2, player_position: Vector2) -> Vector2:
	# Calculate the direction vector pointing from the ship to the player.
	var direction_to_player = (player_position - current_position).normalized()
	# Return the direction vector for the ship to move in.
	return direction_to_player
	
# Moves the ship in a random direction, smoothly changing the drift direction occasionally.
func random_drift_pattern() -> Vector2:
	var drift_interval: float = 1.0  # Time (in seconds) between changing directions.
	var max_angle_change: float = 45.0  # Maximum angle change (in degrees) per interval.
	var min_forward_speed: float = 2.0  # Minimum forward (downward) component.
	# Increment the timer by the time since the last frame.
	drift_timer += get_process_delta_time()
	# If the drift interval is exceeded, adjust the drift direction slightly.
	if drift_timer > drift_interval:
		# Generate a small random angle change within the range [-max_angle_change, +max_angle_change].
		var angle_change = deg_to_rad(randf_range(-max_angle_change, max_angle_change))
		# Adjust the current drift direction by the angle change.
		drift_direction = drift_direction.rotated(angle_change).normalized()
		# Ensure the downward component (y) is always greater than `min_forward_speed`.
		if drift_direction.y < min_forward_speed:
			drift_direction.y = min_forward_speed
			drift_direction = drift_direction.normalized()
		# Reset the timer.
		drift_timer = 0.0
	# Return the updated drift direction.
	return drift_direction

# Moves the ship in a downward-moving spiral motion.
func spiral_pattern() -> Vector2:
	var spiral_speed: float = 5.0  # Speed of the spiral motion (angle increment per second).
	var downward_speed: float = 350.0  # Constant downward speed (in pixels per second).
	var spiral_radius: float = 750.0  # Radius of the circular motion (in pixels).
	# Increment the angle for the spiral motion based on time.
	spiral_angle += spiral_speed * get_process_delta_time()
	# Calculate the horizontal and vertical offsets for circular motion.
	var x_offset = cos(spiral_angle) * spiral_radius
	var y_offset = sin(spiral_angle) * spiral_radius
	# Combine the circular motion with a steady downward descent.
	var spiral_movement = Vector2(x_offset, downward_speed + y_offset / 2)
	# Normalize the movement vector to ensure consistent speed.
	return spiral_movement.normalized()
