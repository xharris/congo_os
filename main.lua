color = require "plugins.color"
require "plugins.effects"
input = require "plugins.input"

-- solarsystem = require "solarsystem"
-- viewtest = require "viewtest"

engine.load = function()
  -- local s, e, o = solarsystem.load()
  -- viewtest.load(e)
  local Family = require "family"

  local son = Family.spawn{name = "son"}

  engine.Game.background_color = {color("gray", 900)}
end
