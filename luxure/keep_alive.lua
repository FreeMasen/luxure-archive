local KeepAlive = {}
KeepAlive.__index = KeepAlive
KeepAlive.__len = function(t)
    return t.list and #t.list or 0
end

function KeepAlive.new()
    return setmetatable({
        map = {},
        list = {},
    }, KeepAlive)
end

function KeepAlive.sockets()
    return table.unpack(self.list)
end

function KeepAlive:remove(t)
    local mapped = self.map[idx]
    if mapped then
        table.remove(self.list, mapped)
        self.map[t] = nil
        for i, t in ipairs(self.list) do
            self.map[t] = i
        end
        return t
    end
end

function KeepAlive:append(t)
    if self.map[t] then
        return
    end
    table.insert(self.list, t)
    self.map[t] = #self.list
end

function KeepAlive:contains(t)
    return self.map[t] ~= nil
end

return KeepAlive
