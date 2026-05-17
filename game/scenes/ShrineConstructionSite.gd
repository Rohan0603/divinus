# ShrineConstructionSite: Placeholder where followers gather to build a shrine.
# Emits shrine_completed when 3 builders have arrived and held for 5 seconds.
extends Node2D

const BUILDERS_REQUIRED = 3
const BUILD_TIME = 5.0

signal shrine_completed

var _builders_present: int = 0
var _building: bool = false
var _build_accum: float = 0.0

func _ready() -> void:
	add_to_group("shrine_sites")

func _process(delta: float) -> void:
	if _building:
		_build_accum += delta
		if _build_accum >= BUILD_TIME:
			_building = false
			shrine_completed.emit()

func builder_arrived() -> void:
	_builders_present += 1
	if _builders_present >= BUILDERS_REQUIRED and not _building:
		_building = true
		_build_accum = 0.0

func builder_left() -> void:
	_builders_present = max(0, _builders_present - 1)
	if _builders_present < BUILDERS_REQUIRED:
		_building = false
