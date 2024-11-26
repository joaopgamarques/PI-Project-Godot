extends Node2D

# Load the meteor, laser, and health bonus scenes from the specified paths, which will be used to instantiate objects.
var meteor_scene: PackedScene = load("res://scenes/meteor.tscn")
var laser_scene: PackedScene = load("res://scenes/laser.tscn")
var health_bonus_scene: PackedScene = load("res://scenes/health_bonus.tscn")
var ship_scene: PackedScene = load("res://scenes/ship.tscn")  

var health: int = 3 # Player's health, initially set to 3.
var level: int = 1 # Player's current level.
var base_meteor_lambda: float = 2 # Base value for the average number of meteors per level (used in Poisson distribution).
var destroyed_meteor_count: int = 0 # Counts meteors destroyed since the last bonus.
var bonus_threshold: int = 0 # Threshold for meteor destruction count to trigger bonus.
var rng = RandomNumberGenerator.new() # Random number generator for various distributions.
var ship_types = ["Cruisers", "Battlecruisers", "Battleships"]  # Ship types.
var ship_probabilities = [0.6, 0.3, 0.1]  # Probabilities for each ship type.

signal level_up_signal(level: int) # Custom signal emitted when the level increases.

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set the initial bonus threshold.
	set_bonus_threshold()  
	# Set up the health and level display on the UI by sending the health value to the UI group.
	get_tree().call_group('ui', 'set_health', health)
	get_tree().call_group("ui", "set_level", level)
	# Connect the TimeIntervalTimer's timeout signal to the '_on_time_interval_timeout' function.
	# This timer controls when the level increases.
	$TimeIntervalTimer.timeout.connect(_on_time_interval_timeout)
	# Connect the MeteorWaveTimer's timeout signal to the '_on_wave_timeout' function.
	# This timer controls when each wave starts.
	$MeteorWaveTimer.timeout.connect(_on_wave_timeout)
	# Connect ShipTimer timeout to spawn logic.
	$ShipTimer.timeout.connect(_on_ship_timeout)
	# Set the initial level-up interval using a random normal distribution.
	set_random_level_interval()
	# Start the MeteorWaveTimer to begin spawning waves.
	start_wave_timer()
	# Start the ShipTimer for spawning ships.
	start_ship_timer()
	# Randomize the appearance of background stars for visual variety.
	set_random_background()

# Randomizes the position, scale, and speed of the background stars for visual variety.
func set_random_background():
	# Get the size of the viewport (visible screen area).
	var size := get_viewport().get_visible_rect().size
	# For each star in the 'Stars' node, set random position, scale, and animation speed.
	for star in $Stars.get_children():
		# Randomize X and Y positions within the viewport size.
		star.position = Vector2(rng.randi_range(0, int(size.x)), rng.randi_range(0, int(size.y)))
		# Randomize the scale of the star between 1 and 2.
		var random_scale = rng.randf_range(1, 2)
		star.scale = Vector2(random_scale, random_scale)
		# Randomize the animation speed of the star between 0.6 and 1.4.
		star.speed_scale = rng.randf_range(0.6, 1.4)

# Starts the meteor wave timer with a random interval.
func start_wave_timer() -> void:
	# Calculate the interval for the next wave using a truncated normal distribution.
	var next_wave_interval = Distributions.InverseTruncatedNormalCDF(5, 2, rng.randf_range(0, 1), 2, 8)
	print("Next wave in approximately ", next_wave_interval, " seconds.")
	# Set the interval and start the MeteorWaveTimer.
	$MeteorWaveTimer.wait_time = next_wave_interval
	$MeteorWaveTimer.start()
	
