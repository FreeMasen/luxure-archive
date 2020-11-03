local socket = require 'socket'
local lux = require 'luxure'

local server = lux.Server.new(socket)
server:get('/', function(req, res)
    res.send('Hello world!')
end)

server:get('/:name', function(req, res)
    res.send(string.format('Hello %s', req.params.name))
end)

server:listen(8080)

server:run()
