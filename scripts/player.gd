extends CharacterBody3D

# Movement
@export var walk_speed: float = 4.5
@export var sprint_speed: float = 7.5
@export var acceleration: float = 12.0
@export var air_control: float = 0.25
@export var jump_velocity: float = 4.5

# Mouse look
@export var mouse_sensitivity: float = 0.003
@export var invert_y: bool = false
@export var look_smoothness: float = 0.15

# Head bob
@export var bob_frequency: float = 8.0
@export var bob_amplitude: float = 0.05

# Internal variables
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _yaw: float = 0.0
var _pitch: float = 0.0
var _target_yaw: float = 0.0
var _target_pitch: float = 0.0
var _bob_timer: float = 0.0
var _default_head_y: float = 0.0

@onready var head: Node3D = $Head
@onready var cam: Camera3D = $Head/Camera3D

# ----------------------------------
# SAFE _ready function
# ----------------------------------
func _ready() -> void:
	# Spawn at marker if it exists
	var spawn: Node3D = get_parent().get_node_or_null("PlayerSpawn")
	if spawn != null:
		global_transform.origin = spawn.global_transform.origin
	else:
		push_warning("No PlayerSpawn marker found. Using default position.")

	# Safely get head
	if head != null:
		_default_head_y = head.translation.y
	else:
		push_warning("Head node not found! Camera/head may not work.")

	# Capture mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# ----------------------------------
# Handle mouse input
# ----------------------------------
func _unhandled_input(event: InputEvent) -> void:
	# Toggle mouse capture
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		return

	# Recapture mouse on left click
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Mouse motion
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var dx: float = event.relative.x * mouse_sensitivity
		var dy: float = event.relative.y * mouse_sensitivity
		if not invert_y:
			dy *= -1.0

		_target_yaw += dx
		_target_pitch = clamp(_target_pitch + dy, deg_to_rad(-85), deg_to_rad(85))

# ----------------------------------
# Physics/movement
# ----------------------------------
func _physics_process(delta: float) -> void:
	# Smooth rotation
	_yaw = lerp(_yaw, _target_yaw, look_smoothness)
	_pitch = lerp(_pitch, _target_pitch, look_smoothness)
	rotation.y = _yaw
	if head != null:
		head.rotation.x = _pitch

	# Movement input
	var input_dir: Vector2 = Vector2(
		int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left")),
		int(Input.is_action_pressed("move_backward")) - int(Input.is_action_pressed("move_forward"))
	)

	var direction: Vector3 = Vector3.ZERO
	if input_dir.length() > 0:
		input_dir = input_dir.normalized()
		direction = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	# Speed
	var speed: float = walk_speed
	if Input.is_action_pressed("sprint"):
		speed = sprint_speed

	# Smooth acceleration
	var accel: float
	if is_on_floor():
		accel = acceleration
	else:
		accel = acceleration * air_control

	var target_velocity: Vector3 = direction * speed
	velocity.x = lerp(velocity.x, target_velocity.x, accel * delta)
	velocity.z = lerp(velocity.z, target_velocity.z, accel * delta)

	# Jump & gravity
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
	else:
		velocity.y -= _gravity * delta

	# Move character (Godot 4)
	move_and_slide()

	# Head bob
	if head != null:
		var horizontal_speed: float = Vector3(velocity.x, 0.0, velocity.z).length()
		if horizontal_speed > 0.1 and is_on_floor():
			_bob_timer += delta * bob_frequency * (horizontal_speed / sprint_speed)
		else:
			_bob_timer = 0.0
		head.translation.y = _default_head_y + sin(_bob_timer) * bob_amplitude
