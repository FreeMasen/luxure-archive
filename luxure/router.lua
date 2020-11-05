local Route = require 'luxure.route'.Route
---@class Router
---@field routes table List of Routes registered
local Router = {}

Router.__index = Router

function Router.new()
    local base = {
        routes = {},
    }
    setmetatable(base, Router)
    return base
end
---Dispatch a request to the approparte Route
---@param self Router
---@param req Request
---@param res Response
function Router:route(req, res)
    for _, route in pairs(self.routes) do
        local matched, params = route:matches(req.url)
        if matched and route:handles_method(req.method) then
            req.params = params
            route:handle(req, res)
            return true
        end
    end

    local r, s, a = res.outgoing:getstats()
    if s == 0 then
        res:status(404)
        res:send()
    end
    return false
end
---Register a single route
---@param self Router
---@param path string The route for this request
---@param method string the HTTP method for this request
---@param callback function(luxure.request.Request, luxure.response.Response) The callback this route will use to handle requests
function Router:register_handler(path, method, callback)
    if self.routes[path] == nil then
        self.routes[path] = Route.new(path)
    end
    self.routes[path].methods[method] = callback
end


return {
    Router = Router,
}
