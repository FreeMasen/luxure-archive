
local Router = {}

Router.__index = Router

function Router.new(options)
    local opts = options or {}
    local base = {
        params = {},
        _params = {},
        case_sensitive = opts.case_sensitive,
        merge_params = opts.merge_params,
        strict = opts.strict,
        stack = {}
    }
    setmetatable(base, Router)
    return base
end

function Router:route(path)

end

function Router:register_handler(path, method, callback)
    if self.handlers[path] == nil then
        self.handlers[path] = {
            [method] = callback
        }
    else
        self.handlers[path][method] = callback
    end
end


return {
    Router = Router,
}
