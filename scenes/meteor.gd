extends Area2D

@export var damage: int = 1  # Damage the meteor deals to the player.
var speed: int # Meteor's movement speed in pixels per second.
var rotation_speed: int # Meteor's rotation speed in degrees per second.
var direction: Vector2 # Meteor's movement direction vector.
var can_collide := true # Controls whether the meteor can collide, preventing multiple collisions.

signal destroyed # Signal emitted when the meteor is destroyed.
signal collision(meteor: Node2D) # Signal emitted when the meteor collides with another object.

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Create a random number generator for randomizing meteor properties.
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	# Randomly load one of the six meteor textures from the specified folder.
	var path: String = "res://graphics/Meteors/" + str(rng.randi_range(1, 6)) + ".png"
	$Sprite2D.texture = load(path)
	# Ensure CollisionShape2D is enabled when the meteor spawns.
	$CollisionShape2D.disabled = false
	# Get the player node. Adjust the path to match your scene structure.
	var player = get_tree().get_root().get_node("/root/Level/Player")
	# Randomize the meteor's starting position within the viewport.
	var width = get_viewport().get_visible_rect().size[0]
	# Randomize the meteor's starting position within the viewport.
	position = Vector2(rng.randi_range(0, width), rng.randi_range(-500, -50)) # Meteor's starting position.
	# Calculate direction towards the player or default to a downward vector if the player is not found.
	direction = calculate_direction_to_target(position, player.position) if player else Vector2(0, 1)
	# Apply a random deviation to the movement direction for variety.
	var deviation_angle_degrees = Distributions.InverseTruncatedNormalCDF(0, 15, rng.randf_range(0, 1), -45, 45)
	var deviation_angle_radians = deg_to_rad(deviation_angle_degrees)  # Convert degrees to radians. 
	# Rotate the meteor to face the movement direction.
	direction = direction.rotated(deviation_angle_radians)
	# Rotate the meteor to face the player direction.
	rotation = direction.angle()
	# Set a random movement speed using an exponential distribution for variability.
	# Set the movement speed in pixels per second.
	speed = Distributions.InverseTruncatedExponentialCDF(0.005, rng.randf_range(0, 1), 150, 500)
	# Set a random rotation speed in degrees per second.
	rotation_speed = rng.randi_range(-180, 180)

# Helper method to calculate a normalized direction vector from a start position to a target position.
func calculate_direction_to_target(start_position: Vector2, target_position: Vector2) -> Vector2:
	return (target_position - start_position).normalized()

# Called every frame. Moves and rotates the meteor based on its speed and rotation.
func _process(delta: float) -> void:
	# Move the meteor downward and sideways scaled by speed and delta.
	position += direction * speed * delta
	# Rotate the meteor based on its rotation speed and delta to ensure frame-rate independence.
	rotation_degrees += rotation_speed * delta

# Called when the meteor collides with another body (e.g., the player or an obstacle).
func _on_body_entered(_body: Node2D) -> void:
	if can_collide:
		# Emit the 'collision' signal to notify other nodes (e.g., player) about the collision.
		print("Meteor collided with player!")
		collision.emit(self)

# Called when the meteor enters an area (e.g., another meteor or projectile).
func _on_area_entered(area: Area2D) -> void:
	# Remove the colliding area (e.g., a laser) from the scene.
	area.queue_free()  # Free the laser or other objects that collided with the meteor.
	# Disable the meteor's collision to prevent multiple hits.
	$CollisionShape2D.set_deferred("disabled", true)
	# Emit the 'destroyed' signal, passing the meteor's position.
	destroyed.emit(position)
	# Play an explosion sound effect.
	$ExplosionSound.play()
	# Hide the meteor's sprite to simulate destruction.
	$Sprite2D.hide()
	# Prevent further collisions by disabling 'can_collide'.
	can_collide = false
	# Wait for a short delay (1 second) before removing the meteor from the scene.
	await get_tree().create_timer(1).timeout
	queue_free() # Remove the meteor from the scene to free resources.
