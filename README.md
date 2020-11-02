# Luxure

An HTTP Server framework for Lua

## Usage

```lua
-- import a module that provides the api of luasocket
local socket = require 'socket'
local luxure = require 'luxure'
-- pass in the socket module you'd like to use here
local server = luxure.Server.new(socket)

-- use some middleware for parsing json bodies
server:use(function(req, next)
    if req.headers.content_type == 'application/json' then
        req.body = dkjson.parse(req.body)
    end
    next(req)
end)

-- define a root GET endpoint
server:get('/', function(req, res) 
    res:send('Hello World!')
end)

-- define a POST endpoint
server:post('/hello', function(req, res)
    assert(
        req.headers.content_type == 'application/json' and req.body.name,
        'POST /hello must provide a json body with a name property'
    )
    res:send(string.format('Hello %s!', req.body.name))
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
-- from exiting. The callback provided will be called
-- after successfully binding to the ip/port provided in
-- `new` above
server:run(function(ip, port)
    print(string.format('Listening on %s:%s', ip, port))
end)
```

## Contributing

There is still lots of work to do, feel free to open a pull request with any contribution you'd like to make
or Issue with a bug you have identified.

If you'd like to take on an Issue, please make a comment on that issue to avoid duplicated work.

As always with free software people are working on in their free time, please be understanding
if things take a while to get a response.
