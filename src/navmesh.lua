local M = {}

local color = engine.Plugin "color"
local Delaunay = require "src.lib.delaunay" -- remove? turns out love2d comes with triangulation :)
local Point = Delaunay.Point
--[[
Point(point.x, point.y))
Delaunay.triangulate(unpack(points)) 
love.graphics.polygon('fill', tri.p1.x, tri.p1.y, tri.p2.x, tri.p2.y, tri.p3.x, tri.p3.y, tri.p1.x, tri.p1.y)
]]

engine.Component("navmesh", { triangles={} })

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
  local a, b, c, d, e, f
  for t, tri in ipairs(triangles) do 
    ax, ay, bx, by, cx, cy = unpack(tri.points)
    graph[tri.id] = {}
    for t2, tri2 in ipairs(triangles) do 
      dx, dy, ex, ey, fx, fy = unpack(tri2.points)
      -- any edges matching?
      if (ax == dx and ay == dy and bx == ex and by == ey) or 
         (bx == ex and by == ey and cx == fx and cy == fy) or 
         (cx == fx and cy == fy and ax == dx and ay == dy) 
      then 
        graph[tri.id][tri2.id] = true
      end 
    end
  end
  return engine.Entity{
    navmesh = { 
      graph=graph,
      triangles=triangles 
    }
  }
end

engine.System("navmesh")
  :draw(function(ent)
    local nm = ent.navmesh
    love.graphics.setColor(color('red'))
    love.graphics.setLineWidth(2)
    for t, tri in ipairs(nm.triangles) do 
      love.graphics.polygon('line', unpack(tri.points))
      love.graphics.print(tri.id, tri.center.x - 5, tri.center.y - 5)
    end
  end)

return M