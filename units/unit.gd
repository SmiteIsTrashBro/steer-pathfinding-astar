extends Node2D


# Steering parameters
@export var max_speed: float = 150.0
@export var max_force: float = 5.0
@export var mass: float = 2.0
@export var prediction_time: float = 0.5
@export var path_follow_distance: float = 50.0
@export var slowing_radius: float = 100.0

var path_curve: Curve2D = Curve2D.new()
var velocity: Vector2 = Vector2.ZERO

@onready var debug_future_pos: Sprite2D = $Debug/FuturePos
@onready var debug_path: Line2D = $Debug/Path
@onready var debug_projected_point: Sprite2D = $Debug/ProjectedPoint
@onready var debug_offset_projected: Sprite2D = $Debug/OffsetProjected
@onready var debug_future_projected_dist: Label = $Debug/FutureProjectedDist
@onready var point_offset: Label = $Debug/PointOffset
@onready var debug_speed: Label = $Debug/Speed


func _ready() -> void:
	#velocity = transform.x * max_speed
	pass
	

func _physics_process(delta: float) -> void:
	if path_curve.get_point_count() < 2:
		return  # Ensure the curve has enough points
		
	var future_pos = global_position + velocity * prediction_time
	var target_offset = path_curve.get_baked_length()
	var current_offset = path_curve.get_closest_offset(future_pos)
	var desired_offset = move_toward(current_offset, target_offset, 100)
	
	var desired_pos = path_curve.sample_baked(desired_offset)
	var current_pos = path_curve.sample_baked(current_offset)
	var target_pos = path_curve.sample_baked(target_offset)
	
	if future_pos.distance_to(current_pos) > path_follow_distance:
		var steering = seek(desired_pos)
		apply_force(steering, delta)
	else:
		var steering = arrive(target_pos)
		apply_force(steering, delta)

	debug_future_pos.global_position = future_pos
	debug_projected_point.global_position = path_curve.sample_baked(current_offset)
	debug_offset_projected.global_position = path_curve.sample_baked(desired_offset)
	point_offset.text = "curve offset ===> current: %.2f // target: %.2f // desired: %.2f" % [current_offset, target_offset, desired_offset]
	debug_speed.text = "speed: %.2f" % [velocity.length()]
	
	
	#position += velocity * delta
	
	
	if velocity.length_squared() > 5:
		var current_rotation = transform.x
		var desired_rotation = velocity.normalized()
		rotation = current_rotation.slerp(desired_rotation, 0.05).angle()
		
	
	
func seek(target: Vector2) -> Vector2:
	var to_target = global_position.direction_to(target)
	var desired_velocity = to_target * max_speed
	var steering = desired_velocity - velocity
	return steering
	
	
# Arrival behavior to slow down near target
func arrive(target: Vector2) -> Vector2:
	var distance = global_position.distance_to(target)
	var desired_speed = max_speed

	if distance < slowing_radius:
		desired_speed = max_speed * (distance / slowing_radius)

	var desired_velocity = global_position.direction_to(target) * desired_speed
	var steering_force = desired_velocity - velocity

	return steering_force
	
	
func apply_force(force: Vector2, delta: float) -> void:
	var limited_force = force.limit_length(max_force)
	
	var acceleration = limited_force / mass

	# Update velocity based on acceleration and maintain speed limit
	velocity += acceleration
	velocity = velocity.limit_length(max_speed)
	

func set_path(new_path: PackedVector2Array) -> void:
	path_curve.clear_points()
	for point in new_path:
		path_curve.add_point(point)
	debug_path.set_points(path_curve.tessellate())
