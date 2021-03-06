local engine = {
  _VERSION        = 'engine v0.8.0',
  _URL            = 'https://github.com/xharris/mechanic6-remake',
  _DESCRIPTION    = 'An engine I\'ll probably use in my games',
  _LICENSE        = [[
    MIT LICENSE

    Copyright (c) 2021 Xavier Harris

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ]]
}

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
local draw = eng_require "draw"

local systems = {}
local entities = {}

engine.Log = eng_require "log"
local log = engine.Log

engine.System = class{
  count = 0,
  _update_tick = true, -- t/f, determines whether an object needs to update its transform

  init = function(self, ...)
    engine.System.count = engine.System.count + 1 
    self.id = engine.System.count

    self.enabled = true
    self.callbacks = {}
    self.entities = {}
    self.components = {...}
    self.z = 0
    table.insert(systems, self)

    for _, comp in ipairs(self.components) do 
      if not engine.Component.exists(comp) then 
        engine.Component(comp)
      end
    end

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

  _updateAll = function(dt)
    engine.System._update_tick = not engine.System._update_tick
    for _, sys in ipairs(systems) do 
      sys:_update(dt)
    end
  end,

  _update = function(self, dt)
    if not self.enabled then return nil end
    if self.callbacks.update then 
      for _, ent in ipairs(self.entities) do 
        ent:_updateTransform()
        self.callbacks.update(ent, dt)
      end
    end
    if self.callbacks.updateAll then 
      self.callbacks.updateAll(self.entities, dt)
    end
  end,

  _draw = function(self, ent)
    if not self.enabled then return nil end
    if self.callbacks.draw then 
      draw.push()
      self.callbacks.draw(ent)
      draw.pop()
    end
  end,

  _add = function(self, ent)
    if not self.enabled then return nil end
    if self.callbacks.add then 
      self.callbacks.add(ent)
    end 
  end,

  _remove = function(self, ent)
    if not self.enabled then return nil end
    if self.callbacks.remove then 
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
    local negated
    for _, v in ipairs(self.components) do 
      negated = v:starts('~')
      if (negated and component_list[v]) or (not negated and component_list[v] == nil) then 
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
  names = {}, -- {name:t/f} used to check if a component exists
  templates = {},

  __call = function(t, name, value)
    engine.Component.templates[name] = value ~= nil and value or {} 
  end,

  exists = function(name) 
    return engine.Component.templates[name] ~= nil 
  end,

  use = function(entity, name, value)
    local templates = engine.Component.templates
    -- assign if it does not exist on entity 
    if entity[name] == nil then
      if value == nil and templates[name] then 
        entity[name] = copy(templates[name])
      else 
        entity[name] = value
      end
    end
    
    -- update with given value
    if value ~= nil then 
      if type(value) == 'table' then 
        table.update(entity[name], value, -1)
      else 
        entity[name] = value
      end
    end

    -- update with template value
    if templates[name] and type(entity[name]) == "table" then 
      table.defaults(entity[name], templates[name])
      
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
    self.is_entity = true
    self._local = love.math.newTransform()
    self._world = love.math.newTransform()
    self._sort_children = false 
    self.children = {}
    self.visible = true
    self.z = 0
    self._update_tick = not engine.System._update_tick

    components = components or {}
    if not components.transform then 
      components.transform = {}
    end
    for k, v in pairs(components) do 
      engine.Component.use(self, k, v)
    end

    if engine.Entity.root and not self._is_root then 
      engine.Entity.root:add(self)
    end

    engine.System._checkAll(self)

    table.insert(entities, self)
  end,

  _load = function()
    engine.Entity.root = engine.Entity{ _is_root=true }
  end,

  _updateTransform = function(self, force, parent_transform)
    if not parent_transform and self.parent then 
      self.parent:_updateTransform(force)
      self:_updateTransform(force, self.parent._world)
      return
    end
    if force or self._update_tick ~= engine.System._update_tick then 
      self._update_tick = engine.System._update_tick
      -- update local
      local t = self.transform
      self._local:reset()
        :setTransformation(
          floor(t.x), floor(t.y), t.r, 
          t.sx, t.sy, floor(t.ox), floor(t.oy),
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
    end
  end,

  _draw = function(self)
    -- transformations
    self:_updateTransform()
    -- render in systems 
    love.graphics.applyTransform(self._local)
    -- color 
    if self.color then 
      love.graphics.setColor(self.color)
    end
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
  end,

  draw = function(self)
    if not self then
      engine.Entity.root:draw()
    else
      if not self.visible then return end 
      draw.push(true)
      if self.effect then 
        self.effect(function()
          self:_draw()
        end)
      else 
        self:_draw()
      end
      draw.pop()
    end
  end,

  add = function(self, ...)
    local _type = type(select(1, ...))

    if _type == "string" then 
      -- component 
      engine.Component.use(self, ...)
      engine.System._checkAll(self)

    elseif _type == "table" then
      local obj = select(1, ...)
      
      if not obj.is_entity then
        -- list of components
        for k, v in pairs(obj) do 
          engine.Component.use(self, k, v)
        end
        engine.System._checkAll(self)

      else
        -- entity 
        local child
        for c = 1, select('#', ...) do 
          child = select(c, ...)

          if self.id == child.id then break end 
          if child.parent and child.parent.id == self.id then break end
          if child.parent then 
            child.parent:remove(child)
          end
          child.parent = self
          table.insert(self.children, child)
        end
      end
    end
    return self
  end,

  remove = function(self, ...)
    local _type = type(select(1, ...))
    if _type == "string" then 
      --component 
      for c = 1, select('#', ...) do 
        self[select(c, ...)] = nil 
      end
      engine.System._checkAll(self)

    else
      -- entity
      local child = select(1, ...)
      if self.id ~= child.id then 
        child.parent = nil
        table.iterate(self.children, function(c)
          return c.id == child.id
        end)
      end
    end
    return self
  end,

  detach = function(self)
    if self.parent then 
      self.parent:remove(self)
    end
    return self
  end,

  destroy = function(self)
    -- remove from parent 
    self:detach()
    -- remove components 
    for k, v in pairs(self) do 
      if engine.Component.exists(k) then
        self[k] = nil 
      end
    end
    engine.System._checkAll(self)
  end,

  merge = function(self, obj)
    for k, v in pairs(obj) do 

    end
  end,

  toWorld = function(self, x, y)
    self:_updateTransform(true)
    return self._world:transformPoint(x, y)
  end,

  toLocal = function(self, x, y)
    self:_updateTransform(true)
    return self._local:transformPoint(x, y)
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

      elseif k == 'effect' then 
        if type(v) == "string" then 
          v = {v}
        end
        v = engine.Effect(unpack(v))
      
      elseif k == 'z' and t.parent and t.z ~= v then 
        t.parent._sort_children = true
      
      elseif engine.Component.exists(k) then 
        engine.Component.use(t, k, v)

      end 
      rawset(t,k,v)
    end,

    tostring = function(t)
      local str = "Entity{id="..t.id
      if t.parent and engine.Entity.root and t.parent.id ~= engine.Entity.root.id then 
        str = str .. ", parent=" .. t.parent.id 
      end
      if t.children and #t.children > 0 then 
        str = str .. ", #children=" .. #t.children
      end
      for k, v in pairs(t) do 
        if engine.Component.exists(k) then 
          str = str .. ", " .. k .. "=" .. tostring(v)
        end 
      end
      return str.."}"
    end
  }
}

