local header = require "header"

Request = {}

Request.__index = Request

--- Parse the first line of an HTTP request
local function parse_preamble(line)
    for method, path, http_version in string.gmatch(line, "([A-Z]+) (.+) HTTP/([0-9.]+)") do
        return {
            method = method,
            path = path,
            http_version = http_version,
            raw = line .. "\r\n",
            headers = nil,
            body = nil,
        }
    end
    return nil, string.format("Invalid http request first line: '%s'", line)
end

--- Constructor from the provided incoming socket connection
function Request.from(incoming)
    local line, acc_err = incoming:receive()
    if acc_err then
        return nil, acc_err
    end
    local pre, pre_err = parse_preamble(line)
    if pre_err then
        return nil, acc_err
    end
    setmetatable(pre, Request)
    pre.parsed_headers = false
    return pre
end

--- Get the headers for this request
--- parsing the incoming stream of headers
--- if not already parsed
function Request:headers()
    if self.headers == nil then
        local err = self:_parse_headers()
        if err == nil then
            return err
        end
    end
    return self.headers
end

function Request:_parse_headers()
    while true do
        local done, err = self:_parse_header()
        if err ~= nil then
            return err
        end
        if done then
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
        self.headers = header.Headers.new()
    end
    if line == "" then
        self:_append_raw("")
        return true
    else
        self.headers:append_from(line)
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
    self.raw = self.raw .. line .. "\r\n"
end

function Request:_append_body(line)
    if self.body == nil then
        self.body = line
    else
        self.body = self.body .. line
    end
end

if _G.TEST then
    describe("Request", function()
        describe("parse_preamble", function()
            it("GET / HTTP/1.1 should work", function()
                local r, e = parse_preamble("GET / HTTP/1.1")
                assert(e == nil)
                assert(r.method == "GET")
                assert(r.path == "/")
                assert(r.http_version == "1.1")
            end)
            it("GET /things HTTP/2 should work", function()
                local r, e = parse_preamble("GET /things HTTP/2")
                assert(r.method == "GET", "expected method to be GET")
                assert(r.path == "/things", "expected path to be /things")
                assert(r.http_version == "2", "expected version to be 2")
            end)
            it("POST /stuff HTTP/2 should work", function()
                local r, e = parse_preamble("POST /stuff HTTP/2")
                assert(r.method == "POST", "expected method to be POST")
                assert(r.path == "/stuff", "expected path to be /stuff")
                assert(r.http_version == "2", "expected version to be 2")
            end)
        end)
    end)
end

return {
    Request = Request,
    Headers = header.Headers,
}