# Spawns a wave of meteors when the wave timer times out.
func _on_wave_timeout() -> void:
	# Calculate the average number of meteors for this wave using a Poisson distribution.
	var lambda = base_meteor_lambda + (level - 1) * 3
	var wave_meteor_count = Distributions.InversePoissonCDF(lambda, rng.randf_range(0, 1))
	print("Spawning wave of ", wave_meteor_count, " meteors.")
	# Spawn the calculated number of meteors.
	for i in range(wave_meteor_count):
		# Create an instance of the meteor using the loaded meteor scene.
		var meteor = meteor_scene.instantiate()
		# Add the newly created meteor as a child to the 'Meteors' node in the scene.
		$Meteors.add_child(meteor)
		# Connect the 'collision' signal for meteor-player interaction.
		meteor.connect('collision', _on_meteor_collision)
		# Connect the 'destroyed' signal for meteor-laser interaction.
		meteor.connect('destroyed', _on_meteor_destroyed)
	# Start the next wave timer.
	start_wave_timer()

# Handles meteor collision with the player.
func _on_meteor_collision(meteor: Node2D):
	# Play the collision sound from the player when the meteor collides.
	$Player.play_collision_sound()
	# Decrease the player's health upon meteor collision.
	reduce_player_health(meteor.damage, "Meteor")

# Handles the laser being fired from the player's position. Spawns a laser when the player shoots.
func _on_player_laser(_position) -> void:
	# Create an instance of the laser using the loaded laser scene.
	var laser = laser_scene.instantiate()
	# Add the laser as a child to the 'Lasers' node in the scene.
	$Lasers.add_child(laser)
	# Set the laser's position to the specified position (where the player fired the laser).
	laser.position = _position
	
# Increases the level when the level timer times out.
func _on_time_interval_timeout() -> void:
	# Level up the game by increasing the level, updating the UI, and adjusting difficulty as needed.
	level += 1  # Increment the level.
	get_tree().call_group("ui", "set_level", level)  # Update the level display on the UI.
	print("Level up! Now at Level: ", level)  # Print for debugging or logging.
	# Emit the custom level-up signal with the current level as an argument.
	level_up_signal.emit(level)
	# Set a new interval for the next level-up.
	set_random_level_interval()
	
# Randomizes the time interval for the next level up.
func set_random_level_interval() -> void:
	# Create a random number generator for randomizing level time-interval.
	rng.randomize()
	# Generate a normally distributed interval with the specified mean and standard deviation.
	var interval = Distributions.InverseTruncatedNormalCDF(45, 5, rng.randf_range(0, 1), 30, 60)
	print("Next level-up in approximately ", interval, " seconds.")
	# Apply the calculated interval to TimeIntervalTimer and start it.
	$TimeIntervalTimer.wait_time = interval
	$TimeIntervalTimer.start()

# Handles meteor destruction and checks if a health bonus should spawn.
func _on_meteor_destroyed(meteor_position: Vector2):
	# Increment the destroyed meteor count.
	destroyed_meteor_count += 1
	print("Meteors destroyed: ", destroyed_meteor_count, " / Bonus threshold: ", bonus_threshold)
	# Check if the bonus threshold is reached.
	if destroyed_meteor_count >= bonus_threshold:
		# Spawn a health bonus at the meteor's destroyed position.
		print("Bonus threshold reached! Spawning health bonus.")
		var health_bonus = health_bonus_scene.instantiate() 
		health_bonus.position = meteor_position  # Position the bonus at the meteor's position.
		add_child(health_bonus)  # Add the bonus to the level scene.
		# Connect the health bonus signal to the function for adding extra life.
		health_bonus.connect('picked_up', _on_health_bonus_picked)
		destroyed_meteor_count = 0  # Reset the counter.
		set_bonus_threshold()  # Set a new threshold for the next bonus.
	
# Sets a new bonus threshold based on a geometric distribution.
func set_bonus_threshold():
	# Create a random number generator for randomizing the bonus thresold.
	rng.randomize()
	bonus_threshold = Distributions.InverseGeometricCDF(0.1, rng.randf_range(0, 1), 5)
	print("New bonus threshold set to: ", bonus_threshold)

# Handles health bonus collection by the player.
func _on_health_bonus_picked(health_value: int):
	# Check if the player's health is less than the maximum allowed (7).
	if health < 7:
		# Increase the player's health.
		health += health_value
		# Update the UI to display the new health value.
		get_tree().call_group("ui", "set_health", health)
		# Print debug message for confirmation.
		print("Health bonus picked! Player health increased to: ", health)
	else:
		# If health is already at the maximum, do nothing.
		print("Health bonus picked, but health is already at maximum: ", health)

