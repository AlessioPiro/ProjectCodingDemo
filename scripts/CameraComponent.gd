extends Camera3D

@export var strong_shake_strenght = 1
@export var week_shake_strenght = 0.5
@export var shake_fade = 8

var rng = RandomNumberGenerator.new()

var shake_power : float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	#rotation = Vector3(0,45.55,0)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if shake_power != 0:
		shake_power = lerpf(shake_power, 0, shake_fade * delta)
		
		h_offset = rng.randf_range(-shake_power, shake_power)
		v_offset = rng.randf_range(-shake_power, shake_power)

func shake(intensity : String):
	if intensity == "strong":
		shake_power = strong_shake_strenght
	elif intensity == "week":
		shake_power = week_shake_strenght

