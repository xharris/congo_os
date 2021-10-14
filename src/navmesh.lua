local M = {}

local color = engine.Plugin "color"
local Delaunay = require "src.lib.delaunay" -- remove? turns out love2d comes with triangulation :)
local Point = Delaunay.Point
--[[
Point(point.x, point.y))
Delaunay.triangulate(unpack(points)) 
love.graphics.polygon('fill', tri.p1.x, tri.p1.y, tri.p2.x, tri.p2.y, tri.p3.x, tri.p3.y, tri.p1.x, tri.p1.y)
]]
-- require "src.lib.a-star"
local astar = require "src.lib.astar"

engine.Component("navmesh", { triangles={} })
engine.Component("pathfinder", { navmesh=false, start_id=-1, end_id=-1 })

local sys_navmesh

M.new = function(opts)
  local points = {}
  for p, point in ipairs(opts.points) do 
    table.insert(points, point.x)
    table.insert(points, point.y) 
  end
  local triangles = {}
  local triangulation = love.math.triangulate(points)
  -- change from list to { points={} }
  for t, tri in ipairs(triangulation) do
    table.insert(triangles, {
      id = t,
      center = { x=(tri[1] + tri[3] + tri[5]) / 3, y=(tri[2] + tri[4] + tri[6]) / 3 },
      points = tri
    })
  end
  -- gather more info about the triangles (connections)
  local graph = {}
  local match
  for t, tri in ipairs(triangles) do 
    graph[tri.id] = {}
    for t2, tri2 in ipairs(triangles) do 
      if tri.id ~= tri2.id then
        -- any edges matching?
        match = 0
        for x1 = 1, 6, 2 do 
          for x2 = 1, 6, 2 do 
            if tri.points[x1] == tri2.points[x2] and tri.points[x1+1] == tri2.points[x2+1] then 
              match = match + 1 
            end
            if match >= 2 then 
              graph[tri.id][tri2.id] = true
            end
          end
        end
      end
    end
  end
  engine.Entity{
    navmesh = { 
      graph=graph,
      triangles=triangles
    }
  }
  return ent
end

M.moveTo = function(ent, x, y)
  engine.Component.use(ent, "pathfinder")
  local tform = ent.transform
  -- find closest starting triangle and closest ending triangle
  local nm
  local start_dist, end_dist
  local start_id, end_id
  for _, ent in ipairs(sys_navmesh.entities) do 
    for _, tri in ipairs(ent.navmesh.triangles) do
      if not start_dist or math.dist(tri.center.x, tri.center.y, tform.x, tform.y) < start_dist then 
        start_id = tri.id
        start_dist = math.dist(tri.center.x, tri.center.y, tform.x, tform.y)
        nm = ent.navmesh
      end
      if not end_dist or math.dist(tri.center.x, tri.center.y, x, y) < end_dist then 
        end_id = tri.id 
        end_dist = math.dist(tri.center.x, tri.center.y, x, y)
        nm = ent.navmesh
      end
    end
  end
  -- calculate shortest path (A*)
  local id2tri = {}
  local triangles = {}
  for _, tri in ipairs(nm.triangles) do 
    id2tri[tri.id] = tri
    table.insert(triangles, { id=tri.id, x=tri.center.x, y=tri.center.y })
  end
  local start_tri = id2tri[start_id]
  local end_tri = id2tri[end_id]
  start_tri = { id=start_tri.id, x=start_tri.center.x, y=start_tri.center.y }
  end_tri = { id=end_tri.id, x=end_tri.center.x, y=end_tri.center.y }

  local h = function(from)
    local tri = id2tri[from].center
    return math.dist(tri.x, tri.y, end_tri.x, end_tri.y)
  end 
  local f = function(from, to)
    if to == start_id then return 0 end 
    local tri = id2tri[to].center
    local node = id2tri[from].center
    local g = math.dist(tri.x, tri.y, node.x, node.y)
    local _h = h(to)
    return g + _h, g, _h
  end
  local open = { [start_id]=0 }
  local num_open = 1
  local came_from = {}
  local cost_so_far = {}
  came_from[start_id] = true 
  cost_so_far[start_id] = 0 

  while num_open > 0 do 
    -- get lowest cost open node
    local current
    for id, cost in pairs(open) do 
      if not current or cost < open[current] then 
        current = id 
      end
    end
    open[current] = nil
    num_open = num_open - 1
    -- done?
    if current == end_id then 
      break
    end
    -- check neighbors for next step
    local new_cost, priority
    for next, _ in pairs(nm.graph[current]) do
      new_cost = cost_so_far[current] + f(current, next)
      if not cost_so_far[next] or new_cost < cost_so_far[next] then 
        cost_so_far[next] = new_cost
        if not open[next] then 
          num_open = num_open + 1
        end
        open[next] = new_cost + h(next)
        came_from[next] = current
      end
    end
  end

  -- construct path (backwards) 
  local path = {}
  local current = end_id
  while current ~= start_id do
    table.insert(path, { id=current, x=id2tri[current].center.x, y=id2tri[current].center.y })
    current = came_from[current]
  end
  table.insert(path, {
    id=start_id, 
    x=id2tri[start_id].center.x, 
    y=id2tri[start_id].center.y
  })
  table.reverse(path)

  return path
end

sys_navmesh = engine.System("navmesh")
  :update(function(ent)
    
  end)
  :draw(function(ent)
    local nm = ent.navmesh
    love.graphics.setColor(color('red'))
    love.graphics.setLineWidth(1)
    love.graphics.setLineJoin("none")
    for t, tri in ipairs(nm.triangles) do 
      love.graphics.polygon('line', unpack(tri.points))
      love.graphics.print(tri.id, tri.center.x - 8, tri.center.y - 8)
    end
  end)

return M