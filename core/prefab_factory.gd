extends Node

## Project-local prefab registry. Most visuals in this collection are drawn
## procedurally so that every game remains deterministic and asset-light.
var dimension_mode := "2d"
var _factories: Dictionary = {}

func _ready() -> void:
	set_dimension_mode("2d")

func set_dimension_mode(mode: String) -> void:
	dimension_mode = mode

func register(prefab_id: String, factory: Callable) -> void:
	_factories[prefab_id] = factory

func create(prefab_id: String, properties: Dictionary = {}) -> Node:
	if not _factories.has(prefab_id):
		return Node2D.new()
	return _factories[prefab_id].call(properties)
