local M = {}

local color = engine.Plugin "color"

local S = require "src.lib.Strike"
local shash = require "src.lib.shash"
local JGrid = require "src.lib.Jumper.jumper.grid"
local JPathfinder = require "src.lib.Jumper.jumper.pathfinder"

local sys_path_map

engine.Component("path_map", { polygon={}, grid_size=16 })
engine.Component("path_follow", { target=false, path=false })

sys_path_map = engine.System("path_map")
  :add(function(ent)
    local pmap = ent.path_map 
    -- triangulate
    local points = {}
    for _, pt in ipairs(pmap.polygon) do 
      table.insert(points, pt.x)
      table.insert(points, pt.y)
    end
    local triangles = love.math.triangulate(points)
    pmap.shash = shash.new()
    local shape 
    local shapes = {}
    for t, tri in ipairs(triangles) do 
      shape = S.hapes.ConvexPolygon(unpack(tri))
      local l, t, w, h = shape:getBbox()
      pmap.shash:add(shape, l, t, w, h)
      table.insert(shapes, shape)
    end
    pmap.collider = S.trikers.Collider(unpack(shapes))
    local x, y, w, h = pmap.collider:getBbox()
    pmap.dims = { x=x, y=y, w=w, h=h }
  end)
  :draw(function(ent)
    local pmap = ent.path_map 
    love.graphics.setColor(color('red'))
    love.graphics.setLineJoin('bevel')
    local shapes = { pmap.collider:unpack() }
    for _, shape in ipairs(shapes) do 
      local vertices = {}
      if shape.vertices then 
        for _, pt in ipairs(shape.vertices) do 
          table.insert(vertices, pt.x)
          table.insert(vertices, pt.y)
        end
        love.graphics.polygon('line',unpack(vertices))
      end
    end
    love.graphics.rectangle('line', pmap.dims.x, pmap.dims.y, pmap.dims.w, pmap.dims.h)
  end)

local getPath = function(ent)
  local pfollow = ent.path_follow
  local pmap = pfollow.map.path_map
  assert(pmap, "path_map_ent does not have path_map component")

  -- get start and end positions
  local start = { x = ent.transform.x, y = ent.transform.y }
  local goal = { x = pfollow.target.x, y = pfollow.target.y }
  local size = pmap.grid_size

  local checkOpen = function(x, y)
    local walkable = false
    local pt = { x=x, y=y }
    pmap.shash:each(x - size, y - size, x + size, y + size, function(tri)
      if tri:containsPoint(pt) then 
        walkable = true
      end
    end)
    -- return pmap.collider:containsPoint(pt)
    return walkable
  end

  -- construct grid
  local map = {}
  for y = 1, math.ceil((pmap.dims.y + pmap.dims.h) / size) do 
    if not map[y] then map[y] = {} end 
    for x = 1, math.ceil((pmap.dims.x + pmap.dims.w) / size) do 
      map[y][x] = checkOpen(x * size, y * size) and 0 or 1
      if y == start.y / size and x == start.x / size then 
        io.write('s')
      else 
        io.write(map[y][x])
      end
    end
    print()
  end

  local grid = JGrid(map)
  local finder = JPathfinder(grid, 'JPS', 0)
  local jpath = finder:getPath(
    math.ceil(start.x/size), 
    math.ceil(start.y/size), 
    math.ceil(goal.x/size), 
    math.ceil(goal.y/size)
  )
  
  local path = { step = 1, steps = { { x=start.x, y=start.y } } }
  if jpath then 
    for node, count in jpath:nodes() do 
      table.insert(path.steps, {
        x = (node.x * size) - pmap.dims.x, 
        y = (node.y * size) - pmap.dims.y
      })
    end
  end
  pfollow.path = path
end

engine.System("path_follow")
  :update(function(ent)
    local pfollow = ent.path_follow
    -- new target set
    if pfollow.target then 
      getPath(ent)
      pfollow.target = nil 
    end
    -- follow current path
    if pfollow.path then 
      if pfollow.path.step > #pfollow.path.steps then 
        pfollow.path = false
      end
    end
  end)
  :draw(function(ent)
    local pfollow = ent.path_follow
    if pfollow.path then 
      love.graphics.setColor(color('blue'))
      for _, step in ipairs(pfollow.path.steps) do 
        love.graphics.circle('line', step.x, step.y, 4)
      end
    end
  end)

return M