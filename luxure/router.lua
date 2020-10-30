local Layer = require 'luxure.layer'
local percent_decode = require 'luxure.utils'.percent_decode
local resty_url = require 'resty.url'

---@class Route
---
--- A single instance of a route
---@field path string raw string that comprises this path
---@field segments table list of ids or path segments, each segment may be a parameter if preceded by a :
---@field vars table list of variables that will be parsed from the segments field
local Route = {}

Route.__index = Route

Route.mt.__eq = function (lhs,rhs)
    Route.matches(lhs, rhs)
end

---construct a new Route parsing any route parameters in the process
---@param path string
function Route.new(path)
    local base = {
        path = path,
        stack = {},
        methods = {}
    }
    
    setmetatable(base, Route)
    return base
end
function Route:_handles_method(method)
    if self.methods.all ~= nil then
        return true
    end
    local name = method:lower()
    if name == 'head' and self.methods.head == nil then
        name = 'get'
    end
    return self.methods[name] ~= nil
end
---parse query parameters
---@param url string
function Route.parse_query(url)
    local s, _e, params = string.find(url, "?(.+)")
    if params == nil then
        return url, nil
    end
    local ret = {}
    for key, value in string.gmatch(params, "(.+)=(.+)&?") do
        ret[key] = percent_decode(string.gsub(value, '+', '%20'))
    end
    return string.sub(url, 1, s), ret
end

function Route:_options()
    local ret = {}
    if self.methods.get ~= nil and self.methods.head == nil then
        table.insert(ret, 'HEAD')
    end
    for key in pairs(self.methods) do
        table.insert(ret, string.upper(key))
    end
    return ret
end

