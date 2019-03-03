extends Node2D

const LevelBaseGd            = preload("res://core/level/LevelBase.gd")
const UnitBaseGd             = preload("res://core/UnitBase.gd")


var m_fog : TileMap = null
var m_grayTileId := 0
export var _side := 8   # use an even number
var m_rectOffset = Vector2( _side / 2.0, _side / 2.0 )
var m_nodesToUpdate := []
onready var m_updateTimer = $"UpdateTimer"

# UnitBaseGd to Rect2
var m_unitsToVisionRects := {}


func _ready():
	assert( get_parent() is TileMap )
	m_fog = get_parent()
	m_grayTileId = m_fog.tile_set.find_tile_by_name("grey")

	m_updateTimer.connect("timeout", self, "_updateFog", [m_nodesToUpdate])
	m_updateTimer.one_shot = true


func addUnit( unitNode : UnitBaseGd ):
	if m_unitsToVisionRects.has( unitNode ):
		return

	m_unitsToVisionRects[ unitNode ] = _rectFromNode( unitNode )
	unitNode.connect("changedPosition", self, "onUnitChangedPosition", [unitNode] )
	_updateFog( m_unitsToVisionRects.keys() )


func removeUnit( unitNode : UnitBaseGd ):
	m_unitsToVisionRects.erase( unitNode )
	unitNode.disconnect("changedPosition", self, "onUnitChangedPosition" )
	_updateFog( m_unitsToVisionRects.keys() )


func onUnitChangedPosition( unitNode : UnitBaseGd ):
	if m_nodesToUpdate.has( unitNode ):
		return

	m_nodesToUpdate.append( unitNode )
	if m_nodesToUpdate.size() == 1:
		m_updateTimer.start( m_updateTimer.wait_time )


func _updateFog( unitNodes : Array ):
	for unit in unitNodes:
		_setTileInRect( m_grayTileId, m_unitsToVisionRects[unit] )

	#uncover fog for every unit
	for unit in m_unitsToVisionRects:
		var pos : Vector2 = m_fog.world_to_map( unit.global_position )
		pos -= m_rectOffset
		m_unitsToVisionRects[unit].position = pos
		_setTileInRect( -1, m_unitsToVisionRects[unit] )

	unitNodes.clear()


func _setTileInRect( tileId : int, rect : Rect2 ):
	for x in range( rect.position.x, rect.size.x + rect.position.x):
		for y in range( rect.position.y, rect.size.y + rect.position.y):
			m_fog.set_cell(x, y, tileId)


func _rectFromNode( unitNode : UnitBaseGd ) -> Rect2:
	var rect = Rect2( 0, 0, _side, _side )
	var pos : Vector2 = m_fog.world_to_map( unitNode.global_position )
	pos -= m_rectOffset
	rect.position = pos
	return rect

