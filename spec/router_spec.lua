local Router = require 'luxure.router'.Router
local Request = require 'luncheon.request'
local Response = require 'luncheon.response'
local MockSocket = require 'spec.mock_socket'.MockSocket
describe('Router', function ()
    it('Should call callback on route', function()
        local r = Router.new()
        local req = Request.tcp_source(MockSocket.new_with_preamble('GET', '/'))
        local called = false
        r:register_handler('/', 'GET', function(req, res)
            called = true
        end)
        r:route(
            req,
            Response.new(200, MockSocket.new())
        )
        assert(called)
    end)
    it('should not call if route not matched', function()
        local r = Router.new()
        local req = Request.tcp_source(MockSocket.new_with_preamble('GET', '/not_registered'))
        local called = false
        r:register_handler('/', 'GET', function(req, res)
            called = true
        end)
        assert(not r:route(
            req,
            Response.new(200, MockSocket.new())
        ))
        assert(not called)
    end)
    it('should not call if method not matched', function()
        local r = Router.new()
        local req = Request.tcp_source(MockSocket.new_with_preamble('POST', '/'))
        local called = false
        r:register_handler('/', 'GET', function(req, res)
            called = true
        end)
        assert(not r:route(
            req,
            Response.tcp_source(MockSocket.new())
        ))
        assert(not called)
    end)
    it('Handler error should panic', function()
        local r = Router.new()
        local req = Request.tcp_source(MockSocket.new_with_preamble('GET', '/'))
        local res = Response.new(200, MockSocket.new())
        r:register_handler('/', 'GET', function(req, res)
            error('called')
        end)
        assert(not r:route(
            req,
            res
        ))
        assert.are.equal(500, res.status)
    end)
end)
