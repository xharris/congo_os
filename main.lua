color = engine.Plugin "color"
engine.Plugin "effects"

-- engine.Debug.transform = true

engine.load = function()
  -- local s, e, o = solarsystem.load()
  -- viewtest.load(e)
  local Person = require "src.person"
  local Level = require "src.level"
  local NavMesh = require "src.navmesh"

  engine.Game.background_color = {color("gray", "900")}

  local my_table = {
    one = 1,
    two = { 1, 'two' },
    three = {
      one = 1,
      two = 2,
      three = 3
    },
    four = "four"
  }

  local level = Level.load("tutorial")
  local path = NavMesh.moveTo(level.person[1], level.appliance[1].transform.x, level.appliance[1].transform.y)
  print_r(path)
end