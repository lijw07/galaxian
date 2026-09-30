extends SceneTree


func _initialize() -> void:
	for directory in ["res://assets/sprites", "res://assets/ui", "res://assets/approved/frames"]:
		for file in DirAccess.get_files_at(directory):
			if not file.ends_with(".png.import"):
				continue
			var config := ConfigFile.new()
			var path: String = directory.path_join(file)
			if config.load(path) == OK:
				config.set_value("params", "process/fix_alpha_border", false)
				config.set_value("params", "mipmaps/generate", false)
				config.set_value("params", "compress/mode", 0)
				config.save(path)
	quit()
