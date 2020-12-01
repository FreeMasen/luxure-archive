local Router = require 'luxure.router'.Router
local Request = require 'luxure.request'.Request
local Response = require 'luxure.response'.Response
local methods = require 'luxure.methods'
local Error = require 'luxure.error'.Error

---@class Server
---@field socket_mod table socket module being used by the server
---@field router Router The router for incoming requests
---@field middleware table List of middleware callbacks
---@field ip string defaults to '0.0.0.0'
local Server = {}

Server.__index = Server

---Constructor for a Server
---@param socket_mod table This should look something like luasocket
function Server.new(socket_mod, opts)
    opts = opts or {}
    local base = {
        socket_mod = socket_mod,
        router = Router.new(),
        middleware = nil,
        ip = '0.0.0.0',
        env = opts.env or 'production',
        backlog = opts.backlog or 5,
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
    self.sock = self.socket_mod.tcp()
    assert(self.sock:bind(self.ip, port or 0), "failed to bind")
    self.sock:listen(self.backlog)
    local ip, port = self.sock:getsockname()
    self.ip = ip
    self.port = port
end

for _, method in ipairs(methods) do
    local subbed = string.lower(string.gsub(method, '-', '_'))
    Server[subbed] = function(self, path, callback)
        self.router:register_handler(path, method, callback)
    end
end

function Server:use(middleware)
    if self.middleware == nil then
        self.middleware = function (req, res)
            self.router.route(self.router, req, res)
        end
    end
    local next = self.middleware
    self.middleware = function(req, res)
        local success, err = Error.pcall(middleware, req, res, next)
        if not success then
            req.err = req.err or err
            res:status(err.status)
        end
    end
end

function Server:route(req, res)
    if self.middleware then
        self.middleware(req, res)
    else
        self.router.route(self.router, req, res)
    end
end

---A single step in the Server run loop
function Server:tick()
    local incoming = Error.assert(self.sock:accept())
    local req = Request.new(incoming)
    local res = Response.new(incoming)
    self:route(req, res)
    local has_sent = res:has_sent()
    if req.err then
        if not has_sent then
            local msg
            if self.env == 'production' then
                if req.err.msg then
                    msg = req.err.msg
                end
            else
                if req.err.traceback then
                    msg = req.err.msg_with_line .. '\n' .. req.err.traceback
                end
            end
            res:send(msg)
        else
            print('error sending after bytes have been sent...')
            print(req.err.msg)
            if req.err.traceback then
                print(req.err.traceback)
            end
        end
    elseif not req.handled then
        if not has_sent then
            res:status(404):send('')
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
