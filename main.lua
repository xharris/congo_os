color = require "plugins.color"
require "plugins.effects"
input = require "plugins.input"

solarsystem = require "solarsystem"

engine.load = function()
  solarsystem.load()
  local Family = require "family"

  local son = Family.spawn{name = "son"}
  son.on_mouse = true

  engine.Game.background_color = {color("gray", 900)}

  local v = engine.View{
    transform = { 
      ox = engine.Game.width/4, oy = engine.Game.height/4,
      x = engine.Game.width/2, y = engine.Game.height/2,
      r = math.rad(3)
    },
    view = { 
      -- x=engine.Game.width/2, y=engine.Game.height/2,
      r = math.rad(4)
    },
    size = { w=engine.Game.width/2, h=engine.Game.height/2 },
    rotate = 0.05
  }
end

engine.System("on_mouse")
  :update(function(ent, dt)
    local v = engine.View()
    ent.transform.x, ent.transform.y = engine.View.getWorld(input.mouse_x, input.mouse_y)
  end)