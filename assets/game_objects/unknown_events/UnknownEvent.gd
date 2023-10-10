extends Resource
class_name UnknownEvent

var id : String
var name : String
var question : String
var answer_1 : String
var answer_2 : String
var consequence_text_1 : String
var consequence_text_2 : String
var effects_1 = []
var effects_2 = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_event_by_dictionary(event_dictionary : Dictionary):
	id = event_dictionary.get("id")
	name = event_dictionary.get(str(Global.language, "_name"))
	question = event_dictionary.get(str(Global.language, "_question"))
	answer_1 = event_dictionary.get(str(Global.language, "_answer_1"))
	answer_2 = event_dictionary.get(str(Global.language, "_answer_2"))
	consequence_text_1 = event_dictionary.get(str(Global.language, "_consequence_1"))
	consequence_text_2 = event_dictionary.get(str(Global.language, "_consequence_2"))
	effects_1 = event_dictionary.get("effects_1")
	effects_2 = event_dictionary.get("effects_2")


func get_id() -> String:
	return id

func get_event_name() -> String:
	return name

func get_question() -> String:
	return question

func get_answer_1() -> String:
	return answer_1

func get_answer_2() -> String:
	return answer_2

func get_consequence_1() -> String:
	return consequence_text_1

func get_consequence_2() -> String:
	return consequence_text_2

func get_effects_1():
	return effects_1

func get_effects_2():
	return effects_2
