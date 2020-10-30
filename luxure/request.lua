local h = require 'luxure.headers'
local Headers = h.Headers

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
    testable = {
        parse_preamble = parse_preamble,
    }
}