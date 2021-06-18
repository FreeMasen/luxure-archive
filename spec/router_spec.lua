local Router = require 'luxure.router'.Router
local Request = require 'luncheon.request'
local Response = require 'luncheon.response'
local MockSocket = require 'spec.mock_socket'.MockSocket
describe('Router', function ()
    it('Should call callback on route', function()
        local r = Router.new()
        local req = Request.incoming(MockSocket.new_with_preamble('GET', '/'))
        local called = false
        r:register_handler('/', 'GET', function(req, res)
            called = true
        end)
        r:route(
            req,
            Response.outgoing(MockSocket.new())
        )
        assert(called)
    end)
    it('should not call if route not matched', function()
        local r = Router.new()
        local req = Request.incoming(MockSocket.new_with_preamble('GET', '/not_registered'))
        local called = false
        r:register_handler('/', 'GET', function(req, res)
            called = true
        end)
        assert(not r:route(
            req,
            Response.outgoing(MockSocket.new())
        ))
        assert(not called)
    end)
    it('should not call if method not matched', function()
        local r = Router.new()
        local req = Request.incoming(MockSocket.new_with_preamble('POST', '/'))
        local called = false
        r:register_handler('/', 'GET', function(req, res)
            called = true
        end)
        assert(not r:route(
            req,
            Response.incoming(MockSocket.new())
        ))
        assert(not called)
    end)
end)
