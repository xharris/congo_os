local eng = engine
color = require "plugins.color"
image = require "plugins.image"

eng.load = function()
  local sun_orbit, sun = Planet(20, 0, 0.01, "orange")
  local earth_orbit, earth = Planet(10, 100, 0.05, "lightblue")
  local moon_orbit, moon = Planet(5, 50, 0, "gray")
  
  sun_orbit.transform.x = love.graphics.getWidth()/2
  sun_orbit.transform.y = love.graphics.getHeight()/2

  sun_orbit:add(earth_orbit)
  earth_orbit:add(moon_orbit)

  image.newAnimation{name="person_stand", frames={1}, rows=1, cols=3}
  image.newAnimation{name="person_walk", frames={2,3}, rows=1, cols=3, speed=10}

  eng.Entity{ image={name="son.png", animation="person_walk"}, morph=true }
end

eng.System{"image", "morph"}
  :update(function(ent, dt)
    if love.mouse.getX() > love.graphics.getWidth()/2 then 
      ent.image.name = "father.png"
    else 
      ent.image.name = "son.png"
    end
  end)

Planet = function(size, distance, rotate, color)
  local planet = eng.Entity{ circle=size, color=color }
  local orbit = eng.Entity{ rotate=rotate }
  orbit.transform.x = distance
  orbit:add(planet)
  return orbit, planet 
end

eng.System{"rotate"}
  :update(function(e, dt)
    e.transform.r = e.transform.r + math.deg(e.rotate) * dt 
  end)

eng.System{"circle", "color"}
  :draw(function(e)
    love.graphics.setColor(color(e.color))
    love.graphics.circle("fill", 0, 0, e.circle)
  end)