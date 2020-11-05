local Router = require 'luxure.router'.Router
local Request = require 'luxure.request'.Request
local Response = require 'luxure.response'.Response
local methods = require 'luxure.methods'

---@class Server
---@field socket_mod table socket module being used by the server
---@field router Router The router for incoming requests
---@field middleware table List of middleware callbacks
---@field ip string defaults to '0.0.0.0'
local Server = {}

Server.__index = Server

---Constructor for a Server
---@param socket_mod table This should look something like luasocket
function Server.new(socket_mod)
    print('Server.new')
    local base = {
        socket_mod = socket_mod,
        router = Router.new(),
        middleware = nil,
        ip = '0.0.0.0',
    }
    setmetatable(base, Server)
    return base
end
---Override the default IP address
---@param ip string
function Server:set_ip(ip)
    self.ip = ip
end
---Attempt to open a socket
---@param port number If provided, the port this server will attempt to bind on
function Server:listen(port)
    if port == nil then
        port = 0
    end
    self.sock = self.socket_mod.bind(self.ip, port);
end

for _, method in ipairs(methods) do
    local subbed = string.lower(string.gsub(method, '-', '_'))
    Server[subbed] = function(self, path, callback)
        self.router:register_handler(path, method, callback)
    end
end

function Server:use(middleware)
    local next = self.middleware or {
        fn = function(req, res)
            self.router:route(req, res)
        end,
    }
    self.middleware = {
        fn = middleware,
        next = next,
    }
end

function Server:route(req, res)
    local handled
    if self.middleware then
        handled = self.middleware.fn(req, res, self.middleware.next)
    else
        handled = self.router:route(req, res)
    end
    return handled
end

---A single step in the Server run loop
function Server:tick()
    local incoming = assert(self.sock:accept())
    local req = Request.new(incoming)
    local res = Response.new(incoming)
    local success = pcall(self.route, self, req, res)
    if not success then
        local r, s, a = incoming:getstats()
        if s == 0 then
            res:status(500)
            res:send()
        end
    end
    incoming:close()
end
---Start this server, blocking forever
function Server:run()
    while true do
        self:tick()
    end
end

return {
    Server = Server,
}