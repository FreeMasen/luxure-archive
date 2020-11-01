local Layer = require 'luxure.layer'
local utils = require 'luxure.utils'
local net_url = require 'net.url'

---@class Route
---
--- A single instance of a route
---@field path string raw string that comprises this path
---@field segments table list of ids or path segments, each segment may be a parameter if preceded by a :
---@field vars table list of variables that will be parsed from the segments field
---@field methods table list of callbacks registered to a method/path pair
local Route = {}

Route.__index = Route

---construct a new Route parsing any route parameters in the process
---@param path string
function Route.new(path)
    local url = net_url.parse(path)
    url.segments = {}
    url.methods = {}
    local i = 1
    for part in string.gmatch(url.path, "[^/]+") do
        local val = {
            id = part,
            is_var = false,
        }
        local _s, _e, var = string.find(part, "^:(.+)")
        if var ~= nil then
            val.id = var
            val.is_var = true
        end
        table.insert(url.segments, val)
        i = i + 1
    end
    setmetatable(url, Route)
    return url
end

function Route:_handles_method(method)
    return self.methods[method] ~= nil
end

function Route:matches(path)
    local params = {}
    local i = 1
    for part in string.gmatch(path, "[^/]+") do
        local segment = self.segments[i]
        if segment == nil then
            return false
        end
        if segment.is_var then
            params[segment.id] = part
        elseif segment.id ~= part then
            return false
        end
        i = i + 1
    end
    return true, params
end

return {
    Route = Route,
}
