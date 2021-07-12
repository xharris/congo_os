local color = require "plugins.color"

local module = {
  load = function()
    local sun_orbit, sun = Planet(20, 0, 0.01, "orange")
    local earth_orbit, earth = Planet(10, 100, 0.05, "lightblue")
    local moon_orbit, moon = Planet(5, 50, 0, "gray")
    
    sun_orbit.transform.x = love.graphics.getWidth()/2
    sun_orbit.transform.y = love.graphics.getHeight()/2
  
    sun_orbit:add(earth_orbit)
    earth_orbit:add(moon_orbit)
  end
}

Planet = function(size, distance, rotate, color)
  local planet = engine.Entity{ circle=size, color=color }
  local orbit = engine.Entity{ rotate=rotate }
  orbit.transform.x = distance
  orbit:add(planet)
  return orbit, planet 
end

engine.System("rotate")
  :update(function(e, dt)
    e.transform.r = e.transform.r + math.deg(e.rotate) * dt 
  end)

engine.System("circle", "color")
  :draw(function(e)
    love.graphics.setColor(color(e.color))
    love.graphics.circle("fill", 0, 0, e.circle)
  end)

return module