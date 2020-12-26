-- This comes from LuaSocket
local mime = require 'mime'
local lux = require 'luxure'

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
            local decoded = mime.decode('base64')(encoded)
            for _ in string.gmatch(decoded, '.*:SUPERSECRET$') do
                return next(req, res)
            end
        end
    end
    res.headers.www_authenticate = 'Basic realm=\'my realm\''
    lux.Error.raise('Unable to authenticate', 401)
end)

local function static_content(path, res)
    local f = io.open(path)
    lux.Error.assert(f, 'File not found', 404)
    res.content_type('text/html')
    for line in f:lines('L') do
        res.append_body(line)
    end
    res:send()
    if f then f:close() end
end

server:get('/', function(req, res)
    static_content('static/not_authed.html')
end)

server:get('/authed', function(req, res)
    static_content('static/authed.html')
end)

server:run()
