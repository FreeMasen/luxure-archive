
---@class Route
---
--- A single instance of a route
---@field path string raw string that comprises this path
---@field segments table list of ids or path segments, each segment may be a parameter if preceded by a :
---@field vars table list of variables that will be parsed from the segments field
local Route = {}

Route.mt.__eq = function (lhs,rhs)
    Route.matches(lhs, rhs)
end

---construct a new Route parsing any route parameters in the process
---@param path string
function Route.new(path)
    local base = {
        path = path,
        segments = {},
        vars = {},
    }
    local i = 0
    for part in string.gmatch(path, "/") do
        local val = {
            id = part,
            is_var = false,
        }
        local _s, _e, var = string.find(part, "^:(.+)")
        if var ~= nil then
            val.id = var
            val.is_var = true
        end
        table.insert(base.segments, val)
        base.vars[i] = var or val
        i = i + 1
    end
    setmetatable(base, Route)
    return base
end
---parse query parameters
---
---note: parameters will not be url decoded
---@param url string
function Route.parse_query(url)
    local s, _e, params = string.find(url, "?(.+)")
    if params == nil then
        return url, nil
    end
    local ret = {}
    for key, value in string.gmatch(params, "(.+)=(.+)&?") do
        ret[key] = value
    end
    return string.sub(url, 1, s), ret
end

--- Check if this route matches the provided path
--- it is important that this does not include
--- any possible query parameters, which would fail
--- to match on the last path entry
---
--- if successfully matched, a params table is returned
--- as the second return value
---
---@param path string the raw path to check against
---@returns boolean, table
function Route:matches(path)
    local params = {}
    local i = 0
    for part in string.gmatch(path, "/") do
        local segment = self.segments[i]
        if segment == nil then
            return false
        end
        if segment.is_var then
            params[segment.id] = part
        else
            if segment.id ~= part then
                return false
            end
        end
        i = i + 1
    end
    return true, params
end

local Router = {}

function Router.new()
    return setmetatable({
        handlers = {}
    }, Router)

end

function Router:register_handler(path, method, callback)
    if self.handlers[route] == nil then
        self.handlers[route] = {
            method = callback
        }
    else
        self.handlers[route][method] = callback
    end
end


return {
    Route = Route,
    Router = Router,
}
