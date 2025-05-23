# wezterm-config.nvim

Neovim and [Wezterm](https://github.com/wez/wezterm) feel like the perfect match. 

Use this plugin to send Wezterm config overrides from within Neovim. This repo doubles as the source of both the Neovim plugin (`lua/wezterm-config/`) and the Wezterm plugin (`plugin/`). 

Below are instructions and suggestions for setting both pieces up.

## Installation and use

### Neovim

Using [folke/lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    'winter-again/wezterm-config.nvim',
    config = function()
        -- changing this to true means the plugin will try to append
        -- $HOME/.config/wezterm' to your RTP, meaning you can more conveniently
        -- access modules in $HOME/.config/wezterm/lua/ for using with this plugin
        -- otherwise, store data where you want
        require('wezterm_config').setup({
            -- defaults:
            append_wezterm_to_rtp = false,
        })
    end
}
```

### Wezterm

Create a file named `wezterm_config_nvim.lua` in the same directory as your `wezterm.lua` (or in a subdirectory like `lua/`) with the following content:

```lua
local wezterm = require('wezterm')
local M = {}

-- Import the override_user_var function from the plugin
M.override_user_var = require('plugin/init').override_user_var

return M
```

Then in your main `wezterm.lua`, set up the configuration like this:

```lua
local wezterm = require('wezterm')
local config = {}

-- If wezterm_config_nvim.lua is in the same directory as your wezterm.lua:
local wezterm_config_nvim = require('wezterm_config_nvim')
-- If it's in a subdirectory, e.g., 'lua/', use:
-- local wezterm_config_nvim = require('lua.wezterm_config_nvim')

-- Make sure to load other parts of your config here, for example:
-- config.font = wezterm.font("JetBrains Mono") -- Your default font

wezterm.on("user-var-changed", function(window, pane, name, value)
    local overrides = window:get_config_overrides() or {}
    wezterm.log_info("--- User Var Changed ---")
    wezterm.log_info("Name:", name, "| Value:", value, "| Type of value:", type(value))
    wezterm.log_info("Overrides before change:", overrides)

    if name == "font" then
        -- For the 'font' key, Wezterm expects a font object or a font name string.
        -- The 'value' from the user-var is the font name string (e.g., "JetBrains Mono").
        -- It's generally best to create a font object using wezterm.font().
        local font_obj = wezterm.font(value)
        if font_obj then
             overrides.font = font_obj -- Use the literal key "font"
             wezterm.log_info("Applied FONT override. New overrides.font:", overrides.font)
        else
            wezterm.log_error("Failed to create font object for value:", value)
        end
    elseif name == "font_size" then -- Example of a numeric override
        local size = tonumber(value)
        if size then
            overrides.font_size = size
            wezterm.log_info("Applied FONT_SIZE override. New overrides.font_size:", overrides.font_size)
        else
            wezterm.log_error("Invalid font_size value:", value, "- not a number.")
        end
    else
        -- For all other variables, use the generic override function from the module.
        -- 'name' is the config key (e.g., "enable_ligatures", "window_padding").
        -- 'value' is the string to be parsed by the override_user_var function.
        wezterm.log_info("Applying generic override for key:", name)
        overrides = wezterm_config_nvim.override_user_var(overrides, name, value)
        wezterm.log_info("Value for '", name, "' in overrides after generic processing:", overrides[name])
    end

    wezterm.log_info("Final overrides before applying to window:", overrides)
    window:set_config_overrides(overrides)
    wezterm.log_info("--- End User Var Changed ---")
end)

-- Add other configurations and return the config table
-- For example:
-- config.color_scheme = "Catppuccin Mocha"
-- config.font_size = 12.0
-- ... etc.

return config
```

This setup provides enhanced logging and special handling for font-related configurations, while maintaining compatibility with all other configuration options through the generic override function.

### Putting it all together

Simple key-value style (like `config.font_size` or `config.hide_tab_bar_if_only_one_tab`) config overrides should work out-of-the-box. Here's an example of how to override various Wezterm settings from inside of Neovim:

```lua
-- in Neovim
local wezterm_config = require('wezterm-config')

-- Change font size
vim.keymap.set('n', '<leader><leader>f', function()
    wezterm_config.set_wezterm_user_var('font_size', '20')
end)

-- Change font
vim.keymap.set('n', '<leader><leader>F', function()
    wezterm_config.set_wezterm_user_var('font', 'JetBrains Mono')
end)

-- Toggle tab bar visibility
vim.keymap.set('n', '<leader><leader>t', function()
    wezterm_config.set_wezterm_user_var('hide_tab_bar_if_only_one_tab', 'true')
end)

-- Set window padding
vim.keymap.set('n', '<leader><leader>p', function()
    wezterm_config.set_wezterm_user_var('window_padding', '{"left": 0, "right": 0, "top": 0, "bottom": 0}')
end)
```

## Tips

For more complex configuration options that take Lua tables as their values (like `background`), you can pass them as JSON strings. For example:

```lua
-- Set a complex background configuration
vim.keymap.set('n', '<leader><leader>b', function()
    local background_config = {
        source = {
            File = "path/to/your/image.jpg"
        },
        width = "100%",
        height = "100%",
        opacity = 0.9
    }
    wezterm_config.set_wezterm_user_var('background', vim.fn.json_encode(background_config))
end)
```

You might find it helpful to be able to clear your config overrides, especially if there's been a mistake in an override resulting in some internal Wezterm error or you just want to restore defaults. This is how you can setup a Wezterm keymap to do this:

```lua
wezterm.on('clear-overrides', function(window, pane)
    window:set_config_overrides({})
    -- optionally have a small notification pop
    -- the timeout is known to be unreliable
    window:toast_notification('wezterm', 'config overrides cleared', nil, 2000)
end)

local override_keymap = {
    key = 'X',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.EmitEvent('clear-overrides')
}

table.insert(config.keys, override_keymap)
```

### tmux

The plugin should play nicely with [tmux](https://github.com/tmux/tmux). Make sure the following setting is in your tmux conf file, [as advised by Wez](https://wezfurlong.org/wezterm/recipes/passing-data.html#user-vars).

```
set -g allow-passthrough on
```

