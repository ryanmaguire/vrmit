class_name SnapPointManager extends Node

## Single registry of every [SnapPoint] currently in the circuit.
## One instance lives under the Circuits node. Components register their terminals
## on spawn and unregister on destroy.
## Note: pass all coordinate positions in global space.

const SNAP_RADIUS := 0.03

## Every registered [SnapPoint], stored as a "set".
## I say "set" because GDScript doesn't have a native
## set implementation, so I instead use a dictionary
## where only the keys are significant. Better performance
## and O(1) removal and lookup.
var _snap_points: Dictionary = {}


## Add a [SnapPoint] to the registry
func register(sp: SnapPoint) -> void:
	if sp == null:
		return
	_snap_points[sp] = true


## Remove a [SnapPoint] from the registry
func unregister(sp: SnapPoint) -> void:
	_snap_points.erase(sp)


## Return the nearest registered terminal to [param global_pos] within [constant SNAP_RADIUS],
## or null if none qualify.
func nearest(global_pos: Vector3, exclude: Array = []) -> SnapPoint:
	var best: SnapPoint = null
	var best_dist := SNAP_RADIUS
	for sp: SnapPoint in _snap_points:
		if sp in exclude:
			continue
		var d := sp.global_position.distance_to(global_pos)
		if d <= best_dist:
			best_dist = d
			best = sp
	return best
