local headers = require 'luxure.headers'
local statuses = require 'luxure.status'
local Error = require 'luxure.error'.Error

---Send all text provided, retrying on failure or timeout
---@param sock table The client socket to send on
---@param s string The string to send
local function send_all(sock, s)
    local total_sent = 0
    local target = #s
    local retries = 0
    while total_sent < target and retries < 5 do
        local success, sent_or_err, err = pcall(sock.send, sock, string.sub(s, total_sent))
        if not success then
            retries = retries + 1
        else
            if not sent_or_err then
                if err == 'closed' then
                    Error.raise('Attempt to send on closed socket')
                elseif err == 'timeout' then
                    retries = retries + 1
                end
            else
                total_sent = total_sent + sent_or_err
            end
        end
    end
    return total_sent
end

---@class Response
---@field headers Headers The HTTP headers for this response
---@field body string the contents of the response body
---@field outgoing table The socket this response will send on
local Response = {}

Response.__index = Response

---create a response for to a corisponding request
---@param outgoing table anything that can call `:send()`
---@param send_buffer_size number|nil If provided, sending will happen
---in a buffered fashion
function Response.new(outgoing, send_buffer_size)
    local base = {
        headers = headers.Headers.new(),
        _status = 200,
        body = '',
        http_version = '1.1',
        outgoing = outgoing,
        _send_buffer_size = send_buffer_size,
        chunks_sent = 0,
    }
    setmetatable(base, Response)
    return base
end

---Set the status for this request
---@param n number the 3 digit status
---@return Response
function Response:status(n)
    if type(n) == 'string' then
        n = math.tointeger(n)
    end
    Error.assert(type(n) == 'number', string.format('http status must be a number, found %s', type(n)))
    self._status = n
    return self
end

---set the content type of the outbound request
---@param s string the mime type for this request
function Response:content_type(s)
    Error.assert(type(s) == 'string', string.format('mime type must be a string, found %s', type(s)))
    self.headers.content_type = s
    return self
end

---Set the Content-Length header for this response
---@param len number The length of the content that will be sent
---@return Response
function Response:content_length(len)
    assert(type(len) == 'number', string.format('content length must be a number, found %s', type(len)))
    self.headers.content_length = string.format('%i', len)
    return self
end

---Set the send buffer size to enable buffered writes
---if unset, the full response body is buffered before sending
---@param size number|nil
function Response:set_send_buffer_size(size)
    self._send_buffer_size = size
end

---Serialize this full response into a string
---@return string
function Response:_serialize()
    self:content_length(#self.body)
    self.headers.server = 'Luxure'
    return self:_generate_prebody()
        .. (self.body or '')
end

---Generate the first line of this response without the trailing \r\n
---@return string
function Response:_generate_preamble()
    return string.format('HTTP/%s %s %s',
        self.http_version,
        self._status,
        statuses[self._status] or ''
    )
end

---Create the string representing the pre-body entries for
---this request. including the 2 trailing \r\n
---@return string
function Response:_generate_prebody()
    return self:_generate_preamble() .. '\r\n'
        .. self.headers:serialize() .. '\r\n'
end

---Append text to the body
---@param s string the text to append
---@return Response
function Response:append_body(s)
    if type(s) == 'string' then
        self.body = (self.body or '') .. s
    end
    if self:_should_send() then
        self:_send_chunk()
    end
    return self
end

---Check if we are sending in buffered mode
---and if we should send the current buffer
---@return number|nil
function Response:_should_send()
    return self._send_buffer_size and
        #self.body >= self._send_buffer_size
end

---Send a chunk when sending in buffered mode
---this will truncate self.body to an empty string
function Response:_send_chunk()
    local to_send = self.body
    if not self:has_sent() then
        to_send = self:_generate_prebody()..to_send
    else
    end
    send_all(self.outgoing, to_send)
    self.body = ''
end

---complete this http request by sending this response as text
---@param s string|nil
function Response:send(s)
    if type(s) == 'string' then
        self:append_body(s)
    end
    if self.headers.content_type == nil then
        self:content_type('text/plain')
    end
    if self._send_buffer_size == nil
    or not self:has_sent() then
        send_all(self.outgoing, self:_serialize())
    else
        send_all(self.outgoing, self.body)
    end
end

---Create a ltn12 sink for sending on this Response
---If using this interface, it is a very good idea to already
---know the size of your response body and set that prior
---to passing this sink to a pump. If the Content-Length header
---is unset when this starts, there will be no way to back fill
---that value.
---
---For buffered writes, be sure to call :set_send_buffer_size
---@return fun(chunk:string|nil, err: string|nil): number|nil
function Response:sink()
    return function(chunk, err)
        Error.assert(not err, err)
        if chunk == nil then
            self:send()
        else
            self:append_body(chunk)
        end
        return 1
    end
end


---Check if this response has sent any bytes
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
