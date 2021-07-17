local hex2rgb = memoize(function(hex, a)
  local hex = hex:gsub("#","")
  if hex:len() == 3 then
    return (tonumber("0x"..hex:sub(1,1))*17)/255, (tonumber("0x"..hex:sub(2,2))*17)/255, (tonumber("0x"..hex:sub(3,3))*17)/255
  else
    return tonumber("0x"..hex:sub(1,2))/255, tonumber("0x"..hex:sub(3,4))/255, tonumber("0x"..hex:sub(5,6))/255, a or 1
  end
end)

local color
color = callable{
  library = {},

  __call = function(t, c, shade)
    if c == "gray" then c = "grey" end
    assert(color.library[c], "Color '"..c.."' not found")
    if not shade then 
      local keys = table.keys(color.library[c])
      shade = keys[floor(#keys/2)]
    else 
      shade = tostring(shade)
    end
    assert(color.library[c][shade], "Shade '"..shade.."' of color '"..c.."' not found")
    return hex2rgb(color.library[c][shade])
  end,

  load = function(json_file, append)
    contents, size = love.filesystem.read(json_file)
    if not contents then return end 

    data = json.decode(contents)
    if not append then 
      color.library = {}
    end
    for c, shades in pairs(data) do 
      color.library[c] = {}
      for shade, hex in pairs(shades) do 
        color.library[c][shade] = hex
      end 
    end
  end
}

color.load("plugins/color/material.json")

return color