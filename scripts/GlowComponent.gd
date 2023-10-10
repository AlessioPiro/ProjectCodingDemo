extends Node3D

##Texture del Glow
@export var glow_texture : Texture
##Colore della luce
@export var modulate : Color
##Intensità minima della luce (da 0 a 255)
@export_range(0, 1) var min_intensity : float
##Intensità massima della luce (da 0 a 255)
@export_range(0, 1) var max_intensity : float
##Velocità del glow (1 è il valore standard)
@export var glow_speed : float
##Se all'avvio il glow è visibile o meno
@export var visible_on_start : bool = false
##Priorità per la visibilità
@export var glow_sorting_offset = 0
##Priorità di rendering
@export var render_priority = 0

@onready var glow_sprite = $Glow
@onready var animation_player = $GlowAnimationPlayer
var transparency = 0
var min_glow : Color
var max_glow : Color


# Called when the node enters the scene tree for the first time.
func _ready():
	min_glow = Color(modulate, min_intensity)
	max_glow = Color(modulate, max_intensity)
	_set_animation_keyframes()
	
	if !visible_on_start:
		animation_player.stop()
		glow_sprite.modulate = Color(modulate, 0)
	
	glow_sprite.sorting_offset = glow_sorting_offset
	glow_sprite.render_priority = render_priority
	glow_sprite.texture = glow_texture


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _set_animation_keyframes():
	
	animation_player.speed_scale = glow_speed
	
	var animation = animation_player.get_animation("glow")
	
	animation.track_set_key_value(0, 0, min_glow)
	animation.track_set_key_value(0, 1, max_glow)
	animation.track_set_key_value(0, 2, min_glow)
	
	animation_player.play("glow")

func stop_glow():
	var animation = animation_player.get_animation("stop_glow")
	animation.track_set_key_value(0, 0, min_glow)
	animation_player.play("stop_glow")

func start_glow():
	var animation = animation_player.get_animation("start_glow")
	animation.track_set_key_value(0, 1, min_glow)
	animation_player.play("start_glow")
	animation_player.animation_set_next ("start_glow", "glow")


func update_render_priority(new_render_priority : int):
	glow_sprite.render_priority = new_render_priority
	render_priority = new_render_priority
