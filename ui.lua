--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
-- Lua Library inline imports
function __TS__ObjectAssign(to, ...)
    local sources = {...}
    if to == nil then
        return to
    end
    for ____, source in ipairs(sources) do
        for key in pairs(source) do
            to[key] = source[key]
        end
    end
    return to
end

function __TS__New(target, ...)
    local instance = setmetatable({}, target.prototype)
    instance:____constructor(...)
    return instance
end

function __TS__ArrayJoin(self, separator)
    if separator == nil then
        separator = ","
    end
    local result = ""
    for index, value in ipairs(self) do
        if index > 1 then
            result = tostring(result) .. tostring(separator)
        end
        result = tostring(result) .. tostring(
            tostring(value)
        )
    end
    return result
end

function __TS__TypeOf(value)
    local luaType = type(value)
    if luaType == "table" then
        return "object"
    elseif luaType == "nil" then
        return "undefined"
    else
        return luaType
    end
end

function __TS__ArrayIsArray(value)
    return (type(value) == "table") and ((value[1] ~= nil) or (next(value, nil) == nil))
end

function __TS__ArraySome(arr, callbackfn)
    do
        local i = 0
        while i < #arr do
            if callbackfn(_G, arr[i + 1], i, arr) then
                return true
            end
            i = i + 1
        end
    end
    return false
end

