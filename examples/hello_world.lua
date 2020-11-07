-- import a module that provides the api of luasocket
local socket = require 'socket'
local dkjson = require 'dkjson'
local lux = require 'luxure'

-- pass in the socket module you'd like to use here
local server = lux.Server.new(socket)

-- use some middleware for parsing json bodies
server:use(function (req, res, next)
    local h = req:get_headers()
    if req.method == 'POST' and h.content_type == 'application/json' then
        req.raw_body = req:get_body()
        assert(req.raw_body)
        local success, body = pcall(dkjson.decode, req.raw_body)
        if success then
            req.body = body
        else
            print('failed to parse json')
        end
    end
    next.fn(req, res, next.next)
end)

-- define a root GET endpoint
server:get('/', function(req, res)
    print('GET /')
    res:send('Hello world!')
end)

-- This endpoint will always return 500
server:get('/fail', function()
    assert(false)
end)

-- define a parameterized GET endpoint, here :name will
-- be matched on any request /hello/(.+) and whatever
-- value is after /hello/ will populate `req.params.name`
server:get('/hello/:name', function(req, res)
    print('GET /hello/:name')
    res:send(string.format('Hello %s', req.params.name))
end)

-- define a POST endpoint expecting a json body
server:post('/hello', function(req, res)
    print('POST /hello')
    if req.body.name == nil then
        res:status(404):sent()
        return
    end
    local content = string.format('Hello %s', req.body.name)
    res:send(content)
end)

-- define a GET endpoint, expecting query params
server:get('/hello', function(req, res)
    if req.url.query.name == nil then
        res:status(404):sent()
        return
    end
    res:send(string.format('Hello %s!', req.url.query.name))
end)

-- open the server's socket on port 8080
server:listen(8080)

-- Run the server forever, this will block the application
-- from exiting.
server:run()
