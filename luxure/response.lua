local headers = require 'headers'
local statuses = require 'luxure.status'
local Response = {}


--- create a response for to a corisponding request
--- @param outgoing table anything that can call `:send()`
function Response.new(outgoing)
    local base = {
        headers = headers.Headers.new(),
        status = 200,
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
    assert(type(n) == 'number', string.format('http status must be a number, found %s', type(n)))
    self.status = n
    return self
end

--- set the content type of the outbound request
--- @param mime string the mime type for this request
function Response:content_type(mime)
    assert(type(mime) == 'string', string.format('mime type must be a string, found %s', type(mime)))
    self.headers.content_type = mime
    return self
end

function Response:_serialize()
    local s = string.format('HTTP/%s %s %s\r\n', self.http_version, self.status, statuses[self.status] or '')
    self.headers:append('content-length', string.format('%i', #self.body))
    self.headers:append('server', 'Luxure')
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
        self.append_body(s)
    end
    self.outgoing:send(self._serialize())
end

return {
    Response = Response,
}