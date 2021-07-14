color = require "plugins.color"
require "plugins.effects"

solarsystem = require "solarsystem"

engine.load = function()
  solarsystem.load()
  local Family = require "family"

  Family.spawn{name = "son"}

  love.graphics.setBackgroundColor(color("gray", 900))

  engine.View.setCenter(engine.Game.width/2, engine.Game.height/2)

  local v = engine.View()
  v.transform.sx = 0.5 
  v.transform.sy = 0.5

  v.rotate = -0.005
end