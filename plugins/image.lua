local get_image = memoize(function(path)
  return love.graphics.newImage(
    engine.Asset("image", path)
  )
end)

local get_quads = memoize(function(anim_name, texture)
  local w, h = texture:getWidth(), texture:getHeight()
  local anim = image.animations[anim_name]
  local frames = anim.frames


end)

local mon = monitor()

engine.System{"image"}
  :add(function(ent)
    ent.image._image = get_image(ent.image.name)
    if ent.image.animation then 
      ent.image._quads = get_quads(ent.image.animation, ent.image._image)
    end
    mon:track(ent.image, "name")
  end)
  :update(function(ent, dt)
    if mon:changed(ent.image, "name", true) then 
      ent.image._image = get_image(ent.image.name)
    end 
  end)
  :draw(function(ent)
    love.graphics.draw(ent.image._image)
  end)

local image = {
  animations = {},
  newAnimation = function(opts)
    image.animations[opts.name] = opts

  end
}

return image 