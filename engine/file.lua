local file = {}


file.load = function(path)
  ok, chunk = pcall(love.filesystem.load, path)
  if not ok then 
    return ok, chunk
  else 
    ok, result = pcall(chunk)
    if not ok then 
      return ok, result
    else
      return result
    end
  end
end

file.loadJson = function(path)
  ok, result = file.load(path)
  if not ok then 
    return ok, chunk 
  else 
    return json.decode(result)
  end
end

file.basename = function(path)
  return string.gsub(path, "(.*[/\\])(.*)", "%2")
end

return file