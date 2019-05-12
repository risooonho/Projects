extends Node

const PlayerAgentGd          = preload("res://core/agent/PlayerAgent.gd")

onready var playerAgent : PlayerAgentGd = $"PlayerAgent"
var _playerUnits__ := SetWrapper.new()         setget deleted, getUnits
onready var _game : Node = get_parent()


func deleted(_a):
	assert(false)


func _ready():
	_playerUnits__.connect( "changed", self, "_onUnitsChanged" )
	_game.connect("currentLevelChanged", self, "_onCurrentLevelChanged" )

	playerAgent.setGame( _game )
	Console._consoleBox.connect( "visibility_changed", self, "_updatePlayerAgentProcessing" )


func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		_freeUnitsNotInTree( _playerUnits__.container() )


func setPlayerUnits( playerUnits : Array ):
	for unit in playerUnits:
		assert( unit is UnitBase )

	var unitsToRemove := []
	for unit in _playerUnits__.container():
		if not unit in playerUnits:
			unitsToRemove.append( unit )

	_freeUnitsNotInTree( unitsToRemove )
	_playerUnits__.reset( playerUnits )


func addPlayerUnits( playerUnits : Array ):
	for unit in playerUnits:
		assert( unit is UnitBase )

	_playerUnits__.add( playerUnits )


func removePlayerUnits( playerUnits : Array ):
	for unit in playerUnits:
		assert( unit is UnitBase )

	_playerUnits__.remove( playerUnits )
	_freeUnitsNotInTree( playerUnits )


func getPlayerUnitNodes():
	var nodes := []
	for playerUnit in _playerUnits__.container():
		assert( playerUnit is UnitBase )
		nodes.append( playerUnit )
	return nodes


func getUnits():
	return _playerUnits__.container()


func unparentUnits():
	for unit in _playerUnits__.container():
		assert( unit is UnitBase )
		unit.get_parent().remove_child( unit )


func _onUnitsChanged( changedUnits : Array ):
	var unitsToRemove := []
	var unitsToAdd    := []

	for unit in playerAgent.getUnits():
		if not unit in changedUnits:
			unitsToRemove.append( unit )

	for unit in changedUnits:
		assert( unit is UnitBase )
		if not unit in playerAgent.getUnits():
			unitsToAdd.append( unit )

	for unit in unitsToRemove:
		playerAgent.removeUnit( unit )

	for unit in unitsToAdd:
		playerAgent.addUnit( unit )
		unit.connect( "predelete", _playerUnits__, "remove", [[unit]] )

	if is_instance_valid( _game.currentLevel ):
		_connectUnitsToLevel( playerAgent.getUnits(), _game.currentLevel )


func _onCurrentLevelChanged( level : LevelBase ):
	if is_instance_valid( level ):
		_connectUnitsToLevel( _playerUnits__.container(), level )


func _connectUnitsToLevel( playerUnits : Array, level : LevelBase ):
	for playerUnit in playerUnits:
		assert( playerUnit is UnitBase )
		if playerUnit.is_connected( "tree_entered", level, "addUnitToFogVision" ):
			continue

		playerUnit.connect( "tree_entered", level, "addUnitToFogVision",      [playerUnit] )
		playerUnit.connect( "tree_exiting", level, "removeUnitFromFogVision", [playerUnit] )

		if playerUnit.is_inside_tree():
			level.addUnitToFogVision( playerUnit )

	for unit in level.getFogVisionUnits():
		if not unit in playerUnits:
			level.removeUnitFromFogVision( unit )
			unit.disconnect( "tree_entered", level, "addUnitToFogVision" )
			unit.disconnect( "tree_exiting", level, "removeUnitFromFogVision" )


func _freeUnitsNotInTree( units : Array ):
	for unit in units:
		if is_instance_valid( unit ) and not unit.is_inside_tree():
			unit.free()


func _updatePlayerAgentProcessing():
	playerAgent.setProcessing( !Console._consoleBox.visible )
