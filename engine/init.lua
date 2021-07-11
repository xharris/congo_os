-- engine 2021, MIT License
-- engine for game dev

local pkg = (...):match("(.-)[^%.]+$").."engine."
class = require(pkg.."clasp")
json = require(pkg.."json")
require(pkg.."print_r")
require(pkg.."util")

local engine = {}
local systems = {}
local entities = {}

engine.System = class{
  count = 0,

  init = function(self, components)
    engine.System.count = engine.System.count + 1 
    self.id = engine.System.count

    self.callbacks = {}
    self.entities = {}
    self.components = components or {}
    self.z = 0
    table.insert(systems, self)

    for _, ent in ipairs(entities) do 
      self:_check(ent)
    end
  end,

  add = function(self, callback)
    self.callbacks.add = callback 
    return self 
  end,

  remove = function(self, callback)
    self.callbacks.remove = callback 
    return self 
  end,

  update = function(self, callback)
    self.callbacks.update = callback
    return self
  end,

  updateAll = function(self, callback)
    self.callbacks.updateAll = callback
    return self
  end,

  draw = function(self, callback)
    self.callbacks.draw = callback
    return self
  end,

  order = function(self, z)
    self.z = z 
    return self
  end,

  _update = function(self, dt)
    if self.callbacks.update then 
      for _, ent in ipairs(self.entities) do 
        self.callbacks.update(ent, dt)
      end
    end
    if self.callbacks.updateAll then 
      self.callbacks.updateAll(self.entities, dt)
    end
  end,

  _draw = function(self, ent)
    if self.callbacks.draw then 
      self.callbacks.draw(ent)
    end
  end,

  _add = function(self, ent)
    if self.callbacks.add then 
      self.callbacks.add(ent)
    end 
  end,

  _remove = function(self, ent)
    if self.callbacks.add then 
      self.callbacks.remove(ent)
    end 
  end,

  _has = function(self, entity)
    for _, ent in ipairs(self.entities) do 
      if ent.id == entity.id then 
        return true 
      end 
    end
    return false 
  end,

  _compatible = function(self, component_list)
    for _, v in ipairs(self.components) do 
      if component_list[v] == nil then 
        return false 
      end
    end
    return true
  end,

  _check = function(self, entity)
    local belongs = self:_compatible(entity) 
    local here = self:_has(entity)
    -- add it 
    if belongs and not here then 
      table.insert(self.entities, entity)
      entity:_addRenderSystem(self)
      self:_add(entity)
    end
    -- remove it 
    if not belongs and here then 
      self:_remove(entity)
      table.iterate(self.entities, function(ent)
        return ent.id == entity.id
      end)
      entity:_removeRenderSystem(self)
    end 
  end,

  _checkAll = function(entity)
    for _, sys in ipairs(systems) do 
      sys:_check(entity)
    end
  end
}

engine.Entity = class{
  count = 0,
  root = nil,

  init = function(self, components)
    engine.Entity.count = engine.Entity.count + 1 
    self.id = engine.Entity.count

    self._renderers = {}
    self._local = love.math.newTransform()
    self._world = love.math.newTransform()
    self._sort_children = false 
    self.children = {}
    self.transform = { x=0, y=0, ox=0, oy=0, r=0, sx=1, sy=1, kx=0, ky=0 }
    self.z = 0
    for k, v in pairs(components or {}) do 
      self[k] = v 
    end
    engine.System._checkAll(self)

    if engine.Entity.root then 
      engine.Entity.root:add(self)
    end
    table.insert(entities, self)
  end,

  _updateTransform = function(self, parent_transform)
    -- update local
    local t = self.transform
    self._local:reset()
      :setTransformation(
        floor(t.x), floor(t.y), t.r, 
        t.sx, t.sy, t.ox, t.oy,
        t.kx, t.ky
      )
    -- update world
    if parent_transform then 
      self._world:reset()
        :apply(parent_transform)
        :apply(self._local)
    else 
      self._world:reset()
        :apply(self._local)
    end 
  end,

  draw = function(self)
    -- transformations
    if self.parent then 
      self:_updateTransform(self.parent._world)
    else 
      self:_updateTransform()
    end 
    -- render in systems 
    love.graphics.push()
    love.graphics.replaceTransform(self._world)
    for _, sys in ipairs(self._renderers) do 
      sys:_draw(self)
    end
    -- render children 
    if self._sort_children then 
      table.keySort(self.children, 'z', 0)
      self._sort_children = false 
    end 
    for _, child in ipairs(self.children) do
      child:draw()
    end
    love.graphics.pop()
  end,

  add = function(self, child)
    if self.id == child.id then return end 
    if child.parent and child.parent.id == self.id then return end
    if child.parent then 
      child.parent:remove(child)
    end
    child.parent = self
    table.insert(self.children, child)
  end,

  remove = function(self, child)
    if self.id == child.id then return end 

    child.parent = nil
    table.iterate(self.children, function(c)
      return c.id == child.id
    end)
  end,

  _addRenderSystem = function(self, system)
    table.insert(self._renderers, system)
    table.keySort(self._renderers, 'z', 0)
  end,

  _removeRenderSystem = function(self, system)
    table.iterate(self._renderers, function(sys)
      return sys.id == system.id
    end)
  end
}

engine.Asset = function(category, file)
  return "assets/"..category.."/"..file
end

love.load = function()
  engine.Entity.root = engine.Entity()

  if engine.load then 
    engine.load()
  end
end

love.update = function(dt)
  for _, sys in ipairs(systems) do 
    sys:_update(dt)
  end
end

love.draw = function()
  engine.Entity.root:draw()
end

return engine