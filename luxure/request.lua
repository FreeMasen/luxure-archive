local net_url = require 'net.url'
local Headers = require 'luxure.headers'.Headers
---@class Request
---@field method string the HTTP method for this request
---@field url table The parse url of this request
---@field http_version string The http version from the request preamble
---@field headers Headers The HTTP headers for this request
---@field body string The contents of the request
---@field raw string the raw request contents
local Request = {}

Request.__index = Request

--- Parse the first line of an HTTP request
local function parse_preamble(line)
    for method, path, http_version in string.gmatch(line, "([A-Z]+) (.+) HTTP/([0-9.]+)") do
        return {
            method = method,
            url = net_url.parse(path),
            http_version = http_version,
            _body = nil,
            _headers = nil,
            raw = line .. "\r\n",
        }
    end
    return nil, string.format("Invalid http request first line: '%s'", line)
end

--- Get the headers for this request
--- parsing the incoming stream of headers
--- if not already parsed
function Request:get_headers()
    if self.parsed_headers == false then
        local err = self:_fill_headers()
        if err ~= nil then
            return nil, err
        end
    end
    return self._headers
end

function Request:_fill_headers()
    while true do
        local done, err = self:_parse_header()
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
    if self._headers == nil then
        self._headers = Headers.new()
    end
    if line == "" then
        self:_append_raw("")
        return true
    else
        self._headers:append_chunk(line)
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
    if self._body == nil then
        self._body = line
    else
        self._body = self.body .. line
    end
end

function Request:get_body()
    if not self._received_body then
        self:_fill_body()
    end
    return self._body
end

function Request:_fill_body()
    local headers, err = self:get_headers()
    if err then
        return err
    end
    if headers.content_length ~= nil then
        self._body = self.socket:receive(headers.content_length)
    end
end

function Request.new(socket)
    local r = {
        socket = socket,
        parsed_headers = false,
    }
    setmetatable(r, Request)
    local line, acc_err = r:_next_chunk()
    if acc_err then
        return nil, acc_err
    end
    local pre, pre_err = parse_preamble(line)
    if pre_err then
        return nil, pre_err
    end
    r.http_version = pre.http_version
    r.method = pre.method
    r.url = pre.url
    r.raw = pre.raw
    return r
end

return {
    Request = Request,
    testable = {
        parse_preamble = parse_preamble,
    }
}