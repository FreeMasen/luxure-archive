
local function format_non_table(v)
    if v == nil then
        return 'nil'
    end
    if type(v) == 'string' then return string.format('\'%s\'', v) end
    return string.format('%s', v)
end

local function table_string(v, pre)
    pre = pre or ""
    if type(v) ~= 'table' then
        return format_non_table(v)
    elseif next(v) == nil then
        return '{ }'
    end
    local ret = "{"
    local orig_pre = pre
    pre = pre .. "  "
    for key, value in pairs(v) do
        ret = ret .. '\n' .. pre .. key .. ' = '
        if type(value) == "table" then
            ret = ret .. table_string(value, pre .. "  ")
        else
            ret = ret .. format_non_table(value)
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