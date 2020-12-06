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
        ---@type Router
        router = Router.new(),
        ---@type fun(req:Request,res:Response)
        middleware = nil,
        ---@type string
        ip = '0.0.0.0',
        ---@type string
        env = opts.env or 'production',
        ---@type number
        backlog = opts.backlog,
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
---@param port number|nil If provided, the port this server will attempt to bind on
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

---Register some middleware to be use for each request
---@param middleware fun(req:Request, res:Response, next:fun(res:Request, res:Response))
function Server:use(middleware)
    if self.middleware == nil then
        ---@type fun(req:Request,res:Response)
        self.middleware = function (req, res)
            self.router.route(self.router, req, res)
        end
    end
    ---@type fun(req:Request,res:Response)
    local next = self.middleware
    ---@type fun(req:Request,res:Response)
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
        self.router:route(req, res)
    end
end

---A single step in the Server run loop
---which will call `accept` on the underlying socket
---and when that returns a client socket, it will
--attempt to route the Request/Response objects through
--the registered middleware and reoutes
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
            print(req.err)
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
---Add a ACL endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
function Server:acl(route, handler)end
---Add a BIND endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
function Server:bind(route, handler)end
---Add a CHECKOUT endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
function Server:checkout(route, handler)end
---Add a CONNECT endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
function Server:connect(route, handler)end
---Add a COPY endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
function Server:copy(route, handler)end
---Add a DELETE endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
function Server:delete(route, handler)end
---Add a GET endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
function Server:get(route, handler)end
---Add a HEAD endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
function Server:head(route, handler)end
---Add a LINK endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
function Server:link(route, handler)end
---Add a LOCK endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
function Server:lock(route, handler)end
---Add a M-SEARCH endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
function Server:m_search(route, handler)end
---Add a MERGE endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
function Server:merge(route, handler)end
---Add a MKACTIVITY endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
function Server:mkactivity(route, handler)end
---Add a MKCALENDAR endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
function Server:mkcalendar(route, handler)end
---Add a MKCOL endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
function Server:mkcol(route, handler)end
---Add a MOVE endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
function Server:move(route, handler)end
---Add a NOTIFY endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
function Server:notify(route, handler)end
---Add a OPTIONS endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
function Server:options(route, handler)end
---Add a PATCH endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
function Server:patch(route, handler)end
---Add a POST endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
function Server:post(route, handler)end
---Add a PROPFIND endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
function Server:propfind(route, handler)end
---Add a PROPPATCH endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
function Server:proppatch(route, handler)end
---Add a PURGE endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
function Server:purge(route, handler)end
---Add a PUT endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
function Server:put(route, handler)end
---Add a REBIND endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
function Server:rebind(route, handler)end
---Add a REPORT endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
function Server:report(route, handler)end
---Add a SEARCH endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
function Server:search(route, handler)end
---Add a SUBSCRIBE endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
function Server:subscribe(route, handler)end
---Add a TRACE endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
function Server:trace(route, handler)end
---Add a UNBIND endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
function Server:unbind(route, handler)end
---Add a UNLINK endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
function Server:unlink(route, handler)end
---Add a UNLOCK endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
function Server:unlock(route, handler)end
---Add a UNSUBSCRIBE endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
function Server:unsubscribe(route, handler)end

for _, method in ipairs(methods) do
    local subbed = string.lower(string.gsub(method, '-', '_'))
    Server[subbed] = function(self, path, callback)
        self.router:register_handler(path, method, callback)
    end
end

return {
    Server = Server,
}
