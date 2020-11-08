local Server = require 'luxure.server'.Server
local mocks = require 'spec.mock_socket'
local utils = require 'luxure.utils'
local Error = require 'luxure.error'.Error

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
            next(req, res)
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
                next(req, res)
            end)
        end
        s:get('/', function(req, res)
            called = true
        end)
        s:tick()
        assert(called)
        assert(middleware_call_count == 10)
    end)
    it('middleware error should return 500', function()
        local sock = {'GET / HTTP/1.1'}
        local s = assert(Server.new(mocks.MockModule.new({{
            sock
        }})))
        s:listen(8080)
        local called = false
        s:use(function(req, res, next)
            Error.assert(false, 'expected fail')
        end)
        s:get('/', function(req, res)
            called = true
        end)
        s:tick()
        assert(not called)
        assert(string.find(
            sock[1],
            '^HTTP/1.1 500 Internal Server Error'),
            string.format('Expected 500 found %s',  utils.table_string(sock))
        )
    end)
    it('no endpoint found should return 404', function()
        local sock = {'GET / HTTP/1.1'}
        local s = assert(Server.new(mocks.MockModule.new({{
            sock
        }})))
        s:listen(8080)
        s:tick()
        assert(string.find(sock[1], '^HTTP/1.1 404 Not Found'), string.format('Expected 500 found %s',  utils.table_string(sock)))
    end)
    it('no endpoint found should return 404, with endpoints', function()
        local sock = {'GET /not-found HTTP/1.1'}
        local s = assert(Server.new(mocks.MockModule.new({{
            sock
        }})))
        s:get('/', function() end)
        s:get('/found', function() end)
        s:post('/found', function() end)
        s:delete('/found', function() end)
        s:listen(8080)
        s:tick()
        assert(string.find(sock[1], '^HTTP/1.1 404 Not Found'), string.format('Expected 404 found %s',  utils.table_string(sock)))
    end)

end)
