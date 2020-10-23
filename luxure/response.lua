local headers = require 'headers'
local Response = {}

function Response.new(base)
    base = base or {
        headers = headers.Headers.new(),
        status = 200,
        status_message = "OK",
        body = "",
        http_version = "1.1"
    }
    setmetatable(base, Response)
    return base
end

function Response:status(n)
    if type(n) == "number" then
        self.status = n
    end
    return self.status
end

function Response:append_body(s)
    if type(s) == "string" then
        self.body = (self.body or "") .. s
    end
    return self.body
end

function Response:serialize()
    local s = string.format("HTTP/%s %s %s\r\n", self.http_version, self.status, self.status_message)
    self.headers:append("content-length", string.format("%i", #self.body))
    s = s .. self.headers:serialize() .. "\r\n"
    s = s .. (self.body or "")
    return s
end

return {
    Response = Response,
}