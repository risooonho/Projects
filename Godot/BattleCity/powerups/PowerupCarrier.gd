extends Node2D

const PowerupFactoryScn = preload("res://powerups/PowerupFactory.tscn")
const TankGd = preload("res://units/Tank.gd")

export (String, "", "Helmet", "Star", "Tank") var m_powerupName
var m_tank                setget deleted
var m_originalTankColor   setget deleted


func deleted(_a):
	assert(false)


func _ready():
	# parent has to be a tank
	m_tank = get_parent()
	get_node("AnimationPlayer").play("changeTankColor")


func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		var powerupFactory = PowerupFactoryScn.instance()
		var powerup = powerupFactory.makePowerup(m_powerupName) \
			if m_powerupName != "" \
			else powerupFactory.makeRandomPowerup()
		m_tank.m_stage.get_ref().placePowerup( powerup )
		powerupFactory.free()


func setTankOriginalColor():
	if m_tank.m_colorFrame == TankGd.ColorOffset.PURPLE:
		m_tank.setColor( m_originalTankColor )


func setPurpleColor():
	if m_tank.m_colorFrame != TankGd.ColorOffset.PURPLE:
		m_originalTankColor = m_tank.m_colorFrame
		m_tank.setColor( TankGd.ColorOffset.PURPLE )
