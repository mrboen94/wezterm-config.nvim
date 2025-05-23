if vim ~= nil then
	return
end

local wezterm = require("wezterm")
local M = {}

local function trim_quotes(s)
	return (s or ""):gsub("^['\"](.-)['\"]$", "%1")
end

local function is_shell_integ_user_var(var)
	local shell_integ_user_vars = {
		WEZTERM_PROG = true,
		WEZTERM_USER = true,
		WEZTERM_HOST = true,
		WEZTERM_IN_TMUX = true,
	}
	return shell_integ_user_vars[var] == true
end

--- Interpret the Wezterm user var and make config changes.
---@param overrides table
---@param name string
---@param value string
---@return table
function M.override_user_var(overrides, name, value)
	if is_shell_integ_user_var(name) then
		wezterm.log_info("Skipping shell integration var:", name)
		return overrides
	end

	if name == "font" then
		local cleaned = trim_quotes(value)
		local success, font_obj = pcall(wezterm.font, cleaned)
		if success and font_obj then
			if font_obj.font and font_obj.font[1] and font_obj.font[1].family then
				font_obj.font[1].family = trim_quotes(font_obj.font[1].family)
			end
			overrides.font = font_obj
			wezterm.log_info("Applied FONT override. Cleaned value:", cleaned)
		else
			wezterm.log_error("Failed to create font object from sanitized input:", cleaned)
		end
		return overrides
	end

	if name == "font_size" then
		local size = tonumber(value)
		if size then
			overrides.font_size = size
			wezterm.log_info("Applied FONT_SIZE override. New overrides.font_size:", overrides.font_size)
		else
			wezterm.log_error("Invalid font_size value:", value)
		end
		return overrides
	end

	local success, parsed_json_value = pcall(wezterm.json_parse, value)
	if success then
		overrides[name] = parsed_json_value
		wezterm.log_info("Parsed JSON override:", name, parsed_json_value)
	else
		if value == "true" then
			overrides[name] = true
		elseif value == "false" then
			overrides[name] = false
		else
			local num = tonumber(value)
			if num ~= nil then
				overrides[name] = num
			else
				overrides[name] = value
			end
		end
		wezterm.log_info("Set override for", name, "=", overrides[name])
	end

	return overrides
end

return M
