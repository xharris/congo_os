log = engine.Log
color = engine.Plugin "color"
engine.Plugin "effects"

engine.Debug.transform = true

engine.System("name")
  :order(1000)
  :draw(function(ent)
    love.graphics.print(ent.name)
  end)

engine.System("size")
  :order(1000)
  :draw(function(ent)
    love.graphics.setColor(color('green'))
    love.graphics.rectangle('line',2,2,ent.size.w-4,ent.size.h-4)
  end)

engine.load = function()
  Person = require "src.person"
  Level = require "src.level"
  NavMesh = require "src.navmesh"
  Pathfinding = require "src.pathfinding"
  require "src.movement"

  engine.Game.background_color = {color("gray", "900")}

  Level.load("tutorial")
end