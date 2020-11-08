local headers = require 'luxure.headers'
local statuses = require 'luxure.status'
local Error = require 'luxure.error'.Error

---@class Response
---@field headers Headers The HTTP headers for this response
---@field _status number The HTTP status code for this response
---@field body string the contents of the response body
---@field outgoing table The socket this response will send on
local Response = {}

Response.__index = Response


--- create a response for to a corisponding request
--- @param outgoing table anything that can call `:send()`
function Response.new(outgoing)
    local base = {
        headers = headers.Headers.new(),
        _status = 200,
        body = "",
        http_version = "1.1",
        outgoing = outgoing,
    }
    setmetatable(base, Response)
    return base
end

--- set the status for this request
--- @param n number the 3 digit status
function Response:status(n)
    Error.assert(type(n) == 'number', string.format('http status must be a number, found %s', type(n)))
    self._status = n
    return self
end

--- set the content type of the outbound request
--- @param mime string the mime type for this request
function Response:content_type(mime)
    Error.assert(type(mime) == 'string', string.format('mime type must be a string, found %s', type(mime)))
    self.headers.content_type = mime
    return self
end

function Response:_serialize()
    local s = string.format('HTTP/%s %s %s\r\n', self.http_version, self._status, statuses[self._status] or '')
    self.headers:append('Content-Length', string.format('%i', #self.body))
    self.headers:append('Server', 'Luxure')
    s = s .. self.headers:serialize() .. '\r\n'
    s = s .. (self.body or "")
    return s
end

--- Append text to the body
--- @param s string the text to append
function Response:append_body(s)
    if self.headers.content_type == nil then
        self.headers.content_type = 'text/plain'
    end
    if type(s) == "string" then
        self.body = (self.body or "") .. s
    end
    return self
end

--- complete this http request by sending this response as text
function Response:send(s)
    if type(s) == 'string' then
        self:append_body(s)
    end
    local success, sent_or_err, err = pcall(self.outgoing.send, self.outgoing, self:_serialize())
    -- if pcall failes on send, we return early with the message
    -- from that
    Error.assert(success, sent_or_err)
    -- if pcall returns successfully, we still need to make sure that
    -- the send didn't return an eror 'timeout' or 'close'
    Error.assert(sent_or_err, err)
end

function Response:has_sent()
    if self._has_sent then
        return self._has_sent
    end
    local _, s = self.outgoing:getstats()
    self._has_sent = s > 0
    return self._has_sent
end

return {
    Response = Response,
}
