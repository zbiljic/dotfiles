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
}
