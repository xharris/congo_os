local image = engine.Plugin "image"

local Person = {}

engine.Component("script", { step=0, lines={}, line_count=0 })

image.newAnimation{name="person_stand", frames={1}, rows=1, cols=3}
image.newAnimation{name="person_walk", frames={2,3}, rows=1, cols=3, speed=10}

Person.new = function(opt)
  local ok, info = engine.File.loadJson(engine.Asset("people", opt.name..".json"))
  assert(ok, info)

  return engine.Entity{
    transform = { x=opt.x, y=opt.y, ox=21/2, oy=34 },
    image = {name = opt.name..".png", animation = "person_stand"},
    path_follow = { speed=info.speed },
    script = { step = 0, lines = info.script, line_count = #info.script }
  }
end

-- walk animation
engine.System("path_follow", "image")
  :update(function(ent, dt)
    local pfollow, img, tform = ent.path_follow, ent.image, ent.transform
    local path = pfollow.path 

    if path.step_count > 0 then 
      local current_step = path.steps[path.step]
      local next_step = path.steps[path.step + 1]
      if next_step then 
        -- tform. next_step.x < 
      end
    end
  end)

-- TODO: 
-- { "type": "dialogue", "value": "now focus on the clock", "wait": "camera.1" },
-- check notebook

engine.System("script", "path_follow")
  :update(function(ent, dt)
    local script, pfollow = ent.script, ent.path_follow 
    -- local appliance = Level.getAppliance('clock')
    -- local appx, appy = appliance:toWorld(0, 0)
    -- pfollow.map = Level.getMap(ent.name)
    -- pfollow.target = { x = appx, y = appy }
  end)

engine.System("name")
  :draw(function(ent)
    love.graphics.print(0, 0, ent.name)
  end)

return Person