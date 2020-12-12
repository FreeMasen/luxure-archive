local net_url = require 'net.url'
local Headers = require 'luxure.headers'.Headers
local Error = require 'luxure.error'.Error

---@class Request
---@field method string the HTTP method for this request
---@field url table The parse url of this request
---@field http_version string The http version from the request preamble
---@field headers Headers The HTTP headers for this request
---@field body string The contents of the request
local Request = {}

Request.__index = Request

---Parse the first line of an HTTP request
---@param line string
---@return table
local function parse_preamble(line)
    for method, path, http_version in string.gmatch(line, '([A-Z]+) (.+) HTTP/([0-9.]+)') do
        return {
            method = method,
            url = net_url.parse(path),
            http_version = http_version,
            _body = nil,
            _headers = nil,
        }
    end
    Error.assert(false, string.format('Invalid http request first line: "%s"', line))
end

---Get the headers for this request
---parsing the incoming stream of headers
---if not already parsed
---@return Headers, string|nil
function Request:get_headers()
    if self.parsed_headers == false then
        local err = self:_fill_headers()
        if err ~= nil then
            return nil, err
        end
    end
    return self._headers
end

---read from the socket filling in the headers property
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

---Read a single line from the socket and parse it as an http header
---returning true when the end of the http headers
---@return boolean|nil, string|nil
function Request:_parse_header()
    local line, err = self:_next_line()
    if err ~= nil then
        return nil, err
    end
    if self._headers == nil then
        self._headers = Headers.new()
    end
    if line == '' then
        return true
    else
        self._headers:append_chunk(line)
    end
    return false
end
---Read a single line from the socket
---@return string|nil, string|nil
function Request:_next_line()
    local line, err = self.socket:receive('*l')
    return line, err
end

---Get the contents of this request's body
---if not yet received, this will read the body
---from the socket
---@return string|nil, string|nil
function Request:get_body()
    if not self._received_body then
        local err = self:_fill_body()
        if err ~= nil then
            return nil, err
        end
    end
    return self._body
end

---Read from the socket, filling the body property
---of this request
---@return string|nil
function Request:_fill_body()
    local len, err = self:content_length()
    if len == nil then
        return err
    end
    self._body = self.socket:receive(len)
    self._received_body = true
end

---Get the value from the Content-Length header that should be present
---for all http requests
---@return number|nil, string|nil
function Request:content_length()
    local headers, err = self:get_headers()
    if err then
        return nil, err
    end
    if headers.content_length == nil then
        return 0
    end
    return math.tointeger(headers.content_length) or 0
end

---Construct a new Request
---@param socket table The tcp client socket for this request
---@return Request|nil, string|nil
function Request.new(socket)
    Error.assert(socket, 'cannot create request with nil socket')
    local r = {
        socket = socket,
        parsed_headers = false,
    }
    setmetatable(r, Request)
    local line, acc_err = r:_next_line()
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
    return r
end

return {
    Request = Request,
    testable = {
        parse_preamble = parse_preamble,
    }
}
