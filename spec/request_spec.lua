local r = require 'luxure.request'
local Request = r.Request
local parse_preamble = r.testable.parse_preamble
local serialize_header = r.testable.serialize_header
local MockSocket = require 'spec.mock_socket'.MockSocket

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

describe('Request', function()
    describe('parse_preamble', function()
        it('GET / HTTP/1.1 should work', function()
            local r, e = parse_preamble("GET / HTTP/1.1")
            assert(e == nil)
            assert(r.method == "GET")
            assert(r.url.path == "/")
            assert(r.http_version == "1.1")
        end)
        it('GET /things HTTP/2 should work', function()
            local r, e = parse_preamble("GET /things HTTP/2")
            assert(r.method == "GET", "expected method to be GET")
            assert(r.url.path == "/things", "expected path to be /things")
            assert(r.http_version == "2", "expected version to be 2")
        end)
        it('POST /stuff HTTP/2 should work', function()
            local r, e = parse_preamble("POST /stuff HTTP/2")
            assert(r.method == "POST", "expected method to be POST")
            assert(r.url.path == "/stuff", "expected path to be /stuff")
            assert(r.http_version == "2", "expected version to be 2")
        end)
    end)
    describe('Request.headers', function ()
        it('works', function ()
            local inner = {'GET / HTTP/1.1 should work'}
            for _, set in ipairs(normal_headers) do
                table.insert(inner, set[1])
            end
            table.insert(inner, '')
            local r, e = Request.new(MockSocket.new(inner))
            assert(e == nil, string.format('error in Request.from: %s', e))
            local headers, e2 = r:get_headers()
            assert(e2 == nil, string.format('error in get_headers %s', e2))
            local table_string = require 'luxure.utils'.table_string
            assert(headers, string.format('headers was nil: %s', table_string(r)))
            for _, set in ipairs(normal_headers) do
                local key = set[2]
                local expected = set[3]
                assert(headers[key] == expected, string.format("%s, found %s expected %s", key, headers[key], expected))
            end
        end)
    end)
    describe('Request.body', function()
        it('Will get filled in when needed', function()
            local lines = {
                'POST / HTTP/1.1 should work',
                'Content-Length: 4',
                '',
                'asdfg',
            }
            local r, e = Request.new(MockSocket.new(lines))
            assert(e == nil, 'error parsing preamble ' .. (e or 'nil'))
            local e2 = r:_fill_body()
            assert(e2 == nil, 'error parsing body: ' .. (e2 or 'nil'))
            assert(r._body == 'asdfg', 'Expected asdfg, found ' .. (r._body or 'nil'))
        end)
    end)
end)
