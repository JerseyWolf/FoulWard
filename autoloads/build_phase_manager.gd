## build_phase_manager.gd
## Headless-safe guard for hex placement during the build phase (Prompt 49).
## Prompt 11: signals for HUD build menu / research panel visibility.

extends Node

## When false, [method HexGrid.place_building] / sell / upgrade return early with a warning.
## GameManager sets this false when combat starts and true in [method GameManager.enter_build_mode].
## Default true matches headless tests that place buildings without toggling mission state.
var is_build_phase: bool = true


func assert_build_phase(context: String) -> bool:
	if is_build_phase:
		return true
	push_warning("BuildPhaseManager: blocked %s — not in build phase" % context)
	return false


func confirm_build_phase() -> void:
	# Reserved for HUD "Begin wave" wiring; gameplay may toggle [member is_build_phase] via GameManager.
	pass


## Toggles [member is_build_phase] and emits the matching signal (no-op if unchanged).
func set_build_phase_active(active: bool) -> void:
	if is_build_phase == active:
		return
	is_build_phase = active
	if active:
		SignalBus.build_phase_started.emit()
	else:
		SignalBus.combat_phase_started.emit()
