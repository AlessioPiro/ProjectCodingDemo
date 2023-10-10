extends CanvasLayer


var target : String
var type : String
var play_special_animation : bool = false

var is_loading_ended : bool = false
var is_fade_in_animation_ended : bool = false

@onready var general_animator = $GeneralAnimation
@onready var specific_animator = $SpecificAnimation

var transition_image

func change_scene_from_map(output_scene : String, input_type : String):
	target = output_scene
	type = input_type
	var transition_image_path = _choose_sprite(type)
	var transition_image : Texture = load(transition_image_path)
	$VBoxContainer/TextureRect.texture = transition_image
	
	_fade_in_animation()


func change_scene_to_map(from_scene: String):
	var transition_image_path = _choose_sprite(from_scene)
	var transition_image : Texture = load(transition_image_path)
	$VBoxContainer/TextureRect.texture = transition_image
	target = "res://scenes/MapScene.tscn"
	visible = true
	general_animator.play("fade_in")


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "fade_in":
		is_fade_in_animation_ended = true
		_fade_out_animation()
	elif anim_name == "fade_out":
		visible = false


func on_loading_finish():
	is_loading_ended = true
	_fade_out_animation()

func _fade_out_animation():
	if is_loading_ended and is_fade_in_animation_ended:
		is_loading_ended = false
		is_fade_in_animation_ended = false
		$GeneralAnimation.play("fade_out")
		if specific_animator.has_animation(str(type, "_in")) and play_special_animation:
			$SpecificAnimation.play(str(type, "_out"))
			play_special_animation = false
		return

func _fade_in_animation():
	visible = true
	if specific_animator.has_animation(str(type, "_in")):
		play_special_animation = true
		specific_animator.play(str(type, "_in"))
	general_animator.play("fade_in")

func _choose_sprite(type : String):
	var path
	if FileAccess.file_exists(str("res://assets/icons/map_", type, "_icon.png")):
		path = str("res://assets/icons/map_", type, "_icon.png")
	else:
		path = str("res://assets/ui/general_menu_ui_elements/logo.png")
	return path
