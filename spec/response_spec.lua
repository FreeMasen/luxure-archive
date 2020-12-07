local MockSocket = require 'spec.mock_socket'.MockSocket
local Response = require 'luxure.response'.Response
local utils = require 'luxure.utils'
local ltn12 = require("ltn12")

describe('Response', function()
    it('should send some stuff', function()
        local sock = MockSocket.new()
        local r = Response.new(sock)
        r:send()
        local res = assert(sock.inner[1], 'nothing was sent')
        assert(string.find(res, '^HTTP/1.1 200 OK'), 'Didn\'t contain HTTP preamble')
        assert(string.find(res, 'Server: Luxure'), 'expected server ' .. res)
        assert(string.find(res, 'Content-Length: 0', 0, true), 'expected content length ' .. res)
    end)
    it('should send the right status', function()
        local sock = MockSocket.new()
        local r = Response.new(sock):status(500)
        r:send()
        local res = assert(sock.inner[1], 'nothing was sent')
        assert(string.find(res, '^HTTP/1.1 500 Internal Server Error'), 'expected 500, found ' .. res)
    end)
    it('should send the right default content type/length', function()
        local sock = MockSocket.new()
        local r = Response.new(sock)
        r:send('body')
        local res = assert(sock.inner[1], 'nothing was sent')
        assert(string.find(res, 'Content-Type: text/plain', 0, true), 'expected text/plain ' .. res)
        assert(string.find(res, 'Content-Length: 4', 0, true), 'expected length to be 4 ' .. res)
    end)
    it('should send the right explicit content type', function()
        local sock = MockSocket.new()
        local r = Response.new(sock):content_type('application/json')
        r:send('body')
        local res = assert(sock.inner[1], 'nothing was sent')
        assert(string.find(res, 'Content-Type: application/json', 0, true), 'expected application/json ' .. res)
    end)
    describe('has_sent', function()
        it('should work as expected with normal usage', function()
            local sock = MockSocket.new()
            local r = Response.new(sock)
            r:send('body')
            assert(r:has_sent(), 'expected that `send` would actually send...')
        end)
        it('should work as expected with direct socket usage', function()
            local sock = MockSocket.new()
            local r = Response.new(sock)
            r.outgoing:send('body')
            assert(r:has_sent(), 'expected that `outgoing:send` would actually send...')
        end)
        it('true should be cached', function()
            local sock = MockSocket.new()
            local s = spy.on(sock, 'getstats')
            local r = Response.new(sock)
            r.outgoing:send('body')
            assert(r:has_sent())
            assert(r:has_sent())
            assert.spy(s).was.called(1)
        end)
        it('false should not be cached', function()
            local sock = MockSocket.new()
            local s = spy.on(sock, 'getstats')
            local r = Response.new(sock)
            assert(not r:has_sent())
            assert(not r:has_sent())
            assert.spy(s).was.called(2)
        end)
    end)
    describe('buffered mode', function()
        it('should handle buffering with 1 chunk', function()
            local sock = MockSocket.new()
            local r = Response.new(sock)
            local s = spy.on(sock, 'send')
            r._send_buffer_size = 10
            r:append_body('1234567890')
            r:send()
            assert.spy(s).was.called(1)
            assert(r.body == '')
            assert(sock.inner[1] == 'HTTP/1.1 200 OK\r\n\r\n'..'1234567890', string.format('unexpected socket content, %s', sock.inner[1]))
        end)
        it('should handle buffering with many chunks', function()
            local sock = MockSocket.new()
            local r = Response.new(sock)
            local s = spy.on(sock, 'send')
            r:set_send_buffer_size(10)
            for i = 1, 20, 1 do
                r:append_body('12345')
                if i % 2 == 0 then
                    assert(r.body == '', string.format('expected empty body found %s', r.body))
                    if i == 2 then
                        assert(sock.inner[1] == 'HTTP/1.1 200 OK\r\n\r\n'..'1234512345')
                    else
                        assert(sock.inner[#sock.inner] == '1234512345', string.format('%i, unexpected socket content, %s', i, utils.table_string(sock.inner)))
                    end
                else
                    assert(r.body == '12345', string.format('expected 12345 found %s', r.body))
                end
            end
            
            r:send()
            assert.spy(s).was.called(10)
            assert(r.body == '')
        end)
        it('sink should work as expected: short', function()
            local sock = MockSocket.new()
            local r = Response.new(sock)
            r:set_send_buffer_size(10)
            local body = 'This is the body of a Response, please send all of these bytes to the socket'
            ltn12.pump.all(
                ltn12.source.string(body),
                r:sink()
            )
            
            assert(sock.inner[1] == 'HTTP/1.1 200 OK\r\n\r\n'..body, string.format('unexpected body, found %s', sock.inner[1] or utils.table_string(sock.inner)))
        end)
        it('sink should work as expected: long', function()
            local sock = MockSocket.new()
            local r = Response.new(sock)
            r:set_send_buffer_size(10)
            local body = [[Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium
            doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et
            quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas
            sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione
            voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet,
            consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et
            dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem
            ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel
            eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel
            illum qui dolorem eum fugiat quo voluptas nulla pariatur?]]
            for _ = 1, 10, 1 do
                body = body .. body
            end
            ltn12.pump.all(
                ltn12.source.string(body),
                r:sink()
            )
            assert(table.concat(sock.inner, '') == 'HTTP/1.1 200 OK\r\n\r\n'..body, string.format('unexpected body, found %s', sock.inner[1]))
        end)
    end)
end)
