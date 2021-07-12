image = require "plugins.image"
color = require "plugins.color"
require "plugins.effects"

solarsystem = require "solarsystem"

engine.load = function()
  solarsystem.load()

  image.newAnimation{name="person_stand", frames={1}, rows=1, cols=3}
  image.newAnimation{name="person_walk", frames={2,3}, rows=1, cols=3, speed=10}

  local bob = engine.Entity{ 
    image={name="son.png", animation="person_walk"}, 
    morph=true,
    -- transform = { x=love.graphics.getWidth()/2, y=love.graphics.getHeight()/2 }
  }

  love.graphics.setBackgroundColor(color("gray", 900))
end

engine.System("image", "morph")
  :update(function(ent, dt)
    if love.mouse.getX() > love.graphics.getWidth()/2 then 
      ent.image.name = "father.png"
    else 
      ent.image.name = "son.png"
    end
  end)