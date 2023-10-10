extends Control

@onready var before_opening_container = $BeforeOpeningContainer
@onready var bottom_text = $BottomText
@onready var transition_animation = $TransitionAnimation

var coins_number = 27

# Called when the node enters the scene tree for the first time.
func _ready():
	init_texts()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func import_data_from_previous_scene(transfer_data : Dictionary):
	if transfer_data.has("coins_number"):
		coins_number = transfer_data.get("coins_number")

func init_texts():
	bottom_text.text = str(coins_number, "\nCOINS")

func give_reward():
	Global.game_money += coins_number

func _on_map_button_pressed():
	var transfer_data = {}
	transfer_data["progress"] = true
	Global.change_scene_to_map("treasure", transfer_data)


func _on_lock_button_pressed():
	transition_animation.play("transition")
