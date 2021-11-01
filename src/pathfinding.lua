-- TODO: [132] bbox in getPath() seems bigger than necessary

local M = {}

local color = engine.Plugin "color"
local input = engine.Plugin "input"

local JGrid = require "src.lib.Jumper.jumper.grid"
local JPathfinder = require "src.lib.Jumper.jumper.pathfinder"
local HC = require "src.lib.HC"
local vector = require 'src.lib.HC.vector-light'

local round = math.ceil
local sys_path_map

engine.Component("path_map", { polygon={}, grid_size=8, map={} })
engine.Component("path_follow", { target=false, speed=400, path={ step = 0, step_count = 0, steps = {} } })

local lerp = function(a, b, t) return a * (1 - t) + b * t end 

local checkOpen = function(pmap, x, y)
  return pmap.shape:contains(x * size, y * size)
end

local getPath = function(ent)
  local pfollow = ent.path_follow
  local pmap = pfollow.map.path_map
  assert(pmap, "path_map_ent does not have path_map component")

  -- get start and end positions
  local entx, enty = ent:toWorld(ent.transform.ox, ent.transform.oy)
  local start = { x = entx, y = enty }
  local goal = { x = pfollow.target.x, y = pfollow.target.y }
  local size = pmap.grid_size
  -- construct grid
  local closest_goal = { x=start.x, y=start.y, dist=math.huge }
  local map = pmap.map
  for y = 1, round((pmap.dims.x + pmap.dims.h) / size) do 
    for x = 1, round((pmap.dims.x + pmap.dims.w) / size) do 
      if pmap.map[y][x] == 0 and math.dist(x * size, y * size, goal.x, goal.y) < closest_goal.dist then 
        closest_goal.x = x * size 
        closest_goal.y = y * size
        closest_goal.dist = math.dist(x * size, y * size, goal.x, goal.y)
      end 
    end
  end
  -- get initial path
  local grid = JGrid(map)
  local finder = JPathfinder(grid, 'JPS', 0)
  local jpath = finder:getPath(
    round(start.x/size), 
    round(start.y/size), 
    round(closest_goal.x/size), 
    round(closest_goal.y/size)
  )
  -- smooth out path
  local path = { step = 0, step_count = 1, steps = { { i=1, x=start.x, y=start.y } }, total_dist=0 }
  do 
    local x, y, hits, step, px, py, actual_hits, dx, dy, last_step, dist
    local i = 1
    local root_step = path.steps[1]
    local nodes = {}
    if jpath then 
      for node, count in jpath:nodes() do 
        if i > 1 then 
          table.insert(nodes, { i=i, x=node.x * size, y=node.y * size })
        end
        i = i + 1
      end
      table.insert(nodes, { i=i+1, x=closest_goal.x, y=closest_goal.y })
      for _, step in ipairs(nodes) do 
        -- check if there's a clear path to next node 
        dx, dy = (step.x - root_step.x), (step.y - root_step.y)
        hits = pmap.shape:intersectionsWithRay(root_step.x, root_step.y, dx, dy)
        -- cast ray from this step to next step
        if hits then 
          actual_hits = 0
          -- get ray intersections with walls
          for _, t in ipairs(hits) do
            px, py = vector.add(root_step.x, root_step.y, vector.mul(t, dx, dy))
            if 
              math.sign(dx) ~= math.sign(root_step.x - px) and 
              math.sign(dy) ~= math.sign(root_step.y - py) and 
              math.dist(px, py, root_step.x, root_step.y) <= math.dist(step.x, step.y, root_step.x, root_step.y)
            then 
              actual_hits = actual_hits + 1
            end
          end
          -- hit a wall, not a straight path 
          if actual_hits > 1 then 
            table.insert(path.steps, last_step)
            dist = math.dist(last_step.x, last_step.y, root_step.x, root_step.y)
            path.total_dist = path.total_dist + dist
            path.steps[#path.steps - 1].dist = dist
            root_step = last_step
          end
          -- add last step at the end
          if step.i == i + 1 and path.steps[#path.steps].i ~= i + 1 then 
            table.insert(path.steps, step)
            dist = math.dist(step.x, step.y, root_step.x, root_step.y)
            path.total_dist = path.total_dist + dist
            path.steps[#path.steps - 1].dist = dist
          end
          last_step = step
        end
      end
    end
    path.step_count = #path.steps
  end
  -- measure path lengths
  do
    for s = 1, path.step_count - 1 do 
      path.steps[s].speed_mod = 1 - (path.steps[s].dist / path.total_dist)
    end
  end
  pfollow.path = path
end

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
    pmap.hc = HC.new(pmap.grid_size)
    pmap.shape = pmap.hc:polygon(unpack(points))
    local x, y, w, h = pmap.shape:bbox()
    pmap.dims = { x=x, y=y, w=w, h=h }
    -- generate grid map 
    local map = {}
    local open 
    local size = pmap.grid_size
    for y = 1, round((pmap.dims.x + pmap.dims.h) / size) do 
      if not map[y] then map[y] = {} end 
      for x = 1, round((pmap.dims.x + pmap.dims.w) / size) do 
        -- is open?
        map[y][x] = pmap.shape:contains(x * size, y * size) and 0 or 1
      end
    end
    pmap.map = map
  end)
  :draw(function(ent)
    local pmap = ent.path_map 
    love.graphics.setColor(color('red'))
    love.graphics.setLineJoin('bevel')
    pmap.shape:draw('line')
    -- love.graphics.rectangle('line', pmap.dims.x, pmap.dims.y, pmap.dims.w, pmap.dims.h)
  end)

engine.System("path_follow")
  :update(function(ent, dt)
    local pfollow = ent.path_follow
    local path = pfollow.path
    -- new target set
    if pfollow.target and pfollow.map then 
      getPath(ent)
      pfollow.target = nil 
    end
    -- follow current path
    if path.step_count > 0 then 
      local current_step = path.steps[path.step]
      local next_step = path.steps[path.step + 1]
      -- reached next point?
      if path.step == 0 or path.i >= 100 then
        path.step = path.step + 1
        path.i = 0
      else 
        -- finished?
        if not next_step then 
          path.step = 0 
          path.step_count = 0
          path.steps = {}
        else
          ent.transform.x = lerp(current_step.x, next_step.x, path.i / 100)
          ent.transform.y = lerp(current_step.y, next_step.y, path.i / 100)
          path.i = path.i + (pfollow.speed * current_step.speed_mod) * dt
        end
      end
    end
  end)
  :draw(function(ent)
    local pfollow = ent.path_follow
    local tx,ty = ent:toLocal(0,0)
    love.graphics.translate(-tx, -ty)
    if pfollow.path then 
      -- love.graphics.origin()
      love.graphics.setColor(color('blue'))
      local pts = {}
      for _, step in ipairs(pfollow.path.steps) do 
        love.graphics.print(step.i, step.x, step.y)
        love.graphics.circle('fill', step.x, step.y, 1)
        table.insert(pts, step.x)
        table.insert(pts, step.y)
      end
      
    end
  end)

return M