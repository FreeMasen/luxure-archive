local Router = require 'luxure.router'.Router
local Request = require 'luxure.request'.Request
local Response = require 'luxure.response'.Response
local methods = require 'luxure.methods'
local Error = require 'luxure.error'.Error
local cosock = require "cosock"

---@alias handler fun(req: Request, res: Response)

---@class Server
---
---The primary interface for working with this framework
---it can be used to register middleware and route handlers
---@field private sock table socket being used by the server
---@field public router Router The router for incoming requests
---@field private middleware table List of middleware callbacks
---@field public ip string defaults to '0.0.0.0'
---@field private env string defaults to 'production'
---@field private backlog number|nil defaults to nil
---@field private async boolean If the server should spawn a cosock runtime and task for each incoming request
local Server = {}

Server.__index = Server

---@class Opts
---
---The options a server knows about
---@field public env string 'debug'|'production' if debug, more information is provided on errors
---@field public backlog number The number to pass to `socket:listen`
local Opts = {}
Opts.__index = Opts

---Create a new options object
---@param t table|nil If not the pre-set options
---@return Opts
function Opts.new(t)
    t = t or {}
    return setmetatable({
        backlog = t.backlog,
        env = t.env or 'production',
        sync = t.sync,
    }, Opts)
end

---Set the backlog property
---@param backlog number
---@return Opts
function Opts:set_backlog(backlog)
    self.backlog = backlog
    return self
end

---Set the env property
---@param env string 'production'|'debug' The env string
---@return Opts
function Opts:set_env(env)
    self.env = env
    return self
end

---Constructor for a Server that will use luasocket's socket
---implementation
---@param opts Opts The configuration of this Server
function Server.new(opts)
    local sock = cosock.socket.tcp()
    return Server.new_with(sock, opts)
end

---Constructor for a Server that will use the provided socket
---this is useful for using an alternative implementation of sockets
---@param sock table This should have an api similar to luasocket's socket type
---@param opts Opts The configuration of this Server
function Server.new_with(sock, opts)
    opts = opts or Opts.new()
    local base = {
        sock = sock,
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
        _sync = opts.sync,
    }
    return setmetatable(base, Server)
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
    assert(self.sock:bind(self.ip, port or 0))
    self.sock:listen(self.backlog)
    local ip, resolved_port = self.sock:getsockname()
    self.ip = ip
    self.port = resolved_port
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
    local next = self.middleware
    self.middleware = function(req, res)
        local success, err = Error.pcall(middleware, req, res, next)
        if not success then
            req.err = req.err or err
            res:status(err.status)
        end
    end
end

---Route a request, first through any registered middleware
---followed by any registered handler
---@param req Request
---@param res Response
function Server:route(req, res)
    if self.middleware then
        self.middleware(req, res)
    else
        self.router:route(req, res)
    end
end

---generate html for error when in debug mode
---@param err Error
local function debug_error_body(err)
    local code = err.status or '500'
    local h2 = err.msg_with_line or 'Unknown Error'
    local pre = err.traceback or ''
    return string.format([[<!DOCTYPE html>
<html>
    <head>
    </head>
    <body>
        <h1>Error processing request: <code> %s </code></h1>
        <h2>%s</h2>
        <pre>%s</pre>
    </body>
</html>
    ]], code, h2, pre)
end

local function error_request(env, err, res)
    if res:has_sent() then
        print('error sending after bytes have been sent...')
        print(err)
        return
    end
    if env == 'production' then
        res:send(err.msg or '')
        return
    end
    res:content_type('text/html'):send(debug_error_body(err))
    return
end

function Server:_tick(incoming)
    local req, req_err = Request.new(incoming)
    if req_err then
        return nil, req_err
    end
    local res = Response.new(incoming)
    self:route(req, res)
    local has_sent = res:has_sent()
    if req.err then
        error_request(self.env, req.err, res)
    elseif not req.handled then
        if not has_sent then
            res:status(404):send('')
        end
    end
    if res.should_close then
        res:close()
    end
    return 1
end

