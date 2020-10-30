local function table_string(v, pre)
    pre = pre or ""
    local ret = pre .. "{"
    local orig_pre = pre
    pre = pre .. "  "
    for key, value in pairs(v) do
        if type(value) == "table" then
            ret = string.format("%s\n%s%s: %s", ret, pre, key, table_string(value, pre .. "  "))
        else
            ret = string.format("%s\n%s%s: %s", ret, pre, key, value)
        end
    end
    return string.format("%s\n%s}", ret, orig_pre)
end

local function percent_decode(s)
    return string.gsub(
        s,
        '(%%[0-7][0-9A-Fa-f])',
        function (encoded)
            local last_two = string.sub(encoded, 2)
            return string.char(tonumber(last_two, 16))
        end
    )
end

return {
    table_string = table_string,
    percent_decode = percent_decode,
}