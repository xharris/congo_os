color = engine.Plugin "color"
engine.Plugin "effects"

-- engine.Debug.transform = true


engine.load = function()
  local Person = require "src.person"
  local Level = require "src.level"
  local NavMesh = require "src.navmesh"
  local Pathfinding = require "src.pathfinding"

  engine.Game.background_color = {color("gray", "900")}

  local level = Level.load("tutorial")
  level.person[1]:add("path_follow", { map=level.path, target=level.appliance[1].transform })
end