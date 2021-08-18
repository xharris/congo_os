-- color = engine.Plugin "color"
-- engine.Plugin "effects"
-- input = engine.Plugin "input"
-- map = engine.Plugin "map"
-- log = engine.Log

-- engine.Plugin "editor"

-- -- solarsystem = require "engine.examples.solarsystem"
-- -- viewtest = require "engine.examples.viewtest"

-- local m

-- engine.load = function()
--   -- local s, e, o = solarsystem.load()
--   -- viewtest.load(e)
--   local Family = require "family"

--   local son = Family.spawn{name = "son"}
--   son.label = "wow"
  
--   son.transform.x = engine.Game.width / 2
--   son.transform.y = engine.Game.height / 2

--   engine.Game.background_color = {color("gray", "900")}

--   local my_table = {
--     one = 1,
--     two = { 1, 'two' },
--     three = {
--       one = 1,
--       two = 2,
--       three = 3
--     },
--     four = "four"
--   }

--   m = map()
--   m:addTile("house_inside.png", 100, 100, 0, 0, 100, 100)
-- end

-- engine.System()
--   :updateAll(function()
--     m:removeTile(input.mouse_x, input.mouse_y)
--   end)

-- engine.Component("label", "")
-- engine.System("label")
--   :draw(function(ent)
--     love.graphics.setColor(color('white'))
--     love.graphics.print(ent.label, 0, -20)
--   end)

local canvas 
local snap = {x=32, y=32}

love.load = function()
  width, height = love.graphics.getWidth(), love.graphics.getHeight()
  canvas = love.graphics.newCanvas()

  love.graphics.setCanvas(canvas)
    love.graphics.clear()
    love.graphics.setColor(224/255, 224/255, 224/255, 0.5)
    local linex, liney = 0, 0
    -- v lines
    for x = 0, width do 
      linex = x * snap.x 
      love.graphics.line(linex, 0, linex, height)
    end
    -- h lines
    for y = 0, width do 
      liney = y * snap.y 
      love.graphics.line(0, liney, width, liney)
    end
    -- origin
    love.graphics.setColor(224/255, 224/255, 224/255, 1)
    love.graphics.line(0,0,width,0)
    love.graphics.line(0,0,0,height)
  love.graphics.setCanvas()
end

love.draw = function()
  love.graphics.draw(canvas)
end