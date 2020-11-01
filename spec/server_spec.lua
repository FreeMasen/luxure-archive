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
end)
