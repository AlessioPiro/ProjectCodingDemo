extends Path3D

@export var starting_path : Curve3D
@export var from_main_menu_to_shop_menu : Curve3D
@export var from_main_menu_to_bench_menu : Curve3D
@export var from_main_menu_to_pc1_menu : Curve3D
@export var from_shop_menu_to_bench_menu : Curve3D
@export var from_shop_menu_to_pc1_menu : Curve3D
@export var from_bench_menu_to_shop_menu : Curve3D
@export var from_bench_menu_to_pc1_menu : Curve3D
@export var from_pc1_menu_to_shop_menu : Curve3D
@export var from_pc1_menu_to_bench_menu : Curve3D

@onready var lunas_camera = $PathFollow3D/LunasCamera

# Called when the node enters the scene tree for the first time.
func _ready():
	curve = starting_path


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func reset_path():
	curve = starting_path
	#lunas_camera.position = curve.get_point_position(0)

func change_path(from : String, to : String):
	var path_name = str("from_", from, "_to_", to)
	match path_name:
		"starting_path":
			curve = starting_path
			#lunas_camera.position = curve.get_point_position(0)
		"from_main_menu_to_shop_menu":
			curve = from_main_menu_to_shop_menu
			#lunas_camera.position = curve.get_point_position(0)
		"from_main_menu_to_bench_menu":
			curve = from_main_menu_to_bench_menu
			#lunas_camera.position = curve.get_point_position(0)
		"from_main_menu_to_pc1_menu":
			curve = from_main_menu_to_pc1_menu
			#lunas_camera.position = curve.get_point_position(0)
		"from_shop_menu_to_bench_menu":
			curve = from_shop_menu_to_bench_menu
			#lunas_camera.position = curve.get_point_position(0)
		"from_shop_menu_to_pc1_menu":
			curve = from_shop_menu_to_pc1_menu
			#lunas_camera.position = curve.get_point_position(0)
		"from_bench_menu_to_shop_menu":
			curve = from_bench_menu_to_shop_menu
			#lunas_camera.position = curve.get_point_position(0)
		"from_bench_menu_to_pc1_menu":
			curve = from_bench_menu_to_pc1_menu
			#lunas_camera.position = curve.get_point_position(0)
		"from_pc1_menu_to_shop_menu":
			curve = from_pc1_menu_to_shop_menu
			#lunas_camera.position = curve.get_point_position(0)
		"from_pc1_menu_to_bench_menu":
			curve = from_pc1_menu_to_bench_menu
			#lunas_camera.position = curve.get_point_position(0)
		
	
