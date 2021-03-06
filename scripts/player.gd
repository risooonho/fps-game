extends RigidBody

var PID
var isAlive = true
var hp = 100

export var view_sensitivity = 0.3

export var walk_speed = 5
export var jump_speed = 3
export var max_accel = 0.02
export var air_accel = 0.1

#For ray cast calcution
var to
var from
export var raylength = 1000

func _input(ie):
	if get_node("/root/client").connected && isAlive:
		if get_node("/root/client").localplayer == get_node("."):
			if ie.type == InputEvent.MOUSE_MOTION:
				var yaw = rad2deg(get_node("/root/client").localplayer.get_node("body").get_rotation().y)
				var pitch = rad2deg(get_node("/root/client").localplayer.get_node("body/cam").get_rotation().x)
		
				yaw = fmod(yaw - ie.relative_x * view_sensitivity, 360)
				pitch = max(min(pitch - ie.relative_y * view_sensitivity, 90), -90)
		
				get_node("/root/client").localplayer.get_node("body").set_rotation(Vector3(0, deg2rad(yaw), 0))
				get_node("/root/client").localplayer.get_node("body/cam").set_rotation(Vector3(deg2rad(pitch), 0, 0))
			
func _integrate_forces(state):
	if isAlive:
		if get_node("/root/client").localplayer == get_node("."):
			var aim = get_node("body").get_global_transform().basis
			var direction = Vector3()
	
			if Input.is_action_pressed("Forward"):
				direction -= aim[2]
			if Input.is_action_pressed("Backward"):
				direction += aim[2]
			if Input.is_action_pressed("Left"):
				direction -= aim[0]
			if Input.is_action_pressed("Right"):
				direction += aim[0]
			direction = direction.normalized()
	
			var ray = get_node("ray")
			if ray.is_colliding():
				var up = state.get_total_gravity().normalized()
				var normal = ray.get_collision_normal()
				var floor_velocity = Vector3()
		
				var speed = walk_speed
				var diff = floor_velocity + direction * walk_speed - state.get_linear_velocity()
				var vertdiff = aim[1] * diff.dot(aim[1])
				diff -= vertdiff
				diff = diff.normalized() * clamp(diff.length(), 0, max_accel / state.get_step())
				diff += vertdiff
				apply_impulse(Vector3(), diff * get_mass())
		
				if Input.is_key_pressed(KEY_SPACE):
					apply_impulse(Vector3(), Vector3(0,1,0) * jump_speed * get_mass())
			else:
				apply_impulse(Vector3(), direction * air_accel * get_mass())
		
			state.integrate_forces()

func _ready():
	set_process_input(true)
	set_fixed_process(true)

func _fixed_process(delta):
	#print(PID)
	var screensize = OS.get_window_size()/2
	from =  get_node("body/cam").project_ray_origin(screensize)
	to = from + get_node("body/cam").project_ray_normal(screensize) * raylength
	
	var space_state = get_world().get_direct_space_state()
	var result = space_state.intersect_ray(from, to)
	
	if Input.is_action_pressed("Fire1"):
		if !result.empty():
			var collider = result.collider
			
			if collider != null && collider extends RigidBody:
				if collider.is_in_group("player"):
					print("Hit ", collider.get_name())
				collider.apply_impulse(result.position-collider.get_global_transform().origin, -result["normal"]*4*collider.get_mass())
				
func _enter_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _exit_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)