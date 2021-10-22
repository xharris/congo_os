local M = {}

local color = engine.Plugin "color"

engine.Component("navmesh", { triangles={} })
engine.Component("pathfinder", { navmesh=false, start_id=-1, end_id=-1 })

local sys_navmesh

local ccw = function(A, B, C)
  return (C.y - A.y) * (B.x - A.x) > (B.y - A.y) * (C.x - A.x)
end

local interset = function(A, B, C, D)
  return ccw(A, C, D) ~= ccw(B, C, D) and ccw(A, B, C) ~= ccw(A, B, D)
end

local toPortal = function(nm, e, from, to)
  local edge = nm.edges[e]
  local edge_ids = nm.edges[e].ids
  
  if (edge_ids[1] == from.id and edge_ids[2] == to.id) then
    -- get left and right 
    path_angle = math.angle(from.x, from.y, to.x, to.y)
    pt1_angle = math.angle(from.x, from.y, edge.points[1].x, edge.points[1].y)
    if pt1_angle < path_angle then 
      return true, {
        ids = edge_ids,
        left = { x=edge.points[1].x, y=edge.points[1].y },
        right = { x=edge.points[2].x, y=edge.points[2].y }
      }
    else
      return true, {
        ids = edge_ids,
        left = { x=edge.points[1].x, y=edge.points[1].y },
        right = { x=edge.points[2].x, y=edge.points[2].y }
      }
    end
  end
  return false, {
    ids = edge_ids
  }
end

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
  local edges = {}
  local verts_found = {}
  local match
  for t, tri in ipairs(triangles) do 
    for t2, tri2 in ipairs(triangles) do 
      if tri.id ~= tri2.id then
        -- any edges matching?
        match = 0
        for x1 = 1, 6, 2 do 
          if not verts_found[tri.id] then verts_found[tri.id] = {} end
          for x2 = 1, 6, 2 do 
            if not verts_found[tri.id][tri2.id] then verts_found[tri.id][tri2.id] = {} end
            if tri.points[x1] == tri2.points[x2] and tri.points[x1+1] == tri2.points[x2+1] then 
              table.insert(verts_found[tri.id][tri2.id], { x=tri.points[x1], y=tri.points[x1+1] })
            end
          end
        end

      end
    end
  end
  -- convert matching vertices to neighboring triangles
  for tri, other in pairs(verts_found) do 
    if not graph[tri] then graph[tri] = {} end
    for tri2, pts in pairs(other) do 
      if #pts >= 2 then 
        if not graph[tri2] then graph[tri][tri2] = {} end
        table.insert(edges, {
          ids = { tri, tri2 },
          points = pts
        })
        graph[tri][tri2] = true
      end
    end
  end

  engine.Entity{
    navmesh = { 
      graph=graph,
      edges=edges,
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
    table.insert(path, { 
      id=current, 
      x=id2tri[current].center.x, 
      y=id2tri[current].center.y 
    })
    current = came_from[current]
  end
  table.insert(path, {
    id=start_id, 
    x=id2tri[start_id].center.x, 
    y=id2tri[start_id].center.y
  })
  table.reverse(path)

  -- funnel algorithm
  -- construct 'portals' from edges
  local portals = {}
  do 
    local tri1, tri2, pt, pt_next, edge_ids, edge, last_tri, min_edge_dist, min_edge, edge_dist, from, to, ids
    leftover_edges = {}
    for p = 1, #path - 1 do 
      pt = path[p]
      pt_next = path[p + 1]
      tri1 = path[p].id
      tri2 = path[p + 1].id
      -- get edge connecting triangles
      if tri1 ~= tri2 and nm.graph[tri1][tri2] then 
        for e = 1, #nm.edges do 
          local ok, new_portal = toPortal(nm, e, path[p], path[p + 1])
          if ok then 
            table.insert(portals, new_portal)
          end
        end
      end
    end
    -- make sure closest edge of last triangle is added
    last_tri = path[#path] 
    for e = 1, #nm.edges do 
      edge = nm.edges[e]
      if edge.ids[1] == last_tri.id or edge.ids[2] == last_tri.id then
        edge_dist = math.min(math.dist(edge.points[1].x, edge.points[1].y, x, y), math.dist(edge.points[2].x, edge.points[2].y, x, y))
        if not min_edge_dist or edge_dist < min_edge_dist then 
          min_edge_dist = edge_dist
          min_edge = e
        end
      end
    end
    edge = nm.edges[min_edge]
    if edge then 
      -- get from/to
      ids = nm.edges[min_edge].ids 
      for _, tri in ipairs(nm.triangles) do 
        if not from then 
          from = (tri.id == ids[1] and tri) or (tri.id == ids[2] and tri)
        elseif not to then 
          to = (tri.id == ids[1] and tri) or (tri.id == ids[2] and tri)
        end
      end
      -- add last portal
      local ok, new_portal = toPortal(nm, min_edge, { x=from.center.x, y=from.center.y, id=from.id }, { x=to.center.x, y=to.center.y, id=to.id })
      if ok then 
        table.insert(portals, new_portal)
      end
    end
  end
  -- check if a triangle vertex is closer than the center
  local end_point = {}
  -- start funnelling!
  local new_path = {}
  do 
    local side, left, right, li, ri, funnel_ang
    li, ri = 1, 1
    left = portals[li].left 
    right = portals[ri].right 

        
  end
  nm.portals = portals
  ent.pathfinder.path = path

  return path
end

engine.System('pathfinder')
  :draw(function(ent)
    local points = {}
    for _, node in ipairs(ent.pathfinder.path) do 
      table.insert(points, node.x)
      table.insert(points, node.y)
    end
    love.graphics.origin()
    love.graphics.setColor(color('blue'))
    love.graphics.setLineWidth(2)
    love.graphics.line(unpack(points))
  end)

sys_navmesh = engine.System("navmesh")
  :draw(function(ent)
    local nm = ent.navmesh
    love.graphics.setLineWidth(1)
    love.graphics.setLineJoin("none")
    for t, tri in ipairs(nm.triangles) do 
      love.graphics.setColor(color('red', 0.5))
      love.graphics.polygon('fill', unpack(tri.points))
      love.graphics.setColor(color('black'))
      love.graphics.print(tri.id, tri.center.x, tri.center.y)
    end
    for e, edge in ipairs(nm.edges) do 
      love.graphics.setColor(color('red',0.75))
      love.graphics.line(edge.points[1].x, edge.points[1].y, edge.points[2].x, edge.points[2].y)
    end
    for e, edge in ipairs(nm.portals) do 
      if (e % 2) == 0 then 
        love.graphics.setColor(color('yellow'))
        love.graphics.circle('fill', edge.left.x, edge.left.y, 4)
        love.graphics.line(edge.left.x, edge.left.y, edge.right.x, edge.right.y)
      else 
        love.graphics.setColor(color('green'))
        love.graphics.circle('fill', edge.right.x, edge.right.y, 4)
        love.graphics.line(edge.left.x, edge.left.y, edge.right.x, edge.right.y)
      end
    end
  end)

return M