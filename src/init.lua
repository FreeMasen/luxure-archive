_G.TEST = os.getenv("LUXURE_TEST") == "1"
if _G.TEST then
    function describe(str, cb)
        io.write(str)
        io.write("->")
        cb()
    end
    function it(str, cb)
        io.write("\n  " .. str .. " .. ")
        local s, e = pcall(cb)
        if s then
            io.write("passed")
            return
        end
        io.write("failed ")
        print(e)
    end
    function assert(b, msg)
        if b then
            return
        end
        error("Assert failed: " .. (msg or ""))
    end
end
return {
    request = require "request",
}
