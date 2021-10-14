local image = engine.Plugin "image"

local Person = {}

image.newAnimation{name="person_stand", frames={1}, rows=1, cols=3}
image.newAnimation{name="person_walk", frames={2,3}, rows=1, cols=3, speed=10}

Person.new = function(opt)
  return engine.Entity{
    transform = { x=opt.x, y=opt.y, ox=21/2, oy=34 },
    image = {name = opt.name..".png", animation = "person_stand"}
  }
end

return Person