-- debug
local sys_debug
sys_debug = engine.System("transform")
  :order(100)
  :draw(function(ent)
    if engine.Debug.transform then 
      draw.push()
      love.graphics.translate(ent.transform.ox, ent.transform.oy)
      love.graphics.setColor(244/255, 67/255, 54/255, 1)
      love.graphics.line(-3,-3,3,3)
      love.graphics.line(-3,3,3,-3)
      draw.pop()
    end
  end)

engine.Asset = callable {
  __call = function(t, category, file)
    return "assets/"..category.."/"..file
  end,

  image = memoize(function(image)
    return love.graphics.newImage(engine.Asset("image", image))
  end),

  quad = memoize(function(image, x, y, w, h)
    return love.graphics.newQuad(x, y, w, h, engine.Asset.image(image))
  end)
}

engine.System("view", "size")
  :add(function(ent)
    local view = ent.view 
    view._transform = love.math.newTransform()
  end)
  :remove(function(ent)
    for name, view in pairs(engine.View.views) do 
      if view.id == ent.id then 
        engine.View.views[name] = nil
      end
    end
  end)
  :update(function(ent, dt)
    local view, t, size = ent.view, ent.transform, ent.size
    if view.entity and view.entity.is_entity then 
      view.x, view.y = view.entity:toWorld(0,0)
    end

    local ox, oy = size.w, size.h
    if view.ox then ox = view.ox end 
    if view.oy then oy = view.oy end 
    local tform = view._transform
    view._transform:reset()
    local w2, h2 = size.w*0.5, size.h*0.5
    tform:scale(view.sx, view.sy)
    tform:translate(w2 / view.sx, h2 / view.sy)
    tform:rotate(-view.r)
    tform:translate(-view.x, -view.y)
  end)
  :draw(function(ent)
    local view, t, size = ent.view, ent.transform, ent.size
    engine.View._canvas:renderTo(function()

      draw.push()
      engine.Game.clear()
      love.graphics.origin()
      love.graphics.applyTransform(view._transform)

      view.root:draw()

      draw.pop()
    end)
    engine.View._quad:setViewport(
      0, 0, size.w, size.h,
      engine.Game.width,engine.Game.height
    )
    love.graphics.draw(engine.View._canvas, engine.View._quad)
  end)

