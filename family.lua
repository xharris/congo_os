local image = require "plugins.image"

local Family = {}

image.newAnimation{name="person_stand", frames={1}, rows=1, cols=3}
image.newAnimation{name="person_walk", frames={2,3}, rows=1, cols=3, speed=10}

Family = {
  spawn = function(opt)
    return engine.Entity{
      transform = { ox=21/2, oy=34/2 },
      image = {name = opt.name..".png", animation = "person_stand"}
    }
  end
}

return Family