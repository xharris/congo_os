local image = {
  _VERSION        = 'xhh-image v1',
  _URL            = '',
  _DESCRIPTION    = [[
    Component "image"
    {
      name (string) engine.Asset.image
      speed (number) seconds per frame
      frame (number) current frame
      frames (number) total frames
    }

    newAnimation(
      name string, 
      opts {
        frames (number)
        cols (number)
        rows (number)
      }
    )
  ]]
}

engine.Component("image", { speed=1, frame=1, frames=1, _t=0 })

local get_image = memoize(function(path)
  return love.graphics.newImage(
    engine.Asset("image", path)
  )
end)

local get_quads = memoize(function(anim_name, texture)
  if not image.animations[anim_name] then return end

  local anim = image.animations[anim_name]
  local frames = anim.frames
  local fw, fh = texture:getWidth() / anim.cols, texture:getHeight() / anim.rows

  local quads = {}
  local get_frame = function(f)
    local x, y = math.to2D(f, anim.cols)
    table.insert(quads, love.graphics.newQuad((x-1)*fw, (y-1)*fh, fw, fh, texture))
  end

  for _, frame in ipairs(frames) do 
    if type(frame) == "number" then 
      get_frame(frame)
    elseif type(frame) == "string" then 
      local range = frame:split('-')
      for f = range[1], range[2] do 
        get_frame(f)
      end
    end
  end

  return quads
end)

local update_entity = function(ent)
  ent.image._image = get_image(ent.image.name)
  if ent.image.animation then 
    ent.image._anim = image.animations[ent.image.animation]
    ent.image._quads = get_quads(ent.image.animation, ent.image._image)
    ent.image.frames = #ent.image._quads
  end
end

image.animations = {}

image.newAnimation = function(opts)
  assert(opts.name, "newAnimation requires 'name'")
  image.animations[opts.name] = opts
end

image.getInfo = function(path)
  local img = get_image(path)
  return {
    width = img:getWidth(),
    height = img:getHeight()
  }
end

local mon = monitor()
engine.System("image")
  :add(function(ent)
    update_entity(ent)
    mon:track(ent.image, "name")
  end)
  :update(function(ent, dt)
    local img = ent.image
    if mon:changed(img, "name", true) or mon:changed(img, "animation", true) then 
      update_entity(ent)
    end
    -- update animation
    if img._quads then 
      img._t = img._t + dt 
      if img.speed ~= 0 and img._t > img.speed then 
        img._t = 0
        if img.speed < 0 then
          -- backwards animation
          img.frame = img.frame - 1
        else
          img.frame = img.frame + 1
        end
      end
      -- loop
      if img.frame < 1 then 
        img.frame = #img.frames
      elseif img.frame > img.frames then 
        img.frame = 1
      end
      img._quad = img._quads[img.frame]
    end
  end)
  :draw(function(ent)
    love.graphics.draw(ent.image._image, ent.image._quad)
  end)

return image 