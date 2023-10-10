extends CanvasLayer

@onready var health_text = $CenterContainer/VBoxContainer/HBoxContainer/HealthText
@onready var money_text = $CenterContainer/VBoxContainer/HBoxContainer/MoneyText

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update_health_text()
	update_money_text()


func update_health_text():
	var new_text = str(Global.game_player_hp, "/", Global.player_hp)
	health_text.text = new_text

func update_money_text():
	money_text.text = str(Global.game_money)
