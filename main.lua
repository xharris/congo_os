color = engine.Plugin "color"
engine.Plugin "effects"

-- engine.Debug.transform = true

engine.load = function()
  -- local s, e, o = solarsystem.load()
  -- viewtest.load(e)
  local Person = require "src.person"
  local Level = require "src.level"

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

  Level.load("tutorial")
end