engine.View = callable{
  root = nil,
  _canvas = nil,
  _quad = nil,
  views = {}, -- {name:entity}
  __call = function(t, name, opts)
    name = name or "_"
    if type(name) == "table" then 
      opts = name 
      name = "_"
    end
    local views = engine.View.views
    -- create a new view or update existing
    if not views[name] then 
      opts = opts or {}
      table.defaults(opts, {
        view = { root=engine.Entity.root, x=engine.Game.width/2, y=engine.Game.height/2 },
        size = { w=engine.Game.width, h=engine.Game.height }
      })
      views[name] = engine.Entity(opts)
      engine.View.root:add(views[name])
    elseif opts then 
      views[name]:add(opts)
    end
    return views[name]
  end,
  _load = function()
    engine.View._canvas = love.graphics.newCanvas()
    engine.View._quad = love.graphics.newQuad(
      0,0,
      engine.Game.width,engine.Game.height,
      engine.Game.width,engine.Game.height
    )
    engine.View.root = engine.Entity() -- .root
    engine.View.root:detach()
    engine.View()
  end,
  draw = function()
    engine.View.root:draw()
  end,
  getWorld = function(name, x, y)
    if not y then y, x, name = x, name, nil end 
    local v = engine.View.views[name or '_']
    if v and v.view then  
      return v.view._transform:inverseTransformPoint(v._local:inverseTransformPoint(x, y))
    end
    return x, y
  end,
  -- TODO does this actually work?
  getLocal = function(name, x, y)
    if not y then y, x, name = x, name, nil end 
    local v = engine.View.views[name or '_']
    if v and v.view then  
      return v.view._transform:transformPoint(v._local:transformPoint(x, y))
    end
    return x, y
  end
}

