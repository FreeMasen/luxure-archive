local MockSocket = {}
MockSocket.__index = MockSocket

function MockSocket.new(inner)
    local ret = {
        recvd = 0,
        sent = 0,
        inner = inner or {},
        open = true,
    }
    setmetatable(ret, MockSocket)
    return ret
end

function MockSocket:getstats()
    return self.recvd, self.sent
end

function MockSocket:close()
    self.open = false
end

function MockSocket.new_with_preamble(method, path)
    return MockSocket.new({
        string.format("%s %s HTTP/1.1", string.upper(method), path)
    })
end

function MockSocket:receive()
    if #self.inner == 0 then
        return nil, 'empty'
    end
    local part = table.remove(self.inner, 1)
    self.recvd = self.recvd + #(part or "")
    return part
end

function MockSocket:send(s)
    self.inner = self.inner or {}
    self.sent = self.sent + #(s or "")
    table.insert(self.inner, s)
    if s then
        return #s
    end
end

local MockTcp = {}
MockTcp.__index = MockTcp

function MockTcp.new(inner)
    local ret = {
        inner = inner or {}
    }
    setmetatable(ret, MockTcp)
    return ret
end

function MockTcp:accept()
    local list = assert(table.remove(self.inner))
    return MockSocket.new(list)
end

local MockModule = {}
MockModule.__index = MockModule
local sockets
function MockModule.new(inner)
    sockets = inner or {}
    return MockModule
end
function MockModule.bind(ip, port)
    local list = assert(table.remove(sockets))
    return MockTcp.new(list)
end

return {
    MockSocket = MockSocket,
    MockTcp = MockTcp,
    MockModule = MockModule,
}
