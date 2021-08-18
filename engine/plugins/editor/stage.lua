local input = engine.Plugin "input"
local color = engine.Plugin "color"

engine.Component("Grid", {})

local camera = {x=0, y=0}
local snap = {x=32, y=32}
local btn3_down = false 
local grid_redraw = function(ent)
  local grid = ent.Grid 
  grid._canvas:renderTo(function()
    engine.Game.clear(0,0,0,0)
    love.graphics.setColor(color('grey', "300", 0.5))
    local linex, liney = 0, 0
    -- v lines
    for x = 0, engine.Game.width do 
      linex = x * snap.x 
      love.graphics.line(linex, 0, linex, engine.Game.height)
    end
    -- h lines
    for y = 0, engine.Game.width do 
      liney = y * snap.y 
      love.graphics.line(0, liney, engine.Game.width, liney)
    end
    -- origin
    love.graphics.setColor(color('grey', "300", 1))
    love.graphics.line(0,0,engine.Game.width,0)
    love.graphics.line(0,0,0,engine.Game.height)
  end)
end

engine.System("Grid")
  :add(function(ent) 
    local grid = ent.Grid 
    grid._canvas = love.graphics.newCanvas()
    grid_redraw(ent)
  end)
  :update(function(ent, dt)
    
  end)
  :draw(function(ent)
    love.graphics.draw(ent.Grid._canvas)
  end)

engine.Signal.on('load', function()
  local grid = engine.Entity{ Grid={ }, Snap={ } }
  grid.z = -1000
end)

engine.Signal.on('mousepressed', function(x, y, btn)
  if btn == 3 then 
    btn3_down = true
  end
end)

engine.Signal.on('mousereleased', function(x, y, btn)
  if btn == 3 then 
    btn3_down = false
  end
end)