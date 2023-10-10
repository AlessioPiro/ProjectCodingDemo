extends Resource
class_name BattleSignalManager

var battle_element_signal_managers_dictionary = {}


#Restituisce un BattleElementSignalManager dato l'id dell'elemento ad esso collegato. Se non esiste, lo crea.
func get_battle_element_signal_manager(key : int) -> BattleElementSignalManager:
	
	#Se il BattleElementSignalManager dell'elemento passato non esiste ancora, viene creato e aggiunto al dizionario
	if !battle_element_signal_managers_dictionary.has(key):
		battle_element_signal_managers_dictionary[key] = BattleElementSignalManager.new()
	
	var battle_element_signal_manager = battle_element_signal_managers_dictionary.get(key)
	
	return battle_element_signal_manager


#Elimina un BattleElementSignalManager dato il suo id
func delete_battle_element_signal_manager(key : String):
	
	if !battle_element_signal_managers_dictionary.has(key):
		battle_element_signal_managers_dictionary.erase(key)
