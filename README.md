# Luxure

![Codecov](https://img.shields.io/codecov/c/github/freemasen/luxure)
![GitHub Workflow Status](https://img.shields.io/github/workflow/status/freemasen/luxure/CI)
![LuaRocks](https://img.shields.io/luarocks/v/FreeMasen/luxure)

![Luxure Logo](./luxure.svg)

An HTTP Server framework for Lua

## Usage

```lua
local dkjson = require 'dkjson'
local lux = require 'luxure'

-- Create a server with the options
local server = lux.Server.new(lux.Opts.new({env = 'debug'}))

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
    next(req, res)
end)

-- Use a middleware that will emulate nginx logging
server:use(function (req, res, next)
    local start = os.time()
    local remote = req.socket:getpeername()
    next(req, res)
    local request = string.format('%s %s %s', req.method, req.url.path, req.http_version)
    local _, sent, _ = req.socket:getstats()
    print(
        string.format('%s - %s - [%s] "%s" %i %i "%s" "%s"',
            remote,
            req.url.user or '',
            os.date('%Y-%m-%dT%H:%M:%S%z', start),
            request,
            res:status(),
            sent,
            req:get_headers().referrer or '-',
            req:get_headers().user_agent or '-'
    ))
end)

-- define a root GET endpoint
server:get('/', function(req, res)
    print('GET /')
    res:send('Hello world!')
end)

-- This endpoint will always return 500
server:get('/fail', function()
    print('GET /fail')
    -- using Error.assert from luxure, you will automatically
    -- generate the correctly formatted error to automatically
    -- return 500 to the caller and set your message as the body.
    -- if you were to set the environment variable `LUXURE_ENV`
    -- to a value other than 'production' and it will also send
    -- the origial file/line number and the backtrace from the error
    lux.Error.assert(false, 'I always fail')
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
    -- You can also pass an optional status code to this custom assert
    -- that will automatically set the reply status to that
    lux.Error.assert(req.body.name, 'name is a required variable', 417)
    local content = string.format('Hello %s', req.body.name)
    res:send(content)
end)

-- define a GET endpoint, expecting query params
server:get('/hello', function(req, res)
    if req.url.query.name == nil then
        res:set_status(404):send()
        return
    end
    res:send(string.format('Hello %s!', req.url.query.name))
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
