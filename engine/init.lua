-- engine 2021, MIT License
-- engine for game dev

function get_require(...)
  local root = (...) -- :match("(.-)[^%.]+$")
  return function(p)
    return require(root..'.'..p)
  end
end

local eng_require = get_require(...)
class = eng_require("clasp")
json = eng_require("json")
moonshine = eng_require("moonshine")
eng_require("print_r")
eng_require("util")

local engine = {}
local systems = {}
local entities = {}

engine.System = class{
  count = 0,

  init = function(self, ...)
    engine.System.count = engine.System.count + 1 
    self.id = engine.System.count

    self.callbacks = {}
    self.entities = {}
    self.components = {...}
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

engine.Component = callable{
  templates = {},

  __call = function(t, name, value)
    local templates = engine.Component.templates
    if type(value) == "table" then 
      templates[name] = value
    end
  end,

  use = function(entity, name, value)
    local templates = engine.Component.templates
    entity[name] = value
    if templates[name] then
      if type(entity[name]) == "table" then 
        table.defaults(entity[name], templates[name])
      else 
        entity[name] = copy(templates[name])
      end
    end
  end
}

engine.Entity = class{
  count = 0,
  root = nil,
  _check = {},
  _need_to_check = false,

  init = function(self, components)
    engine.Entity.count = engine.Entity.count + 1 
    self.id = engine.Entity.count

    self._renderers = {}
    self._local = love.math.newTransform()
    self._world = love.math.newTransform()
    self._sort_children = false 
    self.children = {}
    self.z = 0

    components = components or {}
    if not components.transform then 
      components.transform = {}
    end
    for k, v in pairs(components) do 
      engine.Component.use(self, k, v)
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

  _draw = function(self)
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

  draw = function(self)
    if self.effect then 
      self.effect(function()
        self:_draw()
      end)
    else 
      self:_draw()
    end
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
  end,

  __ = {
    newindex = function(t, k, v)
      if k ~= 'id' and (t[k] == nil or v == nil) then 
        engine.Entity._check[t.id] = t
        engine.Entity._need_to_check = true
      end
      if k == 'effect' then 
        if type(v) == "string" then 
          v = {v}
        end
        v = engine.Effect(unpack(v))
      end
      rawset(t,k,v)
    end
  }
}

engine.Asset = function(category, file)
  return "assets/"..category.."/"..file
end

local function passthrough()
  return moonshine.Effect{
    name = 'Passthrough',
    draw = function(buffer)
      front, back = buffer()
      love.graphics.setCanvas(front)
      love.graphics.clear()
      love.graphics.draw(back)
    end
  }
end

engine.Effect = callable{
  __call = function(t, ...)
    local effect = moonshine--(passthrough)
    for n = 1, select('#', ...) do 
      effect = effect.chain(moonshine.effects[select(n, ...)])
    end
    return effect
  end,
  
  new = function(opts)
    if opts.pixel or opts.code or opts.vertex then 
      opts.shader = love.graphics.newShader(opts.pixel or opts.code, opts.vertex)
    end
    if not opts.setters and opts.defaults then 
      opts.setters = {}
      for k, v in pairs(opts.defaults) do 
        opts.setters[k] = function(v)
          opts.shader:send(k, v)
        end
      end
    end 
    moonshine.effects[opts.name] = moonshine.Effect(opts)
  end
}

engine.Component("transform", { x=0, y=0, ox=0, oy=0, r=0, sx=1, sy=1, kx=0, ky=0 })

love.load = function()
  engine._canvas = love.graphics.newCanvas()
  engine.Entity.root = engine.Entity()
  love.graphics.setDefaultFilter("nearest", "nearest", 1)

  if engine.load then 
    engine.load()
  end
end

love.update = function(dt)
  -- check entities that may need to be moved around the systems
  if engine.Entity._need_to_check then 
    for id, ent in pairs(engine.Entity._check) do 
      engine.System._checkAll(ent)
    end
    engine.Entity._check = {}
    engine.Entity._need_to_check = false 
  end
  -- update all systems
  for _, sys in ipairs(systems) do 
    sys:_update(dt)
  end
end

love.draw = function()
  -- engine._canvas:renderTo(function()
  --   love.graphics.clear()
    engine.Entity.root:draw()
  -- end)

  love.graphics.draw(engine._canvas)
end

return engine