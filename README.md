# Luxure

An HTTP Server framework for Lua

## Usage

```lua
-- import a module that provides the api of luasocket
-- here we are actually using luasocket
local socket = require 'socket'
local luxure = require 'luxure'

-- pass in the socket module you'd like to use here
local server = luxure.Server.new(socket)

-- use some middleware for parsing json bodies
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

-- define a root GET endpoint
server:get('/', function(req, res) 
    res:send('Hello World!')
end)

-- define a POST endpoint expecting a json body
server:post('/hello', function(req, res)
    if req.body.name == nil then
        res:status(404):sent()
        return
    end
    res:send(string.format('Hello %s!', req.body.name))
end)

-- define a GET endpoint, expecting query params
server:get('/hello', function(req, res)
    if req.url.query.name == nil then
        res:status(404):sent()
        return
    end
    res:send(string.format('Hello %s!', req.body.name))
end)

-- This endpoint will always return 500
server:get('/fail', function()
    assert(false)
end)

-- define a parameterized GET endpoint, here :name will
-- be matched on any request /hello/(.+) and whatever
-- value is after /hello/ will populate `req.params.name`
server:get('/hello/:name', function(res, res)
    res:send(string.format('Hello %s!', req.params.name))
end)

-- open the server's socket on port 8080
server:listen(8080)

-- Run the server forever, this will block the application
-- from exiting.
server:run()
```

## Contributing

There is still lots of work to do, feel free to open a pull request with any contribution you'd like to make
or Issue with a bug you have identified.

If you'd like to take on an Issue, please make a comment on that issue to avoid duplicated work.

As always with free software people are working on in their free time, please be understanding
if things take a while to get a response.
