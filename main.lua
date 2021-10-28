color = engine.Plugin "color"
engine.Plugin "effects"

engine.Debug.transform = true


engine.load = function()
  Person = require "src.person"
  Level = require "src.level"
  NavMesh = require "src.navmesh"
  Pathfinding = require "src.pathfinding"
  require "src.movement"

  engine.Game.background_color = {color("gray", "900")}

  local level = Level.load("tutorial")
  
  local vw_main = engine.View()
  vw_main.view.x = level.person[1].transform.x 
  vw_main.view.y = level.person[1].transform.y
end