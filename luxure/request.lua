---A map of the key value pairs from the header portion
---of an HTTP request
local Headers = {}

Headers.__index = Headers

local function _append(t, key, value)
    if t[key] == nil then
        t[key] = {value}
    else
        table.insert(t[key], value)
    end
end

local function serialize_header(key, value)
    if type(value) == "table" then
        value = value[#value]
    end
    local lower = string.lower(key)
    local replaced = string.gsub(lower, '-', '_')
    return string.format("%s: %s", replaced, value)
end

function Headers:serialize()
    local ret = ""
    for key, value in pairs(self) do
        ret = ret .. serialize_header(key, value) .. "\r\n"
    end
end

function Headers:append_chunk(text)
    if string.match(text, "^\\s+") ~= nil then
        if self.last_key == nil then
            return "Continuation with no key"
        end
        local ty = type(self[self.last_key])
        if ty == "string" then
            self[self.last_key] = {self[self.last_key], text}
        elseif ty == "table" then
            table.insert(self[self.last_key], text)
        else
            self[self.last_key] = text
        end
        return
    end
    for raw_key, value in string.gmatch(text, "([0-9a-zA-Z\\-]+): (.+);?") do
        local key = Headers.normalize_key(raw_key)
        self.last_key = key
        self[key] = value
    end
end

---Append a key value pair to this collection
---@param self table
---@param key string
---@param value string
function Headers:append(key, value)
    if self[key] == nil then
        self[key] = value
    else
        table.insert(self[key], value)
    end
end

--- Constructor for a Headers instance with the provided text
function Headers.from_chunk(text)
    local headers = Headers.new()
    headers:append_chunk(text)
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
--- lua identifer used by this collection
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
    if type(values) == "string" then
        return values
    end
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
    local values = self[k]
    if type(values) == "string" then
        return {values}
    end
    return self[k]
end

local Request = {}

Request.__index = Request

--- Parse the first line of an HTTP request
local function parse_preamble(line)
    for method, path, http_version in string.gmatch(line, "([A-Z]+) (.+) HTTP/([0-9.]+)") do
        return {
            method = method,
            path = path,
            http_version = http_version,
            raw = line .. "\r\n",
        }
    end
    return nil, string.format("Invalid http request first line: '%s'", line)
end

--- Constructor from the provided incoming socket connection
function Request.from(incoming)
    local r = Request.new({socket = incoming})
    assert(getmetatable(r) == Request)
    local line, acc_err = Request._next_chunk(r)
    if acc_err then
        return nil, acc_err
    end
    local pre, pre_err = parse_preamble(line)
    if pre_err then
        return nil, pre_err
    end
    r.http_version = pre.http_version
    r.method = pre.method
    r.path = pre.path
    r.raw = pre.raw
    return r
end

--- Get the headers for this request
--- parsing the incoming stream of headers
--- if not already parsed
function Request:get_headers()
    if self.parsed_headers == false then
        local err = Request._parse_headers(self)
        if err == nil then
            return err
        end
    end
    return self.headers
end

function Request:_parse_headers(r)
    while true do
        local done, err = self:_parse_header(r)
        if err ~= nil then
            return err
        end
        if done then
            self.parsed_headers = true
            return
        end
    end
end

function Request:_parse_header()
    local line, err = self:_next_chunk()
    if err ~= nil then
        return nil, err
    end
    if self.headers == nil then
        self.headers = Headers.new()
    end
    if line == "" then
        self:_append_raw("")
        return true
    else
        self.headers:append_chunk(line)
    end
    return false
end

function Request:_next_chunk()
    local chunk, err = self.socket:receive()
    if chunk ~= nil then
        self:_append_raw(chunk)
    end
    return chunk, err
end

function Request:_append_raw(line)
    self.raw = (self.raw or '') .. line .. "\r\n"
end

function Request:_append_body(line)
    if self.body == nil then
        self.body = line
    else
        self.body = self.body .. line
    end
end

function Request.new(base)
    local ret = base or {}
    if ret.parsed_headers == nil then
        ret.parsed_headers = false
    end
    setmetatable(ret, Request)
    return ret
end

return {
    Request = Request,
    Headers = Headers,
    testable = {
        parse_preamble = parse_preamble,
        serialize_header = serialize_header,
    }
}