engine.Effect = callable{
  __call = function(t, ...)
    local effect = moonshine
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

engine.Signal = {
  _functions = {},

  on = function(name, fn)
    local t = engine.Signal
    if not t._functions[name] then 
      t._functions[name] = {}
    end
    if not table.hasValue(t._functions[name], fn) then 
      table.insert(t._functions[name], fn)
    end
  end,

  off = function(name, fn)
    table.iterate(engine.Signal._functions, function(fn2)
      return fn == fn2
    end)
  end,

  emit = function(name, ...)
    if not engine.Signal._functions[name] then return end
    local t = engine.Signal._functions[name]
    for i = 1, #t do 
      t[i](...)
    end
  end
}

engine.Plugin = function(name)
  return eng_require("plugins."..name)
end

engine.File = eng_require "file"

engine.Draw = draw

engine.Debug = {
  transform = false
}

engine.Game = callable{
  width = 0,
  height = 0,
  background_color = {0,0,0,1},
  backstage_color = {0,0,0,1},
  padx = 0,
  pady = 0,
  scale = 1,

  _load = function()
    draw.init()
    engine.Game.width = love.graphics.getWidth()
    engine.Game.height = love.graphics.getHeight()

    engine.Component("view", { 
      entity=nil, 
      x=0, y=0,
      r=0, sx=1, sy=1, kx=0, ky=0
    })
    engine.Component("transform", { x=0, y=0, ox=0, oy=0, r=0, sx=1, sy=1, kx=0, ky=0 })
    engine.Component("size", { w=0, h=0 })
    
    engine.Entity._load()
    engine.View._load()
    engine._canvas = love.graphics.newCanvas()
    love.graphics.setDefaultFilter("nearest", "nearest", 1)
  end,

  __ = {
    index = function(t, k)
      if k == "window_width" then 
        return love.graphics.getWidth()
      end 
      if k == "window_height" then 
        return love.graphics.getHeight()
      end
      return rawget(t, k)
    end,
    newindex = function(t, k, v)
      if k == "width" then 
        return love.graphics.setWidth(v)
      end
      if k == "height" then 
        return love.graphics.getHeight(v)
      end
      return rawset(t, k, v)
    end
  },

  clear = function(r, g, b, a)
    if r then 
      love.graphics.clear(r, g, b, a)
    else
      love.graphics.clear(engine.Game.background_color)
    end
  end 
}

love.load = function()
  engine.Game._load()

  if engine.load then 
    engine.load()
    engine.Signal.emit("load")
  end
end

love.update = function(dt)
  -- debug flags 
  sys_debug.enabled = engine.Debug.transform -- or other flags
  -- check entities that may need to be moved around the systems
  if engine.Entity._need_to_check then 
    for id, ent in pairs(engine.Entity._check) do 
      engine.System._checkAll(ent)
    end
    engine.Entity._check = {}
    engine.Entity._need_to_check = false 
  end
  -- update all systems
  engine.System._updateAll(dt)
end

love.draw = function()
  engine._canvas:renderTo(function()
    love.graphics.clear(engine.Game.background_color)
    engine.View.draw()
  end)
  local scale, x, y = 1, 0, 0
  local scalex = engine.Game.window_height / engine.Game.height
  local scaley = engine.Game.window_width / engine.Game.width
  if scalex > scaley then
    scale = scaley 
    y = floor((engine.Game.window_height - (engine.Game.height*scaley))/2)
  else 
    scale = scalex
    x = floor((engine.Game.window_width - (engine.Game.width*scalex))/2)
  end
  engine.Game.padx, engine.Game.pady, engine.Game.scale = x, y, scale 
  love.graphics.translate(x, y)
  love.graphics.scale(scale, scale)
  love.graphics.clear(engine.Game.backstage_color)
  love.graphics.draw(engine._canvas)
end

local love_events = {
  "displayrotated",
  "directorydropped", "filedropped", "mousefocus", "resize", "visible",
  "mousepressed", "mousereleased", "wheelmoved",
  "gamepadaxis", "gamepadpressed", "gamepadreleased", "joystickadded", "joystickaxis", "joystickhat", "joystickpressed", "joystickreleased", "joystickremoved",
  "touchmoved", "touchpressed", "touchreleased"
}
for _, evt in ipairs(love_events) do 
  love[evt] = function(...) engine.Signal.emit(evt, ...) end
end

return engine