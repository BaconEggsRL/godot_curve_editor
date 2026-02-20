@tool
extends Node

# Label / Prefix
@export_group("Points/point_")
# Define properties.
@export var position := Vector2(0,0)
@export var left_control_point := Vector2(0,0)
@export_enum("Free", "Linear", "Balanced", "Mirrored") var left_mode: int
@export var right_control_point := Vector2(0,0)
@export_enum("Free", "Linear", "Balanced", "Mirrored") var right_mode: int

# End of properties.
@export_group("")

var label: String
var prefix: String

var property_info_cache: Array[Dictionary]
var defaults: Dictionary[String, Variant]
var making_cache: bool

var values: Dictionary[StringName, Variant]
var count: int
var count_property: StringName:
	get:
		return str(prefix, "count")

func _get_property_list() -> Array[Dictionary]:
	if making_cache:
		return []

	_ensure_cache()

	var ret: Array[Dictionary]
	ret.append({
		"name": count_property,
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_ARRAY,
		"class_name": str(label, ",", prefix)
	})

	for i in get(count_property):
		for property in property_info_cache:
			var info: Dictionary = property.duplicate()

			var prop_name := str(prefix, i, "/", property["name"])
			var default = defaults[property["name"]]
			info["name"] = prop_name
			if values.get(prop_name, default) == default:
				info["usage"] &= ~PROPERTY_USAGE_STORAGE

			ret.append(info)

	return ret

func _set(property: StringName, value: Variant) -> bool:
	_ensure_cache()

	if property == count_property:
		count = value
		notify_property_list_changed()
		return true

	if property.begins_with(prefix):
		values[property] = value
		return false

	return false

func _get(property: StringName) -> Variant:
	_ensure_cache()

	if property == count_property:
		return count

	if property.begins_with(prefix):
		if property in values:
			return values[property]

		var part := property.get_slice("/", 1)
		return defaults.get(part)

	return null

func _property_can_revert(property: StringName) -> bool:
	return property.begins_with(prefix)

func _property_get_revert(property: StringName) -> Variant:
	var part := property.get_slice("/", 1)
	return defaults.get(part)

func _validate_property(property: Dictionary) -> void:
	if property["name"] in defaults:
		property["usage"] = PROPERTY_USAGE_NONE

func _ensure_cache():
	if property_info_cache.is_empty():
		making_cache = true

		var in_group: bool
		for property in get_property_list():
			var propname: String = property["name"]
			if property["usage"] & PROPERTY_USAGE_GROUP:
				if not in_group and property["name"].contains("/"):
					in_group = true
					label = propname.get_slice("/", 0)
					prefix = propname.get_slice("/", 1)
				elif in_group and property["name"].is_empty():
					break

			if in_group:
				property_info_cache.append(property)
				defaults[propname] = get(propname)

		making_cache = false
