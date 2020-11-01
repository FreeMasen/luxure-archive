local MockSocket = {}

MockSocket.__index = MockSocket

function MockSocket.new(inner)
    local ret = {
        inner = inner or {},
    }
    setmetatable(ret, MockSocket)
    return ret
end

function MockSocket:receive()
    if #self.inner == 0 then
        return nil
    end
    return table.remove(self.inner, 1)
end
function MockSocket:send(s)
    self.inner = self.inner or {}
    table.insert(self.inner, s)
end
return MockSocket