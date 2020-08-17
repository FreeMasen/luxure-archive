Headers = {}

Headers.__index = Headers

local function _append(t, key, value)
    if t[key] ~= nil then
        t[key] = {value}
    else
        table.insert(t[key], value)
    end
end

function Headers:append_chunk(text)
    if string.match(text, "^\\s+") ~= nil then
        if self.last_key == nil then
            return "Continuation with no key"
        end
        table.insert(self[self.last_key], text)
    end
    for raw_key, value in string.gmatch(text, "(a-zA-Z\\-): (.+);?") do
        self.last_key = Headers.normalize_key(raw_key)
        self:append(self.last_key, value)
    end
end

--- Constructor for a Headers instance with the provided text
function Headers.from_chunk(text)
    local headers = Headers.new()
    headers:append_from(text)
    return headers
end

--- Bare constructor
function Headers.new(base)
    local ret = base or {
        last_key = nil,
    }
    setmetatable(ret, Headers)
    return ret
end

--- Parse and append the provided text as HTTP headers
---
--- @param text string
function Headers:append_from(text)
    for raw_key, value in string.gmatch(text, "(a-zA-Z\\-): (.+)") do
        local key = Headers.normalize_key(raw_key)
        self:append(key, value)
    end
end

--- Convert a standard header key to the normalized
--- lua identifer ued by this collection
--- @param key string
--- @return string
function Headers.normalize_key(key)
    local lower = string.lower(key)
    local normalized = string.gsub(lower, "-", "_")
    return normalized
end

--- Insert a single key value pair to the collection
function Headers:append(key, value)
    _append(self, key, value)
end

--- Get a header from the map of headers
---
--- This will first normalize the provided key. For example
--- "Content-Type" will be normalized to `content_type`.
--- If more than one value is provided for that header, the
--- last value will be provided
--- @param key string
--- @return string
function Headers:get_one(key)
    local k = Headers.normalize_key(key or "")
    if self[k] == nil then
        return nil
    end
    local values = self[k]

    return values[#values]
end

--- Get a header from the map of headers
---
--- This will first normalize the provided key. For example
--- "Content-Type" will be normalized to `content_type`.
--- If more than one value is provided for that header
--- @param key string
--- @return table a list of the provided values
function Headers:get_all(key)
    local k = Headers.normalize_key(key or "")
    return self[k]
end

return {
    Headers = Headers,
}

if _G.TEST then
    
end
