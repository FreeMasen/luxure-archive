local Server = require 'luxure.server'.Server
local mocks = require 'spec.mock_socket'
describe('Server', function()
    it('Should handle requests', function()
        local s = assert(Server.new(mocks.MockModule.new({{
            {'GET / HTTP/1.1'}
        }})))
        s:listen(8080)
        local called = false
        s:get('/', function(req, res)
            called = true
        end)
        s:tick()
        assert(called)
    end)
    it('should call middleware and handle requests', function()
        local s = assert(Server.new(mocks.MockModule.new({{
            {'GET / HTTP/1.1'}
        }})))
        s:listen(8080)
        local called = false
        local called_middleware = false
        s:use(function(req, res, next)
            called_middleware = true
            next.fn(req, res, next.next)
        end)
        s:get('/', function(req, res)
            called = true
        end)
        s:tick()
        assert(called)
        assert(called_middleware)
    end)
    it('should call a middleware chain and handle requests', function()
        local s = assert(Server.new(mocks.MockModule.new({{
            {'GET / HTTP/1.1'}
        }})))
        s:listen(8080)
        local called = false
        local middleware_call_count = 0
        for i=1,10,1 do
            s:use(function(req, res, next)
                middleware_call_count = middleware_call_count + 1
                next.fn(req, res, next.next)
            end)
        end
        s:get('/', function(req, res)
            called = true
        end)
        s:tick()
        assert(called)
        assert(middleware_call_count == 10)
    end)
end)