---A single step in the Server run loop
---which will call `accept` on the underlying socket
---and when that returns a client socket, it will
---attempt to route the Request/Response objects through
---the registered middleware and routes
function Server:tick()
    local incoming = Error.assert(self.sock:accept())
    if not self._sync then
        cosock.spawn(
            function() self:_tick(incoming) end,
            string.format('Accepted request ptr: %s', incoming)
        )
    else
        self:_tick(incoming)
    end
end

function Server:_run(err_callback)
    while true do
        local success, msg = self:tick()
        if not success then
            if not err_callback(msg) then
                return
            end
        end
    end
end
---Start this server, blocking forever
---@param err_callback fun(msg:string):boolean Optional callback to be run if `tick` returns an error
function Server:run(err_callback)
    err_callback = err_callback or function () return true end
    if not self._sync then
        cosock.spawn(function()
            self:_run(err_callback)
        end, 'luxure-main-loop')
        cosock.run()
    else
        self:_run(err_callback)
    end
end

---Add a ACL endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
--luacheck: no unused args
function Server:acl(route, handler)end
---Add a BIND endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
--luacheck: no unused args
function Server:bind(route, handler)end
---Add a CHECKOUT endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
--luacheck: no unused args
function Server:checkout(route, handler)end
---Add a CONNECT endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
--luacheck: no unused args
function Server:connect(route, handler)end
---Add a COPY endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
--luacheck: no unused args
function Server:copy(route, handler)end
---Add a DELETE endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
--luacheck: no unused args
function Server:delete(route, handler)end
---Add a GET endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
--luacheck: no unused args
function Server:get(route, handler)end
---Add a HEAD endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
--luacheck: no unused args
function Server:head(route, handler)end
---Add a LINK endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
--luacheck: no unused args
function Server:link(route, handler)end
---Add a LOCK endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
--luacheck: no unused args
function Server:lock(route, handler)end
---Add a M-SEARCH endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
--luacheck: no unused args
function Server:m_search(route, handler)end
---Add a MERGE endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
--luacheck: no unused args
function Server:merge(route, handler)end
---Add a MKACTIVITY endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
--luacheck: no unused args
function Server:mkactivity(route, handler)end
---Add a MKCALENDAR endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
--luacheck: no unused args
function Server:mkcalendar(route, handler)end
---Add a MKCOL endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
--luacheck: no unused args
function Server:mkcol(route, handler)end
---Add a MOVE endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
--luacheck: no unused args
function Server:move(route, handler)end
---Add a NOTIFY endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
--luacheck: no unused args
function Server:notify(route, handler)end
---Add a OPTIONS endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
--luacheck: no unused args
function Server:options(route, handler)end
---Add a PATCH endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
--luacheck: no unused args
function Server:patch(route, handler)end
---Add a POST endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
--luacheck: no unused args
function Server:post(route, handler)end
---Add a PROPFIND endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
--luacheck: no unused args
function Server:propfind(route, handler)end
---Add a PROPPATCH endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
--luacheck: no unused args
function Server:proppatch(route, handler)end
---Add a PURGE endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
--luacheck: no unused args
function Server:purge(route, handler)end
---Add a PUT endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
--luacheck: no unused args
function Server:put(route, handler)end
---Add a REBIND endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
--luacheck: no unused args
function Server:rebind(route, handler)end
---Add a REPORT endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
--luacheck: no unused args
function Server:report(route, handler)end
---Add a SEARCH endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
--luacheck: no unused args
function Server:search(route, handler)end
---Add a SUBSCRIBE endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
--luacheck: no unused args
function Server:subscribe(route, handler)end
---Add a TRACE endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
--luacheck: no unused args
function Server:trace(route, handler)end
---Add a UNBIND endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
--luacheck: no unused args
function Server:unbind(route, handler)end
---Add a UNLINK endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
--luacheck: no unused args
function Server:unlink(route, handler)end
---Add a UNLOCK endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
--luacheck: no unused args
function Server:unlock(route, handler)end
---Add a UNSUBSCRIBE endpoint
---@param route string
---@param handler fun(req:Request, res:Response)
--luacheck: no unused args
function Server:unsubscribe(route, handler)end

for _, method in ipairs(methods) do
    local subbed = string.lower(string.gsub(method, '-', '_'))
    Server[subbed] = function(self, path, callback)
        self.router:register_handler(path, method, callback)
    end
end

return {
    Server = Server,
    Opts = Opts,
}
