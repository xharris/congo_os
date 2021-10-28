local file = {}

file.json = {}

file.json.encode = function(t)
  return json:encode(t)
end

file.json.decode = function(str)
  return json:decode(str)
end

file.load = function(path)
  ok, chunk = pcall(love.filesystem.load, path)
  if not ok then 
    print("here", ok, chunk)
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
  contents, size = love.filesystem.read(path)
  if not contents then 
    return contents, size 
  else 
    return true, file.json.decode(contents)
  end
end

file.basename = function(path)
  return string.gsub(path, "(.*[/\\])(.*)", "%2")
end

return file