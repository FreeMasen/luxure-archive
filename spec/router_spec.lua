local Router = require 'luxure.router'.Router
local Request = require 'luxure.request'.Request
local Response = require 'luxure.response'.Response
local MockSocket = require 'spec.mock_socket'.MockSocket
describe('Router', function ()
    it('Should call callback on route', function()
        local r = Router.new()
        local req = Request.new(MockSocket.new_with_preamble('GET', '/'))
        local called = false
        r:register_handler('/', 'GET', function(req, res)
            called = true
        end)
        assert(r:route(
            req,
            Response.new(MockSocket.new())
        ))
        assert(called)
    end)
    it('should not call if route not matched', function()
        local r = Router.new()
        local req = Request.new(MockSocket.new_with_preamble('GET', '/not_registered'))
        local called = false
        r:register_handler('/', 'GET', function(req, res)
            called = true
        end)
        assert(not r:route(
            req,
            Response.new(MockSocket.new())
        ))
        assert(not called)
    end)
    
    it('should not call if method not matched', function()
        local r = Router.new()
        local req = Request.new(MockSocket.new_with_preamble('POST', '/'))
        local called = false
        r:register_handler('/', 'GET', function(req, res)
            called = true
        end)
        assert(not r:route(
            req,
            Response.new(MockSocket.new())
        ))
        assert(not called)
    end)
end)
