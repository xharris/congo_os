color = require "plugins.color"
require "plugins.effects"
input = require "plugins.input"

solarsystem = require "solarsystem"

engine.load = function()
  local s, e, o = solarsystem.load()
  local Family = require "family"

  local son = Family.spawn{name = "son"}
  son.on_mouse = true
  son.rotate = -10

  engine.Game.background_color = {color("gray", 900)}

  engine.View{
    transform = { 
      ox = engine.Game.width/4, oy = engine.Game.height/4,
      x = engine.Game.width/2, y = engine.Game.height/2
    },
    view = { 
      entity = e,
      r = math.rad(45)
    },
    size = { w=engine.Game.width/2, h=engine.Game.height/2 },
    -- on_mouse = true
    rotate = 10
  }
  engine.View("alt", {
    view = {
      entity = e
    },
    size = { w=100, h=100 }
  })
end

engine.System("rotate", "view")
  :update(function(ent, dt)
    if ent.view.r > math.rad(20) then 
      -- print('do it')
      -- ent.view = nil
      -- print('done it')
    end
  end)

engine.System("on_mouse")
  :update(function(ent, dt)
    ent.transform.x, ent.transform.y = engine.View.getWorld(input.mouse_x, input.mouse_y)
  end)