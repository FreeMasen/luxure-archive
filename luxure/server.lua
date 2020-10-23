local Server = {}

function Server.new(base)
    base = base or {}
    setmetatable(base, Server)
    return base
end

function Server:listen(port)
    if port == nil then
        port = 0
    end
    self.sock = socket.tcp("0.0.0.0", port);
end

return Server