local percent_decode = require 'luxure.utils'.percent_decode
local Layer = {}

Layer.__index = Layer

function Layer.new(path, opts, fn)
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
    base.fast_star = path == '*'
    setmetatable(base, Layer)
    return base
end

function Layer:handle_error(err, req, res, next)
    local success, err2 = pcall(self.handle(err, req, res, next))
    if success == false then
        next(err2)
    end
end

function Layer:handle_request(req, res, next)
    local success, err = pcall(self.handle(req, res, next))
    if success == false then
        next(err)
    end
end

function Layer:match(path)
    local params = {}
    if self.fast_star then
        table.insert(params, percent_decode(path))
        return true
    end
    local i = 0
    for part in string.gmatch(path, "/") do
        part = percent_decode(part)
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
    self.params = params
    return true
end

return Layer