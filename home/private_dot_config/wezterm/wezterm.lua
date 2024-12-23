local wezterm = require 'wezterm'

return {
  check_for_updates = true,
  color_scheme = "Dracula (Official)",
  font = wezterm.font 'JetBrains Mono',

  -- Enable the scrollbar.
  -- It will occupy the right window padding space.
  -- If right padding is set to 0 then it will be increased
  -- to a single cell width
  enable_scroll_bar = true,

  -- How many lines of scrollback you want to retain per tab
  scrollback_lines = 65536,

  -- Controls the maximum frame rate used when rendering easing effects
  -- https://wezfurlong.org/wezterm/config/lua/config/animation_fps.html
  animation_fps = 30,

  -- Limits the maximum number of frames per second that wezterm will attempt to draw.
  -- Defaults to 60.
  -- https://wezfurlong.org/wezterm/config/lua/config/max_fps.html
  max_fps = 120,

  -- Whether to display a confirmation prompt when the window is closed by
  -- the windowing environment, either because the user closed it with
  -- the window decorations, or instructed their window manager to close it.
  window_close_confirmation = "NeverPrompt",
}