function Route:dispatch(req, res, done)
    local idx = 0;
    local stack = self.stack;
    if (#stack == 0) then
        return done();
    end

    local method = req.method:lower();
    if (method == 'head' and self.methods['head'] == nil) then
        method = 'get'
    end

    req.route = self;

    local function next(err)
        -- signal to exit route
        if (err and err == 'route') then
            return done();
        end

        -- signal to exit router
        if (err and err == 'router') then
            return done(err)
        end

        local layer = stack[idx];
        idx = idx + 1
        if (layer == nil) then
            return done(err);
        end

        if (layer.method and layer.method ~= method) then
            return next(err);
        end

        if (err) then
            layer:handle_error(err, req, res, next);
        else
            layer:handle_request(req, res, next);
        end
    end
    next()
end


local function flatten(t, out)
    local ret = out or {}
    for _, v in ipairs(t) do
        if type(v) == 'table' then
            flatten(v, ret)
        else
            table.insert(ret, v)
        end
    end
    return ret
end

function Route:all(...)
    local handles = flatten(arg)
    for _, handle in ipairs(handles) do
        assert(type(handle) == 'function', string.format('Route.all() requires a callback function but got a %s', type(handle)))
        local layer = Layer.new('/', {}, handle)
        layer.method = nil
        self._all = true
        table.insert(self.stack, handle)
    end
    return self
end
local methods = {
    'ACL',
    'BIND',
    'CHECKOUT',
    'CONNECT',
    'COPY',
    'DELETE',
    'GET',
    'HEAD',
    'LINK',
    'LOCK',
    'M-SEARCH',
    'MERGE',
    'MKACTIVITY',
    'MKCALENDAR',
    'MKCOL',
    'MOVE',
    'NOTIFY',
    'OPTIONS',
    'PATCH',
    'POST',
    'PROPFIND',
    'PROPPATCH',
    'PURGE',
    'PUT',
    'REBIND',
    'REPORT',
    'SEARCH',
    'SUBSCRIBE',
    'TRACE',
    'UNBIND',
    'UNLINK',
    'UNLOCK',
    'UNSUBSCRIBE',
}

for _, method in methods do
    Route[string.lower(string.gsub(method, '-', '_'))] = function(self, ...)
        local handles = flatten(arg);

        for _, handle in ipairs(handles) do
            assert(type(handle) == 'function', string.format('Route.%s() requires a callback function but got a %s', method, type(handle)))

            local layer = Layer('/', {}, handle);
            layer.method = method;

            self.methods[method] = true;
            table.insert(self.stack, layer);
        end

        return self
    end
end

local function parse_url(req)
    if req._url ~= nil then
        return req._url
    end
    local url, err = resty_url.parse(req.url or '')
    if err then
        return nil, err
    end
    req._url = url
    return url
end

local function get_path_name(req)
    local url, err = parse_url(req)
    if err then
        return nil, err
    end
    return url.path
end

local function get_proto_host(url)
    if type(url) ~= 'string'
    or #url == 0
    or string.sub(1, 1) == '/' then
        return nil
    end
    local path_length = #url
    local search_index = string.find(url, '?')
    if search_index ~= nil then
        path_length = search_index
    end

    local fqdn_index = string.find(string.sub(url, 0, path_length), '://')
    if fqdn_index ~= nil then
        local end_idx = string.find(url, '/', fqdn_index + 3) or 0
        return string.sub(url, 1, end_idx - 1)
    end
end


local function match_layer(layer, path)
    local success, err_or_bool = pcall(layer.match(path))
    if success then
        return err_or_bool
    end
    return nil, err_or_bool
end
  
--   // get type for error message
--   function gettype(obj) {
--     var type = typeof obj;
  
--     if (type !== 'object') {
--       return type;
--     }
  
--     // inspect [[Class]] for objects
--     return toString.call(obj)
--       .replace(objectRegExp, '$1');
--   }

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

function Router:param(name, fn)
    -- param logic
    -- apply param functions
    local params = self._params
    local len = #params
    local ret
    for i, param in ipairs(params) do
        local res = param(name, fn)
        if res then
            ret = res
            fn = res
        end

    end
    assert(type(fn) == 'function', string.format('invalid pararms() call for %s, got %s', name, fn))
    self.params[name] = (self.params[name] or {})
    table.insert(self.params[name], fn)
    return self
end

-- possible semantic issue here around `this`
-- may need to add caller argument to, also
-- `arguments` may need some attention
local function wrap(old, fn)
    return function(...)
        fn(old, ...)
    end
end

local function restore(caller, fn, obj, ...)
    local args = arg
    local props = {}
    local vals = {}
    for i in ipairs(args) do
        props[i] = arg[i]
        vals[i] = obj[props[i]]
    end
    return function()
        for i, val in ipairs(vals) do
            obj[props[i]] = val
        end
        return fn(caller, fn, obj, table.unpack(args))
    end
end

local function merge_params(params, parent_params)
    if type(parent_params) ~= 'table' then
        return params
    end
    assert(false, 'not yet implemented')
end

local function send_options_response(res, optsions, next)
    assert(false, 'not yet implemented')
end

function Router:handle(req, res, out)
    local idx = 0
    local proto_host = get_proto_host(req.url) or ''
    local removed = ''
    local slash_added = false
    local param_called = {}

    local options = {}
    local stack = self.stack

    local parent_params = req.params

    local parent_url = req.base_url
    req.base_url = parent_url
    req.original_url = req.original_url or req.url

    local done = restore(self, out, req, 'base_url', 'next', 'params')
    if req.method == 'OPTIONS' then
        -- for options requests, respond with a default if nothing else responds
        done = wrap(done, function(old, err)
            if err or #options == 0 then
                return old(err)
            end
            send_options_response(res, options, old);
        end);
    end

    local function next(err)
        local function trim_prefix(layer, layer_error, layer_path, path)
            if #layer_path ~= 0 then
                local c = path[#layer_path]
                if c and c ~= '/' and c ~= '.' then
                    return next(layer_error)
                end
                removed = layer_path
                req.url = proto_host .. string.sub(req.url, #proto_host + #removed)
                if not proto_host and string.sub(req.url, 1, 1) ~= '/' then
                    req.url = '/' .. req.url
                    slash_added = true
                end
    
                req.base_url = parent_url
                if string.sub(removed, #removed, #removed) == '/' then
                    req.base_url = req.base_url .. string.sub(removed, 1, -2)
                else
                    req.base_url = req.base_url .. removed
                end
            end
            if layer_error then
                layer.handle_error(layer_error, req, res, next)
            else
                layer.handle_request(req, res, next)
            end
        end
        local layer_error
        if err == 'route' then
            layer_error = err
        end
        if slash_added then
            req.url = string.sub(req.url, 2)
            slash_added = false
        end
        if #removed > 0 then
            req.base_url = parent_url
            req.url = proto_host .. removed .. string.sub(req.url, #proto_host)
            removed = ''
        end
        if layer_error == 'router' then
            done()
        end
        if idx >= #stack then
            done(layer_error)
        end
        local path = get_path_name(req)
        if path == nil then
            done(layer_error)
        end
        local layer
        local match
        local route
        while (match ~= true and idx < #stack) do

            layer = stack[idx]
            idx = idx + 1
            local m, match_err = match_layer(layer, path)
            route = layer.route
            if match_err ~= nil then
                layer_error = layer_error or match_err
            else
                match = m
            end
            if match ~= true then
                goto loop_bottom
            end
            if not route then
                goto loop_bottom
            end
            if layer_error then
                match = false
                goto loop_bottom
            end
            local method = req.method
            local has_method = req._handles_method(method)

            if not has_method and method == 'OPTIONS' then
                append_methods(options, route._options());
            end
            if not has_method and method ~= 'HEAD' then
                match = false
                goto loop_bottom
            end

            ::loop_bottom::
        end

        if match ~= true then
            return done(layer_error)
        end


        if route then
            req.route = route
        end

        if self.merge_params then
            req.params = merge_params(layer.params, parent_params)
        else
            req.params = layer.params
        end

        local layer_path = layer.path
        self:process_params(layer, param_called, req, res, function(err)
            if err then
                return next(layer_error or err)
            end
            if route then
                return layer.handle_request(req, res, next)
            end

            trim_prefix(layer, layer_error, layer_path, path)
        end)
    end
    req.next = next
    next()

end

function Router:process_params(layer, called, req, res, done)
    local params = self.params
    local keys = layer.keys
    if not keys or #keys == 0 then
        return done()
    end
    local i = 0
    local name
    local param_idx = 0
    local key
    local param_val
    local param_callbacks
    local param_called

    local function param(err)
        local function param_callback(err)
            local fn = param_callbacks[param_idx]
            param_idx = param_idx + 1

            param_called.value = req.params[key.name]
            if err then
                param_called.errorr = err
                param(err)
                return
            end
            if not fn then
                return param()
            end
            local success, msg = pcall(fn(req, res, param_callback, param_val, key.name))
            if not success then
                param_callback(msg)
            end
        end

        if err then
            return done(err)
        end
        if i >= #keys then
            return done()
        end
        param_idx = 0
        key = keys[i]
        i = i + 1
        name = key.name
        param_val = req.params[name]
        param_callbacks = params[name]
        param_called = called[name]
        if param_val == nil or not param_callbacks then
            return param()
        end
        if param_called
        and (param_called.match == param_val
            or param_called.error
            and param_called.error ~= 'route')
        then
            req.param[name] = param_called.value
            return param(param_called.error)
        end
        param_called = {
            error = nil,
            match = param_val,
            value = param_val
        }
        called[name] = param_called
        param_callback()
    end

    param()
end

function Router:use(fn, ...)
    local offset = 0
    local path = '/'
    local args = arg
    if type(fn) ~= 'function' then
        local a = fn
        while type(a) == 'table' and #a ~= 0 do
            a = table.remove(a, 1)
        end
        if type(a) ~= 'function' then
            table.insert(args, 1)
        end
    end

    local callbacks = flatten(args)
    assert(#callbacks > 0, 'Router.use requires a middleware function')
    for _, f in ipairs(callbacks) do
        assert(type(f) == 'function', 'Router.use requires a middleware function')
        local layer = Layer.new(path, {
            sensitive = self.case_sensitive,
            strict = false,
            ['end'] = false
        }, f)
        layer.route = nil
        table.insert(self.stack, layer)
    end
    return self
end

function Router:route(path)

end

function set_method(method)
    Router[method] = function(self, path, ...)
        local route = self:route(path)
        route[method].route(table.unpack(arg))
        return self
    end
end
set_method('all')
for _, method in pairs(methods) do
    set_method(method)
end

local function append_methods(list, add)
    local set = {}
    for _, method in ipairs(list) do
        set[method] = true
    end
    for _, method in ipairs(add) do
        if set[method] == nil then
            table.insert(list, method)
        end
    end
end


function Router:register_handler(path, method, callback)
    if self.handlers[path] == nil then
        self.handlers[path] = {
            method = callback
        }
    else
        self.handlers[path][method] = callback
    end
end


return {
    Route = Route,
    Router = Router,
}
