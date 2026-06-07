class_name Session


static func create_seat(id: String, is_learner: bool, dog_breed: String) -> Dictionary:
	return {
		"id": id,
		"isLearner": is_learner,
		"dogBreed": dog_breed,
		"hands": [],
	}
