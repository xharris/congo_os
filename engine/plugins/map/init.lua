local M = {}

local r = get_require(...)
local shash = r("shash")

engine.Component("map", { tile_layer = {}, layers = {}, shash=false })
engine.Component "map_tile_layer" 

local getSpritebatch = function(ent, layer, image)
  local map = ent.map
  layer = layer or "_"
  if not map.layers[layer] then 
    map.layers[layer] = {}
  end
  if not map.layers[layer][image] then 
    map.layers[layer][image] = engine.Entity{ map_tile_layer={ image=image } }
    ent:add(map.layers[layer][image])
  end
  return map.layers[layer][image].map_tile_layer._spritebatch, layer
end


M.new = function()
  return engine.Entity{
    map = { 
      shash = shash.new()
    }
  }
end

M.addTile = function(ent, image, x, y, tx, ty, tw, th, _layer)
  local map = ent.map
  local sb, layer = getSpritebatch(ent, _layer, image)
  map.shash:add({
    id = sb:add(engine.Asset.quad(image, tx, ty, tw, th), x, y),
    image = image, 
    layer = layer
  }, x, y, tw, th)    
end

M.removeTile = function(ent, x, y, w, h, layer, image)
  local map = ent.map
  w = w or 1
  h = h or 1
  map.shash:each(x, y, w, h, function(obj)
    if (not image or obj.image == image) and (not layer or obj.layer == layer) then 
      map.shash:remove(obj)
      local sb = getSpritebatch(ent, obj.layer, obj.image)
      sb:set(obj.id, 0, 0, 0, 0, 0)
    end
  end)
end

M.addEntity = function(ent, added)
  ent:add(added)
end

engine.System("map_tile_layer")
  :add(function(ent)
    ent.map_tile_layer._spritebatch = love.graphics.newSpriteBatch(engine.Asset.image(ent.map_tile_layer.image))
  end)
  :draw(function(ent)
    love.graphics.draw(ent.map_tile_layer._spritebatch) 
  end)

M.Tiled = r "tiled"

return M