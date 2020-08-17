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
    return string.format("%s\n%s}", orig_pre, pre)
end

return {
    table_string = table_string,
}