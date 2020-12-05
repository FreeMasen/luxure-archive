local socket = require 'socket'
local lux = require 'luxure'

--- This will hold our base64 decoding map
local map = nil

local function setup_base64_map()
    if map then
        return
    end
    map = {}
    for i, ch in ipairs({'A','B','C','D','E','F','G','H','I','J',
    'K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y',
    'Z','a','b','c','d','e','f','g','h','i','j','k','l','m','n',
    'o','p','q','r','s','t','u','v','w','x','y','z','0','1','2',
    '3','4','5','6','7','8','9','+','/','='}) do
        local byte = string.byte(ch)
        map[byte] = i - 1
    end
end

--- Base64 decode a set of encoded characters
---@param byte1 number
---@param byte2 number
---@param byte3 number
---@param byte4 number
local function decode_part(byte1, byte2, byte3, byte4)
    local v = map[byte1] * 0x40000
    v = v + (map[byte2] * 0x1000)
    if byte3 ~= nil then
        v = v + (map[byte3]) * 0x40
    end
    if byte4 ~= nil then
        v = v + map[byte4]
    end
    local parsed = string.char((v >> 16) & ((1 << 8) - 1))
    if  byte3 ~= nil then
        parsed = parsed .. string.char((v >>  8) & ((1 << 8) - 1))
    end
    if byte4 ~= nil then
        parsed = parsed .. string.char(v & ((1 << 8) - 1))
    end
    return parsed
end

--- Base64 decode a string
---@param s string
local function base64_decode(s)
    setup_base64_map()
    s = string.gsub(s,'[^%w%+%/%=]', '')
    local padding = 0
    local len = #s
    if string.sub(s,-2) == '==' then
        padding = 2
        len = len - 4
    elseif string.sub(s,-1) == '=' then
        padding = 1
        len = len - 4
    end
    if len == 0 then len = #s end
    local parsed = {}
    for i = 1, len, 4 do
        table.insert(parsed, decode_part(string.byte(s, i, i+3)))
    end
    if padding == 2 then
        parsed[#parsed+1] = decode_part(string.byte(s, #s - 3, #s - 2))
    elseif padding == 1 then
        parsed[#parsed+1] = decode_part(string.byte(s, #s - 3, #s - 1))
    end

    return table.concat(parsed, '')
end

local server = lux.Server.new(socket)
server:listen(9090)
-- use some middleware that will check for
-- the authorization header with a password 'SUPERSECRET'
server:use(function (req, res, next)
    if req.url == '/' then
        return next(req, res)
    end
    local h = req:get_headers();
    if h.authorization then
        for encoded in string.gmatch(h.authorization, 'Basic (.*)') do
            local decoded = base64_decode(encoded)
            for _ in string.gmatch(decoded, '.*:SUPERSECRET$') do
                return next(req, res)
            end
        end
    end
    res.headers.www_authenticate = 'Basic realm="my realm"'
    lux.Error.raise("Unable to authenticate", 401)
end)

local function static_content(path, res)
    local f = io.open(path)
    lux.Error.assert(f, 'File not found', 404)
    res.content_type('text/html')
    for line in f:lines('L') do
        res.append_body(line)
    end
    ;res:send()
    if f then f:close() end
end

server:get('/', function(req, res)
    static_content('static/not_authed.html')
end)

server:get('/authed', function(req, res)
    static_content('static/authed.html')
end)

server:run()
