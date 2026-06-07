extends SceneTree


func _initialize() -> void:
	var godot_bin: String = OS.get_executable_path()
	var project_path: String = ProjectSettings.globalize_path("res://")
	var suites: Array[String] = [
		"res://tests/unit",
		"res://tests/functional",
		"res://tests/integration",
	]
	var failed := false

	for suite in suites:
		var output: Array = []
		var exit_code: int = OS.execute(
			godot_bin,
			[
				"--headless",
				"--path",
				project_path,
				"-s",
				"addons/gut/gut_cmdln.gd",
				"-gdir=%s" % suite,
				"-gexit",
			],
			output,
			true
		)
		for line in output:
			print(line)
		if exit_code != 0:
			failed = true

	quit(1 if failed else 0)
