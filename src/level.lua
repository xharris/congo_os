local M = {}

local log = engine.Log

local map = engine.Plugin "map"
local Appliance = require "src.appliance"
local Person = require "src.person"
local NavMesh = require "src.navmesh"
local Pathfinding = require "src.pathfinding"

engine.Component("level", { path=false, view={}, name='' })

M.load = function(name)
  return engine.Entity{
    level = { name=name }
  }
end

local get_child = function(name)
  for _, level in pairs(M._sys.entities) do 
    for _, child in ipairs(level.children) do 
      if child.name == name then 
        return child
      end
    end
  end 
end

M.setCamera = function(name)
  for _, level in pairs(M._sys.entities) do 
    for _, camera in ipairs(level.children) do
      if camera.view then 
        camera.visible = (camera.name == name)
      end
    end
  end
end

M.getAppliance = function(name)
  return get_child(name)
end

M.getPerson = function(name)
  return get_child(name)
end

M._sys = engine.System("level")
  :add(function(ent)
    local level = ent.level
    ent:detach()

    -- load lua map
    local tiled = map.Tiled.load(engine.Asset('map', level.name))
    local m_tutorial = map.new()
    ent:add(m_tutorial)

    for l, layer in ipairs(tiled.layers) do 
      -- add tiles
      if layer.type == "tilelayer" then 
        for t, tile in ipairs(layer.tiles) do 
          map.addTile(m_tutorial, unpack(tile))
        end
      end
      -- add objects
      if layer.type == "objectgroup" then 
        for o, object in ipairs(layer.objects) do 
          local cx, cy = object.x + (object.width / 2), object.y + (object.height / 2)

          if layer.name == "appliance" then 
            ent:add(
              Appliance.new{
                name = object.name, 
                x = cx, 
                y = cy
              }
            )
          
          elseif layer.name == "person" then 
            map.addEntity(
              ent,
              Person.new{
                name = object.name,
                x = cx, y = cy
              }
            )
          
          elseif layer.name == "path" then 
            local points = {}
            assert(object.polygon, "path object is not a polygon")
            for p, pt in ipairs(object.polygon) do 
              table.insert(points, { x=object.x + pt.x, y=object.y + pt.y })
            end
            level.path = engine.Entity()
              :add("path_map", { polygon = points })
            ent:add(level.path)

          elseif layer.name == "camera" then 
            table.insert(level.view,
              engine.View(level.name..'.'..object.name, {
                visible = false,
                view = { root=ent, x=object.x + (object.width/2), y=object.y + (object.height/2) },
                size = { w=object.width, h=object.height },
                name = object.name
              })
            )
          end
        end
      end
    end

    if tiled.properties.camera then 
      M.setCamera(tiled.properties.camera)
    end
  end)

return M 