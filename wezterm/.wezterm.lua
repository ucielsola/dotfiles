-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

-- Dynamic theme based on time of day
local function get_theme_for_time()
  local time = wezterm.time.now()
  local hour = tonumber(time:format("%H"))
  
  -- Light theme from 7am to 7pm, dark theme otherwise
  if hour >= 7 and hour < 17 then
    return "Catppuccin Latte"
  else
    return "Catppuccin Mocha"
  end
end

config.color_scheme = get_theme_for_time()

config.font = wezterm.font("CaskaydiaMono Nerd Font")
config.font_size = 19

-- Tab bar configuration
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true

config.window_decorations = "RESIZE"

config.window_background_opacity = 0.9
config.macos_window_background_blur = 10

-- Performance and behavior
config.scrollback_lines = 10000
config.adjust_window_size_when_changing_font_size = false

-- Custom tab title formatting with icons
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local pane = tab.active_pane
  local title = pane.title
  
  -- Add icon based on process
  local process_icons = {
    ["nvim"] = "󰈺",
    ["vim"] = "",
    ["zsh"] = "",
    ["bash"] = "",
    ["node"] = "",
    ["python"] = "",
    ["git"] = "",
  }
  
  local process_name = pane.foreground_process_name
  local icon = "󰞷"
  
  if process_name then
    for name, proc_icon in pairs(process_icons) do
      if process_name:find(name) then
        icon = proc_icon
        break
      end
    end
  end
  
  return {
    { Text = " " .. icon .. " " .. tab.tab_index + 1 .. ": " .. title .. " " },
  }
end)

-- Custom status bar with git branch and time
wezterm.on("update-status", function(window, pane)
  local cwd = pane:get_current_working_dir()
  local git_branch = ""
  
  if cwd then
    local cwd_path = cwd.file_path or cwd
    local success, stdout = pcall(function()
      return io.popen("cd " .. cwd_path .. " && git branch --show-current 2>/dev/null"):read("*a")
    end)
    
    if success and stdout and stdout ~= "" then
      git_branch = " " .. stdout:gsub("\n", "")
    end
  end
  
  local time = wezterm.strftime(" %H:%M")
  
  window:set_right_status(wezterm.format({
    { Foreground = { Color = "#fab387" } },
    { Text = git_branch },
    { Foreground = { Color = "#89b4fa" } },
    { Text = time .. " " },
  }))
end)

return config