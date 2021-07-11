table.hasValue = function(t, value)
  for i, v in ipairs(t) do
    if v == value then return true end 
  end
  return false 
end

table.keys = function(t)
  local keys = {}
  for k,v in pairs(t) do
    table.insert(keys, k)
  end
  return keys 
end

table.iterate = function(t, fn)
  local len = #t
  local offset = 0
  local removals = {}
  for o=1,len do
    local obj = t[o]
    if obj then
      -- return true to remove element
      if fn(obj, o) == true then
        table.insert(removals, o)
      end
    else 
      table.insert(removals, o)
    end 
  end
  if #removals > 0 then
    for i = #removals, 1, -1 do
      table.remove(t, removals[i])
    end
  end
end

table.find = function(t, value)
  for i, v in ipairs(t) do 
    if v == value then return i end 
  end 
  return 0
end

table.keySort = function(t, key, default)
  if #t == 0 then return end
  table.sort(t, function(a, b)
    if a == nil and b == nil then
        return false
    end
    if a == nil then
        return true
    end
    if b == nil then
        return false
    end
    if a[key] == nil then a[key] = default end
    if b[key] == nil then b[key] = default end
    return a[key] < b[key]
  end)
end

callable = function(t)
  if t.__ then
      for _, mm in ipairs(t) do t['__'..mm] = t.__[mm] end
  end
  return setmetatable(t, { __call = t.__call })
end

local sin, cos, rad, deg, abs, min, max = math.sin, math.cos, math.rad, math.deg, math.abs, math.min, math.max
floor = function(x) return math.floor(x+0.5) end

memoize = nil
do
  local mem_cache = {}
  setmetatable(mem_cache, {__mode = "kv"})
  memoize = function(f, cache)
      -- default cache or user-given cache?
      cache = cache or mem_cache
      if not cache[f] then 
          cache[f] = {}
      end 
      cache = cache[f]
      return function(...)
          local args = {...}
          local cache_str = '<no-args>'
          local found_args = false
          for i, v in ipairs(args) do
              if v ~= nil then 
                  if not found_args then 
                      found_args = true 
                      cache_str = ''
                  end

                  if i ~= 1 then 
                      cache_str = cache_str .. '~'
                  end 
                  if type(v) == "table" then
                      cache_str = cache_str .. tbl_to_str(v)
                  else
                      cache_str = cache_str .. tostring(v)
                  end
              end
          end 
          -- retrieve cached value?
          local ret = cache[cache_str]
          if not ret then
              -- not cached yet
              ret = { f(unpack(args)) }
              cache[cache_str] = ret 
              -- print('store',cache_str,'as',unpack(ret))
          end
          return unpack(ret)
      end
  end
end 

monitor = class{
  init = function(self)
    self._cache = {}
  end,

  track = function(self, t, ...)
    for s = 1, select("#", ...) do 
      self:reset(t, select(s, ...))
    end
  end,

  changed = function(self, t, k, reset)
    local res = self._cache[t] and self._cache[t][k] ~= t[k]
    if reset then 
      self:reset(t, k)
    end
    return res
  end,  

  reset = function(self, t, k)
    if not self._cache[t] then 
      self._cache[t] = {}
    end
    self._cache[t][k] = t[k]
  end,

  untrack = function(self, t, k)
    if not k then 
      self._cache[t] = nil 
    elseif self._cache[t] then 
      self._cache[t][k] = nil 
    end
  end
}