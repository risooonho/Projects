extends Node

const NodeName = "Game"
const CurrentLevelName = "CurrentLevel"
enum UnitFields {PATH = 0, OWNER = 1}

var m_levelLoader = preload("res://levels/LevelLoader.gd").new()
var m_module
var m_playerUnits = []


signal gameStarted
signal gameEnded


func _init(module, playerUnits):
	assert( module )
	set_name(NodeName)
	m_module = module
	m_playerUnits = playerUnits

func _enter_tree():
	Connector.connectGame( self )
	setPaused(true)
	loadStartingLevel()
	placePlayerUnits(m_playerUnits)
	
func _exit_tree():
	setPaused(false)
	emit_signal("gameEnded")

func delete():
	m_levelLoader.unloadLevel( self.get_node(CurrentLevelName) )
	m_module.free()

func setPaused( enabled ):
	get_tree().set_pause(enabled)

func loadStartingLevel():
	m_levelLoader.loadLevel( m_module.getStartingMap(), self, CurrentLevelName )
	emit_signal("gameStarted")

func placePlayerUnits( units ):
	m_levelLoader.insertPlayerUnits( units, self.get_node(CurrentLevelName) )
