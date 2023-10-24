extends Node3D
class_name MovesetManagerComponent

@export_enum("random_choice") var behavior = "random_choice"

var moves = []

# Called when the node enters the scene tree for the first time.
func _ready():
	init_moveset_manager()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func init_moveset_manager():
	moves = get_children()
	choose_move()

func choose_move():
	if moves.size() == 0:
		return
	
	match behavior:
		"random_choice":
			var rng = RandomNumberGenerator.new()
			var move_index = rng.randi_range(0, moves.size() - 1)
			var move = moves[move_index]
			move.spawn()
			if move.has_node("AnimationPlayer"):
				var anim_player = move.get_node("AnimationPlayer")
				if !anim_player.is_connected("animation_finished", on_animation_finished):
					anim_player.animation_finished.connect(on_animation_finished)

func on_animation_finished(animation_name : String):
	choose_move()
