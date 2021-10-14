local M = {}

local map = engine.Plugin "map"
local Appliance = require "src.appliance"
local Person = require "src.person"
local NavMesh = require "src.navmesh"

M.load = function(name)
  local level = {
    appliance = {},
    person = {}
  }

  -- load lua map
  local tiled = map.Tiled.load(engine.Asset('map', name))
  local m_tutorial = map()
  for l, layer in ipairs(tiled.layers) do 
    -- add tiles
    if layer.type == "tilelayer" then 
      for t, tile in ipairs(layer.tiles) do 
        m_tutorial:addTile(unpack(tile))
      end
    end
    --
    if layer.type == "objectgroup" then 
      for o, object in ipairs(layer.objects) do 
        local cx, cy = object.x + (object.width / 2), object.y + (object.height / 2)

        if layer.name == "appliance" then 
          local ent = Appliance.new{
            name=object.name, 
            x = cx, 
            y = cy
          }
        
        elseif layer.name == "person" then 
          local ent = Person.new{
            name = object.name,
            x = cx, y = cy
          }
        
        elseif layer.name == "path" then 
          local points = {}
          for p, pt in ipairs(object.polygon) do 
            table.insert(points, { x=object.x + pt.x, y=object.y + pt.y })
          end
          local ent = NavMesh.new{
            points = points
          }
        end
      end
    end
  end
end

return M 