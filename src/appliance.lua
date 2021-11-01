local M = {}

local Image = engine.Plugin "image"

Image.newAnimation{name="appliance", frames={'1-2'}, cols=2, rows=1 }

M.new = function(opt)
  local img = Image.getInfo(opt.name..".png")
  return engine.Entity{
    name = opt.name,
    transform = { x=opt.x, y=opt.y, ox=img.width/4, oy=img.height/2 },
    image = { name=opt.name..".png", animation="appliance", speed=0 }
  }
end

return M