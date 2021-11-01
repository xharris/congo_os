local M = {}

M.push = function(just_transform)
  love.graphics.push(just_transform and nil or 'all')
end

M.pop = function()
  love.graphics.pop()
end

M.init = function()
  for name, fn in pairs(love.graphics) do 
    if not M[name] then 
      M[name] = fn
    end
  end
end

return M 