function __TS__ObjectValues(obj)
    local result = {}
    for key in pairs(obj) do
        result[#result + 1] = obj[key]
    end
    return result
end

function __TS__ArrayMap(arr, callbackfn)
    local newArray = {}
    do
        local i = 0
        while i < #arr do
            newArray[i + 1] = callbackfn(_G, arr[i + 1], i, arr)
            i = i + 1
        end
    end
    return newArray
end

function __TS__ArraySlice(list, first, last)
    local len = #list
    local relativeStart = first or 0
    local k
    if relativeStart < 0 then
        k = math.max(len + relativeStart, 0)
    else
        k = math.min(relativeStart, len)
    end
    local relativeEnd = last
    if last == nil then
        relativeEnd = len
    end
    local final
    if relativeEnd < 0 then
        final = math.max(len + relativeEnd, 0)
    else
        final = math.min(relativeEnd, len)
    end
    local out = {}
    local n = 0
    while k < final do
        out[n + 1] = list[k + 1]
        k = k + 1
        n = n + 1
    end
    return out
end

function __TS__ArrayPush(arr, ...)
    local items = {...}
    for ____, item in ipairs(items) do
        arr[#arr + 1] = item
    end
    return #arr
end

function __TS__ObjectKeys(obj)
    local result = {}
    for key in pairs(obj) do
        result[#result + 1] = key
    end
    return result
end

function __TS__ObjectEntries(obj)
    local result = {}
    for key in pairs(obj) do
        result[#result + 1] = {key, obj[key]}
    end
    return result
end

function __TS__ArrayFilter(arr, callbackfn)
    local result = {}
    do
        local i = 0
        while i < #arr do
            if callbackfn(_G, arr[i + 1], i, arr) then
                result[#result + 1] = arr[i + 1]
            end
            i = i + 1
        end
    end
    return result
end

function __TS__Number(value)
    local valueType = type(value)
    if valueType == "number" then
        return value
    elseif valueType == "string" then
        local numberValue = tonumber(value)
        if numberValue then
            return numberValue
        end
        if value == "Infinity" then
            return math.huge
        end
        if value == "-Infinity" then
            return -math.huge
        end
        local stringWithoutSpaces = string.gsub(value, "%s", "")
        if stringWithoutSpaces == "" then
            return 0
        end
        return 0 / 0
    elseif valueType == "boolean" then
        return (value and 1) or 0
    else
        return 0 / 0
    end
end

function __TS__NumberIsFinite(value)
    return (((type(value) == "number") and (value == value)) and (value ~= math.huge)) and (value ~= -math.huge)
end

function __TS__NumberIsNaN(value)
    return value ~= value
end

local ____exports = {}
____exports.stringifyJSON = function(____, data, options)
    if options and (options.language == "lua") then
        options = __TS__ObjectAssign(
            {
                equals = "=",
                array = {"{", "}"},
                key = {
                    number = function(____, k) return ("[" .. k) .. "]" end
                },
                value = {
                    string = function(____, k) return ("\"" .. k) .. "\"" end
                }
            },
            options
        )
    end
    local ____ = options or ({})
    local equals = ____.equals
    if equals == nil then
        equals = ":"
    end
    local array = ____.array
    if array == nil then
        array = {"[", "]"}
    end
    local key = ____.key
    if key == nil then
        key = {}
    end
    local value = ____.value
    if value == nil then
        value = {}
    end
    local array_width = ____.array_width
    if array_width == nil then
        array_width = {}
    end
    local _stringify
    _stringify = function(____, data, depth, from)
        if depth == nil then
            depth = 1
        end
        if from == nil then
            from = ""
        end
        local indent = __TS__ArrayJoin(
            __TS__New(Array, depth):fill("    "),
            ""
        )
        local indent_lessone = __TS__ArrayJoin(
            __TS__New(
                Array,
                math.max(0, depth - 1)
            ):fill("    "),
            ""
        )
        local ____type = __TS__TypeOf(data)
        local inline = not (not array_width[from])
        local newline = (inline and " ") or "\n"
        local function next_from(____, k)
            return ((#from > 0) and ((from .. ".") .. k)) or k
        end
        local ____switch8 = ____type
        if ____switch8 == "object" then
            goto ____switch8_case_0
        elseif ____switch8 == "number" then
            goto ____switch8_case_1
        elseif ____switch8 == "string" then
            goto ____switch8_case_2
        elseif ____switch8 == "boolean" then
            goto ____switch8_case_3
        end
        goto ____switch8_case_default
        ::____switch8_case_0::
        do
            if __TS__ArrayIsArray(data) then
                if #data == 0 then
                    return array[1] .. array[2]
                elseif (not array_width[from]) and __TS__ArraySome(
                    data,
                    function(____, d) return type(d) == "table" end
                ) then
                    local arr = __TS__ArrayMap(
                        __TS__ObjectValues(data),
                        function(____, v, i) return (((__TS__ArrayIsArray(data) and (i ~= 0)) and indent) or "") .. _stringify(nil, v, depth + 1, from) end
                    )
                    return (((((array[1] .. "\n") .. indent) .. table.concat(arr, ",\n" or ",")) .. "\n") .. indent_lessone) .. array[2]
                else
                    local arr = __TS__ArrayMap(
                        __TS__ObjectValues(data),
                        function(____, v) return _stringify(
                            nil,
                            v,
                            ((type(v) == "table") and (depth + 1)) or 0,
                            from
                        ) end
                    )
                    local new_arr = {}
                    do
                        local i = 0
                        local j = #arr
                        while i < j do
                            __TS__ArrayPush(
                                new_arr,
                                tostring(indent) .. tostring(
                                    table.concat(
                                        __TS__ArraySlice(arr, i, i + array_width[from]),
                                        "," or ","
                                    )
                                )
                            )
                            i = i + array_width[from]
                        end
                    end
                    return ((((array[1] .. "\n") .. table.concat(new_arr, ",\n" or ",")) .. "\n") .. indent_lessone) .. array[2]
                end
            elseif #__TS__ObjectKeys(data) == 0 then
                return "{}"
            else
                return (((("{" .. newline) .. table.concat(
                    __TS__ArrayMap(
                        __TS__ArrayFilter(
                            __TS__ObjectEntries(data),
                            function(____, ____bindingPattern0)
                                local _ = ____bindingPattern0[1]
                                local v
                                v = ____bindingPattern0[2]
                                return v ~= nil
                            end
                        ),
                        function(____, ____bindingPattern0)
                            local k
                            k = ____bindingPattern0[1]
                            local v
                            v = ____bindingPattern0[2]
                            return ((((((inline and "") or indent) .. ((key[__TS__TypeOf(k)] and key[__TS__TypeOf(k)](key, k)) or k)) .. " ") .. equals) .. " ") .. _stringify(
                                nil,
                                v,
                                depth + 1,
                                next_from(nil, k)
                            )
                        end
                    ),
                    (", " .. newline) or ","
                )) .. newline) .. ((inline and "") or indent_lessone)) .. "}"
            end
        end
        ::____switch8_case_1::
        do
            if not __TS__NumberIsFinite(
                __TS__Number(data)
            ) then
                return "\"Inf\""
            elseif __TS__NumberIsNaN(
                __TS__Number(data)
            ) then
                return "\"NaN\""
            end
            return (value[____type] and value[____type](value, data)) or data
        end
        ::____switch8_case_2::
        do
            return ("\"" .. tostring(
                data:replace(nil, "\\\"")
            )) .. "\""
        end
        ::____switch8_case_3::
        do
            return (data and "true") or "false"
        end
        ::____switch8_case_default::
        do
            return "null"
        end
        ::____switch8_end::
    end
    return _stringify(nil, data)
end
return ____exports
