local socket = require 'socket'
local lux = require 'luxure'
local dkjson = require 'dkjson'

local server = lux.Server.new(socket)

server:use(function (req, res, next)
    local h = req:get_headers()
    if req.method == 'POST' and h.content_type == 'application/json' then
        req.raw_body = req:get_body()
        local success, body = pcall(dkjson.decode, req.raw_body)
        if success then
            req.body = body
        else
            print('failed to parse json')
        end
    end
    next.fn(req, res, next.next)
end)

server:get('/', function(req, res)
    res:send('Hello world!')
end)

server:get('/:name', function(req, res)
    res:send(string.format('Hello %s', req.params.name))
end)

server:post('/', function(req, res)
    res:send(string.format('Hello %s', req.body.name))
end)

server:listen(8080)

server:run()
