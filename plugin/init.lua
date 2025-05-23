-- TODO:
-- simple workaround to avoid nvim trying to load this module
-- https://github.com/wez/wezterm/issues/4533#issuecomment-1874094722
-- is there a better alt?
if vim ~= nil then
    return
end

local wezterm = require('wezterm')
local M = {}

---@param var string
---@return boolean
local function is_shell_integ_user_var(var)
    local shell_integ_user_vars = {
        'WEZTERM_PROG',
        'WEZTERM_USER',
        'WEZTERM_HOST',
        'WEZTERM_IN_TMUX',
    }
    for _, val in ipairs(shell_integ_user_vars) do
        if val == var then
            return true
        end
    end
    return false
end

---Interpret the Wezterm user var that is passed in and
---make the appropriate changes to the given overrides table.
---@param overrides table The table of configuration overrides.
---@param name string The name of the user variable (intended as the configuration key).
---@param value string The string value of the user variable.
---@return table The modified overrides table.
function M.override_user_var(overrides, name, value)
    -- Do nothing for shell integration specific user vars
    if is_shell_integ_user_var(name) then
        wezterm.log_info('Skipping shell integration var:', name)
        return overrides
    end

    -- Attempt to parse the value as JSON
    local success, parsed_json_value = pcall(wezterm.json_parse, value)

    if success then
        -- Value was valid JSON. parsed_json_value is the Lua equivalent (table, string, number, boolean, nil).
        overrides[name] = parsed_json_value
        wezterm.log_info("Successfully parsed JSON for key '", name, "'. Value set to:", parsed_json_value, "(type:", type(parsed_json_value), ")")
    else
        -- Value was not valid JSON.
        -- Treat it as a plain string, but also try to convert to boolean or number
        -- if it explicitly matches "true", "false", or a numeric pattern.
        wezterm.log_info("Value for key '", name, "' ('", value, "') is not valid JSON. Attempting direct type conversion.")
        if value == "true" then
            overrides[name] = true
            wezterm.log_info("Converted '", name, "' to boolean: true")
        elseif value == "false" then
            overrides[name] = false
            wezterm.log_info("Converted '", name, "' to boolean: false")
        else
            local num = tonumber(value)
            if num ~= nil then
                overrides[name] = num
                wezterm.log_info("Converted '", name, "' to number:", num)
            else
                -- Default to treating it as a string if no other conversion fits
                overrides[name] = value
                wezterm.log_info("Set '", name, "' to string value:", value)
            end
        end
    end
    return overrides
end

return M
