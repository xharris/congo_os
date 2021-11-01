local tiled = {}

local fs = engine.File

tiled.load = function(path)
  data = require(path)
  local map = {}
  map.properties = data.properties
  map.tilesets = data.tilesets
  map.layers = {}
  local tileset
  -- turn chunks into quad lists
  for l, layer in ipairs(data.layers) do 
    map.layers[l] = {
      type = layer.type,
      name = layer.name
    }
    if layer.type == "tilelayer" then 
      local tiles = {}
      for c, chunk in ipairs(layer.chunks) do 
        for i, idx in ipairs(chunk.data) do
          if idx ~= 0 then  
            -- get tileset
            for t, tset in ipairs(data.tilesets) do
              if idx >= tset.firstgid and idx <= tset.tilecount then 
                tileset = data.tilesets[t]
                break 
              end
            end
            -- calc x, y
            local x, y = math.to2D(i, layer.width)
            local tx, ty = math.to2D(idx, tileset.columns)
            table.insert(tiles, {
              -- image 
              fs.basename(tileset.image),
              -- x, y
              ((x-1) * data.tilewidth) + (chunk.x * data.tilewidth), ((y-1) * data.tileheight) + (chunk.y * data.tileheight),
              -- tx, ty
              (tx-1) * tileset.tilewidth, (ty-1) * tileset.tileheight,
              -- tw, th
              tileset.tilewidth, tileset.tileheight,
              -- layer
              layer.name
            })
          end   
        end
      end
      map.layers[l].tiles = tiles
    
    elseif layer.type == "objectgroup" then 
      map.layers[l] = layer
    end
  end

  return map
end

return tiled