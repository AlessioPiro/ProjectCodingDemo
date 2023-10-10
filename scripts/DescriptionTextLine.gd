extends HBoxContainer

@export var bullet_point_visible = false

# Called when the node enters the scene tree for the first time.
func _ready():
	if bullet_point_visible:
		_enable_bullet_point()
	else:
		_disable_bullet_point()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _disable_bullet_point():
	$BulletPoint.visible = false

func _enable_bullet_point():
	$BulletPoint.visible = true

func set_text(new_text : String, font_size : int):
	$Text.text = new_text
	$Text.add_theme_font_size_override("normal_font_size", font_size)

