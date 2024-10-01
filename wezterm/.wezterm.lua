local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

config.set_environment_variables = {
    PATH = '/opt/homebrew/bin:' .. os.getenv('PATH')
}

config.color_scheme = 'Catppuccin Macchiato (Gogh)'

config.font = wezterm.font("CaskaydiaMono Nerd Font")
config.font_size = 19

config.enable_tab_bar = true

config.window_decorations = "RESIZE"

config.window_background_opacity = 0.9
config.macos_window_background_blur = 30

wezterm.on('gui-startup', function(cmd)
    local mux = wezterm.mux
    local tab, pane, window = mux.spawn_window(cmd or {})
    -- Create a split occupying the right 1/3 of the screen
    pane:split { direction = 'Top', size = 0.9 }
end)

-- Table mapping keypresses to actions
config.leader = { key = "Space", mods = 'OPT', timeout_milliseconds = 1000 }
config.keys = {
    -- Sends ESC + b and ESC + f sequence, which is used
    -- for telling your shell to jump back/forward.
    {
        -- When the left arrow is pressed
        key = 'LeftArrow',
        -- With the "Option" key modifier held down
        mods = 'OPT',
        -- Perform this action, in this case - sending ESC + B
        -- to the terminal
        action = act.SendString '\x1bb',
    },
    {
        key = 'RightArrow',
        mods = 'OPT',
        action = act.SendString '\x1bf',
    },
    {
        key = ',',
        mods = 'SUPER',
        action = act.SpawnCommandInNewTab {
            cwd = wezterm.home_dir,
            args = { 'zed', wezterm.config_file },
        },
    },
    {
        key = 'v',
        mods = 'LEADER',
        action = act.SplitVertical { domain = 'CurrentPaneDomain' }
    },
    {
        key = 'h',
        mods = 'LEADER',
        action = act.SplitHorizontal { domain = 'CurrentPaneDomain' }
    },
    {
        key = 'x',
        mods = 'LEADER',
        action = act.CloseCurrentPane { confirm = false },
    },
    {
        key = 'DownArrow',
        mods = 'LEADER',
        action = act.AdjustPaneSize { "Down", 20 },
    }
}

return config