# Starts the ship spawn timer with a random interval.
func start_ship_timer() -> void:
	# Calculate a random interval using a truncated normal distribution.
	var ship_interval = Distributions.InverseTruncatedNormalCDF(10, 2.5, rng.randf_range(0, 1), 5, 15)
	print("Next ship in approximately ", ship_interval, " seconds.")
	# Set the timer's interval and start it.
	$ShipTimer.wait_time = ship_interval
	$ShipTimer.start()

# Spawns a ship when the ship timer times out.
func _on_ship_timeout() -> void:
	# Create an instance of the ship scene.
	var ship = ship_scene.instantiate()
	# Randomize the position at the top of the screen.
	var width = get_viewport().get_visible_rect().size.x
	ship.position = Vector2(rng.randi_range(100, width - 100), -100)  # Start above the screen.
	# Call the discrete distribution method to determine the ship type.
	var ship_type = Distributions.InverseDiscreteCDF(ship_types, ship_probabilities, rng.randf())
	print("Generated ship type: ", ship_type) # Print the type of the ship generated.
	# Set properties based on the ship type.
	match ship_type:
		"Cruisers":
			ship.health = 1
			ship.speed = 100
			ship.get_node("Sprite2D").texture = preload("res://graphics/ship/playerShip1_blue.png") # Replace with Cruisers texture.
		"Battlecruisers":
			ship.health = 2
			ship.speed = 100
			ship.get_node("Sprite2D").texture = preload("res://graphics/ship/playerShip2_blue.png")  # Replace with Battlecruisers texture.
			ship.get_node("Sprite2D").scale = Vector2(1.5, 1.5)  # Scale texture 1.5x.
			ship.get_node("CollisionShape2D").scale = Vector2(1.5, 1.5)  # Scale collision area 1.5x.
		"Battleships":
			ship.health = 3
			ship.speed = 100
			ship.get_node("Sprite2D").texture = preload("res://graphics/ship/playerShip3_blue.png")  # Replace with Battleships texture.
			ship.get_node("Sprite2D").scale = Vector2(2, 2)  # Scale texture 2x.
			ship.get_node("CollisionShape2D").scale = Vector2(2, 2)  # Scale collision area 2x.
	# Add the ship to the Ships node in the scene.
	$Ships.add_child(ship)
	# Connect the ship's destroyed signal to handle cleanup or scoring.
	ship.connect("destroyed", _on_ship_destroyed)
	# Connect the player_collided signal to handle player-ship collision
	ship.connect("player_collided", _on_player_ship_collision)
	# Restart the timer for the next ship.
	start_ship_timer()

# Handles the destruction of a ship.
func _on_ship_destroyed(_ship_position: Vector2):
	print("Enemy ship destroyed.")

# Handles collision between the player and a ship.
func _on_player_ship_collision(ship: Node2D) -> void:
	# Play the collision sound from the player when the meteor collides.
	$Player.play_collision_sound()
	# Decrease the ship's health upon ship collision.
	ship.health -= ship.damage
	# Check if the ship's health has reached 0 or below.
	if ship.health <= 0:
		ship.destroy_ship()
	# Decrease the player's health upon ship collision.
	reduce_player_health(ship.damage, "Ship")

# Reduces the player's health based on damage from lasers, meteors, or ships.
func reduce_player_health(damage: int, source: String) -> void:
	# Deduct the specified damage from the player's health.
	health -= damage
	# Update the health display in the UI.
	get_tree().call_group('ui', 'set_health', health)
	print("Player health reduced by: ", damage, " Source: ", source, " Remaining health: ", health)
	# Check if the player's health drops to zero or below.
	if health <= 0:
		print("Game Over! Player was defeated by: ", source)
		# Transition to the game over scene.
		get_tree().change_scene_to_file("res://scenes/game_over.tscn")
