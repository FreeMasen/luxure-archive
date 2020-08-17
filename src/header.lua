Headers = {}

Headers.__index = Headers

local function _append(t, key, value)
    if t[key] == nil then
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
    for raw_key, value in string.gmatch(text, "([0-9a-zA-Z\\-]+): (.+);?") do
        local key = Headers.normalize_key(raw_key)
        self.last_key = key
        if self[key] == nil then
            self[key] = {}
        end
        table.insert(self[key], value)
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

if _G.TEST then
    describe("Header", function()
        describe("append_chunk", function()
            it("All Standard headers", function()
                local h = Headers.new()
                h:append_chunk("Accept: text/html")
                assert(h.accept[1] == "text/html", string.format('h.accept ~= "text/html" ~= %s', h.accept))
                h:append_chunk("Accept-Charset: utf-8")
                assert(h.accept_charset[1] == "utf-8", 'h.accept_charset ~= "utf-8"')
                h:append_chunk("Accept-Encoding: *")
                assert(h.accept_encoding[1] == "*", 'h.accept_encoding ~= "*"')
                h:append_chunk("Accept-Language: en-us")
                assert(h.accept_language[1] == "en-us", 'h.accept_language ~= "en-us"')
                h:append_chunk("Accept-Ranges: none")
                assert(h.accept_ranges[1] == "none", 'h.accept_ranges ~= "none"')
                h:append_chunk("Age: 12")
                assert(h.age[1] == "12", 'h.age ~= "12"')
                h:append_chunk("Allow: GET, HEAD")
                assert(h.allow[1] == "GET, HEAD", 'h.allow ~= "GET, HEAD"')
                h:append_chunk("Authorization: Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==")
                assert(h.authorization[1] == "Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==", 'h.authorization ~= "Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ=="')
                h:append_chunk("Cache-Control: no-cache")
                assert(h.cache_control[1] == "no-cache", 'h.cache_control ~= "no-cache"')
                h:append_chunk("Connection: keep-alive")
                assert(h.connection[1] == "keep-alive", 'h.connection ~= "keep-alive"')
                h:append_chunk("Content-Encoding: gzip")
                assert(h.content_encoding[1] == "gzip", 'h.content_encoding ~= "gzip"')
                h:append_chunk("Content-Language: en")
                assert(h.content_language[1] == "en", 'h.content_language ~= "en"')
                h:append_chunk("Content-Length: 100")
                assert(h.content_length[1] == "100", 'h.content_length ~= "100"')
                h:append_chunk("Content-Location: /index.html")
                assert(h.content_location[1] == "/index.html", 'h.content_location ~= "/index.html"')
                h:append_chunk("Content-MD5: Q2hlY2sgSW50ZWdyaXR5IQ==")
                print(u.table_string(h))
                assert(h.content_md5[1] == "Q2hlY2sgSW50ZWdyaXR5IQ==")
                h:append_chunk("Content-Range: bytes 21010-47021/47022")
                assert(h.content_range[1] == "bytes 21010-47021/47022", 'h.content_range ~= "bytes 21010-47021/47022"')
                h:append_chunk("Content-Type: text/html; charset=utf-8")
                assert(h.content_type[1] == "text/html; charset=utf-8", 'h.content_type ~= "text/html; charset=utf-8"')
                h:append_chunk("Date: Tue, 15 Nov 1994 08:12:31 GMT")
                assert(h.date[1] == "Tue, 15 Nov 1994 08:12:31 GMT", 'h.date ~= "Tue, 15 Nov 1994 08:12:31 GMT"')
                h:append_chunk("ETag: \"737060cd8c284d8af7ad3082f209582d\"")
                assert(h.etag[1] == "\"737060cd8c284d8af7ad3082f209582d\"", 'h.etag ~= "\"737060cd8c284d8af7ad3082f209582d\""')
                h:append_chunk("Expect: 100-continue")
                assert(h.expect[1] == "100-continue", 'h.expect ~= "100-continue"')
                h:append_chunk("Expires: Thu, 01 Dec 1994 16:00:00 GMT")
                assert(h.expires[1] == "Thu, 01 Dec 1994 16:00:00 GMT", 'h.expires ~= "Thu, 01 Dec 1994 16:00:00 GMT"')
                h:append_chunk("From: user@example.com")
                assert(h.from[1] == "user@example.com", 'h.from ~= "user@example.com"')
                h:append_chunk("Host: www.example.com")
                assert(h.host[1] == "www.example.com", 'h.host ~= "www.example.com" ' .. h.host[1])
                h:append_chunk("If-Match: \"737060cd8c284d8af7ad3082f209582d\"")
                assert(h.if_match[1] == "\"737060cd8c284d8af7ad3082f209582d\"", 'h.if_match ~= "\"737060cd8c284d8af7ad3082f209582d\""')
                h:append_chunk("If-Modified-Since: Sat, 29 Oct 1994 19:43:31 GMT")
                assert(h.if_modified_since[1] == "Sat, 29 Oct 1994 19:43:31 GMT", 'h.if_modified_since ~= "Sat, 29 Oct 1994 19:43:31 GMT"')
                h:append_chunk("If-None-Match: \"737060cd8c284d8af7ad3082f209582d\"")
                assert(h.if_none_match[1] == "\"737060cd8c284d8af7ad3082f209582d\"", 'h.if_none_match ~= "\"737060cd8c284d8af7ad3082f209582d\""')
                h:append_chunk("If-Range: \"737060cd8c284d8af7ad3082f209582d\"")
                assert(h.if_range[1] == "\"737060cd8c284d8af7ad3082f209582d\"", 'h.if_range ~= "\"737060cd8c284d8af7ad3082f209582d\""')
                h:append_chunk("If-Unmodified-Since: Sat, 29 Oct 1994 19:43:31 GMT")
                assert(h.if_unmodified_since[1] == "Sat, 29 Oct 1994 19:43:31 GMT", 'h.if_unmodified_since ~= "Sat, 29 Oct 1994 19:43:31 GMT"')
                h:append_chunk("Last-Modified: Sat, 29 Oct 1994 19:43:31 GMT")
                assert(h.last_modified[1] == "Sat, 29 Oct 1994 19:43:31 GMT", 'h.last_modified ~= "Sat, 29 Oct 1994 19:43:31 GMT"')
                h:append_chunk("Location: http://www.w3.org/pub/WWW/People.html")
                assert(h.location[1] == "http://www.w3.org/pub/WWW/People.html", 'h.location ~= "http://www.w3.org/pub/WWW/People.html"')
                h:append_chunk("Max-Forwards: 10")
                assert(h.max_forwards[1] == "10", 'h.max_forwards ~= "10"')
                h:append_chunk("Pragma: no-cache")
                assert(h.pragma[1] == "no-cache", 'h.pragma ~= "no-cache"')
                h:append_chunk("Proxy-Authenticate: Basic")
                assert(h.proxy_authenticate[1] == "Basic", 'h.proxy_authenticate ~= "Basic"')
                h:append_chunk("Proxy-Authorization: Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==")
                assert(h.proxy_authorization[1] == "Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==", 'h.proxy_authorization ~= "Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ=="')
                h:append_chunk("Range: bytes=500-999")
                assert(h.range[1] == "bytes=500-999", 'h.range ~= "bytes=500-999"')
                h:append_chunk("Referer: http://www.example.com/index.html")
                assert(h.referer[1] == "http://www.example.com/index.html", 'h.referer ~= "http://www.example.com/index.html"')
                h:append_chunk("Retry-After: 120")
                assert(h.retry_after[1] == "120", 'h.retry_after ~= "120"')
                h:append_chunk("Server: Luxure 0.1.0")
                assert(h.server[1] == "Luxure 0.1.0", 'h.server ~= "Luxure 0.1.0"')
                h:append_chunk("TE: trailers, deflate")
                assert(h.te[1] == "trailers, deflate", 'h.te ~= "trailers, deflate"')
                h:append_chunk("Trailer: Max-Forwards")
                assert(h.trailer[1] == "Max-Forwards", 'h.trailer ~= "Max-Forwards"')
                h:append_chunk("Upgrade: h2c, HTTPS/1.3, IRC/6.9, RTA/x11, websocket")
                assert(h.upgrade[1] == "h2c, HTTPS/1.3, IRC/6.9, RTA/x11, websocket", 'h.upgrade ~= "h2c, HTTPS/1.3, IRC/6.9, RTA/x11, websocket"')
                h:append_chunk("User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:12.0) Gecko/20100101 Firefox/12.0")
                assert(h.user_agent[1] == "Mozilla/5.0 (X11; Linux x86_64; rv:12.0) Gecko/20100101 Firefox/12.0", 'h.user_agent ~= "Mozilla/5.0 (X11; Linux x86_64; rv:12.0) Gecko/20100101 Firefox/12.0"')
                h:append_chunk("Vary: *")
                assert(h.vary[1] == "*", 'h.vary ~= "*"')
                h:append_chunk("Via: 1.0 fred, 1.1 example.com (Apache/1.1)")
                assert(h.via[1] == "1.0 fred, 1.1 example.com (Apache/1.1)", 'h.via ~= "1.0 fred, 1.1 example.com (Apache/1.1)"')
                h:append_chunk("Warning: 199 Miscellaneous warning")
                assert(h.warning[1] == "199 Miscellaneous warning", 'h.warning ~= "199 Miscellaneous warning"')
                h:append_chunk("WWW-Authenticate: Basic")
                assert(h.www_authenticate[1] == "Basic", 'h.www_authenticate ~= "Basic"')
            end)
        end)
    end)
end
return {
    Headers = Headers,
}

