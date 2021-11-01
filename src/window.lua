local M = {}

engine.Component("window", { title="window" })

M.new = function(opts)
  return engine.Entity{
    window = {}
  }
end

return M 