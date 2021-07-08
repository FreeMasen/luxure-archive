local lux = require 'luxure'
local cosock = require 'cosock'
local Request = require 'luncheon.request'
local Response = require 'luncheon.response'
local log = require 'log'

function get_socket(ip, port)
  local sock = assert(cosock.socket.tcp())
  assert(sock:connect(ip, port))
  return sock
end

function make_request(req, ip, port)
  local sock = get_socket(ip, port)
  req.socket = sock
  req:send()
  local res = assert(Response.tcp_source(sock))
  return res
end

local tests = {
  index = function(ip, port)
    local index_req = Request.new('GET', '/')
    local index_res = make_request(index_req, ip, port)
    assert.are.equal(200, index_res.status)
    assert.are.equal('index', index_res:get_body())
  end,
  not_found = function(ip, port)
    local req = Request.new('GET', '/not-found')
    local res = make_request(req, ip, port)
    assert.are.equal(404, res.status)
  end,
  error = function(ip, port)
    local req = Request.new('GET', '/error')
    local res = make_request(req, ip, port)
    assert.are.equal(500, res.status)
    assert(res:get_body():find('Error!'))
  end,
  error_after_send = function(ip, port)
    local req = Request.new('GET', '/error-after-send')
    local res = make_request(req, ip, port)
    assert.are.equal(200, res.status)
  end,
}

describe('Integration Test', function()
  it('works #integration', function()
    local server = assert(lux.Server.new(lux.Opts.new():set_env('debug')))
    server:listen()
    server:get('/', function(req, res)
      res:send('index')
    end)
    server:get('/error', function(req, res)
      lux.Error.raise('Error!')
    end)
    server:get('/error-after-send', function(req, res)
      res:send()
      lux.Error.raise('Error!')
    end)
    server:get('/close-socket', function(req, res)
      res:send()
      server.sock:close()
    end)
    local ip = assert(server.ip)
    local port = assert(server.port)
    local total_tests = (function()
      local ret = 0
      for _ in pairs(tests) do ret = ret + 1 end
      return ret
    end)()
    local ct = 0
    cosock.spawn(function()
      for name, f in pairs(tests) do
        ct = ct + 1
        log.info('starting', name)
        f(ip, port)
        log.info('completed', name)
      end
    end,'client loop')
    server:run(error, function()
      return ct < total_tests
    end)
  end)
end)