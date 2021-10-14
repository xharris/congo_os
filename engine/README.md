# engine

## TODOS

**engine general**

- [ ] tilemap loading
- [ ] audio
- [ ] pathfinding through graph (undirected & directed)
- [ ] view culling

**Frequently used components**

## Image

```
Image.newAnimation{ name="appliance", frames={'1-2'}, cols=2, rows=1}
image = { name='asset.png', animation='anime' }
```

## Color

```
color('red', '200')
```

**Cheatsheet**

```lua

-- OOP

local MyClass = class {
  static_var = 'wow',

  init = function(self, arg1, arg2)
    self.property = "value"
  end,
  method = function(self, arg1) end,
  _privateMethod = function(self) end, -- not actually private but close enough
  __ = {
    newindex = function(t, k, v) end,
    tostring = function(t) end,
    -- metamethods...
  }
}

local MyStaticClass = callable {
  __call = function(t, arg1, arg2) end,
  __ = {
    -- metamethods...
  }
}

-- ecs

engine.System("component1", "component1")
  :order(2)
  :add(function(ent) ... end)
  :update(function(ent, dt) ... end)
  :draw(function(ent) ... end)
  :remove(function(ent) ... end)

engine.Component("Jump", { height=20 })
engine.Component("Run", { max_speed=10 })
engine.Component("Shoot", { bullets=10, rate=0.3 })

local bobby = engine.Entity{
  Jump = { height=30 },
  Run = { } -- will be max_speed=10
}

engine.Component("ExtraInfo")
bob:add("ExtraInfo")
bob:add("Shoot", { bullets=1 })


---- built-in components

transform { x, y, ox, oy, r, sx, sy, kx, ky }
size { w, h }
view { entity, x, y, r, sx, sy, kx, ky }


-- scene graph

local gun = engine.Entity{}
bobby:add(gun)

-- effects

require "plugins.effects"
bobby.effect = engine.Effect("boxblur")

-- assets

local img_path = engine.Asset("image", "bobby.png")

-- view (an entity)

engine.View("bobbyvision", {
  transform = {
    ox = engine.Game.width/4, oy = engine.Game.height/4,
    x = engine.Game.width/2, y = engine.Game.height/2
  },
  view = {
    entity = bobby,
    r = math.rad(45)
  }
})

-- plugin

local plugin_require = get_require(...) -- a require for this plugin's local path

local MyPlugin = {}
MyPlugin.doSometing = function() end

return MyPlugin

-- included modules

json
moonshine
print_r

```
