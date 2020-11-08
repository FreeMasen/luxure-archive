
local function format_non_table(v)
    if v == nil then
        return 'nil'
    end
    if type(v) == 'string' then return string.format('\'%s\'', v) end
    return string.format('%s', v)
end

local function table_string(v, pre, visited)
    pre = pre or ""
    visited = visited or {}
    if type(v) ~= 'table' then
        return format_non_table(v)
    elseif next(v) == nil then
        return '{ }'
    end
    local ret = "{"
    local orig_pre = pre
    pre = pre .. "  "
    visited[v] = true
    for key, value in pairs(v) do
        ret = ret .. '\n' .. pre .. key .. ' = '
        if type(value) == "table" then
            if visited[value] then
                ret = ret .. '[recursive]'
            else
                ret = ret .. table_string(value, pre .. "  ", visited)
            end
        else
            ret = ret .. format_non_table(value)
        end
    end
    return string.format("%s\n%s}", ret, orig_pre)
end

return {
    table_string = table_string,
}
