local headers = require 'luxure.headers'
local Headers = headers.Headers
local serialize_header = headers.serialize_header

local normal_headers = {
    {"Accept: text/html", 'accept', "text/html"},
    {"Accept-Charset: utf-8", 'accept_charset', "utf-8"},
    {"Accept-Encoding: *", 'accept_encoding', "*"},
    {"Accept-Language: en-us", 'accept_language', "en-us"},
    {"Accept-Ranges: none", 'accept_ranges', "none"},
    {"Age: 12", 'age', "12"},
    {"Allow: GET, HEAD", 'allow', "GET, HEAD"},
    {"Authorization: Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==", 'authorization', 'Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ=='},
    {"Cache-Control: no-cache", 'cache_control', 'no-cache'},
    {"Connection: keep-alive", 'connection', 'keep-alive'},
    {"Content-Encoding: gzip", 'content_encoding', 'gzip'},
    {"Content-Language: en", 'content_language', 'en'},
    {"Content-Length: 100", 'content_length', '100'},
    {"Content-Location: /index.html", 'content_location', '/index.html'},
    {"Content-MD5: Q2hlY2sgSW50ZWdyaXR5IQ==", 'content_md5', 'Q2hlY2sgSW50ZWdyaXR5IQ=='},
    {"Content-Range: bytes 21010-47021/47022", 'content_range', 'bytes 21010-47021/47022'},
    {"Content-Type: text/html; charset=utf-8", 'content_type', 'text/html; charset=utf-8'},
    {"Date: Tue, 15 Nov 1994 08:12:31 GMT", 'date', 'Tue, 15 Nov 1994 08:12:31 GMT'},
    {"ETag: \"737060cd8c284d8af7ad3082f209582d\"", 'etag', '\"737060cd8c284d8af7ad3082f209582d\"'},
    {"Expect: 100-continue", 'expect', '100-continue'},
    {"Expires: Thu, 01 Dec 1994 16:00:00 GMT", 'expires', 'Thu, 01 Dec 1994 16:00:00 GMT'},
    {"From: user@example.com", 'from', 'user@example.com'},
    {"Host: www.example.com", 'host', 'www.example.com'},
    {"If-Match: \"737060cd8c284d8af7ad3082f209582d\"", 'if_match', '\"737060cd8c284d8af7ad3082f209582d\"'},
    {"If-Modified-Since: Sat, 29 Oct 1994 19:43:31 GMT", 'if_modified_since', 'Sat, 29 Oct 1994 19:43:31 GMT'},
    {"If-None-Match: \"737060cd8c284d8af7ad3082f209582d\"", 'if_none_match', '\"737060cd8c284d8af7ad3082f209582d\"'},
    {"If-Range: \"737060cd8c284d8af7ad3082f209582d\"", 'if_range', '\"737060cd8c284d8af7ad3082f209582d\"'},
    {"If-Unmodified-Since: Sat, 29 Oct 1994 19:43:31 GMT", 'if_unmodified_since', 'Sat, 29 Oct 1994 19:43:31 GMT'},
    {"Last-Modified: Sat, 29 Oct 1994 19:43:31 GMT", 'last_modified', 'Sat, 29 Oct 1994 19:43:31 GMT'},
    {"Location: http://www.w3.org/pub/WWW/People.html", 'location', 'http://www.w3.org/pub/WWW/People.html'},
    {"Max-Forwards: 10", 'max_forwards', '10'},
    {"Pragma: no-cache", 'pragma', 'no-cache'},
    {"Proxy-Authenticate: Basic", 'proxy_authenticate', 'Basic'},
    {"Proxy-Authorization: Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==", 'proxy_authorization', 'Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ=='},
    {"Range: bytes=500-999", 'range', 'bytes=500-999'},
    {"Referer: http://www.example.com/index.html", 'referer', 'http://www.example.com/index.html'},
    {"Retry-After: 120", 'retry_after', '120'},
    {"Server: Luxure 0.1.0", 'server', 'Luxure 0.1.0'},
    {"TE: trailers, deflate", 'te', 'trailers, deflate'},
    {"Trailer: Max-Forwards", 'trailer', 'Max-Forwards'},
    {"Upgrade: h2c, HTTPS/1.3, IRC/6.9, RTA/x11, websocket", 'upgrade', 'h2c, HTTPS/1.3, IRC/6.9, RTA/x11, websocket'},
    {"User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:12.0) Gecko/20100101 Firefox/12.0", 'user_agent', 'Mozilla/5.0 (X11; Linux x86_64; rv:12.0) Gecko/20100101 Firefox/12.0'},
    {"Vary: *", 'vary', '*'},
    {"Via: 1.0 fred, 1.1 example.com (Apache/1.1)", 'via', '1.0 fred, 1.1 example.com (Apache/1.1)'},
    {"Warning: 199 Miscellaneous warning", 'warning', '199 Miscellaneous warning'},
    {"WWW-Authenticate: Basic", 'www_authenticate', 'Basic'},
}
describe('Headers', function ()
    describe("append_chunk", function()
        it("All Standard headers", function()
            local h = Headers.new()
            for _, set in ipairs(normal_headers) do
                local chunk = set[1]
                local key = set[2]
                local expected = set[3]
                h:append_chunk(chunk)
                assert(h[key] == expected, string.format('%s found %s expected %s', key, h[key], expected))
            end
        end)

        it("Can handle multi line headers", function()
            local h = Headers.new()
            h:append_chunk("x-Multi-Line-Header: things and stuff")
            h:append_chunk(" places and people")
            assert(h.x_multi_line_header, "thinigs and stuff\nplaces and people")
        end)
    end)
    describe('serialize_header', function ()
        it('can handle normal header', function()
            for _, set in ipairs(normal_headers) do
                local header = serialize_header(set[2], set[3])
                assert(header == set[1], string.format('expected %s found %s', set[1], header))
            end
        end)
    end)
end)