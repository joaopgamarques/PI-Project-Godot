extends CharacterBody2D

@export var speed := 500 # The movement speed of the player, adjustable in the editor.
var can_shoot: bool = true  # Boolean to control if the player can shoot lasers.

# Signal emitted when shooting a laser, passing the position from which the laser should spawn.
signal laser(_position)

# Called when theS node enters the scene tree for the first time.
func _ready() -> void:
	# Set the initial position of the player character when the scene starts.
	position = Vector2(100, 500)

# Called every frame. '_delta' is the time that has passed since the last frame.
func _process(_delta: float) -> void:
	# Get the input direction from arrow keys (or mapped inputs).
	# This vector will determine the direction in which the player moves.
	var direction = Input.get_vector("left", "right", "up", "down")
	# Update the player's velocity based on the input direction and speed.
	velocity = direction * speed
	# Move the player using built-in collision detection.
	move_and_slide()
	
	# Check if the "shoot" action is pressed and if the player is allowed to shoot.
	if Input.is_action_just_pressed("shoot") and can_shoot:
		# Emit the 'laser' signal with the global position of the LaserStartPosition node.
		# This tells other nodes (e.g., laser node) where to spawn the laser.
		laser.emit($LaserStartPosition.global_position)
		# Temporarily disable shooting to enforce a delay between shots.
		can_shoot = false
		# Temporarily disable shooting to enforce a delay between shots.
		$LaserTimer.start()
		# Play the laser sound effect when the laser is fired.
		$LaserSound.play()

# Called when the LaserTimer finishes (timeout occurs).
func _on_laser_timer_timeout() -> void:
	# Re-enable shooting, allowing the player to fire another laser.
	can_shoot = true

# Plays a collision sound when the player takes damage or collides with an object.	
func play_collision_sound():
	# Play the sound effect associated with taking damage or a collision.
	$DamageSound.play()
