local dkjson = require 'dkjson'
local lux = require 'luxure'
local cosock = require "cosock"

-- Create a server with the options
local server = lux.Server.new(
    lux.Opts.new()
        :set_env('debug') -- debug html on 500s
)

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
            res._status,
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
    -- the original file/line number and the backtrace from the error
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
        res:status(404):send()
        return
    end
    res:send(string.format('Hello %s!', req.url.query.name))
end)

server:get('/dynamic', function(req, res)
    res:content_type('text/html'):send([[<!DOCTYPE html>
<html>
<head>
</head>
<body>
<h1>Dynamic !</h1>
<ul id="list">
</ul>
<script>
(function() {
    let ul = document.getElementById('list')
    let s = new EventSource('/sse')
    function li(text) {
        let ele = document.createElement('li');
        let node = document.createTextNode(text);
        ele.appendChild(node);
        return ele;
    }
    s.onmessage = function(ev) {
        let text = `${new Date()} ${ev.data}`;
        let node = li(text);
        ul.appendChild(node);
    }
    s.onerror = function(ev) {
        console.error(ev);
        console.error(ev.message);
        let text = `${new Date()} Error in event stream`;
        let node = li(text);
        ul.appendChild(node);
    }
    s.addEventListener('clear', function(ev) {
        while (ul.hasChildNodes()) {
            ul.removeChild(ul.firstChild);
        }
    });
    setTimeout(function() {
        s.close()
    }, 1000 * 60)
    
})()
</script>
</body>
</html>
]])
end)

server:get('/sse', function(req, res)
    print('sse')
    local socket = cosock.socket;
    local sse = require 'luxure.sse'
    local stream = sse.Sse.new(res, 4)
    local wait = 5
    local err
    while true do
        print('sending event with wait', wait)
        if wait == 0 then
            _, err = stream:send(sse.Event.new():event('clear'):data('clearing'))
            wait = 5
        else
            _, err = stream:send(sse.Event.new():data(string.format('next tick in %s', wait)))
            socket.sleep(wait)
        end
        if err then
            print('error in sse, exiting', err)
            break
        end
        if wait >= 1 then
            wait = wait - 1
        end
    end
end)

server.sock:setoption('reuseaddr', true)
-- open the server's socket on port 8080
server:listen(8080)
server.sock:setoption('reuseaddr', true)
print(string.format('listening on http://%s:%s', server.sock:getsockname()))
-- Run the server forever, this will block the application
-- from exiting.
server:run()
